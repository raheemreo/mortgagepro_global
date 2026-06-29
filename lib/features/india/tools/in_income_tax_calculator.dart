// lib/features/india/tools/in_income_tax_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INIncomeTaxCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INIncomeTaxCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INIncomeTaxCalculator> createState() =>
      _INIncomeTaxCalculatorState();
}

class _INIncomeTaxCalculatorState extends ConsumerState<INIncomeTaxCalculator> {
  // Inputs
  String _regime = 'new'; // 'new' or 'old'
  double _gross = 1200000;
  double _otherIncome = 0;
  double _d80c = 150000;
  double _d80d = 25000;
  double _hli = 0;
  double _hra = 0;
  double _nps = 50000;

  // Controllers
  late TextEditingController _grossCtrl;
  late TextEditingController _otherCtrl;
  late TextEditingController _d80cCtrl;
  late TextEditingController _d80dCtrl;
  late TextEditingController _hliCtrl;
  late TextEditingController _hraCtrl;
  late TextEditingController _npsCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _grossCtrl = TextEditingController(text: _gross.toStringAsFixed(0));
    _otherCtrl = TextEditingController(text: _otherIncome.toStringAsFixed(0));
    _d80cCtrl = TextEditingController(text: _d80c.toStringAsFixed(0));
    _d80dCtrl = TextEditingController(text: _d80d.toStringAsFixed(0));
    _hliCtrl = TextEditingController(text: _hli.toStringAsFixed(0));
    _hraCtrl = TextEditingController(text: _hra.toStringAsFixed(0));
    _npsCtrl = TextEditingController(text: _nps.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _grossCtrl.dispose();
    _otherCtrl.dispose();
    _d80cCtrl.dispose();
    _d80dCtrl.dispose();
    _hliCtrl.dispose();
    _hraCtrl.dispose();
    _npsCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _regime = 'new';
      _gross = 1200000;
      _otherIncome = 0;
      _d80c = 150000;
      _d80d = 25000;
      _hli = 0;
      _hra = 0;
      _nps = 50000;

      _grossCtrl.text = '1200000';
      _otherCtrl.text = '0';
      _d80cCtrl.text = '150000';
      _d80dCtrl.text = '25000';
      _hliCtrl.text = '0';
      _hraCtrl.text = '0';
      _npsCtrl.text = '50000';
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

  Map<String, dynamic> _calcNewTax(double inc) {
    final List<Map<String, dynamic>> slabs = [
      {'lo': 0.0, 'hi': 300000.0, 'r': 0},
      {'lo': 300000.0, 'hi': 700000.0, 'r': 5},
      {'lo': 700000.0, 'hi': 1000000.0, 'r': 10},
      {'lo': 1000000.0, 'hi': 1200000.0, 'r': 15},
      {'lo': 1200000.0, 'hi': 1500000.0, 'r': 20},
      {'lo': 1500000.0, 'hi': double.infinity, 'r': 30}
    ];

    double tax = 0;
    List<Map<String, dynamic>> details = [];
    for (final s in slabs) {
      if (inc <= s['lo']) break;
      final double sHi = s['hi'];
      final taxable = min(inc, sHi) - s['lo'];
      final t = taxable * s['r'] / 100.0;
      tax += t;
      if (taxable > 0) {
        details.add({
          'range':
              '${_fmtShort(s['lo'])} – ${sHi == double.infinity ? 'Above' : _fmtShort(sHi)}',
          'rate': '${s['r']}%',
          'taxable': taxable,
          'tax': t
        });
      }
    }

    if (inc <= 700000.0) {
      tax = 0;
    }
    return {'tax': tax, 'details': details};
  }

  Map<String, dynamic> _calcOldTax(double inc) {
    final List<Map<String, dynamic>> slabs = [
      {'lo': 0.0, 'hi': 250000.0, 'r': 0},
      {'lo': 250000.0, 'hi': 500000.0, 'r': 5},
      {'lo': 500000.0, 'hi': 1000000.0, 'r': 20},
      {'lo': 1000000.0, 'hi': double.infinity, 'r': 30}
    ];

    double tax = 0;
    List<Map<String, dynamic>> details = [];
    for (final s in slabs) {
      if (inc <= s['lo']) break;
      final double sHi = s['hi'];
      final taxable = min(inc, sHi) - s['lo'];
      final t = taxable * s['r'] / 100.0;
      tax += t;
      if (taxable > 0) {
        details.add({
          'range':
              '${_fmtShort(s['lo'])} – ${sHi == double.infinity ? 'Above' : _fmtShort(sHi)}',
          'rate': '${s['r']}%',
          'taxable': taxable,
          'tax': t
        });
      }
    }

    if (inc <= 500000.0) {
      tax = 0;
    }
    return {'tax': tax, 'details': details};
  }

  double _addSurcharge(double tax, double inc) {
    if (inc > 50000000) return tax + (tax * 0.37);
    if (inc > 20000000) return tax + (tax * 0.25);
    if (inc > 10000000) return tax + (tax * 0.15);
    if (inc > 5000000) return tax + (tax * 0.10);
    return tax;
  }

  double _addCess(double tax) {
    return tax + (tax > 0 ? tax * 0.04 : 0);
  }

  void _saveCalculation(double usedTax, double usedTaxable) async {
    final labelCtrl = TextEditingController(text: 'Income Tax');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_income_tax_calculator'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Tax Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Tax ${_fmt(usedTax)} · Regime ${_regime.toUpperCase()}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Tax FY26)',
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
              backgroundColor: const Color(0xFFFF6B00),
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
          : 'Income Tax';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Income Tax Calculator',
        inputs: {
          'gross': _gross,
          'otherIncome': _otherIncome,
          'regime': _regime == 'new' ? 1.0 : 0.0,
          'd80c': _d80c,
          'd80d': _d80d,
          'hli': _hli,
          'hra': _hra,
          'nps': _nps,
        },
        results: {
          'taxPayable': usedTax,
          'taxableIncome': usedTaxable,
          'effectiveRate':
              _gross > 0 ? usedTax / (_gross + _otherIncome) * 100 : 0.0,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tax calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFFFF6B00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _computeResults() {
    final d80cLimit = min(_d80c, 150000.0);
    final d80dLimit = min(_d80d, 25000.0);
    final hliLimit = min(_hli, 200000.0);
    final npsLimit = min(_nps, 50000.0);

    const stdNew = 75000.0;
    const stdOld = 50000.0;

    final totalIncome = _gross + _otherIncome;

    final taxableNew = max(0.0, totalIncome - stdNew);
    final taxableOld = max(
        0.0,
        totalIncome -
            stdOld -
            d80cLimit -
            d80dLimit -
            hliLimit -
            _hra -
            npsLimit);

    final resNew = _calcNewTax(taxableNew);
    final resOld = _calcOldTax(taxableOld);

    final double rawNew = resNew['tax'];
    final double rawOld = resOld['tax'];

    final taxNew = _addCess(_addSurcharge(rawNew, taxableNew));
    final taxOld = _addCess(_addSurcharge(rawOld, taxableOld));

    final usedTax = _regime == 'new' ? taxNew : taxOld;
    final usedTaxable = _regime == 'new' ? taxableNew : taxableOld;
    final effRate = totalIncome > 0 ? usedTax / totalIncome * 100 : 0.0;

    final deductions = _regime == 'old'
        ? stdOld + d80cLimit + d80dLimit + hliLimit + _hra + npsLimit
        : stdNew;

    return {
      'taxableNew': taxableNew,
      'taxableOld': taxableOld,
      'taxNew': taxNew,
      'taxOld': taxOld,
      'usedTax': usedTax,
      'usedTaxable': usedTaxable,
      'effRate': effRate,
      'deductions': deductions,
      'rawTax': _regime == 'new' ? rawNew : rawOld,
      'cess': (_regime == 'new' ? rawNew : rawOld) * 0.04,
      'details': _regime == 'new' ? resNew['details'] : resOld['details'],
    };
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

    final results = _computeResults();
    final usedTax = results['usedTax'] as double;
    final usedTaxable = results['usedTaxable'] as double;
    final effRate = results['effRate'] as double;
    final deductions = results['deductions'] as double;
    final rawTax = results['rawTax'] as double;
    final cess = results['cess'] as double;
    final details = results['details'] as List<dynamic>;

    final taxNew = results['taxNew'] as double;
    final taxOld = results['taxOld'] as double;
    final taxableNew = results['taxableNew'] as double;
    final taxableOld = results['taxableOld'] as double;

    // Slabs breakdown for display
    final List<Map<String, dynamic>> newSlabs = [
      {'r': '0%', 'hi': '₹3L', 'pct': 0.0},
      {'r': '5%', 'hi': '₹3L–7L', 'pct': 16.7},
      {'r': '10%', 'hi': '₹7L–10L', 'pct': 33.3},
      {'r': '15%', 'hi': '₹10L–12L', 'pct': 50.0},
      {'r': '20%', 'hi': '₹12L–15L', 'pct': 66.7},
      {'r': '30%', 'hi': 'Above ₹15L', 'pct': 100.0}
    ];

    final List<Map<String, dynamic>> oldSlabs = [
      {'r': '0%', 'hi': 'Up to ₹2.5L', 'pct': 0.0},
      {'r': '5%', 'hi': '₹2.5L–5L', 'pct': 33.3},
      {'r': '20%', 'hi': '₹5L–10L', 'pct': 66.7},
      {'r': '30%', 'hi': 'Above ₹10L', 'pct': 100.0}
    ];

    final activeSlabs = _regime == 'new' ? newSlabs : oldSlabs;
    final List<Color> slabColors = [
      const Color(0xFF86EFAC),
      const Color(0xFFFCD34D),
      const Color(0xFFFDBA74),
      const Color(0xFFFB923C),
      const Color(0xFFF97316),
      const Color(0xFFDC2626)
    ];

    // Retrieve saved calculations matching Income Tax
    final savedList = ref
        .watch(savedProvider)
        .where((c) => c.calcType == 'Income Tax Calculator')
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
              _headerRateItem('Basic Exempt', '₹3L', 'New Regime', context),
              _verticalDivider(),
              _headerRateItem('Rebate 87A', '₹7L', 'New Regime', context,
                  isGreen: true),
              _verticalDivider(),
              _headerRateItem('Std Deduct', '₹75K', 'Salaried', context),
              _verticalDivider(),
              _headerRateItem('Surcharge', '10%', '>₹50L', context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Regime Selector Toggle
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _regime = 'new'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _regime == 'new'
                          ? const Color(0xFFFF6B00)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '🆕 New Regime',
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: _regime == 'new'
                            ? Colors.white
                            : theme.getMutedColor(context),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _regime = 'old'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _regime == 'old'
                          ? const Color(0xFFFF6B00)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '📋 Old Regime',
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: _regime == 'old'
                            ? Colors.white
                            : theme.getMutedColor(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Income Inputs Card
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
                  Text('INCOME & DEDUCTIONS',
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

              // Synced input-slider 1: Gross Annual Income
              _buildSyncedInputRow(
                label: 'SALARY / BUSINESS INCOME (ANNUAL)',
                controller: _grossCtrl,
                value: _gross,
                min: 0,
                max: 5000000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _gross = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _gross = val;
                    _grossCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 2: Other Income
              _buildSyncedInputRow(
                label: 'OTHER INCOME (INTEREST, CAPITAL GAINS ETC)',
                controller: _otherCtrl,
                value: _otherIncome,
                min: 0,
                max: 1000000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _otherIncome = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _otherIncome = val;
                    _otherCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),

              // Deductions for Old Regime
              if (_regime == 'old') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // 80C
                _buildSyncedInputRow(
                  label: '80C INVESTMENTS (ELSS, PF, LIC ETC)',
                  controller: _d80cCtrl,
                  value: _d80c,
                  min: 0,
                  max: 150000,
                  prefix: '₹ ',
                  onChangedText: (val) {
                    setState(() {
                      _d80c = val;
                    });
                  },
                  onChangedSlider: (val) {
                    setState(() {
                      _d80c = val;
                      _d80cCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 80D
                _buildSyncedInputRow(
                  label: '80D HEALTH INSURANCE PREMIUM',
                  controller: _d80dCtrl,
                  value: _d80d,
                  min: 0,
                  max: 25000,
                  prefix: '₹ ',
                  onChangedText: (val) {
                    setState(() {
                      _d80d = val;
                    });
                  },
                  onChangedSlider: (val) {
                    setState(() {
                      _d80d = val;
                      _d80dCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Home Loan Interest
                _buildSyncedInputRow(
                  label: 'HOME LOAN INTEREST (SEC 24B)',
                  controller: _hliCtrl,
                  value: _hli,
                  min: 0,
                  max: 200000,
                  prefix: '₹ ',
                  onChangedText: (val) {
                    setState(() {
                      _hli = val;
                    });
                  },
                  onChangedSlider: (val) {
                    setState(() {
                      _hli = val;
                      _hliCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 12),

                // HRA Exemption
                _buildSyncedInputRow(
                  label: 'HRA EXEMPTION',
                  controller: _hraCtrl,
                  value: _hra,
                  min: 0,
                  max: 500000,
                  prefix: '₹ ',
                  onChangedText: (val) {
                    setState(() {
                      _hra = val;
                    });
                  },
                  onChangedSlider: (val) {
                    setState(() {
                      _hra = val;
                      _hraCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 12),

                // NPS Extra
                _buildSyncedInputRow(
                  label: 'NPS 80CCD(1B) EXTRA DEDUCTION',
                  controller: _npsCtrl,
                  value: _nps,
                  min: 0,
                  max: 50000,
                  prefix: '₹ ',
                  onChangedText: (val) {
                    setState(() {
                      _nps = val;
                    });
                  },
                  onChangedSlider: (val) {
                    setState(() {
                      _nps = val;
                      _npsCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _scrollToResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text('📊 Calculate Tax Liability',
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
                      onPressed: () => _saveCalculation(usedTax, usedTaxable),
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

        // Result Card (Orange/Navy Gradient)
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFFFF6B00)],
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
              Text('${_regime.toUpperCase()} REGIME · FY 2025–26',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: Colors.white70,
                      weight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                _fmt(usedTax),
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
                  _resultBox('Taxable Income', _fmt(usedTaxable)),
                  _resultBox(
                      'Effective Rate', '${effRate.toStringAsFixed(2)}%'),
                  _resultBox('Monthly TDS', _fmt(usedTax / 12), isRed: true),
                  _resultBox('In-Hand/Month',
                      _fmt(((_gross + _otherIncome) - usedTax) / 12),
                      isGreen: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Slab Progress Bars Card
        Text(
            'Tax Slab Breakdown (${_regime == 'new' ? 'New Regime' : 'Old Regime'})',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: List.generate(activeSlabs.length, (i) {
              final slab = activeSlabs[i];
              final double pct = slab['pct'];
              final color = slabColors[i % slabColors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        slab['hi'],
                        style: AppTextStyles.dmSans(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: theme.getTextColor(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF6B00).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: max(0.04, pct / 100.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 35,
                      child: Text(
                        slab['r'],
                        style: AppTextStyles.dmSans(
                          size: 10.5,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Step-by-step Computation summary
        Text('Detailed Tax Computation Summary',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _summaryRow('Gross Salary/Business Income', _fmt(_gross)),
              _summaryRow('Other Income', _fmt(_otherIncome)),
              _summaryRow('Total Deductions Claimed', '- ${_fmt(deductions)}',
                  isGreen: true),
              _summaryRow('Net Taxable Income', _fmt(usedTaxable)),
              const Divider(),
              ...details.map((d) => _summaryRow(
                  'Slab ${d['range']} @ ${d['rate']}', _fmt(d['tax']))),
              const Divider(),
              _summaryRow('Basic Tax (Before Cess)', _fmt(rawTax)),
              _summaryRow('Health & Education Cess (4%)', '+ ${_fmt(cess)}',
                  isRed: true),
              _summaryRow('Total Net Tax Payable', _fmt(usedTax),
                  isBoldSaffron: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Side-by-side Old vs New Tax Regime table
        Text('Side-by-side Regime Comparison',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Detail',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70))),
                    Expanded(
                        flex: 3,
                        child: Text('New Regime',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('Old Regime',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70),
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
              _compareRow('Taxable Inc', _fmt(taxableNew), _fmt(taxableOld)),
              _compareRow('Tax + Cess', _fmt(taxNew), _fmt(taxOld),
                  hlIndex: taxNew <= taxOld ? 1 : 2),
              _compareRow(
                  'Effective %',
                  '${(taxableNew > 0 ? taxNew / (_gross + _otherIncome) * 100 : 0.0).toStringAsFixed(2)}%',
                  '${(taxableOld > 0 ? taxOld / (_gross + _otherIncome) * 100 : 0.0).toStringAsFixed(2)}%'),
              _compareRow('Monthly TDS', _fmt(taxNew / 12), _fmt(taxOld / 12)),
              _compareRow(
                  'Regime Savings',
                  taxNew <= taxOld ? '+${_fmt(taxOld - taxNew)}' : '0',
                  taxOld < taxNew ? '+${_fmt(taxNew - taxOld)}' : '0',
                  hlIndex: taxNew <= taxOld ? 1 : 2),
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
              final sGross = s.inputs['gross'] ?? 0.0;
              final sOther = s.inputs['otherIncome'] ?? 0.0;
              final isSNew = s.inputs['regime'] == 1.0;
              final sTax = s.results['taxPayable'] ?? 0.0;
              final sTaxable = s.results['taxableIncome'] ?? 0.0;

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
                            '${s.label} · ${isSNew ? "New Regime" : "Old Regime"}',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Salary: ${_fmtShort(sGross)} · Other: ${_fmtShort(sOther)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                          Text(
                            'Taxable Inc: ${_fmtShort(sTaxable)}',
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
                          _fmtShort(sTax),
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: Colors.redAccent),
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

  Widget _resultBox(String label, String value,
      {bool isGreen = false, bool isRed = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
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
                color: isGreen
                    ? const Color(0xFF86EFAC)
                    : isRed
                        ? const Color(0xFFFCA5A5)
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

  Widget _summaryRow(String label, String val,
      {bool isGreen = false, bool isRed = false, bool isBoldSaffron = false}) {
    Color valColor = widget.theme.getTextColor(context);
    FontWeight fw = FontWeight.w600;
    double size = 11;

    if (isGreen) {
      valColor = const Color(0xFF046A38);
      fw = FontWeight.w800;
    } else if (isRed) {
      valColor = const Color(0xFFDC2626);
      fw = FontWeight.w800;
    } else if (isBoldSaffron) {
      valColor = const Color(0xFFFF6B00);
      fw = FontWeight.w900;
      size = 14;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context))),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: size, weight: fw, color: valColor)),
        ],
      ),
    );
  }

  Widget _compareRow(String label, String v1, String v2, {int hlIndex = 0}) {
    final bool isHl1 = hlIndex == 1;
    final bool isHl2 = hlIndex == 2;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: widget.theme.getBorderColor(context))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: AppTextStyles.dmSans(
                      size: 10, color: widget.theme.getTextColor(context)))),
          Expanded(
            flex: 3,
            child: Text(
              v1,
              style: AppTextStyles.dmSans(
                size: 10,
                weight: isHl1 ? FontWeight.w800 : FontWeight.w500,
                color: isHl1
                    ? const Color(0xFF046A38)
                    : widget.theme.getTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              v2,
              style: AppTextStyles.dmSans(
                size: 10,
                weight: isHl2 ? FontWeight.w800 : FontWeight.w500,
                color: isHl2
                    ? const Color(0xFF046A38)
                    : widget.theme.getTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
