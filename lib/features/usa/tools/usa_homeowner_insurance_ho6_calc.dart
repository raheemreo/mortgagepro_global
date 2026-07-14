// lib/features/usa/tools/usa_homeowner_insurance_ho6_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceHo6Calc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAHomeownerInsuranceHo6Calc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAHomeownerInsuranceHo6Calc> createState() => _USAHomeownerInsuranceHo6CalcState();
}

class _USAHomeownerInsuranceHo6CalcState extends ConsumerState<USAHomeownerInsuranceHo6Calc> {
  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  double _interiorValue = 80000;
  double _personalPropertyValue = 40000;
  double _deductible = 1000;
  String _riskLevel = 'medium';

  bool _showResults = false;
  bool _isCalcDirty = false;
  bool _calculating = false;

  final Map<String, double> _riskMultipliers = {
    'low': 0.70,
    'medium': 1.0,
    'high': 1.40,
    'fl': 1.80
  };

  final Map<double, double> _deductibleDiscounts = {
    500: 0.04,
    1000: 0.0,
    2500: -0.08,
    5000: -0.15
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _interiorValue = inputs['InteriorValue'] ?? 80000.0;
      _personalPropertyValue = inputs['PersonalPropertyValue'] ?? 40000.0;
      _deductible = inputs['Deductible'] ?? 1000.0;
      final code = inputs['RiskLevelCode'] ?? 1.0;
      _riskLevel = code == 0.0 ? 'low' : code == 1.0 ? 'medium' : code == 2.0 ? 'high' : 'fl';
      _calcSnapshot['InteriorValue'] = _interiorValue;
      _calcSnapshot['PersonalPropertyValue'] = _personalPropertyValue;
      _calcSnapshot['Deductible'] = _deductible;
      _calcSnapshot['RiskLevel'] = _riskLevel;
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
      _interiorValue = 80000;
      _personalPropertyValue = 40000;
      _deductible = 1000;
      _riskLevel = 'medium';
      _showResults = false;
      _isCalcDirty = false;
      _calcSnapshot.clear();
    });
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _calculating = false;
      _calcSnapshot['InteriorValue'] = _interiorValue;
      _calcSnapshot['PersonalPropertyValue'] = _personalPropertyValue;
      _calcSnapshot['Deductible'] = _deductible;
      _calcSnapshot['RiskLevel'] = _riskLevel;
      _showResults = true;
      _isCalcDirty = false;
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

  void _saveCalculation() async {
    final double interiorValue = _calcSnapshot['InteriorValue'] ?? _interiorValue;
    final double personalPropertyValue = _calcSnapshot['PersonalPropertyValue'] ?? _personalPropertyValue;
    final double deductible = _calcSnapshot['Deductible'] ?? _deductible;
    final String riskLevel = _calcSnapshot['RiskLevel'] ?? _riskLevel;

    double total = interiorValue + personalPropertyValue;
    double rate = 0.0040;
    final riskMult = _riskMultipliers[riskLevel] ?? 1.0;
    final dedDisc = _deductibleDiscounts[deductible] ?? 0.0;
    double annual = total * rate * riskMult * (1 + dedDisc);
    annual = (annual / 10).round() * 10.0;
    annual = annual < 150 ? 150 : annual;
    final monthly = (annual / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'HO-6 Condo Quote');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_homeowner_insurance_ho6_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save HO-6 Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Annual: ${CurrencyFormatter.compact(annual, symbol: r'$')}/yr · Interior: ${CurrencyFormatter.compact(interiorValue, symbol: r'$')}',
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
                hintText: 'Label (e.g. My HO-6 Condo Quote)',
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
          : 'HO-6 Condo Quote';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HO-6 Condo',
        inputs: {
          'InteriorValue': interiorValue,
          'PersonalPropertyValue': personalPropertyValue,
          'Deductible': deductible,
          'RiskLevelCode': riskLevel == 'low' ? 0.0 : riskLevel == 'medium' ? 1.0 : riskLevel == 'high' ? 2.0 : 3.0,
        },
        results: {
          'Annual Premium': annual,
          'Monthly Premium': monthly,
          'Interior Limit': interiorValue,
          'Personal Prop Limit': personalPropertyValue,
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

    final double snapInteriorValue = _calcSnapshot['InteriorValue'] ?? _interiorValue;
    final double snapPersonalPropertyValue = _calcSnapshot['PersonalPropertyValue'] ?? _personalPropertyValue;
    final double snapDeductible = _calcSnapshot['Deductible'] ?? _deductible;
    final String snapRiskLevel = _calcSnapshot['RiskLevel'] ?? _riskLevel;

    // Compute active calculation
    double total = snapInteriorValue + snapPersonalPropertyValue;
    double rate = 0.0040;
    final riskMult = _riskMultipliers[snapRiskLevel] ?? 1.0;
    final dedDisc = _deductibleDiscounts[snapDeductible] ?? 0.0;
    double annualPremium = total * rate * riskMult * (1 + dedDisc);
    annualPremium = (annualPremium / 10).round() * 10.0;
    annualPremium = annualPremium < 150 ? 150 : annualPremium;
    final monthlyPremium = (annualPremium / 12).round();
    final lou = (snapInteriorValue * 0.30).roundToDouble();

    final isDirty = _showResults && (
      _interiorValue != snapInteriorValue ||
      _personalPropertyValue != snapPersonalPropertyValue ||
      _deductible != snapDeductible ||
      _riskLevel != snapRiskLevel
    );

    final riskLabels = {
      'low': 'Low-risk state',
      'medium': 'Medium risk',
      'high': 'High-risk state',
      'fl': 'Florida'
    };

    // Rate strip values
    const rateStats = [
      {'label': 'Nat\'l Avg/yr', 'value': '\$593', 'note': '2025 Avg'},
      {'label': 'vs HO-3', 'value': '74% Less', 'note': 'Lower Cost'},
      {'label': 'Coverage', 'value': 'Walls-In', 'note': 'Interior Only'},
      {'label': 'HOA Policy', 'value': 'Required', 'note': 'Master Policy'},
    ];

    // State average scroll cards
    const stateCards = [
      {'icon': '🌊', 'state': 'Florida', 'rate': '\$1,186', 'lbl': 'Highest/yr'},
      {'icon': '🌪️', 'state': 'Louisiana', 'rate': '\$980', 'lbl': 'Per year'},
      {'icon': '🌩️', 'state': 'Texas', 'rate': '\$748', 'lbl': 'Per year'},
      {'icon': '🏙️', 'state': 'New York', 'rate': '\$658', 'lbl': 'Per year'},
      {'icon': '☀️', 'state': 'California', 'rate': '\$510', 'lbl': 'Per year'},
      {'icon': '🌾', 'state': 'Ohio', 'rate': '\$387', 'lbl': 'Per year'},
      {'icon': '🌲', 'state': 'Oregon', 'rate': '\$299', 'lbl': 'Lowest/yr'},
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
                          color: stat['label'] == 'vs HO-3' || stat['label'] == 'HOA Policy' ? const Color(0xFFD97706) : textColor,
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

        // Results section or placeholder
        if (!_showResults) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('📊', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  'View HO-6 Condo Premium Estimate',
                  style: AppTextStyles.playfair(size: 13, color: textColor, weight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Adjust parameters below and tap "Calculate HO-6 Premium" to estimate your rates.',
                  style: AppTextStyles.dmSans(size: 10.5, color: mutedColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDirty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Inputs have changed. Calculate again to update results.',
                            style: AppTextStyles.dmSans(
                              size: 11.5,
                              color: const Color(0xFFB45309),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'HO-6 Estimator',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B3F72).withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANNUAL HO-6 PREMIUM ESTIMATE',
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
                        'HO-6 · ${CurrencyFormatter.compact(snapInteriorValue, symbol: r'$')} interior value · ${riskLabels[snapRiskLevel] ?? ''} · ${CurrencyFormatter.compact(snapDeductible, symbol: r'$')} ded',
                        style: AppTextStyles.dmSans(
                            size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildHeroBottomBox('Monthly', CurrencyFormatter.format(monthlyPremium.toDouble(), symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Deductible', CurrencyFormatter.format(snapDeductible, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Interior Value', '\$${(snapInteriorValue / 1000).round()}K'),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Inputs Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Configure Your HO-6',
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
              // Interior Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Interior Replacement Value'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_interiorValue, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _interiorValue,
                min: 20000,
                max: 400000,
                divisions: 76,
                activeColor: const Color(0xFF1B3F72),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _interiorValue = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$20K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$100K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$200K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$400K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Personal Property Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Personal Property Value'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_personalPropertyValue, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _personalPropertyValue,
                min: 10000,
                max: 200000,
                divisions: 38,
                activeColor: const Color(0xFF1B3F72),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _personalPropertyValue = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$10K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$60K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$120K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$200K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
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
                  _buildDedChoiceBtn('\$2,500', 2500),
                  const SizedBox(width: 6),
                  _buildDedChoiceBtn('\$5,000', 5000),
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
                  _buildRiskChoiceBtn('Florida', 'fl'),
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
                        backgroundColor: const Color(0xFF1B3F72),
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
                              'Calculate HO-6 Premium',
                              style: AppTextStyles.playfair(
                                  size: 13, weight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_showResults && !isDirty) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveCalculation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: const Color(0xFF1B3F72),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFF1B3F72), width: 2),
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

        if (_showResults && !isDirty) ...[
          // Walls-in diagram using CustomPainter
          Text(
            'Walls-In Coverage Diagram',
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
                  'What HO-6 Covers vs. HOA Master Policy',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WallsInDiagramPainter(
                      interiorValue: _interiorValue,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Coverage Details
          Text(
            'HO-6 Coverage Details',
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
              children: [
                _buildCovRow('🧱', 'Interior Structure (Walls-In)', 'Flooring, cabinets, fixtures, drywall', CurrencyFormatter.format(_interiorValue, symbol: r'$'), 'Your coverage'),
                _buildCovRow('🛋️', 'Personal Property (C)', 'Furniture, electronics, clothing', CurrencyFormatter.format(_personalPropertyValue, symbol: r'$'), 'Named perils'),
                _buildCovRow('🏨', 'Loss of Use (D)', 'Temp living if unit uninhabitable', CurrencyFormatter.format(lou, symbol: r'$'), '~30% of interior'),
                _buildCovRow('⚖️', 'Liability (E)', 'Personal injury protection', '\$100,000', 'Standard'),
                _buildCovRow('🏗️', 'HOA Special Assessment', 'Optional rider — highly recommended', '+\$50/yr', 'Up to \$50K', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // HOA Master Policy vs. Your HO-6 Gap Table
          Text(
            'HOA Master vs. HO-6',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14243C) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏢 HOA Master Policy vs. Your HO-6',
                  style: AppTextStyles.playfair(
                      size: 12.5, weight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: const Color(0xFF93C5FD).withValues(alpha: 0.2), width: 0.5),
                  ),
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeaderCell('Item', isDark ? Colors.white70 : const Color(0xFF1E3A8A)),
                        _buildTableHeaderCell('HOA Covers', const Color(0xFF15803D)),
                        _buildTableHeaderCell('HO-6 Covers', const Color(0xFF1D4ED8)),
                      ],
                    ),
                    _buildCompareRow('Roof & Exterior', '✓ HOA', '✗ No', const Color(0xFF15803D), const Color(0xFFB91C1C)),
                    _buildCompareRow('Hallways/Lobby', '✓ HOA', '✗ No', const Color(0xFF15803D), const Color(0xFFB91C1C)),
                    _buildCompareRow('Interior Walls', 'Varies', '✓ HO-6', textColor, const Color(0xFF1D4ED8)),
                    _buildCompareRow('Your Flooring', '✗ No', '✓ HO-6', const Color(0xFFB91C1C), const Color(0xFF1D4ED8)),
                    _buildCompareRow('Your Appliances', '✗ No', '✓ HO-6', const Color(0xFFB91C1C), const Color(0xFF1D4ED8)),
                    _buildCompareRow('Your Furniture', '✗ No', '✓ HO-6', const Color(0xFFB91C1C), const Color(0xFF1D4ED8)),
                    _buildCompareRow('Liability (Your Act)', '✗ No', '✓ HO-6', const Color(0xFFB91C1C), const Color(0xFF1D4ED8)),
                    _buildCompareRow('Special Assessment', 'Your cost', '✓ Rider', const Color(0xFFB91C1C), const Color(0xFF1D4ED8)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // HO-6 Avg Premiums by State
        Text(
          'Avg Premium by State',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: stateCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (_, i) {
              final c = stateCards[i];
              return Container(
                width: 95,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c['icon']!, style: const TextStyle(fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(c['state']!,
                        style: AppTextStyles.playfair(
                            size: 9, weight: FontWeight.w800, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(c['rate']!,
                        style: AppTextStyles.playfair(
                            size: 14, weight: FontWeight.w800, color: const Color(0xFF1B3F72))),
                    Text(c['lbl']!, style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Coverage Limits at a Glance bars
        if (_showResults && !isDirty) ...[
          Text(
            'HO-6 Coverage Limits',
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
                  'HO-6 Coverage Limits at a Glance',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 12),
                _buildBarRow('Interior (A)', _interiorValue, _interiorValue, colors: [const Color(0xFF1B3F72), const Color(0xFF4A90D9)]),
                const SizedBox(height: 11),
                _buildBarRow('Pers. Prop (C)', _personalPropertyValue, _interiorValue, colors: [const Color(0xFF1B3F72), const Color(0xFF4A90D9)]),
                const SizedBox(height: 11),
                _buildBarRow('Loss of Use', lou, _interiorValue, colors: [const Color(0xFF1B3F72), const Color(0xFF4A90D9)]),
                const SizedBox(height: 11),
                _buildBarRow('Liability', 100000, 100000, colors: [const Color(0xFF0B1D3A), const Color(0xFF4A5C7A)]),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Pro Tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF11223A) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 HO-6 Must-Knows',
                style: AppTextStyles.playfair(
                    size: 11, weight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
              ),
              const SizedBox(height: 5),
              Text(
                'Always add the Loss Assessment Rider (~\$50–75/yr) which covers special HOA assessments up to \$50,000. After the Surfside, FL collapse, many Florida condo owners faced \$100K+ special assessments. Also review whether your HOA has a "bare walls-in" or "all-in" master policy — bare walls means you must cover all interior structure yourself.',
                style: AppTextStyles.dmSans(
                    size: 10, color: const Color(0xFF1E3A8A), height: 1.55),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: color),
        textAlign: text == 'Item' ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  TableRow _buildCompareRow(String item, String hoaVal, String ho6Val, Color hoaColor, Color ho6Color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            item,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            hoaVal,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: hoaColor),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            ho6Val,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: ho6Color),
            textAlign: TextAlign.center,
          ),
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

  Widget _buildCovRow(String icon, String name, String desc, String amt, String pct, {bool isLast = false}) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.playfair(
                        size: 12, weight: FontWeight.w800, color: textColor)),
                Text(desc,
                    style: AppTextStyles.dmSans(size: 9.5, color: mutedColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amt,
                  style: AppTextStyles.playfair(
                      size: 13.5, weight: FontWeight.w800, color: textColor)),
              Text(pct, style: AppTextStyles.dmSans(size: 9, color: mutedColor)),
            ],
          )
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
          width: 82,
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
            color: sel ? const Color(0xFFEFF6FF) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF1B3F72) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: sel ? const Color(0xFF1D4ED8) : widget.theme.getTextColor(context))),
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
            color: sel ? const Color(0xFFEFF6FF) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF1B3F72) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: sel ? const Color(0xFF1D4ED8) : widget.theme.getTextColor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class WallsInDiagramPainter extends CustomPainter {
  final double interiorValue;
  final bool isDark;

  WallsInDiagramPainter({required this.interiorValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Building outline (HOA Master)
    final exteriorPaint = Paint()
      ..color = isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0x1A1B3F72)
      ..style = PaintingStyle.fill;
    final exteriorBorderPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final buildingRect = Rect.fromLTWH(30, 20, W - 60, H - 35);
    canvas.drawRect(buildingRect, exteriorPaint);
    canvas.drawRect(buildingRect, exteriorBorderPaint);

    // Text: HOA Master Policy
    final textPainterHOA = TextPainter(
      text: const TextSpan(
        text: 'HOA Master Policy',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B3F72),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: W);
    textPainterHOA.paint(canvas, Offset((W - textPainterHOA.width) / 2, 28));

    // HO-6 inner unit
    const ux = 60.0;
    const uy = 45.0;
    final uw = W - 120.0;
    final uh = H - 70.0;

    final ho6Paint = Paint()
      ..color = const Color(0x26D97706)
      ..style = PaintingStyle.fill;
    final ho6BorderPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final unitRect = Rect.fromLTWH(ux, uy, uw, uh);
    canvas.drawRect(unitRect, ho6Paint);

    // Dotted boundary line for HO-6
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    _drawDashedRect(canvas, unitRect, ho6BorderPaint, dashWidth, dashSpace);

    // Text: Your HO-6 Coverage
    final textPainterHO6 = TextPainter(
      text: const TextSpan(
        text: 'Your HO-6 Coverage',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF92400E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: uw);
    textPainterHO6.paint(canvas, Offset((W - textPainterHO6.width) / 2, uy + 12));

    // Text: Walls-In: $Value
    final textPainterVal = TextPainter(
      text: TextSpan(
        text: 'Walls-In: \$${(interiorValue / 1000).round()}K',
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF7C2D12),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: uw);
    textPainterVal.paint(canvas, Offset((W - textPainterVal.width) / 2, uy + 26));

    final textPainterRoof = TextPainter(
      text: const TextSpan(
        text: 'Roof →',
        style: TextStyle(fontSize: 8, color: Color(0xFF0B1D3A)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterRoof.paint(canvas, const Offset(35, 60));

    final textPainterExt = TextPainter(
      text: const TextSpan(
        text: 'Exterior →',
        style: TextStyle(fontSize: 8, color: Color(0xFF0B1D3A)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterExt.paint(canvas, const Offset(35, 78));

    final textPainterStruct = TextPainter(
      text: const TextSpan(
        text: '← Structure',
        style: TextStyle(fontSize: 8, color: Color(0xFF0B1D3A)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterStruct.paint(canvas, Offset(W - 35 - textPainterStruct.width, 60));

    // Legend
    final textPainterLegend = TextPainter(
      text: const TextSpan(
        text: '🛋️ Furniture  💻 Electronics  🎨 Upgrades',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Color(0xFF92400E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: W);
    textPainterLegend.paint(canvas, Offset((W - textPainterLegend.width) / 2, H - 12));
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, double dashWidth, double dashSpace) {
    // Top
    _drawDashedLine(canvas, Offset(rect.left, rect.top), Offset(rect.right, rect.top), paint, dashWidth, dashSpace);
    // Right
    _drawDashedLine(canvas, Offset(rect.right, rect.top), Offset(rect.right, rect.bottom), paint, dashWidth, dashSpace);
    // Bottom
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom), paint, dashWidth, dashSpace);
    // Left
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom), Offset(rect.left, rect.top), paint, dashWidth, dashSpace);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = Offset(dx, dy).distance;
    final double totalDash = dashWidth + dashSpace;
    final int count = (distance / totalDash).floor();

    final double stepX = (dx / distance) * totalDash;
    final double stepY = (dy / distance) * totalDash;

    double currentX = start.dx;
    double currentY = start.dy;

    for (int i = 0; i < count; i++) {
      final double nextDashX = currentX + (dx / distance) * dashWidth;
      final double nextDashY = currentY + (dy / distance) * dashWidth;
      canvas.drawLine(Offset(currentX, currentY), Offset(nextDashX, nextDashY), paint);
      currentX += stepX;
      currentY += stepY;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
