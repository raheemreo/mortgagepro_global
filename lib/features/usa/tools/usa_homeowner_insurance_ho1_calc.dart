// lib/features/usa/tools/usa_homeowner_insurance_ho1_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceHo1Calc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAHomeownerInsuranceHo1Calc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAHomeownerInsuranceHo1Calc> createState() => _USAHomeownerInsuranceHo1CalcState();
}

class _USAHomeownerInsuranceHo1CalcState extends ConsumerState<USAHomeownerInsuranceHo1Calc> {
  double _dwellingValue = 200000;
  double _homeAge = 20;
  double _deductible = 1000;
  String _riskLevel = 'medium';

  bool _showResults = true;
  bool _isCalcDirty = false;
  bool _calculating = false;

  final Map<String, double> _riskMultipliers = {
    'low': 0.75,
    'medium': 1.0,
    'high': 1.45
  };

  final Map<double, double> _deductibleDiscounts = {
    500: 0.04,
    1000: 0.0,
    2000: -0.08,
    5000: -0.16
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _dwellingValue = inputs['DwellingValue'] ?? 200000.0;
      _homeAge = inputs['HomeAge'] ?? 20.0;
      _deductible = inputs['Deductible'] ?? 1000.0;
      final code = inputs['RiskLevelCode'] ?? 1.0;
      _riskLevel = code == 0.0 ? 'low' : code == 1.0 ? 'medium' : 'high';
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
      _dwellingValue = 200000;
      _homeAge = 20;
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
    double baseRate = 0.0057 * 0.70; // HO-1 is ~30% less than HO-3
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

    final labelCtrl = TextEditingController(text: 'HO-1 Basic Quote');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_homeowner_insurance_ho1_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save HO-1 Calculation',
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
                hintText: 'Label (e.g. My HO-1 Quote)',
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
          : 'HO-1 Basic Quote';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HO-1 Basic',
        inputs: {
          'DwellingValue': _dwellingValue,
          'HomeAge': _homeAge,
          'Deductible': _deductible,
          'RiskLevelCode': _riskLevel == 'low' ? 0.0 : _riskLevel == 'medium' ? 1.0 : 2.0,
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
    double baseRate = 0.0057 * 0.70; // HO-1 ~30% less than HO-3
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

    final riskLabels = {
      'low': 'Low-risk state',
      'medium': 'Medium risk',
      'high': 'High-risk state'
    };

    // Rate strip values
    const rateStats = [
      {'label': 'vs HO-3 Cost', 'value': '−25–35%', 'note': 'Lower Premium'},
      {'label': 'Perils', 'value': '11', 'note': 'Named Only'},
      {'label': 'Availability', 'value': 'Limited', 'note': 'Not All States'},
      {'label': 'Liability', 'value': 'Optional', 'note': 'Not Always Inc.'},
    ];

    // 11 Named Perils
    const perils = [
      {'icon': '🔥', 'name': 'Fire & Lightning'},
      {'icon': '💥', 'name': 'Explosion'},
      {'icon': '💨', 'name': 'Windstorm & Hail'},
      {'icon': '✈️', 'name': 'Aircraft Damage'},
      {'icon': '🚗', 'name': 'Vehicle Impact'},
      {'icon': '🌋', 'name': 'Volcanic Eruption'},
      {'icon': '🏚️', 'name': 'Vandalism'},
      {'icon': '🧊', 'name': 'Freezing Pipes'},
      {'icon': '🌨️', 'name': 'Snow & Ice Load'},
      {'icon': '💡', 'name': 'Electrical Surge'},
      {'icon': '🎇', 'name': 'Smoke/Riot'},
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
                          color: stat['label'] == 'vs HO-3 Cost' || stat['label'] == 'Liability' ? const Color(0xFFD97706) : textColor,
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
          'HO-1 Estimator',
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
                'ANNUAL HO-1 PREMIUM ESTIMATE',
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
                'HO-1 · ${CurrencyFormatter.compact(_dwellingValue, symbol: r'$')} dwelling · ${riskLabels[_riskLevel] ?? ''} · ${CurrencyFormatter.compact(_deductible, symbol: r'$')} ded',
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
                  _buildHeroBottomBox('Perils Covered', '11 Named'),
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
              'Configure Your HO-1',
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
                  Text('Dwelling Value'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_dwellingValue, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _dwellingValue,
                min: 50000,
                max: 600000,
                divisions: 55,
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
                  Text('\$50K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$200K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$400K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$600K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
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
              Text('State Risk Level'.toUpperCase(),
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
                              'Calculate HO-1 Premium',
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

        // The 11 Named Perils List
        Text(
          'The 11 Named Perils',
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
              Row(
                children: [
                  Text(
                    'HO-1 Covers ONLY These Perils',
                    style: AppTextStyles.playfair(
                        size: 12, weight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '11',
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.7,
                children: [
                  ...perils.map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(p['icon']!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p['name']!,
                                    style: AppTextStyles.dmSans(
                                        size: 10, weight: FontWeight.w800, color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '✓ Covered',
                                    style: AppTextStyles.dmSans(
                                        size: 8.5, weight: FontWeight.w700, color: const Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('🌊', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Flood/Quake',
                                style: AppTextStyles.dmSans(
                                    size: 10, weight: FontWeight.w800, color: textColor),
                              ),
                              Text(
                                '✗ NOT Covered',
                                style: AppTextStyles.dmSans(
                                    size: 8, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Coverage comparison bar chart
        Text(
          'Coverage vs. Other Policies',
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
                'Perils Coverage by Policy Type',
                style: AppTextStyles.playfair(
                    size: 12, weight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 12),
              _buildCompareBarRow('HO-1 Basic', '11 Perils', 0.30, const Color(0xFFB91C1C)),
              const SizedBox(height: 10),
              _buildCompareBarRow('HO-2 Broad', '16 Perils', 0.48, const Color(0xFFD97706)),
              const SizedBox(height: 10),
              _buildCompareBarRow('HO-3 Standard', 'Open Dwlg', 0.80, const Color(0xFFD97706)),
              const SizedBox(height: 10),
              _buildCompareBarRow('HO-5 Premium', 'Open All', 1.00, const Color(0xFF15803D)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Premium comparison chart using CustomPainter
        if (_showResults && !_isCalcDirty) ...[
          Text(
            'Premium Comparison',
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
                  'Annual Premium Comparison (\$300K Home)',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: PremiumBarChartPainter(
                      bars: [
                        PremiumBarItem(label: 'HO-1', value: 1330, color: const Color(0xFFB91C1C)),
                        PremiumBarItem(label: 'HO-2', value: 1710, color: const Color(0xFFD97706)),
                        PremiumBarItem(label: 'HO-3', value: 1900, color: const Color(0xFFB45309)),
                        PremiumBarItem(label: 'HO-5', value: 2280, color: const Color(0xFF15803D)),
                      ],
                      maxVal: 2500,
                      labelColor: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Warning banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Important HO-1 Limitations',
                style: AppTextStyles.playfair(
                    size: 12, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
              ),
              const SizedBox(height: 10),
              _buildWarningRow('Not Available in Many States', 'Phased out in most states due to inadequate coverage — check availability'),
              _buildWarningRow('Mortgage Lenders May Reject It', 'Most lenders require at minimum an HO-3 for loan approval'),
              _buildWarningRow('No Theft Coverage', 'Unlike HO-3/HO-5 — theft of personal property is NOT a named peril in HO-1'),
              _buildWarningRow('Actual Cash Value Only', 'Pays depreciated value, not full replacement cost — you may receive far less than rebuild cost'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Who uses HO-1
        Text(
          'Who HO-1 is For',
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
            _buildWhoCard('🏚️', 'Vacant/Seasonal', 'Low-value or seasonal properties not occupied year-round', textColor, mutedColor, borderColor, cardColor),
            _buildWhoCard('🔨', 'Fixer-Uppers', 'Renovation projects needing minimal short-term coverage', textColor, mutedColor, borderColor, cardColor),
            _buildWhoCard('💰', 'Very Low Value', 'Properties under \$100K in rural areas where HO-3 premiums are disproportionate', textColor, mutedColor, borderColor, cardColor),
            _buildWhoCard('🏘️', 'Investment Properties', 'Non-owner-occupied structures where landlord policy isn\'t an option', textColor, mutedColor, borderColor, cardColor),
          ],
        ),
        const SizedBox(height: 20),

        // Expert Recommendation
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
                '⚠️ Expert Recommendation',
                style: AppTextStyles.playfair(
                    size: 11, weight: FontWeight.w800, color: const Color(0xFF92400E)),
              ),
              const SizedBox(height: 5),
              Text(
                'Most insurance professionals do not recommend HO-1 as a long-term policy for primary residences. It covers only 11 named perils, often excludes theft, and pays actual cash value (not replacement cost). If cost is a concern, consider a higher-deductible HO-3 instead — it offers dramatically better protection for a modest premium increase.',
                style: AppTextStyles.dmSans(
                    size: 10, color: const Color(0xFF7C2D12), height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5, right: 8),
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
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: const Color(0xFF7F1D1D)),
                ),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareBarRow(String label, String value, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getMutedColor(context)),
            ),
            Text(
              value,
              style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhoCard(String icon, String title, String desc, Color textColor,
      Color mutedColor, Color borderColor, Color cardColor) {
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
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 5),
          Text(
            title,
            style: AppTextStyles.dmSans(
                size: 11, weight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              desc,
              style: AppTextStyles.dmSans(size: 9, color: mutedColor),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
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

class PremiumBarItem {
  final String label;
  final double value;
  final Color color;

  PremiumBarItem({required this.label, required this.value, required this.color});
}

class PremiumBarChartPainter extends CustomPainter {
  final List<PremiumBarItem> bars;
  final double maxVal;
  final Color labelColor;

  PremiumBarChartPainter({required this.bars, required this.maxVal, required this.labelColor});

  @override
  void paint(Canvas canvas, Size size) {
    final H = size.height;
    final W = size.width;
    const bw = 40.0;
    final gap = (W - 80.0) / (bars.length);

    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final x = 40.0 + i * gap + (gap - bw) / 2;
      final bh = (b.value / maxVal) * (H - 30.0);
      final y = H - 20.0 - bh;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, bw, bh),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);

      // Label text inside bar if big enough
      if (bh > 14) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '\$${(b.value / 1000).toStringAsFixed(1)}K',
            style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: bw);
        textPainter.paint(canvas, Offset(x + (bw - textPainter.width) / 2, y + 2));
      }

      // X-Axis labels
      final labelPainter = TextPainter(
        text: TextSpan(
          text: b.label,
          style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: bw);
      labelPainter.paint(canvas, Offset(x + (bw - labelPainter.width) / 2, H - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
