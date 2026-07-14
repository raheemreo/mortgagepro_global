// lib/features/canada/tools/ca_prepayment.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

// ════════════════════════════════════════════════════════════════════════════
//  🍁  CANADIAN PREPAYMENT CALCULATOR
// ════════════════════════════════════════════════════════════════════════════

class CAPrepayment extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAPrepayment({super.key, required this.theme});

  @override
  ConsumerState<CAPrepayment> createState() => _CAPrepaymentState();
}

class _CAPrepaymentState extends ConsumerState<CAPrepayment>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _balanceController = TextEditingController(text: '400000');
  final _rateController = TextEditingController(text: '4.99');
  final _amortController = TextEditingController(text: '22');
  final _lumpsumController = TextEditingController(text: '20000');
  final _extraController = TextEditingController(text: '200');

  // Payment frequency: monthly | biweekly | accel
  String _payFreq = 'biweekly';

  // Results cache (null until first calc)
  _PrepayResult? _result;

  // Animation controller for donut
  late final AnimationController _animCtrl;
  late Animation<double> _animation;

  final _resultsKey = GlobalKey();
  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _rateController.dispose();
    _amortController.dispose();
    _lumpsumController.dispose();
    _extraController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Core Calculation ─────────────────────────────────────────────────────
  void _calculate() {
    final errors = <String, String>{};

    final P = double.tryParse(_balanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (P <= 0) errors['balance'] = 'Enter a valid mortgage balance';

    final annualRate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (annualRate <= 0 || annualRate > 25) errors['rate'] = 'Enter interest rate (0.1% - 25%)';

    final years = double.tryParse(_amortController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (years <= 0 || years > 50) errors['amort'] = 'Enter a valid amortization term';

    final lumpsum = double.tryParse(_lumpsumController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (lumpsum < 0) errors['lumpsum'] = 'Enter a valid lumpsum amount';

    final extraPmt = double.tryParse(_extraController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (extraPmt < 0) errors['extra'] = 'Enter a valid extra payment';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    // Save to snapshot
    setState(() {
      _calcSnapshot[_balanceController] = P;
      _calcSnapshot[_rateController] = annualRate;
      _calcSnapshot[_amortController] = years;
      _calcSnapshot[_lumpsumController] = lumpsum;
      _calcSnapshot[_extraController] = extraPmt;
      _calcSnapshot['_payFreq'] = _payFreq;
      _showResults = true;
    });

    // Canadian compounding: semi-annual → effective annual
    final double ea = dm.pow(1 + annualRate / 200, 2).toDouble() - 1;

    // Payment frequency adjustments
    int periodsPerYear;
    switch (_payFreq) {
      case 'monthly':
        periodsPerYear = 12;
        break;
      case 'accel':
        periodsPerYear = 26;
        break;
      default: // biweekly
        periodsPerYear = 26;
    }

    final double r = ea / periodsPerYear;
    final int n = (years * periodsPerYear).round();

    // Standard payment
    double pmt;
    if (r == 0) {
      pmt = P / n;
    } else {
      pmt = P * r / (1 - dm.pow(1 + r, -n));
    }

    // For accelerated: payment = monthly / 2
    final double monthlyR = ea / 12;
    final double monthlyPmt = monthlyR > 0
        ? P * monthlyR / (1 - dm.pow(1 + monthlyR, -(years * 12)))
        : P / (years * 12);
    final double accelPmt = monthlyPmt / 2;

    final double basePmt = _payFreq == 'accel' ? accelPmt : pmt;

    // ── Baseline simulation (no prepay) ──────────────────────────────────
    double bal = P;
    double totalInt = 0;
    int months = 0;
    final List<double> baseYrInt = [];
    double yInt = 0;

    while (bal > 0.01 && months < 600) {
      final double ip = bal * r;
      final double newPmt = basePmt;
      final double pp = (newPmt - ip).clamp(0, bal);
      totalInt += ip;
      yInt += ip;
      bal -= pp;
      months++;
      if (months % periodsPerYear == 0) {
        baseYrInt.add(yInt);
        yInt = 0;
      }
    }

    // ── Prepay simulation ─────────────────────────────────────────────────
    double bal2 = P;
    double totalInt2 = 0;
    int months2 = 0;
    int periodInYear = 0;
    final List<double> prepYrInt = [];
    double yInt2 = 0;

    while (bal2 > 0.01 && months2 < 600) {
      final double ip = bal2 * r;
      final double newPmt2 = basePmt + extraPmt;
      final double pp = (newPmt2 - ip).clamp(0, bal2);
      totalInt2 += ip;
      yInt2 += ip;
      bal2 -= pp;
      months2++;
      periodInYear++;

      if (periodInYear == periodsPerYear) {
        if (lumpsum > 0) bal2 = (bal2 - lumpsum).clamp(0, double.infinity);
        prepYrInt.add(yInt2);
        yInt2 = 0;
        periodInYear = 0;
      }
    }

    final double saved = (totalInt - totalInt2).clamp(0, double.infinity);
    final double baseMonths = (months / periodsPerYear) * 12;
    final double prepMonths = (months2 / periodsPerYear) * 12;
    final double yrsSaved = (baseMonths - prepMonths) / 12;
    final double pct = totalInt > 0 ? ((saved / totalInt) * 100).clamp(0, 100) : 0;

    final newResult = _PrepayResult(
      P: P,
      annualRate: annualRate,
      years: years,
      lumpsum: lumpsum,
      extraPmt: extraPmt,
      basePmt: basePmt,
      totalInt: totalInt,
      totalInt2: totalInt2,
      saved: saved,
      yrsSaved: yrsSaved,
      pct: pct,
      baseMonths: baseMonths,
      prepMonths: prepMonths,
      baseYrInt: baseYrInt,
      prepYrInt: prepYrInt,
    );

    setState(() => _result = newResult);
    _animCtrl.forward(from: 0);

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

  void _resetInputs() {
    setState(() {
      _balanceController.text = '400000';
      _rateController.text = '4.99';
      _amortController.text = '22';
      _lumpsumController.text = '20000';
      _extraController.text = '200';
      _payFreq = 'biweekly';
      _result = null;
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  // ── Save to Provider ──────────────────────────────────────────────────────
  void _saveCalculation() async {
    final r = _result;
    if (r == null) return;

    final labelCtrl = TextEditingController(text: 'Prepayment Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_prepayment/save'),
      builder: (ctx) => AlertDialog(
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
              'Saving: ${CurrencyFormatter.compact(r.saved, symbol: 'CA\$')} saved · ${r.yrsSaved.toStringAsFixed(1)} yrs shorter',
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
                hintText: 'Label (e.g. Lump Sum Strategy)',
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
          : 'Prepayment Plan';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Prepayment Calculator',
        inputs: {
          'Balance': r.P,
          'Rate': r.annualRate,
          'Amort': r.years,
          'Lumpsum': r.lumpsum,
          'Extra': r.extraPmt,
        },
        results: {
          'BasePmt': r.basePmt,
          'TotalInt': r.totalInt,
          'TotalInt2': r.totalInt2,
          'Saved': r.saved,
          'YrsSaved': r.yrsSaved,
          'Pct': r.pct,
        },
        label: label,
        currencyCode: 'CAD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Prepayment plan saved!',
              style: AppTextStyles.dmSans(
                  color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: widget.theme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  bool _rateInitialized = false;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Watch rates provider to initialize default interest rate
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    if (ratesAsync.hasValue && !_rateInitialized) {
      final defaultRate = ratesAsync.value!.rate5yrFixed;
      _rateController.text = defaultRate.toStringAsFixed(2);
      _rateInitialized = true;
    }

    final isDirty = _showResults && (
      (double.tryParse(_balanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_balanceController] ?? 0.0) ||
      (double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_rateController] ?? 0.0) ||
      (double.tryParse(_amortController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_amortController] ?? 0.0) ||
      (double.tryParse(_lumpsumController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_lumpsumController] ?? 0.0) ||
      (double.tryParse(_extraController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_extraController] ?? 0.0) ||
      _payFreq != (_calcSnapshot['_payFreq'] ?? '')
    );

    final saved = ref.watch(savedProvider);
    final localSaved = saved
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType.toLowerCase() == 'prepayment calculator')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Mortgage Details ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('MORTGAGE DETAILS', theme),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _inputCard(theme, children: [
          _inputField('Balance Owing', _balanceController,
              prefix: 'CA\$', errorText: _errors['balance'], theme: theme),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _inputField('Interest Rate', _rateController,
                  suffix: '%', errorText: _errors['rate'], theme: theme),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _inputField('Amortization Left', _amortController,
                  suffix: 'yrs', errorText: _errors['amort'], theme: theme),
            ),
          ]),
          const SizedBox(height: 14),
          Text('PAYMENT FREQUENCY',
              style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.bold,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _freqSelector(theme),
        ]),
        const SizedBox(height: 20),

        // ── Prepayment Options ───────────────────────────────────────────
        _sectionLabel('PREPAYMENT OPTIONS', theme),
        const SizedBox(height: 8),
        _inputCard(theme, children: [
          _inputField('Annual Lump Sum', _lumpsumController,
              prefix: 'CA\$', errorText: _errors['lumpsum'], theme: theme),
          const SizedBox(height: 12),
          _inputField('Payment Increase', _extraController,
              prefix: 'CA\$', errorText: _errors['extra'], theme: theme),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5C35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('📈 Calculate Savings',
                    style: AppTextStyles.dmSans(
                        size: 13, color: Colors.white, weight: FontWeight.bold)),
              ),
            ),
            if (_showResults && _result != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  width: 50,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A4A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('💾', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ]),
        ]),
        const SizedBox(height: 20),

        // ── Results ──────────────────────────────────────────────────────
        if (_showResults && _result != null) ...[
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('YOUR SAVINGS', theme),
                const SizedBox(height: 8),
                _buildResultHero(_result!, theme),
                const SizedBox(height: 20),

                _sectionLabel('VISUAL ANALYSIS', theme),
                const SizedBox(height: 8),
                _buildChartCard(_result!, theme),
                const SizedBox(height: 20),

                _sectionLabel('BREAKDOWN', theme),
                const SizedBox(height: 8),
                _buildBreakdownCard(_result!, theme),
                const SizedBox(height: 20),

                _buildProTip(_result!, theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],

        // ── Lender Privilege Guide ───────────────────────────────────────
        _sectionLabel('LENDER PRIVILEGE GUIDE (2026)', theme),
        const SizedBox(height: 8),
        _buildPrivilegeCard(theme),
        const SizedBox(height: 20),

        // ── Local Saved Calculations ──────────────────────────────────────
        if (localSaved.isNotEmpty) ...[
          _sectionLabel('SAVED CALCULATIONS (${localSaved.length})', theme),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: localSaved.length,
            itemBuilder: (context, idx) {
              final c = localSaved[idx];
              final saved2 = c.results['Saved'] ?? 0;
              final yrs = c.results['YrsSaved'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            c.label,
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: theme.getTextColor(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CA\$${(c.inputs['Balance'] ?? 0).toStringAsFixed(0)} @ ${c.inputs['Rate']}% · Lump CA\$${(c.inputs['Lumpsum'] ?? 0).toStringAsFixed(0)} + CA\$${(c.inputs['Extra'] ?? 0).toStringAsFixed(0)}/pmt',
                            style: AppTextStyles.dmSans(
                                size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(saved2, symbol: 'CA\$'),
                          style: AppTextStyles.playfair(
                              size: 13,
                              weight: FontWeight.bold,
                              color: const Color(0xFF1A5C35)),
                        ),
                        Text(
                          '${yrs.toStringAsFixed(1)} yrs saved',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          ref.read(savedProvider.notifier).delete(c.id),
                      child: const Text('✕',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ── Result Hero Card ─────────────────────────────────────────────────────
  Widget _buildResultHero(_PrepayResult r, CountryTheme theme) {
    final String basePayoff = _mToYrMo(r.baseMonths.round());
    final String newPayoff = _mToYrMo(r.prepMonths.round());
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A0F), Color(0xFF0A2E1A), Color(0xFF1A5C35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL INTEREST SAVED',
              style: AppTextStyles.dmSans(
                  size: 9,
                  color: Colors.white54,
                  weight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(r.saved, symbol: 'CA\$'),
            style: AppTextStyles.playfair(
                size: 36, weight: FontWeight.bold, color: const Color(0xFF6EDFA0)),
          ),
          Text('Compared to baseline payments',
              style: AppTextStyles.dmSans(size: 11, color: Colors.white54)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _resBox(
                    'Years Saved',
                    r.yrsSaved > 0
                        ? '${r.yrsSaved.toStringAsFixed(1)} yrs'
                        : '< 1 mo',
                    const Color(0xFF6EDFA0)),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: _resBox('New Payoff', newPayoff, Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                  child: _resBox('Base Payoff', basePayoff, const Color(0xFFFF8A9A))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chart Card ────────────────────────────────────────────────────────────
  Widget _buildChartCard(_PrepayResult r, CountryTheme theme) {
    final int maxYrs =
        dm.min(5, dm.max(r.baseYrInt.length, r.prepYrInt.length)).toInt();
    final double maxVal = [
      ...r.baseYrInt.take(maxYrs),
      ...r.prepYrInt.take(maxYrs),
      1.0
    ].reduce(dm.max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Interest Breakdown',
                style: AppTextStyles.playfair(
                    size: 13,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context))),
            Text('${r.pct.toStringAsFixed(1)}% saved',
                style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.w600,
                    color: theme.getMutedColor(context))),
          ]),
          const SizedBox(height: 14),

          // Donut + Legend
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      pct: r.pct * _animation.value,
                      savedColor: const Color(0xFF6EDFA0),
                      remainingColor: const Color(0xFFFFB0B8),
                      bgColor: theme.getBgColor(context),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(r.pct * _animation.value).toStringAsFixed(0)}%',
                            style: AppTextStyles.playfair(
                                size: 18,
                                weight: FontWeight.bold,
                                color: theme.getTextColor(context)),
                          ),
                          Text('saved',
                              style: AppTextStyles.dmSans(
                                  size: 9,
                                  weight: FontWeight.bold,
                                  color: theme.getMutedColor(context))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendItem(
                          'Interest Saved',
                          CurrencyFormatter.compact(r.saved, symbol: 'CA\$'),
                          const Color(0xFF6EDFA0),
                          theme),
                      const SizedBox(height: 8),
                      _legendItem(
                          'Remaining Int.',
                          CurrencyFormatter.compact(r.totalInt2, symbol: 'CA\$'),
                          const Color(0xFFFFB0B8),
                          theme),
                      const SizedBox(height: 8),
                      _legendItem(
                          'Principal',
                          CurrencyFormatter.compact(r.P, symbol: 'CA\$'),
                          const Color(0xFF1A5C35),
                          theme),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text('5-Year Cumulative Interest (Base vs Prepay)',
              style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w600,
                  color: theme.getMutedColor(context))),
          const SizedBox(height: 10),

          // Mini bar chart
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(maxYrs, (i) {
                final double bv = i < r.baseYrInt.length ? r.baseYrInt[i] : 0;
                final double pv = i < r.prepYrInt.length ? r.prepYrInt[i] : 0;
                final double bh = (bv / maxVal * 48).clamp(3.0, 48.0);
                final double ph = (pv / maxVal * 48).clamp(3.0, 48.0);
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 9,
                            height: bh,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFB0B8),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 9,
                            height: ph,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6EDFA0),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Yr ${i + 1}',
                          style: AppTextStyles.dmSans(
                              size: 8,
                              weight: FontWeight.bold,
                              color: theme.getMutedColor(context))),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _chartLeg('Base', const Color(0xFFFFB0B8), theme),
            const SizedBox(width: 14),
            _chartLeg('With Prepay', const Color(0xFF6EDFA0), theme),
          ]),
        ],
      ),
    );
  }

  // ── Breakdown Card ────────────────────────────────────────────────────────
  Widget _buildBreakdownCard(_PrepayResult r, CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          _bkRow('Regular payment (${_payFreqLabel()})',
              '${CurrencyFormatter.format(r.basePmt, symbol: 'CA\$')}/${_payFreqUnit()}',
              null, theme),
          const Divider(height: 16, thickness: 0.5),
          _bkRow('Total interest (no prepay)',
              CurrencyFormatter.format(r.totalInt, symbol: 'CA\$'),
              const Color(0xFFC8102E), theme),
          const Divider(height: 16, thickness: 0.5),
          _bkRow('Total interest (with prepay)',
              CurrencyFormatter.format(r.totalInt2, symbol: 'CA\$'),
              const Color(0xFF1A5C35), theme),
          const Divider(height: 16, thickness: 0.5),
          _bkRow('Net interest saved',
              CurrencyFormatter.format(r.saved, symbol: 'CA\$'),
              const Color(0xFF1A5C35), theme),
          const SizedBox(height: 12),
          // Progress bar
          Text('Interest reduction %',
              style: AppTextStyles.dmSans(
                  size: 10,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 9,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (ctx, _) => LinearProgressIndicator(
                  value: (r.pct / 100 * _animation.value).clamp(0.0, 1.0),
                  backgroundColor: theme.getBgColor(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A5C35)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('0%',
                style: AppTextStyles.dmSans(
                    size: 10, color: theme.getMutedColor(context))),
            Text('${r.pct.toStringAsFixed(1)}% saved',
                style: AppTextStyles.dmSans(
                    size: 10,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  // ── Pro Tip Card ──────────────────────────────────────────────────────────
  Widget _buildProTip(_PrepayResult r, CountryTheme theme) {
    final String tipText = r.lumpsum > 0 || r.extraPmt > 0
        ? 'Your CA\$${r.lumpsum.toStringAsFixed(0)} annual lump sum + CA\$${r.extraPmt.toStringAsFixed(0)}/pmt increase saves ${CurrencyFormatter.compact(r.saved, symbol: 'CA\$')} in interest and cuts ${r.yrsSaved.toStringAsFixed(1)} years off your mortgage. Applying prepayments in Year 1 maximises impact.'
        : 'In Year 1, ~70% of each payment is interest. A \$20K prepayment early in your term can save over \$40K total and shorten amortisation by 2+ years.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]),
        border: Border.all(color: const Color(0xFF1A5C35).withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prepay Early for Maximum Impact',
                    style: AppTextStyles.playfair(
                        size: 13,
                        weight: FontWeight.bold,
                        color: const Color(0xFF166534))),
                const SizedBox(height: 4),
                Text(tipText,
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: const Color(0xFF4A7C5F),
                        weight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Privilege Card ────────────────────────────────────────────────────────
  Widget _buildPrivilegeCard(CountryTheme theme) {
    const lenders = [
      _LenderPriv('TD Bank', '15% lump sum · 100% pmt increase', 'Once/yr'),
      _LenderPriv('RBC', '10% lump sum · 10% pmt increase', 'Once/yr'),
      _LenderPriv('Scotiabank', '15% lump sum · 15% pmt increase', 'Once/yr'),
      _LenderPriv('BMO', '20% lump sum · 20% pmt increase', 'Once/yr'),
      _LenderPriv('CIBC', '20% lump sum · 100% pmt increase', 'Once/yr'),
      _LenderPriv('nesto / Monoline', '20% lump sum · 20% pmt increase', 'Open'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: lenders.asMap().entries.map((entry) {
          final isLast = entry.key == lenders.length - 1;
          final l = entry.value;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏦', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name,
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: theme.getTextColor(context))),
                        Text(l.detail,
                            style: AppTextStyles.dmSans(
                                size: 10, color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF4E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(l.badge,
                        style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.bold,
                            color: const Color(0xFF166534))),
                  ),
                ],
              ),
              if (!isLast) const Divider(height: 16, thickness: 0.5),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, CountryTheme theme) {
    return Text(text,
        style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6));
  }

  Widget _inputCard(CountryTheme theme, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller,
      {required CountryTheme theme,
      String? prefix,
      String? suffix,
      String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: errorText != null ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Text(prefix,
                      style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.bold,
                          color: theme.primaryColor)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: AppTextStyles.dmSans(
                      size: 16,
                      weight: FontWeight.bold,
                      color: theme.getTextColor(context)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 11),
                  child: Text(suffix,
                      style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: theme.getMutedColor(context))),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _freqSelector(CountryTheme theme) {
    final freqs = [
      ('Monthly', 'monthly'),
      ('Bi-Weekly', 'biweekly'),
      ('Accel.', 'accel'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: freqs.map((f) {
          final active = _payFreq == f.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _payFreq = f.$2);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  f.$1,
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.bold,
                    color: active ? Colors.white : theme.getMutedColor(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _resBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white60,
                  weight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 12, weight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _legendItem(
      String label, String value, Color dotColor, CountryTheme theme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: AppTextStyles.dmSans(
                  size: 11, color: theme.getMutedColor(context), weight: FontWeight.w600)),
        ),
        Text(value,
            style: AppTextStyles.playfair(
                size: 12, weight: FontWeight.bold, color: theme.getTextColor(context))),
      ],
    );
  }

  Widget _chartLeg(String title, Color color, CountryTheme theme) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(title,
            style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _bkRow(String label, String value, Color? valueColor,
      CountryTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 12, color: theme.getMutedColor(context), weight: FontWeight.w600)),
        Text(value,
            style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.bold,
                color: valueColor ?? theme.getTextColor(context))),
      ],
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────
  String _mToYrMo(int m) {
    final int y = m ~/ 12;
    final int mo = m % 12;
    return mo > 0 ? '${y}yr ${mo}mo' : '${y}yr';
  }

  String _payFreqLabel() {
    switch (_payFreq) {
      case 'monthly':
        return 'monthly';
      case 'accel':
        return 'accel bi-wkly';
      default:
        return 'bi-weekly';
    }
  }

  String _payFreqUnit() {
    switch (_payFreq) {
      case 'monthly':
        return 'mo';
      case 'accel':
        return '2wks';
      default:
        return '2wks';
    }
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _PrepayResult {
  final double P;
  final double annualRate;
  final double years;
  final double lumpsum;
  final double extraPmt;
  final double basePmt;
  final double totalInt;
  final double totalInt2;
  final double saved;
  final double yrsSaved;
  final double pct;
  final double baseMonths;
  final double prepMonths;
  final List<double> baseYrInt;
  final List<double> prepYrInt;

  const _PrepayResult({
    required this.P,
    required this.annualRate,
    required this.years,
    required this.lumpsum,
    required this.extraPmt,
    required this.basePmt,
    required this.totalInt,
    required this.totalInt2,
    required this.saved,
    required this.yrsSaved,
    required this.pct,
    required this.baseMonths,
    required this.prepMonths,
    required this.baseYrInt,
    required this.prepYrInt,
  });
}

class _LenderPriv {
  final String name;
  final String detail;
  final String badge;
  const _LenderPriv(this.name, this.detail, this.badge);
}

// ── Donut Chart Painter ───────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double pct;
  final Color savedColor;
  final Color remainingColor;
  final Color bgColor;

  const _DonutPainter({
    required this.pct,
    required this.savedColor,
    required this.remainingColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 2 - 12;
    const double strokeW = 14;
    const double startAngle = -dm.pi / 2;
    const double fullAngle = 2 * dm.pi;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    // Remaining interest arc (base)
    final remPaint = Paint()
      ..color = remainingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      fullAngle,
      false,
      remPaint,
    );

    // Saved arc
    if (pct > 0) {
      final savedPaint = Paint()
        ..color = savedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;
      final sweepAngle = fullAngle * (pct / 100);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle,
        false,
        savedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.pct != pct;
}
