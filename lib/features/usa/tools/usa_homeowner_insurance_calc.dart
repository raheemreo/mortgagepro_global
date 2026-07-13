// lib/features/usa/tools/usa_homeowner_insurance_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAHomeownerInsuranceCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAHomeownerInsuranceCalc> createState() => _USAHomeownerInsuranceCalcState();
}

class _USAHomeownerInsuranceCalcState extends ConsumerState<USAHomeownerInsuranceCalc> {
  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  double _dwellingValue = 300000;
  double _homeAge = 15;
  double _deductible = 500;
  String _riskLevel = 'medium';

  bool _showResults = false;
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

  void _resetInputs() {
    setState(() {
      _dwellingValue = 300000;
      _homeAge = 15;
      _deductible = 500;
      _riskLevel = 'medium';
      _calcSnapshot.clear();
      _showResults = false;
    });
  }

  void _markDirty() {}

  // Unused: _loadSavedCalculation removed to resolve analyzer warnings.

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _calcSnapshot['dwellingValue'] = _dwellingValue;
      _calcSnapshot['homeAge'] = _homeAge;
      _calcSnapshot['deductible'] = _deductible;
      _calcSnapshot['riskLevel'] = _riskLevel;
      _calculating = false;
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

  void _saveCalculation() async {
    final dwellingValue = _showResults ? (_calcSnapshot['dwellingValue'] ?? 300000.0) : _dwellingValue;
    final homeAge = _showResults ? (_calcSnapshot['homeAge'] ?? 15.0) : _homeAge;
    final deductible = _showResults ? (_calcSnapshot['deductible'] ?? 500.0) : _deductible;
    final riskLevel = _showResults ? (_calcSnapshot['riskLevel'] ?? 'medium') : _riskLevel;

    double baseRate = 0.0057;
    if (homeAge > 50) {
      baseRate *= 1.35;
    } else if (homeAge > 30) {
      baseRate *= 1.18;
    } else if (homeAge > 15) {
      baseRate *= 1.08;
    }

    final riskMult = _riskMultipliers[riskLevel] ?? 1.0;
    final dedDisc = _deductibleDiscounts[deductible] ?? 0.0;
    double annual = dwellingValue * baseRate * riskMult * (1 + dedDisc);
    annual = (annual / 10).round() * 10.0;
    final monthly = (annual / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'Homeowner Insurance');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_homeowner_insurance_calc/save'),
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
              'Saving: Annual: ${CurrencyFormatter.compact(annual, symbol: r'$')}/yr · Dwelling: ${CurrencyFormatter.compact(dwellingValue, symbol: r'$')}',
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
                hintText: 'Label (e.g. My Homeowner Quote)',
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
          : 'Homeowner Insurance';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Homeowner Insurance',
        inputs: {
          'DwellingValue': dwellingValue,
          'HomeAge': homeAge,
          'Deductible': deductible,
          'RiskLevelCode': riskLevel == 'low' ? 0.0 : riskLevel == 'medium' ? 1.0 : riskLevel == 'high' ? 2.0 : 3.0,
        },
        results: {
          'Annual Premium': annual,
          'Monthly Premium': monthly,
          'Dwelling Limit': dwellingValue,
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

    // Rate strip values
    const rateStats = [
      {'label': 'Nat\'l Avg/yr', 'value': '\$2,285', 'note': '2025 Avg'},
      {'label': '\$/Mo Avg', 'value': '\$190', 'note': 'Per Month'},
      {'label': 'Highest', 'value': 'Oklahoma', 'note': '\$5,979/yr'},
      {'label': 'Lowest', 'value': 'Hawaii', 'note': '\$499/yr'},
    ];

    final dwellingValue = _showResults ? (_calcSnapshot['dwellingValue'] ?? 300000.0) : _dwellingValue;
    final homeAge = _showResults ? (_calcSnapshot['homeAge'] ?? 15.0) : _homeAge;
    final deductible = _showResults ? (_calcSnapshot['deductible'] ?? 500.0) : _deductible;
    final riskLevel = _showResults ? (_calcSnapshot['riskLevel'] ?? 'medium') : _riskLevel;

    final isDirty = _showResults && (
      _dwellingValue != (_calcSnapshot['dwellingValue'] ?? 300000.0) ||
      _homeAge != (_calcSnapshot['homeAge'] ?? 15.0) ||
      _deductible != (_calcSnapshot['deductible'] ?? 500.0) ||
      _riskLevel != (_calcSnapshot['riskLevel'] ?? 'medium')
    );

    // Compute active calculation
    double baseRate = 0.0057;
    if (homeAge > 50) {
      baseRate *= 1.35;
    } else if (homeAge > 30) {
      baseRate *= 1.18;
    } else if (homeAge > 15) {
      baseRate *= 1.08;
    }

    final riskMult = _riskMultipliers[riskLevel] ?? 1.0;
    final dedDisc = _deductibleDiscounts[deductible] ?? 0.0;
    double annualPremium = dwellingValue * baseRate * riskMult * (1 + dedDisc);
    annualPremium = (annualPremium / 10).round() * 10.0;
    final monthlyPremium = (annualPremium / 12).round();
    final covRatio = annualPremium / dwellingValue * 100;

    // Coverages breakdown
    final covA = dwellingValue;
    final covB = (dwellingValue * 0.10).roundToDouble();
    final covC = (dwellingValue * 0.50).roundToDouble();
    final covD = (dwellingValue * 0.20).roundToDouble();

    final riskLabels = {
      'low': 'Low-risk state · standard HO-3',
      'medium': 'Medium-risk · standard HO-3',
      'high': 'High-risk state · elevated rates',
      'extreme': 'Tornado/Gulf Coast · windstorm add-on'
    };

    // State average items
    const stateCards = [
      {'icon': '🌪️', 'state': 'Oklahoma', 'rate': '\$5,979', 'lbl': 'Highest/yr'},
      {'icon': '🌀', 'state': 'Kansas', 'rate': '\$4,652', 'lbl': 'Per year'},
      {'icon': '🌩️', 'state': 'Texas', 'rate': '\$4,043', 'lbl': 'Per year'},
      {'icon': '🌊', 'state': 'Florida', 'rate': '\$3,878', 'lbl': 'Per year'},
      {'icon': '🏔️', 'state': 'Colorado', 'rate': '\$3,383', 'lbl': 'Per year'},
      {'icon': '🌴', 'state': 'California', 'rate': '\$1,380', 'lbl': 'Per year'},
      {'icon': '🌺', 'state': 'Hawaii', 'rate': '\$499', 'lbl': 'Lowest/yr'},
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
                          color: stat['label'] == 'Nat\'l Avg/yr' || stat['label'] == 'Highest' ? const Color(0xFFD97706) : textColor,
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

        if (!_showResults)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('🏡', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Home Details Below',
                  style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll estimate your annual homeowner premium, monthly PITI tax portion, and Coverage A-F policy limits.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(size: 10.5, color: mutedColor),
                ),
              ],
            ),
          )
        else ...[
          Text(
            'Your Estimate',
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
                  'ANNUAL PREMIUM ESTIMATE',
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
                  'HO-3 · ${CurrencyFormatter.compact(dwellingValue, symbol: r'$')} dwelling · ${riskLabels[riskLevel] ?? ''}',
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildHeroBottomBox('Monthly', CurrencyFormatter.format(monthlyPremium.toDouble(), symbol: r'$')),
                    const SizedBox(width: 8),
                    _buildHeroBottomBox('Deductible', CurrencyFormatter.format(deductible, symbol: r'$')),
                    const SizedBox(width: 8),
                    _buildHeroBottomBox('Coverage/Val', '${covRatio.toStringAsFixed(2)}%'),
                  ],
                )
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Your Home Details inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Home Details',
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
              // Dwelling replacement value Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Home Replacement Value'.toUpperCase(),
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
                max: 1000000,
                divisions: 90,
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
                  Text('\$300K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$600K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Home Age Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Home Age (Years)'.toUpperCase(),
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
                              'Calculate Premium',
                              style: AppTextStyles.playfair(
                                  size: 13, weight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_showResults) ...[
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
                            'Inputs have changed. Tap "Calculate Premium" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Coverage Breakdown Chart
          Text(
            'Coverage Breakdown Chart',
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
                _buildBarRow('Dwelling (A)', covA, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Other Struct (B)', covB, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Personal Prop (C)', covC, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
                const SizedBox(height: 11),
                _buildBarRow('Loss of Use (D)', covD, covA, colors: [const Color(0xFFD97706), const Color(0xFFFCD34D)]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // HO-3 Coverage Breakdown policy summary
          Text(
            'HO-3 Coverage Breakdown',
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
                _buildCovRow('🏠', 'Coverage A – Dwelling', 'Structure of your home', CurrencyFormatter.format(covA, symbol: r'$'), '100%'),
                _buildCovRow('🏚️', 'Coverage B – Other Structures', 'Fence, garage, shed', CurrencyFormatter.format(covB, symbol: r'$'), '10%'),
                _buildCovRow('🛋️', 'Coverage C – Personal Property', 'Furniture, electronics, clothing', CurrencyFormatter.format(covC, symbol: r'$'), '50%'),
                _buildCovRow('🏨', 'Coverage D – Loss of Use', 'Temp housing while repairs done', CurrencyFormatter.format(covD, symbol: r'$'), '20%'),
                _buildCovRow('⚖️', 'Coverage E – Liability', 'Personal liability protection', '\$300,000', 'Standard'),
                _buildCovRow('🚑', 'Coverage F – Medical', 'Guest medical payments', '\$5,000', 'Standard', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Avg premium by state list
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
                width: 100,
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
                            size: 9.5, weight: FontWeight.w800, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(c['rate']!,
                        style: AppTextStyles.playfair(
                            size: 15, weight: FontWeight.w800, color: const Color(0xFFD97706))),
                    Text(c['lbl']!, style: AppTextStyles.dmSans(size: 8.5, color: mutedColor)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Policy Types
        Text(
          'Policy Types',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            _buildPolicyCard('🏠', 'HO-3 Standard', 'Open perils on dwelling', 'Most Common', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
            _buildPolicyCard('💎', 'HO-5 Premium', 'Open perils – all coverage', 'Best Coverage', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
            _buildPolicyCard('📦', 'HO-1 Basic', 'Named perils only (limited)', null, null, null),
            _buildPolicyCard('🏘️', 'HO-6 Condo', 'Walls-in coverage', null, null, null, slate: true),
            _buildPolicyCard('🔥', 'Wildfire Rider', 'CA, OR, WA add-on', null, null, null, red: true),
            _buildPolicyCard('🌀', 'Hurricane Rider', 'FL, TX, Gulf states', null, null, null),
          ],
        ),
        const SizedBox(height: 20),

        // Top insurers list
        Text(
          'Top US Insurers 2025',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        _buildInfoCard('🏆', 'State Farm – #1 Market Share', 'AM Best A++ · avg \$1,854/yr · 19,000+ agents', textColor, mutedColor, borderColor, cardColor),
        _buildInfoCard('🦷', 'Allstate – Nationwide Coverage', 'AM Best A+ · avg \$2,070/yr · online claims', textColor, mutedColor, borderColor, cardColor),
        _buildInfoCard('🏛️', 'USAA – Military Families', 'AM Best A++ · avg \$1,640/yr · members only', textColor, mutedColor, borderColor, cardColor),
        _buildInfoCard('💻', 'Lemonade – Digital-First', 'Fast claims AI · from \$25/mo · renters+home', textColor, mutedColor, borderColor, cardColor),
      ],
    );
  }

  Widget _buildPolicyCard(String icon, String title, String desc, String? badge,
      Color? badgeBg, Color? badgeTextCol,
      {bool red = false, bool slate = false}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color titleCol = Colors.white;
    Color descCol = Colors.white70;

    if (red) {
      bg = const Color(0xFFB91C1C);
    } else if (slate) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72);
    } else if (badge == 'Most Common') {
      bg = const Color(0xFFD97706);
    } else {
      bg = theme.getCardColor(context);
      titleCol = theme.getTextColor(context);
      descCol = theme.getMutedColor(context);
    }

    VoidCallback? onTap;
    if (title == 'HO-3 Standard') {
      onTap = () => context.push('/tool/usa/homeinsurance_ho3');
    } else if (title == 'HO-5 Premium') {
      onTap = () => context.push('/tool/usa/homeinsurance_ho5');
    } else if (title == 'HO-1 Basic') {
      onTap = () => context.push('/tool/usa/homeinsurance_ho1');
    } else if (title == 'HO-6 Condo') {
      onTap = () => context.push('/tool/usa/homeinsurance_ho6');
    } else if (title == 'Wildfire Rider') {
      onTap = () => context.push('/tool/usa/homeinsurance_wildfire');
    } else if (title == 'Hurricane Rider') {
      onTap = () => context.push('/tool/usa/homeinsurance_hurricane');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: bg == theme.getCardColor(context) ? Border.all(color: theme.getBorderColor(context)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: bg == theme.getCardColor(context) ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 6),
            Text(title,
                style: AppTextStyles.playfair(
                    size: 12.5, weight: FontWeight.w800, color: titleCol)),
            Text(desc,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: descCol)),
            if (badge != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg ?? Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge,
                    style: AppTextStyles.dmSans(
                        size: 8, weight: FontWeight.w700, color: badgeTextCol ?? Colors.white)),
              )
            ]
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

  Widget _buildInfoCard(String icon, String title, String subtitle, Color textColor,
      Color mutedColor, Color borderColor, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(size: 9, color: mutedColor),
                ),
              ],
            ),
          ),
          Text('›', style: TextStyle(fontSize: 16, color: mutedColor)),
        ],
      ),
    );
  }
}

