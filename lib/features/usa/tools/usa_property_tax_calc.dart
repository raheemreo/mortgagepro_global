// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_property_tax_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAPropertyTaxCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAPropertyTaxCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAPropertyTaxCalc> createState() => _USAPropertyTaxCalcState();
}

class _USAPropertyTaxCalcState extends ConsumerState<USAPropertyTaxCalc> {
  final _resultsKey = GlobalKey();
  final Map<dynamic, dynamic> _calcSnapshot = {};
  static const List<String> _statesList = [
    'NJ', 'IL', 'CT', 'VT', 'NY', 'WI', 'TX', 'NE', 'OH', 'PA', 'IA', 'MI', 'WA', 'GA',
    'FL', 'CA', 'OR', 'NC', 'SC', 'NV', 'WY', 'DC', 'AZ', 'CO', 'TN', 'AL', 'HI'
  ];

  double _assessedValue = 300000;
  String _state = 'TX';
  double _exemptAmt = 25000;

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  final Map<String, double> _stateRates = {
    'NJ': 2.23, 'IL': 2.08, 'CT': 1.79, 'VT': 1.90, 'NY': 1.72, 'WI': 1.73, 'TX': 1.60,
    'NE': 1.54, 'OH': 1.53, 'PA': 1.49, 'IA': 1.46, 'MI': 1.44, 'WA': 0.87, 'GA': 0.87,
    'FL': 0.83, 'CA': 0.76, 'OR': 0.90, 'NC': 0.70, 'SC': 0.52, 'NV': 0.52, 'WY': 0.56,
    'DC': 0.55, 'AZ': 0.51, 'CO': 0.48, 'TN': 0.48, 'AL': 0.40, 'HI': 0.29
  };

  final Map<String, String> _stateNames = {
    'NJ': 'New Jersey', 'IL': 'Illinois', 'CT': 'Connecticut', 'VT': 'Vermont', 'NY': 'New York',
    'WI': 'Wisconsin', 'TX': 'Texas', 'NE': 'Nebraska', 'OH': 'Ohio', 'PA': 'Pennsylvania',
    'IA': 'Iowa', 'MI': 'Michigan', 'WA': 'Washington', 'GA': 'Georgia', 'FL': 'Florida',
    'CA': 'California', 'OR': 'Oregon', 'NC': 'North Carolina', 'SC': 'South Carolina',
    'NV': 'Nevada', 'WY': 'Wyoming', 'DC': 'District of Columbia', 'AZ': 'Arizona',
    'CO': 'Colorado', 'TN': 'Tennessee', 'AL': 'Alabama', 'HI': 'Hawaii'
  };

  final List<Map<String, dynamic>> _compStates = [
    {'code': 'NJ', 'name': 'New Jersey', 'rate': 2.23},
    {'code': 'TX', 'name': 'Texas', 'rate': 1.60},
    {'code': 'OH', 'name': 'Ohio', 'rate': 1.53},
    {'code': 'US', 'name': 'US Average', 'rate': 1.07},
    {'code': 'FL', 'name': 'Florida', 'rate': 0.83},
    {'code': 'HI', 'name': 'Hawaii', 'rate': 0.29}
  ];

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  void _resetInputs() {
    setState(() {
      _calcSnapshot.clear();
      _showResults = false;
      _assessedValue = 300000;
      _state = 'TX';
      _exemptAmt = 25000;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  // Unused: _loadSavedCalculation removed to resolve analyzer warnings.

    void _calculate() {
    setState(() {
      _calcSnapshot['_assessedValue'] = _assessedValue;
      _calcSnapshot['_state'] = _state;
      _calcSnapshot['_exemptAmt'] = _exemptAmt;
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
    final rate = _stateRates[_state] ?? 1.07;
    final taxableVal = max(0.0, _assessedValue - _exemptAmt);
    final annualTax = (taxableVal * rate / 100).roundToDouble();
    final monthlyTax = (annualTax / 12).roundToDouble();

    final labelCtrl = TextEditingController(text: 'Property Tax');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_property_tax_calc/save'),
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
              'Saving: Tax: ${CurrencyFormatter.compact(annualTax, symbol: r'$')}/yr · State: ${_stateNames[_state]}',
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
                hintText: 'Label (e.g. My Property Tax)',
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
          : 'Property Tax';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Property Tax Calc',
        inputs: {
          'AssessedValue': _assessedValue,
          'StateCode': _statesList.indexOf(_state).toDouble(),
          'ExemptAmt': _exemptAmt,
        },
        results: {
          'Annual Tax': annualTax,
          'Monthly Tax': monthlyTax,
          'Assessed Value': _assessedValue,
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
    final _assessedValue = _showResults ? (_calcSnapshot['_assessedValue'] ?? this._assessedValue) : this._assessedValue;
    final _state = _showResults ? (_calcSnapshot['_state'] ?? this._state) : this._state;
    final _exemptAmt = _showResults ? (_calcSnapshot['_exemptAmt'] ?? this._exemptAmt) : this._exemptAmt;

    final isDirty = _showResults && (this._assessedValue != _calcSnapshot['_assessedValue'] || this._state != _calcSnapshot['_state'] || this._exemptAmt != _calcSnapshot['_exemptAmt']);

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.getCardColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    // Compute active calculation
    final rate = _stateRates[_state] ?? 1.07;
    final stateName = _stateNames[_state] ?? _state;
    final taxableVal = max<num>(0.0, _assessedValue - _exemptAmt).toDouble();
    final annualTax = (taxableVal * rate / 100).roundToDouble();
    final fullTax = (_assessedValue * rate / 100).roundToDouble();
    final monthlyTax = (annualTax / 12).roundToDouble();
    final savings = fullTax - annualTax;

    // Rate strip values removed — using live LightRateStripBanner below

    // State comparison values
    final compValues = _compStates.map((s) {
      double r = s['rate'];
      if (s['code'] == _state) {
        r = rate;
      }
      return (s['name'] as String, (r * _assessedValue / 100).roundToDouble(), s['code'] == _state || s['code'] == 'US', r);
    }).toList();
    final maxCompVal = max(1.0, compValues.map((e) => e.$2).reduce(max));

    // 5-Year projection values
    final List<(String, double)> projections = [];
    double projectionTotal = 0.0;
    for (int y = 1; y <= 5; y++) {
      final projVal = (_assessedValue * pow(1.03, y)).roundToDouble();
      final projTax = (max<num>(0.0, projVal - _exemptAmt) * rate / 100).roundToDouble();
      projections.add(('Year $y', projTax));
      projectionTotal += projTax;
    }
    final maxProjVal = max(1.0, projections.map((e) => e.$2).reduce(max));

    // State Rates Table data
    const tableStates = [
      {'flag': '🏙️', 'state': 'New Jersey', 'rate': '2.23%', 'val': '\$6,690', 'rank': '51st', 'class': 'rate-hi'},
      {'flag': '🌆', 'state': 'Illinois', 'rate': '2.08%', 'val': '\$6,240', 'rank': '50th', 'class': 'rate-hi'},
      {'flag': '🤠', 'state': 'Texas', 'rate': '1.60%', 'val': '\$4,800', 'rank': '43rd', 'class': 'rate-md'},
      {'flag': '🚗', 'state': 'Michigan', 'rate': '1.44%', 'val': '\$4,320', 'rank': '40th', 'class': 'rate-md'},
      {'flag': '🎬', 'state': 'California', 'rate': '0.76%', 'val': '\$2,280', 'rank': '16th', 'class': 'rate-lo'},
      {'flag': '🌴', 'state': 'Florida', 'rate': '0.83%', 'val': '\$2,490', 'rank': '20th', 'class': 'rate-lo'},
      {'flag': '🌺', 'state': 'Hawaii', 'rate': '0.29%', 'val': '\$870', 'rank': '1st', 'class': 'rate-lo'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip — Live FRED + Census median home value
        LightRateStripBanner(items: [
          RateStripItem(label: 'US Avg Rate', provider: fredMortgage30Provider, fallback: 1.07),
          RateStripItem(label: 'Median Home\nValue', provider: censusMedianHomeValueProvider, fallback: 310000, isDollar: true, suffix: ''),
          RateStripItem(label: '30-Yr Rate', provider: fredMortgage30Provider, fallback: 6.82),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),

        // Result Hero Card
        Text(
          'Your Tax Estimate',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANNUAL PROPERTY TAX',
                style: AppTextStyles.dmSans(
                    size: 8,
                    weight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                _showResults ? CurrencyFormatter.format(annualTax, symbol: r'$') : '\$0',
                style: AppTextStyles.playfair(
                    size: 32, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                _showResults
                    ? '$stateName · ${rate.toStringAsFixed(2)}% effective rate · ${CurrencyFormatter.format(_assessedValue, symbol: r'$')} assessed value'
                    : 'Enter details below and tap Calculate',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroBottomBox('Monthly (PITI)', _showResults ? CurrencyFormatter.format(monthlyTax, symbol: r'$') : '—'),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Effective Rate', _showResults ? '${rate.toStringAsFixed(2)}%' : '—', gold: true),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('After Exemption', _showResults ? CurrencyFormatter.format(annualTax, symbol: r'$') : '—'),
                ],
              )
            ],
          ),
        ),

        // Save banner
        if (_showResults) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                          'Inputs have changed. Tap "Calculate" to update results.',
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

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save This Calculation',
                        style: AppTextStyles.playfair(
                            size: 12, weight: FontWeight.w800, color: const Color(0xFF15803D)),
                      ),
                      Text(
                        '$stateName · ${CurrencyFormatter.compact(_assessedValue, symbol: r'$')} · ${CurrencyFormatter.format(annualTax, symbol: r'$')}/yr',
                        style: AppTextStyles.dmSans(
                            size: 9.5, color: const Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
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

        // Inputs Card
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
              // Assessed Value Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assessed Value'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_assessedValue, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _assessedValue,
                min: 50000,
                max: 2000000,
                divisions: 195,
                activeColor: const Color(0xFF334155),
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    this._assessedValue = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$50K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$500K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$2M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // State Select Dropdown
              Text('State'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _state,
                    isExpanded: true,
                    dropdownColor: cardColor,
                    style: AppTextStyles.dmSans(
                        size: 13, weight: FontWeight.w700, color: textColor),
                    items: _stateNames.keys.map((code) {
                      final name = _stateNames[code]!;
                      final pct = _stateRates[code]!;
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text('$name — ${pct.toStringAsFixed(2)}%'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          this._state = val;
                          _markDirty();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Homestead Exemption choice buttons
              Text('Homestead Exemption (if applicable)'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildExemptBtn('None', 0.0),
                  const SizedBox(width: 6),
                  _buildExemptBtn('\$25K', 25000.0),
                  const SizedBox(width: 6),
                  _buildExemptBtn('\$50K', 50000.0),
                  const SizedBox(width: 6),
                  _buildExemptBtn('\$100K', 100000.0),
                ],
              ),
              const SizedBox(height: 16),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
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
                        '🧮 Calculate Property Tax',
                        style: AppTextStyles.playfair(
                            size: 13, weight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
        Container(
          key: _resultsKey,
          margin: const EdgeInsets.only(bottom: 12),
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
                          'Inputs have changed. Tap "Calculate" to update results.',
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

          // Breakdown analysis donut
          Text(
            'Tax Breakdown Analysis',
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
                    const Text('📊', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Annual Cost Breakdown',
                      style: AppTextStyles.playfair(
                          size: 12, weight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Donut graph
                    SizedBox(
                      height: 86,
                      width: 86,
                      child: CustomPaint(
                        painter: _TaxDonutPainter(
                          taxableVal: taxableVal,
                          exemptVal: _exemptAmt,
                          totalVal: _assessedValue,
                          rate: rate,
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow('Full Tax', fullTax, const Color(0xFF334155)),
                          const SizedBox(height: 6),
                          _buildLegendRow('Exemption Savings', savings, const Color(0xFF6EE7B7), sign: '-'),
                          const SizedBox(height: 6),
                          _buildLegendRow('You Owe', annualTax, const Color(0xFF1E293B)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // State comparison bars list
                Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'vs. Other States (your value)',
                      style: AppTextStyles.playfair(
                          size: 12, weight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: compValues.map((item) {
                    final fillPct = (item.$2 / maxCompVal).clamp(0.0, 1.0);
                    final isSelected = item.$3;
                    final col = sColor(item.$1, isSelected);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              item.$1.split(' ')[0],
                              style: AppTextStyles.dmSans(
                                  size: 9.5, weight: FontWeight.w700, color: mutedColor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: fillPct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: col,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          SizedBox(
                            width: 52,
                            child: Text(
                              CurrencyFormatter.compact(item.$2, symbol: r'$'),
                              style: AppTextStyles.playfair(
                                  size: 10.5, weight: FontWeight.w800, color: textColor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5-Year Projection Card
          Text(
            '5-Year Tax Projection',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📈', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Projected Annual Tax (3% appreciation)',
                      style: AppTextStyles.playfair(
                          size: 12, weight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: projections.map((item) {
                    final fillPct = (item.$2 / maxProjVal).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              item.$1,
                              style: AppTextStyles.dmSans(
                                  size: 9.5, weight: FontWeight.w700, color: mutedColor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: fillPct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF475569)]),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          SizedBox(
                            width: 52,
                            child: Text(
                              CurrencyFormatter.compact(item.$2, symbol: r'$'),
                              style: AppTextStyles.playfair(
                                  size: 10.5, weight: FontWeight.w800, color: textColor),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5-Year Total',
                          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedColor)),
                      Text(
                        CurrencyFormatter.format(projectionTotal, symbol: r'$'),
                        style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // State rate table guide
        Text(
          'State Property Tax Rates',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.6),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.1),
              3: FlexColumnWidth(0.8),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                ),
                children: [
                  _buildTableHeaderCell('State', leftAlign: true),
                  _buildTableHeaderCell('Rate'),
                  _buildTableHeaderCell('\$300K Home'),
                  _buildTableHeaderCell('Rank'),
                ],
              ),
              ...tableStates.map((row) {
                final isSelected = row['state'] == stateName;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
                      child: Row(
                        children: [
                          Text(row['flag']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(row['state']!,
                                style: AppTextStyles.playfair(
                                    size: 11.5, weight: FontWeight.w800, color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rPillBg(row['class']!),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(row['rate']!,
                              style: AppTextStyles.dmSans(
                                  size: 9.5, weight: FontWeight.w800, color: rPillFg(row['class']!))),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(row['val']!,
                          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(row['rank']!,
                          style: AppTextStyles.dmSans(size: 11, color: mutedColor),
                          textAlign: TextAlign.center),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Common Exemptions Info
        Text(
          'Common Exemptions',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildExemptRow('🏠 Homestead Exemption', 'Primary residence reduction · most states offer this', '\$25K–\$100K'),
              _buildExemptRow('👴 Senior Citizens', 'Age 65+ freeze or reduction · varies by state', 'Up to \$50K'),
              _buildExemptRow('🎖️ Veterans / Disabled', '100% disabled vets may qualify for full exemption', '100% off'),
              _buildExemptRow('📜 CA Prop 13', 'Limits increases to 2%/yr · purchase price base', '2% cap'),
              _buildExemptRow('🌟 TX Homestead Cap', 'Appraised value increase capped at 10%/yr', '10% cap', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Related Tools
        Text(
          'Related Tools',
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
            _buildRelatedCard('📊', 'PITI Calculator', 'Add tax to mortgage payment', null, null, null, slate: true, onTap: () => context.push('/tool/usa/piti')),
            _buildRelatedCard('🏠', 'Closing Costs', 'Transfer taxes included', null, null, null, onTap: () => context.push('/tool/usa/closingcosts')),
            _buildRelatedCard('📋', 'Tax Deduction', 'SALT deduction \$10K cap', '2025 Rules', const Color(0xFFF0FDF4), const Color(0xFF15803D), gold: true, onTap: () => context.push('/tool/usa/taxdeduction')),
            _buildRelatedCard('📉', 'Appeal Guide', 'Contest your assessment', null, null, null, red: true),
          ],
        ),
      ],
    );
  }

  Color sColor(String stateName, bool isSelected) {
    if (isSelected) {
      return const Color(0xFF334155);
    }
    if (stateName == 'US Average') {
      return const Color(0xFF94A3B8);
    }
    return const Color(0xFFCBD5E1);
  }

  Color rPillBg(String cls) {
    if (cls == 'rate-hi') return const Color(0xFFFEF2F2);
    if (cls == 'rate-md') return const Color(0xFFFFF7ED);
    return const Color(0xFFF0FDF4);
  }

  Color rPillFg(String cls) {
    if (cls == 'rate-hi') return const Color(0xFFB91C1C);
    if (cls == 'rate-md') return const Color(0xFFC2410C);
    return const Color(0xFF15803D);
  }

  Widget _buildRelatedCard(String icon, String title, String desc, String? badgeText,
      Color? badgeBg, Color? badgeTextCol,
      {bool red = false, bool gold = false, bool slate = false, VoidCallback? onTap}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color titleCol = Colors.white;
    Color descCol = Colors.white70;

    if (red) {
      bg = const Color(0xFFB91C1C);
    } else if (gold) {
      bg = const Color(0xFFD97706);
    } else if (slate) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFF334155);
    } else {
      bg = theme.primaryColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Text(title,
                style: AppTextStyles.playfair(
                    size: 12.5, weight: FontWeight.w800, color: titleCol)),
            Text(desc,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: descCol)),
            if (badgeText != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg ?? Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badgeText,
                    style: AppTextStyles.dmSans(
                        size: 8, weight: FontWeight.w700, color: badgeTextCol ?? Colors.white)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildExemptRow(String title, String desc, String value, {bool isLast = false}) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textColor)),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: mutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: const Color(0xFF15803D))),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String name, double val, Color color, {String sign = ''}) {
    final textColor = widget.theme.getTextColor(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(name, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: textColor)),
        const Spacer(),
        Text(
          '$sign${CurrencyFormatter.format(val, symbol: r'$')}',
          style: AppTextStyles.playfair(size: 10.5, weight: FontWeight.w800, color: textColor),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, {bool leftAlign = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
            size: 9, weight: FontWeight.w800, color: Colors.white70),
        textAlign: leftAlign ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildExemptBtn(String label, double val) {
    final sel = _exemptAmt == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _exemptAmt = val;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFF1F5F9) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF334155) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 11,
                weight: sel ? FontWeight.w800 : FontWeight.w700,
                color: sel ? const Color(0xFF334155) : widget.theme.getMutedColor(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBottomBox(String label, String val, {bool gold = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
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
                    color: gold ? const Color(0xFFFCD34D) : Colors.white)),
          ],
        ),
      ),
    );
  }

  // Unused: _buildInfoCard removed to resolve analyzer warnings.
}

// Custom Painter for Tax Breakdown Donut Chart
class _TaxDonutPainter extends CustomPainter {
  final double taxableVal;
  final double exemptVal;
  final double totalVal;
  final double rate;
  final Color textColor;
  final Color mutedColor;

  const _TaxDonutPainter({
    required this.taxableVal,
    required this.exemptVal,
    required this.totalVal,
    required this.rate,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    final fullTax = totalVal * rate / 100;
    final annualTax = taxableVal * rate / 100;
    final savings = fullTax - annualTax;

    if (fullTax == 0) return;

    double startAngle = -pi / 2;

    // Draw background gray path
    final trackPaint = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw "You Owe" segment (blue)
    final owePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final oweSweep = (annualTax / fullTax) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      oweSweep,
      false,
      owePaint,
    );

    // Draw "Savings" segment (green) starting where "You Owe" ends
    if (savings > 0) {
      final savingsPaint = Paint()
        ..color = const Color(0xFF6EE7B7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final savingsSweep = (savings / fullTax) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + oweSweep,
        savingsSweep,
        false,
        savingsPaint,
      );
    }

    // Draw central text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '${rate.toStringAsFixed(2)}%',
      style: AppTextStyles.playfair(size: 9, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 6));

    textPainter.text = TextSpan(
      text: 'Rate',
      style: AppTextStyles.dmSans(size: 7, color: mutedColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 5));
  }

  @override
  bool shouldRepaint(covariant _TaxDonutPainter oldDelegate) {
    return oldDelegate.taxableVal != taxableVal ||
        oldDelegate.exemptVal != exemptVal ||
        oldDelegate.totalVal != totalVal ||
        oldDelegate.rate != rate ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}

