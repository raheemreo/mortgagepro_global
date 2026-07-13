// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this
// lib/features/usa/tools/usa_closing_costs_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAClosingCostsCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAClosingCostsCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAClosingCostsCalc> createState() =>
      _USAClosingCostsCalcState();
}

class _USAClosingCostsCalcState extends ConsumerState<USAClosingCostsCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  static const List<String> _statesList = [
    'DC',
    'NY',
    'CT',
    'PA',
    'FL',
    'TX',
    'CA',
    'NJ',
    'IL',
    'WA',
    'GA',
    'AZ',
    'CO',
    'WY',
    'MO'
  ];

  double _price = 450000;
  double _downPct = 10;
  String _state = 'TX';
  bool _inclConcession = false;
  bool _inclPoints = true;

  bool _showResults = false;
  bool _isCalcDirty = true;
  final bool _calculating = false;

  final Map<String, double> _transferRates = {
    'DC': 0.029,
    'NY': 0.004,
    'CT': 0.0125,
    'PA': 0.02,
    'FL': 0.0035,
    'TX': 0.0,
    'CA': 0.0011,
    'NJ': 0.01,
    'IL': 0.001,
    'WA': 0.011,
    'GA': 0.001,
    'AZ': 0.0001,
    'CO': 0.0001,
    'WY': 0.0001,
    'MO': 0.00005,
  };

  final Map<String, String> _transferNotes = {
    'DC': 'DC: 2.9% deed recordation',
    'NY': 'NY: 0.4% + potential mansion tax',
    'CT': 'CT: 1.25% transfer tax',
    'PA': 'PA: 2.0% realty transfer',
    'FL': 'FL: \$3.50 per \$1,000 doc stamps',
    'TX': 'Texas: No state transfer tax',
    'CA': 'CA: \$1.10 per \$1,000',
    'NJ': 'NJ: 1.0% realty fee',
    'IL': 'IL: \$1.00 per \$1,000',
    'WA': 'WA: 1.10% REET',
    'GA': 'GA: \$1.00 per \$1,000',
    'AZ': 'AZ: \$0.50 per \$1,000',
    'CO': 'CO: \$0.01 per \$100',
    'WY': 'WY: Minimal transfer',
    'MO': 'MO: \$0.50 per \$1,000',
  };

  final Map<String, String> _stateLabels = {
    'DC': '🏛️ DC — Transfer Tax 2.9%',
    'NY': '🗽 New York — Mansion Tax + Transfer',
    'CT': 'CT — 1.25% transfer',
    'PA': 'PA — 2% transfer',
    'FL': 'FL — Doc stamps 0.35%',
    'TX': '🤠 Texas — No transfer tax!',
    'CA': 'CA — 0.11% transfer',
    'NJ': 'NJ — 1.0% realty fee',
    'IL': 'IL — 0.10% transfer',
    'WA': 'WA — 1.10% REET',
    'GA': 'GA — 0.10% transfer',
    'AZ': 'AZ — Minimal transfer',
    'CO': 'CO — \$0.01/\$100',
    'WY': 'WY — Low cost state',
    'MO': 'MO — \$0.005/\$100',
  };

  final Map<String, String> _stateNames = {
    'DC': 'District of Columbia',
    'NY': 'New York',
    'CT': 'Connecticut',
    'PA': 'Pennsylvania',
    'FL': 'Florida',
    'TX': 'Texas',
    'CA': 'California',
    'NJ': 'New Jersey',
    'IL': 'Illinois',
    'WA': 'Washington',
    'GA': 'Georgia',
    'AZ': 'Arizona',
    'CO': 'Colorado',
    'WY': 'Wyoming',
    'MO': 'Missouri',
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
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
      _price = 450000;
      _downPct = 10;
      _state = 'TX';
      _inclConcession = false;
      _inclPoints = true;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  // Unused: _loadSavedCalculation was defined but not referenced.

  void _calculate() {
    final errors = <String, String>{};

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() {
      _calcSnapshot['_price'] = _price;
      _calcSnapshot['_downPct'] = _downPct;
      _calcSnapshot['_state'] = _state;
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
    final loanAmt = _price * (1 - _downPct / 100);
    final downAmt = _price * _downPct / 100;
    final origFee = (loanAmt * 0.003).roundToDouble();
    final pointsAmt = _inclPoints ? (loanAmt * 0.008).roundToDouble() : 0.0;
    final titleOwner = (_price * 0.003).roundToDouble();
    final titleLender = (loanAmt * 0.0018).roundToDouble();
    final transferRate = _transferRates[_state] ?? 0;
    final transferTax = (_price * transferRate).roundToDouble();
    final prepaidInt = (loanAmt * 0.0682 / 365 * 15).roundToDouble();
    final escrowSetup = ((_price * 0.016 / 12) * 2).roundToDouble();

    double total = origFee +
        pointsAmt +
        600 +
        30 +
        titleOwner +
        titleLender +
        1000 +
        transferTax +
        200 +
        prepaidInt +
        1500 +
        escrowSetup;
    if (_inclConcession) {
      total = max(0.0, total - (_price * 0.03).roundToDouble());
    }

    final totalCash = downAmt + total;

    final labelCtrl = TextEditingController(text: 'Closing Costs');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings:
          const RouteSettings(name: '/dialog/usa_closing_costs_calc/save'),
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
              'Saving: Total Costs: ${CurrencyFormatter.compact(total, symbol: r'$')} · Cash Needed: ${CurrencyFormatter.compact(totalCash, symbol: r'$')}',
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
                hintText: 'Label (e.g. Closing Cost NY)',
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
          : 'Closing Costs';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Closing Costs',
        inputs: {
          'Price': _price,
          'DownPct': _downPct,
          'StateCode': _statesList.indexOf(_state).toDouble(),
          'InclConcession': _inclConcession ? 1.0 : 0.0,
          'InclPoints': _inclPoints ? 1.0 : 0.0,
        },
        results: {
          'Closing Costs': total,
          'Down Payment': downAmt,
          'Total Cash': totalCash,
          'Loan Amount': loanAmt,
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
    final _price = _showResults
        ? (_calcSnapshot['_price'] as double? ?? this._price)
        : this._price;
    final _downPct = _showResults
        ? (_calcSnapshot['_downPct'] as double? ?? this._downPct)
        : this._downPct;
    final _state = _showResults
        ? (_calcSnapshot['_state'] as String? ?? this._state)
        : this._state;

    final isDirty = _showResults &&
        (this._price != _calcSnapshot['_price'] ||
            this._downPct != _calcSnapshot['_downPct'] ||
            this._state != _calcSnapshot['_state']);

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.getCardColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    // Compute active calculation
    final loanAmt = _price * (1 - _downPct / 100);
    final downAmt = _price * _downPct / 100;
    final origFee = (loanAmt * 0.003).roundToDouble();
    final pointsAmt = _inclPoints ? (loanAmt * 0.008).roundToDouble() : 0.0;
    final titleOwner = (_price * 0.003).roundToDouble();
    final titleLender = (loanAmt * 0.0018).roundToDouble();
    final transferRate = _transferRates[_state] ?? 0;
    final transferTax = (_price * transferRate).roundToDouble();
    final prepaidInt = (loanAmt * 0.0682 / 365 * 15).roundToDouble();
    final escrowSetup = ((_price * 0.016 / 12) * 2).roundToDouble();

    double total = origFee +
        pointsAmt +
        600 +
        30 +
        titleOwner +
        titleLender +
        1000 +
        transferTax +
        200 +
        prepaidInt +
        1500 +
        escrowSetup;
    if (_inclConcession) {
      total = max(0.0, total - (_price * 0.03).roundToDouble());
    }

    final totalCash = downAmt + total;

    // Categories for chart
    final loanCosts = origFee + pointsAmt + 630;
    final titleFees = titleOwner + titleLender + 1000;
    final taxes = transferTax + 200;
    final prepaids = prepaidInt + 1500 + escrowSetup;
    final totalSum = loanCosts + titleFees + taxes + prepaids;

    final colors = [
      const Color(0xFF1B3F72),
      const Color(0xFFB91C1C),
      const Color(0xFFD97706),
      const Color(0xFF15803D)
    ];
    final labels = [
      'Loan Costs',
      'Title & Settlement',
      'Taxes & Recording',
      'Prepaids'
    ];
    final vals = [loanCosts, titleFees, taxes, prepaids];
    final maxVal = max(1.0, vals.reduce(max));

    // Dynamic stats header removed — using live LightRateStripBanner below

    // Insight text
    final pct = (total / _price * 100).toStringAsFixed(1);
    String insight = 'Your closing costs are $pct% of the purchase price. ';
    if (transferTax == 0) {
      insight +=
          'Great news: ${_stateNames[_state]} has no transfer tax, saving you thousands. ';
    }
    if (_inclPoints) {
      insight +=
          'Discount points add ${CurrencyFormatter.format(pointsAmt, symbol: r'$')} upfront but reduce your rate long-term. ';
    }
    if (_inclConcession) {
      insight +=
          'Seller concessions offset up to ${CurrencyFormatter.format((_price * 0.03).roundToDouble(), symbol: r'$')} in buyer costs. ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip header — Live FRED + Census median price
        LightRateStripBanner(items: [
          RateStripItem(
              label: "Nat'l Avg CC",
              provider: fredMortgage30Provider,
              fallback: 6905,
              isDollar: true,
              suffix: ''),
          RateStripItem(
              label: 'Median Home',
              provider: censusMedianHomeValueProvider,
              fallback: 412000,
              isDollar: true,
              suffix: ''),
          RateStripItem(
              label: '30-Yr Rate',
              provider: fredMortgage30Provider,
              fallback: 6.82),
          RateStripItem(
              label: 'Fed Funds',
              provider: fredFedFundsProvider,
              fallback: 5.33,
              isGold: true),
        ]),

        // Settings Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loan & Property Details',
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

        // Slider inputs inside card
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
              // Purchase Price Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Purchase Price'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w800,
                          color: mutedColor,
                          letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_price, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.w800,
                          color: primaryColor)),
                ],
              ),
              Slider(
                value: _price,
                min: 100000,
                max: 1500000,
                divisions: 280,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    this._price = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$100K',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$500K',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1M',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1.5M',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Down Payment Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Down Payment (%)'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w800,
                          color: mutedColor,
                          letterSpacing: 0.5)),
                  Text('${_downPct.toInt()}%',
                      style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.w800,
                          color: primaryColor)),
                ],
              ),
              Slider(
                value: _downPct,
                min: 3,
                max: 30,
                divisions: 27,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    this._downPct = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3%',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('10%',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('20%',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('30%',
                      style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // State Dropdown
              Text('State'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9,
                      weight: FontWeight.w800,
                      color: mutedColor,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF0F4FF),
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
                    items: _stateLabels.keys.map((code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(_stateLabels[code]!),
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

              // Concession & Points toggles
              const Divider(),
              const SizedBox(height: 10),
              _buildToggleRow(
                'Include Seller Concessions',
                'Seller pays up to 3% of buyer closing costs',
                _inclConcession,
                (val) => setState(() {
                  _inclConcession = val;
                  _markDirty();
                }),
              ),
              const SizedBox(height: 10),
              _buildToggleRow(
                'Include Points (1 pt = 1%)',
                'Avg 0.8 pts paid at closing to buy down rate',
                _inclPoints,
                (val) => setState(() {
                  _inclPoints = val;
                  _markDirty();
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculate Button
        ElevatedButton(
          onPressed: _calculate,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                theme.accentColor, // Gold-ish/Navy button matching theme
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  '🧮 Calculate Closing Costs',
                  style:
                      AppTextStyles.playfair(size: 13, weight: FontWeight.w800),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inputs have changed. Tap "Calculate" to update results.',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                color: theme.getTextColor(context),
                                weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Hero Result panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, const Color(0xFF1B3F72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED CLOSING COSTS',
                  style: AppTextStyles.dmSans(
                      size: 8,
                      weight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(total, symbol: r'$'),
                  style: AppTextStyles.playfair(
                      size: 32, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Buyer costs · ${_stateNames[_state]} · ${CurrencyFormatter.format(_price, symbol: r'$')} purchase · ${_downPct.toInt()}% down',
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildHeroBottomBox('Down Payment',
                        CurrencyFormatter.format(downAmt, symbol: r'$')),
                    const SizedBox(width: 8),
                    _buildHeroBottomBox('Closing Costs',
                        CurrencyFormatter.format(total, symbol: r'$'),
                        gold: true),
                    const SizedBox(width: 8),
                    _buildHeroBottomBox('Cash Needed',
                        CurrencyFormatter.format(totalCash, symbol: r'$')),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Donut visual
          Text(
            'Cost Breakdown Visual',
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
                  '🍩 Closing Cost Composition',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Donut graphic
                    SizedBox(
                      height: 110,
                      width: 110,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          vals: vals,
                          colors: colors,
                          price: _price,
                          totalCosts: totalSum,
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Expanded(
                      child: Column(
                        children: vals.map((v) {
                          final idx = vals.indexOf(v);
                          final pctVal =
                              totalSum > 0 ? (v / totalSum * 100).round() : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colors[idx],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(labels[idx],
                                          style: AppTextStyles.dmSans(
                                              size: 10,
                                              weight: FontWeight.w700,
                                              color: textColor)),
                                      Text('$pctVal%',
                                          style: AppTextStyles.dmSans(
                                              size: 8, color: mutedColor)),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(v, symbol: r'$'),
                                  style: AppTextStyles.playfair(
                                      size: 10.5,
                                      weight: FontWeight.w800,
                                      color: textColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cost by category horizontal bars
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
                  '📊 Cost by Category',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),
                Column(
                  children: vals.map((v) {
                    final idx = vals.indexOf(v);
                    final fillPct = (v / maxVal).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(labels[idx],
                                  style: AppTextStyles.dmSans(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: textColor)),
                              Text(CurrencyFormatter.format(v, symbol: r'$'),
                                  style: AppTextStyles.playfair(
                                      size: 10.5,
                                      weight: FontWeight.w800,
                                      color: textColor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: fillPct,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors[idx],
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
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

          // Insight card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B2F0F) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Cost Intelligence',
                  style: AppTextStyles.playfair(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFF92400E)),
                ),
                const SizedBox(height: 5),
                Text(
                  insight,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: const Color(0xFF78350F), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Save button
          ElevatedButton(
            onPressed: _saveCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 1,
            ),
            child: Text(
              '🔖 Save This Calculation',
              style:
                  AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Breakdown Table Form
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
                  'Cost Breakdown (LE Form)',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),

                // Loan Costs
                _buildBreakdownSectionHeader('🏦 Loan Costs (Section A&B)'),
                _buildBreakdownRow(
                    'Origination Fee',
                    'Lender fee · typically 0–1%',
                    CurrencyFormatter.format(origFee, symbol: r'$')),
                _buildBreakdownRow(
                    'Discount Points',
                    '0.8 pts to buy down rate',
                    _inclPoints
                        ? CurrencyFormatter.format(pointsAmt, symbol: r'$')
                        : '\$0'),
                _buildBreakdownRow('Appraisal Fee',
                    'Licensed appraiser · \$500–\$750', '\$600'),
                _buildBreakdownRow(
                    'Credit Report', 'Tri-merge credit report', '\$30'),
                const SizedBox(height: 10),

                // Title Services
                _buildBreakdownSectionHeader(
                    '📜 Other Required Services (Section C)'),
                _buildBreakdownRow(
                    'Title – Owner\'s Insurance',
                    'Protects your ownership',
                    CurrencyFormatter.format(titleOwner, symbol: r'$')),
                _buildBreakdownRow(
                    'Title – Lender\'s Insurance',
                    'Required by lender',
                    CurrencyFormatter.format(titleLender, symbol: r'$')),
                _buildBreakdownRow('Settlement / Closing Fee',
                    'Escrow / attorney fee', '\$1,000'),
                const SizedBox(height: 10),

                // Taxes
                _buildBreakdownSectionHeader(
                    '🏛️ Taxes & Government Fees (Section E)'),
                _buildBreakdownRow(
                    'State Transfer Tax',
                    _transferNotes[_state] ?? '',
                    CurrencyFormatter.format(transferTax, symbol: r'$')),
                _buildBreakdownRow(
                    'Recording Fees', 'County deed recording', '\$200'),
                const SizedBox(height: 10),

                // Prepaids
                _buildBreakdownSectionHeader('📅 Prepaids (Section F)'),
                _buildBreakdownRow(
                    'Prepaid Interest (15 days)',
                    'Per diem × 15 days',
                    CurrencyFormatter.format(prepaidInt, symbol: r'$')),
                _buildBreakdownRow(
                    'Homeowner Ins. (1 yr)', 'Full year upfront', '\$1,500'),
                _buildBreakdownRow(
                    'Escrow Setup (2 mo reserve)',
                    'Tax + insurance impound',
                    CurrencyFormatter.format(escrowSetup, symbol: r'$')),
                const SizedBox(height: 12),

                const Divider(),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Estimated Closing Costs',
                        style: AppTextStyles.playfair(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: textColor)),
                    Text(CurrencyFormatter.format(total, symbol: r'$'),
                        style: AppTextStyles.playfair(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: primaryColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Related tools
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
            GestureDetector(
              onTap: () => context.push('/tool/usa/piti'),
              child: _buildRelatedCard(
                  '📊',
                  'PITI Calculator',
                  'Full monthly payment',
                  'All-in-one',
                  const Color(0xFFEFF6FF),
                  const Color(0xFF1D4ED8)),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/downpayment'),
              child: _buildRelatedCard(
                  '💰', 'Down Payment', '3–20% comparison', null, null, null,
                  red: true),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/propertytax'),
              child: _buildRelatedCard(
                  '🏛️', 'Property Tax', 'By state & county', null, null, null,
                  gold: true),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/pmi'),
              child: _buildRelatedCard(
                  '🛡️', 'PMI Calculator', '<20% down impact', null, null, null,
                  slate: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelatedCard(String icon, String title, String desc,
      String? badgeText, Color? badgeBg, Color? badgeTextCol,
      {bool red = false, bool gold = false, bool slate = false}) {
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
          Text(title,
              style: AppTextStyles.playfair(
                  size: 12.5, weight: FontWeight.w800, color: titleCol)),
          Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: descCol)),
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
                      size: 8,
                      weight: FontWeight.w700,
                      color: badgeTextCol ?? Colors.white)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBreakdownSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.dmSans(
            size: 8,
            weight: FontWeight.w800,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildBreakdownRow(String name, String note, String amt) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.dmSans(
                        size: 11, weight: FontWeight.w700, color: textColor)),
                if (note.isNotEmpty)
                  Text(note,
                      style:
                          AppTextStyles.dmSans(size: 8.5, color: mutedColor)),
              ],
            ),
          ),
          Text(amt,
              style: AppTextStyles.playfair(
                  size: 11.5, weight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildHeroBottomBox(String label, String val, {bool gold = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
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

  Widget _buildToggleRow(
      String title, String subtitle, bool val, ValueChanged<bool> onChanged) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.dmSans(
                      size: 11.5, weight: FontWeight.w700, color: textColor)),
              Text(subtitle,
                  style: AppTextStyles.dmSans(size: 9, color: mutedColor)),
            ],
          ),
        ),
        Switch(
          value: val,
          activeThumbColor: widget.theme.primaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Custom Painter for Donut Chart
class _DonutPainter extends CustomPainter {
  final List<double> vals;
  final List<Color> colors;
  final double price;
  final double totalCosts;
  final Color textColor;
  final Color mutedColor;

  const _DonutPainter({
    required this.vals,
    required this.colors,
    required this.price,
    required this.totalCosts,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    final total = vals.reduce((a, b) => a + b);
    if (total == 0) return;

    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < vals.length; i++) {
      final sweepAngle = (vals[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Draw central text
    final pct =
        price > 0 ? (totalCosts / price * 100).toStringAsFixed(1) : '0.0';
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '$pct%',
      style: AppTextStyles.playfair(
          size: 9.5, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2 - 4));

    textPainter.text = TextSpan(
      text: 'of price',
      style: AppTextStyles.dmSans(size: 7.5, color: mutedColor),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2,
            center.dy - textPainter.height / 2 + 6));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.price != price ||
        oldDelegate.totalCosts != totalCosts ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}
