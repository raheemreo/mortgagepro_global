// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_usda_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';
import 'usa_fha_loan_calc.dart'; // For ChecklistStatus

class USAUsdaLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAUsdaLoanCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAUsdaLoanCalc> createState() => _USAUsdaLoanCalcState();
}

class _USAUsdaLoanCalcState extends ConsumerState<USAUsdaLoanCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  // Input Controllers
  final _homePriceController = TextEditingController(text: '280000');
  final _incomeController = TextEditingController(text: '75000');
  final _rateController = TextEditingController(text: '6.35');
  final _propTaxController = TextEditingController(text: '2800');
  final _insuranceController = TextEditingController(text: '1400');

  int _selectedHhSize = 4;
  String _selectedRegion = 'standard';
  bool _showResults = false;
  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedCalculation(widget.savedCalc!);
      });
    }
  }

  @override
  void dispose() {
    _homePriceController.dispose();
    _incomeController.dispose();
    _rateController.dispose();
    _propTaxController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    double defaultVal = 0.0;
    if (c == _homePriceController) {
      defaultVal = 280000.0;
    } else if (c == _incomeController) {
      defaultVal = 75000.0;
    } else if (c == _rateController) {
      defaultVal = 6.35;
    } else if (c == _propTaxController) {
      defaultVal = 2800.0;
    } else if (c == _insuranceController) {
      defaultVal = 1400.0;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  // 2025 USDA Income Limits by household size (standard counties and high-cost counties)
  static const _incomeLimitsMap = {
    'standard': [103500, 112450, 126500, 140550, 151800, 163050, 174300, 185550],
    'high_cost': [135600, 154900, 174250, 193550, 208900, 224300, 239650, 255050],
  };

  void _resetInputs() {
    setState(() {
      _homePriceController.text = '280000';
      _incomeController.text = '75000';
      _rateController.text = '6.35';
      _propTaxController.text = '2800';
      _insuranceController.text = '1400';
      _selectedHhSize = 4;
      _selectedRegion = 'standard';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    final val_homePrice = calc.inputs['HomePrice'] ?? 280000.0;
    final val_income = calc.inputs['HouseholdIncome'] ?? 75000.0;
    final val_rate = calc.inputs['InterestRate'] ?? 6.35;
    final val_propTax = calc.inputs['PropertyTax'] ?? 2800.0;
    final val_insurance = calc.inputs['HomeInsurance'] ?? 1400.0;
    final hhSize = (calc.inputs['HouseholdSize'] ?? 4.0).toInt();
    final region = (calc.inputs['RegionIndex'] ?? 0.0) == 0.0 ? 'standard' : 'high_cost';

    setState(() {
      _homePriceController.text = val_homePrice.toStringAsFixed(0);
      _incomeController.text = val_income.toStringAsFixed(0);
      _rateController.text = val_rate.toStringAsFixed(2);
      _propTaxController.text = val_propTax.toStringAsFixed(0);
      _insuranceController.text = val_insurance.toStringAsFixed(0);
      _selectedHhSize = hhSize;
      _selectedRegion = region;

      _calcSnapshot[_homePriceController] = val_homePrice;
      _calcSnapshot[_incomeController] = val_income;
      _calcSnapshot[_rateController] = val_rate;
      _calcSnapshot[_propTaxController] = val_propTax;
      _calcSnapshot[_insuranceController] = val_insurance;
      _calcSnapshot['_selectedHhSize'] = hhSize;
      _calcSnapshot['_selectedRegion'] = region;
      _showResults = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _calculate() {
    final errors = <String, String>{};
    
    final val_homePrice = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_homePrice < 0) {
      errors['homePrice'] = 'Enter valid price';
    } else if (val_homePrice == 0) {
      errors['homePrice'] = 'Price required';
    }
    
    final val_income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_income < 0) {
      errors['income'] = 'Enter valid income';
    } else if (val_income == 0) {
      errors['income'] = 'Income required';
    }
    
    final val_rate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_rate < 0) {
      errors['rate'] = 'Enter valid rate';
    } else if (val_rate == 0) {
      errors['rate'] = 'Rate required';
    }

    final val_propTax = double.tryParse(_propTaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_propTax < 0) errors['propTax'] = 'Enter valid tax';

    final val_insurance = double.tryParse(_insuranceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_insurance < 0) errors['insurance'] = 'Enter valid ins';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      _showResults = false;
      return;
    }

    setState(() {
      _calcSnapshot[_homePriceController] = val_homePrice;
      _calcSnapshot[_incomeController] = val_income;
      _calcSnapshot[_rateController] = val_rate;
      _calcSnapshot[_propTaxController] = val_propTax;
      _calcSnapshot[_insuranceController] = val_insurance;
      _calcSnapshot['_selectedHhSize'] = _selectedHhSize;
      _calcSnapshot['_selectedRegion'] = _selectedRegion;
      _showResults = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _saveCalculation() async {
    final price = _val(_homePriceController);
    final income = _val(_incomeController);
    final rateAnnual = _val(_rateController);
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);

    final gf = price * 0.01;
    final loanAmt = price + gf;
    const termYears = 30;

    final double pi = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rateAnnual,
      termYears: termYears,
    );

    final annualFeeMonthly = (loanAmt * 0.0035) / 12;
    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + annualFeeMonthly + taxMonthly + insMonthly;

    final limits = _incomeLimitsMap[_selectedRegion] ?? _incomeLimitsMap['standard']!;
    final limit = limits[max(0, min(_selectedHhSize - 1, 7))];
    final isIncomeEligible = income <= limit;
    final ratio = limit > 0 ? (income / limit * 100) : 0.0;

    final labelCtrl = TextEditingController(text: 'USDA Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_usda_loan_calc/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: USDA Monthly Payment: ${CurrencyFormatter.format(total, symbol: '\$').split('.').first} · ${isIncomeEligible ? "Eligible" : "Exceeds Limit"}',
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
                hintText: 'Label (e.g. USDA Rural Home)',
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
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'USDA Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'USDA Loan Calculator',
        inputs: {
          'HomePrice': price,
          'HouseholdIncome': income,
          'InterestRate': rateAnnual,
          'HouseholdSize': _selectedHhSize.toDouble(),
          'PropertyTax': propTaxAnnual,
          'HomeInsurance': insAnnual,
          'RegionIndex': _selectedRegion == 'standard' ? 0.0 : 1.0,
        },
        results: {
          'MonthlyPayment': total,
          'GuaranteeFee': gf,
          'LoanAmount': loanAmt,
          'IncomeLimit': limit.toDouble(),
          'UsageRatio': ratio,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final _selectedHhSize = _showResults ? (_calcSnapshot['_selectedHhSize'] ?? this._selectedHhSize) : this._selectedHhSize;
    final _selectedRegion = _showResults ? (_calcSnapshot['_selectedRegion'] ?? this._selectedRegion) : this._selectedRegion;

    final isDirty = _showResults && (this._selectedHhSize != _calcSnapshot['_selectedHhSize'] || this._selectedRegion != _calcSnapshot['_selectedRegion'] || double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_homePriceController] ?? 0.0) || double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_incomeController] ?? 0.0) || double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_rateController] ?? 0.0) || double.tryParse(_propTaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_propTaxController] ?? 0.0) || double.tryParse(_insuranceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_insuranceController] ?? 0.0));

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final price = _val(_homePriceController);
    final income = _val(_incomeController);
    final rateAnnual = _val(_rateController);
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);

    // Calculations
    final gf = price * 0.01;
    final loanAmt = price + gf;
    const termYears = 30;
    const months = termYears * 12;

    final double pi = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rateAnnual,
      termYears: termYears,
    );

    final annualFeeMonthly = (loanAmt * 0.0035) / 12;
    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + annualFeeMonthly + taxMonthly + insMonthly;
    final totalInterest = (pi * months) - loanAmt;

    // Income eligibility check
    final limits = _incomeLimitsMap[_selectedRegion] ?? _incomeLimitsMap['standard']!;
    final limit = limits[max(0, min(_selectedHhSize - 1, 7))];
    final ratio = limit > 0 ? (income / limit * 100) : 0.0;
    final isIncomeEligible = income <= limit;

    // Conventional savings comparison
    final convDown = price * 0.20;
    final convPMI = (loanAmt * 0.0080) / 12;
    final netSavings = convPMI - annualFeeMonthly;

    // Interest formatter helper
    String formattedInterest;
    if (totalInterest >= 1000000) {
      formattedInterest = '\$${(totalInterest / 1000000).toStringAsFixed(2)}M';
    } else {
      formattedInterest = '\$${(totalInterest / 1000).toStringAsFixed(0)}K';
    }

    // Watch saved USDA calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'USDA Loan Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Premium Rate Strip Card — Live FRED data
        DarkRateStripBanner(items: [
          RateStripItem(label: 'USDA Rate\n(30-Yr)', provider: fredMortgage30Provider, fallback: 6.35),
          RateStripItem(label: 'Min. Down', provider: fredMortgage30Provider, fallback: 0, suffix: '', isGold: true),
          RateStripItem(label: 'Guarantee\nFee', provider: fredMortgage30Provider, fallback: 1.0, suffix: ''),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 16),

        _buildSectionHeader('Loan Details', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Rural Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF2D220F), Color(0xFF5C3E00)])
                : const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
            border: Border.all(
              color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFF59E0B),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USDA Rural Eligibility Check',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '97% of U.S. land area is eligible. Check USDA official map.',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.75) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌾 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'USDA Purchase Parameters',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Home Price & Income
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Home Price', _homePriceController, prefix: '\$', hint: 'Rural area property', errorText: _errors['homePrice']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Household Income', _incomeController, prefix: '\$', hint: 'All members combined', errorText: _errors['income']),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Interest Rate', _rateController, suffix: '%', errorText: _errors['rate']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField<int>(
                      label: 'Household Size',
                      value: _selectedHhSize,
                      items: List.generate(8, (i) {
                        final count = i + 1;
                        return DropdownMenuItem(
                          value: count,
                          child: Text('$count ${count == 1 ? "person" : "people"}'),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            this._selectedHhSize = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDropdownField<String>(
                label: 'State Region',
                value: _selectedRegion,
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Standard (most states)')),
                  DropdownMenuItem(value: 'high_cost', child: Text('High-Cost (CA, HI, AK, etc.)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      this._selectedRegion = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Property Tax', _propTaxController, prefix: '\$', suffix: '/yr', errorText: _errors['propTax']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Home Insurance', _insuranceController, prefix: '\$', suffix: '/yr', errorText: _errors['insurance']),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calculate & Save buttons
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: GestureDetector(
                      onTap: _calculate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF15803D).withValues(alpha: isDirty ? 0.45 : 0.25),
                              blurRadius: isDirty ? 16 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🌾 Calculate USDA Payment',
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Opacity(
                      opacity: _showResults ? 1.0 : 0.5,
                      child: GestureDetector(
                        onTap: () {
                          if (!_showResults) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please calculate before saving.', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            _saveCalculation();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.getCardColor(context),
                            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '💾 Save',
                            style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Saved list
        if (savedCalcs.isNotEmpty) ...[
          _buildSectionHeader(
            'Saved Calculations',
            onReset: () async {
              for (final calc in savedCalcs) {
                await ref.read(savedProvider.notifier).delete(calc.id);
              }
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All saved calculations cleared!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            resetLabel: 'Clear All',
            countBadge: savedCalcs.length,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              final limitVal = calc.results['IncomeLimit'] ?? 0.0;
              final isElig = (calc.inputs['HouseholdIncome'] ?? 0.0) <= limitVal;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _loadSavedCalculation(calc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc.label,
                              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${CurrencyFormatter.compact(calc.inputs['HomePrice'] ?? 0.0, symbol: '\$')} home · HH ${calc.inputs['HouseholdSize']?.toInt() ?? 0} · ${isElig ? '✅ Eligible' : '❌ Over limit'}',
                              style: AppTextStyles.dmSans(size: 9.0, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.compact(calc.results['MonthlyPayment'] ?? 0.0, symbol: '\$'),
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isElig
                            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                            : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: theme.getMutedColor(context).withValues(alpha: 0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await ref.read(savedProvider.notifier).delete(calc.id);
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        if (!_showResults)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('🌾', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Your Loan Details Above',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll calculate your monthly payment,\ntotal interest, and income eligibility requirements.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          )
        else ...[
          Container(
            key: _resultsKey,
            child: Column(
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
                            'Inputs have changed. Tap "Calculate USDA Payment" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF0B1D3A), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSectionHeader('Monthly Payment Breakdown', onReset: null),
          const SizedBox(height: 8),

          // Result Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL MONTHLY PAYMENT (PITI + ANNUAL FEE)',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$',
                      style: AppTextStyles.dmSans(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(total, symbol: '').split('.').first,
                      style: AppTextStyles.dmSans(
                        size: 38,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' /mo',
                      style: AppTextStyles.dmSans(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Loan: ${CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first} · \$0 down · Guarantee Fee: ${CurrencyFormatter.format(gf, symbol: '\$').split('.').first} financed',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubHeroStat('Guar. Fee', CurrencyFormatter.compact(gf, symbol: '\$')),
                    _buildSubHeroStat('Ann. Fee/mo', CurrencyFormatter.compact(annualFeeMonthly, symbol: '\$')),
                    _buildSubHeroStat('Total Interest', formattedInterest),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stacked Payment Composition Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 PAYMENT COMPOSITION',
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 28,
                    width: double.infinity,
                    child: Row(
                      children: [
                        if (pi > 0)
                          Expanded(
                            flex: (pi / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
                              ),
                            ),
                          ),
                        if (annualFeeMonthly > 0)
                          Expanded(
                            flex: (annualFeeMonthly / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                              ),
                            ),
                          ),
                        if (taxMonthly > 0)
                          Expanded(
                            flex: (taxMonthly / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF4A5C7A), Color(0xFF64748B)]),
                              ),
                            ),
                          ),
                        if (insMonthly > 0)
                          Expanded(
                            flex: (insMonthly / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF78350F), Color(0xFFA16207)]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Legend Layout
                LayoutBuilder(builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem('P&I', CurrencyFormatter.format(pi), const Color(0xFF15803D), itemWidth),
                      _buildLegendItem('Annual Fee', CurrencyFormatter.format(annualFeeMonthly), const Color(0xFFD97706), itemWidth),
                      _buildLegendItem('Tax', CurrencyFormatter.format(taxMonthly), const Color(0xFF4A5C7A), itemWidth),
                      _buildLegendItem('Insurance', CurrencyFormatter.format(insMonthly), const Color(0xFF78350F), itemWidth),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 6-Card Breakdown Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.22,
            children: [
              _buildMetricCard('💵', 'Principal & Interest', CurrencyFormatter.format(pi), 'Base mortgage'),
              _buildMetricCard('🛡️', 'Annual Fee', CurrencyFormatter.format(annualFeeMonthly), '0.35% of loan ÷ 12'),
              _buildMetricCard('🏛️', 'Property Tax', CurrencyFormatter.format(taxMonthly), 'Monthly escrow'),
              _buildMetricCard('🔥', 'Home Insurance', CurrencyFormatter.format(insMonthly), 'Monthly escrow'),
              _buildMetricCard('📊', 'Upfront Fee', CurrencyFormatter.format(gf), '1.0% financed'),
              _buildMetricCard('💰', 'Total Interest', formattedInterest, 'Over 30 years'),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Income Eligibility Check (2025)', onReset: null),
          const SizedBox(height: 8),

          // Income status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F3A1D) : const Color(0xFFDCFCE7),
              border: Border.all(color: isDark ? const Color(0xFF15803D).withValues(alpha: 0.4) : const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌾 USDA 2025 Income Limits (502 Guaranteed)',
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 10),
                _buildIncomeRow('Your Household Income', '${CurrencyFormatter.format(income, symbol: '\$').split('.').first} / yr', isDark),
                _buildIncomeRow('Income Limit for HH Size', '${CurrencyFormatter.format(limit.toDouble(), symbol: '\$').split('.').first} ($_selectedHhSize-person)', isDark),
                _buildIncomeRow(
                  'Eligibility Status',
                  isIncomeEligible ? '✅ Within limit' : '❌ Exceeds limit',
                  isDark,
                  statusColor: isIncomeEligible
                      ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                      : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                ),
                _buildIncomeRow('Income to Limit Ratio', '${ratio.toStringAsFixed(1)}% – ${isIncomeEligible ? "Eligible" : "Over cap"}', isDark),
                const SizedBox(height: 12),
                // Income Usage Meter Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Income Usage',
                          style: AppTextStyles.dmSans(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                          ),
                        ),
                        Text(
                          '${ratio.toStringAsFixed(1)}% of limit',
                          style: AppTextStyles.dmSans(
                            size: 9.5,
                            weight: FontWeight.w800,
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF86EFAC).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.centerLeft,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final fillW = constraints.maxWidth * min(ratio / 100, 1.0);
                        final meterColor = ratio <= 70
                            ? const Color(0xFF15803D)
                            : (ratio <= 90 ? const Color(0xFFD97706) : const Color(0xFFB91C1C));
                        return Container(
                          height: 10,
                          width: fillW,
                          decoration: BoxDecoration(
                            color: meterColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('USDA vs. Conventional Savings', onReset: null),
          const SizedBox(height: 8),

          // Savings comparison card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💚 USDA vs. Conventional Savings Benefit',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFCD34D),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildSavingsGridItem('Down Pmt Saved', '${CurrencyFormatter.format(convDown, symbol: '\$').split('.').first} saved', isGreen: true),
                    _buildSavingsGridItem('No PMI Savings', '${CurrencyFormatter.format(convPMI, symbol: '\$').split('.').first}/mo', isGreen: true),
                    _buildSavingsGridItem('USDA Ann. Fee', '${CurrencyFormatter.format(annualFeeMonthly, symbol: '\$').split('.').first}/mo', isGreen: false),
                    _buildSavingsGridItem('Net Monthly Save', '${netSavings >= 0 ? "+" : ""}${CurrencyFormatter.format(netSavings, symbol: '\$').split('.').first}/mo', isGreen: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('USDA Eligibility Checklist', onReset: null),
          const SizedBox(height: 8),

          // Eligibility Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildChecklistRow(
                  label: 'Location Requirement',
                  value: 'Rural/suburban area',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Down Payment',
                  value: '\$0 required (100% financing)',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Loan Term',
                  value: '30-year fixed only',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Primary Residence',
                  value: 'Must be primary home',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Credit Score',
                  value: 'No USDA min · Lenders ~640',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Property Type',
                  value: 'SFR, Approved Condos/PUDs',
                  status: ChecklistStatus.success,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        _buildSectionHeader('USDA Program Resources', onReset: null),
        const SizedBox(height: 8),

        // Resources List
        Column(
          children: [
            GestureDetector(
              onTap: () => context.push('/usa/usda-eligibility-map'),
              child: _buildGuidelineCard('🗺️', 'USDA Eligibility Map', 'Check property address at RD eligibility page'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/usda-502-direct-vs-guaranteed'),
              child: _buildGuidelineCard('🌾', '502 Direct vs. Guaranteed', 'Direct: very low income · Guaranteed: moderate income limits'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/usda-2025-income-limits'),
              child: _buildGuidelineCard('📋', '2025 Income Limits by County', 'Limits vary by standard vs high-cost county regions'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/usda-streamline-refinance'),
              child: _buildGuidelineCard('🔄', 'USDA Streamline Refinance', 'Reduce rate on current USDA loan with simplified processing'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubHeroStat(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color, double width) {
    final theme = widget.theme;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w600,
                color: theme.getMutedColor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value.split('.').first,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGridItem(String label, String value, {required bool isGreen}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: isGreen ? const Color(0xFF86EFAC) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String? resetLabel, int? countBadge}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w800,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 1,
              ),
            ),
            if (countBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF134E5E) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$countBadge',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              resetLabel ?? 'Reset',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? prefix,
    String? suffix,
    String? hint,
    String? errorText,
  }) {
    final theme = widget.theme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: hasError ? Colors.red : theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  errorText,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w700,
              color: theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              prefixText: prefix != null ? '$prefix ' : null,
              suffixText: suffix != null ? ' $suffix' : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ),
        if (hint != null && !hasError) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w700,
                color: theme.getTextColor(context),
              ),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String emoji, String label, String value, String sub) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: theme.getMutedColor(context), letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow({required String label, required String value, required ChecklistStatus status}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    if (status == ChecklistStatus.success) {
      statusColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    } else if (status == ChecklistStatus.warning) {
      statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    } else {
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w700, color: theme.getTextColor(context)),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(String key, String val, bool isDark, {Color? statusColor}) {
    final kColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
    final vColor = statusColor ?? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D));
    final bColor = isDark ? const Color(0xFF15803D).withValues(alpha: 0.3) : const Color(0xFFDCFCE7);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bColor, width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: kColor)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: vColor)),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard(String emoji, String title, String subtitle) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.getMutedColor(context).withValues(alpha: 0.18),
            size: 16,
          ),
        ],
      ),
    );
  }
}

