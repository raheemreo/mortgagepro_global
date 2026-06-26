// lib/features/usa/tools/usa_homeowner_insurance_wildfire_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceWildfireCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAHomeownerInsuranceWildfireCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAHomeownerInsuranceWildfireCalc> createState() => _USAHomeownerInsuranceWildfireCalcState();
}

class _USAHomeownerInsuranceWildfireCalcState extends ConsumerState<USAHomeownerInsuranceWildfireCalc> {
  double _dwellingValue = 400000;
  double _homeAge = 10;
  double _deductible = 2500;
  String _riskLevel = 'ca_std';
  String _mitigation = 'partial';

  bool _showResults = true;
  bool _isCalcDirty = false;
  bool _calculating = false;

  final Map<String, double> _stateRates = {
    'low': 0.0028,
    'ca_std': 0.0039,
    'ca_sra': 0.0072,
    'extreme': 0.0130,
  };

  final Map<double, double> _deductibleDiscounts = {
    1000: 0.0,
    2500: -0.08,
    5000: -0.15,
    10000: -0.22,
  };

  final Map<String, double> _mitigationDiscounts = {
    'none': 0.0,
    'partial': -0.08,
    'full': -0.18,
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _dwellingValue = inputs['DwellingValue'] ?? 400000.0;
      _homeAge = inputs['HomeAge'] ?? 10.0;
      _deductible = inputs['Deductible'] ?? 2500.0;
      final riskCode = inputs['RiskLevelCode'] ?? 1.0;
      _riskLevel = riskCode == 0.0 ? 'low' : riskCode == 1.0 ? 'ca_std' : riskCode == 2.0 ? 'ca_sra' : 'extreme';
      final mitCode = inputs['MitigationCode'] ?? 1.0;
      _mitigation = mitCode == 0.0 ? 'none' : mitCode == 1.0 ? 'partial' : 'full';
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
      _homeAge = 10;
      _deductible = 2500;
      _riskLevel = 'ca_std';
      _mitigation = 'partial';
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
    double rate = _stateRates[_riskLevel] ?? 0.0039;
    if (_homeAge > 40) {
      rate *= 1.20;
    } else if (_homeAge > 20) {
      rate *= 1.10;
    }

    final disc = (_deductibleDiscounts[_deductible] ?? 0.0) +
        (_mitigationDiscounts[_mitigation] ?? 0.0);
    double annual = _dwellingValue * rate * (1 + disc);
    annual = (annual / 10).round() * 10.0;
    final monthly = (annual / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'Wildfire Rider Quote');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Wildfire Rider',
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
                hintText: 'Label (e.g. My Wildfire Quote)',
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
          : 'Wildfire Rider Quote';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Wildfire Rider',
        inputs: {
          'DwellingValue': _dwellingValue,
          'HomeAge': _homeAge,
          'Deductible': _deductible,
          'RiskLevelCode': _riskLevel == 'low' ? 0.0 : _riskLevel == 'ca_std' ? 1.0 : _riskLevel == 'ca_sra' ? 2.0 : 3.0,
          'MitigationCode': _mitigation == 'none' ? 0.0 : _mitigation == 'partial' ? 1.0 : 2.0,
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
            content: Text('✅ Wildfire calculation saved successfully!',
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
    double rate = _stateRates[_riskLevel] ?? 0.0039;
    if (_homeAge > 40) {
      rate *= 1.20;
    } else if (_homeAge > 20) {
      rate *= 1.10;
    }

    final disc = (_deductibleDiscounts[_deductible] ?? 0.0) +
        (_mitigationDiscounts[_mitigation] ?? 0.0);
    double annualPremium = _dwellingValue * rate * (1 + disc);
    annualPremium = (annualPremium / 10).round() * 10.0;
    final monthlyPremium = (annualPremium / 12).round();
    final pct = (annualPremium / _dwellingValue * 100);

    // Coverages breakdown
    final covDwelling = _dwellingValue;
    final covSmoke = (_dwellingValue * 0.10).roundToDouble();
    final covDebris = (_dwellingValue * 0.10).roundToDouble();
    final covALE = (_dwellingValue * 0.20).roundToDouble();

    final riskLabels = {
      'low': 'OR/WA Standard',
      'ca_std': 'CA Standard Risk',
      'ca_sra': 'CA SRA Zone',
      'extreme': 'CA FAIR Plan Zone',
    };

    // Rate strip values
    const rateStats = [
      {'label': 'Avg Add-On/yr', 'value': '\$1,840', 'note': '2025 Data'},
      {'label': 'CA High Risk', 'value': '\$3,200+', 'note': 'SRA Zone'},
      {'label': 'Homes at Risk', 'value': '4.5M', 'note': 'Nationwide'},
      {'label': 'CA Losses', 'value': '\$12B', 'note': '2024 Est.'},
    ];

    // High risk counties
    const riskCounties = [
      {'icon': '🔴', 'county': 'Butte, CA', 'rate': '\$4,100', 'note': 'SRA / Camp Fire', 'isHi': true},
      {'icon': '🔴', 'county': 'Shasta, CA', 'rate': '\$3,850', 'note': 'Very High Risk', 'isHi': true},
      {'icon': '🔴', 'county': 'Mariposa, CA', 'rate': '\$3,600', 'note': 'Yosemite-adj.', 'isHi': true},
      {'icon': '🟠', 'county': 'Jackson, CO', 'rate': '\$1,900', 'note': 'High Elevation', 'isHi': false},
      {'icon': '🟠', 'county': 'Deschutes, OR', 'rate': '\$1,420', 'note': 'WUI Zone', 'isHi': false},
      {'icon': '🟡', 'county': 'Yakima, WA', 'rate': '\$870', 'note': 'Moderate Risk', 'isHi': false},
    ];

    // State comparative list
    const stateRatesComp = [
      {'label': 'CA – SRA Zone', 'value': 3200.0, 'color': Color(0xFF7C2D12)},
      {'label': 'CA – Standard', 'value': 1800.0, 'color': Color(0xFFC2410C)},
      {'label': 'CO', 'value': 1410.0, 'color': Color(0xFFD97706)},
      {'label': 'AZ', 'value': 1215.0, 'color': Color(0xFFD97706)},
      {'label': 'OR', 'value': 895.0, 'color': Color(0xFF1B3F72)},
      {'label': 'WA', 'value': 705.0, 'color': Color(0xFF1B3F72)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isDark ? borderColor : const Color(0xFFFDBA74)),
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
                          color: stat['label'] == 'Avg Add-On/yr' || stat['label'] == 'CA Losses' ? const Color(0xFFC2410C) : textColor,
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

        // Alert Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'High-Risk Zone Warning',
                      style: AppTextStyles.playfair(
                          size: 11.5, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Standard HO-3 policies exclude wildfire in many CA, OR & WA counties. This rider restores coverage. California\'s FAIR Plan is the last-resort option if private carriers have non-renewed your policy.',
                      style: AppTextStyles.dmSans(
                          size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF7F1D1D), height: 1.45),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // Result Hero
        Text(
          'Your Rider Estimate',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C2D12), Color(0xFFC2410C), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C2D12).withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANNUAL WILDFIRE RIDER PREMIUM',
                style: AppTextStyles.dmSans(
                    size: 8,
                    weight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(annualPremium, symbol: r'$'),
                style: AppTextStyles.playfair(
                    size: 32, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                '${riskLabels[_riskLevel] ?? ''} · ${CurrencyFormatter.compact(_dwellingValue, symbol: r'$')} dwelling · ${CurrencyFormatter.compact(_deductible, symbol: r'$')} ded.',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.82)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroBottomBox('Monthly Add-On', CurrencyFormatter.format(monthlyPremium.toDouble(), symbol: r'$')),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('% of Dwelling', '${pct.toStringAsFixed(2)}%'),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Ded. (Fire)', CurrencyFormatter.format(_deductible, symbol: r'$')),
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
                min: 150000,
                max: 1500000,
                divisions: 135,
                activeColor: const Color(0xFFC2410C),
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
                  Text('\$150K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$500K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1.5M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // State/Risk Zone Buttons
              Text('State / Risk Zone'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('OR/WA', 'low', _riskLevel == 'low', (val) {
                    setState(() {
                      _riskLevel = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('CA Std', 'ca_std', _riskLevel == 'ca_std', (val) {
                    setState(() {
                      _riskLevel = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('CA SRA', 'ca_sra', _riskLevel == 'ca_sra', (val) {
                    setState(() {
                      _riskLevel = val;
                      _riskLevel = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('CA FAIR', 'extreme', _riskLevel == 'extreme', (val) {
                    setState(() {
                      _riskLevel = val;
                      _markDirty();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Fire Deductible
              Text('Fire Deductible'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('\$1,000', 1000.0, _deductible == 1000, (val) {
                    setState(() {
                      _deductible = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('\$2,500', 2500.0, _deductible == 2500, (val) {
                    setState(() {
                      _deductible = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('\$5,000', 5000.0, _deductible == 5000, (val) {
                    setState(() {
                      _deductible = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('\$10,000', 10000.0, _deductible == 10000, (val) {
                    setState(() {
                      _deductible = val;
                      _markDirty();
                    });
                  }),
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
                activeColor: const Color(0xFFC2410C),
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
                  Text('50 yr', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('80 yr', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Fire-Resistant Features Choice Buttons
              Text('Fire-Resistant Features'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('None', 'none', _mitigation == 'none', (val) {
                    setState(() {
                      _mitigation = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('Partial', 'partial', _mitigation == 'partial', (val) {
                    setState(() {
                      _mitigation = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('IBH-Rated', 'full', _mitigation == 'full', (val) {
                    setState(() {
                      _mitigation = val;
                      _markDirty();
                    });
                  }),
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
                        backgroundColor: const Color(0xFFC2410C),
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
                              'Calculate Rider Premium',
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
                        foregroundColor: const Color(0xFFC2410C),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFC2410C), width: 2),
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
          // Stats grid
          Text(
            '2025 Wildfire Statistics',
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
            childAspectRatio: 1.6,
            children: [
              _buildStatBox('🔥', '68,988', 'Wildfires in 2024 USA', isDark, hasFireGradient: true),
              _buildStatBox('🏚️', '\$29B', '2024 US Wildfire Losses', isDark, hasAmberGradient: true),
              _buildStatBox('📍', '4.5M', 'US Homes in WUI Zones', isDark),
              _buildStatBox('📈', '+340%', 'CA Premium Rise (2020–25)', isDark),
            ],
          ),
          const SizedBox(height: 20),

          // Rider Cost by State
          Text(
            'Rider Cost by State',
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avg Wildfire Rider Premium / Year',
                      style: AppTextStyles.playfair(
                          size: 11.5, weight: FontWeight.w800, color: textColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('2025 Rates',
                          style: AppTextStyles.dmSans(
                              size: 8, weight: FontWeight.w700, color: const Color(0xFFC2410C))),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                ...stateRatesComp.map((st) {
                  final fillPct = (st['value'] as double) / 3200.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 86,
                          child: Text(
                            st['label'] as String,
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w700, color: mutedColor),
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
                                  color: st['color'] as Color,
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
                            CurrencyFormatter.format(st['value'] as double, symbol: r'$'),
                            style: AppTextStyles.playfair(
                                size: 11, weight: FontWeight.w800, color: textColor),
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
          const SizedBox(height: 20),

          // Donut Chart - Premium Breakdown
          Text(
            'Your Premium Breakdown',
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
                        painter: WildfireDonutChartPainter(
                          values: [55, 20, 15, 10],
                          colors: const [
                            Color(0xFF7C2D12),
                            Color(0xFFC2410C),
                            Color(0xFFD97706),
                            Color(0xFFFCD34D),
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
                          CurrencyFormatter.compact(annualPremium, symbol: r'$'),
                          style: AppTextStyles.playfair(
                              size: 12, weight: FontWeight.w800, color: textColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildDonutLegendRow('Structure Loss', '55%', const Color(0xFF7C2D12), 'Rebuild coverage', textColor, mutedColor),
                      const SizedBox(height: 6),
                      _buildDonutLegendRow('Debris Removal', '20%', const Color(0xFFC2410C), 'Clean-up costs', textColor, mutedColor),
                      const SizedBox(height: 6),
                      _buildDonutLegendRow('Smoke / ALE', '15%', const Color(0xFFD97706), 'Loss of use', textColor, mutedColor),
                      const SizedBox(height: 6),
                      _buildDonutLegendRow('Admin / Reserve', '10%', const Color(0xFFFCD34D), 'Carrier overhead', textColor, mutedColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // What the Rider Covers
          Text(
            'What the Rider Covers',
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
                _buildCovRow('🏠', 'Dwelling – Fire Loss', 'Full rebuild from wildfire destruction', CurrencyFormatter.format(covDwelling, symbol: r'$'), 'Included', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
                _buildCovRow('🌫️', 'Smoke Damage', 'Interior/exterior smoke remediation', CurrencyFormatter.format(covSmoke, symbol: r'$'), 'Included', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
                _buildCovRow('🪨', 'Debris Removal', 'Ash, tree, structural debris', CurrencyFormatter.format(covDebris, symbol: r'$'), 'Included', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
                _buildCovRow('🏨', 'Additional Living Exp.', 'Evacuation hotel, meals up to 24 mo', CurrencyFormatter.format(covALE, symbol: r'$'), 'Add-On', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                _buildCovRow('🌲', 'Vegetation / Ember Buffer', 'Defensible space clearing cost', '\$5,000', 'Add-On', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                _buildCovRow('❌', 'Land / Soil Remediation', 'Not covered under standard rider', '—', 'Excluded', const Color(0xFFFEF2F2), const Color(0xFFB91C1C), isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Highest-Risk Counties 2025
          Text(
            'Highest-Risk Counties 2025',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: riskCounties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (_, i) {
                final c = riskCounties[i];
                final isHi = c['isHi'] as bool;
                return Container(
                  width: 105,
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isHi ? const Color(0xFF381D1D) : const Color(0xFF26201B))
                        : (isHi ? const Color(0xFFFFF5F5) : const Color(0xFFFFFBF0)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isHi ? const Color(0xFFFCA5A5).withValues(alpha: 0.3) : const Color(0xFFFDE68A).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c['icon'] as String, style: const TextStyle(fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(c['county'] as String,
                          style: AppTextStyles.playfair(
                              size: 9.5, weight: FontWeight.w800, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(c['rate'] as String,
                          style: AppTextStyles.playfair(
                              size: 15,
                              weight: FontWeight.w800,
                              color: isHi ? const Color(0xFFB91C1C) : const Color(0xFFD97706))),
                      Text(c['note'] as String,
                          style: AppTextStyles.dmSans(size: 8, color: mutedColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Ways to Lower Your Premium
        Text(
          'Ways to Lower Your Premium',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildTipCard('🪵', 'Class A Fire-Rated Roof', 'Replace wood shake with tile, metal, or asphalt. Most carriers offer a 10–15% discount for Class A roofing material.', '💰 Save up to \$320/yr', cardColor, borderColor, textColor, mutedColor),
            const SizedBox(height: 9),
            _buildTipCard('🌿', 'Defensible Space – Zone 1', 'Clear 0–30 ft of combustible vegetation. California IBHS mitigation grants available through 2026 legislative session.', '💰 Save up to \$210/yr', cardColor, borderColor, textColor, mutedColor),
            const SizedBox(height: 9),
            _buildTipCard('🚪', 'Ember-Resistant Vents & Eaves', 'Replace open vents with 1/16" ember-blocking mesh. IBH-rated homes qualify for up to 20% premium reduction.', '💰 Save up to \$280/yr', cardColor, borderColor, textColor, mutedColor),
            const SizedBox(height: 9),
            _buildTipCard('📋', 'Higher Fire Deductible', 'Increasing your fire deductible from \$1,000 to \$5,000 can reduce annual rider cost by 12–18%.', '💰 Save up to \$250/yr', cardColor, borderColor, textColor, mutedColor),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceBtn<T>(String label, T value, bool isSelected, Function(T) onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? const Color(0xFFC2410C) : widget.theme.getBorderColor(context),
                width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w700,
                color: isSelected ? const Color(0xFF7C2D12) : widget.theme.getTextColor(context)),
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

  Widget _buildStatBox(String icon, String val, String label, bool isDark,
      {bool hasFireGradient = false, bool hasAmberGradient = false}) {
    final theme = widget.theme;
    final cardColor = theme.getCardColor(context);
    final borderColor = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);

    if (hasFireGradient) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C2D12), Color(0xFFC2410C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(val, style: AppTextStyles.playfair(size: 16.5, weight: FontWeight.w800, color: Colors.white)),
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
          ],
        ),
      );
    }

    if (hasAmberGradient) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(val, style: AppTextStyles.playfair(size: 16.5, weight: FontWeight.w800, color: Colors.white)),
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(val, style: AppTextStyles.playfair(size: 16.5, weight: FontWeight.w800, color: textColor)),
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: mutedColor)),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow(String title, String pct, Color color, String sub, Color textColor, Color mutedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: textColor)),
                Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedColor)),
              ],
            ),
          ],
        ),
        Text(pct, style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textColor)),
      ],
    );
  }

  Widget _buildCovRow(String icon, String name, String desc, String amount, String badge,
      Color badgeBg, Color badgeTxt, {bool isLast = false}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.w800, color: textColor)),
                  Text(desc, style: AppTextStyles.dmSans(size: 9, color: mutedColor)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: badgeTxt),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTipCard(String icon, String title, String desc, String saving,
      Color cardColor, Color borderColor, Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: mutedColor, height: 1.45)),
                const SizedBox(height: 4),
                Text(saving, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: const Color(0xFF15803D))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class WildfireDonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color cardColor;

  WildfireDonutChartPainter({required this.values, required this.colors, required this.cardColor});

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
