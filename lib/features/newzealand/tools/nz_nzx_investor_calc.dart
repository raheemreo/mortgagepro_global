// lib/features/newzealand/tools/nz_nzx_investor_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZNZXInvestorCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZNZXInvestorCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZNZXInvestorCalc> createState() => _NZNZXInvestorCalcState();
}

class _NZNZXInvestorCalcState extends ConsumerState<NZNZXInvestorCalc> {
  String _currentTab = 'fif'; // 'fif' | 'pie' | 'nzx'

  // FIF controllers
  final _openValController = TextEditingController(text: '50000');
  final _closeValController = TextEditingController(text: '58000');
  final _divsController = TextEditingController(text: '1200');
  double _fifRate = 30.0;

  // PIE controllers
  final _pieInvestController = TextEditingController(text: '25000');
  final _pieReturnController = TextEditingController(text: '7.5');
  double _piePirRate = 17.5;
  double _pieMarginalRate = 30.0;

  // NZX controllers
  final _buyPriceController = TextEditingController(text: '10000');
  final _sellPriceController = TextEditingController(text: '13500');
  final _nzxDivController = TextEditingController(text: '450');
  final _imputeController = TextEditingController(text: '190');

  bool _showResults = true;

  @override
  void dispose() {
    _openValController.dispose();
    _closeValController.dispose();
    _divsController.dispose();
    _pieInvestController.dispose();
    _pieReturnController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _nzxDivController.dispose();
    _imputeController.dispose();
    super.dispose();
  }

  void _saveCalculation() async {
    final titleCtrl = TextEditingController(
      text: _currentTab == 'fif'
          ? 'NZ FIF Tax Calculation'
          : _currentTab == 'pie'
              ? 'NZ PIE Fund Saving'
              : 'NZX Share Dividend Tax',
    );

    final String detailsText;
    if (_currentTab == 'fif') {
      final double open = double.tryParse(_openValController.text) ?? 50000;
      final double close = double.tryParse(_closeValController.text) ?? 58000;
      final double divs = double.tryParse(_divsController.text) ?? 1200;
      final double fdrIncome = open * 0.05;
      final double cvIncome = max(0.0, close - open) + divs;
      final double fdrTax = fdrIncome * _fifRate / 100;
      final double cvTax = cvIncome * _fifRate / 100;
      final double bestTax = min(fdrTax, cvTax);
      detailsText = 'FIF Opening: ${CurrencyFormatter.compact(open, symbol: 'NZ\$')} · Tax Owed: ${CurrencyFormatter.compact(bestTax, symbol: 'NZ\$')}';
    } else if (_currentTab == 'pie') {
      final double invest = double.tryParse(_pieInvestController.text) ?? 25000;
      final double ret = double.tryParse(_pieReturnController.text) ?? 7.5;
      final double returnAmt = invest * ret / 100;
      final double pieTax = returnAmt * _piePirRate / 100;
      final double margTax = returnAmt * _pieMarginalRate / 100;
      final double saving = margTax - pieTax;
      detailsText = 'PIE Invest: ${CurrencyFormatter.compact(invest, symbol: 'NZ\$')} · Tax Saving: ${CurrencyFormatter.compact(saving, symbol: 'NZ\$')}';
    } else {
      final double sell = double.tryParse(_sellPriceController.text) ?? 13500;
      final double div = double.tryParse(_nzxDivController.text) ?? 450;
      final double imp = double.tryParse(_imputeController.text) ?? 190;
      final double grossDiv = div + imp;
      final double taxOnDiv = max(0.0, grossDiv * 0.30 - imp);
      detailsText = 'Current Value: ${CurrencyFormatter.compact(sell, symbol: 'NZ\$')} · Div Tax: ${CurrencyFormatter.compact(taxOnDiv, symbol: 'NZ\$')}';
    }

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
              detailsText,
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. FIF Portfolio)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
      final label = titleCtrl.text.trim().isNotEmpty
          ? titleCtrl.text.trim()
          : 'NZX Investor Calc';

      final SavedCalc calc;
      if (_currentTab == 'fif') {
        final double open = double.tryParse(_openValController.text) ?? 50000;
        final double close = double.tryParse(_closeValController.text) ?? 58000;
        final double divs = double.tryParse(_divsController.text) ?? 1200;
        final double fdrIncome = open * 0.05;
        final double cvIncome = max(0.0, close - open) + divs;
        final double fdrTax = fdrIncome * _fifRate / 100;
        final double cvTax = cvIncome * _fifRate / 100;
        final double bestTax = min(fdrTax, cvTax);

        calc = SavedCalc.create(
          country: 'New Zealand',
          calcType: 'NZX Investor Calc',
          inputs: {
            'tabIndex': 0.0,
            'openVal': open,
            'closeVal': close,
            'divs': divs,
            'taxRate': _fifRate,
          },
          results: {
            'fdrIncome': fdrIncome,
            'cvIncome': cvIncome,
            'fdrTax': fdrTax,
            'cvTax': cvTax,
            'taxLiability': bestTax,
          },
          label: label,
          currencyCode: 'NZD',
        );
      } else if (_currentTab == 'pie') {
        final double invest = double.tryParse(_pieInvestController.text) ?? 25000;
        final double ret = double.tryParse(_pieReturnController.text) ?? 7.5;
        final double returnAmt = invest * ret / 100;
        final double pieTax = returnAmt * _piePirRate / 100;
        final double margTax = returnAmt * _pieMarginalRate / 100;
        final double saving = margTax - pieTax;

        calc = SavedCalc.create(
          country: 'New Zealand',
          calcType: 'NZX Investor Calc',
          inputs: {
            'tabIndex': 1.0,
            'pieInvest': invest,
            'pieReturn': ret,
            'piePirRate': _piePirRate,
            'pieMarginalRate': _pieMarginalRate,
          },
          results: {
            'annualReturn': returnAmt,
            'pieTax': pieTax,
            'marginalTax': margTax,
            'taxSaving': saving,
          },
          label: label,
          currencyCode: 'NZD',
        );
      } else {
        final double buy = double.tryParse(_buyPriceController.text) ?? 10000;
        final double sell = double.tryParse(_sellPriceController.text) ?? 13500;
        final double div = double.tryParse(_nzxDivController.text) ?? 450;
        final double imp = double.tryParse(_imputeController.text) ?? 190;
        final double gain = sell - buy;
        final double grossDiv = div + imp;
        final double taxOnDiv = max(0.0, grossDiv * 0.30 - imp);
        final double netDiv = div - taxOnDiv;

        calc = SavedCalc.create(
          country: 'New Zealand',
          calcType: 'NZX Investor Calc',
          inputs: {
            'tabIndex': 2.0,
            'buyPrice': buy,
            'sellPrice': sell,
            'nzxDiv': div,
            'imputeCredits': imp,
          },
          results: {
            'capitalGain': gain,
            'grossDividend': grossDiv,
            'taxOnDiv': taxOnDiv,
            'netDividend': netDiv,
          },
          label: label,
          currencyCode: 'NZD',
        );
      }

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Investment tax assessment saved!',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title banner matching HTML layout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Investment Tax & PIE',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                border: Border.all(color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'IRD Rates',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Live NZX Movers Snapshot Box
        _buildNZXMoversSection(),
        const SizedBox(height: 16),

        // PIE Rates PIR shortcuts selector
        _buildPIRSelectorSection(),
        const SizedBox(height: 16),

        // Tab Switchers
        Row(
          children: [
            Expanded(
              child: _buildTabButton(
                tabId: 'fif',
                label: '🌏 FIF / Overseas',
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                tabId: 'pie',
                label: '🥝 PIE Fund',
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                tabId: 'nzx',
                label: '💹 NZX Direct',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Main Calculation Inputs Card
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
                _currentTab == 'fif'
                    ? 'FOREIGN INVESTMENT FUND (FIF) · IRD NZ'
                    : _currentTab == 'pie'
                        ? 'PORTFOLIO INVESTMENT ENTITIES (PIE) · PIR TAX'
                        : 'NZ DIRECT STOCKS · IMPUTATION CREDIT OFFSET',
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
                  style: AppTextStyles.playfair(
                      size: 16, color: Colors.white, weight: FontWeight.w800),
                  children: [
                    const TextSpan(text: 'Calculate your '),
                    TextSpan(
                      text: _currentTab == 'fif'
                          ? 'FIF Tax Liability'
                          : _currentTab == 'pie'
                              ? 'PIE Tax Saving'
                              : 'NZX Dividend Tax',
                      style: const TextStyle(color: Color(0xFF7DD3FC)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inputs based on active tab
              if (_currentTab == 'fif') _buildFIFInputs(),
              if (_currentTab == 'pie') _buildPIEInputs(),
              if (_currentTab == 'nzx') _buildNZXInputs(),

              const SizedBox(height: 12),

              // Calculate Trigger Button (re-runs setstate to refresh outputs)
              ElevatedButton(
                onPressed: () => setState(() => _showResults = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💹 ', style: TextStyle(fontSize: 14)),
                    Text(
                      'Calculate Tax Liability',
                      style: AppTextStyles.playfair(
                          size: 13, color: Colors.white, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Results Card Section
        if (_showResults) ...[
          const SizedBox(height: 20),
          _buildResultsCard(),
        ],

        // Tax Rules Guide matching HTML list
        const SizedBox(height: 20),
        Text(
          'Key NZ Investment Tax Rules',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        _buildTaxRulesGuide(),
      ],
    );
  }

  // Live NZX movers widget
  Widget _buildNZXMoversSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = widget.theme.getCardColor(context);
    final border = Border.all(color: widget.theme.getBorderColor(context));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NZX Top Movers & Indices',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: widget.theme.getTextColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '● Live Snapshot',
                  style: AppTextStyles.dmSans(
                    size: 8,
                    weight: FontWeight.w800,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _buildMoversCell('NZX 50', '11,820', '+0.62%', true),
              _buildMoversCell('FNZ', '\$5.42', '+1.10%', true),
              _buildMoversCell('MEL', '\$7.38', '-0.40%', false),
              _buildMoversCell('AIR', '\$0.72', '+2.80%', true),
              _buildMoversCell('SPK', '\$3.11', '-0.60%', false),
              _buildMoversCell('PCT', '\$1.63', '+0.60%', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoversCell(String sym, String val, String chg, bool up) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sym,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.bold,
              color: widget.theme.getMutedColor(context),
            ),
          ),
          Text(
            val,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.bold,
              color: widget.theme.getTextColor(context),
            ),
          ),
          Text(
            chg,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w800,
              color: up
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                  : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }

  // PIE rates grid widget
  Widget _buildPIRSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PIE Tax Rates (Prescribed Investor Rate)',
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.bold,
            color: widget.theme.getMutedColor(context),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildPIROptionCard(
                rate: 10.5,
                desc: 'Income ≤\$14K',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPIROptionCard(
                rate: 17.5,
                desc: '\$14K–\$48K',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPIROptionCard(
                rate: 28.0,
                desc: 'Over \$48K',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPIROptionCard({required double rate, required String desc}) {
    final isSelected = _piePirRate == rate;
    final cardBg = isSelected
        ? widget.theme.primaryColor
        : widget.theme.getCardColor(context);
    final border = isSelected
        ? Border.all(color: widget.theme.primaryColor, width: 1.5)
        : Border.all(color: widget.theme.getBorderColor(context));

    return InkWell(
      onTap: () {
        setState(() {
          _piePirRate = rate;
          // Auto switch to PIE tab if selected
          _currentTab = 'pie';
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: border,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.theme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: AppTextStyles.playfair(
                size: 16,
                weight: FontWeight.w800,
                color: isSelected ? Colors.white : widget.theme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: AppTextStyles.dmSans(
                size: 8,
                color: isSelected ? Colors.white70 : widget.theme.getMutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String tabId, required String label}) {
    final active = _currentTab == tabId;
    return GestureDetector(
      onTap: () => setState(() {
        _currentTab = tabId;
        _showResults = true; // Auto recalculate with defaults on tab swap
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0EA5E9) : widget.theme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF0284C7) : widget.theme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.bold,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  // Tab inputs - FIF
  Widget _buildFIFInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHeroInputBox(
                label: 'Opening Market Value (NZD)',
                controller: _openValController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeroInputBox(
                label: 'Closing Market Value (NZD)',
                controller: _closeValController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildHeroInputBox(
                label: 'Dividends Received (NZD)',
                controller: _divsController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeroDropdown<double>(
                label: 'Your Tax Rate',
                value: _fifRate,
                items: [
                  DropdownMenuItem(
                      value: 10.5,
                      child: Text('10.5%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 17.5,
                      child: Text('17.5%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 30.0,
                      child: Text('30.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 33.0,
                      child: Text('33.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 39.0,
                      child: Text('39.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                ],
                onChanged: (val) => setState(() => _fifRate = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tab inputs - PIE
  Widget _buildPIEInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHeroInputBox(
                label: 'PIE Fund Investment (NZD)',
                controller: _pieInvestController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeroInputBox(
                label: 'Annual Return Rate (%)',
                controller: _pieReturnController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildHeroDropdown<double>(
                label: 'Your PIR Rate',
                value: _piePirRate,
                items: [
                  DropdownMenuItem(
                      value: 10.5,
                      child: Text('10.5%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 17.5,
                      child: Text('17.5%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 28.0,
                      child: Text('28.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                ],
                onChanged: (val) => setState(() => _piePirRate = val!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeroDropdown<double>(
                label: 'Your Marginal Rate',
                value: _pieMarginalRate,
                items: [
                  DropdownMenuItem(
                      value: 17.5,
                      child: Text('17.5%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 30.0,
                      child: Text('30.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 33.0,
                      child: Text('33.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                  DropdownMenuItem(
                      value: 39.0,
                      child: Text('39.0%',
                          style: AppTextStyles.dmSans(
                              size: 13, color: Colors.white))),
                ],
                onChanged: (val) => setState(() => _pieMarginalRate = val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tab inputs - NZX
  Widget _buildNZXInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHeroInputBox(
                label: 'Shares Bought Price (NZD)',
                controller: _buyPriceController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeroInputBox(
                label: 'Current Value (NZD)',
                controller: _sellPriceController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildHeroInputBox(
                label: 'NZX Dividends (NZD)',
                controller: _nzxDivController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeroInputBox(
                label: 'Imputation Credits (NZD)',
                controller: _imputeController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Standard input boxes helper
  Widget _buildHeroInputBox({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
              size: 8, color: Colors.white70, weight: FontWeight.w600),
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
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.playfair(
                size: 13, color: Colors.white, weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // Dropdown helper
  Widget _buildHeroDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
              size: 8, color: Colors.white70, weight: FontWeight.w600),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF0D3B2E),
              style: AppTextStyles.playfair(
                  size: 12, color: Colors.white, weight: FontWeight.w800),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Colors.white70, size: 18),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  // Results display widget
  Widget _buildResultsCard() {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentTab == 'fif') {
      final double open = double.tryParse(_openValController.text) ?? 50000;
      final double close = double.tryParse(_closeValController.text) ?? 58000;
      final double divs = double.tryParse(_divsController.text) ?? 1200;

      final double fdrIncome = open * 0.05;
      final double cvIncome = max(0.0, close - open) + divs;
      final double fdrTax = fdrIncome * _fifRate / 100;
      final double cvTax = cvIncome * _fifRate / 100;
      final bool fdrBest = fdrTax < cvTax;
      final String bestMethod = fdrBest ? 'FDR' : 'CV';
      final double diff = (fdrTax - cvTax).abs();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.getBorderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 FIF Tax Analysis',
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.bold,
                color: theme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _buildResBox('FDR Deemed Income', fdrIncome, '5% of opening value', const Color(0xFF0EA5E9)),
                _buildResBox('FDR Tax Liability', fdrTax, 'At your $_fifRate% rate', const Color(0xFFC0392B)),
                _buildResBox('CV Actual Income', cvIncome, 'Gain + dividends', const Color(0xFF0EA5E9)),
                _buildResBox('CV Tax Liability', cvTax, 'At your $_fifRate% rate', const Color(0xFFC0392B)),
              ],
            ),
            const SizedBox(height: 16),

            // Comparison list
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.getBgColor(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIF Method Comparison — Best Option',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildComparisonRow(
                    icon: '📊',
                    label: 'FDR Method (5% deemed)',
                    tax: fdrTax,
                    isBest: fdrBest,
                  ),
                  const SizedBox(height: 8),
                  _buildComparisonRow(
                    icon: '📈',
                    label: 'CV Method (actual gain)',
                    tax: cvTax,
                    isBest: !fdrBest,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use $bestMethod method — saves ${CurrencyFormatter.format(diff, currencyCode: 'NZD')} this year',
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      weight: FontWeight.bold,
                      color: isDark ? const Color(0xFF86EFAC) : widget.theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveCalculation,
              icon: const Text('💾', style: TextStyle(fontSize: 14)),
              label: Text(
                'Save This Calculation',
                style: AppTextStyles.playfair(
                    size: 12.5, color: Colors.white, weight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
          ],
        ),
      );
    } else if (_currentTab == 'pie') {
      final double invest = double.tryParse(_pieInvestController.text) ?? 25000;
      final double ret = double.tryParse(_pieReturnController.text) ?? 7.5;

      final double returnAmt = invest * ret / 100;
      final double pieTax = returnAmt * _piePirRate / 100;
      final double margTax = returnAmt * _pieMarginalRate / 100;
      final double saving = margTax - pieTax;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.getBorderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 PIE Fund Tax Analysis',
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.bold,
                color: theme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _buildResBox('Annual Return', returnAmt, '$ret% on ${CurrencyFormatter.compact(invest, symbol: 'NZ\$')}', const Color(0xFF1A6B4A)),
                _buildResBox('PIE Tax (PIR)', pieTax, '$_piePirRate% PIR rate', const Color(0xFFC0392B)),
                _buildResBox('Marginal Tax (direct)', margTax, '$_pieMarginalRate% marginal rate', const Color(0xFFC0392B)),
                _buildResBox('PIE Tax Saving', saving, 'Annual benefit', const Color(0xFF1A6B4A)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveCalculation,
              icon: const Text('💾', style: TextStyle(fontSize: 14)),
              label: Text(
                'Save This Calculation',
                style: AppTextStyles.playfair(
                    size: 12.5, color: Colors.white, weight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
          ],
        ),
      );
    } else {
      final double buy = double.tryParse(_buyPriceController.text) ?? 10000;
      final double sell = double.tryParse(_sellPriceController.text) ?? 13500;
      final double div = double.tryParse(_nzxDivController.text) ?? 450;
      final double imp = double.tryParse(_imputeController.text) ?? 190;

      final double gain = sell - buy;
      final double grossDiv = div + imp;
      final double taxOnDiv = max(0.0, grossDiv * 0.30 - imp);
      final double netDiv = div - taxOnDiv;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.getBorderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 NZX Shares Tax Analysis',
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.bold,
                color: theme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _buildResBox('Capital Gain', gain, 'Generally tax-free (NZ)', const Color(0xFF1A6B4A)),
                _buildResBox('Gross Dividend', grossDiv, 'Div + imputation credits', const Color(0xFF0EA5E9)),
                _buildResBox('Tax on Dividends', taxOnDiv, 'After imputation credits', const Color(0xFFC0392B)),
                _buildResBox('Net Div After Tax', netDiv, 'In your hand', const Color(0xFF1A6B4A)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveCalculation,
              icon: const Text('💾', style: TextStyle(fontSize: 14)),
              label: Text(
                'Save This Calculation',
                style: AppTextStyles.playfair(
                    size: 12.5, color: Colors.white, weight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildResBox(String label, double val, String sub, Color valColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color displayColor = valColor;
    if (isDark) {
      if (valColor == const Color(0xFFC0392B)) {
        displayColor = const Color(0xFFFCA5A5);
      } else if (valColor == const Color(0xFF1A6B4A)) {
        displayColor = const Color(0xFF86EFAC);
      } else if (valColor == const Color(0xFF0EA5E9)) {
        displayColor = const Color(0xFF7DD3FC);
      }
    } else {
      if (valColor == const Color(0xFF0EA5E9)) {
        displayColor = const Color(0xFF0284C7);
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w600,
              color: widget.theme.getMutedColor(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            CurrencyFormatter.format(val, currencyCode: 'NZD'),
            style: AppTextStyles.playfair(
              size: 15,
              weight: FontWeight.w800,
              color: displayColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 8,
              color: widget.theme.getMutedColor(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String icon,
    required String label,
    required double tax,
    required bool isBest,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = widget.theme.getTextColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isBest
            ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF))
            : widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBest
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD))
              : widget.theme.getBorderColor(context),
          width: isBest ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(
                size: 10,
                weight: isBest ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.format(tax, currencyCode: 'NZD'),
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.bold,
              color: isBest
                  ? (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7))
                  : textColor,
            ),
          ),
          const SizedBox(width: 6),
          if (isBest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '✓ Best',
                style: AppTextStyles.dmSans(
                  size: 8,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.theme.getBgColor(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Higher',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme.getMutedColor(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaxRulesGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          _buildGuideRow(
            icon: '🌏',
            title: 'FIF — Foreign Investment Fund',
            desc:
                'Applies to overseas shares over NZD \$50,000 cost threshold. Choose FDR (5% of opening value) or Comparative Value (actual gain) — use whichever gives lower tax.',
          ),
          const Divider(height: 16),
          _buildGuideRow(
            icon: '🥝',
            title: 'PIE Funds — Tax at PIR Rate',
            desc:
                'Portfolio Investment Entities are taxed at your Prescribed Investor Rate (10.5%, 17.5% or 28%). PIE tax is a final tax — no top-up required even if your marginal rate is higher.',
          ),
          const Divider(height: 16),
          _buildGuideRow(
            icon: '💹',
            title: 'NZX Direct Shares — No CGT',
            desc:
                'NZ has no capital gains tax on NZX shares for passive investors. Dividends are taxable income. Imputation credits from company tax can offset your tax tax bill.',
          ),
          const Divider(height: 16),
          _buildGuideRow(
            icon: '📊',
            title: '\$50K FIF Threshold',
            desc:
                'If overseas shares cost ≤ NZD \$50,000, FIF rules don\'t apply — dividends taxed as ordinary income, capital gains generally tax-free. Threshold applies per person.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow({
    required String icon,
    required String title,
    required String desc,
  }) {
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
          child: Text(icon, style: const TextStyle(fontSize: 16)),
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
              const SizedBox(height: 3),
              Text(
                desc,
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: widget.theme.getMutedColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
