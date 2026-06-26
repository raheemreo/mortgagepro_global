// lib/features/india/tools/in_ppf_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min, pow, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INPPFCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INPPFCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INPPFCalculator> createState() => _INPPFCalculatorState();
}

class _INPPFCalculatorState extends ConsumerState<INPPFCalculator> {
  // Input states
  bool _isMonthly = false;
  double _contribution = 150000;
  int _periodYears = 15;
  double _roi = 7.10;

  // Controllers
  late TextEditingController _contributionCtrl;
  late TextEditingController _periodCtrl;
  late TextEditingController _roiCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _rules = const [
    {
      'icon': '📅',
      'title': 'Loan facility from 3rd–6th year',
      'desc':
          'Borrow up to 25% of balance at 2% above PPF rate. Repay within 36 months.'
    },
    {
      'icon': '💸',
      'title': 'Partial withdrawal from 7th year',
      'desc':
          'Withdraw up to 50% of balance at end of 4th year. Only once per financial year.'
    },
    {
      'icon': '⏰',
      'title': 'Extension in 5-year blocks',
      'desc':
          'After 15 years, extend without contribution (just interest) or with fresh contributions.'
    },
    {
      'icon': '🏦',
      'title': 'Account transfer allowed',
      'desc':
          'Transfer between Post Offices and scheduled banks (SBI, HDFC, ICICI, etc.) anytime.'
    },
    {
      'icon': '👨‍👩‍👧',
      'title': 'Minor account allowed',
      'desc':
          'Open in minor\'s name — guardian manages. Counts towards guardian\'s 80C limit.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _contributionCtrl =
        TextEditingController(text: _contribution.toStringAsFixed(0));
    _periodCtrl = TextEditingController(text: _periodYears.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _contributionCtrl.dispose();
    _periodCtrl.dispose();
    _roiCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _isMonthly = false;
      _contribution = 150000;
      _periodYears = 15;
      _roi = 7.10;

      _contributionCtrl.text = '150000';
      _periodCtrl.text = '15';
      _roiCtrl.text = '7.10';
    });
  }

  void _toggleMode(bool monthly) {
    setState(() {
      _isMonthly = monthly;
      if (_isMonthly) {
        _contribution = (_contribution / 12).clamp(500, 12500);
      } else {
        _contribution = (_contribution * 12).clamp(500, 150000);
      }
      // Round contribution to nearest 100 for a clean display
      _contribution = (_contribution / 100).round() * 100.0;
      if (_isMonthly) {
        _contribution = _contribution.clamp(500, 12500);
      } else {
        _contribution = _contribution.clamp(500, 150000);
      }
      _contributionCtrl.text = _contribution.toStringAsFixed(0);
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

  void _saveCalculation(double corpus, double totalInv, double totalInt) async {
    final labelCtrl = TextEditingController(text: 'PPF Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save PPF Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Maturity ${_fmt(corpus)} · Mode: ${_isMonthly ? "Monthly" : "Yearly"}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My PPF Retirement)',
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
              backgroundColor: const Color(0xFF046A38),
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
          : 'PPF Calculator';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'PPF Calculator',
        inputs: {
          'yearlyInvestment': _isMonthly ? _contribution * 12 : _contribution,
          'period': _periodYears.toDouble(),
          'rate': _roi,
          'isMonthly': _isMonthly ? 1.0 : 0.0,
          'contribution': _contribution,
        },
        results: {
          'corpus': corpus,
          'totalInterest': totalInt,
          'totalInvested': totalInv,
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

    // Reactively run PPF Calculations
    final r = _roi / 100;
    double balance = 0;
    double totalInv = 0;
    final List<Map<String, dynamic>> yearData = [];

    if (_isMonthly) {
      for (int y = 1; y <= _periodYears; y++) {
        double yearInterest = 0;
        double yearInvested = 0;
        for (int m = 0; m < 12; m++) {
          balance += _contribution;
          yearInvested += _contribution;
          // Calculate interest monthly on the lowest balance of the month.
          // In practice, interest is credited at end of year, so we accumulate it.
          yearInterest += balance * (r / 12);
        }
        balance += yearInterest;
        totalInv += yearInvested;
        yearData.add({
          'y': y,
          'balance': balance,
          'invested': totalInv,
          'interest': balance - totalInv,
        });
      }
    } else {
      for (int y = 1; y <= _periodYears; y++) {
        balance = (balance + _contribution) * (1 + r);
        totalInv += _contribution;
        yearData.add({
          'y': y,
          'balance': balance,
          'invested': totalInv,
          'interest': balance - totalInv,
        });
      }
    }

    final corpus = balance;
    final totalInt = corpus - totalInv;
    final wealthGain = totalInv > 0 ? (corpus / totalInv) : 0.0;
    final cagr = totalInv > 0
        ? (pow(corpus / totalInv, 1.0 / _periodYears) - 1) * 100
        : 0.0;

    final yearlyEquivalent = _isMonthly ? _contribution * 12 : _contribution;
    final annualTaxSaved =
        min(yearlyEquivalent, 150000) * 0.30 * 1.04; // 30% slab + 4% cess
    final totalTaxSaved = annualTaxSaved * _periodYears;

    // Filter growth chart years: Year 1, every 5th year, and the last year
    final List<Map<String, dynamic>> chartYears = [];
    for (int i = 0; i < yearData.length; i++) {
      final y = i + 1;
      if (y == 1 || y % 5 == 0 || y == _periodYears) {
        chartYears.add(yearData[i]);
      }
    }

    // Remove duplicates if any
    final Set<int> added = {};
    final List<Map<String, dynamic>> uniqueChartYears = [];
    for (final d in chartYears) {
      if (!added.contains(d['y'])) {
        added.add(d['y']);
        uniqueChartYears.add(d);
      }
    }

    final maxChartVal = uniqueChartYears.isNotEmpty
        ? uniqueChartYears.map((d) => d['balance'] as double).reduce(max)
        : 1.0;

    // Retrieve saved calculations matching PPF
    final savedList = ref
        .watch(savedProvider)
        .where((c) => c.calcType == 'PPF Calculator')
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
              _headerRateItem('PPF Rate', '${_roi.toStringAsFixed(2)}%',
                  'Q1 FY26', context),
              _verticalDivider(),
              _headerRateItem('Lock-in', '15 yrs', 'Extendable', context),
              _verticalDivider(),
              _headerRateItem('Max/yr', '₹1.5L', 'Sec 80C', context,
                  isGreen: true),
              _verticalDivider(),
              _headerRateItem('Min/yr', '₹500', 'Active status', context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Investment Inputs Card
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
                  Text('INVESTMENT DETAILS',
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

              // Monthly vs Yearly Segment Switcher
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
                            color: !_isMonthly
                                ? const Color(0xFF046A38)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Yearly Mode',
                              style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: !_isMonthly
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
                            color: _isMonthly
                                ? const Color(0xFF046A38)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              'Monthly Mode',
                              style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: _isMonthly
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

              // Synced input-slider 1: Contribution Amount
              _buildSyncedInputRow(
                label:
                    _isMonthly ? 'MONTHLY CONTRIBUTION' : 'YEARLY CONTRIBUTION',
                controller: _contributionCtrl,
                value: _contribution,
                min: 500,
                max: _isMonthly ? 12500 : 150000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _contribution = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _contribution = val;
                    _contributionCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                _isMonthly
                    ? 'Maximum ₹12,500 per month (totaling ₹1.5 Lakhs annually).'
                    : 'Maximum ₹1.5 Lakh per year. Invest before the 5th of the month for monthly interest calculations.',
                style: AppTextStyles.dmSans(
                    size: 8.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 16),

              // Synced input-slider 2: Investment Period (Tenure)
              _buildSyncedInputRow(
                label: 'INVESTMENT PERIOD',
                controller: _periodCtrl,
                value: _periodYears.toDouble(),
                min: 15,
                max: 50,
                suffix: ' Years',
                onChangedText: (val) {
                  setState(() {
                    _periodYears = val.toInt();
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _periodYears = val.toInt();
                    _periodCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                '15 years base lock-in. Extendable in blocks of 5 years.',
                style: AppTextStyles.dmSans(
                    size: 8.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 16),

              // PPF Interest Rate Input (Editable only, no slider)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PPF INTEREST RATE (P.A.)',
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: theme.getMutedColor(context),
                              weight: FontWeight.w800)),
                      Text('${_roi.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(
                              size: 11.5,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                      border: Border.all(
                          color:
                              const Color(0xFFFF6B00).withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: TextFormField(
                      controller: _roiCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                        if (parsed != null && parsed > 0 && parsed <= 25) {
                          setState(() {
                            _roi = parsed;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Government-regulated rate: 7.10% p.a. (Revised quarterly).',
                    style: AppTextStyles.dmSans(
                        size: 8.5, color: theme.getMutedColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _scrollToResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text('🏛️ Calculate PPF Corpus',
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
                          _saveCalculation(corpus, totalInv, totalInt),
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

        // Maturity Summary Card (Green Gradient)
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF07543A), Color(0xFF046A38)],
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
              Text('PPF CORPUS AT MATURITY (TAX-FREE)',
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
                    color: const Color(0xFFDCFCE7),
                    weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _resultBox('Total Invested', _fmt(totalInv)),
                  _resultBox('Interest Earned', _fmt(totalInt), isYellow: true),
                  _resultBox(
                      'Wealth Gained', '${wealthGain.toStringAsFixed(2)}x',
                      isYellow: true),
                  _resultBox('CAGR (Effective)', '${cagr.toStringAsFixed(2)}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Visual Analysis Card
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
              Text('📊 Composition & Year-wise Growth',
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
                      painter: _DonutChartPainter(
                        invested: totalInv,
                        interest: totalInt,
                        investedColor: const Color(0xFF046A38),
                        interestColor: const Color(0xFFF5A623),
                        textColor: theme.getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFF046A38), 'Total Invested',
                            _fmt(totalInv)),
                        const SizedBox(height: 12),
                        _legendRow(const Color(0xFFF5A623), 'Wealth Gained',
                            _fmt(totalInt)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Growth Chart
              Text('PPF CORPUS ACCUMULATION (Y1 to Y$_periodYears)',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: uniqueChartYears.map((d) {
                    final balanceVal = d['balance'] as double;
                    final interestVal = d['interest'] as double;

                    final double totalH =
                        max(6.0, (balanceVal / maxChartVal) * 80.0);
                    final double intH =
                        max(2.0, (interestVal / balanceVal) * totalH);
                    final double prinH = max(0.0, totalH - intH);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 16,
                            height: totalH,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: intH,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5A623),
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                                Container(
                                  height: prinH,
                                  width: 16,
                                  color: const Color(0xFF046A38),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Y${d['y']}',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  color: theme.getMutedColor(context))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chartIndicatorDot(const Color(0xFF046A38), 'Principal'),
                  const SizedBox(width: 16),
                  _chartIndicatorDot(const Color(0xFFF5A623), 'Interest'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tax Benefit Banner (Orange Gradient)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            border: Border.all(color: const Color(0xFFFDBA74)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🧾 EEE Benefit — Zero Tax at All 3 Stages',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: const Color(0xFF9A3412))),
              const SizedBox(height: 10),
              _taxRow('Annual Section 80C Deduction',
                  _fmt(min(yearlyEquivalent, 150000))),
              _taxRow('Tax Saved Per Year (30% slab)', _fmt(annualTaxSaved)),
              _taxRow('Total Tax Saved Over Period', _fmt(totalTaxSaved)),
              _taxRow('Interest Earned at Maturity', '100% Tax-Free'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // PPF Rules Card
        Text('PPF Rules & Features',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: _rules
                .map((r) => _ruleRow(r['icon'], r['title'], r['desc']))
                .toList(),
          ),
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
              final sYears = s.inputs['period']?.toInt() ?? 15;
              final sRate = s.inputs['rate'] ?? 7.10;
              final sCorp = s.results['corpus'] ?? 0.0;
              final sInv = s.results['totalInvested'] ?? 0.0;
              final sInt = s.results['totalInterest'] ?? 0.0;
              final isSMonthly = s.inputs['isMonthly'] == 1.0;
              final contribution = s.inputs['contribution'] ??
                  s.inputs['yearlyInvestment'] ??
                  0.0;

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
                            '${isSMonthly ? "Monthly" : "Yearly"}: ${_fmtShort(contribution)} · Invested: ${_fmtShort(sInv)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                          Text(
                            'Interest: ${_fmtShort(sInt)}',
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
                              color: const Color(0xFF046A38)),
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

  Widget _resultBox(String label, String value, {bool isYellow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w800,
              color: isYellow ? const Color(0xFFFFDEA0) : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  Widget _taxRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF9A3412))),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: const Color(0xFFE05A00))),
        ],
      ),
    );
  }

  Widget _ruleRow(String icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: widget.theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: widget.theme.getMutedColor(context),
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double invested;
  final double interest;
  final Color investedColor;
  final Color interestColor;
  final Color textColor;

  _DonutChartPainter({
    required this.invested,
    required this.interest,
    required this.investedColor,
    required this.interestColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final total = invested + interest;
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
    final pInterest = interest / total;

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
    if (pInterest > 0) {
      final sweep = pInterest * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = interestColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // Center text
    final ratioLabel = '${(pInterest * 100).round()}%';
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
        text: 'interest',
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
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.invested != invested ||
        oldDelegate.interest != interest ||
        oldDelegate.textColor != textColor;
  }
}
