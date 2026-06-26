// lib/features/usa/tools/usa_moving_cost_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAMovingCostCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAMovingCostCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAMovingCostCalc> createState() => _USAMovingCostCalcState();
}

class _USAMovingCostCalcState extends ConsumerState<USAMovingCostCalc> {
  String _moveType = 'long'; // 'local', 'long', 'cross'
  String _fromState = 'NY';
  String _toState = 'TX';
  String _homeSize = '2br'; // 'studio', '2br', '4br', 'office'
  final _distanceController = TextEditingController(text: '1500');
  String _moveSeason = 'offpeak'; // 'peak', 'offpeak'
  String _storageOpt = 'no'; // 'no', '1mo', '3mo', '6mo'
  String _packingOpt = 'self'; // 'self', 'partial', 'full'

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  final List<String> _states = ['CA', 'TX', 'NY', 'FL', 'IL', 'WA', 'CO', 'GA', 'AZ', 'NV'];

  @override
  void initState() {
    super.initState();
    _distanceController.addListener(_markDirty);
    // Auto calculate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  final Map<String, Map<String, double>> _costMatrix = {
    'local': {'studio': 950, '2br': 1250, '4br': 1900, 'office': 2200},
    'long': {'studio': 2800, '2br': 4200, '4br': 6800, 'office': 9000},
    'cross': {'studio': 4500, '2br': 7200, '4br': 11500, 'office': 14000}
  };

  Map<String, dynamic> _calcCosts(String seasonOverride) {
    final size = _homeSize;
    final season = seasonOverride;
    final storage = _storageOpt;
    final packing = _packingOpt;

    double base = _costMatrix[_moveType]?[size] ?? 0.0;
    if (season == 'peak') {
      base *= 1.20;
    }

    final double fuel = _moveType == 'local' ? 80 : _moveType == 'long' ? 320 : 580;
    final double insurance = (base * 0.03).roundToDouble();
    final double packMat = packing == 'self' ? 180 : packing == 'partial' ? 450 : 900;
    final double packService = packing == 'partial' ? 350 : packing == 'full' ? 900 : 0;
    final double storageAmt = storage == 'no' ? 0 : storage == '1mo' ? 180 : storage == '3mo' ? 540 : 1080;
    final double travel = _moveType == 'local' ? 80 : _moveType == 'long' ? 350 : 650;
    const double tips = 100;

    final double subtotal = base + fuel + insurance + packMat + packService + storageAmt + travel + tips;
    final double contingency = (subtotal * 0.10).roundToDouble();
    final double total = subtotal + contingency;

    return {
      'base': base,
      'fuel': fuel,
      'insurance': insurance,
      'packMat': packMat,
      'packService': packService,
      'storageAmt': storageAmt,
      'travel': travel,
      'tips': tips,
      'subtotal': subtotal,
      'contingency': contingency,
      'total': total,
    };
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final c = _calcCosts(_moveSeason);
    final total = c['total'] as double;
    if (total <= 0) return;

    final labelCtrl = TextEditingController(text: 'Moving Cost Estimate');
    final confirmed = await showDialog<bool>(
      context: context,
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
              'Saving estimate: From $_fromState to $_toState · Total: ${CurrencyFormatter.compact(total, symbol: r'$')}',
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
                hintText: 'Label (e.g. My Move to Texas)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Moving Cost Estimate';
      
      final moveTypeIdx = _moveType == 'local' ? 0.0 : _moveType == 'long' ? 1.0 : 2.0;
      final homeSizeIdx = _homeSize == 'studio' ? 0.0 : _homeSize == '2br' ? 1.0 : _homeSize == '4br' ? 2.0 : 3.0;
      final seasonIdx = _moveSeason == 'peak' ? 0.0 : 1.0;
      
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Moving Cost Calc',
        inputs: {
          'MoveType': moveTypeIdx,
          'HomeSize': homeSizeIdx,
          'Distance': _val(_distanceController),
          'Season': seasonIdx,
        },
        results: {
          'Total Cost': total,
          'Mover Base': c['base'] as double,
          'Add-Ons': (c['fuel'] as double) + (c['insurance'] as double) + (c['packMat'] as double) + (c['packService'] as double),
          'Travel & Tips': (c['travel'] as double) + (c['tips'] as double),
          'Contingency': c['contingency'] as double,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
    
    final current = _calcCosts(_moveSeason);
    final otherSeason = _moveSeason == 'peak' ? 'offpeak' : 'peak';
    final comparison = _calcCosts(otherSeason);

    final totalVal = current['total'] as double;
    final baseVal = current['base'] as double;
    final addonsVal = (current['fuel'] as double) + (current['insurance'] as double) + (current['packMat'] as double) + (current['packService'] as double);
    final travelVal = (current['travel'] as double) + (current['tips'] as double);
    final contingencyVal = current['contingency'] as double;

    final offPeakTotal = _moveSeason == 'offpeak' ? totalVal : comparison['total'] as double;
    final peakTotal = _moveSeason == 'peak' ? totalVal : comparison['total'] as double;
    final savings = peakTotal - offPeakTotal;

    final typeLabel = _moveType == 'local' ? 'Local' : _moveType == 'long' ? 'Long Distance' : 'Cross-Country';
    final sizeLabel = _homeSize == 'studio' ? 'Studio/1BR' : _homeSize == '2br' ? '2-3BR' : _homeSize == '4br' ? '4+BR' : 'Office';

    // Horizontal bars
    final List<Map<String, dynamic>> barItems = [
      {'name': '🚛 Movers', 'val': baseVal, 'color': const Color(0xFF1B3F72)},
      {'name': '📦 Packing', 'val': (current['packMat'] as double) + (current['packService'] as double), 'color': const Color(0xFFB91C1C)},
      {'name': '⛽ Fuel', 'val': current['fuel'] as double, 'color': const Color(0xFFD97706)},
      {'name': '🛡 Insurance', 'val': current['insurance'] as double, 'color': const Color(0xFF6D28D9)},
      {'name': '🏨 Travel', 'val': (current['travel'] as double) + (current['tips'] as double), 'color': const Color(0xFF15803D)},
      {'name': '🏗 Storage', 'val': current['storageAmt'] as double, 'color': const Color(0xFF0284C7)},
      {'name': '🔄 Buffer', 'val': contingencyVal, 'color': const Color(0xFF64748B)},
    ].where((b) => (b['val'] as double) > 0).toList();

    final maxBarVal = barItems.isNotEmpty
        ? barItems.map((b) => b['val'] as double).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Local Avg', r'$1,250', '<50 mi', theme, context),
              _buildHeaderStat('Long Dist.', r'$4,890', 'Avg USA', theme, context, isGold: true),
              _buildHeaderStat('Cross-Ctry', r'$9,200', 'Coast-Coast', theme, context),
              _buildHeaderStat('Storage/mo', r'$180', '10x10 unit', theme, context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('MOVE DETAILS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Estimator Form Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move Type', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildTypeBtn('local', '📍 Local\n<50 mi'),
                  const SizedBox(width: 6),
                  _buildTypeBtn('long', '🛣️ Long Dist.\n50–500 mi'),
                  const SizedBox(width: 6),
                  _buildTypeBtn('cross', '✈️ Cross-Ctry\n500+ mi'),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField('Origin State', _fromState, _states, (v) {
                      setState(() {
                        _fromState = v!;
                        _markDirty();
                      });
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField('Destination State', _toState, _states, (v) {
                      setState(() {
                        _toState = v!;
                        _markDirty();
                      });
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDropdownField(
                'Home Size',
                _homeSize,
                ['studio', '2br', '4br', 'office'],
                (v) {
                  setState(() {
                    _homeSize = v!;
                    _markDirty();
                  });
                },
                labels: {
                  'studio': 'Studio / 1BR Apartment',
                  '2br': '2–3 Bedroom Home',
                  '4br': '4+ Bedroom Home',
                  'office': 'Office / Commercial'
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Move Distance (mi)', _distanceController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'Move Month',
                      _moveSeason,
                      ['peak', 'offpeak'],
                      (v) {
                        setState(() {
                          _moveSeason = v!;
                          _markDirty();
                        });
                      },
                      labels: {
                        'peak': 'May–Sep (Peak)',
                        'offpeak': 'Oct–Apr (Off-Peak)',
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Need Storage?',
                      _storageOpt,
                      ['no', '1mo', '3mo', '6mo'],
                      (v) {
                        setState(() {
                          _storageOpt = v!;
                          _markDirty();
                        });
                      },
                      labels: {
                        'no': 'No Storage',
                        '1mo': '1 Month',
                        '3mo': '3 Months',
                        '6mo': '6 Months',
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'Packing Service',
                      _packingOpt,
                      ['self', 'partial', 'full'],
                      (v) {
                        setState(() {
                          _packingOpt = v!;
                          _markDirty();
                        });
                      },
                      labels: {
                        'self': 'Self Pack',
                        'partial': 'Partial Pack',
                        'full': 'Full Pack',
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.85)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _calculate,
                        child: _calculating
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('📦 Calculate Moving Budget', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showResults ? _saveCalculation : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _showResults ? const Color(0xFFD97706) : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('💾 Save',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: _showResults ? Colors.white : theme.getMutedColor(context),
                              weight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
          // Results Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED TOTAL MOVING COST', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(CurrencyFormatter.format(totalVal, symbol: r'$'),
                    style: AppTextStyles.playfair(size: 36, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('$typeLabel · $_fromState → $_toState · $sizeLabel · ${_moveSeason == 'peak' ? 'Peak Season' : 'Off-Peak'}',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroResult('Moving Co.', baseVal),
                    _buildHeroResult('Add-Ons', addonsVal),
                    _buildHeroResult('Travel/Hotel', travelVal),
                    _buildHeroResult('Contingency', contingencyVal, color: const Color(0xFF6EE7B7)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown chart card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Cost Breakdown by Category', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('Proportional breakdown of your moving budget', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 14),
                ...barItems.map((bar) {
                  final double val = bar['val'] as double;
                  final double pct = val / maxBarVal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bar['name'] as String, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.w600)),
                            Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: pct.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bar['color'] as Color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
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

          // Seasonal compare card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Seasonal Savings Opportunity', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('Same move — different timing', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🍂 Off-Peak', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(CurrencyFormatter.format(offPeakTotal, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                            Text('Oct – Apr', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('☀️ Peak Season', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB91C1C), weight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(CurrencyFormatter.format(peakTotal, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFFB91C1C), weight: FontWeight.bold)),
                            Text('May – Sep', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (savings > 0) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      '💡 Moving off-peak saves you ${CurrencyFormatter.format(savings, symbol: r'$')} (${(savings / peakTotal * 100).round()}% less)',
                      style: AppTextStyles.dmSans(size: 11, color: const Color(0xFF15803D), weight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Itemized Breakdown List
          Text('COST BREAKDOWN', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreakdownItem('Professional Movers', 'Truck + crew, labor hours', baseVal),
                _buildBreakdownItem('Packing Materials', 'Boxes, tape, bubble wrap', (current['packMat'] as double)),
                _buildBreakdownItem('Fuel Surcharge', 'Long distance fuel cost', current['fuel'] as double),
                _buildBreakdownItem('Moving Insurance', 'Full value protection', current['insurance'] as double),
                _buildBreakdownItem('Hotel / Gas / Food', 'Travel during move', current['travel'] as double),
                _buildBreakdownItem('Storage Unit', 'If needed', current['storageAmt'] as double),
                _buildBreakdownItem('Tips for Crew', r'$20–50/mover recommended', current['tips'] as double),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1D3A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Budget (incl. 10% buffer)', style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(totalVal, symbol: r'$'), style: AppTextStyles.playfair(size: 16, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // COL comparisons Scroll
        Text('COST OF LIVING COMPARISON', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildColCard('🌴', 'California', '+38%', 'vs US avg', 'High COL', isHigh: true),
              _buildColCard('🤠', 'Texas', '-8%', 'vs US avg', 'Low COL', isHigh: false),
              _buildColCard('🌇', 'New York', '+62%', 'vs US avg', 'High COL', isHigh: true),
              _buildColCard('🌞', 'Florida', '+5%', 'vs US avg', 'Near Avg', isHigh: null),
              _buildColCard('🌄', 'Colorado', '+12%', 'vs US avg', 'Above Avg', isHigh: true),
              _buildColCard('🎰', 'Nevada', '+3%', 'vs US avg', 'Near Avg', isHigh: null),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Money Saving Tips
        Text('MONEY-SAVING TIPS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTipCard('📅', 'Move Off-Peak Season', 'Oct–Apr saves 15–25% vs summer peak months', theme, context),
        _buildTipCard('📦', 'Self-Pack to Save \$400–900', 'Buy boxes from U-Haul, Home Depot, or free on Craigslist', theme, context),
        _buildTipCard('🏦', 'IRS Moving Deduction (Military)', 'Active duty military can deduct qualified moving expenses', theme, context),
        _buildTipCard('🔍', 'Get 3 Binding Quotes', 'FMCSA licensed movers only · verify at protectyourmove.gov', theme, context),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, String note, CountryTheme theme, BuildContext context, {bool isGold = false}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.playfair(size: 14, color: isGold ? const Color(0xFFD97706) : theme.getTextColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildTypeBtn(String type, String label) {
    final active = _moveType == type;
    final theme = widget.theme;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _moveType = type;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0B1D3A) : theme.getBgColor(context),
            border: Border.all(color: active ? const Color(0xFF0B1D3A) : theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10,
              color: active ? Colors.white : theme.getMutedColor(context),
              weight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String val, List<String> items, ValueChanged<String?> onChanged, {Map<String, String>? labels}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              isExpanded: true,
              dropdownColor: theme.getCardColor(context),
              style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
              onChanged: onChanged,
              items: items.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(labels?[opt] ?? opt),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroResult(String label, double value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
        const SizedBox(height: 4),
        Text(CurrencyFormatter.compact(value, symbol: r'$'), style: AppTextStyles.playfair(size: 13, color: color ?? Colors.white, weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBreakdownItem(String name, String sub, double val) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.dmSans(size: 11.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
              Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
            ],
          ),
          Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildColCard(String icon, String label, String value, String sub, String badge, {required bool? isHigh}) {
    final theme = widget.theme;
    final badgeColor = isHigh == null
        ? Colors.grey
        : isHigh
            ? const Color(0xFFB91C1C)
            : const Color(0xFF15803D);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          Text(value, style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.bold)),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
          const Spacer(),
          Text(badge, style: AppTextStyles.dmSans(size: 8, color: badgeColor, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTipCard(String icon, String title, String subtitle, CountryTheme theme, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

