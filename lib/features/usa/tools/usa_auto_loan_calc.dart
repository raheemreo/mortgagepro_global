// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_auto_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../../widgets/ads/native_ad_widget.dart';

class USAAutoLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAAutoLoanCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAAutoLoanCalc> createState() => _USAAutoLoanCalcState();
}

class _USAAutoLoanCalcState extends ConsumerState<USAAutoLoanCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  // Vehicle types presets
  static const _vtypeData = {
    'new': _VehiclePreset(
      title: 'New Vehicle Financing',
      sub: 'Avg new car price: \$48,401 (Kelley Blue Book)',
      priceHint: 'Avg new: \$48,401',
      aprHint: 'Avg new: 7.18%',
      price: 48401.0,
      apr: 7.18,
    ),
    'used': _VehiclePreset(
      title: 'Used Vehicle Financing',
      sub: 'Avg used car price: \$28,544 (Kelley Blue Book)',
      priceHint: 'Avg used: \$28,544',
      aprHint: 'Avg used: 11.54%',
      price: 28544.0,
      apr: 11.54,
    ),
    'truck': _VehiclePreset(
      title: 'Truck / SUV Financing',
      sub: 'Avg new truck/SUV price: \$56,800',
      priceHint: 'Avg truck: \$56,800',
      aprHint: 'Avg truck: 7.54%',
      price: 56800.0,
      apr: 7.54,
    ),
    'ev': _VehiclePreset(
      title: 'Electric Vehicle Financing',
      sub: 'Avg EV price: \$58,940 + up to \$7,500 tax credit',
      priceHint: 'Avg EV: \$58,940',
      aprHint: 'Avg EV: 6.89%',
      price: 58940.0,
      apr: 6.89,
    ),
    'refi': _VehiclePreset(
      title: 'Auto Loan Refinance',
      sub: 'Refinance your existing auto loan for a lower rate',
      priceHint: 'Current balance',
      aprHint: 'New refi rate',
      price: 22000.0,
      apr: 6.49,
    ),
  };

  String _selectedVtype = 'new';

  // Input Controllers
  final _priceController = TextEditingController(text: '48401');
  final _downPmtController = TextEditingController(text: '5000');
  final _tradeInController = TextEditingController(text: '0');
  final _aprController = TextEditingController(text: '7.18');

  final _salesTaxController = TextEditingController(text: '5.75');
  final _dealerFeesController = TextEditingController(text: '500');
  final _regFeeController = TextEditingController(text: '250');
  final _rebateController = TextEditingController(text: '0');

  int _selectedTerm = 48;
  bool _rollTaxFees = false;
  bool _showResults = false;

  @override
  void dispose() {
    _priceController.dispose();
    _downPmtController.dispose();
    _tradeInController.dispose();
    _aprController.dispose();
    _salesTaxController.dispose();
    _dealerFeesController.dispose();
    _regFeeController.dispose();
    _rebateController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    double defaultVal = 0.0;
    if (c == _priceController) {
      defaultVal = _vtypeData[_selectedVtype]?.price ?? 48401.0;
    } else if (c == _downPmtController) {
      defaultVal = 5000.0;
    } else if (c == _aprController) {
      defaultVal = _vtypeData[_selectedVtype]?.apr ?? 7.18;
    } else if (c == _salesTaxController) {
      defaultVal = 5.75;
    } else if (c == _dealerFeesController) {
      defaultVal = 500.0;
    } else if (c == _regFeeController) {
      defaultVal = 250.0;
    } else if (c == _rebateController) {
      defaultVal = _selectedVtype == 'ev' ? 7500.0 : 0.0;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _selectVtype(String type) {
    setState(() {
      _selectedVtype = type;
      final d = _vtypeData[type]!;
      _priceController.text = d.price.toStringAsFixed(0);
      _aprController.text = d.apr.toStringAsFixed(2);
      if (type == 'ev') {
        _rebateController.text = '7500';
      } else {
        _rebateController.text = '0';
      }
    });
  }

  double _monthlyPayment(double principal, double annualRate, int months) {
    final r = annualRate / 100 / 12;
    if (r == 0) return principal / months;
    return principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
  }

  void _resetInputs() {
    setState(() {
      _priceController.clear();
      _downPmtController.clear();
      _tradeInController.clear();
      _aprController.clear();
      _salesTaxController.clear();
      _dealerFeesController.clear();
      _regFeeController.clear();
      _rebateController.clear();
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
      _selectedVtype = 'new';
      _priceController.text = '48401';
      _downPmtController.text = '5000';
      _tradeInController.text = '0';
      _aprController.text = '7.18';
      _salesTaxController.text = '5.75';
      _dealerFeesController.text = '500';
      _regFeeController.text = '250';
      _rebateController.text = '0';
      _selectedTerm = 48;
      _rollTaxFees = false;
      _showResults = false;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _priceController.text = (calc.inputs['VehiclePrice'] ?? 48401.0).toStringAsFixed(0);
      _downPmtController.text = (calc.inputs['DownPayment'] ?? 5000.0).toStringAsFixed(0);
      _tradeInController.text = (calc.inputs['TradeIn'] ?? 0.0).toStringAsFixed(0);
      _aprController.text = (calc.inputs['InterestRate'] ?? 7.18).toStringAsFixed(2);
      _salesTaxController.text = (calc.inputs['SalesTaxPct'] ?? 5.75).toStringAsFixed(2);
      _dealerFeesController.text = (calc.inputs['DocFees'] ?? 500.0).toStringAsFixed(0);
      _regFeeController.text = (calc.inputs['RegFee'] ?? 250.0).toStringAsFixed(0);
      _rebateController.text = (calc.inputs['Rebate'] ?? 0.0).toStringAsFixed(0);
      _selectedTerm = (calc.inputs['LoanTermMonths'] ?? 48.0).toInt();
      _rollTaxFees = (calc.inputs['RollTaxFees'] ?? 0.0) == 1.0;

      final typeIdx = (calc.inputs['VehicleTypeIndex'] ?? 0.0).toInt();
      const types = ['new', 'used', 'truck', 'ev', 'refi'];
      if (typeIdx >= 0 && typeIdx < types.length) {
        _selectedVtype = types[typeIdx];
      }

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

  void _saveCalculation() async {
    final price = _val(_priceController);
    final down = _val(_downPmtController);
    final tradeIn = _val(_tradeInController);
    final apr = _val(_aprController);
    final taxRate = _val(_salesTaxController);
    final docFees = _val(_dealerFeesController);
    final regFee = _val(_regFeeController);
    final rebate = _val(_rebateController);

    final salesTaxAmt = max(0.0, price - rebate) * (taxRate / 100);
    final feesTotal = docFees + regFee;
    final totalExtra = salesTaxAmt + feesTotal;

    final netPrice = price - down - tradeIn - rebate;
    final financed = max(0.0, _rollTaxFees ? netPrice + totalExtra : netPrice);

    final pmt = _monthlyPayment(financed, apr, _selectedTerm);
    final totalPaid = pmt * _selectedTerm;
    final totalInt = totalPaid - financed;
    final allIn = totalPaid + (_rollTaxFees ? 0.0 : totalExtra) + down + tradeIn;

    final labelCtrl = TextEditingController(text: 'Auto Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_auto_loan_calc/save'),
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
              'Saving: Payment ${CurrencyFormatter.compact(pmt, symbol: '\$')}/mo · Price: ${CurrencyFormatter.compact(price, symbol: '\$')} · Financed: ${CurrencyFormatter.compact(financed, symbol: '\$')}',
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
                hintText: 'Label (e.g. My SUV Loan)',
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
          : 'Auto Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Auto Loan',
        inputs: {
          'VehiclePrice': price,
          'DownPayment': down,
          'TradeIn': tradeIn,
          'InterestRate': apr,
          'LoanTermMonths': _selectedTerm.toDouble(),
          'SalesTaxPct': taxRate,
          'DocFees': docFees,
          'RegFee': regFee,
          'Rebate': rebate,
          'RollTaxFees': _rollTaxFees ? 1.0 : 0.0,
          'VehicleTypeIndex': _selectedVtype == 'new'
              ? 0.0
              : (_selectedVtype == 'used'
                  ? 1.0
                  : (_selectedVtype == 'truck'
                      ? 2.0
                      : (_selectedVtype == 'ev' ? 3.0 : 4.0))),
        },
        results: {
          'MonthlyPayment': pmt,
          'TotalPrincipal': financed,
          'TotalInterest': totalInt,
          'TotalTaxFees': totalExtra,
          'TotalLoanCost': allIn,
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

    void _calculate() {
    final errors = <String, String>{};
    final val_price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_price <= 0) errors['price'] = 'Please enter a valid amount';
    final val_downPmt = double.tryParse(_downPmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_tradeIn = double.tryParse(_tradeInController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_apr = double.tryParse(_aprController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_apr <= 0) errors['apr'] = 'Please enter a valid amount';
    final val_salesTax = double.tryParse(_salesTaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_dealerFees = double.tryParse(_dealerFeesController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_regFee = double.tryParse(_regFeeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_rebate = double.tryParse(_rebateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() {
      _calcSnapshot[_priceController] = val_price;
      _calcSnapshot[_downPmtController] = val_downPmt;
      _calcSnapshot[_tradeInController] = val_tradeIn;
      _calcSnapshot[_aprController] = val_apr;
      _calcSnapshot[_salesTaxController] = val_salesTax;
      _calcSnapshot[_dealerFeesController] = val_dealerFees;
      _calcSnapshot[_regFeeController] = val_regFee;
      _calcSnapshot[_rebateController] = val_rebate;
      _calcSnapshot['_selectedVtype'] = _selectedVtype;
      _calcSnapshot['_selectedTerm'] = _selectedTerm;
      _calcSnapshot['_rollTaxFees'] = _rollTaxFees;
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

  @override
  Widget build(BuildContext context) {
    final calcSelectedVtype = _showResults ? (_calcSnapshot['_selectedVtype'] ?? _selectedVtype) : _selectedVtype;
    final calcSelectedTerm = _showResults ? (_calcSnapshot['_selectedTerm'] ?? _selectedTerm) : _selectedTerm;
    final calcRollTaxFees = _showResults ? (_calcSnapshot['_rollTaxFees'] ?? _rollTaxFees) : _rollTaxFees;

    final isDirty = _showResults && (
      _selectedVtype != _calcSnapshot['_selectedVtype'] ||
      _selectedTerm != _calcSnapshot['_selectedTerm'] ||
      _rollTaxFees != _calcSnapshot['_rollTaxFees'] ||
      double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_priceController] ?? 0.0) ||
      double.tryParse(_downPmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_downPmtController] ?? 0.0) ||
      double.tryParse(_tradeInController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_tradeInController] ?? 0.0) ||
      double.tryParse(_aprController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_aprController] ?? 0.0) ||
      double.tryParse(_salesTaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_salesTaxController] ?? 0.0) ||
      double.tryParse(_dealerFeesController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_dealerFeesController] ?? 0.0) ||
      double.tryParse(_regFeeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_regFeeController] ?? 0.0) ||
      double.tryParse(_rebateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_rebateController] ?? 0.0)
    );

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final preset = _vtypeData[calcSelectedVtype]!;

    // Inputs
    final price = _val(_priceController);
    final down = _val(_downPmtController);
    final tradeIn = _val(_tradeInController);
    final apr = _val(_aprController);
    final taxRate = _val(_salesTaxController);
    final docFees = _val(_dealerFeesController);
    final regFee = _val(_regFeeController);
    final rebate = _val(_rebateController);

    // Calculations
    final salesTaxAmt = max(0.0, price - rebate) * (taxRate / 100);
    final feesTotal = docFees + regFee;
    final totalExtra = salesTaxAmt + feesTotal;

    final netPrice = price - down - tradeIn - rebate;
    final financed = max(0.0, calcRollTaxFees ? netPrice + totalExtra : netPrice);

    final pmt = _monthlyPayment(financed, apr, calcSelectedTerm);
    final totalPaid = pmt * calcSelectedTerm;
    final totalInt = totalPaid - financed;
    final allIn = totalPaid + (calcRollTaxFees ? 0.0 : totalExtra) + down + tradeIn;

    // Proportions for donut
    final totalDonut = financed + totalInt + totalExtra;
    final prinPct = totalDonut > 0 ? financed / totalDonut : 0.0;
    final intPct = totalDonut > 0 ? totalInt / totalDonut : 0.0;
    final feesPct = totalDonut > 0 ? totalExtra / totalDonut : 0.0;

    // Amortization snapshot
    final r = apr / 100 / 12;
    double bal = financed;
    final amortRows = <_AutoAmortRow>[];
    final years = (calcSelectedTerm / 12.0).ceil();
    for (int y = 1; y <= years; y++) {
      final moStart = (y - 1) * 12 + 1;
      final moEnd = min<num>(y * 12, calcSelectedTerm).toInt();
      double yInt = 0.0;
      double yPrin = 0.0;
      double yPmt = 0.0;
      for (int m = moStart; m <= moEnd; m++) {
        final intPart = bal * r;
        final prinPart = min(pmt - intPart, bal);
        yInt += intPart;
        yPrin += prinPart;
        yPmt += pmt;
        bal = max(0.0, bal - prinPart);
      }
      amortRows.add(_AutoAmortRow(
        year: y,
        payment: yPmt,
        interest: yInt,
        principal: yPrin,
        balance: bal,
      ));
    }

    // Watch saved auto loan calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Auto Loan').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF0F766E)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildRsCell('New Car', '7.18%', 'Avg APR', isUp: false)),
              Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.14)),
              Expanded(child: _buildRsCell('Used Car', '11.54%', 'Avg APR', isUp: true)),
              Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.14)),
              Expanded(child: _buildRsCell('Credit Union', '6.84%', 'New Car')),
              Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.14)),
              Expanded(child: _buildRsCell('Fed Funds', '5.33%', 'FOMC', isGold: true)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Vehicle Type', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Vehicle chips
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTypeChip('new', '🚗 New Car'),
              _buildTypeChip('used', '🚙 Used Car'),
              _buildTypeChip('truck', '🛻 Truck/SUV'),
              _buildTypeChip('ev', '⚡ Electric (EV)'),
              _buildTypeChip('refi', '🔄 Refi Auto'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Details Card
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏎️', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.title,
                          style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.getTextColor(context)),
                        ),
                        Text(
                          preset.sub,
                          style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildInputField('Vehicle Price', _priceController, preset.priceHint, errorText: _errors['price']),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Down Payment', _downPmtController, '', errorText: _errors['downPmt']),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Trade-In Value', _tradeInController, '', errorText: _errors['tradeIn']),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // APR Input & Slider
              _buildInputField('Loan APR (%)', _aprController, preset.aprHint, suffix: '%', errorText: _errors['apr']),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF0F766E),
                  thumbColor: const Color(0xFF0F766E),
                  inactiveTrackColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                  overlayColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: apr.clamp(0.0, 25.0),
                  min: 0,
                  max: 25,
                  onChanged: (v) {
                    setState(() {
                      _aprController.text = v.toStringAsFixed(2);
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0%', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                  Text('Best credit → lowest APR', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                  Text('25%', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 12),

              // Term Selector
              _buildSelectorRow<int>(
                label: 'Loan Term',
                value: _selectedTerm,
                items: [24, 36, 48, 60, 72, 84],
                labelBuilder: (v) => '$v mo',
                onChanged: (v) => setState(() {
                  this._selectedTerm = v;
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Taxes & Fees', onReset: null),
        const SizedBox(height: 8),

        // Taxes & Fees Card
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏛️ ', style: TextStyle(fontSize: 18)),
                  Text(
                    'State Taxes & Dealer Fees',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Sales Tax', _salesTaxController, '', suffix: '%', errorText: _errors['salesTax']),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Doc / Dealer Fees', _dealerFeesController, '', errorText: _errors['dealerFees']),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Registration Fee', _regFeeController, '', errorText: _errors['regFee']),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Rebate / Incentive', _rebateController, '', errorText: _errors['rebate']),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Roll costs segment
              Text(
                'FINANCE TAX & FEES?',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildSegButton('Pay Upfront', !_rollTaxFees, () => setState(() {
                      _rollTaxFees = false;
                    })),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSegButton('Roll Into Loan', _rollTaxFees, () => setState(() {
                      _rollTaxFees = true;
                    })),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
          onTap: _calculate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: isDirty ? 0.45 : 0.25),
                        blurRadius: isDirty ? 18 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🏎️ Calculate Auto Loan',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Save button right below calculate
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    border: Border.all(color: const Color(0xFF0F766E), width: 1.5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💾 ', style: TextStyle(color: Color(0xFF0F766E), fontSize: 13)),
                      Text(
                        'Save This Calculation',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Today\'s Auto Loan Rates', onReset: null),
        const SizedBox(height: 8),

        // Horizontal rates
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRateCard('PenFed CU', '5.99%', 'New · 36-mo', 'Lowest', const Color(0xFFCCFBF1), const Color(0xFF0F766E)),
              _buildRateCard('Navy Fed CU', '6.29%', 'New · 60-mo', 'Top CU', const Color(0xFFCCFBF1), const Color(0xFF0F766E)),
              _buildRateCard('LightStream', '6.49%', 'New · Any term', 'Low', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildRateCard('Chase Auto', '7.09%', 'New · 60-mo', 'Avg', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildRateCard('Capital One', '7.54%', 'New / Used', 'Avg', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildRateCard('Wells Fargo', '7.69%', 'New · 60-mo', 'Avg', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
            ],
          ),
        ),

        // Saved Calculations Section
        if (savedCalcs.isNotEmpty) ...[
          const SizedBox(height: 20),
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
                              style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Price: ${CurrencyFormatter.compact(calc.inputs['VehiclePrice'] ?? 0.0, symbol: '\$')} · APR: ${(calc.inputs['InterestRate'] ?? 0.0).toStringAsFixed(2)}% · ${calc.inputs['LoanTermMonths']?.toInt() ?? 0} mo',
                              style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${CurrencyFormatter.compact(calc.results['MonthlyPayment'] ?? 0.0, symbol: '\$')}/mo',
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.red,
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
        ],

        const SizedBox(height: 20),

        if (!_showResults)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('🏎️', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Your Vehicle Details Above',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll calculate your monthly payment,\ntotal interest, and full cost breakdown.',
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
                            'Inputs have changed. Tap "Calculate Auto Loan" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF0B1D3A), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildSectionHeader('Your Results', onReset: null),
                const SizedBox(height: 8),

                // Monthly Payment Hero
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY AUTO PAYMENT',
                        style: AppTextStyles.dmSans(size: 9, color: Colors.white70, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(pmt, symbol: '\$').split('.').first,
                        style: AppTextStyles.dmSans(size: 38, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'per month · $calcSelectedTerm-month loan @ ${apr.toStringAsFixed(2)}% APR',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white60),
                      ),
                      const SizedBox(height: 14),

                      // Hero stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroStatBox('Total Interest', CurrencyFormatter.format(totalInt, symbol: '\$').split('.').first),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStatBox('Total Cost', CurrencyFormatter.format(allIn, symbol: '\$').split('.').first),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStatBox('Loan Amount', CurrencyFormatter.format(financed, symbol: '\$').split('.').first),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Cost Breakdown Card with Donut Chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💰 Total Cost Breakdown',
                        style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 14),

                      // Donut SVG representation in CustomPaint
                      Row(
                        children: [
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CustomPaint(
                              painter: _DonutChartPainter(
                                principalPct: prinPct,
                                interestPct: intPct,
                                feesPct: feesPct,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                _buildLegendRow('Principal (Vehicle)', financed, const Color(0xFF0F766E)),
                                _buildLegendRow('Total Interest', totalInt, const Color(0xFFB91C1C)),
                                _buildLegendRow('Tax & Fees', totalExtra, const Color(0xFFD97706)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildBreakdownRow('Vehicle Price', price, isDot: true, dotColor: const Color(0xFF0F766E)),
                      _buildBreakdownRow('Down + Trade-In', -(down + tradeIn + rebate), isMuted: true),
                      _buildBreakdownRow('Amount Financed', financed, isDot: true, dotColor: const Color(0xFF0F766E)),
                      _buildBreakdownRow('Sales Tax', salesTaxAmt, isDot: true, dotColor: const Color(0xFFFCA5A5)),
                      _buildBreakdownRow('Dealer + Reg Fees', feesTotal, isDot: true, dotColor: const Color(0xFFD97706)),
                      _buildBreakdownRow('Total Interest Paid', totalInt, isDot: true, dotColor: const Color(0xFFB91C1C), valColor: const Color(0xFFB91C1C)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Out-of-Pocket',
                              style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                            Text(
                              CurrencyFormatter.format(allIn, symbol: '\$').split('.').first,
                              style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Amortization Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📅 Yearly Amortization',
                            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                          ),
                          Text(
                            'P&I breakdown',
                            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.1),
                          2: FlexColumnWidth(1.1),
                          3: FlexColumnWidth(1.1),
                          4: FlexColumnWidth(1.2),
                        },
                        children: [
                          TableRow(
                            children: [
                              _th('Year', align: TextAlign.left),
                              _th('Payment'),
                              _th('Interest'),
                              _th('Principal'),
                              _th('Balance'),
                            ],
                          ),
                          ...amortRows.map((row) {
                            return TableRow(
                              children: [
                                _td('Year ${row.year}', align: TextAlign.left),
                                _td(CurrencyFormatter.format(row.payment, symbol: '').split('.').first),
                                _td(CurrencyFormatter.format(row.interest, symbol: '').split('.').first, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
                                _td(CurrencyFormatter.format(row.principal, symbol: '').split('.').first, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)),
                                _td(CurrencyFormatter.format(row.balance, symbol: '').split('.').first),
                              ],
                            );
                          }),
                          // Totals Row
                          TableRow(
                            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(6)),
                            children: [
                              _td('Total', align: TextAlign.left, weight: FontWeight.w800),
                              _td(CurrencyFormatter.format(pmt * _selectedTerm, symbol: '').split('.').first, weight: FontWeight.w800),
                              _td(CurrencyFormatter.format(totalInt, symbol: '').split('.').first, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C), weight: FontWeight.w800),
                              _td(CurrencyFormatter.format(financed, symbol: '').split('.').first, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), weight: FontWeight.w800),
                              _td('\$0', weight: FontWeight.w800),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const NativeAdWidget(
                  screenName: 'usa_auto_loan_calc',
                  adType: 'mediumCard',
                ),
                const SizedBox(height: 32),

                // Related tools
                _buildSectionHeader('Related Tools', onReset: null),
                const SizedBox(height: 8),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    _buildRelatedCard('📊', 'Lease vs Buy', 'True cost comparison', null, const Color(0xFF0F766E), const Color(0xFF0D9488)),
                    _buildRelatedCard('💳', 'Credit Score', 'APR impact by FICO', '620–850', const Color(0xFF0B1D3A), const Color(0xFF1B3F72)),
                    _buildRelatedCard('⚡', 'EV Tax Credit', 'IRS §30D · up to \$7,500', '2026 Rules', null, null),
                    _buildRelatedCard('🔄', 'Refinance Auto', 'Lower your current rate', null, const Color(0xFFB91C1C), const Color(0xFF991B1B)),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('💡 Auto Loan Insights', onReset: null),
                const SizedBox(height: 8),

                Column(
                  children: [
                    _buildInsightCard('🏦', 'Get Pre-Approved Before the Dealership', 'Credit unions like PenFed and Navy Federal routinely offer 1–2% lower APR than dealer financing. Getting pre-approved gives you leverage to negotiate.'),
                    const SizedBox(height: 9),
                    _buildInsightCard('⚡', 'EV Tax Credit: Up to \$7,500', 'The IRS §30D Clean Vehicle Credit offers up to \$7,500 for qualifying new EVs in 2026. Income limits apply: \$150K single / \$300K married. MSRP cap: \$80K SUV/truck, \$55K sedan.'),
                    const SizedBox(height: 9),
                    _buildInsightCard('📉', 'Shorter Terms Save Thousands', 'A 48-month loan at 7.18% on \$43,000 saves ~\$2,800 in interest vs. a 72-month loan, though monthly payments are higher. Only take 72–84 months if cash flow is tight.'),
                    const SizedBox(height: 9),
                    _buildInsightCard('🎯', '20/4/10 Rule of Thumb', 'Put 20% down, finance for no more than 4 years, and keep total vehicle expenses (payment + insurance) under 10% of gross monthly income for a financially sound purchase.'),
                  ],
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Auto loan rates from NCUA, Experian State of the Automotive Finance Market Q1 2026, and individual lender websites. Average new car price from Kelley Blue Book June 2026. Results are estimates for educational purposes only.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dmSans(
                      size: 9.0,
                      color: theme.getMutedColor(context),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRsCell(String label, String value, String note, {bool? isUp, bool isGold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            color: Colors.white.withValues(alpha: 0.48),
            weight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 15,
                weight: FontWeight.w800,
                color: isGold
                    ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFFCD34D))
                    : Colors.white,
              ),
            ),
            if (isUp != null) ...[
              const SizedBox(width: 2),
              Text(
                isUp ? '↑' : '↓',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w900,
                  color: isUp ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 1),
        Text(
          note,
          style: AppTextStyles.dmSans(
            size: 8,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
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

  Widget _buildTypeChip(String key, String label) {
    final isActive = key == _selectedVtype;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _selectVtype(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
          decoration: BoxDecoration(
            gradient: isActive ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]) : null,
            color: isActive ? null : widget.theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? const Color(0xFF0D9488) : widget.theme.getBorderColor(context),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w700,
              color: isActive ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {String? suffix, String? errorText}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.dmSans(
                size: 9.5,
                weight: FontWeight.w700,
                color: hasError ? Colors.red : theme.getMutedColor(context),
                letterSpacing: 0.5,
              ),
            ),
            if (hasError)
              Text(
                errorText,
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: Colors.red,
                ),
              )
            else if (hint.isNotEmpty)
              Text(
                hint,
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w600,
                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
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
              prefixText: suffix == '%' ? null : '\$ ',
              suffixText: suffix != null ? ' $suffix' : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
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
        const SizedBox(height: 6),
        Row(
          children: items.map((item) {
            final isActive = item == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isActive ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]) : null,
                    color: isActive ? null : theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isActive ? const Color(0xFF0D9488) : theme.getBorderColor(context),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelBuilder(item),
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: isActive ? Colors.white : theme.getMutedColor(context),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSegButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]) : null,
          color: isActive ? null : widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w700,
            color: isActive ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRateCard(String bank, String rate, String type, String tag, Color tagBg, Color tagTextColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 118,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 11),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bank,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context), letterSpacing: 0.4),
          ),
          Text(
            rate,
            style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
          ),
          Text(
            type,
            style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? (tagBg == const Color(0xFFCCFBF1)
                      ? const Color(0xFF0F3A2E)
                      : (tagBg == const Color(0xFFEFF6FF) ? const Color(0xFF0B1E3F) : const Color(0xFF3F1616)))
                  : tagBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: AppTextStyles.dmSans(
                size: 8.5,
                weight: FontWeight.w700,
                color: isDark
                    ? (tagBg == const Color(0xFFCCFBF1)
                        ? const Color(0xFF2DD4BF)
                        : (tagBg == const Color(0xFFEFF6FF) ? const Color(0xFF60A5FA) : const Color(0xFFF87171)))
                    : tagTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, double val, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color finalColor = color;
    if (isDark) {
      if (color == const Color(0xFFB91C1C)) {
        finalColor = const Color(0xFFF87171);
      } else if (color == const Color(0xFFD97706)) {
        finalColor = const Color(0xFFFBBF24);
      } else if (color == const Color(0xFF0F766E)) {
        finalColor = const Color(0xFF0D9488);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: finalColor, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context)),
            ),
          ),
          Text(
            CurrencyFormatter.format(val, symbol: '\$').split('.').first,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double val, {bool isDot = false, Color? dotColor, bool isMuted = false, Color? valColor}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color? finalValColor = valColor;
    if (isDark && valColor == const Color(0xFFB91C1C)) {
      finalValColor = const Color(0xFFF87171);
    }
    Color? finalDotColor = dotColor;
    if (isDark) {
      if (dotColor == const Color(0xFFB91C1C)) {
        finalDotColor = const Color(0xFFF87171);
      } else if (dotColor == const Color(0xFFD97706)) {
        finalDotColor = const Color(0xFFFBBF24);
      } else if (dotColor == const Color(0xFF0F766E)) {
        finalDotColor = const Color(0xFF0D9488);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.getBorderColor(context), width: 0.5)),
        ),
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isDot) ...[
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: finalDotColor ?? theme.primaryColor, shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: AppTextStyles.dmSans(size: 11.5, weight: isMuted ? FontWeight.w500 : FontWeight.w600, color: theme.getMutedColor(context)),
                ),
              ],
            ),
            Text(
              (val < 0 ? '– ' : '') + CurrencyFormatter.format(val.abs(), symbol: '\$').split('.').first,
              style: AppTextStyles.dmSans(size: 13, weight: isMuted ? FontWeight.w600 : FontWeight.w800, color: isMuted ? theme.getMutedColor(context) : (finalValColor ?? theme.getTextColor(context))),
            ),
          ],
        ),
      ),
    );
  }

  TableCell _th(String text, {TextAlign align = TextAlign.right}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text.toUpperCase(),
          textAlign: align,
          style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: widget.theme.getMutedColor(context), letterSpacing: 0.5),
        ),
      ),
    );
  }

  TableCell _td(String text, {TextAlign align = TextAlign.right, Color? color, FontWeight weight = FontWeight.w700}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          textAlign: align,
          style: AppTextStyles.dmSans(size: 11, weight: weight, color: color ?? widget.theme.getTextColor(context)),
        ),
      ),
    );
  }

  Widget _buildRelatedCard(String emoji, String title, String desc, String? tag, Color? bg1, Color? bg2) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGrd = bg1 != null && bg2 != null;
    final dec = isGrd
        ? BoxDecoration(
            gradient: LinearGradient(colors: [bg1, bg2]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          )
        : BoxDecoration(
            color: widget.theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.getBorderColor(context)),
          );

    final titleColor = isGrd ? Colors.white : widget.theme.getTextColor(context);
    final descColor = isGrd ? Colors.white70 : widget.theme.getMutedColor(context);
    final arrowColor = isGrd ? Colors.white.withValues(alpha: 0.22) : widget.theme.getMutedColor(context).withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: dec,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isGrd ? Colors.white.withValues(alpha: 0.14) : widget.theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: titleColor),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.dmSans(size: 9.5, color: descColor),
              ),
              if (tag != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1E3F) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.dmSans(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              '›',
              style: TextStyle(
                fontSize: 20,
                color: arrowColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String icon, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white70, letterSpacing: 0.3),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _VehiclePreset {
  final String title;
  final String sub;
  final String priceHint;
  final String aprHint;
  final double price;
  final double apr;

  const _VehiclePreset({
    required this.title,
    required this.sub,
    required this.priceHint,
    required this.aprHint,
    required this.price,
    required this.apr,
  });
}

class _AutoAmortRow {
  final int year;
  final double payment;
  final double interest;
  final double principal;
  final double balance;

  const _AutoAmortRow({
    required this.year,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.balance,
  });
}

class _DonutChartPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final double feesPct;
  final bool isDark;

  _DonutChartPainter({required this.principalPct, required this.interestPct, required this.feesPct, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 12.0;

    final paintBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    if (principalPct <= 0 && interestPct <= 0 && feesPct <= 0) return;

    double startAngle = -pi / 2;

    if (principalPct > 0) {
      final sweep = 2 * pi * principalPct;
      final paintPrin = Paint()
        ..color = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintPrin);
      startAngle += sweep;
    }

    if (interestPct > 0) {
      final sweep = 2 * pi * interestPct;
      final paintInt = Paint()
        ..color = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintInt);
      startAngle += sweep;
    }

    if (feesPct > 0) {
      final sweep = 2 * pi * feesPct;
      final paintFees = Paint()
        ..color = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintFees);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

