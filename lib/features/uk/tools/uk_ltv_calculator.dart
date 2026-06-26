// lib/features/uk/tools/uk_ltv_calculator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class UKLtvCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKLtvCalculator({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKLtvCalculator> createState() => _UKLtvCalculatorState();
}

class _UKLtvCalculatorState extends ConsumerState<UKLtvCalculator> {
  final _propValController = TextEditingController(text: '380000');
  final _equityController = TextEditingController(text: '76000');
  final _outstandingController = TextEditingController(text: '0');

  double _propVal = 380000;
  double _equity = 76000;
  double _outstanding = 0;

  bool _hasCalculated = false;

  final List<Map<String, dynamic>> tiers = const [
    {
      'max': 60.0,
      'rate': 3.99,
      'label': 'Up to 60%',
      'badge': 'best',
      'badgeText': 'Best Rate'
    },
    {
      'max': 65.0,
      'rate': 4.05,
      'label': 'Up to 65%',
      'badge': 'best',
      'badgeText': 'Excellent'
    },
    {
      'max': 75.0,
      'rate': 4.35,
      'label': 'Up to 75%',
      'badge': 'ok',
      'badgeText': 'Good'
    },
    {
      'max': 80.0,
      'rate': 4.55,
      'label': 'Up to 80%',
      'badge': 'ok',
      'badgeText': 'Standard'
    },
    {
      'max': 85.0,
      'rate': 4.75,
      'label': 'Up to 85%',
      'badge': 'ok',
      'badgeText': 'Fair'
    },
    {
      'max': 90.0,
      'rate': 4.95,
      'label': 'Up to 90%',
      'badge': 'high',
      'badgeText': 'Higher'
    },
    {
      'max': 95.0,
      'rate': 5.49,
      'label': 'Up to 95%',
      'badge': 'high',
      'badgeText': 'High'
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _propValController.text =
          (inputs['propVal'] ?? 380000.0).toStringAsFixed(0);
      _equityController.text = (inputs['equity'] ?? 76000.0).toStringAsFixed(0);
      _outstandingController.text =
          (inputs['outstanding'] ?? 0.0).toStringAsFixed(0);
      _hasCalculated = true;
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _propValController.dispose();
    _equityController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _propVal = double.tryParse(_propValController.text) ?? 0;
      _equity = double.tryParse(_equityController.text) ?? 0;
      _outstanding = double.tryParse(_outstandingController.text) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loan = _outstanding > 0 ? _outstanding : (_propVal - _equity);
    final ltv = _propVal > 0 ? (loan / _propVal * 100) : 0.0;
    final equityAmt = _propVal - loan;

    // Find tier
    Map<String, dynamic> activeTier = tiers.last;
    for (var t in tiers) {
      if (ltv <= t['max']) {
        activeTier = t;
        break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates for context strip
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final fixed5yr = ukRates?.fixed5yr.value ?? 4.35;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final isLive   = ukRates?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _rateCell('60% LTV', '3.99%', 'Best rate',
                      isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
              _divider(),
              Expanded(
                  child: _rateCell('75% LTV', '${fixed5yr.toStringAsFixed(2)}%', isLive ? 'Live 🟢' : 'Good', textThemeColor)),
              _divider(),
              Expanded(
                  child: _rateCell(
                      '90% LTV', '4.95%', 'Higher', isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))),
              _divider(),
              Expanded(
                  child: _rateCell(
                      'BoE Base', '${boeBase.toStringAsFixed(2)}%', isLive ? '🟢 Live' : 'Est.', isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'PROPERTY & LOAN DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _inputField(
                          label: 'Property Value (£)',
                          controller: _propValController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _inputField(
                          label: 'Deposit / Equity (£)',
                          controller: _equityController)),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(
                  label: 'Outstanding Mortgage (£) — leave 0 for purchase',
                  controller: _outstandingController),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Calculate Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
            onPressed: () {
              _calculateValues();
              setState(() => _hasCalculated = true);
            },
            child: Text(
              '📊 Calculate LTV',
              style: AppTextStyles.dmSans(
                  size: 14, color: Colors.white, weight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          // Results Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOAN-TO-VALUE RATIO',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 0.7),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${ltv.toStringAsFixed(1)}%',
                      style: AppTextStyles.dmSans(
                        size: 38,
                        weight: FontWeight.w800,
                        color: ltv <= 75
                            ? const Color(0xFF90EE90)
                            : (ltv <= 85
                                ? const Color(0xFFFFD700)
                                : const Color(0xFFFF8A9A)),
                      ).copyWith(fontFamily: 'Georgia'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final calc = SavedCalc.create(
                          country: 'UK',
                          calcType: 'LTV Ratio',
                          inputs: {
                            'propVal': _propVal,
                            'equity': _equity,
                            'outstanding': _outstanding,
                          },
                          results: {
                            'LTV Ratio': ltv,
                            'Loan Amount': loan,
                            'Equity Amount': equityAmt,
                            'Indicative Rate': activeTier['rate'],
                          },
                          label:
                              '${CurrencyFormatter.compact(_propVal, symbol: '£')} property · ${ltv.toStringAsFixed(1)}% LTV',
                          currencyCode: 'GBP',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).save(calc);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✓ LTV calculation saved'),
                            backgroundColor: Color(0xFF0D9488),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.save,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('Save',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${activeTier['label']} tier · ${activeTier['badgeText']}',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // LTV Grid
          ResultPanel(
            primaryColor: widget.theme.primaryColor,
            rows: [
              ResultRow(label: 'Loan Amount', value: loan, currencyCode: 'GBP'),
              ResultRow(
                  label: 'Equity Amount',
                  value: equityAmt,
                  currencyCode: 'GBP'),
              ResultRow(
                  label: 'Indicative Rate',
                  value: activeTier['rate'] as double,
                  isPercent: false,
                  isHighlighted: true),
              ResultRow(
                  label: 'Rate Tier Limit',
                  value: activeTier['max'] as double,
                  isPercent: false),
            ],
          ),
          const SizedBox(height: 12),

          // Loan vs Equity Visual Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan vs Equity Split',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        if (ltv > 0)
                          Expanded(
                            flex: ltv.clamp(0.0, 100.0).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xFFC8102E),
                                  Color(0xFF991B1B)
                                ]),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${ltv.toStringAsFixed(0)}% Loan',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: Colors.white,
                                    weight: FontWeight.w800),
                              ),
                            ),
                          ),
                        if (ltv < 100)
                          Expanded(
                            flex: (100 - ltv.clamp(0.0, 100.0)).round(),
                            child: Container(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFEEF2FF),
                              alignment: Alignment.center,
                              child: Text(
                                '${(100 - ltv).toStringAsFixed(0)}% Equity',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: widget.theme.getTextColor(context),
                                    weight: FontWeight.w800),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendItem(const Color(0xFFC8102E), 'Loan'),
                    const SizedBox(width: 16),
                    _legendItem(
                        isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEEF2FF),
                        'Equity'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // UK Rate Tiers Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📈 UK Rate Tiers (2025 Best Buys)',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                ...tiers.map((t) {
                  final isCurrent = activeTier == t;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? (isDark
                              ? const Color(0xFF1E1B4B)
                              : const Color(0xFFEEF2FF))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFA5B4FC)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            t['label'] as String,
                            style: AppTextStyles.dmSans(
                                size: 11.5,
                                weight: FontWeight.w800,
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1A1A5E)),
                          ),
                        ),
                        Text(
                          '${t['rate']}%',
                          style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.w800,
                              color: textThemeColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '5-yr fixed indicative',
                            style: AppTextStyles.dmSans(
                                  size: 9.5, color: widget.theme.getMutedColor(context)),
                          ),
                        ),
                        _badgeWidget(
                            t['badge'] as String,
                            isCurrent
                                ? '✓ Your tier'
                                : t['badgeText'] as String),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.dmSans(
              size: 10,
              color: widget.theme.getMutedColor(context),
              weight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _badgeWidget(String badgeType, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    if (badgeType == 'best') {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
      fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
    } else if (badgeType == 'high') {
      bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
    } else if (badgeType == 'current') {
      bg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e);
      fg = isDark ? const Color(0xFF0D0D2B) : Colors.white;
    } else {
      bg = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
      fg = isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style:
            AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _inputField(
      {required String label, required TextEditingController controller}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _calculateValues(),
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5F5F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
