// lib/features/usa/tools/usa_homeowner_insurance_hurricane_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeownerInsuranceHurricaneCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAHomeownerInsuranceHurricaneCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAHomeownerInsuranceHurricaneCalc> createState() => _USAHomeownerInsuranceHurricaneCalcState();
}

class _USAHomeownerInsuranceHurricaneCalcState extends ConsumerState<USAHomeownerInsuranceHurricaneCalc> {
  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  double _dwellingValue = 300000;
  String _state = 'FL';
  String _location = 'coast';
  double _dedPct = 2;
  String _construction = 'wood';

  bool _showResults = false;
  bool _isCalcDirty = false;
  bool _calculating = false;

  final Map<String, double> _stateBaseRates = {
    'FL': 0.0080,
    'TX': 0.0066,
    'LA': 0.0072,
    'NC': 0.0052,
  };

  final Map<String, double> _locationMultipliers = {
    'coast': 1.35,
    'near': 1.0,
    'inland': 0.62,
  };

  final Map<double, double> _deductibleDiscounts = {
    1.0: 0.10,
    2.0: 0.0,
    3.0: -0.08,
    5.0: -0.18,
  };

  final Map<String, double> _constructionDiscounts = {
    'wood': 0.0,
    'masonry': -0.10,
    'fortified': -0.28,
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _dwellingValue = inputs['DwellingValue'] ?? 300000.0;
      final stateCode = inputs['StateCode'] ?? 0.0;
      _state = stateCode == 0.0 ? 'FL' : stateCode == 1.0 ? 'TX' : stateCode == 2.0 ? 'LA' : 'NC';
      final locCode = inputs['LocationCode'] ?? 0.0;
      _location = locCode == 0.0 ? 'coast' : locCode == 1.0 ? 'near' : 'inland';
      _dedPct = inputs['DeductiblePct'] ?? 2.0;
      final constCode = inputs['ConstructionCode'] ?? 0.0;
      _construction = constCode == 0.0 ? 'wood' : constCode == 1.0 ? 'masonry' : 'fortified';
      _calcSnapshot['DwellingValue'] = _dwellingValue;
      _calcSnapshot['State'] = _state;
      _calcSnapshot['Location'] = _location;
      _calcSnapshot['DeductiblePct'] = _dedPct;
      _calcSnapshot['Construction'] = _construction;
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
      _dwellingValue = 300000;
      _state = 'FL';
      _location = 'coast';
      _dedPct = 2;
      _construction = 'wood';
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
      _calcSnapshot['DwellingValue'] = _dwellingValue;
      _calcSnapshot['State'] = _state;
      _calcSnapshot['Location'] = _location;
      _calcSnapshot['DeductiblePct'] = _dedPct;
      _calcSnapshot['Construction'] = _construction;
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
    final double dwellingValue = _calcSnapshot['DwellingValue'] ?? _dwellingValue;
    final String state = _calcSnapshot['State'] ?? _state;
    final String location = _calcSnapshot['Location'] ?? _location;
    final double dedPct = _calcSnapshot['DeductiblePct'] ?? _dedPct;
    final String construction = _calcSnapshot['Construction'] ?? _construction;

    final baseRate = _stateBaseRates[state] ?? 0.0080;
    double annual = dwellingValue *
        baseRate *
        (_locationMultipliers[location] ?? 1.0) *
        (1 + (_deductibleDiscounts[dedPct] ?? 0.0)) *
        (1 + (_constructionDiscounts[construction] ?? 0.0));
    annual = (annual / 10).round() * 10.0;
    final monthly = (annual / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'Hurricane Rider Quote');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_homeowner_insurance_hurricane_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Hurricane Rider',
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
                hintText: 'Label (e.g. My Hurricane Quote)',
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
          : 'Hurricane Rider Quote';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Hurricane Rider',
        inputs: {
          'DwellingValue': dwellingValue,
          'StateCode': state == 'FL' ? 0.0 : state == 'TX' ? 1.0 : state == 'LA' ? 2.0 : 3.0,
          'LocationCode': location == 'coast' ? 0.0 : location == 'near' ? 1.0 : 2.0,
          'DeductiblePct': dedPct,
          'ConstructionCode': construction == 'wood' ? 0.0 : construction == 'masonry' ? 1.0 : 2.0,
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
            content: Text('✅ Hurricane calculation saved successfully!',
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

    final double snapDwellingValue = _calcSnapshot['DwellingValue'] ?? _dwellingValue;
    final String snapState = _calcSnapshot['State'] ?? _state;
    final String snapLocation = _calcSnapshot['Location'] ?? _location;
    final double snapDedPct = _calcSnapshot['DeductiblePct'] ?? _dedPct;
    final String snapConstruction = _calcSnapshot['Construction'] ?? _construction;

    final covDwelling = snapDwellingValue;

    // Compute active calculation
    final baseRate = _stateBaseRates[snapState] ?? 0.0080;
    double annualPremium = snapDwellingValue *
        baseRate *
        (_locationMultipliers[snapLocation] ?? 1.0) *
        (1 + (_deductibleDiscounts[snapDedPct] ?? 0.0)) *
        (1 + (_constructionDiscounts[snapConstruction] ?? 0.0));
    annualPremium = (annualPremium / 10).round() * 10.0;
    final monthlyPremium = (annualPremium / 12).round();
    final windDed = (snapDwellingValue * snapDedPct / 100).roundToDouble();
    final surge = (snapDwellingValue * 0.10).roundToDouble();
    final ale = (snapDwellingValue * 0.20).roundToDouble();
    final debris = (snapDwellingValue * 0.05).roundToDouble();

    final isDirty = _showResults && (
      _dwellingValue != snapDwellingValue ||
      _state != snapState ||
      _location != snapLocation ||
      _dedPct != snapDedPct ||
      _construction != snapConstruction
    );

    // Rate strip values
    const rateStats = [
      {'label': 'FL Avg/yr', 'value': '\$3,200', 'note': 'Wind Only'},
      {'label': 'TX Gulf Avg', 'value': '\$2,650', 'note': 'Per Year'},
      {'label': 'Highest', 'value': 'FL Keys', 'note': '\$8,400/yr'},
      {'label': 'Deductible', 'value': '2–5%', 'note': 'Of Coverage A'},
    ];

    // State comparative list
    final refMax = (_dwellingValue / 300000.0) * 8400.0;
    final comparisons = [
      {'label': 'Your Rider', 'value': annualPremium, 'isUser': true},
      {'label': 'FL Keys', 'value': (_dwellingValue / 300000.0) * 8400.0, 'isUser': false},
      {'label': 'FL Coastal', 'value': (_dwellingValue / 300000.0) * 6050.0, 'isUser': false},
      {'label': 'TX Gulf', 'value': (_dwellingValue / 300000.0) * 5300.0, 'isUser': false},
      {'label': 'LA Coast', 'value': (_dwellingValue / 300000.0) * 4870.0, 'isUser': false},
      {'label': 'NC Outer Bks', 'value': (_dwellingValue / 300000.0) * 3870.0, 'isUser': false},
      {'label': 'SC Myrtle Bch', 'value': (_dwellingValue / 300000.0) * 3200.0, 'isUser': false},
    ];

    final locLabels = {
      'coast': 'Coastal',
      'near': 'Near-Coast',
      'inland': 'Inland',
    };

    // Hurricane-risk states
    const stateCards = [
      {'icon': '🌴', 'name': 'Florida', 'rate': '\$1,800–\$8,400', 'lbl': 'Coastal to Keys · yr', 'level': 'Extreme Risk', 'color': Color(0xFFB91C1C)},
      {'icon': '🤠', 'name': 'Texas (Gulf)', 'rate': '\$1,400–\$5,300', 'lbl': 'Gulf Coast · per yr', 'level': 'Very High Risk', 'color': Color(0xFFB91C1C)},
      {'icon': '🎷', 'name': 'Louisiana', 'rate': '\$1,200–\$4,870', 'lbl': 'Coastal parishes · yr', 'level': 'High Risk', 'color': Color(0xFFD97706)},
      {'icon': '🌿', 'name': 'N. Carolina', 'rate': '\$950–\$3,870', 'lbl': 'Outer Banks · per yr', 'level': 'High Risk', 'color': Color(0xFFD97706)},
      {'icon': '🌅', 'name': 'S. Carolina', 'rate': '\$800–\$3,200', 'lbl': 'Grand Strand coast', 'level': 'Mod–High', 'color': Color(0xFF1B3F72)},
      {'icon': '🍑', 'name': 'Georgia', 'rate': '\$700–\$2,400', 'lbl': 'Coastal GA · per yr', 'level': 'Moderate', 'color': Color(0xFF15803D)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1E2E) : const Color(0xFFEFF6FF),
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
                          color: stat['label'] == 'FL Avg/yr' || stat['label'] == 'Highest' ? const Color(0xFF0284C7) : textColor,
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
                  'View Hurricane Rider Estimate',
                  style: AppTextStyles.playfair(size: 13, color: textColor, weight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Adjust parameters below and tap "Calculate Hurricane Rider" to estimate your rates.',
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
                  'Your Hurricane Rider Estimate',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C4A6E), Color(0xFF0284C7), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C4A6E).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANNUAL RIDER PREMIUM ESTIMATE',
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
                        'Hurricane Rider · ${CurrencyFormatter.compact(snapDwellingValue, symbol: r'$')} dwelling · ${locLabels[snapLocation]} · $snapState',
                        style: AppTextStyles.dmSans(
                            size: 9.5, color: Colors.white.withValues(alpha: 0.82)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildHeroBottomBox('Monthly', CurrencyFormatter.format(monthlyPremium.toDouble(), symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Wind Deductible', CurrencyFormatter.format(windDed, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Storm Surge', CurrencyFormatter.format(surge, symbol: r'$')),
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
              'Configure Your Rider',
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
              // Dwelling Replacement Value Slider
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
                max: 1500000,
                divisions: 140,
                activeColor: const Color(0xFF0284C7),
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
                  Text('\$1.5M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // State Buttons
              Text('State'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('Florida', 'FL', _state == 'FL', (val) {
                    setState(() {
                      _state = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('Texas', 'TX', _state == 'TX', (val) {
                    setState(() {
                      _state = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('Louisiana', 'LA', _state == 'LA', (val) {
                    setState(() {
                      _state = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('N. Carolina', 'NC', _state == 'NC', (val) {
                    setState(() {
                      _state = val;
                      _markDirty();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Location Type
              Text('Location Type'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('Coastal (<1mi)', 'coast', _location == 'coast', (val) {
                    setState(() {
                      _location = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('Near-Coast', 'near', _location == 'near', (val) {
                    setState(() {
                      _location = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('Inland', 'inland', _location == 'inland', (val) {
                    setState(() {
                      _location = val;
                      _markDirty();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Wind Deductible
              Text('Wind Deductible (% of Coverage A)'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('1%', 1.0, _dedPct == 1, (val) {
                    setState(() {
                      _dedPct = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('2%', 2.0, _dedPct == 2, (val) {
                    setState(() {
                      _dedPct = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('3%', 3.0, _dedPct == 3, (val) {
                    setState(() {
                      _dedPct = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('5%', 5.0, _dedPct == 5, (val) {
                    setState(() {
                      _dedPct = val;
                      _markDirty();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Construction Type
              Text('Construction Type'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChoiceBtn('Wood Frame', 'wood', _construction == 'wood', (val) {
                    setState(() {
                      _construction = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('Masonry', 'masonry', _construction == 'masonry', (val) {
                    setState(() {
                      _construction = val;
                      _markDirty();
                    });
                  }),
                  const SizedBox(width: 5),
                  _buildChoiceBtn('FORTIFIED™', 'fortified', _construction == 'fortified', (val) {
                    setState(() {
                      _construction = val;
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
                        backgroundColor: const Color(0xFF0284C7),
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
                  if (_showResults && !isDirty) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveCalculation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFF0284C7), width: 2),
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
          // Saffir-Simpson Scale & Premium Impact
          Text(
            'Saffir-Simpson Scale & Premium Impact',
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
                _buildScaleRow('C1', 'Category 1', '74–95 mph · minimal damage', 0.30, '+15%', const Color(0xFF2563EB)),
                const SizedBox(height: 9),
                _buildScaleRow('C2', 'Category 2', '96–110 mph · moderate damage', 0.50, '+35%', const Color(0xFF0369A1)),
                const SizedBox(height: 9),
                _buildScaleRow('C3', 'Category 3', '111–129 mph · extensive', 0.68, '+60%', const Color(0xFFD97706)),
                const SizedBox(height: 9),
                _buildScaleRow('C4', 'Category 4', '130–156 mph · catastrophic', 0.83, '+90%', const Color(0xFFB45309)),
                const SizedBox(height: 9),
                _buildScaleRow('C5', 'Category 5', '157+ mph · total destruction', 1.0, '+150%', const Color(0xFFB91C1C)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // State Premium Comparison
          Text(
            'State Premium Comparison',
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
              children: comparisons.map((st) {
                final isUser = st['isUser'] as bool;
                final fillPct = (st['value'] as double) / refMax;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          st['label'] as String,
                          style: AppTextStyles.dmSans(
                              size: 10,
                              weight: FontWeight.w700,
                              color: isUser ? const Color(0xFF0284C7) : mutedColor),
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
                            widthFactor: fillPct.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isUser
                                      ? const [Color(0xFF0C4A6E), Color(0xFF0284C7)]
                                      : const [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                ),
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
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // What This Rider Covers
          Text(
            'What This Rider Covers',
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
                _buildCovRow('🏠', 'Wind Damage – Dwelling', 'Roof, walls, windows from hurricane-force wind', CurrencyFormatter.format(covDwelling, symbol: r'$'), '100% RCV'),
                _buildCovRow('🌊', 'Storm Surge (Endorsement)', 'Water intrusion from surge – optional add-on', CurrencyFormatter.format(surge, symbol: r'$'), '10% of A'),
                _buildCovRow('🏨', 'Additional Living Expense', 'Hotel & meals during evacuation/repair', CurrencyFormatter.format(ale, symbol: r'$'), '20% of A'),
                _buildCovRow('🌳', 'Debris Removal', 'Tree, shingle, structural debris cleanup', CurrencyFormatter.format(debris, symbol: r'$'), '5% of A'),
                _buildCovRow('🏗️', 'Code Upgrade Coverage', 'Rebuilding to current FL/TX wind codes', 'Included', 'FORTIFIED+'),
                _buildCovRow('⚡', 'Power Surge / Generator', 'Appliance damage from outage/surge', '\$5,000', 'Standard', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hurricane-Risk States 2025
          Text(
            'Hurricane-Risk States 2025',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.15,
            children: stateCards.map((c) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14243C) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (c['color'] as Color).withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c['icon'] as String, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(c['name'] as String, style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textColor)),
                    Text(c['rate'] as String, style: AppTextStyles.playfair(size: 14.5, weight: FontWeight.w800, color: const Color(0xFF0369A1))),
                    Text(c['lbl'] as String, style: AppTextStyles.dmSans(size: 8.5, color: mutedColor)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (c['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c['level'] as String,
                        style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: c['color'] as Color),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Need-to-Know Facts
        Text(
          'Need-to-Know Facts',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C4A6E), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0C4A6E).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildFactRow('⚠️', 'Hurricane deductibles are separate: Most Gulf/Atlantic states mandate a hurricane-specific deductible of 1–5% of Coverage A, not the standard flat deductible.'),
              _buildFactRow('🌊', 'Flood ≠ Hurricane rider: Storm surge and inland flooding require a separate NFIP flood policy. Avg NFIP cost: \$888/yr (2025).'),
              _buildFactRow('🏠', 'FL Citizens Insurance: State insurer of last resort. 2025 avg \$3,000–\$6,000/yr wind-only. Over 1.2M FL policies.'),
              _buildFactRow('🔨', 'FORTIFIED™ discount: IBHS FORTIFIED roof standard earns up to 25–30% off in FL and AL. Some insurers require it to write new policies.'),
              _buildFactRow('📉', 'Hurricane Ian 2022: \$60B+ insured loss in FL. Caused Farmers, Bankers Insurance, Lexington to exit the FL market 2023–2025.'),
            ],
          ),
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
            color: isSelected ? const Color(0xFFEFF6FF) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? const Color(0xFF0284C7) : widget.theme.getBorderColor(context),
                width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w700,
                color: isSelected ? const Color(0xFF0C4A6E) : widget.theme.getTextColor(context)),
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

  Widget _buildScaleRow(String cat, String title, String description, double trackPct, String impact, Color color) {
    final theme = widget.theme;
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(cat, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textColor)),
              Text(description, style: AppTextStyles.dmSans(size: 9.5, color: mutedColor)),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: trackPct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            impact,
            style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textColor),
            textAlign: TextAlign.right,
          ),
        )
      ],
    );
  }

  Widget _buildCovRow(String icon, String name, String desc, String amount, String pct, {bool isLast = false}) {
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
              Text(pct, style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFactRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.dmSans(size: 10.5, color: Colors.white.withValues(alpha: 0.88), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
