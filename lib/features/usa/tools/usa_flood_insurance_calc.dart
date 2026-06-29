// lib/features/usa/tools/usa_flood_insurance_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAFloodInsuranceCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAFloodInsuranceCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAFloodInsuranceCalc> createState() => _USAFloodInsuranceCalcState();
}

class _USAFloodInsuranceCalcState extends ConsumerState<USAFloodInsuranceCalc> {
  double _bldgCoverage = 250000;
  double _contCoverage = 100000;
  String _floodZone = 'AE';
  int _elevation = 1;

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  final Map<String, Map<int, double>> _zoneRates = {
    'V': {-2: 3800, 0: 2800, 1: 2200, 3: 1600},
    'AE': {-2: 2400, 0: 1620, 1: 888, 3: 580},
    'A': {-2: 1800, 0: 1200, 1: 720, 3: 450},
    'X': {-2: 600, 0: 450, 1: 350, 3: 280}
  };

  final Map<String, String> _zoneNames = {
    'V': 'Zone V/VE',
    'AE': 'Zone AE',
    'A': 'Zone A',
    'X': 'Zone X'
  };

  final Map<String, Color> _zoneColors = {
    'V': const Color(0xFF7F1D1D),
    'AE': const Color(0xFFDC2626),
    'A': const Color(0xFFD97706),
    'X': const Color(0xFF15803D)
  };

  final Map<String, String> _marketType = {
    'V': 'NFIP Req.',
    'AE': 'NFIP',
    'A': 'NFIP/Private',
    'X': 'Optional'
  };

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  void _resetInputs() {
    setState(() {
      _bldgCoverage = 250000;
      _contCoverage = 100000;
      _floodZone = 'AE';
      _elevation = 1;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  // Unused: _loadSavedCalculation removed to resolve analyzer warnings.

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
    final baseRate = _zoneRates[_floodZone]?[_elevation] ?? _zoneRates[_floodZone]![1]!;
    final bldgFactor = _bldgCoverage / 250000;
    final contFactor = _contCoverage / 100000;
    final bldgPremium = ((baseRate * bldgFactor) / 10).round() * 10.0;
    final contPremium = ((baseRate * 0.3 * contFactor) / 10).round() * 10.0;
    final annualPremium = bldgPremium + contPremium;
    final monthly = (annualPremium / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'Flood Insurance');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_flood_insurance_calc/save'),
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
              'Saving: Annual: ${CurrencyFormatter.compact(annualPremium, symbol: r'$')}/yr · Zone: ${_zoneName(_floodZone)}',
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
                hintText: 'Label (e.g. My Flood Quote)',
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
          : 'Flood Insurance';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Flood Insurance',
        inputs: {
          'BldgCoverage': _bldgCoverage,
          'ContCoverage': _contCoverage,
          'FloodZoneCode': _floodZone == 'V' ? 0.0 : _floodZone == 'AE' ? 1.0 : _floodZone == 'A' ? 2.0 : 3.0,
          'ElevationFeet': _elevation.toDouble(),
        },
        results: {
          'Annual Premium': annualPremium,
          'Monthly Premium': monthly,
          'Zone': _floodZone == 'V' ? 0.0 : _floodZone == 'AE' ? 1.0 : _floodZone == 'A' ? 2.0 : 3.0,
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

  String _zoneName(String z) => _zoneNames[z] ?? z;

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
    const stripValues = [
      {'label': 'NFIP Avg/yr', 'value': '\$888', 'note': '2025 FEMA'},
      {'label': 'Zone AE Avg', 'value': '\$1,620', 'note': 'High Risk', 'warn': true},
      {'label': 'Policies', 'value': '4.7M', 'note': 'NFIP Total'},
      {'label': 'Max Cover', 'value': '\$250K', 'note': 'Building'},
    ];

    // Current calculations
    final baseRate = _zoneRates[_floodZone]?[_elevation] ?? _zoneRates[_floodZone]![1]!;
    final bldgFactor = _bldgCoverage / 250000;
    final contFactor = _contCoverage / 100000;
    final bldgPremium = ((baseRate * bldgFactor) / 10).round() * 10.0;
    final contPremium = ((baseRate * 0.3 * contFactor) / 10).round() * 10.0;
    final annualPremium = bldgPremium + contPremium;
    final monthly = (annualPremium / 12).round();

    // Zone comparison list calculations at selected elevation
    final allZones = ['V', 'AE', 'A', 'X'];
    final allPremiums = allZones.map((z) {
      final rate = _zoneRates[z]?[_elevation] ?? _zoneRates[z]![1]!;
      final bPrem = ((rate * bldgFactor) / 10).round() * 10;
      final cPrem = ((rate * 0.3 * contFactor) / 10).round() * 10;
      return bPrem + cPrem;
    }).toList();
    final maxP = max(10, allPremiums.reduce(max));

    // Donut 1: Risk Level vs Zone AE baseline at-grade
    final aeBaseline = ((_zoneRates['AE']![0]! * bldgFactor + _zoneRates['AE']![0]! * 0.3 * contFactor) / 10).round() * 10.0;
    final riskPct = aeBaseline > 0 ? (annualPremium / aeBaseline * 100).round().clamp(0, 100) : 0;

    // Donut 2: Elevation savings vs at-grade same zone
    final atGrade = ((_zoneRates[_floodZone]![0]! * bldgFactor + _zoneRates[_floodZone]![0]! * 0.3 * contFactor) / 10).round() * 10.0;
    final savedAmt = max(0.0, atGrade - annualPremium);
    final savingsPct = atGrade > 0 ? (savedAmt / atGrade * 100).round().clamp(0, 100) : 0;

    // Stacked Premium bar proportions
    final bldgPct = annualPremium > 0 ? (bldgPremium / annualPremium * 100).round() : 70;

    // Savings opportunities list
    final List<Map<String, dynamic>> suggestions = [];
    if (_elevation < 3) {
      final targetRate = _zoneRates[_floodZone]?[3] ?? _zoneRates[_floodZone]![1]!;
      final targetBldgP = ((targetRate * bldgFactor) / 10).round() * 10.0;
      final targetContP = ((targetRate * 0.3 * contFactor) / 10).round() * 10.0;
      final targetP = targetBldgP + targetContP;
      suggestions.add({
        'icon': '📐',
        'label': 'Elevate to +3 ft above BFE',
        'saving': max(0.0, annualPremium - targetP)
      });
    }
    if (_floodZone == 'AE' || _floodZone == 'V') {
      suggestions.add({
        'icon': '🏢',
        'label': 'Get a private market quote',
        'saving': (annualPremium * 0.15).roundToDouble()
      });
    }
    if (_contCoverage > 50000) {
      final reducedContP = ((baseRate * 0.3 * 0.5) / 10).round() * 10.0;
      suggestions.add({
        'icon': '📦',
        'label': 'Reduce contents to \$50K',
        'saving': max(0.0, contPremium - reducedContP)
      });
    }
    suggestions.add({
      'icon': '📋',
      'label': 'Request LOMA map amendment',
      'saving': (annualPremium * 0.40).roundToDouble()
    });

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
            children: stripValues.map((stat) {
              final idx = stripValues.indexOf(stat);
              final isLast = idx == stripValues.length - 1;
              final hasWarnColor = stat['warn'] == true;
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
                        stat['label'] as String,
                        style: AppTextStyles.dmSans(
                            size: 8.5, weight: FontWeight.w700, color: mutedColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat['value'] as String,
                        style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.w800,
                          color: hasWarnColor ? const Color(0xFFD97706) : textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        stat['note'] as String,
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

        // Main results hero panel
        Text(
          'Your Flood Premium',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4C75), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F4C75).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANNUAL NFIP PREMIUM ESTIMATE',
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
                '${_zoneName(_floodZone)} · ${CurrencyFormatter.format(_bldgCoverage, symbol: r'$')} building · ${CurrencyFormatter.format(_contCoverage, symbol: r'$')} contents · NFIP Risk Rating 2.0',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroBottomBox('Monthly', CurrencyFormatter.format(monthly.toDouble(), symbol: r'$')),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Flood Zone', _zoneName(_floodZone)),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Market', _marketType[_floodZone] ?? 'NFIP'),
                ],
              )
            ],
          ),
        ),

        // Save banner
        if (_showResults && !_isCalcDirty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14532D), Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quote Ready to Save',
                        style: AppTextStyles.dmSans(
                            size: 11.5, weight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        '${_zoneName(_floodZone)} · ${CurrencyFormatter.compact(_bldgCoverage, symbol: r'$')} bldg · ${CurrencyFormatter.compact(_contCoverage, symbol: r'$')} contents',
                        style: AppTextStyles.dmSans(
                            size: 9.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Save Quote',
                    style: AppTextStyles.dmSans(
                        size: 10.5, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Property Details inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Details',
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
              // Building Coverage Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Building Coverage'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_bldgCoverage, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _bldgCoverage,
                min: 20000,
                max: 250000,
                divisions: 46,
                activeColor: const Color(0xFF0F4C75),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _bldgCoverage = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$20K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$100K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$175K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$250K max', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Contents Coverage Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Contents Coverage'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_contCoverage, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _contCoverage,
                min: 0,
                max: 100000,
                divisions: 20,
                activeColor: const Color(0xFF0F4C75),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _contCoverage = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$0', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$25K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$60K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$100K max', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // FEMA Flood Zone Selection Buttons
              Text('FEMA Flood Zone'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildZoneChoiceBtn('Zone V', 'Coastal', 'V'),
                  const SizedBox(width: 6),
                  _buildZoneChoiceBtn('Zone AE', 'High Risk', 'AE'),
                  const SizedBox(width: 6),
                  _buildZoneChoiceBtn('Zone A', 'Moderate', 'A'),
                  const SizedBox(width: 6),
                  _buildZoneChoiceBtn('Zone X', 'Low Risk', 'X'),
                ],
              ),
              const SizedBox(height: 16),

              // Elevation Selection Buttons
              Text('First Floor Elevation (ft above BFE)'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildElevChoiceBtn('-2 ft', -2),
                  const SizedBox(width: 6),
                  _buildElevChoiceBtn('At BFE', 0),
                  const SizedBox(width: 6),
                  _buildElevChoiceBtn('+1 ft', 1),
                  const SizedBox(width: 6),
                  _buildElevChoiceBtn('+3 ft', 3),
                ],
              ),
              const SizedBox(height: 16),

              // Calculate trigger button
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C75),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
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
                        '🧮 Calculate Premium',
                        style: AppTextStyles.playfair(
                            size: 13, weight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_showResults && !_isCalcDirty) ...[
          // Analytics Panel
          Text(
            'Premium Analysis',
            style: AppTextStyles.dmSans(
                size: 10.5, weight: FontWeight.w800, color: mutedColor, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),

          // Zone-by-zone comparison bar chart
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
                  '📊 Zone-by-Zone Annual Premium Comparison',
                  style: AppTextStyles.playfair(
                      size: 11, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),
                Column(
                  children: allZones.map((z) {
                    final idx = allZones.indexOf(z);
                    final isCurrent = z == _floodZone;
                    final fillPct = (allPremiums[idx] / maxP).clamp(0.0, 1.0);
                    final color = _zoneColors[z] ?? const Color(0xFF0F4C75);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 58,
                            child: Text(
                              _zoneName(z).replaceAll('Zone ', 'Zn '),
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.w700, color: textColor),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                                border: isCurrent ? Border.all(color: const Color(0xFF0F766E), width: 1.5) : null,
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: fillPct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isCurrent ? 1.0 : 0.6),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 44,
                            child: Text(
                              CurrencyFormatter.compact(allPremiums[idx].toDouble(), symbol: r'$'),
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: isCurrent ? color : textColor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Double Donut Row
          Row(
            children: [
              // Donut 1: Risk level vs baseline
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                        width: 70,
                        child: CustomPaint(
                          painter: _CircleProgressPainter(
                            pct: riskPct / 100,
                            color: riskPct > 80 ? const Color(0xFFB91C1C) : riskPct > 50 ? const Color(0xFFD97706) : const Color(0xFF15803D),
                            isDark: isDark,
                            textColor: textColor,
                            label: 'of max',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Risk Level',
                          style: AppTextStyles.playfair(
                              size: 10, weight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 2),
                      Text('vs. Zone AE baseline ${CurrencyFormatter.compact(aeBaseline, symbol: r'$')}',
                          style: AppTextStyles.dmSans(size: 8, color: mutedColor),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Donut 2: Elevation savings vs at-grade
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                        width: 70,
                        child: CustomPaint(
                          painter: _CircleProgressPainter(
                            pct: savingsPct / 100,
                            color: const Color(0xFF0F766E),
                            isDark: isDark,
                            textColor: textColor,
                            label: 'saved',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Elev. Savings',
                          style: AppTextStyles.playfair(
                              size: 10, weight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 2),
                      Text('Saving ${CurrencyFormatter.compact(savedAmt, symbol: r'$')}/yr vs at-grade',
                          style: AppTextStyles.dmSans(size: 8, color: mutedColor),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Premium Breakdown Stacked Bar Card
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
                  '💰 Premium Breakdown',
                  style: AppTextStyles.playfair(
                      size: 11, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      Expanded(
                        flex: bldgPct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF0F4C75), Color(0xFF1B6CA8)]),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 100 - bldgPct,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem(const Color(0xFF0F4C75), 'Building', '${CurrencyFormatter.format(bldgPremium, symbol: r'$')} ($bldgPct%)'),
                    _buildLegendItem(const Color(0xFF0F766E), 'Contents', '${CurrencyFormatter.format(contPremium, symbol: r'$')} (${100 - bldgPct}%)'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildQuickStat('Daily Cost', '\$${(annualPremium / 365).toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    _buildQuickStat('5-Year Cost', CurrencyFormatter.compact(annualPremium * 5, symbol: r'$')),
                    const SizedBox(width: 8),
                    _buildQuickStat('% of Coverage', _bldgCoverage + _contCoverage > 0 ? '${(annualPremium / (_bldgCoverage + _contCoverage) * 100).toStringAsFixed(2)}%' : '—', teal: true),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Potential Savings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0C2E1A), const Color(0xFF071F11)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Potential Savings',
                          style: AppTextStyles.playfair(
                              size: 12.5, weight: FontWeight.w800, color: const Color(0xFF14532D)),
                        ),
                        Text(
                          'Steps that could lower your premium',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF166534)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  children: suggestions.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item['icon']} ${item['label']}',
                              style: AppTextStyles.dmSans(
                                  size: 11, weight: FontWeight.w700, color: const Color(0xFF166534))),
                          Text(
                            '~${CurrencyFormatter.compact(item['saving'], symbol: r'$')}/yr',
                            style: AppTextStyles.dmSans(
                                size: 11, weight: FontWeight.w800, color: const Color(0xFF14532D)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // NFIP Info Banner
        Text(
          'NFIP Program Info',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🏛️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NATIONAL FLOOD INSURANCE PROGRAM',
                      style: AppTextStyles.dmSans(
                          size: 8.5, weight: FontWeight.w700, color: Colors.white38),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Risk Rating 2.0',
                      style: AppTextStyles.playfair(
                          size: 17, weight: FontWeight.w800, color: const Color(0xFFFCD34D)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FEMA\'s updated pricing since Oct 2021 · Equity in pricing',
                      style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: Text('Flood Map', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800)),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // FEMA Flood Zone Table
        Text(
          'FEMA Flood Zone Guide',
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
              _buildZoneRow('V', 'Zone V / VE', 'Coastal high hazard · wave action · mandatory insurance', 'Extreme', const Color(0xFF7F1D1D)),
              _buildZoneRow('AE', 'Zone AE', '1% annual chance flood · 100-yr floodplain', 'High', const Color(0xFFDC2626)),
              _buildZoneRow('A', 'Zone A', 'High risk, no BFE determined · riverine areas', 'High', const Color(0xFFD97706)),
              _buildZoneRow('X', 'Zone X (shaded)', 'Moderate risk · 0.2% annual chance', 'Moderate', const Color(0xFF15803D)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // High Risk States H-grid
        Text(
          'Highest Risk States',
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
            _buildStateCard('🌀', 'Louisiana', 'Avg \$835/yr · Hurricane risk', 'Mandatory', const Color(0xFFB91C1C)),
            _buildStateCard('🌴', 'Florida', 'Most NFIP policies nationwide', null, const Color(0xFF0F766E)),
            _buildStateCard('🌊', 'Texas', 'Gulf Coast · Harvey legacy', 'Zone AE', theme.primaryColor),
            _buildStateCard('🏖️', 'New Jersey', 'Sandy aftermath · Zone VE', null, const Color(0xFF0B1D3A)),
          ],
        ),
        const SizedBox(height: 20),

        // NFIP vs Private
        Text(
          'NFIP vs Private Flood',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        _buildInfoCard('🏛️', 'NFIP – Federal Program', 'Max \$250K building · \$100K contents · 30-day wait · backed by FEMA', textColor, mutedColor, borderColor, cardColor),
        _buildInfoCard('🏢', 'Private Flood Insurance', 'Higher limits · faster binding · up to \$1M+ coverage · competitive rates', textColor, mutedColor, borderColor, cardColor),
        _buildInfoCard('📋', 'Excess Flood Coverage', 'NFIP + private top-up · covers gap over \$250K building max', textColor, mutedColor, borderColor, cardColor),
        _buildInfoCard('⚡', '30-Day Waiting Period', 'NFIP requires 30 days · private can be same-day · plan ahead', textColor, mutedColor, borderColor, cardColor),
      ],
    );
  }

  Widget _buildStateCard(String icon, String stateName, String desc, String? badge, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 6),
          Text(stateName,
              style: AppTextStyles.playfair(
                  size: 12.5, weight: FontWeight.w800, color: Colors.white)),
          Text(desc,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: Colors.white70)),
          if (badge != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w700, color: Colors.white)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildZoneRow(String code, String name, String desc, String risk, Color color) {
    final active = _floodZone == code;
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _floodZone = code;
          _markDirty();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF0FDFA) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: const Color(0xFF0F766E), width: 0.5) : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 75,
              child: Text(name,
                  style: AppTextStyles.playfair(
                      size: 11.5, weight: FontWeight.w800, color: active ? const Color(0xFF0F4C75) : textColor)),
            ),
            Expanded(
              child: Text(desc,
                  style: AppTextStyles.dmSans(size: 8.5, color: mutedColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            Text(
              risk,
              style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: risk == 'Extreme' || risk == 'High' ? const Color(0xFFB91C1C) : risk == 'Moderate' ? const Color(0xFFD97706) : const Color(0xFF15803D)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String val, {bool teal = false}) {
    final cardBg = widget.theme.getBgColor(context);
    final color = teal ? const Color(0xFF0F766E) : widget.theme.getTextColor(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: teal ? const Color(0xFFF0FDFA) : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: teal ? Border.all(color: const Color(0xFF99F6E4)) : null,
        ),
        child: Column(
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: AppTextStyles.playfair(size: 14.5, weight: FontWeight.w800, color: color),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, String val) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text('$text ', style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w600)),
        Text(val, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getTextColor(context), weight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildHeroBottomBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
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

  Widget _buildZoneChoiceBtn(String label, String sub, String code) {
    final sel = _floodZone == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _floodZone = code;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFF0FDFA) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF0F766E) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          child: Column(
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
              const SizedBox(height: 1),
              Text(sub, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFFB91C1C), weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevChoiceBtn(String label, int val) {
    final sel = _elevation == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _elevation = val;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFF0FDFA) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF0F766E) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
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

// Custom Painter for Circular Progress / Donut Indicator
class _CircleProgressPainter extends CustomPainter {
  final double pct;
  final Color color;
  final bool isDark;
  final Color textColor;
  final String label;

  const _CircleProgressPainter({
    required this.pct,
    required this.color,
    required this.isDark,
    required this.textColor,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 8.0;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground segment
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = pct * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );

    // Central text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final pctText = '${(pct * 100).round()}%';
    textPainter.text = TextSpan(
      text: pctText,
      style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 4));

    textPainter.text = TextSpan(
      text: label,
      style: AppTextStyles.dmSans(size: 6.5, color: isDark ? Colors.white60 : Colors.black45),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 8));
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.pct != pct ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.textColor != textColor ||
        oldDelegate.label != label;
  }
}

