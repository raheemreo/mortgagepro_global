// lib/features/uk/tools/uk_buy_to_let.dart

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

class UKBuyToLet extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKBuyToLet({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKBuyToLet> createState() => _UKBuyToLetState();
}

class _UKBuyToLetState extends ConsumerState<UKBuyToLet> {
  final _priceController = TextEditingController(text: '280000');
  final _depPctController = TextEditingController(text: '25');
  final _btlRateController = TextEditingController(text: '5.39');
  final _btlTermController = TextEditingController(text: '25');
  final _rentController = TextEditingController(text: '1400');
  final _voidsController = TextEditingController(text: '1');
  final _agentFeeController = TextEditingController(text: '10');
  final _maintController = TextEditingController(text: '1200');
  final _insureController = TextEditingController(text: '400');
  final _serviceController = TextEditingController(text: '0');
  final _taxRateController = TextEditingController(text: '40');

  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _priceController.text = (inputs['price'] ?? 280000.0).toStringAsFixed(0);
      _depPctController.text = (inputs['depPct'] ?? 25.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _btlRateController.text = (inputs['btlRate'] ?? 5.39).toString();
      _btlTermController.text = (inputs['btlTerm'] ?? 25.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _rentController.text = (inputs['rent'] ?? 1400.0).toStringAsFixed(0);
      _voidsController.text = (inputs['voids'] ?? 1.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _agentFeeController.text = (inputs['agentFee'] ?? 10.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _maintController.text = (inputs['maint'] ?? 1200.0).toStringAsFixed(0);
      _insureController.text = (inputs['insure'] ?? 400.0).toStringAsFixed(0);
      _serviceController.text = (inputs['service'] ?? 0.0).toStringAsFixed(0);
      _taxRateController.text = (inputs['taxRate'] ?? 40.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _calculate();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _depPctController.dispose();
    _btlRateController.dispose();
    _btlTermController.dispose();
    _rentController.dispose();
    _voidsController.dispose();
    _agentFeeController.dispose();
    _maintController.dispose();
    _insureController.dispose();
    _serviceController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c, double defaultVal) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};

    final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (price <= 0) errors['price'] = 'Enter valid purchase price';

    final depPct = double.tryParse(_depPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (depPct <= 0 || depPct > 100) errors['depPct'] = 'Enter valid deposit percentage';

    final btlRate = double.tryParse(_btlRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (btlRate <= 0 || btlRate > 25) errors['btlRate'] = 'Enter valid rate (0.1% - 25%)';

    final btlTerm = double.tryParse(_btlTermController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (btlTerm <= 0 || btlTerm > 50) errors['btlTerm'] = 'Enter term (1 - 50 years)';

    final rent = double.tryParse(_rentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (rent <= 0) errors['rent'] = 'Enter valid monthly rent';

    final voids = double.tryParse(_voidsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (voids < 0) errors['voids'] = 'Enter valid void months';

    final agentFee = double.tryParse(_agentFeeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (agentFee < 0) errors['agentFee'] = 'Enter valid agent fee';

    final maint = double.tryParse(_maintController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (maint < 0) errors['maint'] = 'Enter valid maintenance cost';

    final insure = double.tryParse(_insureController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (insure < 0) errors['insure'] = 'Enter valid insurance cost';

    final service = double.tryParse(_serviceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (service < 0) errors['service'] = 'Enter valid service charge';

    final taxRate = double.tryParse(_taxRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (taxRate < 0 || taxRate > 100) errors['taxRate'] = 'Enter valid tax rate';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_priceController] = price;
      _calcSnapshot[_depPctController] = depPct;
      _calcSnapshot[_btlRateController] = btlRate;
      _calcSnapshot[_btlTermController] = btlTerm;
      _calcSnapshot[_rentController] = rent;
      _calcSnapshot[_voidsController] = voids;
      _calcSnapshot[_agentFeeController] = agentFee;
      _calcSnapshot[_maintController] = maint;
      _calcSnapshot[_insureController] = insure;
      _calcSnapshot[_serviceController] = service;
      _calcSnapshot[_taxRateController] = taxRate;
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

  void _resetInputs() {
    setState(() {
      _priceController.text = '280000';
      _depPctController.text = '25';
      _btlRateController.text = '5.39';
      _btlTermController.text = '25';
      _rentController.text = '1400';
      _voidsController.text = '1';
      _agentFeeController.text = '10';
      _maintController.text = '1200';
      _insureController.text = '400';
      _serviceController.text = '0';
      _taxRateController.text = '40';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double priceVal = _val(_priceController, 280000);
    final double depPctVal = _val(_depPctController, 25);
    final double btlRateVal = _val(_btlRateController, 5.39);
    final double btlTermVal = _val(_btlTermController, 25);
    final double rentVal = _val(_rentController, 1400);
    final double voidsVal = _val(_voidsController, 1);
    final double agentFeeVal = _val(_agentFeeController, 10);
    final double maintVal = _val(_maintController, 1200);
    final double insureVal = _val(_insureController, 400);
    final double serviceVal = _val(_serviceController, 0);
    final double taxRateVal = _val(_taxRateController, 40);

    final dep = priceVal * depPctVal / 100.0;
    final loan = priceVal - dep;
    final mortPmtIO = loan * (btlRateVal / 100 / 12);
    final annualMortInt = mortPmtIO * 12;

    final grossAnnual = rentVal * 12;
    final voidLoss = rentVal * voidsVal;
    final agentAmt = (grossAnnual - voidLoss) * (agentFeeVal / 100.0);
    final netRental = grossAnnual - voidLoss - agentAmt - maintVal - insureVal - serviceVal;

    // Section 24 calculations
    final taxableIncome = netRental;
    final mortRelief = annualMortInt * 0.2;
    final taxDue = math.max(0.0, taxableIncome * (taxRateVal / 100.0) - mortRelief);
    final afterTaxProfit = netRental - annualMortInt - taxDue;

    final grossYield = priceVal > 0 ? (grossAnnual / priceVal * 100.0) : 0.0;
    final netYield = priceVal > 0 ? (netRental / priceVal * 100.0) : 0.0;
    final cashFlow = (netRental - annualMortInt) / 12.0;
    final roi = dep > 0 ? (afterTaxProfit / dep * 100.0) : 0.0;

    // ICR Lender Tests
    const stressRate = 5.5;
    final stressMortInt = loan * (stressRate / 100.0);
    final icr145 = stressMortInt > 0 ? netRental / (stressMortInt * 1.45) : double.infinity;
    final icr125 = stressMortInt > 0 ? netRental / (stressMortInt * 1.25) : double.infinity;

    final icr145Pass = icr145 >= 1.0;
    final icr125Pass = icr125 >= 1.0;

    // Donut percentages
    final totalAnnual = grossAnnual - voidLoss;
    final mortPct = totalAnnual > 0 ? (annualMortInt / totalAnnual).clamp(0.0, 1.0) : 0.0;
    final costsPct = totalAnnual > 0 ? ((agentAmt + maintVal + insureVal + serviceVal) / totalAnnual).clamp(0.0, 1.0) : 0.0;
    final profitPct = math.max(0.0, 1.0 - mortPct - costsPct);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final btlRateLive  = boeBase + 1.14; // typical BTL spread
    final isLive   = ukRates?.isLive == true;

    final isDirty = _showResults && (
      (double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_priceController] ?? 0.0) ||
      (double.tryParse(_depPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_depPctController] ?? 0.0) ||
      (double.tryParse(_btlRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_btlRateController] ?? 0.0) ||
      (double.tryParse(_btlTermController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_btlTermController] ?? 0.0) ||
      (double.tryParse(_rentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_rentController] ?? 0.0) ||
      (double.tryParse(_voidsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_voidsController] ?? 0.0) ||
      (double.tryParse(_agentFeeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_agentFeeController] ?? 0.0) ||
      (double.tryParse(_maintController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_maintController] ?? 0.0) ||
      (double.tryParse(_insureController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_insureController] ?? 0.0) ||
      (double.tryParse(_serviceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_serviceController] ?? 0.0) ||
      (double.tryParse(_taxRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_taxRateController] ?? 0.0)
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
              Expanded(child: _rateCell('BTL Rate', '${btlRateLive.toStringAsFixed(2)}%', isLive ? 'Live 🟢' : 'Avg 2-yr fix', Colors.redAccent)),
              _divider(),
              Expanded(child: _rateCell('Good Yield', '5–8%', 'Gross target', isDark ? Colors.amber : const Color(0xFFD97706))),
              _divider(),
              Expanded(child: _rateCell('Min Deposit', '25%', 'BTL standard', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('SDLT', '+3%', '2nd property', Colors.redAccent)),
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

        // Property Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(label: 'Purchase Price (£)', controller: _priceController, errorText: _errors['price']),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Deposit (%)', controller: _depPctController, errorText: _errors['depPct'])),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'BTL Rate (%)', controller: _btlRateController, errorText: _errors['btlRate'])),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(label: 'Mortgage Term (Yrs)', controller: _btlTermController, errorText: _errors['btlTerm']),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'RENTAL INCOME',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Rental Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(label: 'Monthly Rent (£)', controller: _rentController, errorText: _errors['rent']),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Void Months/Yr', controller: _voidsController, errorText: _errors['voids'])),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Agent Fee (%)', controller: _agentFeeController, errorText: _errors['agentFee'])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'ANNUAL COSTS & TAX',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Costs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Maintenance (£/yr)', controller: _maintController, errorText: _errors['maint'])),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Insurance (£/yr)', controller: _insureController, errorText: _errors['insure'])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Service Charge (£/yr)', controller: _serviceController, errorText: _errors['service'])),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Tax Rate (%)', controller: _taxRateController, errorText: _errors['taxRate'])),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _calculate,
                  child: Text(
                    'Calculate Investment',
                    style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
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
                      'Inputs have changed. Tap Calculate Investment to refresh results.',
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
                // Result Hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB45309), Color(0xFF92400E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GROSS RENTAL YIELD',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${grossYield.toStringAsFixed(2)}%',
                            style: AppTextStyles.dmSans(
                              size: 40,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ).copyWith(fontFamily: 'Georgia'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final calc = SavedCalc.create(
                                country: 'UK',
                                calcType: 'Buy-to-Let',
                                inputs: {
                                  'price': priceVal,
                                  'depPct': depPctVal,
                                  'btlRate': btlRateVal,
                                  'btlTerm': btlTermVal,
                                  'rent': rentVal,
                                  'voids': voidsVal,
                                  'agentFee': agentFeeVal,
                                  'maint': maintVal,
                                  'insure': insureVal,
                                  'service': serviceVal,
                                  'taxRate': taxRateVal,
                                },
                                results: {
                                  'Gross Yield': grossYield,
                                  'Net Yield': netYield,
                                  'Cash Flow': cashFlow,
                                  'ROI': roi,
                                  'After Tax Profit': afterTaxProfit,
                                },
                                label: '${CurrencyFormatter.compact(priceVal, symbol: '£')} BTL · ${grossYield.toStringAsFixed(1)}% yield',
                                currencyCode: 'GBP',
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              await ref.read(savedProvider.notifier).save(calc);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Buy-to-Let calculation saved'),
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
                                mainAxisSize: MainAxisSize.min,
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
                        'Net yield: ${netYield.toStringAsFixed(2)}% · Cash flow: ${CurrencyFormatter.format(cashFlow, symbol: '£').split('.').first}/mo',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          grossYield >= 7.0
                              ? '🟢 Excellent Yield (Target >7%)'
                              : (grossYield >= 5.0 ? '🟡 Good Yield (Target 5-8%)' : '🔴 Below Target Yield (<5%)'),
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                ResultPanel(
                  primaryColor: widget.theme.primaryColor,
                  rows: [
                    ResultRow(label: 'Monthly Mortgage (IO)', value: mortPmtIO, currencyCode: 'GBP'),
                    ResultRow(
                      label: 'Monthly Cash Flow',
                      value: cashFlow,
                      currencyCode: 'GBP',
                      isHighlighted: cashFlow > 0,
                    ),
                    ResultRow(label: 'Net Yield', value: netYield / 100, isPercent: true),
                    ResultRow(label: 'ROI (Cash-on-Cash)', value: roi / 100, isPercent: true, isHighlighted: roi > 0),
                  ],
                ),
                const SizedBox(height: 16),

                // Donut Chart Card
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
                        'Annual Income Breakdown',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CustomPaint(
                              painter: BtlDonutPainter(
                                mortPct: mortPct,
                                costsPct: costsPct,
                                profitPct: profitPct,
                                isDark: isDark,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '£${(totalAnnual / 1000).toStringAsFixed(0)}k',
                                      style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                                    ),
                                    Text(
                                      'annual',
                                      style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _legendRow(const Color(0xFFC8102E), 'Mortgage', CurrencyFormatter.format(annualMortInt, symbol: '£').split('.').first, textThemeColor),
                                _legendRow(const Color(0xFFB45309), 'Costs', CurrencyFormatter.format(agentAmt + maintVal + insureVal + serviceVal, symbol: '£').split('.').first, textThemeColor),
                                _legendRow(const Color(0xFF059669), 'Profit (after tax)', CurrencyFormatter.format(afterTaxProfit, symbol: '£').split('.').first, textThemeColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // P&L Statement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isDark ? [const Color(0xFF451A03), const Color(0xFF1c0d02)] : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFFCD34D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Annual P&L Statement',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F)),
                      ),
                      const SizedBox(height: 12),
                      _pnlRow('Gross Rental Income', grossAnnual, false),
                      _pnlRow('Void Periods', voidLoss, true),
                      _pnlRow('Letting Agent Fees', agentAmt, true),
                      _pnlRow('Mortgage Interest', annualMortInt, true),
                      _pnlRow('Maintenance', maintVal, true),
                      _pnlRow('Insurance', insureVal, true),
                      _pnlRow('Service Charge', serviceVal, true),
                      Divider(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFCD34D), height: 16),
                      _pnlRow('Net Rental Income', netRental, false, isBold: true),
                      _pnlRow('Tax (Section 24)', taxDue, true),
                      _pnlRow('After-Tax Profit', afterTaxProfit, afterTaxProfit < 0, isBold: true, labelSuffix: afterTaxProfit >= 0 ? '' : ' (Loss)'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stress Tests Card
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
                        '🧪 Lender Stress Tests (ICR)',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 12),
                      _icrRow('145% ICR @ 5.5% (standard)', icr145, icr145Pass),
                      const SizedBox(height: 8),
                      _icrRow('125% ICR @ 5.5% (HRT)', icr125, icr125Pass),
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

  Widget _legendRow(Color color, String label, String value, Color textThemeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)))),
          Text(value, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor)),
        ],
      ),
    );
  }

  Widget _pnlRow(String label, double val, bool isNegative, {bool isBold = false, String labelSuffix = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label + labelSuffix,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
            ),
          ),
          Text(
            (isNegative ? '-' : '') + CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isNegative ? const Color(0xFFC8102E) : const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icrRow(String title, double icr, bool isPass) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isPass
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B));
    final statusBg = isPass
        ? (isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5))
        : (isDark ? const Color(0xFF991B1B) : const Color(0xFFFEE2E2));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPass
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w700, color: statusColor)),
          Row(
            children: [
              Text(
                icr == double.infinity ? 'ICR: N/A' : 'ICR: ${icr.toStringAsFixed(2)}x',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: statusColor),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  isPass ? '✓ Pass' : '✗ Fail',
                  style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
        ],
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

class BtlDonutPainter extends CustomPainter {
  final double mortPct;
  final double costsPct;
  final double profitPct;
  final bool isDark;

  BtlDonutPainter({
    required this.mortPct,
    required this.costsPct,
    required this.profitPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;

    if (mortPct > 0) {
      final sweep = 2 * math.pi * mortPct;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = const Color(0xFFC8102E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
      startAngle += sweep;
    }

    if (costsPct > 0) {
      final sweep = 2 * math.pi * costsPct;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = const Color(0xFFB45309)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
      startAngle += sweep;
    }

    if (profitPct > 0) {
      final sweep = 2 * math.pi * profitPct;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = const Color(0xFF059669)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BtlDonutPainter oldDelegate) {
    return oldDelegate.mortPct != mortPct ||
        oldDelegate.costsPct != costsPct ||
        oldDelegate.profitPct != profitPct ||
        oldDelegate.isDark != isDark;
  }
}
