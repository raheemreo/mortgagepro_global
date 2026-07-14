// lib/features/canada/tools/ca_gds_tds_ratio.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CAGdsTdsRatio extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAGdsTdsRatio({super.key, required this.theme});

  @override
  ConsumerState<CAGdsTdsRatio> createState() => _CAGdsTdsRatioState();
}

class _CAGdsTdsRatioState extends ConsumerState<CAGdsTdsRatio> {
  final _incomeController = TextEditingController(text: '9000');
  final _mortgageController = TextEditingController(text: '2832');
  final _taxController = TextEditingController(text: '400');
  final _heatingController = TextEditingController(text: '150');
  final _condoController = TextEditingController(text: '0');

  final _carController = TextEditingController(text: '350');
  final _ccController = TextEditingController(text: '150');
  final _otherController = TextEditingController(text: '0');

  final _resultsKey = GlobalKey();
  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  @override
  void dispose() {
    _incomeController.dispose();
    _mortgageController.dispose();
    _taxController.dispose();
    _heatingController.dispose();
    _condoController.dispose();
    _carController.dispose();
    _ccController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    double defaultVal = 0.0;
    if (c == _incomeController) {
      defaultVal = 9000.0;
    } else if (c == _mortgageController) {
      defaultVal = 2832.0;
    } else if (c == _taxController) {
      defaultVal = 400.0;
    } else if (c == _heatingController) {
      defaultVal = 150.0;
    } else if (c == _condoController) {
      defaultVal = 0.0;
    } else if (c == _carController) {
      defaultVal = 350.0;
    } else if (c == _ccController) {
      defaultVal = 150.0;
    } else if (c == _otherController) {
      defaultVal = 0.0;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};
    final income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (income <= 0) errors['income'] = 'Enter a valid gross monthly income';

    final mortgage = double.tryParse(_mortgageController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (mortgage < 0) errors['mortgage'] = 'Enter a valid mortgage payment';

    final tax = double.tryParse(_taxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (tax < 0) errors['tax'] = 'Enter a valid property tax';

    final heating = double.tryParse(_heatingController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (heating < 0) errors['heating'] = 'Enter a valid heating cost';

    final condo = double.tryParse(_condoController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (condo < 0) errors['condo'] = 'Enter a valid condo fee';

    final car = double.tryParse(_carController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (car < 0) errors['car'] = 'Enter a valid car payment';

    final cc = double.tryParse(_ccController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (cc < 0) errors['cc'] = 'Enter a valid credit card payment';

    final other = double.tryParse(_otherController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (other < 0) errors['other'] = 'Enter a valid amount';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_incomeController] = income;
      _calcSnapshot[_mortgageController] = mortgage;
      _calcSnapshot[_taxController] = tax;
      _calcSnapshot[_heatingController] = heating;
      _calcSnapshot[_condoController] = condo;
      _calcSnapshot[_carController] = car;
      _calcSnapshot[_ccController] = cc;
      _calcSnapshot[_otherController] = other;
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
      _incomeController.text = '9000';
      _mortgageController.text = '2832';
      _taxController.text = '400';
      _heatingController.text = '150';
      _condoController.text = '0';
      _carController.text = '350';
      _ccController.text = '150';
      _otherController.text = '0';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final double income = _val(_incomeController);
    final double mortgage = _val(_mortgageController);
    final double tax = _val(_taxController);
    final double heating = _val(_heatingController);
    final double condo = _val(_condoController);
    final double car = _val(_carController);
    final double cc = _val(_ccController);
    final double other = _val(_otherController);

    final double condoHalf = condo * 0.5;
    final double gdsTotal = mortgage + tax + heating + condoHalf;
    final double otherDebt = car + cc + other;
    final double tdsTotal = gdsTotal + otherDebt;
    final double gds = income > 0 ? (gdsTotal / income * 100) : 0;
    final double tds = income > 0 ? (tdsTotal / income * 100) : 0;

    final labelCtrl = TextEditingController(text: 'GDS/TDS Ratios');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_gds_tds_ratio/save'),
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
              'Saving: GDS ${gds.toStringAsFixed(1)}% · TDS: ${tds.toStringAsFixed(1)}% · Income: ${CurrencyFormatter.compact(income, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. Current Ratios)',
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
          : 'GDS/TDS';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'GDS / TDS Ratio',
        inputs: {
          'Income': income,
          'Mortgage': mortgage,
          'Tax': tax,
          'Heating': heating,
          'Condo': condo,
          'Car': car,
          'Cc': cc,
          'Other': other,
        },
        results: {
          'GDS': gds,
          'TDS': tds,
          'GDSTotal': gdsTotal,
          'TDSTotal': tdsTotal,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ratios saved successfully!',
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
    final theme = widget.theme;

    final double income = _val(_incomeController);
    final double mortgage = _val(_mortgageController);
    final double tax = _val(_taxController);
    final double heating = _val(_heatingController);
    final double condo = _val(_condoController);
    final double car = _val(_carController);
    final double cc = _val(_ccController);
    final double other = _val(_otherController);

    final double condoHalf = condo * 0.5;
    final double gdsTotal = mortgage + tax + heating + condoHalf;
    final double otherDebt = car + cc + other;
    final double tdsTotal = gdsTotal + otherDebt;
    final double gds = income > 0 ? (gdsTotal / income * 100) : 0;
    final double tds = income > 0 ? (tdsTotal / income * 100) : 0;
    final double discretionary = income - tdsTotal;

    final bool gdsPass = gds <= 39;
    final bool tdsPass = tds <= 44;

    final isDirty = _showResults && (
      (double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_incomeController] ?? 0.0) ||
      (double.tryParse(_mortgageController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_mortgageController] ?? 0.0) ||
      (double.tryParse(_taxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_taxController] ?? 0.0) ||
      (double.tryParse(_heatingController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_heatingController] ?? 0.0) ||
      (double.tryParse(_condoController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_condoController] ?? 0.0) ||
      (double.tryParse(_carController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_carController] ?? 0.0) ||
      (double.tryParse(_ccController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_ccController] ?? 0.0) ||
      (double.tryParse(_otherController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_otherController] ?? 0.0)
    );

    // Filter saved calcs locally
    final saved = ref.watch(savedProvider);
    final localSaved = saved
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType.toLowerCase() == 'gds / tds ratio')
        .toList();

    Color getStatusColor(double val, double limit) {
      if (val > limit) return const Color(0xFFC8102E);
      if (val > limit * 0.85) return const Color(0xFFF59E0B);
      return const Color(0xFF1A5C35);
    }

    String getStatusText(double val, double limit) {
      if (val > limit) return '✗ Over Limit';
      if (val > limit * 0.85) return '⚠ Near Limit';
      return '✓ Pass';
    }

    // Live BoC rates for mortgage rate context
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final live5yr = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final liveStress = ratesAsync.valueOrNull?.stressTestRate ?? 7.00;
    final livePrime = ratesAsync.valueOrNull?.prime.value ?? 4.45;
    final isLive = ratesAsync.valueOrNull?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live rate context strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rateCell('5-Yr Fixed', '${live5yr.toStringAsFixed(2)}%', theme),
              Container(width: 1, height: 28, color: theme.getBorderColor(context)),
              _rateCell('Stress Test', '${liveStress.toStringAsFixed(2)}%', theme),
              Container(width: 1, height: 28, color: theme.getBorderColor(context)),
              _rateCell('Prime Rate', '${livePrime.toStringAsFixed(2)}%', theme),
              Container(width: 1, height: 28, color: theme.getBorderColor(context)),
              _rateCell('Source', isLive ? '🟢 Live' : 'est.', theme),
            ],
          ),
        ),
        // Section Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MONTHLY INCOME',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context),
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Income Card
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
              _buildInputField('Gross Monthly Household Income', _incomeController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['income']),
              const SizedBox(height: 4),
              Text(
                'Before-tax income. Include all co-borrowers.',
                style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Housing Costs (GDS)
        Text(
          'HOUSING COSTS (GDS)',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField('Mortgage Payment', _mortgageController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['mortgage']),
              const SizedBox(height: 12),
              _buildInputField('Property Tax', _taxController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['tax']),
              const SizedBox(height: 12),
              _buildInputField('Heating Costs', _heatingController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['heating']),
              const SizedBox(height: 12),
              _buildInputField('Condo Fees (if applicable)', _condoController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['condo']),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Other Debt Payments (TDS)
        Text(
          'OTHER DEBT PAYMENTS (TDS)',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField('Car Loan / Lease', _carController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['car']),
              const SizedBox(height: 12),
              _buildInputField('Credit Cards (3% of balance)', _ccController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['cc']),
              const SizedBox(height: 12),
              _buildInputField('Student / Other Loans', _otherController, prefix: 'CA\$', suffix: '/mo', errorText: _errors['other']),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _calculate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC8102E),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            '📊 Calculate Ratios',
            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),

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
                      'Inputs have changed. Tap Calculate to refresh results.',
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
                // Ratios Summary Gauges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'YOUR RATIOS',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.bold,
                        color: theme.getMutedColor(context),
                        letterSpacing: 0.6,
                      ),
                    ),
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('💾', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              'Save Scenario',
                              style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGaugeCard('GDS Ratio', '${gds.toStringAsFixed(1)}%', 'Limit: 39%', getStatusText(gds, 39), getStatusColor(gds, 39), gds / 39, theme),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildGaugeCard('TDS Ratio', '${tds.toStringAsFixed(1)}%', 'Limit: 44%', getStatusText(tds, 44), getStatusColor(tds, 44), tds / 44, theme),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Qualification Result Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUALIFICATION SUMMARY',
                        style: AppTextStyles.dmSans(
                          size: 9,
                          color: Colors.white60,
                          weight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _qualRow('GDS — Housing Costs', '${gds.toStringAsFixed(1)}% / 39%', gdsPass),
                      const Divider(color: Colors.white12, height: 16),
                      _qualRow('TDS — Total Debt', '${tds.toStringAsFixed(1)}% / 44%', tdsPass),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Visual Income Allocation
                Text(
                  'VISUAL BREAKDOWN',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
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
                      Text(
                        'Monthly Income Distribution',
                        style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GDS: ${gds.toStringAsFixed(1)}%',
                        style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getMutedColor(context)),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 16,
                          child: Row(
                            children: [
                              if (mortgage > 0)
                                Expanded(flex: (mortgage / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFF1A5C35))),
                              if (tax > 0)
                                Expanded(flex: (tax / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFF4A7C5F))),
                              if (heating > 0)
                                Expanded(flex: (heating / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFF6EDFA0))),
                              if (condoHalf > 0)
                                Expanded(flex: (condoHalf / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFF9EDED8))),
                              Expanded(flex: ((income - gdsTotal).clamp(0, income) / income * 100).round().clamp(1, 100), child: Container(color: theme.getBgColor(context))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TDS: ${tds.toStringAsFixed(1)}%',
                        style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getMutedColor(context)),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 16,
                          child: Row(
                            children: [
                              if (gdsTotal > 0)
                                Expanded(flex: (gdsTotal / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFF1A5C35))),
                              if (car > 0)
                                Expanded(flex: (car / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFFF59E0B))),
                              if (cc > 0)
                                Expanded(flex: (cc / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFFFCD34D))),
                              if (other > 0)
                                Expanded(flex: (other / income * 100).round().clamp(1, 100), child: Container(color: const Color(0xFFFEF08A))),
                              Expanded(flex: ((income - tdsTotal).clamp(0, income) / income * 100).round().clamp(1, 100), child: Container(color: theme.getBgColor(context))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Discretionary Income',
                                style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
                              ),
                              Text(
                                'After housing + all debts',
                                style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(dm.max(0, discretionary), symbol: 'CA\$'),
                                style: AppTextStyles.playfair(size: 18, weight: FontWeight.bold, color: theme.primaryColor),
                              ),
                              Text(
                                '${income > 0 ? (discretionary / income * 100).toStringAsFixed(1) : 0}% of income',
                                style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Monthly Cost Breakdown
                Text(
                  'MONTHLY COST BREAKDOWN',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _bkItem('Gross Income', income, null, theme),
                      const Divider(height: 14, thickness: 0.5),
                      _bkItem('Mortgage', mortgage, income > 0 ? (mortgage / income * 100) : 0, theme),
                      const Divider(height: 14, thickness: 0.5),
                      _bkItem('Property Tax + Heating', tax + heating, income > 0 ? ((tax + heating) / income * 100) : 0, theme),
                      const Divider(height: 14, thickness: 0.5),
                      _bkItem('Condo Fees (50%)', condoHalf, income > 0 ? (condoHalf / income * 100) : 0, theme),
                      const Divider(height: 14, thickness: 0.5),
                      _bkItem('Total GDS', gdsTotal, gds, theme, isBold: true, overrideColor: theme.primaryColor),
                      const Divider(height: 14, thickness: 0.5),
                      _bkItem('Car + Credit + Other', otherDebt, income > 0 ? (otherDebt / income * 100) : 0, theme),
                      const Divider(height: 14, thickness: 0.5),
                      _bkItem('Total TDS', tdsTotal, tds, theme, isBold: true, overrideColor: tdsPass ? const Color(0xFF1A5C35) : const Color(0xFFC8102E)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],

        // Local saved calcs
        if (localSaved.isNotEmpty) ...[
          Text(
            'SAVED SCENARIOS',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.bold,
              color: theme.getMutedColor(context),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: localSaved.length,
            itemBuilder: (context, idx) {
              final c = localSaved[idx];
              final bothPass = (c.results['GDS'] ?? 0) <= 39 && (c.results['TDS'] ?? 0) <= 44;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${CurrencyFormatter.format(c.inputs['Income'] ?? 0, symbol: 'CA\$')}/mo · ${c.savedAt.day}/${c.savedAt.month}/${c.savedAt.year}',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'GDS ${(c.results['GDS'] ?? 0).toStringAsFixed(1)}% · TDS ${(c.results['TDS'] ?? 0).toStringAsFixed(1)}%',
                            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bothPass ? const Color(0xFFDCF4E8) : const Color(0xFFFFE4E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bothPass ? 'Both Pass' : 'Fails',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.bold,
                          color: bothPass ? const Color(0xFF1A5C35) : const Color(0xFFC8102E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(savedProvider.notifier).delete(c.id),
                      child: const Text('✕', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix, String? errorText}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(prefix, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: theme.primaryColor)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(suffix, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildGaugeCard(String title, String ratio, String limit, String status, Color color, double val, CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context))),
          const SizedBox(height: 10),
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: val.clamp(0.01, 1.0),
                    strokeWidth: 8,
                    backgroundColor: theme.getBgColor(context),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ratio, style: AppTextStyles.playfair(size: 14, weight: FontWeight.bold, color: theme.getTextColor(context))),
                      Text(title.substring(0, 3), style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(limit, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: theme.getMutedColor(context))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualRow(String label, String val, bool pass) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(val, style: AppTextStyles.playfair(size: 14, weight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: pass ? const Color(0xFF6EDFA0) : const Color(0xFFFF8A9A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            pass ? 'PASS' : 'FAIL',
            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: const Color(0xFF0A2E1A)),
          ),
        ),
      ],
    );
  }

  Widget _bkItem(String label, double val, double? pct, CountryTheme theme, {bool isBold = false, Color? overrideColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold ? (overrideColor ?? theme.getTextColor(context)) : theme.getTextColor(context),
              ),
            ),
            if (pct != null && pct > 0)
              Text(
                '${pct.toStringAsFixed(1)}% of income',
                style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
              ),
          ],
        ),
        Text(
          CurrencyFormatter.format(val, symbol: 'CA\$'),
          style: AppTextStyles.playfair(
            size: isBold ? 15 : 13,
            weight: FontWeight.bold,
            color: overrideColor ?? theme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _rateCell(String label, String value, CountryTheme theme) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 8.5,
            color: theme.getMutedColor(context),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w800,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }
}
