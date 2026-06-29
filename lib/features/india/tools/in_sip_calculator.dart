// lib/features/india/tools/in_sip_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show min, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INSIPCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INSIPCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INSIPCalculator> createState() => _INSIPCalculatorState();
}

class _INSIPCalculatorState extends ConsumerState<INSIPCalculator> {
  // Input states
  bool _isLumpsum = false;
  double _investmentAmount = 10000; // Monthly SIP or Lumpsum
  double _roi = 12.0;
  int _durYears = 15;
  double _stepUpPercent = 0.0; // 0, 5, 10, 15

  // Controllers
  late TextEditingController _investmentCtrl;
  late TextEditingController _roiCtrl;
  late TextEditingController _durCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _funds = const [
    {
      'icon': '📊',
      'name': 'Nippon India Small Cap',
      'cat': 'Small Cap · Direct Growth',
      'rate': 32.4
    },
    {
      'icon': '🏢',
      'name': 'Quant Mid Cap Fund',
      'cat': 'Mid Cap · Direct Growth',
      'rate': 28.7
    },
    {
      'icon': '🌟',
      'name': 'Mirae Asset Large & Mid',
      'cat': 'Large & Mid Cap',
      'rate': 19.1
    },
    {
      'icon': '🛡️',
      'name': 'HDFC Flexi Cap Fund',
      'cat': 'Flexi Cap · Direct',
      'rate': 16.8
    },
    {
      'icon': '⚡',
      'name': 'Parag Parikh Flexi Cap',
      'cat': 'Flexi Cap · Intl exposure',
      'rate': 18.3
    },
  ];

  @override
  void initState() {
    super.initState();
    _investmentCtrl =
        TextEditingController(text: _investmentAmount.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(1));
    _durCtrl = TextEditingController(text: _durYears.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _investmentCtrl.dispose();
    _roiCtrl.dispose();
    _durCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _isLumpsum = false;
      _investmentAmount = 10000;
      _roi = 12.0;
      _durYears = 15;
      _stepUpPercent = 0.0;

      _investmentCtrl.text = '10000';
      _roiCtrl.text = '12.0';
      _durCtrl.text = '15';
    });
  }

  void _toggleMode(bool lumpsum) {
    setState(() {
      _isLumpsum = lumpsum;
      if (_isLumpsum) {
        // Convert to typical lumpsum default
        _investmentAmount = 100000;
      } else {
        // Convert to typical SIP default
        _investmentAmount = 10000;
      }
      _investmentCtrl.text = _investmentAmount.toStringAsFixed(0);
    });
  }

  String _fmt(double n) {
    return '₹${Compat.round(n).toLocaleString()}';
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return Compat.round(n).toLocaleString();
  }

  Map<String, dynamic> _calculateSIP(
      double sip, double ratePA, int months, double step) {
    final mRate = ratePA / 100 / 12;
    double corpus = 0;
    double invested = 0;
    double curSip = sip;
    final List<Map<String, double>> points = [];

    if (_isLumpsum) {
      final double annualRate = ratePA / 100;
      corpus = sip;
      invested = sip;
      points.add({'m': 0, 'corpus': corpus, 'invested': invested});
      for (int y = 1; y <= _durYears; y++) {
        corpus = corpus * (1 + annualRate);
        points.add(
            {'m': y.toDouble() * 12, 'corpus': corpus, 'invested': invested});
      }
    } else {
      for (int m = 1; m <= months; m++) {
        if (m > 1 && (m - 1) % 12 == 0 && step > 0) {
          curSip *= (1 + step / 100);
        }
        corpus = (corpus + curSip) * (1 + mRate);
        invested += curSip;
        if (m % 12 == 0 || m == months) {
          points
              .add({'m': m.toDouble(), 'corpus': corpus, 'invested': invested});
        }
      }
    }

    return {
      'corpus': corpus,
      'invested': invested,
      'points': points,
    };
  }

  void _saveCalculation(double corpus, double invested, double returns) async {
    final labelCtrl = TextEditingController(text: 'SIP Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_sip_calculator/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save SIP Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Wealth ${_fmt(corpus)} · Mode: ${_isLumpsum ? "Lumpsum" : "SIP"}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Retirement Fund)',
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
              backgroundColor: const Color(0xFF9333EA),
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
      final label =
          labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'SIP Plan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'SIP Calculator',
        inputs: {
          'sipAmount': _investmentAmount,
          'rate': _roi,
          'duration': _durYears.toDouble(),
          'stepUp': _isLumpsum ? 0.0 : _stepUpPercent,
          'isLumpsum': _isLumpsum ? 1.0 : 0.0,
        },
        results: {
          'corpus': corpus,
          'totalInvested': invested,
          'totalReturns': returns,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final results =
        _calculateSIP(_investmentAmount, _roi, _durYears * 12, _stepUpPercent);
    final corpus = results['corpus'] as double;
    final invested = results['invested'] as double;
    final List<Map<String, double>> points =
        results['points'] as List<Map<String, double>>;
    final returns = corpus - invested;
    final wealthRatio = invested > 0 ? (corpus / invested) : 0.0;

    // Return Scenario Comparison (Same parameters, different CAGR rates)
    final scenario8 = _calculateSIP(
            _investmentAmount, 8, _durYears * 12, _stepUpPercent)['corpus']
        as double;
    final scenario12 = _calculateSIP(
            _investmentAmount, 12, _durYears * 12, _stepUpPercent)['corpus']
        as double;
    final scenario15 = _calculateSIP(
            _investmentAmount, 15, _durYears * 12, _stepUpPercent)['corpus']
        as double;
    final scenario18 = _calculateSIP(
            _investmentAmount, 18, _durYears * 12, _stepUpPercent)['corpus']
        as double;
    final maxScenarioVal = scenario18;

    // Retrieve saved calculations matching SIP
    final savedList = ref
        .watch(savedProvider)
        .where((c) => c.calcType == 'SIP Calculator')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              _headerRateItem('Nifty 50', '22,643', '1-yr +28%', context),
              _verticalDivider(),
              _headerRateItem('Avg Large', '14.2%', '5-yr CAGR', context,
                  isGreen: true),
              _verticalDivider(),
              _headerRateItem('Avg Mid', '18.6%', '5-yr CAGR', context,
                  isGreen: true),
              _verticalDivider(),
              _headerRateItem('Inflation', '5.1%', 'CPI 2024', context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SIP DETAILS',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFF6B00),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SIP vs Lumpsum Segment Switcher
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleMode(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isLumpsum
                                ? const Color(0xFF9333EA)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'SIP (Monthly)',
                              style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: !_isLumpsum
                                    ? Colors.white
                                    : theme.getTextColor(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleMode(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isLumpsum
                                ? const Color(0xFF9333EA)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Lumpsum (One-time)',
                              style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: _isLumpsum
                                    ? Colors.white
                                    : theme.getTextColor(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Synced input-slider 1: Investment Amount
              _buildSyncedInputRow(
                label: _isLumpsum ? 'LUMPSUM INVESTMENT' : 'MONTHLY SIP AMOUNT',
                controller: _investmentCtrl,
                value: _investmentAmount,
                min: 500,
                max: _isLumpsum ? 1000000 : 200000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _investmentAmount = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _investmentAmount = val;
                    _investmentCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 2: Expected Return Rate (ROI)
              _buildSyncedInputRow(
                label: 'EXPECTED ANNUAL RETURN (CAGR)',
                controller: _roiCtrl,
                value: _roi,
                min: 5.0,
                max: 30.0,
                suffix: '% p.a.',
                onChangedText: (val) {
                  setState(() {
                    _roi = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _roi = val;
                    _roiCtrl.text = val.toStringAsFixed(1);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 3: Investment Duration (Tenure)
              _buildSyncedInputRow(
                label: 'INVESTMENT DURATION',
                controller: _durCtrl,
                value: _durYears.toDouble(),
                min: 1,
                max: 40,
                suffix: ' Years',
                onChangedText: (val) {
                  setState(() {
                    _durYears = val.toInt();
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _durYears = val.toInt();
                    _durCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Step-Up option (SIP Mode only)
              if (!_isLumpsum) ...[
                Text('ANNUAL SIP STEP-UP (TOP-UP)',
                    style: AppTextStyles.dmSans(
                        size: 8.5,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [0.0, 5.0, 10.0, 15.0].map((step) {
                    final active = _stepUpPercent == step;
                    final label =
                        step == 0.0 ? 'None' : '${step.toStringAsFixed(0)}%';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _stepUpPercent = step),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFFF6B00)
                                : Colors.transparent,
                            border: Border.all(
                                color: active
                                    ? const Color(0xFFFF6B00)
                                    : theme.getBorderColor(context)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w800,
                              color: active
                                  ? Colors.white
                                  : theme.getMutedColor(context),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _scrollToResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text('📈 Calculate Returns',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () =>
                          _saveCalculation(corpus, invested, returns),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1F48),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.bookmark_border, size: 20),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Maturity Result Card (Purple Gradient)
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL WEALTH CREATED',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: Colors.white70,
                      weight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                _fmt(corpus),
                style: AppTextStyles.playfair(
                    size: 32,
                    color: const Color(0xFFF3E8FF),
                    weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _resultBox('Total Invested', _fmt(invested)),
                  const SizedBox(width: 8),
                  _resultBox('Returns Earned', _fmt(returns), isGreen: true),
                  const SizedBox(width: 8),
                  _resultBox(
                      'Wealth Ratio', '${wealthRatio.toStringAsFixed(2)}x'),
                  const SizedBox(width: 8),
                  _resultBox('XIRR (approx)', '${_roi.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Visual Composition Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🥧 Composition & Wealth Progression',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 16),

              // Donut Chart Row
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _SIPDonutPainter(
                        invested: invested,
                        returns: returns,
                        investedColor: const Color(0xFFFF6B00),
                        returnsColor: const Color(0xFF9333EA),
                        textColor: theme.getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFFFF6B00), 'Total Invested',
                            _fmt(invested)),
                        const SizedBox(height: 12),
                        _legendRow(const Color(0xFF9333EA), 'Returns Earned',
                            _fmt(returns)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Wealth Growth curve Area chart
              Text('WEALTH GROWTH TIMELINE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SIPAreaPainter(points: points),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chartIndicatorDot(const Color(0xFF9333EA), 'SIP Corpus'),
                  const SizedBox(width: 16),
                  _chartIndicatorDot(
                      const Color(0xFFFF6B00).withValues(alpha: 0.4),
                      'Amount Invested'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scenario Comparison
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Scenario Comparison',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 4),
              Text(
                'What ${_fmtShort(_investmentAmount)}${_isLumpsum ? " lumpsum" : "/mo SIP"} becomes in $_durYears years at different CAGR rates:',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 16),
              _scenarioRow('8% Debt Fund', scenario8, maxScenarioVal,
                  const Color(0xFF1A3A8F)),
              const SizedBox(height: 10),
              _scenarioRow('12% Moderate', scenario12, maxScenarioVal,
                  const Color(0xFF046A38)),
              const SizedBox(height: 10),
              _scenarioRow('15% Growth', scenario15, maxScenarioVal,
                  const Color(0xFFFF6B00)),
              const SizedBox(height: 10),
              _scenarioRow('18% Aggressive', scenario18, maxScenarioVal,
                  const Color(0xFF9333EA)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top Performing MFs
        Text('Top Performing Mutual Funds 2025',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: _funds.map((f) {
            final fRate = f['rate'] as double;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.getBorderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(f['icon'] as String,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['name'] as String,
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        Text(f['cat'] as String,
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${fRate.toStringAsFixed(1)}%',
                          style: AppTextStyles.dmSans(
                              size: 15,
                              weight: FontWeight.w800,
                              color: const Color(0xFF9333EA))),
                      Text('5-yr CAGR',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Saved Calculations Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Calculations',
                style: AppTextStyles.playfair(
                    size: 15, color: theme.getTextColor(context))),
            if (savedList.isNotEmpty)
              Text('(${savedList.length})',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        if (savedList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Center(
              child: Text(
                'No saved calculations yet.',
                style: AppTextStyles.dmSans(
                    size: 12, color: theme.getMutedColor(context)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedList.length,
            itemBuilder: (context, idx) {
              final s = savedList[idx];
              final sAmount = s.inputs['sipAmount'] ?? 0.0;
              final sYears = s.inputs['duration']?.toInt() ?? 15;
              final sRate = s.inputs['rate'] ?? 12.0;
              final sCorp = s.results['corpus'] ?? 0.0;
              final sInv = s.results['totalInvested'] ?? 0.0;
              final sRet = s.results['totalReturns'] ?? 0.0;
              final isSLump = s.inputs['isLumpsum'] == 1.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.label} · $sYears Yrs @ $sRate%',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isSLump ? "Lumpsum" : "SIP"}: ${_fmtShort(sAmount)} · Invested: ${_fmtShort(sInv)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                          Text(
                            'Returns: ${_fmtShort(sRet)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtShort(sCorp),
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFF9333EA)),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                          onPressed: () =>
                              ref.read(savedProvider.notifier).delete(s.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _headerRateItem(
      String label, String value, String note, BuildContext context,
      {bool isGreen = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme.getMutedColor(context),
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: isGreen
                  ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF046A38))
                  : const Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(height: 1),
          Text(note,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme
                      .getMutedColor(context)
                      .withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withValues(alpha: 0.25),
    );
  }

  Widget _buildSyncedInputRow({
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
    String prefix = '',
    String suffix = '',
    required ValueChanged<double> onChangedText,
    required ValueChanged<double> onChangedSlider,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w800)),
            Text('$prefix${_fmtShort(value)}$suffix',
                style: AppTextStyles.dmSans(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
            border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 13,
                color: theme.getTextColor(context),
                weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed >= min && parsed <= max) {
                onChangedText(parsed);
              }
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF6B00),
            inactiveTrackColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.24),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChangedSlider,
          ),
        ),
      ],
    );
  }

  Widget _resultBox(String label, String value, {bool isGreen = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(size: 8, color: Colors.white60),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 11.5,
                weight: FontWeight.w800,
                color: isGreen ? const Color(0xFF86EFAC) : Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scenarioRow(String label, double val, double maxVal, Color color) {
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.05, 1.0) : 0.05;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: widget.theme.getTextColor(context))),
            Text(_fmt(val),
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: widget.theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: widget.theme.getTextColor(context))),
              Text(value,
                  style: AppTextStyles.dmSans(
                      size: 9, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartIndicatorDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9.5,
                color: widget.theme.getMutedColor(context),
                weight: FontWeight.w600)),
      ],
    );
  }
}

class _SIPDonutPainter extends CustomPainter {
  final double invested;
  final double returns;
  final Color investedColor;
  final Color returnsColor;
  final Color textColor;

  _SIPDonutPainter({
    required this.invested,
    required this.returns,
    required this.investedColor,
    required this.returnsColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final total = invested + returns;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      return;
    }

    final pInvested = invested / total;
    final pReturns = returns / total;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    if (pInvested > 0) {
      final sweep = pInvested * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = investedColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (pReturns > 0) {
      final sweep = pReturns * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = returnsColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // Center text
    final ratioLabel = '${(pReturns * 100).round()}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: ratioLabel,
        style: TextStyle(
            fontFamily: 'Book Antiqua',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2 + 5));

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'growth',
        style: TextStyle(
            fontFamily: 'Trebuchet MS',
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas,
        center - Offset(subPainter.width / 2, subPainter.height / 2 - 10));
  }

  @override
  bool shouldRepaint(covariant _SIPDonutPainter oldDelegate) {
    return oldDelegate.invested != invested ||
        oldDelegate.returns != returns ||
        oldDelegate.textColor != textColor;
  }
}

class _SIPAreaPainter extends CustomPainter {
  final List<Map<String, double>> points;

  const _SIPAreaPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintCorpus = Paint()
      ..color = const Color(0xFF9333EA)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintInvested = Paint()
      ..color = const Color(0xFFFF6B00).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillCorpus = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9333EA).withValues(alpha: 0.35),
          const Color(0xFF9333EA).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final fillInvested = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF6B00).withValues(alpha: 0.20),
          const Color(0xFFFF6B00).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    const pad = 10.0;
    final maxV = points.last['corpus']!;
    final stepX = (size.width - pad * 2) / (points.length - 1);

    final pathCorpus = Path();
    final pathInvested = Path();

    for (int i = 0; i < points.length; i++) {
      final x = pad + i * stepX;
      final yCorpus = size.height -
          pad -
          (points[i]['corpus']! / maxV) * (size.height - pad * 2);
      final yInvested = size.height -
          pad -
          (points[i]['invested']! / maxV) * (size.height - pad * 2);

      if (i == 0) {
        pathCorpus.moveTo(x, yCorpus);
        pathInvested.moveTo(x, yInvested);
      } else {
        pathCorpus.lineTo(x, yCorpus);
        pathInvested.lineTo(x, yInvested);
      }
    }

    final fillCorpusPath = Path.from(pathCorpus)
      ..lineTo(pad + (points.length - 1) * stepX, size.height - pad)
      ..lineTo(pad, size.height - pad)
      ..close();

    final fillInvestedPath = Path.from(pathInvested)
      ..lineTo(pad + (points.length - 1) * stepX, size.height - pad)
      ..lineTo(pad, size.height - pad)
      ..close();

    canvas.drawPath(fillInvestedPath, fillInvested);
    canvas.drawPath(fillCorpusPath, fillCorpus);
    canvas.drawPath(pathInvested, paintInvested);
    canvas.drawPath(pathCorpus, paintCorpus);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
