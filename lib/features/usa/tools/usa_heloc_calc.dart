// lib/features/usa/tools/usa_heloc_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAHelocCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAHelocCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAHelocCalc> createState() => _USAHelocCalcState();
}

class _USAHelocCalcState extends ConsumerState<USAHelocCalc> {
  final _homeValController = TextEditingController(text: '550000');
  final _mortBalController = TextEditingController(text: '320000');
  final _rateController = TextEditingController(text: '9.18');
  final _drawAmtController = TextEditingController(text: '50000');
  final _drawYrsController = TextEditingController(text: '10');
  final _repayYrsController = TextEditingController(text: '20');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final controllers = [
      _homeValController,
      _mortBalController,
      _rateController,
      _drawAmtController,
      _drawYrsController,
      _repayYrsController,
    ];
    for (final c in controllers) {
      c.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _homeValController.dispose();
    _mortBalController.dispose();
    _rateController.dispose();
    _drawAmtController.dispose();
    _drawYrsController.dispose();
    _repayYrsController.dispose();
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

  double _calcPI(double loan, double rate, double yrs) {
    final mo = rate / 1200;
    final n = yrs * 12;
    return mo == 0 ? loan / n : loan * mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1);
  }

  void _resetInputs() {
    setState(() {
      _homeValController.text = '550000';
      _mortBalController.text = '320000';
      _rateController.text = '9.18';
      _drawAmtController.text = '50000';
      _drawYrsController.text = '10';
      _repayYrsController.text = '20';
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _calculate() async {
    final hv = _val(_homeValController);
    final mb = _val(_mortBalController);
    final draw = _val(_drawAmtController);

    if (mb >= hv) {
      _showError('⚠️ Mortgage balance exceeds home value');
      return;
    }
    if (draw <= 0) {
      _showError('⚠️ Draw amount must be greater than 0');
      return;
    }

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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveCalculation() async {
    final hv = _val(_homeValController);
    final mb = _val(_mortBalController);
    final rate = _val(_rateController);
    final draw = _val(_drawAmtController);
    final drawYrs = _val(_drawYrsController);
    final repayYrs = _val(_repayYrsController);

    final maxCLTV = 0.85 * hv;
    final maxLine = max(0.0, maxCLTV - mb);
    final actualDraw = min(draw, maxLine);
    final drawPmt = actualDraw * (rate / 1200);
    final repayPmt = _calcPI(actualDraw, rate, repayYrs);

    final labelCtrl = TextEditingController(text: 'HELOC');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_heloc_calc/save'),
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
              'Saving: HELOC Line: ${CurrencyFormatter.compact(maxLine, symbol: r'$')} · Draw: ${CurrencyFormatter.compact(drawPmt, symbol: r'$')}/mo · Repay: ${CurrencyFormatter.compact(repayPmt, symbol: r'$')}/mo',
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
                hintText: 'Label (e.g. My HELOC Estimate)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'HELOC';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HELOC Calculator',
        inputs: {
          'HomeVal': hv,
          'MortBal': mb,
          'Rate': rate,
          'DrawAmt': draw,
          'DrawYrs': drawYrs,
          'RepayYrs': repayYrs,
        },
        results: {
          'CreditLine': maxLine,
          'DrawPmt': drawPmt,
          'RepayPmt': repayPmt,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ HELOC saved successfully!',
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

    final hv = _val(_homeValController);
    final mb = _val(_mortBalController);
    final rate = _val(_rateController);
    final draw = _val(_drawAmtController);
    final drawYrs = _val(_drawYrsController);
    final repayYrs = _val(_repayYrsController);

    final maxCLTV = 0.85 * hv;
    final maxLine = max(0.0, maxCLTV - mb);
    final actualDraw = min(draw, maxLine);
    final cltv = hv > 0 ? ((mb + actualDraw) / hv * 100) : 0.0;
    final equity = max(0.0, hv - mb);

    final drawPmt = actualDraw * (rate / 1200);
    final repayPmt = _calcPI(actualDraw, rate, repayYrs);
    final totalIntDraw = drawPmt * drawYrs * 12;
    final totalIntRepay = repayPmt * repayYrs * 12 - actualDraw;
    final totalInt = totalIntDraw + totalIntRepay;

    final double mbPct = hv > 0 ? min(mb / hv * 100, 100) : 0.0;
    final double drawPct = hv > 0 ? min(actualDraw / hv * 100, 100) : 0.0;
    final double availPct = hv > 0 ? max(0.0, min((maxLine - actualDraw) / hv * 100, 100)) : 0.0;
    final double eqPct = max(0.0, 100.0 - mbPct - drawPct - availPct);

    // Color warning if repay jumps significantly
    final jumpPct = drawPmt > 0 ? ((repayPmt - drawPmt) / drawPmt * 100) : 0.0;
    final repayColor = jumpPct > 50 ? Colors.red : (jumpPct > 25 ? Colors.orange : theme.getTextColor(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate strip header — Live Prime Rate from FRED
        LightRateStripBanner(items: [
          RateStripItem(label: 'Prime Rate', provider: fredPrimeProvider, fallback: 8.50),
          RateStripItem(label: 'HELOC Avg\n(Prime+0.5%)', provider: fredPrimeProvider, fallback: 9.18),
          RateStripItem(label: 'Max CLTV', provider: fredMortgage30Provider, fallback: 85, suffix: '', isGold: true),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 16),

        Text('HELOC SETUP', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(_homeValController, 'HOME VALUE', r'$'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(_mortBalController, 'MORTGAGE BALANCE', r'$'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(_rateController, 'HELOC RATE (APR)', '', suffix: '%'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(_drawAmtController, 'DRAW AMOUNT', r'$'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(_drawYrsController, 'DRAW PERIOD', '', suffix: 'yrs'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(_repayYrsController, 'REPAY PERIOD', '', suffix: 'yrs'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
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
                            : Text('🏦 Calculate HELOC', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _resetInputs,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Reset', style: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context), weight: FontWeight.bold)),
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
          // Results Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AVAILABLE CREDIT LINE', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(CurrencyFormatter.format(maxLine, symbol: r'$'),
                    style: AppTextStyles.playfair(size: 36, color: Colors.white, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('CLTV: ${cltv.toStringAsFixed(1)}% · 85% max allowed${actualDraw < draw ? ' · Draw capped at max line' : ''}',
                    style: AppTextStyles.dmSans(size: 10, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroStatItem('Draw Payment', '${CurrencyFormatter.format(drawPmt, symbol: r'$')}/mo'),
                    _buildHeroStatItem('Repay Payment', '${CurrencyFormatter.format(repayPmt, symbol: r'$')}/mo'),
                    _buildHeroStatItem('Total Interest', CurrencyFormatter.compact(totalInt, symbol: r'$'), color: const Color(0xFFFCD34D)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Home Equity Breakdown stacked bar
          Text('HOME EQUITY BREAKDOWN', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 28,
                    color: theme.getBgColor(context),
                    child: Row(
                      children: [
                        if (mbPct > 0)
                          Container(
                            width: (MediaQuery.of(context).size.width - 64) * (mbPct / 100),
                            color: const Color(0xFF1B3F72),
                            alignment: Alignment.center,
                            child: Text(mbPct > 12 ? 'Mortgage' : 'M', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.bold)),
                          ),
                        if (drawPct > 0)
                          Container(
                            width: (MediaQuery.of(context).size.width - 64) * (drawPct / 100),
                            color: const Color(0xFF0F766E),
                            alignment: Alignment.center,
                            child: Text(drawPct > 12 ? 'HELOC' : 'H', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.bold)),
                          ),
                        if (availPct > 0)
                          Container(
                            width: (MediaQuery.of(context).size.width - 64) * (availPct / 100),
                            color: const Color(0xFF5EEAD4),
                            alignment: Alignment.center,
                            child: Text(availPct > 12 ? 'Available' : 'A', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF0B1D3A), weight: FontWeight.bold)),
                          ),
                        if (eqPct > 0)
                          Container(
                            width: (MediaQuery.of(context).size.width - 64) * (eqPct / 100),
                            color: const Color(0xFFE0F2F1),
                            alignment: Alignment.center,
                            child: Text(eqPct > 12 ? 'Equity' : 'E', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF0B1D3A), weight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildLegendItem('Mortgage Balance', const Color(0xFF1B3F72), theme, context),
                    _buildLegendItem('HELOC Draw', const Color(0xFF0F766E), theme, context),
                    _buildLegendItem('Available HELOC', const Color(0xFF5EEAD4), theme, context),
                    _buildLegendItem('Protected Equity', const Color(0xFFE0F2F1), theme, context),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HOME EQUITY', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(CurrencyFormatter.format(equity, symbol: r'$'), style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context), weight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MAX LINE (85% CLTV)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(CurrencyFormatter.format(maxLine, symbol: r'$'), style: AppTextStyles.playfair(size: 15, color: const Color(0xFF0F766E), weight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Timeline Blocks
          Text('MONTHLY PAYMENT TIMELINE', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
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
                Row(
                  children: [
                    Expanded(
                      flex: drawYrs.toInt(),
                      child: Container(
                        height: 52,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Draw Phase', style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.bold)),
                            Text('${CurrencyFormatter.format(drawPmt, symbol: r'$')}/mo', style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      flex: repayYrs.toInt(),
                      child: Container(
                        height: 52,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                          borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Repay Phase', style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.bold)),
                            Text('${CurrencyFormatter.format(repayPmt, symbol: r'$')}/mo', style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Draw: Yr 1–${drawYrs.toInt()} (Interest-only)', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                    Text('Repay: Yr ${drawYrs.toInt() + 1}–${(drawYrs + repayYrs).toInt()} (P+I)', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Draw Phase Payments', '${CurrencyFormatter.format(drawPmt, symbol: r'$')}/mo', 'Interest-only', theme, context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Repay Phase Payments', '${CurrencyFormatter.format(repayPmt, symbol: r'$')}/mo', 'Principal + Interest', theme, context, valueColor: repayColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Key Facts List
        Text('KEY HELOC FACTS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildFactCard('🔄', 'Variable Rate (Prime + Margin)', 'Rates fluctuate with Fed decisions · budget for increases', theme, context),
        _buildFactCard('📋', '85% CLTV Standard Limit', 'Combined Loan-To-Value · some local credit unions allow up to 90%', theme, context),
        _buildFactCard('💰', 'Tax Deduction Opportunity', 'Interest may be tax deductible if funds are used to build/improve the home', theme, context),
        _buildFactCard('⚠️', 'Repayment Phase Payment Shock', 'P&I payments can jump 40-80% compared to interest-only draw phase', theme, context),
      ],
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, String prefix, {String suffix = ''}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              if (prefix.isNotEmpty)
                Text(prefix, style: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context))),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
              if (suffix.isNotEmpty)
                Text(suffix, style: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.playfair(size: 14, color: color ?? Colors.white, weight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, CountryTheme theme, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String sub, CountryTheme theme, BuildContext context, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15, color: valueColor ?? theme.getTextColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildFactCard(String icon, String title, String subtitle, CountryTheme theme, BuildContext context) {
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


