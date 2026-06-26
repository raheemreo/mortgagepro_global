// lib/features/australia/tools/au_stamp_duty.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUStampDuty extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUStampDuty({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUStampDuty> createState() => _AUStampDutyState();
}

class _AUStampDutyState extends ConsumerState<AUStampDuty> {
  String _selectedState = 'NSW';
  double _propVal = 750000;
  String _buyerType = 'owner'; // 'owner', 'fhb', 'investor'
  String _propType = 'established'; // 'established', 'new', 'vacant'

  bool _showResults = false;

  void _reset() {
    setState(() {
      _selectedState = 'NSW';
      _propVal = 750000;
      _buyerType = 'owner';
      _propType = 'established';
      _showResults = false;
    });
  }

  // 2025 stamp duty brackets configuration
  static final Map<String, dynamic> _stampRates = {
    'NSW': {
      'brackets': [
        [0.0, 14000.0, 1.25],
        [14000.0, 32000.0, 1.5],
        [32000.0, 85000.0, 1.75],
        [85000.0, 319000.0, 3.5],
        [319000.0, 1064000.0, 4.5],
        [1064000.0, 3131000.0, 5.5],
        [3131000.0, double.infinity, 7.0]
      ],
      'concessions':
          'Full exemption on established homes up to \$650K, concession up to \$800K for FHB.'
    },
    'VIC': {
      'brackets': [
        [0.0, 25000.0, 1.4],
        [25000.0, 130000.0, 2.4],
        [130000.0, 440000.0, 5.0],
        [440000.0, 550000.0, 6.0],
        [550000.0, 960000.0, 6.0],
        [960000.0, double.infinity, 6.5]
      ],
      'concessions':
          'Duty waiver on first \$600K (FHB established). Principal place of residence concession.'
    },
    'QLD': {
      'brackets': [
        [0.0, 5000.0, 0.0],
        [5000.0, 75000.0, 1.5],
        [75000.0, 540000.0, 3.5],
        [540000.0, 1000000.0, 4.5],
        [1000000.0, double.infinity, 5.75]
      ],
      'concessions':
          'FHB concession: duty rebate up to \$8,750 on homes under \$700K. FHOG \$30,000 (updated 2024).'
    },
    'WA': {
      'brackets': [
        [0.0, 80000.0, 1.9],
        [80000.0, 100000.0, 2.85],
        [100000.0, 250000.0, 3.8],
        [250000.0, 500000.0, 4.75],
        [500000.0, double.infinity, 5.15]
      ],
      'concessions':
          'FHB exemption on homes up to \$430K, concession up to \$530K.'
    },
    'SA': {
      'brackets': [
        [0.0, 12000.0, 1.0],
        [12000.0, 30000.0, 2.0],
        [30000.0, 50000.0, 3.0],
        [50000.0, 100000.0, 3.5],
        [100000.0, 200000.0, 4.0],
        [200000.0, 250000.0, 4.25],
        [250000.0, 300000.0, 4.75],
        [300000.0, 500000.0, 5.0],
        [500000.0, double.infinity, 5.5]
      ],
      'concessions':
          'No stamp duty exemption for FHB in SA. FHOG \$15,000 for new homes.'
    },
    'TAS': {
      'brackets': [
        [0.0, 3000.0, 50.0], // fixed dollar amount on first bracket
        [3000.0, 25000.0, 1.75],
        [25000.0, 75000.0, 2.25],
        [75000.0, 200000.0, 3.5],
        [200000.0, 375000.0, 4.0],
        [375000.0, 725000.0, 4.25],
        [725000.0, double.infinity, 4.5]
      ],
      'concessions':
          '50% duty concession for FHB on established homes (announced 2023). FHOG \$30,000 new homes.'
    },
    'ACT': {
      'brackets': [
        [0.0, 260000.0, 0.6],
        [260000.0, 300000.0, 2.2],
        [300000.0, 500000.0, 3.4],
        [500000.0, 750000.0, 4.32],
        [750000.0, 1000000.0, 5.9],
        [1000000.0, 1455000.0, 6.4],
        [1455000.0, double.infinity, 6.9]
      ],
      'concessions':
          'Home Buyer Concession Scheme: duty-free on eligible owner-occupier purchases (income tested).'
    },
    'NT': {
      'brackets': [],
      'concessions':
          'NT FHOG \$10,000. First Home Owner Discount: 50% duty concession for homes under \$650K.'
    }
  };

  static const Map<String, dynamic> _fhogData = {
    'NSW': {'new': 10000.0},
    'VIC': {'new': 10000.0},
    'QLD': {'new': 30000.0},
    'WA': {'new': 10000.0},
    'SA': {'new': 15000.0},
    'TAS': {'new': 30000.0},
    'ACT': {'new': 0.0},
    'NT': {'new': 10000.0}
  };

  Map<String, double> _calcStamp(
      String state, double value, String buyer, String propType) {
    double duty = 0;
    if (state == 'NT') {
      if (value < 525000) {
        duty = (0.06571441 * pow(value / 1000, 2) + 15 * (value / 1000));
      } else {
        duty = value * 0.0495;
      }
    } else {
      final brackets = _stampRates[state]['brackets'] as List;
      for (final br in brackets) {
        final double low = br[0];
        final double high = br[1];
        final double rate = br[2];

        if (value > low) {
          final taxable = min(value, high) - low;
          if (state == 'TAS' && low == 0) {
            duty += rate; // fixed fee on TAS first bracket
          } else {
            duty += taxable * (rate / 100);
          }
        }
      }
    }

    double concession = 0;
    if (buyer == 'fhb') {
      if (state == 'NSW' && value <= 800000) {
        if (value <= 650000) {
          concession = duty;
        } else {
          concession = duty * (800000 - value) / 150000;
        }
      }
      if (state == 'VIC' && value <= 750000) {
        if (value <= 600000) {
          concession = duty;
        }
      }
      if (state == 'QLD' && value <= 700000) {
        concession = min(duty, 8750);
      }
      if (state == 'WA' && value <= 530000) {
        if (value <= 430000) {
          concession = duty;
        } else {
          concession = duty * (530000 - value) / 100000;
        }
      }
      if (state == 'TAS') {
        concession = duty * 0.5;
      }
      if (state == 'ACT') {
        concession = duty; // simplified full concession
      }
      if (state == 'NT' && value <= 650000) {
        concession = duty * 0.5;
      }
    }

    final dutyAfterConc = max(duty - concession, 0.0);
    double fhog = 0;
    if (buyer == 'fhb' && propType == 'new') {
      fhog = _fhogData[state]['new'] ?? 0.0;
    }

    return {
      'duty': duty,
      'concession': concession,
      'dutyAfterConc': dutyAfterConc,
      'fhog': fhog,
    };
  }

  void _saveCalculation() async {
    final res = _calcStamp(_selectedState, _propVal, _buyerType, _propType);
    final duty = res['duty']!;
    final concession = res['concession']!;
    final dutyAfterConc = res['dutyAfterConc']!;
    final fhog = res['fhog']!;
    final netCost = max(0.0, dutyAfterConc - fhog);

    final labelCtrl =
        TextEditingController(text: 'Stamp Duty - $_selectedState');
    final confirmed = await showDialog<bool>(
      context: context,
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
                'Saving: \$${CurrencyFormatter.compact(dutyAfterConc, symbol: 'AU\$')} stamp duty in $_selectedState',
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
        calcType: 'Stamp Duty (AUS)',
        inputs: {
          'propertyValue': _propVal,
          'state': _selectedState == 'NSW'
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
          'buyerType': _buyerType == 'owner'
              ? 0.0
              : _buyerType == 'fhb'
                  ? 1.0
                  : 2.0,
          'propertyType': _propType == 'established'
              ? 0.0
              : _propType == 'new'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'duty': duty,
          'concession': concession,
          'dutyAfterConc': dutyAfterConc,
          'fhog': fhog,
          'netCost': netCost,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stamp duty saved!',
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

    // Stamp duty results
    final res = _calcStamp(_selectedState, _propVal, _buyerType, _propType);
    final duty = res['duty']!;
    final concession = res['concession']!;
    final dutyAfterConc = res['dutyAfterConc']!;
    final fhog = res['fhog']!;
    final effRate = _propVal > 0 ? (duty / _propVal * 100) : 0.0;
    final netCost = max(0.0, dutyAfterConc - fhog);

    // Costs details
    const conveyancing = 1800.0;
    const inspection = 600.0;
    const lender = 800.0;
    const registration = 160.0;
    final totalUpfront = dutyAfterConc +
        conveyancing +
        inspection +
        lender +
        registration -
        fhog;

    // States comparison duties list
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
    final List<Map<String, dynamic>> comparisonList = statesList.map((st) {
      final r = _calcStamp(st, _propVal, _buyerType, _propType);
      return {
        'state': st,
        'duty': r['dutyAfterConc']!,
      };
    }).toList();
    final maxDutyValue =
        comparisonList.map((c) => c['duty'] as double).reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selection State Grid & Property Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SELECT STATE / TERRITORY',
                      style: AppTextStyles.dmSans(
                          size: 9,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : theme.primaryColor,
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // States buttons grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 1.8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: statesList.map((st) {
                  final active = st == _selectedState;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedState = st),
                    child: Container(
                      decoration: BoxDecoration(
                        color: active
                            ? theme.primaryColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFFFF8F0)),
                        border: Border.all(
                            color: active
                                ? theme.primaryColor
                                : (isDark
                                    ? theme.getBorderColor(context)
                                    : const Color(0x3B7C2D12))),
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
                              : (isDark
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF92400E)),
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
                      child: _buildBuyerTab(
                          'Owner Occupier',
                          _buyerType == 'owner',
                          () => setState(() => _buyerType = 'owner'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildBuyerTab(
                          'First Home Buyer',
                          _buyerType == 'fhb',
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
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFFFF8F0),
                  border: Border.all(
                      color: isDark
                          ? theme.getBorderColor(context)
                          : theme.borderColor),
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
                    items: [
                      DropdownMenuItem(
                          value: 'established',
                          child: Text('Established Home',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'new',
                          child: Text('New Home / Off-the-Plan',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'vacant',
                          child: Text('Vacant Land',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
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
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('🏘️ Calculate Stamp Duty',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          const SizedBox(height: 20),

          // Result Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD97706), Color(0xFF92400E)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_selectedState Transfer Duty',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white70,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(duty, currencyCode: 'AUD'),
                    style: AppTextStyles.playfair(
                        size: 36,
                        color: Colors.white,
                        weight: FontWeight.w800)),
                Text('Transfer duty payable at settlement',
                    style:
                        AppTextStyles.dmSans(size: 12, color: Colors.white70)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildResultBox(
                        'Effective Rate', '${effRate.toStringAsFixed(2)}%'),
                    _buildResultBox(
                        'After Concessions',
                        concession > 0
                            ? CurrencyFormatter.format(dutyAfterConc,
                                currencyCode: 'AUD')
                            : 'No concession',
                        color: const Color(0xFFFFD700)),
                    _buildResultBox(
                        'FHOG Grant',
                        fhog > 0
                            ? CurrencyFormatter.format(fhog,
                                currencyCode: 'AUD')
                            : 'N/A'),
                    _buildResultBox('Net Cost',
                        CurrencyFormatter.format(netCost, currencyCode: 'AUD'),
                        color: const Color(0xFFFFD700)),
                  ],
                ),
                if (_buyerType == 'fhb' &&
                    _stampRates[_selectedState]['concessions'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                        '✅ FHB Concession: ${_stampRates[_selectedState]['concessions']}',
                        style: AppTextStyles.dmSans(
                            size: 11, color: Colors.white)),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔖', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Save This Calculation',
                          style: AppTextStyles.dmSans(
                              size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Upfront Cost Breakdown Card
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? theme.getBorderColor(context)
                      : theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upfront Cost Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                _buildCostRow(
                    'Stamp Duty',
                    '$_selectedState transfer duty ${_buyerType == 'fhb' ? '(FHB concession applied)' : ''}',
                    CurrencyFormatter.format(dutyAfterConc,
                        currencyCode: 'AUD')),
                _buildCostRow(
                    'Conveyancing / Legal',
                    'Estimated solicitor fees',
                    CurrencyFormatter.format(conveyancing,
                        currencyCode: 'AUD')),
                _buildCostRow(
                    'Building & Pest Inspection',
                    'Pre-purchase inspection',
                    CurrencyFormatter.format(inspection, currencyCode: 'AUD')),
                _buildCostRow(
                    'Lender / Mortgage Fees',
                    'Application + valuation',
                    CurrencyFormatter.format(lender, currencyCode: 'AUD')),
                _buildCostRow(
                    'Title & Land Registration',
                    'Gov. registration fees',
                    CurrencyFormatter.format(registration,
                        currencyCode: 'AUD')),
                if (fhog > 0)
                  _buildCostRow('FHOG Grant', 'First Home Owner Grant offset',
                      '-${CurrencyFormatter.format(fhog, currencyCode: 'AUD')}',
                      isNegative: true),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0x0C7C2D12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Upfront Costs',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context))),
                      Text(
                          CurrencyFormatter.format(totalUpfront,
                              currencyCode: 'AUD'),
                          style: AppTextStyles.playfair(
                              size: 17,
                              weight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF7C2D12))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // State comparison bar chart
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? theme.getBorderColor(context)
                      : theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('State Comparison (same property)',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                ...comparisonList.map((c) {
                  final double dVal = c['duty'];
                  final String st = c['state'];
                  final active = st == _selectedState;
                  final barPct = maxDutyValue > 0 ? (dVal / maxDutyValue) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 32,
                            child: Text(st,
                                style: AppTextStyles.dmSans(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF92400E)))),
                        Expanded(
                          child: Container(
                            height: 9,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFFFF8F0),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: barPct.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: active
                                      ? const LinearGradient(colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFD97706)
                                        ])
                                      : LinearGradient(colors: [
                                          const Color(0xFFD97706),
                                          isDark
                                              ? const Color(0xFF60A5FA)
                                              : const Color(0xFF7C2D12)
                                        ]),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 65,
                            child: Text(
                                CurrencyFormatter.format(dVal,
                                    currencyCode: 'AUD'),
                                style: AppTextStyles.dmSans(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color: active
                                        ? (isDark
                                            ? const Color(0xFFFFD700)
                                            : const Color(0xFF7C2D12))
                                        : theme.getTextColor(context)),
                                textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Info tips
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF7C2D12).withValues(alpha: 0.3)
                  : const Color(0xFFFFF7ED),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.dmSans(
                    size: 11,
                    color: isDark
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF92400E),
                    height: 1.5),
                children: [
                  TextSpan(
                      text: '📋 2025 Note: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF7C2D12))),
                  TextSpan(
                      text:
                          '${_stampRates[_selectedState]['concessions'] ?? 'No concessions available for this buyer type.'} Rates updated for financial year 2024–25. Stamp duty is also known as transfer duty in QLD and WA. Always verify with your state revenue office.'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliderInputRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFFFF8F0),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Text('\$ ',
                  style: AppTextStyles.dmSans(
                      size: 14,
                      color:
                          isDark ? const Color(0xFFFFD700) : theme.primaryColor,
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
            activeTrackColor:
                isDark ? const Color(0xFFFFD700) : theme.primaryColor,
            inactiveTrackColor:
                (isDark ? const Color(0xFFFFD700) : theme.primaryColor)
                    .withValues(alpha: 0.15),
            thumbColor: isDark ? const Color(0xFFFFD700) : theme.primaryColor,
            trackHeight: 3,
            overlayColor:
                (isDark ? const Color(0xFFFFD700) : theme.primaryColor)
                    .withValues(alpha: 0.1),
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
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFFFF8F0)),
          border: Border.all(
              color: active
                  ? widget.theme.primaryColor
                  : (isDark
                      ? widget.theme.getBorderColor(context)
                      : const Color(0x3B7C2D12))),
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

  Widget _buildResultBox(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                  size: 13,
                  weight: FontWeight.w800,
                  color: color ?? Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, String sub, String val,
      {bool isNegative = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.bold,
                        color: widget.theme.getTextColor(context))),
                Text(sub,
                    style: AppTextStyles.dmSans(
                        size: 10, color: widget.theme.getMutedColor(context))),
              ],
            ),
          ),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: isNegative
                      ? const Color(0xFF0F766E)
                      : (isDark
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF7C2D12)))),
        ],
      ),
    );
  }
}
