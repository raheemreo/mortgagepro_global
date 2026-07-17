// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_piti_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../../widgets/ads/native_ad_widget.dart';

class USAPitiCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;

  const USAPitiCalc({
    super.key,
    this.theme = CountryThemes.usa,
  });

  @override
  ConsumerState<USAPitiCalc> createState() => _USAPitiCalcState();
}

class _USAPitiCalcState extends ConsumerState<USAPitiCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  bool _showResults = false;
  // Input Controllers
  final _homePriceController = TextEditingController(text: '420000');
  final _rateController = TextEditingController(text: '6.82');
  final _taxRateController = TextEditingController(text: '1.07');
  final _insuranceController = TextEditingController(text: '1800');
  final _hoaController = TextEditingController(text: '0');
  final _incomeController = TextEditingController(text: '8500');

  double _downPct = 20.0;
  int _termYears = 30;

  @override
  void dispose() {
    _homePriceController.dispose();
    _rateController.dispose();
    _taxRateController.dispose();
    _insuranceController.dispose();
    _hoaController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  // Calculation helpers
  double get _homePrice => double.tryParse(_homePriceController.text) ?? 420000.0;
  double get _rate => double.tryParse(_rateController.text) ?? 6.82;
  double get _taxRate => double.tryParse(_taxRateController.text) ?? 1.07;
  double get _insurance => double.tryParse(_insuranceController.text) ?? 1800.0;
  double get _hoa => double.tryParse(_hoaController.text) ?? 0.0;
  double get _income => double.tryParse(_incomeController.text) ?? 8500.0;
  double _val(TextEditingController controller, double defaultVal) {
    if (_showResults && _calcSnapshot.containsKey(controller)) {
      return _calcSnapshot[controller]!;
    }
    return double.tryParse(controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};
    final val_homePrice = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_homePrice <= 0) errors['homePrice'] = 'Please enter a valid amount';
    final val_rate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_rate <= 0) errors['rate'] = 'Please enter a valid amount';
    final val_taxRate = double.tryParse(_taxRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_insurance = double.tryParse(_insuranceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_hoa = double.tryParse(_hoaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() {
      _calcSnapshot[_homePriceController] = val_homePrice;
      _calcSnapshot[_rateController] = val_rate;
      _calcSnapshot[_taxRateController] = val_taxRate;
      _calcSnapshot[_insuranceController] = val_insurance;
      _calcSnapshot[_hoaController] = val_hoa;
      _calcSnapshot[_incomeController] = val_income;
      _calcSnapshot['_downPct'] = _downPct;
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

  @override
  Widget build(BuildContext context) {
    final _downPct = _showResults ? (_calcSnapshot['_downPct'] ?? this._downPct) : this._downPct;
    final _termYears = _showResults ? (_calcSnapshot['_termYears'] ?? this._termYears) : this._termYears;

    final isDirty = _showResults && (this._downPct != _calcSnapshot['_downPct'] || this._termYears != _calcSnapshot['_termYears'] || double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_homePriceController] ?? 0.0) || double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_rateController] ?? 0.0) || double.tryParse(_taxRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_taxRateController] ?? 0.0) || double.tryParse(_insuranceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_insuranceController] ?? 0.0) || double.tryParse(_hoaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_hoaController] ?? 0.0) || double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_incomeController] ?? 0.0));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = widget.theme;

    // Calculations
    final price = _val(_homePriceController, 420000.0);
    final down = price * _downPct / 100;
    final loan = price - down;
    final rate = _val(_rateController, 6.82);
    final term = _termYears;
    final taxRate = _val(_taxRateController, 1.07);
    final insYr = _val(_insuranceController, 1800.0);
    final hoa = _val(_hoaController, 0.0);
    final income = _val(_incomeController, 8500.0);

    final double pi = MortgageMath.monthlyPayment(
      principal: loan,
      annualRatePercent: rate,
      termYears: term,
    );

    final taxMo = price * taxRate / 100 / 12;
    final insMo = insYr / 12;
    final pmi = _downPct < 20 ? loan * 0.0085 / 12 : 0.0;
    final total = pi + taxMo + insMo + hoa + pmi;

    // First month principal/interest split
    final r = rate / 100 / 12;
    final firstInt = r > 0 ? loan * r : 0.0;
    final firstP = pi - firstInt;

    // Percentages
    final pPct = total > 0 ? (firstP / total * 100).round() : 0;
    final iPct = total > 0 ? (firstInt / total * 100).round() : 0;
    final tPct = total > 0 ? (taxMo / total * 100).round() : 0;
    final insPct = total > 0 ? ((insMo + pmi) / total * 100).round() : 0;

    // DTI calcs
    final dti = income > 0 ? (total / income * 100) : 0.0;

    // Summary calculations
    final totalPaymentsCount = term * 12;
    final totalPaid = pi * totalPaymentsCount;
    final totalInt = totalPaid - loan;
    final totalCost = totalPaid + down;

    final payoffDate = DateTime.now().add(Duration(days: term * 365));
    final payoffMonthYear = '${_getMonthName(payoffDate.month)} ${payoffDate.year}';
    final payoffYear = payoffDate.year;

    final pmiMonths = ((0.2 * price - down) / (pi - firstInt)).round();

    // DTI Status styling
    String dtiStatusText;
    Color dtiStatusBg;
    Color dtiStatusTextColor;
    String dtiNoteText;
    if (dti <= 28) {
      dtiStatusText = '✓ Excellent';
      dtiStatusBg = const Color(0xFFF0FDF4);
      dtiStatusTextColor = const Color(0xFF15803D);
      dtiNoteText = 'Below 28% ideal limit';
    } else if (dti <= 36) {
      dtiStatusText = '✓ Acceptable';
      dtiStatusBg = const Color(0xFFF0FDF4);
      dtiStatusTextColor = const Color(0xFF15803D);
      dtiNoteText = 'Within 36% guideline';
    } else if (dti <= 43) {
      dtiStatusText = '⚠ Borderline';
      dtiStatusBg = const Color(0xFFFFF7ED);
      dtiStatusTextColor = const Color(0xFFC2410C);
      dtiNoteText = 'Max 43% for most lenders';
    } else {
      dtiStatusText = '✗ Too High';
      dtiStatusBg = const Color(0xFFFEF2F2);
      dtiStatusTextColor = const Color(0xFFB91C1C);
      dtiNoteText = 'Exceeds lender limits';
    }

    final badge = _downPct >= 20
        ? 'Conventional'
        : _downPct >= 3.5
            ? 'FHA Eligible'
            : 'Conv 3% Down';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip — Live FRED data
        LightRateStripBanner(items: [
          RateStripItem(label: '30-Yr Fixed', provider: fredMortgage30Provider, fallback: 6.82),
          RateStripItem(label: '15-Yr Fixed', provider: fredMortgage15Provider, fallback: 6.11),
          RateStripItem(label: '5/1 ARM', provider: fredSofrProvider, fallback: 6.05),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),
        const SizedBox(height: 20),

        _buildSectionHeader('Loan Details', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Input Card
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 36,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USA PITI CALCULATOR · FULL PAYMENT BREAKDOWN',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.48),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.dmSans(
                    size: 17,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ).copyWith(fontFamily: 'Georgia'),
                  children: const [
                    TextSpan(text: 'All-in Monthly '),
                    TextSpan(
                      text: 'PITI Payment',
                      style: TextStyle(color: Color(0xFFFCD34D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Home Price
              _buildInputLabel('Home Purchase Price', 'Median US: \$420,800'),
              const SizedBox(height: 4),
              _buildWhiteInput(_homePriceController, prefix: '\$', errorText: _errors['homePrice']),
              const SizedBox(height: 11),

              // Down Payment & Term Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Down Payment %', null),
                        const SizedBox(height: 4),
                        _buildWhiteDropdown<double>(
                          value: _downPct,
                          items: const [
                            DropdownMenuItem(value: 3.0, child: Text('3% (Conv)')),
                            DropdownMenuItem(value: 3.5, child: Text('3.5% (FHA)')),
                            DropdownMenuItem(value: 5.0, child: Text('5%')),
                            DropdownMenuItem(value: 10.0, child: Text('10%')),
                            DropdownMenuItem(value: 20.0, child: Text('20%')),
                            DropdownMenuItem(value: 25.0, child: Text('25%')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => this._downPct = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Loan Term', null),
                        const SizedBox(height: 4),
                        _buildWhiteDropdown<int>(
                          value: _termYears,
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 Years')),
                            DropdownMenuItem(value: 20, child: Text('20 Years')),
                            DropdownMenuItem(value: 15, child: Text('15 Years')),
                            DropdownMenuItem(value: 10, child: Text('10 Years')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => this._termYears = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // Rate & Tax Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Interest Rate %', null),
                        const SizedBox(height: 4),
                        _buildWhiteInput(_rateController, suffix: '%', errorText: _errors['rate']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Property Tax %/yr', null),
                        const SizedBox(height: 4),
                        _buildWhiteInput(_taxRateController, suffix: '%'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // Insurance & HOA Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Home Insurance/yr', null),
                        const SizedBox(height: 4),
                        _buildWhiteInput(_insuranceController, prefix: '\$'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('HOA Fee/mo', null),
                        const SizedBox(height: 4),
                        _buildWhiteInput(_hoaController, prefix: '\$'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              GestureDetector(
                onTap: _calculate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Calculate PITI Payment',
                        style: AppTextStyles.dmSans(
                          size: 15,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0B1D3A),
                        ).copyWith(fontFamily: 'Georgia'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
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
                            'Inputs have changed. Tap "Calculate" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF0B1D3A), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Quick Stats Row
                _buildSectionHeader('Quick Stats', onReset: null),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatBox(
                emoji: '💰',
                label: 'Total Interest',
                value: CurrencyFormatter.compact(totalInt, symbol: '\$'),
                color: const Color(0xFFB91C1C),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStatBox(
                emoji: '📅',
                label: 'Payoff Year',
                value: payoffYear.toString(),
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStatBox(
                emoji: '🏦',
                label: 'True Cost',
                value: CurrencyFormatter.compact(totalCost, symbol: '\$'),
                color: isDark ? Colors.white : const Color(0xFF0B1D3A),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Result Card Section
        _buildSectionHeader('Monthly PITI Breakdown', onReset: null),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Monthly Payment',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.dmSans(
                        size: 9,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // PITI Total Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Est. Monthly PITI Payment',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        weight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            size: 40,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ).copyWith(fontFamily: 'Georgia'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Loan: ${CurrencyFormatter.format(loan)} · $term-yr @ ${rate.toStringAsFixed(2)}%',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),

              // PMI Required Banner
              if (pmi > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                    ),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PMI Required',
                              style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '~${CurrencyFormatter.format(pmi)}/mo · Removed at 20% equity (~$pmiMonths months)',
                              style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Grid Breakdown
              LayoutBuilder(builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBreakdownItem(
                      colors: const [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                      emoji: '🏠',
                      label: 'Principal',
                      value: firstP,
                      pct: pPct,
                      width: itemWidth,
                    ),
                    _buildBreakdownItem(
                      colors: const [Color(0xFFB91C1C), Color(0xFF991B1B)],
                      emoji: '💵',
                      label: 'Interest',
                      value: firstInt,
                      pct: iPct,
                      width: itemWidth,
                    ),
                    _buildBreakdownItem(
                      colors: const [Color(0xFFD97706), Color(0xFFB45309)],
                      emoji: '🏛️',
                      label: 'Property Tax',
                      value: taxMo,
                      pct: tPct,
                      width: itemWidth,
                    ),
                    _buildBreakdownItem(
                      colors: const [Color(0xFF0F766E), Color(0xFF0D9488)],
                      emoji: '🛡️',
                      label: 'Insurance',
                      value: insMo + pmi,
                      pct: insPct,
                      width: itemWidth,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 14),

              // Progress composition bar
              Text(
                'Payment Composition',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 16,
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (pPct > 0)
                        Expanded(
                          flex: pPct,
                          child: Container(color: const Color(0xFF1B3F72)),
                        ),
                      if (iPct > 0)
                        Expanded(
                          flex: iPct,
                          child: Container(color: const Color(0xFFB91C1C)),
                        ),
                      if (tPct > 0)
                        Expanded(
                          flex: tPct,
                          child: Container(color: const Color(0xFFD97706)),
                        ),
                      if (insPct > 0)
                        Expanded(
                          flex: insPct,
                          child: Container(color: const Color(0xFF0D9488)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Legend items
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildLegendItem('Principal', const Color(0xFF1B3F72)),
                  _buildLegendItem('Interest', const Color(0xFFB91C1C)),
                  _buildLegendItem('Tax', const Color(0xFFD97706)),
                  _buildLegendItem('Insurance', const Color(0xFF0D9488)),
                ],
              ),
              const SizedBox(height: 16),

              // Save Button
              _buildSaveButton(_saveCalculation),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Visual Breakdown (Donut Chart)
        _buildSectionHeader('Visual Breakdown', onReset: null),
        const SizedBox(height: 8),

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
              Text(
                '🥧 Where Your Monthly Payment Goes',
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _PitiDonutPainter(
                            principalPct: total > 0 ? firstP / total : 0,
                            interestPct: total > 0 ? firstInt / total : 0,
                            taxPct: total > 0 ? taxMo / total : 0,
                            insurancePct: total > 0 ? (insMo + pmi) / total : 0,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MONTHLY',
                            style: AppTextStyles.dmSans(
                              size: 8,
                              weight: FontWeight.w700,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(total, symbol: '\$').split('.').first,
                            style: AppTextStyles.dmSans(
                              size: 14,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context),
                            ).copyWith(fontFamily: 'Georgia'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildBreakdownLegendRow(
                          color: const Color(0xFF1B3F72),
                          label: 'Principal',
                          value: CurrencyFormatter.format(firstP, symbol: '\$').split('.').first,
                          pct: '$pPct%',
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownLegendRow(
                          color: const Color(0xFFB91C1C),
                          label: 'Interest',
                          value: CurrencyFormatter.format(firstInt, symbol: '\$').split('.').first,
                          pct: '$iPct%',
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownLegendRow(
                          color: const Color(0xFFD97706),
                          label: 'Tax',
                          value: CurrencyFormatter.format(taxMo, symbol: '\$').split('.').first,
                          pct: '$tPct%',
                        ),
                        const SizedBox(height: 6),
                        _buildBreakdownLegendRow(
                          color: const Color(0xFF0D9488),
                          label: 'Insurance',
                          value: CurrencyFormatter.format(insMo + pmi, symbol: '\$').split('.').first,
                          pct: '$insPct%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interest Erosion Over Time Section
        _buildSectionHeader('Interest Erosion Over Time', onReset: null),
        const SizedBox(height: 8),

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
              Text(
                '📉 How Your Payment Shifts Over Time',
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 2),
              Text(
                'Principal share grows as interest erodes year-by-year',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: theme.getMutedColor(context),
                ),
              ),
              const SizedBox(height: 14),

              // Stacked bar custom chart
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ErosionChartPainter(
                    loan: loan,
                    rate: rate,
                    termYears: term,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Legend
              Row(
                children: [
                  _buildLegendItem('Principal', const Color(0xFF1B3F72)),
                  const SizedBox(width: 14),
                  _buildLegendItem('Interest', const Color(0xFFB91C1C)),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Equity Built (% of Original Loan)',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Equity milestones strip
              _buildEquityStrip(loan, rate, term, isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NativeAdWidget(
          screenName: 'usa_piti_calc',
          adType: 'mediumCard',
        ),
        const SizedBox(height: 20),

        // DTI Check Section
        _buildSectionHeader('DTI Quick Check', onReset: null),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
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
              Text(
                'Gross Monthly Income',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: TextField(
                  controller: _incomeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: theme.getMutedColor(context),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Front-End DTI',
                        style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w700,
                          color: theme.getMutedColor(context),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dti.toStringAsFixed(1)}%',
                        style: AppTextStyles.dmSans(
                          size: 26,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context),
                        ).copyWith(fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '28% rule · Lender max 43%',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          weight: FontWeight.w500,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dtiStatusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dtiStatusTextColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          dtiStatusText,
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w800,
                            color: dtiStatusTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dtiNoteText,
                        style: AppTextStyles.dmSans(
                          size: 9,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  LayoutBuilder(builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    // Cap width at 100%
                    final fillW = maxW * (min(dti, 50.0) / 50.0);
                    return Container(
                      height: 8,
                      width: fillW,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15803D), Color(0xFFD97706), Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTickLabel('0%'),
                  _buildTickLabel('28% ideal'),
                  _buildTickLabel('43% max'),
                  _buildTickLabel('50%+'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary Section
        _buildSectionHeader('Loan Summary', onReset: null),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
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
            children: [
              _buildSummaryRow('Purchase Price', CurrencyFormatter.format(price)),
              _buildSummaryRow(
                'Down Payment',
                '${CurrencyFormatter.format(down)} (${_downPct.toStringAsFixed(_downPct % 1 == 0 ? 0 : 1)}%)',
                color: const Color(0xFF15803D),
              ),
              _buildSummaryRow('Loan Amount', CurrencyFormatter.format(loan)),
              _buildSummaryRow(
                'Total Interest Paid',
                CurrencyFormatter.format(totalInt),
                color: const Color(0xFFB91C1C),
              ),
              _buildSummaryRow(
                'Total Cost of Loan',
                CurrencyFormatter.format(totalCost),
                color: const Color(0xFFB91C1C),
              ),
              _buildSummaryRow(
                'PMI Required?',
                _downPct >= 20 ? 'No (≥ 20% down)' : 'Yes ~ ${CurrencyFormatter.format(pmi)}/mo',
              ),
              _buildSummaryRow('Payoff Date', payoffMonthYear, color: const Color(0xFFD97706)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pro Tip Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2C200F), const Color(0xFF1E160A)]
                  : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFD97706).withValues(alpha: 0.5)
                  : const Color(0xFFF59E0B),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'PITI Pro Tip',
                    style: AppTextStyles.dmSans(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Lenders use PITI to qualify you. Most conventional lenders cap front-end DTI at 28% and back-end at 36–43%. FHA allows up to 31%/43%. A 20% down payment eliminates PMI, saving \$100–\$300/mo on a typical loan.',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w500,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
],
],
);
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              'Reset →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  void _saveCalculation() async {
    final price = _homePrice;
    final down = price * _downPct / 100;
    final loan = price - down;
    final rate = _rate;
    final term = _termYears;
    final taxRate = _taxRate;
    final insYr = _insurance;
    final hoa = _hoa;
    final income = _income;

    final double pi = MortgageMath.monthlyPayment(
      principal: loan,
      annualRatePercent: rate,
      termYears: term,
    );

    final taxMo = price * taxRate / 100 / 12;
    final insMo = insYr / 12;
    final pmi = _downPct < 20 ? loan * 0.0085 / 12 : 0.0;
    final total = pi + taxMo + insMo + hoa + pmi;

    final labelCtrl = TextEditingController(text: 'PITI Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_piti_calc/save'),
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
              'Saving: Total ${CurrencyFormatter.compact(total, symbol: '\$')} · Price: ${CurrencyFormatter.compact(price, symbol: '\$')} · Down: ${_downPct.toStringAsFixed(0)}%',
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
                hintText: 'Label (e.g. My PITI Calc)',
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
          : 'PITI Calculator';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'PITI Calculator',
        inputs: {
          'Price': price,
          'DownPct': _downPct,
          'Rate': rate,
          'Term': term.toDouble(),
          'TaxRate': taxRate,
          'Insurance': insYr,
          'HOA': hoa,
          'Income': income,
        },
        results: {
          'TotalMonthly': total,
          'PI': pi,
          'TaxMonthly': taxMo,
          'InsuranceMonthly': insMo,
          'PMI': pmi,
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

  void _resetInputs() {
    setState(() {
      _homePriceController.clear();
      _rateController.clear();
      _taxRateController.clear();
      _insuranceController.clear();
      _hoaController.clear();
      _incomeController.clear();
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
      _homePriceController.text = '420000';
      _rateController.text = '6.82';
      _taxRateController.text = '1.07';
      _insuranceController.text = '1800';
      _hoaController.text = '0';
      _incomeController.text = '8500';
      _downPct = 20.0;
      _termYears = 30;
    });
  }

  Widget _buildInputLabel(String label, String? rightHint) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 0.5,
          ),
        ),
        if (rightHint != null)
          Text(
            rightHint,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w600,
              color: const Color(0xFFFCD34D),
            ),
          ),
      ],
    );
  }

  Widget _buildWhiteInput(TextEditingController controller, {String? prefix, String? suffix, String? errorText}) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: hasError ? Colors.red : Colors.white.withValues(alpha: 0.18),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: Colors.white,
            ).copyWith(fontFamily: 'Georgia'),
            decoration: InputDecoration(
              prefixText: prefix != null ? '$prefix ' : null,
              prefixStyle: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white70).copyWith(fontFamily: 'Georgia'),
              suffixText: suffix != null ? ' $suffix' : null,
              suffixStyle: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white70).copyWith(fontFamily: 'Georgia'),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(
              size: 10,
              color: Colors.red,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWhiteDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1B3F72),
          style: AppTextStyles.dmSans(
            size: 14,
            weight: FontWeight.w800,
            color: Colors.white,
          ).copyWith(fontFamily: 'Georgia'),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.50)),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildBreakdownItem({
    required List<Color> colors,
    required String emoji,
    required String label,
    required double value,
    required int pct,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            CurrencyFormatter.format(value, symbol: '\$').split('.').first,
            style: AppTextStyles.dmSans(
              size: 18,
              weight: FontWeight.w800,
              color: Colors.white,
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 2),
          Text(
            '$pct% of payment',
            style: AppTextStyles.dmSans(
              size: 9,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w600,
            color: widget.theme.getMutedColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTickLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.dmSans(
        size: 8.5,
        color: widget.theme.getMutedColor(context),
      ),
    );
  }

  Widget _buildSummaryRow(String key, String value, {Color? color}) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.getBorderColor(context).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: AppTextStyles.dmSans(
                size: 11.5,
                weight: FontWeight.w600,
                color: theme.getMutedColor(context),
              ),
            ),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: color ?? theme.getTextColor(context),
              ).copyWith(fontFamily: 'Georgia'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildBreakdownLegendRow({
    required Color color,
    required String label,
    required String value,
    required String pct,
  }) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.getTextColor(context)),
              ),
              Text(
                '$pct of total',
                style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
        ),
      ],
    );
  }

  Widget _buildQuickStatBox({
    required String emoji,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w700,
              color: theme.getMutedColor(context),
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 15,
              weight: FontWeight.w800,
              color: color,
            ).copyWith(fontFamily: 'Georgia'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15803D).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              'Save This Calculation',
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityStrip(double loan, double rate, int termYears, bool isDark) {
    final double r = rate / 100 / 12;
    final int n = termYears * 12;
    double monthlyPI;
    if (r == 0) {
      monthlyPI = loan / n;
    } else {
      monthlyPI = loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    }

    final milestones = [1, 5, 10, 15, termYears];
    final Map<int, int> equityData = {};
    double bal = loan;

    for (int y = 1; y <= termYears; y++) {
      for (int m = 0; m < 12; m++) {
        final intPart = bal * r;
        bal = max(0.0, bal - (monthlyPI - intPart));
      }
      if (milestones.contains(y)) {
        equityData[y] = ((loan - bal) / loan * 100).round();
      }
    }

    final theme = widget.theme;

    return Row(
      children: milestones.map((y) {
        final pct = equityData[y] ?? 0;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Text(
                  'Yr $y',
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: theme.getMutedColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pct%',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 4,
                    width: double.infinity,
                    color: isDark ? Colors.white10 : Colors.black12,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct / 100,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B3F72), Color(0xFF15803D)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PitiDonutPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final double taxPct;
  final double insurancePct;
  final bool isDark;

  _PitiDonutPainter({
    required this.principalPct,
    required this.interestPct,
    required this.taxPct,
    required this.insurancePct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 18.0;

    final paintBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    final total = principalPct + interestPct + taxPct + insurancePct;
    if (total <= 0) return;

    double startAngle = -pi / 2;

    if (principalPct > 0) {
      final sweep = 2 * pi * (principalPct / total);
      final paintP = Paint()
        ..color = const Color(0xFF1B3F72)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintP);
      startAngle += sweep;
    }

    if (interestPct > 0) {
      final sweep = 2 * pi * (interestPct / total);
      final paintI = Paint()
        ..color = const Color(0xFFB91C1C)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintI);
      startAngle += sweep;
    }

    if (taxPct > 0) {
      final sweep = 2 * pi * (taxPct / total);
      final paintT = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintT);
      startAngle += sweep;
    }

    if (insurancePct > 0) {
      final sweep = 2 * pi * (insurancePct / total);
      final paintIns = Paint()
        ..color = const Color(0xFF0D9488)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintIns);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ErosionChartPainter extends CustomPainter {
  final double loan;
  final double rate;
  final int termYears;
  final bool isDark;

  _ErosionChartPainter({
    required this.loan,
    required this.rate,
    required this.termYears,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double r = rate / 100 / 12;
    final int n = termYears * 12;

    double monthlyPI;
    if (r == 0) {
      monthlyPI = loan / n;
    } else {
      monthlyPI = loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    }

    final List<Map<String, double>> annualData = [];
    double bal = loan;
    for (int y = 1; y <= termYears; y++) {
      double yInt = 0.0;
      double yPrin = 0.0;
      for (int m = 0; m < 12; m++) {
        final intPart = bal * r;
        final prinPart = min(monthlyPI - intPart, bal);
        yInt += intPart;
        yPrin += prinPart;
        bal = max(0.0, bal - prinPart);
      }
      annualData.add({'interest': yInt, 'principal': yPrin});
    }

    final paintPrincipal = Paint()
      ..color = const Color(0xFF1B3F72)
      ..style = PaintingStyle.fill;

    final paintInterest = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.fill;

    const double paddingLeft = 10;
    const double paddingRight = 10;
    const double paddingTop = 10;
    const double paddingBottom = 20;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    final barWidth = (chartWidth / termYears) * 0.72;
    final barSpacing = (chartWidth / termYears) * 0.28;

    final double maxVal = monthlyPI * 12;

    for (int i = 0; i < termYears; i++) {
      final data = annualData[i];
      final double yInt = data['interest']!;
      final double yPrin = data['principal']!;

      final double x = paddingLeft + i * (barWidth + barSpacing) + barSpacing / 2;

      final double intHeight = (yInt / maxVal) * chartHeight;
      final double prinHeight = (yPrin / maxVal) * chartHeight;

      // Draw Interest (red) on bottom
      final rectInt = Rect.fromLTWH(
        x,
        paddingTop + chartHeight - intHeight,
        barWidth,
        intHeight,
      );
      canvas.drawRect(rectInt, paintInterest);

      // Draw Principal (navy) on top
      final rectPrin = Rect.fromLTWH(
        x,
        paddingTop + chartHeight - intHeight - prinHeight,
        barWidth,
        prinHeight,
      );
      canvas.drawRect(rectPrin, paintPrincipal);
    }

    // Draw Year Labels (Y1, Y5, Y10, Y15, ... Y_term)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = TextStyle(
      fontSize: 8,
      color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
      fontWeight: FontWeight.w700,
    );

    for (int i = 0; i < termYears; i++) {
      final int year = i + 1;
      if (year == 1 || year % 5 == 0 || year == termYears) {
        textPainter.text = TextSpan(text: 'Y$year', style: textStyle);
        textPainter.layout();
        final double x = paddingLeft + i * (barWidth + barSpacing) + barSpacing / 2 + barWidth / 2 - textPainter.width / 2;
        textPainter.paint(canvas, Offset(x, size.height - 15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ErosionChartPainter oldDelegate) {
    return oldDelegate.loan != loan ||
        oldDelegate.rate != rate ||
        oldDelegate.termYears != termYears ||
        oldDelegate.isDark != isDark;
  }
}

