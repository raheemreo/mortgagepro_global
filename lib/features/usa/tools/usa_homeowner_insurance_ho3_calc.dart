// lib/features/usa/tools/usa_homeowner_insurance_ho3_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceHo3Calc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAHomeownerInsuranceHo3Calc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAHomeownerInsuranceHo3Calc> createState() => _USAHomeownerInsuranceHo3CalcState();
}

class _USAHomeownerInsuranceHo3CalcState extends ConsumerState<USAHomeownerInsuranceHo3Calc> {
  double _dwellingValue = 400000;
  double _homeAge = 15;
  double _deductible = 1000;
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
    500: 0.0,
    1000: -0.05,
    2000: -0.12,
    5000: -0.20
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _dwellingValue = inputs['DwellingValue'] ?? 400000.0;
      _homeAge = inputs['HomeAge'] ?? 15.0;
      _deductible = inputs['Deductible'] ?? 1000.0;
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
      _dwellingValue = 400000;
      _homeAge = 15;
      _deductible = 1000;
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
    double baseRate = 0.0057;
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

    final labelCtrl = TextEditingController(text: 'HO-3 Standard Quote');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save HO-3 Calculation',
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
                hintText: 'Label (e.g. My HO-3 Quote)',
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
          : 'HO-3 Standard Quote';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HO-3 Standard',
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
    double baseRate = 0.0057;
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
    final rateVal = (annualPremium / _dwellingValue * 100);

    // Coverages breakdown
    final covA = _dwellingValue;
    final covB = (_dwellingValue * 0.10).roundToDouble();
    final covC = (_dwellingValue * 0.50).roundToDouble();
    final covD = (_dwellingValue * 0.20).roundToDouble();

    final riskLabels = {
      'low': 'Low-risk state',
      'medium': 'Medium risk',
      'high': 'High-risk state',
      'extreme': 'Tornado/Gulf'
    };

    // Rate strip values
    const rateStats = [
      {'label': 'Market Share', 'value': '48%', 'note': 'Most Common'},
      {'label': 'Nat\'l Avg/yr', 'value': '\$2,285', 'note': '2025'},
      {'label': 'Dwelling', 'value': 'Open', 'note': 'All Perils'},
      {'label': 'Contents', 'value': 'Named', 'note': '16 Perils'},
    ];

    // Covered perils
    const perils = [
      {'icon': '🔥', 'name': 'Fire & Smoke', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '💨', 'name': 'Wind & Hail', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '⚡', 'name': 'Lightning', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '🚗', 'name': 'Vehicle Impact', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '💥', 'name': 'Explosion', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '🦅', 'name': 'Aircraft', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '🏚️', 'name': 'Vandalism', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '🌨️', 'name': 'Ice & Snow', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '💧', 'name': 'Water (burst)', 'status': '✓ Covered', 'color': Color(0xFF15803D)},
      {'icon': '🌊', 'name': 'Flood', 'status': '✗ Excluded', 'color': Color(0xFFB91C1C)},
      {'icon': '🌍', 'name': 'Earthquake', 'status': '✗ Excluded', 'color': Color(0xFFB91C1C)},
      {'icon': '🔥', 'name': 'Wildfire', 'status': '⚠ Rider Opt.', 'color': Color(0xFFD97706)},
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
                          color: stat['label'] == 'Market Share' || stat['label'] == 'Contents' ? const Color(0xFFD97706) : textColor,
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
          'Premium Calculator',
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
                'ANNUAL HO-3 PREMIUM ESTIMATE',
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
                'HO-3 · ${CurrencyFormatter.compact(_dwellingValue, symbol: r'$')} dwelling · ${riskLabels[_riskLevel] ?? ''} · ${CurrencyFormatter.compact(_deductible, symbol: r'$')} ded',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroBottomBox('Monthly', CurrencyFormatter.format(monthlyPremium.toDouble(), symbol: r'$')),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Deductible', CurrencyFormatter.format(_deductible, symbol: r'$')),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Rate/Value', '${rateVal.toStringAsFixed(2)}%'),
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
              'Configure Your HO-3',
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
                min: 100000,
                max: 1200000,
                divisions: 110,
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
                  Text('\$100K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$400K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$800K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1.2M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
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
                  _buildDedChoiceBtn('\$500', 500),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$1,000', 1000),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$2,000', 2000),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$5,000', 5000),
                ],
              ),
              const SizedBox(height: 16),

              // State/Risk Level Choice Buttons
              Text('State Risk Profile'.toUpperCase(),
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
                  _buildRiskChoiceBtn('Tornado/Gulf', 'extreme'),
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
                              'Calculate HO-3 Premium',
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
          // Coverage Breakdown Chart
          Text(
            'Coverage Breakdown',
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
                  'Standard HO-3 Coverage Limits',
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
                _buildBarRow('Liability (E)', 300000, 400000, colors: [const Color(0xFF1B3F72), const Color(0xFF4A5C7A)]),
                const SizedBox(height: 11),
                _buildBarRow('Medical (F)', 5000, 400000, colors: [const Color(0xFF15803D), const Color(0xFF4ADE80)]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Donut Chart cost composition
          Text(
            'Premium Cost Composition',
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
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          values: [40, 22, 18, 20],
                          colors: [
                            const Color(0xFFD97706),
                            const Color(0xFF1B3F72),
                            const Color(0xFFB45309),
                            const Color(0xFF15803D),
                          ],
                          cardColor: cardColor,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Annual',
                          style: AppTextStyles.dmSans(
                              size: 7.5, weight: FontWeight.w700, color: mutedColor),
                        ),
                        Text(
                          CurrencyFormatter.format(annualPremium, symbol: r'$'),
                          style: AppTextStyles.playfair(
                              size: 12.5, weight: FontWeight.w800, color: textColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildCostLegendItem('Fire/Wind', '40%', const Color(0xFFD97706), textColor),
                      const SizedBox(height: 6),
                      _buildCostLegendItem('Liability', '22%', const Color(0xFF1B3F72), textColor),
                      const SizedBox(height: 6),
                      _buildCostLegendItem('Theft/Vandal', '18%', const Color(0xFFB45309), textColor),
                      const SizedBox(height: 6),
                      _buildCostLegendItem('Water/Other', '20%', const Color(0xFF15803D), textColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // What HO-3 Covers
        Text(
          'What HO-3 Covers',
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
          childAspectRatio: 2.6,
          children: perils.map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Text(p['icon'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p['name'] as String,
                          style: AppTextStyles.dmSans(
                              size: 10.5, weight: FontWeight.w800, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          p['status'] as String,
                          style: AppTextStyles.dmSans(
                              size: 8.5, weight: FontWeight.w700, color: p['color'] as Color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Standard HO-3 Exclusions
        Text(
          'Standard HO-3 Exclusions',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDBA74), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚫 Standard HO-3 Exclusions',
                style: AppTextStyles.playfair(
                    size: 12.5, weight: FontWeight.w800, color: const Color(0xFF92400E)),
              ),
              const SizedBox(height: 12),
              _buildExclRow('Flood Damage', 'Requires separate NFIP policy — avg \$958/yr nationally'),
              _buildExclRow('Earthquake', 'Separate rider needed; common in CA, OR, WA, TN'),
              _buildExclRow('Sewer/Drain Backup', 'Optional add-on ~\$50–100/yr; highly recommended'),
              _buildExclRow('Wear & Tear / Neglect', 'Maintenance issues not covered — regular upkeep required'),
              _buildExclRow('Business Property', 'Home-based business needs separate endorsement'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Common HO-3 Discounts
        Text(
          'Common HO-3 Discounts',
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
            _buildDiscCard('🏷️', 'Bundle Auto+Home', '10–25%', 'Most major carriers', primaryColor, textColor, mutedColor, borderColor, cardColor),
            _buildDiscCard('🏠', 'New Construction', '8–15%', 'Home under 10 yrs', primaryColor, textColor, mutedColor, borderColor, cardColor),
            _buildDiscCard('🔐', 'Security System', '5–12%', 'Monitored alarm', primaryColor, textColor, mutedColor, borderColor, cardColor),
            _buildDiscCard('🚒', 'Fire Station ≤5mi', '3–8%', 'Class 1–4 fire dept', primaryColor, textColor, mutedColor, borderColor, cardColor),
            _buildDiscCard('🌞', 'Impact Windows', '5–10%', 'Storm hardening', primaryColor, textColor, mutedColor, borderColor, cardColor),
            _buildDiscCard('📆', 'Loyalty/No Claims', '5–10%', 'After 3+ claim-free yrs', primaryColor, textColor, mutedColor, borderColor, cardColor),
          ],
        ),
        const SizedBox(height: 20),

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
                '💡 HO-3 Pro Tip',
                style: AppTextStyles.playfair(
                    size: 11, weight: FontWeight.w800, color: const Color(0xFF92400E)),
              ),
              const SizedBox(height: 5),
              Text(
                'HO-3 covers your dwelling on an open-perils basis (all causes except exclusions) but personal property only on named-perils (16 specific causes). Upgrade to HO-5 to get open-perils on both. Always insure to full replacement cost — not market value — as rebuilding costs have risen 20–35% since 2020.',
                style: AppTextStyles.dmSans(
                    size: 10, color: const Color(0xFF7C2D12), height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExclRow(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5, right: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFB91C1C),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                      size: 10.5, weight: FontWeight.w700, color: const Color(0xFF7C2D12)),
                ),
                Text(
                  sub,
                  style: AppTextStyles.dmSans(
                      size: 9, color: const Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostLegendItem(String label, String pct, Color color, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.dmSans(
                  size: 10.5, weight: FontWeight.w700, color: textColor),
            ),
          ],
        ),
        Text(
          pct,
          style: AppTextStyles.playfair(
              size: 11, weight: FontWeight.w800, color: textColor),
        ),
      ],
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

  Widget _buildDiscCard(String icon, String name, String pct, String sub,
      Color primaryColor, Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTextStyles.dmSans(
                size: 11, weight: FontWeight.w800, color: textColor),
          ),
          Text(
            pct,
            style: AppTextStyles.playfair(
                size: 15, weight: FontWeight.w800, color: primaryColor),
          ),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 9, color: mutedColor),
          ),
        ],
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

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color cardColor;

  DonutChartPainter({required this.values, required this.colors, required this.cardColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -3.1415926535 / 2;
    double total = values.fold(0, (sum, item) => sum + item);

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * 3.1415926535;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = cardColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.65, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
