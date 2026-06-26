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

  double _price = 280000;
  double _depPct = 25;
  double _btlRate = 5.39;
  double _btlTerm = 25;
  double _rent = 1400;
  double _voids = 1;
  double _agentFee = 10;
  double _maint = 1200;
  double _insure = 400;
  double _service = 0;
  double _taxRate = 40;

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
    }
    _calculateValues();
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

  void _calculateValues() {
    setState(() {
      _price = double.tryParse(_priceController.text) ?? 0;
      _depPct = double.tryParse(_depPctController.text) ?? 25;
      _btlRate = double.tryParse(_btlRateController.text) ?? 0;
      _btlTerm = double.tryParse(_btlTermController.text) ?? 25;
      _rent = double.tryParse(_rentController.text) ?? 0;
      _voids = double.tryParse(_voidsController.text) ?? 0;
      _agentFee = double.tryParse(_agentFeeController.text) ?? 0;
      _maint = double.tryParse(_maintController.text) ?? 0;
      _insure = double.tryParse(_insureController.text) ?? 0;
      _service = double.tryParse(_serviceController.text) ?? 0;
      _taxRate = double.tryParse(_taxRateController.text) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dep = _price * _depPct / 100.0;
    final loan = _price - dep;
    final mortPmtIO = loan * (_btlRate / 100 / 12);
    final annualMortInt = mortPmtIO * 12;

    final grossAnnual = _rent * 12;
    final voidLoss = _rent * _voids;
    final agentAmt = (grossAnnual - voidLoss) * (_agentFee / 100.0);
    final netRental = grossAnnual - voidLoss - agentAmt - _maint - _insure - _service;

    // Section 24 calculations
    final taxableIncome = netRental;
    final mortRelief = annualMortInt * 0.2;
    final taxDue = math.max(0.0, taxableIncome * (_taxRate / 100.0) - mortRelief);
    final afterTaxProfit = netRental - annualMortInt - taxDue;

    final grossYield = _price > 0 ? (grossAnnual / _price * 100.0) : 0.0;
    final netYield = _price > 0 ? (netRental / _price * 100.0) : 0.0;
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
    final costsPct = totalAnnual > 0 ? ((agentAmt + _maint + _insure + _service) / totalAnnual).clamp(0.0, 1.0) : 0.0;
    final profitPct = math.max(0.0, 1.0 - mortPct - costsPct);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final btlRate  = boeBase + 1.14; // typical BTL spread
    final isLive   = ukRates?.isLive == true;

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
              Expanded(child: _rateCell('BTL Rate', '${btlRate.toStringAsFixed(2)}%', isLive ? 'Live 🟢' : 'Avg 2-yr fix', Colors.redAccent)),
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

        Text(
          'PROPERTY DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
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
              _inputField(label: 'Purchase Price (£)', controller: _priceController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Deposit (%)', controller: _depPctController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'BTL Rate (%)', controller: _btlRateController)),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(label: 'Mortgage Term (Yrs)', controller: _btlTermController),
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
              _inputField(label: 'Monthly Rent (£)', controller: _rentController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Void Months/Yr', controller: _voidsController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Agent Fee (%)', controller: _agentFeeController)),
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
                  Expanded(child: _inputField(label: 'Maintenance (£/yr)', controller: _maintController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Insurance (£/yr)', controller: _insureController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Service Charge (£/yr)', controller: _serviceController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Tax Rate (%)', controller: _taxRateController)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                          'price': _price,
                          'depPct': _depPct,
                          'btlRate': _btlRate,
                          'btlTerm': _btlTerm,
                          'rent': _rent,
                          'voids': _voids,
                          'agentFee': _agentFee,
                          'maint': _maint,
                          'insure': _insure,
                          'service': _service,
                          'taxRate': _taxRate,
                        },
                        results: {
                          'Gross Yield': grossYield,
                          'Net Yield': netYield,
                          'Cash Flow': cashFlow,
                          'ROI': roi,
                          'After Tax Profit': afterTaxProfit,
                        },
                        label: '${CurrencyFormatter.compact(_price, symbol: '£')} BTL · ${grossYield.toStringAsFixed(1)}% yield',
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
                        _legendRow(const Color(0xFFB45309), 'Costs', CurrencyFormatter.format(agentAmt + _maint + _insure + _service, symbol: '£').split('.').first, textThemeColor),
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
              _pnlRow('Maintenance', _maint, true),
              _pnlRow('Insurance', _insure, true),
              _pnlRow('Service Charge', _service, true),
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
