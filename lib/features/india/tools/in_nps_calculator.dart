// lib/features/india/tools/in_nps_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INNPSCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INNPSCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INNPSCalculator> createState() => _INNPSCalculatorState();
}

class _INNPSCalculatorState extends ConsumerState<INNPSCalculator> {
  // Input states
  double _age = 30;
  double _monthly = 5000;
  double _employer = 0;
  double _roi = 10.0;
  double _annuityPurchasePercent = 40.0; // min 40%, max 100%
  double _annuityRate = 6.0;

  // Controllers
  late TextEditingController _ageCtrl;
  late TextEditingController _monthlyCtrl;
  late TextEditingController _employerCtrl;
  late TextEditingController _annuityPurchaseCtrl;
  late TextEditingController _roiCtrl;
  late TextEditingController _annuityRateCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ageCtrl = TextEditingController(text: _age.toStringAsFixed(0));
    _monthlyCtrl = TextEditingController(text: _monthly.toStringAsFixed(0));
    _employerCtrl = TextEditingController(text: _employer.toStringAsFixed(0));
    _annuityPurchaseCtrl =
        TextEditingController(text: _annuityPurchasePercent.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(1));
    _annuityRateCtrl =
        TextEditingController(text: _annuityRate.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _monthlyCtrl.dispose();
    _employerCtrl.dispose();
    _annuityPurchaseCtrl.dispose();
    _roiCtrl.dispose();
    _annuityRateCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _age = 30;
      _monthly = 5000;
      _employer = 0;
      _roi = 10.0;
      _annuityPurchasePercent = 40.0;
      _annuityRate = 6.0;

      _ageCtrl.text = '30';
      _monthlyCtrl.text = '5000';
      _employerCtrl.text = '0';
      _annuityPurchaseCtrl.text = '40';
      _roiCtrl.text = '10.0';
      _annuityRateCtrl.text = '6.0';
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

  double getEquityPct(double a) {
    return max(10.0, min(75.0, 75.0 - (a - 25.0) * 1.5));
  }

  double getCorpPct(double a) {
    return min(10.0, max(5.0, 10.0 - (a - 25.0) * 0.2));
  }

  void _saveCalculation(double corpus, double lump, double monthlyPension,
      double invested) async {
    final labelCtrl = TextEditingController(text: 'NPS Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_nps_calculator'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save NPS Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Corpus ${_fmt(corpus)} · Pension ${_fmt(monthlyPension)}/mo',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My NPS Pension)',
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
              backgroundColor: const Color(0xFF0D9488),
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
          : 'NPS Calculator';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'NPS Calculator',
        inputs: {
          'age': _age,
          'monthly': _monthly,
          'employer': _employer,
          'roi': _roi,
          'annuityPurchase': _annuityPurchasePercent,
          'annuityRate': _annuityRate,
        },
        results: {
          'corpus': corpus,
          'lumpSum': lump,
          'monthlyPension': monthlyPension,
          'totalInvested': invested,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ NPS calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF0D9488),
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

    final yrs = max(1, 60 - _age.toInt());
    final mRate = _roi / 100 / 12;
    final totalContribution = _monthly + _employer;

    double corpus = 0;
    double invested = 0;
    final List<Map<String, double>> pts = [];
    for (int m = 1; m <= yrs * 12; m++) {
      corpus = (corpus + totalContribution) * (1 + mRate);
      invested += totalContribution;
      if (m % 12 == 0 || m == yrs * 12) {
        pts.add({'y': (m / 12), 'corpus': corpus, 'invested': invested});
      }
    }

    final annuityRatio = _annuityPurchasePercent / 100.0;
    final lumpRatio = 1.0 - annuityRatio;

    final lump = corpus * lumpRatio;
    final annuity = corpus * annuityRatio;
    final monthlyPension = annuity * (_annuityRate / 100) / 12;
    final taxSaved = min(yrs * 12 * _monthly, 200000.0 * yrs) * 0.30;

    // Retrieve saved calculations matching NPS
    final savedList = ref
        .watch(savedProvider)
        .where((c) => c.calcType == 'NPS Calculator')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              _headerRateItem('Tier I', 'Tax-Free', 'EEE Status', context),
              _verticalDivider(),
              _headerRateItem('80C+80CCD', '₹2L Dedn', 'Max Limit', context,
                  isGreen: true),
              _verticalDivider(),
              _headerRateItem('Equity Cap', '75%', 'Age <50', context),
              _verticalDivider(),
              _headerRateItem('Annuity', '40%', 'At Retire', context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // NPS Inputs Card
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
                  Text('NPS DETAILS',
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

              // Synced input-slider 1: Current Age
              _buildSyncedInputRow(
                label: 'CURRENT AGE',
                controller: _ageCtrl,
                value: _age,
                min: 18,
                max: 65,
                suffix: ' Years',
                onChangedText: (val) {
                  setState(() {
                    _age = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _age = val;
                    _ageCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 2: Monthly Contribution
              _buildSyncedInputRow(
                label: 'MONTHLY CONTRIBUTION',
                controller: _monthlyCtrl,
                value: _monthly,
                min: 500,
                max: 100000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _monthly = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _monthly = val;
                    _monthlyCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Input 3: Employer Contribution
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMPLOYER CONTRIBUTION (PER MONTH)',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800)),
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
                      controller: _employerCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w800),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        prefixText: '₹ ',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null && parsed >= 0) {
                          setState(() {
                            _employer = parsed;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider 4: Annuity Purchase %
              _buildSyncedInputRow(
                label: 'ANNUITY PURCHASE PERCENTAGE (%)',
                controller: _annuityPurchaseCtrl,
                value: _annuityPurchasePercent,
                min: 40,
                max: 100,
                suffix: '% of Corpus',
                onChangedText: (val) {
                  setState(() {
                    _annuityPurchasePercent = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _annuityPurchasePercent = val;
                    _annuityPurchaseCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Minimum 40% of the corpus must be used to purchase annuity at retirement.',
                style: AppTextStyles.dmSans(
                    size: 8.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 16),

              // Synced input-slider 5: Expected Return Rate (ROI)
              _buildSyncedInputRow(
                label: 'EXPECTED ANNUAL RETURN (ROI)',
                controller: _roiCtrl,
                value: _roi,
                min: 5.0,
                max: 15.0,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  _presetButton(8, '8% Safe', _roi == 8),
                  const SizedBox(width: 8),
                  _presetButton(10, '10% Bal', _roi == 10),
                  const SizedBox(width: 8),
                  _presetButton(12, '12% Aggr', _roi == 12),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider 6: Expected Annuity Rate
              _buildSyncedInputRow(
                label: 'ANNUITY RATE AT RETIREMENT',
                controller: _annuityRateCtrl,
                value: _annuityRate,
                min: 4.0,
                max: 10.0,
                suffix: '% p.a.',
                onChangedText: (val) {
                  setState(() {
                    _annuityRate = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _annuityRate = val;
                    _annuityRateCtrl.text = val.toStringAsFixed(1);
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _presetAnnuityButton(5, '5% Annuity', _annuityRate == 5),
                  const SizedBox(width: 8),
                  _presetAnnuityButton(6, '6% Annuity', _annuityRate == 6),
                  const SizedBox(width: 8),
                  _presetAnnuityButton(7, '7% Annuity', _annuityRate == 7),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _scrollToResults();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text('🏦 Calculate NPS Corpus',
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
                      onPressed: () => _saveCalculation(
                          corpus, lump, monthlyPension, invested),
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

        // Result Card (Teal/Navy Gradient)
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF0D9488)],
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
              Text('TOTAL NPS CORPUS AT AGE 60',
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
                    color: const Color(0xFFFFDEA0),
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
                  _resultBox(
                      'Lump Sum (${(lumpRatio * 100).toStringAsFixed(0)}%)',
                      _fmt(lump),
                      isYellow: true),
                  _resultBox('Monthly Pension', '${_fmt(monthlyPension)}/mo',
                      isGreen: true),
                  _resultBox('Total Invested', _fmt(invested)),
                  _resultBox('Tax Saved (Est.)', _fmt(taxSaved)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pension Breakout Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text('Tax-Free Lump Sum',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: const Color(0xFF0B1F48))),
                    const SizedBox(height: 4),
                    Text(_fmt(lump),
                        style: AppTextStyles.dmSans(
                            size: 15,
                            weight: FontWeight.w800,
                            color: const Color(0xFF0D9488))),
                    const SizedBox(height: 2),
                    Text(
                        '${(lumpRatio * 100).toStringAsFixed(0)}% of corpus · Exempt',
                        style: AppTextStyles.dmSans(
                            size: 8.5, color: theme.getMutedColor(context))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text('Monthly Pension',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: const Color(0xFF0B1F48))),
                    const SizedBox(height: 4),
                    Text('${_fmt(monthlyPension)}/mo',
                        style: AppTextStyles.dmSans(
                            size: 15,
                            weight: FontWeight.w800,
                            color: const Color(0xFF1E40AF))),
                    const SizedBox(height: 2),
                    Text(
                        '${_annuityPurchasePercent.toStringAsFixed(0)}% annuity · Taxable',
                        style: AppTextStyles.dmSans(
                            size: 8.5, color: theme.getMutedColor(context))),
                  ],
                ),
              ),
            ),
          ],
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
              Text('🥧 Payout Proportions & Accumulation',
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
                      painter: _NPSDonutPainter(
                        lumpSum: lump,
                        annuity: annuity,
                        lumpColor: const Color(0xFF0D9488),
                        annuityColor: const Color(0xFFFF6B00),
                        textColor: theme.getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFF0D9488), 'Tax-Free Lump Sum',
                            _fmt(lump)),
                        const SizedBox(height: 12),
                        _legendRow(const Color(0xFFFF6B00), 'Annuity Purchase',
                            _fmt(annuity)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Growth Chart
              Text('NPS CORPUS BUILD-UP TIMELINE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(
                  painter: _NPSAreaPainter(points: pts),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chartIndicatorDot(const Color(0xFF0D9488), 'Total Corpus'),
                  const SizedBox(width: 16),
                  _chartIndicatorDot(
                      const Color(0xFFFF6B00).withValues(alpha: 0.4),
                      'Total Invested'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Auto Choice Allocation List
        Text('Auto Choice Asset Allocation (LC-75)',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 4),
        Text('Equity-Debt Mix by Age (Your Age: ${_age.toInt()})',
            style: AppTextStyles.dmSans(
                size: 10, color: theme.getMutedColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [25, 30, 35, 40, 45, 50, 55, 60].map((a) {
              final eq = getEquityPct(a.toDouble());
              final co = getCorpPct(a.toDouble());
              final go = 100.0 - eq - co;
              final isCurrent = (a - _age.toInt()).abs() < 5;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Opacity(
                  opacity: isCurrent ? 1.0 : 0.55,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 55,
                        child: Text(
                          'Age $a',
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight:
                                isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: theme.getTextColor(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: eq.toInt(),
                                  child:
                                      Container(color: const Color(0xFFFF6B00)),
                                ),
                                Expanded(
                                  flex: co.toInt(),
                                  child:
                                      Container(color: const Color(0xFF1A3A8F)),
                                ),
                                Expanded(
                                  flex: go.toInt(),
                                  child:
                                      Container(color: const Color(0xFF046A38)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${eq.toStringAsFixed(0)}% E',
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight:
                                isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: theme.getTextColor(context),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(const Color(0xFFFF6B00), 'Equity'),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFF1A3A8F), 'Corp Debt'),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFF046A38), 'Govt Securities'),
          ],
        ),
        const SizedBox(height: 16),

        // Tax deduction card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: Border.all(color: const Color(0xFFFCD34D)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💛 NPS Tax Deduction Summary (FY 2025-26)',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: const Color(0xFF92400E))),
              const SizedBox(height: 10),
              _taxRow('Section 80C (Employee Contrib)', 'Up to ₹1.5L/yr'),
              _taxRow('Section 80CCD(1B) Extra NPS', 'Additional ₹50,000/yr'),
              _taxRow('Section 80CCD(2) Employer', 'Up to 14% of Basic'),
              _taxRow('Total Max Deduction Limit', '₹2,00,000 + employer'),
              _taxRow('Lump Sum at 60 (60%)', '100% Tax-Free'),
              _taxRow('Annuity Income (40%)', 'Taxable as per slab'),
              _taxRow('Available in New Regime?', '80CCD(2) only (Employer)'),
            ],
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
              final sMonthly = s.inputs['monthly'] ?? 0.0;
              final sAge = s.inputs['age']?.toInt() ?? 30;
              final sRate = s.inputs['roi'] ?? 10.0;
              final sCorp = s.results['corpus'] ?? 0.0;
              final sLump = s.results['lumpSum'] ?? 0.0;
              final sPension = s.results['monthlyPension'] ?? 0.0;

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
                            '${s.label} · Age $sAge @ $sRate%',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Contrib: ${_fmtShort(sMonthly)}/mo · Lump Sum: ${_fmtShort(sLump)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                          Text(
                            'Pension: ${_fmtShort(sPension)}/mo',
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
                              color: const Color(0xFF0D9488)),
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
            activeTrackColor: const Color(0xFF0D9488),
            inactiveTrackColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFF0D9488).withValues(alpha: 0.24),
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

  Widget _resultBox(String label, String value,
      {bool isYellow = false, bool isGreen = false}) {
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
                color: isYellow
                    ? const Color(0xFFFFDEA0)
                    : isGreen
                        ? const Color(0xFF86EFAC)
                        : Colors.white,
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
                  color: const Color(0xFF92400E))),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: const Color(0xFF78350F))),
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

  Widget _presetButton(double rate, String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _roi = rate;
            _roiCtrl.text = rate.toStringAsFixed(1);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0D9488)
                : widget.theme.getBgColor(context),
            border: Border.all(
                color: active
                    ? const Color(0xFF0D9488)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetAnnuityButton(double rate, String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _annuityRate = rate;
            _annuityRateCtrl.text = rate.toStringAsFixed(1);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0D9488)
                : widget.theme.getBgColor(context),
            border: Border.all(
                color: active
                    ? const Color(0xFF0D9488)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9.5,
                color: widget.theme.getMutedColor(context),
                weight: FontWeight.w600)),
      ],
    );
  }
}

class _NPSDonutPainter extends CustomPainter {
  final double lumpSum;
  final double annuity;
  final Color lumpColor;
  final Color annuityColor;
  final Color textColor;

  _NPSDonutPainter({
    required this.lumpSum,
    required this.annuity,
    required this.lumpColor,
    required this.annuityColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final total = lumpSum + annuity;
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

    final pLump = lumpSum / total;
    final pAnnuity = annuity / total;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    if (pLump > 0) {
      final sweep = pLump * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = lumpColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (pAnnuity > 0) {
      final sweep = pAnnuity * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = annuityColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // Center text
    final ratioLabel = '${(pAnnuity * 100).round()}%';
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
        text: 'annuity',
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
  bool shouldRepaint(covariant _NPSDonutPainter oldDelegate) {
    return oldDelegate.lumpSum != lumpSum ||
        oldDelegate.annuity != annuity ||
        oldDelegate.textColor != textColor;
  }
}

class _NPSAreaPainter extends CustomPainter {
  final List<Map<String, double>> points;

  const _NPSAreaPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintCorpus = Paint()
      ..color = const Color(0xFF0D9488)
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
          const Color(0xFF0D9488).withValues(alpha: 0.35),
          const Color(0xFF0D9488).withValues(alpha: 0.0),
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
