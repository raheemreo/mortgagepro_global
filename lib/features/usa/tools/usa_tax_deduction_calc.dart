// lib/features/usa/tools/usa_tax_deduction_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USATaxDeductionCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USATaxDeductionCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USATaxDeductionCalc> createState() => _USATaxDeductionCalcState();
}

class _USATaxDeductionCalcState extends ConsumerState<USATaxDeductionCalc> {
  String _filingStatus = 'mfj'; // 'single', 'mfj', 'mfs', 'hoh'
  final _incomeController = TextEditingController(text: '120000');
  final _mortgageBalController = TextEditingController(text: '380000');
  final _mRateController = TextEditingController(text: '6.82');
  final _propTaxController = TextEditingController(text: '8500');
  final _charityController = TextEditingController(text: '3200');
  final _stateTaxController = TextEditingController(text: '6800');
  final _medicalController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  final Map<String, double> _stdDeduction = {
    'single': 14600,
    'mfj': 29200,
    'mfs': 14600,
    'hoh': 21900,
  };

  final List<List<double>> _bracketsMfj = [
    [23200, 0.10],
    [94300, 0.12],
    [201050, 0.22],
    [383900, 0.24],
    [487450, 0.32],
    [731200, 0.35],
    [double.infinity, 0.37]
  ];

  final List<List<double>> _bracketsSingle = [
    [11600, 0.10],
    [47150, 0.12],
    [100525, 0.22],
    [191950, 0.24],
    [243725, 0.32],
    [609350, 0.35],
    [double.infinity, 0.37]
  ];

  final List<List<double>> _bracketsHoh = [
    [16550, 0.10],
    [63100, 0.12],
    [100500, 0.22],
    [191950, 0.24],
    [243700, 0.32],
    [609350, 0.35],
    [double.infinity, 0.37]
  ];

  @override
  void initState() {
    super.initState();
    final controllers = [
      _incomeController,
      _mortgageBalController,
      _mRateController,
      _propTaxController,
      _charityController,
      _stateTaxController,
      _medicalController,
      _otherController
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
    _incomeController.dispose();
    _mortgageBalController.dispose();
    _mRateController.dispose();
    _propTaxController.dispose();
    _charityController.dispose();
    _stateTaxController.dispose();
    _medicalController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  double _calcTax(double taxable, String filing) {
    final List<List<double>> brackets = filing == 'mfj'
        ? _bracketsMfj
        : filing == 'hoh'
            ? _bracketsHoh
            : _bracketsSingle;

    double tax = 0.0;
    double prev = 0.0;
    for (final b in brackets) {
      final double top = b[0];
      final double rate = b[1];
      if (taxable <= prev) break;
      tax += (min(taxable, top) - prev) * rate;
      if (taxable <= top) break;
      prev = top;
    }
    return tax;
  }

  Map<String, dynamic> _computeTaxProfile() {
    final filing = _filingStatus;
    final income = _val(_incomeController);
    final mortgage = _val(_mortgageBalController);
    final mrate = _val(_mRateController) / 100;
    final proptax = _val(_propTaxController);
    final charity = _val(_charityController);
    final stateTax = _val(_stateTaxController);
    final medical = _val(_medicalController);
    final other = _val(_otherController);

    final mortgageInterest = min(mortgage, 750000.0) * mrate;
    final saltRaw = proptax + stateTax;
    final saltCapped = min(saltRaw, 10000.0);
    final medicalAllowed = max(0.0, medical - income * 0.075);
    final itemized = mortgageInterest + saltCapped + charity + medicalAllowed + other;
    
    final std = _stdDeduction[filing] ?? 14600.0;
    final useItemized = itemized > std;
    final deduction = useItemized ? itemized : std;
    final taxable = max(0.0, income - deduction);

    final fedTax = _calcTax(taxable, filing);
    final baseTax = _calcTax(income, filing);
    final savings = baseTax - fedTax;
    final effectiveRate = income > 0 ? (fedTax / income) * 100 : 0.0;
    final filingLabel = {
      'single': 'Single',
      'mfj': 'Married Filing Jointly',
      'mfs': 'Married Filing Separately',
      'hoh': 'Head of Household'
    }[filing]!;

    return {
      'filing': filing,
      'filingLabel': filingLabel,
      'income': income,
      'mortgageInterest': mortgageInterest,
      'saltRaw': saltRaw,
      'saltCapped': saltCapped,
      'medicalAllowed': medicalAllowed,
      'itemized': itemized,
      'std': std,
      'useItemized': useItemized,
      'deduction': deduction,
      'taxable': taxable,
      'fedTax': fedTax,
      'savings': savings,
      'effectiveRate': effectiveRate,
    };
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final income = _val(_incomeController);
    if (income <= 0) return;

    final data = _computeTaxProfile();
    final savings = data['savings'] as double;
    final fedTax = data['fedTax'] as double;
    final filingLabel = data['filingLabel'] as String;

    final label = 'Tax Deduction ($filingLabel)';
    final labelCtrl = TextEditingController(text: label);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Tax Result',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Tax Savings: ${CurrencyFormatter.compact(savings, symbol: r'$')} · Fed Tax: ${CurrencyFormatter.compact(fedTax, symbol: r'$')}',
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
        calcType: 'Tax Deduction Calc',
        inputs: {
          'Income': income,
          'Mortgage': _val(_mortgageBalController),
          'FilingIdx': _filingStatus == 'single' ? 0.0 : _filingStatus == 'mfj' ? 1.0 : _filingStatus == 'mfs' ? 2.0 : 3.0,
        },
        results: {
          'Deduction': data['deduction'] as double,
          'Savings': savings,
          'Federal Tax': fedTax,
          'Taxable Income': data['taxable'] as double,
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final data = _computeTaxProfile();
    final income = data['income'] as double;
    final deduction = data['deduction'] as double;
    final taxable = data['taxable'] as double;
    final fedTax = data['fedTax'] as double;
    final savings = data['savings'] as double;
    final effectiveRate = data['effectiveRate'] as double;
    final itemized = data['itemized'] as double;
    final std = data['std'] as double;
    final useItemized = data['useItemized'] as bool;
    final filingLabel = data['filingLabel'] as String;

    final diff = (itemized - std).abs();

    // Waterfall rows
    final List<Map<String, dynamic>> waterfallItems = [
      {'label': 'Gross Income', 'val': income, 'color': const Color(0xFF1B3F72), 'neg': false},
      {'label': 'Deduction', 'val': deduction, 'color': const Color(0xFF15803D), 'neg': true},
      {'label': 'Taxable Income', 'val': taxable, 'color': const Color(0xFFD97706), 'neg': false},
      {'label': 'Federal Tax', 'val': fedTax, 'color': const Color(0xFFB91C1C), 'neg': true},
      {'label': 'After-Tax Income', 'val': max(0.0, income - fedTax), 'color': const Color(0xFF6D28D9), 'neg': false},
    ];

    // Itemized breakdown rows
    final List<Map<String, dynamic>> itemizedItems = [
      {'label': '🏠 Mortgage Int.', 'val': data['mortgageInterest'] as double, 'color': const Color(0xFF1B3F72)},
      {'label': '🏛 SALT (capped)', 'val': data['saltCapped'] as double, 'color': const Color(0xFF0B1D3A)},
      {'label': '❤️ Charitable', 'val': _val(_charityController), 'color': const Color(0xFFB91C1C)},
      {'label': '🏥 Medical', 'val': data['medicalAllowed'] as double, 'color': const Color(0xFFD97706)},
      {'label': '📋 Other', 'val': _val(_otherController), 'color': const Color(0xFF6D28D9)},
    ].where((i) => (i['val'] as double) > 0).toList();

    final maxItemVal = itemizedItems.isNotEmpty
        ? itemizedItems.map((i) => i['val'] as double).reduce((a, b) => a > b ? a : b)
        : 1.0;

    // Brackets table mapping
    final List<List<double>> brackets = _filingStatus == 'mfj'
        ? _bracketsMfj
        : _filingStatus == 'hoh'
            ? _bracketsHoh
            : _bracketsSingle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Std. Single', r'$14,600', '2024 IRS', theme, context),
              _buildHeaderStat('Std. MFJ', r'$29,200', 'Married', theme, context),
              _buildHeaderStat('Top Rate', '37%', r'>$609K', theme, context, isGold: true),
              _buildHeaderStat('SALT Cap', r'$10,000', 'Federal', theme, context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('YOUR TAX PROFILE', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Inputs Card
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
              Text('Filing Status', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filingStatus,
                    isExpanded: true,
                    dropdownColor: theme.getCardColor(context),
                    style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
                    onChanged: (v) {
                      setState(() {
                        _filingStatus = v!;
                        _markDirty();
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('Single')),
                      DropdownMenuItem(value: 'mfj', child: Text('Married Filing Jointly')),
                      DropdownMenuItem(value: 'mfs', child: Text('Married Filing Separately')),
                      DropdownMenuItem(value: 'hoh', child: Text('Head of Household')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildTextField('Gross Annual Income (\$)', _incomeController),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField('Mortgage Balance (\$)', _mortgageBalController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Mortgage Rate (%)', _mRateController)),
                ],
              ),
              const SizedBox(height: 12),

              _buildTextField('Property Tax Paid (Annual) (\$)', _propTaxController),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField('Charitable Donations (\$)', _charityController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('State Income Tax (\$)', _stateTaxController)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField('Medical Expenses (\$)', _medicalController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Other Itemized (\$)', _otherController)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.85)],
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
                            : Text('🧾 Calculate My Tax Deductions', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
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
                        color: _showResults ? const Color(0xFF15803D) : theme.getBgColor(context),
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
          // Recommended Deduction Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOMMENDED DEDUCTION', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(CurrencyFormatter.format(deduction, symbol: r'$'),
                    style: AppTextStyles.playfair(size: 36, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${useItemized ? "Itemized" : "Standard"} Deduction · $filingLabel',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroResult('Tax Savings', CurrencyFormatter.compact(savings, symbol: r'$'), color: const Color(0xFF6EE7B7)),
                    _buildHeroResult('Effective Rate', '${effectiveRate.toStringAsFixed(1)}%'),
                    _buildHeroResult('Taxable Income', CurrencyFormatter.compact(taxable, symbol: r'$')),
                    _buildHeroResult('Est. Fed Tax', CurrencyFormatter.compact(fedTax, symbol: r'$'), color: const Color(0xFFFCA5A5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Income Waterfall Chart Card
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
                Text('💧 Income Waterfall', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('How your gross income flows to taxable income', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 12),
                ...waterfallItems.map((wf) {
                  final double val = wf['val'] as double;
                  final double pct = income > 0 ? (val / income) : 0;
                  final String sign = wf['neg'] as bool ? '-' : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 100, child: Text(wf['label'] as String, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.w600))),
                        Expanded(
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: pct.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(color: wf['color'] as Color, borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 8),
                                child: pct > 0.15
                                    ? Text('${(pct * 100).round()}%', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '$sign${CurrencyFormatter.format(val, symbol: r'$')}',
                            style: AppTextStyles.playfair(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold),
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
          const SizedBox(height: 16),

          // Deduction Compare Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Deduction Comparison', style: AppTextStyles.playfair(size: 12.5, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Standard', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFB45309), weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(CurrencyFormatter.format(std, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                      ],
                    ),
                    const Text('vs', style: TextStyle(fontSize: 20, color: Color(0xFFD97706), fontWeight: FontWeight.w300)),
                    Column(
                      children: [
                        Text('Itemized', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFB45309), weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(CurrencyFormatter.format(itemized, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      useItemized
                          ? '✓ Itemized Wins — Save ${CurrencyFormatter.format(diff, symbol: r"$")} more'
                          : '✓ Standard Deduction Wins — Save ${CurrencyFormatter.format(diff, symbol: r"$")} more',
                      style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Itemized Deduction Breakdown bars
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
                Text('📋 Itemized Deduction Breakdown', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('What makes up your itemized total vs SALT cap', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 12),
                if (itemizedItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('No itemized deductions entered.', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context))),
                  )
                else ...[
                  ...itemizedItems.map((it) {
                    final double val = it['val'] as double;
                    final double scale = val / maxItemVal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(it['label'] as String, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.w600))),
                          Expanded(
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(6)),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: scale.clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(color: it['color'] as Color, borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 64,
                            child: Text(
                              CurrencyFormatter.format(val, symbol: r'$'),
                              style: AppTextStyles.playfair(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (data['saltRaw'] as double > 10000.0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ SALT capped at \$10K (your actual: ${CurrencyFormatter.format(data['saltRaw'] as double, symbol: r"$")} — ${CurrencyFormatter.format((data['saltRaw'] as double) - 10000.0, symbol: r"$")} non-deductible)',
                        style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFD97706), weight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tax bracket table (highlighting active)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2024 Federal Tax Brackets', style: AppTextStyles.playfair(size: 12, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('$filingLabel — 2024', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
                const SizedBox(height: 10),
                // Table Headers
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Rate', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Income Range', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold))),
                      Expanded(child: Text('Your Tax', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                ...brackets.asMap().entries.map((entry) {
                  final int i = entry.key;
                  final double top = entry.value[0];
                  final double rate = entry.value[1];

                  final double prev = i == 0 ? 0.0 : brackets[i - 1][0];
                  final bool inBracket = taxable > prev;
                  final bool isActive = taxable > prev && taxable <= top;
                  final double taxInBracket = max(0.0, min(taxable, top) - prev) * rate;

                  final String rangeStr = top == double.infinity
                      ? '${CurrencyFormatter.compact(prev, symbol: r"$")}+'
                      : '${CurrencyFormatter.compact(prev, symbol: r"$")} – ${CurrencyFormatter.compact(top, symbol: r"$")}';

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(colors: [const Color(0xFFB91C1C).withValues(alpha: 0.06), const Color(0xFFB91C1C).withValues(alpha: 0.10)])
                          : null,
                      borderRadius: isActive ? BorderRadius.circular(8) : null,
                      border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text('${(rate * 100).round()}%',
                                  style: AppTextStyles.dmSans(
                                      size: 11,
                                      color: isActive ? const Color(0xFFB91C1C) : theme.getTextColor(context),
                                      weight: isActive ? FontWeight.bold : FontWeight.w600)),
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFB91C1C), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('You', style: TextStyle(fontSize: 7.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(rangeStr, style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context))),
                        ),
                        Expanded(
                          child: Text(
                            inBracket && taxInBracket > 0 ? CurrencyFormatter.format(taxInBracket, symbol: r'$') : (taxable <= prev ? '—' : CurrencyFormatter.format(taxInBracket, symbol: r'$')),
                            style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold),
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
          const SizedBox(height: 16),
        ],

        // Key Tax Deductions reference
        Text('KEY TAX DEDUCTIONS 2024', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGuideCard('Mortgage Interest Deduction', 'Up to \$750K loan balance · Schedule A · IRS Pub 936'),
        _buildGuideCard('SALT Deduction Cap', 'State & Local Tax capped at \$10,000 · Expires 2025'),
        _buildGuideCard('Charitable Contributions', 'Up to 60% of AGI for cash donations · 30% for assets'),
        _buildGuideCard('Medical Expense Deduction', 'Expenses exceeding 7.5% of AGI qualify'),
        _buildGuideCard('QBI Deduction (Self-Employed)', '20% deduction on qualified business income · Sec 199A'),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, String note, CountryTheme theme, BuildContext context, {bool isGold = false}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.playfair(size: 14, color: isGold ? const Color(0xFFD97706) : theme.getTextColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroResult(String label, String val, {Color? color}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
        const SizedBox(height: 4),
        Text(val, style: AppTextStyles.playfair(size: 12, color: color ?? Colors.white, weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGuideCard(String title, String desc) {
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
            child: const Text('🧾', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

