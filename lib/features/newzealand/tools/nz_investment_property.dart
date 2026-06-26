// lib/features/newzealand/tools/nz_investment_property.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZInvestmentProperty extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZInvestmentProperty({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZInvestmentProperty> createState() => _NZInvestmentPropertyState();
}

class _NZInvestmentPropertyState extends ConsumerState<NZInvestmentProperty> {
  final _priceController = TextEditingController(text: '750000');
  final _depositController = TextEditingController(text: '262500');
  final _wkRentController = TextEditingController(text: '620');
  final _intRateController = TextEditingController(text: '6.59');
  final _annExpController = TextEditingController(text: '9500');
  final _capGrowthController = TextEditingController(text: '3.5');

  bool _showResults = true;

  @override
  void dispose() {
    _priceController.dispose();
    _depositController.dispose();
    _wkRentController.dispose();
    _intRateController.dispose();
    _annExpController.dispose();
    _capGrowthController.dispose();
    super.dispose();
  }



  void _saveCalculation() async {
    final double price = double.tryParse(_priceController.text) ?? 750000;
    final double dep = double.tryParse(_depositController.text) ?? 262500;
    final double wkR = double.tryParse(_wkRentController.text) ?? 620;
    final double rate = double.tryParse(_intRateController.text) ?? 6.59;
    final double exp = double.tryParse(_annExpController.text) ?? 9500;
    final double cg = double.tryParse(_capGrowthController.text) ?? 3.5;

    final loan = price - dep;
    final annRent = wkR * 52;
    final annInt = loan * (rate / 100);
    final mgmt = annRent * 0.08;
    final grossY = (annRent / price * 100);
    final netCF = annRent - annInt - exp - mgmt;

    final labelCtrl = TextEditingController(text: 'NZ Rental Investment');
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
              'Saving: Gross Yield: ${grossY.toStringAsFixed(2)}% · Net Cashflow: ${CurrencyFormatter.compact(netCF, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Christchurch Rental)',
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
              backgroundColor: const Color(0xFF1A6B4A),
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
          : 'Investment Property';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Investment Property',
        inputs: {
          'price': price,
          'deposit': dep,
          'wkRent': wkR,
          'intRate': rate,
          'annExp': exp,
          'capGrowth': cg,
        },
        results: {
          'loanAmt': loan,
          'grossYield': grossY,
          'netCashflow': netCF,
          'lvr': loan / price * 100,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Investment analysis saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final double price = double.tryParse(_priceController.text) ?? 750000;
    final double dep = double.tryParse(_depositController.text) ?? 262500;
    final double wkR = double.tryParse(_wkRentController.text) ?? 620;
    final double rate = double.tryParse(_intRateController.text) ?? 6.59;
    final double exp = double.tryParse(_annExpController.text) ?? 9500;
    final double cg = double.tryParse(_capGrowthController.text) ?? 3.5;

    final loan = price - dep;
    final lvr = price > 0 ? (loan / price * 100) : 0.0;
    final annRent = wkR * 52;
    final annInt = loan * (rate / 100);
    final mgmt = annRent * 0.08;
    final grossY = price > 0 ? (annRent / price * 100) : 0.0;
    final netCF = annRent - annInt - exp - mgmt;
    final coc = dep > 0 ? (netCF / dep * 100) : 0.0;
    final totalR = grossY + cg;

    final monthlyRent = annRent / 12;
    final monthlyInt = annInt / 12;
    final topup = netCF / 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Investment Analysis',
              style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                border: Border.all(color: const Color(0xFF5EEAD4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Full Return',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFF0F766E), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E), Color(0xFF1A6B4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVESTMENT PROPERTY · CASH FLOW & TOTAL RETURN',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white70,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 16, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'Full '),
                    TextSpan(text: 'investment return', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: '\nanalysis NZD'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Purchase Price',
                      controller: _priceController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Deposit (LVR 35% min)',
                      controller: _depositController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Weekly Rent',
                      controller: _wkRentController,
                      suffix: '/wk',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Interest Rate',
                      controller: _intRateController,
                      suffix: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Annual Expenses',
                      controller: _annExpController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Expected Cap Growth',
                      controller: _capGrowthController,
                      suffix: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () => setState(() => _showResults = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🏢 Analyse Investment Return',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // KPIs Card
        Text(
          'Investment KPIs',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildKpiBox(
                label: 'Gross Yield',
                val: '${grossY.toStringAsFixed(2)}%',
                sub: 'Annual rent/value',
                isDark: true,
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiBox(
                label: 'Cash-on-Cash',
                val: '${coc.toStringAsFixed(1)}%',
                sub: 'Cashflow/deposit',
                isGreen: true,
                theme: theme,
                customColor: coc >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiBox(
                label: 'Total Return',
                val: '${totalR.toStringAsFixed(1)}%',
                sub: 'Yield + growth',
                isTeal: true,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Waterfall bar chart
        if (_showResults) ...[
          Text(
            'Cash Flow Waterfall',
            style: AppTextStyles.playfair(
                size: 12,
                weight: FontWeight.w800,
                color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Annual Cash Flow Components',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),

                // Rent Income bar
                _buildWaterfallRow(
                  label: 'Rent Income',
                  valText: '+${CurrencyFormatter.format(annRent, currencyCode: 'NZD')}',
                  pct: 1.0,
                  barColors: const [Color(0xFF1A6B4A), Color(0xFF0D9488)],
                  valColor: const Color(0xFF1A6B4A),
                ),
                const SizedBox(height: 10),

                // Interest bar
                _buildWaterfallRow(
                  label: 'Mortgage Interest',
                  valText: '–${CurrencyFormatter.format(annInt, currencyCode: 'NZD')}',
                  pct: annRent > 0 ? (annInt / annRent).clamp(0.0, 1.0) : 0.0,
                  barColors: const [Color(0xFFC0392B), Color(0xFF922B21)],
                  valColor: const Color(0xFFC0392B),
                ),
                const SizedBox(height: 10),

                // Expenses bar
                _buildWaterfallRow(
                  label: 'Expenses',
                  valText: '–${CurrencyFormatter.format(exp, currencyCode: 'NZD')}',
                  pct: annRent > 0 ? (exp / annRent).clamp(0.0, 1.0) : 0.0,
                  barColors: const [Color(0xFFD4A017), Color(0xFFA07810)],
                  valColor: const Color(0xFFD97706),
                ),
                const SizedBox(height: 10),

                // Management fee bar
                _buildWaterfallRow(
                  label: 'Mgmt (8%)',
                  valText: '–${CurrencyFormatter.format(mgmt, currencyCode: 'NZD')}',
                  pct: annRent > 0 ? (mgmt / annRent).clamp(0.0, 1.0) : 0.0,
                  barColors: const [Color(0xFF334155), Color(0xFF475569)],
                  valColor: const Color(0xFF334155),
                ),

                const Divider(height: 20, thickness: 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Annual Cash Flow',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.bold,
                        color: theme.getTextColor(context),
                      ),
                    ),
                    Text(
                      (netCF < 0 ? '–' : '') + CurrencyFormatter.format(netCF.abs(), currencyCode: 'NZD'),
                      style: AppTextStyles.playfair(
                        size: 15,
                        weight: FontWeight.w800,
                        color: netCF >= 0 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Full cost breakdown
          Text(
            'Full Cost Breakdown',
            style: AppTextStyles.playfair(
                size: 12,
                weight: FontWeight.w800,
                color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildCostRow(
                  dotColor: const Color(0xFF1A6B4A),
                  label: 'Loan Amount',
                  note: 'Purchase price minus deposit',
                  val: CurrencyFormatter.format(loan, currencyCode: 'NZD'),
                ),
                const Divider(height: 16),
                _buildCostRow(
                  dotColor: const Color(0xFFD4A017),
                  label: 'LVR Ratio',
                  note: 'Must be ≤65% for investors',
                  val: '${lvr.toStringAsFixed(1)}%',
                  customColor: lvr <= 65 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                ),
                const Divider(height: 16),
                _buildCostRow(
                  dotColor: const Color(0xFF0D9488),
                  label: 'Monthly Rent',
                  note: 'Weekly rent × 52 ÷ 12',
                  val: CurrencyFormatter.format(monthlyRent, currencyCode: 'NZD'),
                  isPositive: true,
                ),
                const Divider(height: 16),
                _buildCostRow(
                  dotColor: const Color(0xFFC0392B),
                  label: 'Monthly Interest',
                  note: 'Interest-only equivalent',
                  val: '–${CurrencyFormatter.format(monthlyInt, currencyCode: 'NZD')}',
                  isPositive: false,
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Top-up',
                              style: AppTextStyles.dmSans(
                                  size: 10.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
                            ),
                            Text(
                              'Cash you need to add monthly',
                              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      (topup < 0 ? '–' : '') + CurrencyFormatter.format(topup.abs(), currencyCode: 'NZD'),
                      style: AppTextStyles.playfair(
                        size: 15,
                        weight: FontWeight.w800,
                        color: topup >= 0 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: _saveCalculation,
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    'Save Investment Analysis',
                    style: AppTextStyles.playfair(size: 12.5, color: Colors.white, weight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 42),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5-Year Property Value Projection
          Text(
            '5-Year Property Value Projection',
            style: AppTextStyles.playfair(
                size: 12,
                weight: FontWeight.w800,
                color: theme.getTextColor(context)),
          ),
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
                Text(
                  'Property Value Growth Forecast',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...[1, 3, 5, 7, 9].map((yr) {
                  final val = price * pow(1 + cg / 100, yr);
                  final maxVal = price * pow(1 + cg / 100, 9);
                  final pct = maxVal > 0 ? (val / maxVal) : 0.0;
                  final barColor = yr <= 3
                      ? const Color(0xFF0D9488)
                      : yr <= 5
                          ? const Color(0xFF1A6B4A)
                          : const Color(0xFFD4A017);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            'Yr $yr',
                            style: AppTextStyles.dmSans(
                              size: 10,
                              weight: FontWeight.bold,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.getBgColor(context),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'NZ\$${(val / 1000).round()}K',
                            style: AppTextStyles.dmSans(
                              size: 10,
                              weight: FontWeight.w800,
                              color: barColor,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // NZ Investor Checklist
        Text(
          'NZ Investor Checklist',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildGuideRow(
                icon: '🛡️',
                title: 'LVR 35% Minimum Deposit',
                desc: 'RBNZ requires residential property investors to have at least 35% deposit (LVR ≤65%). New builds may qualify at 20%. Check with your bank for current exemptions.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '📝',
                title: 'Interest Deductibility Restored',
                desc: 'From 1 April 2025: 100% of mortgage interest is deductible for rental properties again. This significantly improves after-tax returns vs 2023-2024 years.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🔒',
                title: 'Ring-Fencing Still Applies',
                desc: 'Rental losses cannot offset your salary income. Losses are carried forward to offset future rental profits. Factor this into your cash flow planning.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🏠',
                title: 'Healthy Homes Compliance',
                desc: 'All rental properties must meet Healthy Homes Standards (heating, insulation, ventilation, draught stopping, moisture/drainage). Compliance required by July 2025 for all tenancies.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroInputBox({
    required String label,
    required TextEditingController controller,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (suffix.isEmpty)
                Text(
                  'NZ\$ ',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white60, weight: FontWeight.bold),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white60, weight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiBox({
    required String label,
    required String val,
    required String sub,
    bool isDark = false,
    bool isGreen = false,
    bool isTeal = false,
    required CountryTheme theme,
    Color? customColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)])
            : isGreen
                ? const LinearGradient(colors: [Color(0xFF1A6B4A), Color(0xFF0D3B2E)])
                : isTeal
                    ? const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                    : null,
        color: !isDark && !isGreen && !isTeal ? theme.getCardColor(context) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8,
              color: isDark || isGreen || isTeal ? Colors.white70 : theme.getMutedColor(context),
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: AppTextStyles.playfair(
              size: 14,
              weight: FontWeight.w800,
              color: customColor ?? (isDark || isGreen || isTeal ? Colors.white : theme.getTextColor(context)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 7.5,
              color: isDark || isGreen || isTeal ? Colors.white54 : theme.getMutedColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallRow({
    required String label,
    required String valText,
    required double pct,
    required List<Color> barColors,
    required Color valColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.bold,
              color: widget.theme.getTextColor(context),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: barColors),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Text(
            valText,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.w800,
              color: valColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow({
    required Color dotColor,
    required String label,
    required String note,
    required String val,
    bool? isPositive,
    Color? customColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  weight: FontWeight.bold,
                  color: widget.theme.getTextColor(context),
                ),
              ),
              Text(
                note,
                style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        Text(
          val,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w800,
            color: customColor ??
                (isPositive == null
                    ? widget.theme.getTextColor(context)
                    : isPositive
                        ? const Color(0xFF1A6B4A)
                        : const Color(0xFFC0392B)),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideRow({required String icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: widget.theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
