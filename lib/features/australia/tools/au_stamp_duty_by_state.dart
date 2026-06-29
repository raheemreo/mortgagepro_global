// lib/features/australia/tools/au_stamp_duty_by_state.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUStampDutyByState extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUStampDutyByState({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUStampDutyByState> createState() => _AUStampDutyByStateState();
}

class _AUStampDutyByStateState extends ConsumerState<AUStampDutyByState> {
  int _activeTab = 0; // 0 = Calculator, 1 = Compare, 2 = Rate Tables

  // Calculator inputs
  String _selectedState = 'NSW';
  double _propVal = 750000;
  String _buyerType = 'owner'; // 'owner', 'fhb', 'investor'
  String _propType = 'established'; // 'established', 'new', 'vacant'
  bool _showResults = true;

  // Comparison inputs
  double _comparePropVal = 750000;
  String _compareBuyerType = 'fhb';

  // Detailed marginal tax rate structure (2024-25)
  static final Map<String, dynamic> _stampRates = {
    'NSW': {
      'brackets': [
        [0.0, 16000.0, 0.0, 1.25],
        [16000.0, 35000.0, 200.0, 1.5],
        [35000.0, 93000.0, 485.0, 1.75],
        [93000.0, 351000.0, 1500.0, 3.5],
        [351000.0, 1168000.0, 10530.0, 4.5],
        [1168000.0, 3505000.0, 47295.0, 5.5],
        [3505000.0, double.infinity, 175735.0, 7.0]
      ],
      'concessions': 'Exempt <\$650K, concession \$650K-\$800K for FHB.',
      'name': 'New South Wales'
    },
    'VIC': {
      'brackets': [
        [0.0, 25000.0, 0.0, 1.4],
        [25000.0, 130000.0, 350.0, 2.4],
        [130000.0, 440000.0, 2870.0, 5.0],
        [440000.0, 550000.0, 18370.0, 6.0],
        [550000.0, 960000.0, 24970.0, 6.0],
        [960000.0, 2000000.0, 49570.0, 5.5],
        [2000000.0, double.infinity, 106770.0, 6.5]
      ],
      'concessions': 'Waiver on first \$600K, concession up to \$750K.',
      'name': 'Victoria'
    },
    'QLD': {
      'brackets': [
        [0.0, 5000.0, 0.0, 0.0],
        [5000.0, 75000.0, 0.0, 1.5],
        [75000.0, 540000.0, 1050.0, 3.5],
        [540000.0, 1000000.0, 17325.0, 4.5],
        [1000000.0, double.infinity, 38025.0, 5.75]
      ],
      'concessions': 'Rebate up to \$8,750 for homes under \$700K.',
      'name': 'Queensland'
    },
    'WA': {
      'brackets': [
        [0.0, 120000.0, 0.0, 1.9],
        [120000.0, 150000.0, 2280.0, 2.85],
        [150000.0, 360000.0, 3135.0, 3.8],
        [360000.0, 725000.0, 11115.0, 4.75],
        [725000.0, double.infinity, 28453.0, 5.15]
      ],
      'concessions': 'Exempt <\$430K, concession \$430K-\$530K.',
      'name': 'Western Australia'
    },
    'SA': {
      'brackets': [
        [0.0, 12000.0, 0.0, 1.0],
        [12000.0, 30000.0, 120.0, 2.0],
        [30000.0, 50000.0, 480.0, 3.0],
        [50000.0, 100000.0, 1080.0, 3.5],
        [100000.0, 200000.0, 2830.0, 4.0],
        [200000.0, 250000.0, 6830.0, 4.25],
        [250000.0, 300000.0, 8955.0, 4.75],
        [300000.0, 500000.0, 11330.0, 5.0],
        [500000.0, double.infinity, 21330.0, 5.5]
      ],
      'concessions': 'No FHB concession. FHOG is \$15,000 for new builds.',
      'name': 'South Australia'
    },
    'TAS': {
      'brackets': [
        [0.0, 3000.0, 50.0, 0.0],
        [3000.0, 25000.0, 50.0, 1.75],
        [25000.0, 75000.0, 435.0, 2.25],
        [75000.0, 200000.0, 1560.0, 3.5],
        [200000.0, 375000.0, 5935.0, 4.0],
        [375000.0, 725000.0, 12935.0, 4.25],
        [725000.0, double.infinity, 27810.0, 4.5]
      ],
      'concessions': '50% concession for first-home buyers under \$750K.',
      'name': 'Tasmania'
    },
    'ACT': {
      'brackets': [
        [0.0, 200000.0, 0.0, 0.0],
        [200000.0, 300000.0, 0.0, 4.17],
        [300000.0, 500000.0, 4170.0, 2.79],
        [500000.0, 750000.0, 9750.0, 3.8],
        [750000.0, 1000000.0, 19250.0, 4.74],
        [1000000.0, 1455000.0, 31100.0, 5.9],
        [1455000.0, double.infinity, 57945.0, 6.4]
      ],
      'concessions': 'Exempt below \$1M (income-tested Home Buyer Scheme).',
      'name': 'Australian Capital Territory'
    },
    'NT': {
      'brackets': [], // Formula-based below $525K
      'concessions': 'Discount up to \$26,730 for first home buyers.',
      'name': 'Northern Territory'
    }
  };

  double _calculateDuty(double value, String stateKey, String buyer) {
    if (stateKey == 'NT') {
      double rawDuty = 0;
      if (value <= 525000) {
        // NT Formula: (0.06571441 * V^2 / 1000000) + 15 * (V/1000)
        // Wait, the HTML formula: Math.max(0, (0.06571441 * value * value / 1000000) + 15);
        // Let's use the exact HTML formula:
        rawDuty = (0.06571441 * value * value / 1000000) + 15;
        if (rawDuty < 0) rawDuty = 0;
      } else {
        rawDuty = value * 0.0495;
      }

      if (buyer == 'fhb') {
        // First Home Owner Discount: 50% discount up to $26,730 concession
        double discount = rawDuty * 0.5;
        if (discount > 26730) discount = 26730;
        return max(0.0, rawDuty - discount);
      }
      return rawDuty;
    }

    final data = _stampRates[stateKey];
    if (data == null) return 0.0;
    final brackets = data['brackets'] as List;
    double rawDuty = 0;

    for (final br in brackets) {
      final double minVal = br[0];
      final double maxVal = br[1];
      final double base = br[2];
      final double rate = br[3];

      if (value > minVal) {
        final taxable = min(value, maxVal) - minVal;
        if (stateKey == 'TAS' && minVal == 0) {
          rawDuty = base; // Fixed fee
        } else {
          rawDuty = base + (taxable * rate / 100);
        }
      }
      if (value <= maxVal) break;
    }

    // Apply concessions
    double concession = 0;
    if (buyer == 'fhb') {
      if (stateKey == 'NSW') {
        if (value <= 650000) {
          concession = rawDuty; // Full exemption
        } else if (value <= 800000) {
          // Pro-rata concession
          concession = rawDuty * (800000 - value) / 150000;
        }
      } else if (stateKey == 'VIC') {
        if (value <= 600000) {
          concession = rawDuty; // Full exemption
        } else if (value <= 750000) {
          concession = rawDuty * (750000 - value) / 150000;
        }
      } else if (stateKey == 'QLD' && value <= 700000) {
        // Exemption up to $500k, concession up to $700k
        if (value <= 500000) {
          concession = rawDuty;
        } else {
          // QLD gives standard concession rebate of $8,750 max
          concession = min(rawDuty, 8750.0);
        }
      } else if (stateKey == 'WA') {
        if (value <= 430000) {
          concession = rawDuty;
        } else if (value <= 530000) {
          concession = rawDuty * (530000 - value) / 100000;
        }
      } else if (stateKey == 'TAS' && value <= 750000) {
        concession = rawDuty * 0.5; // 50% discount
      } else if (stateKey == 'ACT' && value <= 1000000) {
        concession = rawDuty; // Full concession
      }
    }

    return max(0.0, rawDuty - concession);
  }

  void _saveCalculation() async {
    final duty = _calculateDuty(_propVal, _selectedState, _buyerType);
    final effRate = _propVal > 0 ? (duty / _propVal * 100) : 0.0;
    final total = _propVal + duty + 3500; // includes $3500 legal/other

    final labelCtrl =
        TextEditingController(text: 'Stamp Duty - $_selectedState');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_stamp_duty_by_state/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Stamp Duty Calc',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: \$${CurrencyFormatter.compact(duty, symbol: 'AU\$')} stamp duty in $_selectedState',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My NSW Stamp Duty)',
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
          : 'Stamp Duty Plan';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Stamp Duty by State',
        inputs: {
          'propertyValue': _propVal,
          'stateIndex': _selectedState == 'NSW'
              ? 0.0
              : _selectedState == 'VIC'
                  ? 1.0
                  : _selectedState == 'QLD'
                      ? 2.0
                      : _selectedState == 'WA'
                          ? 3.0
                          : _selectedState == 'SA'
                              ? 4.0
                              : _selectedState == 'TAS'
                                  ? 5.0
                                  : _selectedState == 'ACT'
                                      ? 6.0
                                      : 7.0,
          'buyerTypeIndex': _buyerType == 'owner'
              ? 0.0
              : _buyerType == 'fhb'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'duty': duty,
          'effectiveRate': effRate,
          'totalCosts': total,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTabBtn('Calculator', 0)),
              Expanded(child: _buildTabBtn('Compare', 1)),
              Expanded(child: _buildTabBtn('Rate Tables', 2)),
            ],
          ),
        ),

        // Active Tab Screen
        if (_activeTab == 0) _buildCalculatorTab(theme),
        if (_activeTab == 1) _buildCompareTab(theme),
        if (_activeTab == 2) _buildRatesTab(theme),
      ],
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w800,
            color: active
                ? Colors.white
                : widget.theme.getTextColor(context).withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: CALCULATOR ─────────────────────────────────────────────
  Widget _buildCalculatorTab(CountryTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duty = _calculateDuty(_propVal, _selectedState, _buyerType);
    final rawDutyWithoutConc =
        _calculateDuty(_propVal, _selectedState, 'owner');
    final concessionSaved = max(0.0, rawDutyWithoutConc - duty);
    final effRate = _propVal > 0 ? (duty / _propVal * 100) : 0.0;
    const estLegalOther = 3500.0;
    final totalCost = _propVal + duty + estLegalOther;

    final stateName = _stampRates[_selectedState]?['name'] ?? _selectedState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SELECT STATE / TERRITORY',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),

              // States buttons grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 1.8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT']
                    .map((st) {
                  final active = st == _selectedState;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedState = st),
                    child: Container(
                      decoration: BoxDecoration(
                        color: active
                            ? theme.primaryColor
                            : theme.getBgColor(context),
                        border: Border.all(
                            color: active
                                ? theme.primaryColor
                                : theme.getBorderColor(context)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        st,
                        style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : theme.getTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _buildSliderInputRow(
                label: 'Property Value',
                value: _propVal,
                min: 100000,
                max: 3000000,
                onChanged: (val) => setState(() => _propVal = val),
              ),
              const SizedBox(height: 12),

              // Buyer Type Tabs
              Text('BUYER TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _buildBuyerTab('Owner-Occ', _buyerType == 'owner',
                          () => setState(() => _buyerType = 'owner'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildBuyerTab('First Home', _buyerType == 'fhb',
                          () => setState(() => _buyerType = 'fhb'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildBuyerTab(
                          'Investor',
                          _buyerType == 'investor',
                          () => setState(() => _buyerType = 'investor'))),
                ],
              ),
              const SizedBox(height: 12),

              // Property Type Select Dropdown
              Text('PROPERTY TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  border: Border.all(color: theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _propType,
                    dropdownColor: theme.getCardColor(context),
                    isExpanded: true,
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800),
                    items: const [
                      DropdownMenuItem(
                          value: 'established',
                          child: Text('Established Home')),
                      DropdownMenuItem(
                          value: 'new', child: Text('New Build / Plan')),
                      DropdownMenuItem(
                          value: 'vacant', child: Text('Vacant Land')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _propType = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('🏛️ Calculate Stamp Duty',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        if (_showResults) ...[
          const SizedBox(height: 16),

          // Output Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.primaryColor, theme.accentColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_selectedState — $stateName',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white60,
                        weight: FontWeight.w800,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(duty, currencyCode: 'AUD'),
                    style: AppTextStyles.playfair(
                        size: 34,
                        color: Colors.white,
                        weight: FontWeight.w900)),
                Text(
                    'on a ${CurrencyFormatter.compact(_propVal, symbol: 'AU\$')} $_propType property',
                    style:
                        AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildResultBox(
                        'Effective Rate', '${effRate.toStringAsFixed(2)}%'),
                    _buildResultBox(
                        'Concession Saved',
                        concessionSaved > 0
                            ? CurrencyFormatter.format(concessionSaved,
                                currencyCode: 'AUD')
                            : 'Nil'),
                    _buildResultBox(
                        'Total Purchase Cost',
                        CurrencyFormatter.format(totalCost,
                            currencyCode: 'AUD')),
                    _buildResultBox('Marginal Rate Bracket',
                        '${_getMarginalRate(_propVal, _selectedState)}%'),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(double.infinity, 38),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💾', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Save Calculation',
                          style: AppTextStyles.dmSans(
                              size: 12, weight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_buyerType == 'fhb' &&
              _stampRates[_selectedState]?['concessions'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                    : const Color(0xFFEFF6FF),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF93C5FD)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎉 First Home Buyer Benefit',
                      style: AppTextStyles.playfair(
                          size: 12,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1E3A8A),
                          weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(_stampRates[_selectedState]['concessions'],
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB))),
                ],
              ),
            ),
          ],

          // Total cost breakdown and donut chart
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Purchase Costs Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: _StampDutyDonutPainter(
                          propertyVal: _propVal,
                          stampDuty: duty,
                          legalOther: estLegalOther,
                          primaryColor: isDark
                              ? const Color(0xFF60A5FA)
                              : theme.primaryColor,
                          accentColor: isDark
                              ? const Color(0xFF34D399)
                              : theme.accentColor,
                          textColor: theme.getTextColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow(
                              'Property Value', _propVal, theme.accentColor),
                          _buildLegendRow(
                              'Stamp Duty', duty, theme.primaryColor),
                          _buildLegendRow('Est. Legal & Other', estLegalOther,
                              Colors.amber),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Breakdown table
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marginal Tax Rate Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 10),
                _buildBreakdownTable(_propVal, _selectedState, theme),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendRow(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    color: widget.theme
                        .getTextColor(context)
                        .withValues(alpha: 0.75),
                    weight: FontWeight.w600)),
          ),
          Text(CurrencyFormatter.format(val, currencyCode: 'AUD'),
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: widget.theme.getTextColor(context),
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildBreakdownTable(double val, String stateKey, CountryTheme theme) {
    if (stateKey == 'NT') {
      return Text(
        'Northern Territory uses a polynomial formula for properties below \$525,000:\nDuty = (0.06571441 * V² / 1,000,000) + 15\nAbove \$525,000, a flat rate of 4.95% applies.',
        style: AppTextStyles.dmSans(
            size: 11, color: theme.getTextColor(context), height: 1.4),
      );
    }
    final s = _stampRates[stateKey];
    final brackets = s['brackets'] as List;
    List<Widget> rows = [];

    for (var b in brackets) {
      if (val <= b[0]) break;
      final double minV = b[0];
      final double maxV = b[1];
      final double base = b[2];
      final double rate = b[3];

      final taxable = min(val, maxV) - minV;

      final endText = maxV == double.infinity
          ? '+'
          : '– \$${CurrencyFormatter.compact(maxV, symbol: '')}';

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${CurrencyFormatter.compact(minV, symbol: '')}$endText',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color: theme.getTextColor(context).withValues(alpha: 0.8),
                      weight: FontWeight.w600)),
              Text('$rate%',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFFD700)
                          : theme.primaryColor,
                      weight: FontWeight.w800)),
              Text(
                  CurrencyFormatter.format(base + (taxable * rate / 100),
                      currencyCode: 'AUD'),
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w700)),
            ],
          ),
        ),
      );
      if (val <= maxV) break;
    }

    return Column(children: rows);
  }

  double _getMarginalRate(double value, String stateKey) {
    if (stateKey == 'NT') {
      return value <= 525000 ? 4.95 : 4.95; // NT formula approximation
    }
    final brackets = _stampRates[stateKey]['brackets'] as List;
    for (final br in brackets) {
      if (value >= br[0] && value <= br[1]) {
        return br[3];
      }
    }
    return 0.0;
  }

  // ─── TAB 2: COMPARE STATES ─────────────────────────────────────────
  Widget _buildCompareTab(CountryTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> statesList = [
      'NSW',
      'VIC',
      'QLD',
      'WA',
      'SA',
      'TAS',
      'ACT',
      'NT'
    ];
    final List<Map<String, dynamic>> dataList = statesList.map((st) {
      final double dVal =
          _calculateDuty(_comparePropVal, st, _compareBuyerType);
      final double rate =
          _comparePropVal > 0 ? (dVal / _comparePropVal * 100) : 0.0;
      return {
        'state': st,
        'duty': dVal,
        'rate': rate,
      };
    }).toList();

    // Sort by duty ascending
    dataList
        .sort((a, b) => (a['duty'] as double).compareTo(b['duty'] as double));
    final maxDuty = dataList.map((c) => c['duty'] as double).reduce(max);
    final maxRate = dataList.map((c) => c['rate'] as double).reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderInputRow(
                label: 'Property Value for Comparison',
                value: _comparePropVal,
                min: 100000,
                max: 3000000,
                onChanged: (val) => setState(() => _comparePropVal = val),
              ),
              const SizedBox(height: 12),
              Text('BUYER TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _buildBuyerTab(
                          'Owner-Occ',
                          _compareBuyerType == 'owner',
                          () => setState(() => _compareBuyerType = 'owner'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildBuyerTab(
                          'First Home',
                          _compareBuyerType == 'fhb',
                          () => setState(() => _compareBuyerType = 'fhb'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildBuyerTab(
                          'Investor',
                          _compareBuyerType == 'investor',
                          () =>
                              setState(() => _compareBuyerType = 'investor'))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comparison bar chart card - Duties
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stamp Duty Payable (\$ AUD) 🗺️',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              ...dataList.map((item) {
                final double dVal = item['duty'];
                final String st = item['state'];
                final double barPct = maxDuty > 0 ? (dVal / maxDuty) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9.0),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 32,
                          child: Text(st,
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFFFD700)
                                      : theme.primaryColor))),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: barPct.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF60A5FA),
                                          const Color(0xFF3B82F6)
                                        ]
                                      : [theme.accentColor, theme.primaryColor],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          CurrencyFormatter.format(dVal, currencyCode: 'AUD'),
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context)),
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

        // Comparison bar chart card - Effective rates
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Effective Duty Rate (%)',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              ...dataList.map((item) {
                final double rate = item['rate'];
                final String st = item['state'];
                final double barPct = maxRate > 0 ? (rate / maxRate) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9.0),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 32,
                          child: Text(st,
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFFFD700)
                                      : theme.primaryColor))),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: barPct.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Color(0xFFD97706)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${rate.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context)),
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
      ],
    );
  }

  // ─── TAB 3: RATE TABLES ────────────────────────────────────────────
  Widget _buildRatesTab(CountryTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _stampRates.entries.map((entry) {
        final st = entry.key;
        final data = entry.value;
        final name = data['name'];
        final brackets = data['brackets'] as List;
        final conc = data['concessions'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$st — $name',
                      style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: (isDark
                                ? const Color(0xFFFFD700)
                                : theme.primaryColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('2024–25',
                        style: AppTextStyles.dmSans(
                            size: 9,
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : theme.primaryColor,
                            weight: FontWeight.w800)),
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (st == 'NT')
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Polynomial rate below \$525,000:\nDuty = (0.06571441 * V² / 1,000,000) + 15\nFlat rate of 4.95% applies for properties \$525,000 and above.',
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        color:
                            theme.getTextColor(context).withValues(alpha: 0.8),
                        height: 1.4),
                  ),
                )
              else
                ...brackets.map((b) {
                  final double minV = b[0];
                  final double maxV = b[1];
                  final double base = b[2];
                  final double rate = b[3];
                  final endText = maxV == double.infinity
                      ? 'and over'
                      : '– \$${CurrencyFormatter.compact(maxV, symbol: '')}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '\$${CurrencyFormatter.compact(minV, symbol: '')} $endText',
                            style: AppTextStyles.dmSans(
                                size: 10.5,
                                color: theme
                                    .getTextColor(context)
                                    .withValues(alpha: 0.75))),
                        Text(
                            base > 0
                                ? '\$${CurrencyFormatter.compact(base, symbol: '')} + $rate%'
                                : '$rate%',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFFFD700)
                                    : theme.primaryColor)),
                      ],
                    ),
                  );
                }),
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏡 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text('FHB Concessions: $conc',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: theme
                                .getTextColor(context)
                                .withValues(alpha: 0.65))),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── UI Helper Components ──────────────────────────────────────────
  Widget _buildSliderInputRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9,
                color: theme.getMutedColor(context),
                weight: FontWeight.w800,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Text('\$ ',
                  style: AppTextStyles.dmSans(
                      size: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFFD700)
                          : theme.primaryColor,
                      weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: value.toInt().toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.dmSans(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800),
                  decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.primaryColor,
            inactiveTrackColor: theme.primaryColor.withValues(alpha: 0.15),
            thumbColor: theme.primaryColor,
            trackHeight: 3,
            overlayColor: theme.primaryColor.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${(min / 1000).toStringAsFixed(0)}K',
                style: AppTextStyles.dmSans(
                    size: 9, color: theme.getMutedColor(context))),
            Text('\$${(max / 1000000).toStringAsFixed(1)}M',
                style: AppTextStyles.dmSans(
                    size: 9, color: theme.getMutedColor(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildBuyerTab(String text, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? widget.theme.primaryColor
              : widget.theme.getBgColor(context),
          border: Border.all(
              color: active
                  ? widget.theme.primaryColor
                  : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: active
                ? Colors.white
                : (isDark ? const Color(0xFFFFD700) : const Color(0xFF92400E)),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 12.5, color: Colors.white, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// Donut Chart Custom Painter
class _StampDutyDonutPainter extends CustomPainter {
  final double propertyVal;
  final double stampDuty;
  final double legalOther;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  _StampDutyDonutPainter({
    required this.propertyVal,
    required this.stampDuty,
    required this.legalOther,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final paintBg = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    final total = propertyVal + stampDuty + legalOther;
    if (total <= 0) return;

    final propSweep = (propertyVal / total) * 2 * pi;
    final stampSweep = (stampDuty / total) * 2 * pi;
    final legalSweep = (legalOther / total) * 2 * pi;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    // 1. Property value arc (Accent Color)
    final paintProp = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, startAngle, propSweep, false, paintProp);
    startAngle += propSweep;

    // 2. Stamp duty arc (Primary Color)
    final paintStamp = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, startAngle, stampSweep, false, paintStamp);
    startAngle += stampSweep;

    // 3. Legal/Other arc (Amber)
    final paintLegal = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, startAngle, legalSweep, false, paintLegal);

    // Percentage text inside
    final pct = total > 0 ? (stampDuty / total * 100) : 0.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${pct.toStringAsFixed(1)}%',
        style: AppTextStyles.dmSans(
            size: 11, weight: FontWeight.w900, color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
