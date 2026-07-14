// lib/features/europe/tools/eu_country_comparison.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUCountryComparison extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUCountryComparison({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUCountryComparison> createState() => _EUCountryComparisonState();
}

class _EUCountryComparisonState extends ConsumerState<EUCountryComparison> {
  double _propVal = 420000;
  double _depositPct = 20;
  int _termYears = 20;
  String _rateType = 'fixed'; // fixed, variable
  bool _hasCalculated = false;

  final List<Map<String, dynamic>> _countries = [
    {
      'code': 'DE',
      'flag': '🇩🇪',
      'name': 'Germany',
      'sub': 'Baufinanzierung',
      'fixed': 3.85,
      'variable': 4.92,
      'maxLTV': 80,
      'avgPrice': 420000,
      'propTax': 3.5,
      'notary': 1.5,
      'agent': 3.57,
      'color': const Color(0xFF003399)
    },
    {
      'code': 'FR',
      'flag': '🇫🇷',
      'name': 'France',
      'sub': 'Prêt Immobilier',
      'fixed': 3.60,
      'variable': 4.62,
      'maxLTV': 85,
      'avgPrice': 330000,
      'propTax': 0.5,
      'notary': 7.0,
      'agent': 5.0,
      'color': const Color(0xFF1E3A8A)
    },
    {
      'code': 'ES',
      'flag': '🇪🇸',
      'name': 'Spain',
      'sub': 'Hipoteca',
      'fixed': 3.30,
      'variable': 4.92,
      'maxLTV': 80,
      'avgPrice': 280000,
      'propTax': 1.1,
      'notary': 0.5,
      'agent': 3.0,
      'color': const Color(0xFFDC2626)
    },
    {
      'code': 'IT',
      'flag': '🇮🇹',
      'name': 'Italy',
      'sub': 'Mutuo',
      'fixed': 4.25,
      'variable': 5.42,
      'maxLTV': 80,
      'avgPrice': 210000,
      'propTax': 2.0,
      'notary': 1.0,
      'agent': 4.0,
      'color': const Color(0xFF166534)
    },
    {
      'code': 'NL',
      'flag': '🇳🇱',
      'name': 'Netherlands',
      'sub': 'Hypotheek',
      'fixed': 3.75,
      'variable': 4.92,
      'maxLTV': 100,
      'avgPrice': 430000,
      'propTax': 0.0,
      'notary': 0.5,
      'agent': 1.5,
      'color': const Color(0xFF9A3412)
    },
    {
      'code': 'PT',
      'flag': '🇵🇹',
      'name': 'Portugal',
      'sub': 'Crédito Habitação',
      'fixed': 4.30,
      'variable': 5.72,
      'maxLTV': 80,
      'avgPrice': 290000,
      'propTax': 0.3,
      'notary': 0.8,
      'agent': 5.0,
      'color': const Color(0xFF4338CA)
    },
  ];

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _propVal = inputs['propVal'] ?? 420000;
      _depositPct = inputs['depositPct'] ?? 20;
      _termYears = (inputs['termYears'] ?? 20).toInt();
      final typeVal = inputs['rateType'] ?? 0.0;
      _rateType = typeVal == 0.0 ? 'fixed' : 'variable';

      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['depositPct'] = _depositPct;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['rateType'] = _rateType;

      _hasCalculated = true;
    }
  }

  double _monthlyPayment(double P, double rateAnnual, int years) {
    final r = (rateAnnual / 100) / 12;
    final n = years * 12;
    if (r == 0) return P / n;
    return P * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  void _runCalc() {
    setState(() {
      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['depositPct'] = _depositPct;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['rateType'] = _rateType;
      _hasCalculated = true;
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

  void _reset() {
    setState(() {
      _propVal = 420000;
      _depositPct = 20;
      _termYears = 20;
      _rateType = 'fixed';
      _hasCalculated = false;
      _calcSnapshot.clear();
    });
  }

  void _saveCalculation() async {
    final double propVal = _calcSnapshot['propVal'] ?? _propVal;
    final double depositPct = _calcSnapshot['depositPct'] ?? _depositPct;
    final int termYears = _calcSnapshot['termYears'] ?? _termYears;
    final String rateType = _calcSnapshot['rateType'] ?? _rateType;

    final loan = propVal * (1 - depositPct / 100);
    final List<Map<String, dynamic>> results = _countries.map((c) {
      final rate = rateType == 'fixed' ? c['fixed'] as double : c['variable'] as double;
      final m = _monthlyPayment(loan, rate, termYears);
      final total = m * termYears * 12;
      final totalInt = total - loan;
      return {
        ...c,
        'rate': rate,
        'monthly': m,
        'totalInt': totalInt,
      };
    }).toList();

    results.sort((a, b) => (a['monthly'] as double).compareTo(b['monthly'] as double));

    final rates = results.map((r) => r['rate'] as double).toList();
    final lowestRate = rates.reduce(math.min);
    final highestRate = rates.reduce(math.max);
    final rateSpread = highestRate - lowestRate;
    final bestMonthly = results[0]['monthly'] as double;
    final bestName = results[0]['name'] as String;

    final labelCtrl = TextEditingController(text: 'Europe Comparison');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/eu_country_comparison'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparison',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Best $bestName at ${CurrencyFormatter.compact(bestMonthly, symbol: '€')}/mo · Spread ${rateSpread.toStringAsFixed(2)}%',
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
                hintText: 'Label (e.g. EU House Hunting)',
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
          : 'Europe Comparison';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Comparison Calc',
        inputs: {
          'propVal': propVal,
          'depositPct': depositPct,
          'termYears': termYears.toDouble(),
          'rateType': rateType == 'fixed' ? 0.0 : 1.0,
        },
        results: {
          'Spread': rateSpread,
          'Best Monthly': bestMonthly,
        },
        label: label,
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Comparison saved!',
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
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedText = theme.getMutedColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double snapPropVal = _calcSnapshot['propVal'] ?? _propVal;
    final double snapDepositPct = _calcSnapshot['depositPct'] ?? _depositPct;
    final int snapTermYears = _calcSnapshot['termYears'] ?? _termYears;
    final String snapRateType = _calcSnapshot['rateType'] ?? _rateType;

    // Calculate loan details for all countries
    final loan = snapPropVal * (1 - snapDepositPct / 100);
    final List<Map<String, dynamic>> results = _countries.map((c) {
      final rate = snapRateType == 'fixed' ? c['fixed'] as double : c['variable'] as double;
      final m = _monthlyPayment(loan, rate, snapTermYears);
      final total = m * snapTermYears * 12;
      final totalInt = total - loan;
      return {
        ...c,
        'rate': rate,
        'monthly': m,
        'totalInt': totalInt,
      };
    }).toList();

    // Sort results by monthly payment ascending (best is index 0)
    results.sort((a, b) => (a['monthly'] as double).compareTo(b['monthly'] as double));

    // Live ECB rates for context strip
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveEcb = ratesAsync.valueOrNull?.ecbRate.value ?? 4.00;
    final liveEu6m = ratesAsync.valueOrNull?.euribor6m.value ?? 3.42;
    final isLive = ratesAsync.valueOrNull?.isLive == true;

    // Country fixed-rate spreads over ECB (static per country, dynamic base)
    final Map<String, double> fixedSpreads = {'DE': -0.15, 'FR': -0.40, 'ES': -0.70, 'IT': 0.25, 'NL': -0.25, 'PT': 0.30};
    final Map<String, double> varSpreads   = {'DE': 1.50,  'FR': 1.20,  'ES': 1.50,  'IT': 2.00, 'NL': 1.50, 'PT': 2.30};

    final rates = results.map((r) => r['rate'] as double).toList();
    final lowestRate = rates.reduce(math.min);
    final highestRate = rates.reduce(math.max);
    final rateSpread = highestRate - lowestRate;
    final bestMonthly = results[0]['monthly'] as double;

    final isDirty = _hasCalculated && (
      _propVal != snapPropVal ||
      _depositPct != snapDepositPct ||
      _termYears != snapTermYears ||
      _rateType != snapRateType
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Rate Strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cmpRateItem('🇩🇪 ${(liveEcb + fixedSpreads['DE']!).toStringAsFixed(2)}%', 'Germany Fix', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _cmpRateItem('🇫🇷 ${(liveEcb + fixedSpreads['FR']!).toStringAsFixed(2)}%', 'France Fix', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _cmpRateItem('🇪🇸 ${(liveEu6m + varSpreads['ES']!).toStringAsFixed(2)}%', 'Spain Var', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _cmpRateItem('ECB${isLive ? ' 🟢' : ''}\n${liveEcb.toStringAsFixed(2)}%', 'Policy Rate', mutedText, const Color(0xFFFFD700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SET LOAN PARAMETERS', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
            GestureDetector(
              onTap: _reset,
              child: Text('Reset', style: AppTextStyles.dmSans(size: 11, color: theme.primaryColor, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Value & Deposit input fields
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROPERTY VALUE (€)', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                          decoration: InputDecoration(
                            fillColor: theme.getBgColor(context),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          controller: TextEditingController(text: _propVal.toStringAsFixed(0))
                            ..selection = TextSelection.collapsed(offset: _propVal.toStringAsFixed(0).length),
                          onChanged: (v) => _propVal = double.tryParse(v) ?? 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEPOSIT (%)', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                          decoration: InputDecoration(
                            fillColor: theme.getBgColor(context),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          controller: TextEditingController(text: _depositPct.toStringAsFixed(0))
                            ..selection = TextSelection.collapsed(offset: _depositPct.toStringAsFixed(0).length),
                          onChanged: (v) => _depositPct = double.tryParse(v) ?? 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Term & Rate Type
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TERM', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderCol),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _termYears,
                              dropdownColor: cardBg,
                              style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 15, child: Text('15 years')),
                                DropdownMenuItem(value: 20, child: Text('20 years')),
                                DropdownMenuItem(value: 25, child: Text('25 years')),
                                DropdownMenuItem(value: 30, child: Text('30 years')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _termYears = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RATE TYPE', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderCol),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _rateType,
                              dropdownColor: cardBg,
                              style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                                DropdownMenuItem(value: 'variable', child: Text('Variable')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _rateType = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              GestureDetector(
                onTap: _runCalc,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003399), Color(0xFF1A0040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF003399).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌍', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Compare All Countries',
                          style: AppTextStyles.dmSans(
                              size: 13, weight: FontWeight.w800, color: const Color(0xFFFFCC00))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_hasCalculated) ...[
          if (isDirty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Calculate again to update results.',
                      style: AppTextStyles.dmSans(
                        size: 11.5,
                        color: const Color(0xFFB45309),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Quick stats
          Text('QUICK STATS', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            children: [
              _quickStatBox('🏆', 'Lowest Rate', '${lowestRate.toStringAsFixed(2)}%'),
              const SizedBox(width: 8),
              _quickStatBox('💰', 'Best Monthly', CurrencyFormatter.compact(bestMonthly, symbol: '€')),
              const SizedBox(width: 8),
              _quickStatBox('📊', 'Rate Spread', '${rateSpread.toStringAsFixed(2)}%'),
            ],
          ),
          const SizedBox(height: 16),

          // Rankings table
          Text('SIDE-BY-SIDE RANKINGS', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                Container(
                  color: theme.primaryColor.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('COUNTRY', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: mutedText)),
                      Text('EST. MONTHLY', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: mutedText)),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderCol),
                  itemBuilder: (context, idx) {
                    final item = results[idx];
                    final val = item['monthly'] as double;
                    final isBest = idx == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(item['flag'], style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Text(item['name'], style: AppTextStyles.dmSans(size: 11.5, weight: isBest ? FontWeight.bold : FontWeight.w600, color: textColor)),
                              if (isBest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text('🏆 BEST', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF22C55E), weight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${CurrencyFormatter.format(val, symbol: '€')}/mo (${(item['rate'] as double).toStringAsFixed(2)}%)',
                            style: AppTextStyles.dmSans(size: 11.5, weight: isBest ? FontWeight.bold : FontWeight.w600, color: isBest ? theme.primaryColor : textColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly payment bar comparison chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Payment Comparison', style: AppTextStyles.cardTitle(textColor)),
                const SizedBox(height: 4),
                Text('Estimated monthly payments per country (€)', style: AppTextStyles.dmSans(size: 10.5, color: mutedText)),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, idx) {
                    final item = results[idx];
                    final val = item['monthly'] as double;
                    final double pct = bestMonthly > 0 ? (bestMonthly / val) : 1.0;
                    final isBest = idx == 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(item['flag'], style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(item['name'], style: AppTextStyles.dmSans(size: 11.5, weight: isBest ? FontWeight.bold : FontWeight.w600, color: textColor)),
                                if (isBest) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text('🏆 BEST', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF22C55E), weight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${CurrencyFormatter.format(val, symbol: '€')}/mo (${(item['rate'] as double).toStringAsFixed(2)}%)',
                              style: AppTextStyles.dmSans(size: 11.5, weight: isBest ? FontWeight.bold : FontWeight.w600, color: isBest ? theme.primaryColor : textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(4)),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct.clamp(0.1, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item['color'] as Color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Market Snapshots List (Detail cards grid)
          Text('MARKET SNAPSHOTS', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: results.map((c) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c['flag'], style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(c['name'], style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: textColor)),
                      ],
                    ),
                    const Spacer(),
                    _snapshotDetailRow('Max LTV', '${c['maxLTV']}%'),
                    _snapshotDetailRow('Prop Tax', '${c['propTax']}%'),
                    _snapshotDetailRow('Notary Fee', '${c['notary']}%'),
                    _snapshotDetailRow('Avg Price', CurrencyFormatter.compact(c['avgPrice'] * 1.0, symbol: '€')),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Save Comparison Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save Comparison', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: textColor)),
                      Text('Store for later reference', style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveCalculation,
                  child: Text('Save ✓', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFFCC00), weight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ] else
          // Empty state
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                const Text('🇪🇺', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Compare European Markets',
                    style: AppTextStyles.playfair(
                        size: 15, weight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  'Enter property value, deposit percent, term, and rate type,\nthen tap Compare All Countries to see mortgage costs.',
                  style: AppTextStyles.dmSans(size: 11, color: mutedText, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _quickStatBox(String icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.theme.getCardColor(context),
          border: Border.all(color: widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(value, style: AppTextStyles.playfair(size: 13, color: widget.theme.getTextColor(context), weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }


  Widget _snapshotDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
          Text(value, style: AppTextStyles.playfair(size: 9.5, color: widget.theme.getTextColor(context), weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _cmpRateItem(String rate, String label, Color mutedText, Color textColor) {
    return Column(
      children: [
        Text(rate, style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: mutedText)),
      ],
    );
  }
}
