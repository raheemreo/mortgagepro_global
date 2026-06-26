// lib/features/usa/tools/usa_homeowner_insurance_ho5_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceHo5Calc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAHomeownerInsuranceHo5Calc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAHomeownerInsuranceHo5Calc> createState() => _USAHomeownerInsuranceHo5CalcState();
}

class _USAHomeownerInsuranceHo5CalcState extends ConsumerState<USAHomeownerInsuranceHo5Calc> {
  double _dwellingValue = 500000;
  double _homeAge = 10;
  double _deductible = 2500;
  String _riskLevel = 'medium';

  bool _showResults = true;
  bool _isCalcDirty = false;
  bool _calculating = false;

  final Map<String, double> _riskMultipliers = {
    'low': 0.75,
    'medium': 1.0,
    'high': 1.45,
    'extreme': 1.95
  };

  final Map<double, double> _deductibleDiscounts = {
    1000: 0.0,
    2500: -0.08,
    5000: -0.15,
    10000: -0.22
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _dwellingValue = inputs['DwellingValue'] ?? 500000.0;
      _homeAge = inputs['HomeAge'] ?? 10.0;
      _deductible = inputs['Deductible'] ?? 2500.0;
      final code = inputs['RiskLevelCode'] ?? 1.0;
      _riskLevel = code == 0.0 ? 'low' : code == 1.0 ? 'medium' : code == 2.0 ? 'high' : 'extreme';
      _showResults = true;
      _isCalcDirty = false;
    }
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  void _resetInputs() {
    setState(() {
      _dwellingValue = 500000;
      _homeAge = 10;
      _deductible = 2500;
      _riskLevel = 'medium';
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    double baseRate = 0.0057 * 1.20;
    if (_homeAge > 50) {
      baseRate *= 1.35;
    } else if (_homeAge > 30) {
      baseRate *= 1.18;
    } else if (_homeAge > 15) {
      baseRate *= 1.08;
    }

    final riskMult = _riskMultipliers[_riskLevel] ?? 1.0;
    final dedDisc = _deductibleDiscounts[_deductible] ?? 0.0;
    double annual = _dwellingValue * baseRate * riskMult * (1 + dedDisc);
    annual = (annual / 10).round() * 10.0;
    final monthly = (annual / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'HO-5 Premium Quote');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save HO-5 Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Annual: ${CurrencyFormatter.compact(annual, symbol: r'$')}/yr · Dwelling: ${CurrencyFormatter.compact(_dwellingValue, symbol: r'$')}',
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
                hintText: 'Label (e.g. My HO-5 Quote)',
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
          : 'HO-5 Premium Quote';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HO-5 Premium',
        inputs: {
          'DwellingValue': _dwellingValue,
          'HomeAge': _homeAge,
          'Deductible': _deductible,
          'RiskLevelCode': _riskLevel == 'low' ? 0.0 : _riskLevel == 'medium' ? 1.0 : _riskLevel == 'high' ? 2.0 : 3.0,
        },
        results: {
          'Annual Premium': annual,
          'Monthly Premium': monthly,
          'Dwelling Limit': _dwellingValue,
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
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.getCardColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    // Compute active calculation
    double baseRate = 0.0057 * 1.20; // HO-5 is ~20% more than HO-3
    if (_homeAge > 50) {
      baseRate *= 1.35;
    } else if (_homeAge > 30) {
      baseRate *= 1.18;
    } else if (_homeAge > 15) {
      baseRate *= 1.08;
    }

    final riskMult = _riskMultipliers[_riskLevel] ?? 1.0;
    final dedDisc = _deductibleDiscounts[_deductible] ?? 0.0;
    double annualPremium = _dwellingValue * baseRate * riskMult * (1 + dedDisc);
    annualPremium = (annualPremium / 10).round() * 10.0;
    final monthlyPremium = (annualPremium / 12).round();

    // Benchmark HO-3 rate (no age factor, medium risk, $1000 ded) for comparison
    final ho3Benchmark = (_dwellingValue * 0.0057 * riskMult).roundToDouble();
    final diff = annualPremium - ho3Benchmark;

    // Coverages breakdown
    final covA = _dwellingValue;
    final covB = (_dwellingValue * 0.10).roundToDouble();
    final covC = (_dwellingValue * 0.70).roundToDouble(); // HO-5 standard is 70% of dwelling
    final covD = (_dwellingValue * 0.20).roundToDouble();

    final riskLabels = {
      'low': 'Low-risk state',
      'medium': 'Medium risk',
      'high': 'High-risk state',
      'extreme': 'Gulf/CA'
    };

    // Rate strip values
    const rateStats = [
      {'label': 'Cost vs HO-3', 'value': '+15–25%', 'note': 'Premium'},
      {'label': 'Coverage', 'value': 'Open', 'note': 'All Perils'},
      {'label': 'Contents', 'value': 'Open', 'note': 'All Perils'},
      {'label': 'Ideal For', 'value': 'High-Value', 'note': 'Homes \$500K+'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2547) : const Color(0xFFE2ECF7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: rateStats.map((stat) {
              final idx = rateStats.indexOf(stat);
              final isLast = idx == rateStats.length - 1;
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            right: BorderSide(
                                color: textColor.withValues(alpha: 0.12),
                                width: 1),
                          ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        stat['label']!,
                        style: AppTextStyles.dmSans(
                            size: 8.5, weight: FontWeight.w700, color: mutedColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat['value']!,
                        style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.w800,
                          color: stat['label'] == 'Cost vs HO-3' || stat['label'] == 'Ideal For' ? const Color(0xFFD97706) : textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        stat['note']!,
                        style: AppTextStyles.dmSans(
                            size: 7.5, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Result Hero Panel
        Text(
          'HO-5 Premium Estimator',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C2D12), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C2D12).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANNUAL HO-5 PREMIUM ESTIMATE',
                style: AppTextStyles.dmSans(
                    size: 8,
                    weight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(annualPremium, symbol: r'$'),
                style: AppTextStyles.playfair(
                    size: 32, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'HO-5 · ${CurrencyFormatter.compact(_dwellingValue, symbol: r'$')} dwelling · ${riskLabels[_riskLevel] ?? ''}',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroBottomBox('Monthly', CurrencyFormatter.format(monthlyPremium.toDouble(), symbol: r'$')),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('vs HO-3 Diff', '${diff >= 0 ? '+' : ''}${CurrencyFormatter.format(diff, symbol: r'$')}/yr'),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Contents Mode', 'Open Perils'),
                ],
              )
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Inputs Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configure Your HO-5',
              style: AppTextStyles.playfair(
                  size: 13, weight: FontWeight.w700, color: textColor),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                    size: 11, color: primaryColor, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dwelling Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dwelling Replacement Value'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_dwellingValue, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _dwellingValue,
                min: 200000,
                max: 2000000,
                divisions: 72,
                activeColor: const Color(0xFFD97706),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _dwellingValue = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$200K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$600K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1.2M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$2.0M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Home Age Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Home Age'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_homeAge.toInt()} yrs',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _homeAge,
                min: 0,
                max: 80,
                divisions: 16,
                activeColor: const Color(0xFFD97706),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _homeAge = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('20 yr', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('40 yr', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('80 yr', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Deductible Choice Buttons
              Text('Deductible'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDedChoiceBtn('\$1,000', 1000),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$2,500', 2500),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$5,000', 5000),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$10,000', 10000),
                ],
              ),
              const SizedBox(height: 16),

              // State/Risk Level Choice Buttons
              Text('State / Risk Level'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRiskChoiceBtn('Low Risk', 'low'),
                  const SizedBox(width: 6),
                  _buildRiskChoiceBtn('Medium', 'medium'),
                  const SizedBox(width: 6),
                  _buildRiskChoiceBtn('High Risk', 'high'),
                  const SizedBox(width: 6),
                  _buildRiskChoiceBtn('Gulf/CA', 'extreme'),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _calculating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Calculate HO-5 Premium',
                              style: AppTextStyles.playfair(
                                  size: 13, weight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_showResults && !_isCalcDirty) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveCalculation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFD97706), width: 2),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('💾', style: TextStyle(fontSize: 19)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_showResults && !_isCalcDirty) ...[
          // HO-3 vs HO-5 Comparison Side-by-side
          Text(
            'HO-3 vs. HO-5 Comparison',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Side-by-Side Feature Comparison',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: borderColor, width: 0.5),
                  ),
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeaderCell('Feature', textColor),
                        _buildTableHeaderCell('HO-3', textColor),
                        _buildTableHeaderCell('HO-5 💎', const Color(0xFFD97706)),
                      ],
                    ),
                    _buildCompareRow('Dwelling Coverage', 'Open Perils', 'Open Perils', Colors.green, Colors.green),
                    _buildCompareRow('Personal Property', 'Named Perils', 'Open Perils', Colors.amber, Colors.green),
                    _buildCompareRow('Replacement Cost', 'Optional', 'Included', Colors.amber, Colors.green),
                    _buildCompareRow('Scheduled Items', 'Add-on', 'Built-In', Colors.amber, Colors.green),
                    _buildCompareRow('Water Backup', 'Add-on', 'Usually Inc.', Colors.red, Colors.green),
                    _buildCompareRow('ID Theft Protection', 'Rare', 'Often Inc.', Colors.red, Colors.green),
                    _buildCompareRow('Avg Annual Cost', '\$2,285', '~\$2,740+', textColor, const Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Coverage vs Cost Analysis Bars
          Text(
            'Coverage vs Cost Analysis',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HO-5 Value at Different Price Points',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 12),
                _buildValueBarRow('\$300K Home — HO-3', '\$1,710/yr', 0.43, const Color(0xFF1B3F72), textColor),
                const SizedBox(height: 10),
                _buildValueBarRow('\$300K Home — HO-5', '\$2,050/yr', 0.51, const Color(0xFFD97706), textColor),
                const SizedBox(height: 10),
                _buildValueBarRow('\$500K Home — HO-3', '\$2,850/yr', 0.71, const Color(0xFF1B3F72), textColor),
                const SizedBox(height: 10),
                _buildValueBarRow('\$500K Home — HO-5', '\$3,420/yr', 0.86, const Color(0xFFD97706), textColor),
                const SizedBox(height: 10),
                _buildValueBarRow('\$1M Home — HO-5', '\$6,840/yr', 1.0, const Color(0xFFB45309), textColor),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // HO-5 Exclusive Benefits
        Text(
          'HO-5 Exclusive Benefits',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            _buildBenefitCard('👜', 'Open Perils Contents', '✓ All Causes', 'Not just 16 named perils', isDark, cardColor, borderColor, textColor, mutedColor),
            _buildBenefitCard('💍', 'Jewelry Scheduling', '✓ Built-In Option', 'High-value items coverage', isDark, cardColor, borderColor, textColor, mutedColor, isGold: true),
            _buildBenefitCard('💻', 'Electronics RCV', '✓ Replacement Cost', 'New for old, no depreciation', isDark, cardColor, borderColor, textColor, mutedColor, isGold: true),
            _buildBenefitCard('🎨', 'Fine Arts/Antiques', '✓ Scheduled', 'Agreed value payout', isDark, cardColor, borderColor, textColor, mutedColor, isGold: true),
            _buildBenefitCard('🛡️', 'Identity Theft', 'Often Included', 'Up to \$25,000', isDark, cardColor, borderColor, textColor, mutedColor),
            _buildBenefitCard('💧', 'Water Backup', 'Often Included', 'Sewer/drain backup', isDark, cardColor, borderColor, textColor, mutedColor),
          ],
        ),
        const SizedBox(height: 20),

        if (_showResults && !_isCalcDirty) ...[
          // HO-5 Coverage Limits
          Text(
            'Coverage Limits',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HO-5 Standard Coverage Limits',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 12),
                _buildBarRow('Dwelling (A)', covA, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Other Struct (B)', covB, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Personal Prop (C)', covC, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Loss of Use (D)', covD, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Liability (E)', 500000, 500000, colors: [const Color(0xFF1B3F72), const Color(0xFF4A5C7A)]),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Pro Tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💎 When HO-5 Is Worth It',
                style: AppTextStyles.playfair(
                    size: 11, weight: FontWeight.w800, color: const Color(0xFF92400E)),
              ),
              const SizedBox(height: 5),
              Text(
                'HO-5 is the gold standard for homes \$400,000+, or owners with valuable personal property (jewelry, art, tech). The 15–25% premium increase typically costs \$400–800/yr more than HO-3, but provides replacement cost on all contents without depreciation. Especially valuable if you own: collectibles, high-end electronics, designer clothing, or instruments.',
                style: AppTextStyles.dmSans(
                    size: 10, color: const Color(0xFF7C2D12), height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: textColor),
        textAlign: text == 'Feature' ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  TableRow _buildCompareRow(String feature, String ho3Val, String ho5Val, Color ho3Color, Color ho5Color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            feature,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            ho3Val,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: ho3Color),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            ho5Val,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: ho5Color),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildValueBarRow(String label, String value, double pct, Color color, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context)),
            ),
            Text(
              value,
              style: AppTextStyles.playfair(size: 10, weight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitCard(String icon, String title, String status, String sub,
      bool isDark, Color cardColor, Color borderColor, Color textColor, Color mutedColor, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGold
            ? (isDark ? const Color(0xFF33200F) : const Color(0xFFFFFBF0))
            : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isGold ? const Color(0xFFFDBA74) : borderColor,
            width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 5),
          Text(
            title,
            style: AppTextStyles.dmSans(
                size: 11, weight: FontWeight.w800, color: textColor),
          ),
          Text(
            status,
            style: AppTextStyles.dmSans(
                size: 9.5, weight: FontWeight.w700, color: const Color(0xFF15803D)),
          ),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 9, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBottomBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String label, double val, double maxVal, {required List<Color> colors}) {
    final fillPct = (val / maxVal).clamp(0.0, 1.0);
    final textColor = widget.theme.getTextColor(context);
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 9.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context)),
          ),
        ),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fillPct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 62,
          child: Text(
            CurrencyFormatter.format(val, symbol: r'$'),
            style: AppTextStyles.playfair(
                size: 11, weight: FontWeight.w800, color: textColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDedChoiceBtn(String label, double val) {
    final sel = _deductible == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _deductible = val;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFFFF7ED) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFFD97706) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: sel ? const Color(0xFF92400E) : widget.theme.getTextColor(context))),
        ),
      ),
    );
  }

  Widget _buildRiskChoiceBtn(String label, String val) {
    final sel = _riskLevel == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _riskLevel = val;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFFFF7ED) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFFD97706) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: sel ? const Color(0xFF92400E) : widget.theme.getTextColor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
