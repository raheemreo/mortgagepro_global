// lib/features/newzealand/tools/nz_rental_yield.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZRentalYieldCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZRentalYieldCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZRentalYieldCalc> createState() => _NZRentalYieldCalcState();
}

class _NZRentalYieldCalcState extends ConsumerState<NZRentalYieldCalc> {
  final _propValController = TextEditingController(text: '750000');
  final _weeklyRentController = TextEditingController(text: '600');
  final _expensesController = TextEditingController(text: '8000');
  final _rateController = TextEditingController(text: '6.59');
  final _loanAmtController = TextEditingController(text: '525000');

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _propValController.dispose();
    _weeklyRentController.dispose();
    _expensesController.dispose();
    _rateController.dispose();
    _loanAmtController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _propValController.text = '750000';
      _weeklyRentController.text = '600';
      _expensesController.text = '8000';
      _rateController.text = '6.59';
      _loanAmtController.text = '525000';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final double val = double.tryParse(_propValController.text) ?? 0.0;
    final double wkRent = double.tryParse(_weeklyRentController.text) ?? 0.0;
    final double exp = double.tryParse(_expensesController.text) ?? 0.0;
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final double loan = double.tryParse(_loanAmtController.text) ?? 0.0;

    if (val <= 0) {
      errors['propVal'] = 'Enter valid property value';
    }
    if (wkRent <= 0) {
      errors['weeklyRent'] = 'Enter valid weekly rent';
    }
    if (exp < 0) {
      errors['expenses'] = 'Expenses cannot be negative';
    }
    if (rate < 0) {
      errors['rate'] = 'Rate cannot be negative';
    }
    if (loan < 0) {
      errors['loanAmt'] = 'Loan cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['propVal'] = val;
      _calcSnapshot['weeklyRent'] = wkRent;
      _calcSnapshot['expenses'] = exp;
      _calcSnapshot['rate'] = rate;
      _calcSnapshot['loanAmt'] = loan;
      _showResults = true;
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

  void _saveCalculation() async {
    final double val = _calcSnapshot['propVal'] ?? (double.tryParse(_propValController.text) ?? 750000.0);
    final double wkRent = _calcSnapshot['weeklyRent'] ?? (double.tryParse(_weeklyRentController.text) ?? 600.0);
    final double exp = _calcSnapshot['expenses'] ?? (double.tryParse(_expensesController.text) ?? 8000.0);
    final double rate = _calcSnapshot['rate'] ?? (double.tryParse(_rateController.text) ?? 6.59);
    final double loan = _calcSnapshot['loanAmt'] ?? (double.tryParse(_loanAmtController.text) ?? 525000.0);

    final annualRent = wkRent * 52;
    final grossYield = (annualRent / val * 100);
    final netIncome = annualRent - exp;
    final netYield = (netIncome / val * 100);

    final labelCtrl = TextEditingController(text: 'NZ Rental Yield');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_rental_yield/save'),
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
              'Saving: Gross Yield ${grossYield.toStringAsFixed(2)}% · Net: ${netYield.toStringAsFixed(2)}%',
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
                hintText: 'Label (e.g. Hamilton Townhouse)',
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
          : 'Rental Yield';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Rental Yield',
        inputs: {
          'propVal': val,
          'weeklyRent': wkRent,
          'expenses': exp,
          'mortgageRate': rate,
          'loanAmt': loan,
        },
        results: {
          'grossYield': grossYield,
          'netYield': netYield,
          'annualRent': annualRent,
          'cashflow': annualRent - exp - (loan * rate / 100) - (annualRent * 0.08),
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rental yield calculation saved!',
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

    // Snapshot variables if results are shown, otherwise live inputs
    final double val = _showResults
        ? (_calcSnapshot['propVal'] ?? 0.0)
        : (double.tryParse(_propValController.text) ?? 0.0);
    final double wkRent = _showResults
        ? (_calcSnapshot['weeklyRent'] ?? 0.0)
        : (double.tryParse(_weeklyRentController.text) ?? 0.0);
    final double exp = _showResults
        ? (_calcSnapshot['expenses'] ?? 0.0)
        : (double.tryParse(_expensesController.text) ?? 0.0);
    final double rate = _showResults
        ? (_calcSnapshot['rate'] ?? 0.0)
        : (double.tryParse(_rateController.text) ?? 0.0);
    final double loan = _showResults
        ? (_calcSnapshot['loanAmt'] ?? 0.0)
        : (double.tryParse(_loanAmtController.text) ?? 0.0);

    final annualRent = wkRent * 52;
    final grossYield = val > 0 ? (annualRent / val * 100) : 0.0;
    final netIncome = annualRent - exp;
    final netYield = val > 0 ? (netIncome / val * 100) : 0.0;
    final mortInt = loan * (rate / 100);
    final mgmt = annualRent * 0.08;
    final cashflow = annualRent - exp - mortInt - mgmt;
    final monthly = cashflow / 12;

    final isDirty = _showResults && (
      (double.tryParse(_propValController.text) ?? 0.0) != (_calcSnapshot['propVal'] ?? 0.0) ||
      (double.tryParse(_weeklyRentController.text) ?? 0.0) != (_calcSnapshot['weeklyRent'] ?? 0.0) ||
      (double.tryParse(_expensesController.text) ?? 0.0) != (_calcSnapshot['expenses'] ?? 0.0) ||
      (double.tryParse(_rateController.text) ?? 0.0) != (_calcSnapshot['rate'] ?? 0.0) ||
      (double.tryParse(_loanAmtController.text) ?? 0.0) != (_calcSnapshot['loanAmt'] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rental Yield Calculator',
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
                'Tax Tools',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFF0F766E), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF0D9488)],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GROSS & NET YIELD · NZ RENTAL PROPERTY',
                    style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: Colors.white70,
                      weight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Text(
                      'Reset ↺',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: const Color(0xFF6EE7B7),
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 16, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'Calculate '),
                    TextSpan(text: 'rental yield', style: TextStyle(color: Color(0xFF6EE7B7))),
                    TextSpan(text: '\n& cash flow'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildHeroInputBox(
                label: 'Property Value / Purchase Price',
                controller: _propValController,
                prefix: 'NZ\$',
                errorText: _errors['propVal'],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Weekly Rent',
                      controller: _weeklyRentController,
                      prefix: 'NZ\$',
                      suffix: '/wk',
                      errorText: _errors['weeklyRent'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Mortgage Rate',
                      controller: _rateController,
                      suffix: '%',
                      errorText: _errors['rate'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Annual Expenses',
                      controller: _expensesController,
                      prefix: 'NZ\$',
                      errorText: _errors['expenses'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Loan Amount',
                      controller: _loanAmtController,
                      prefix: 'NZ\$',
                      errorText: _errors['loanAmt'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🏘️ Calculate Rental Yield',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
          if (isDirty) ...[
            Container(
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
                      'Inputs have changed. Tap Calculate Rental Yield to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yield Summary
                Text(
                  'Yield Summary',
                  style: AppTextStyles.playfair(
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildYieldCard(
                        label: 'Gross Yield',
                        val: '${grossYield.toStringAsFixed(2)}%',
                        sub: 'Annual rent ÷ value',
                        badgeText: grossYield >= 5
                            ? 'Strong ✓'
                            : grossYield >= 4
                                ? 'Moderate'
                                : 'Low',
                        badgeColor: grossYield >= 5
                            ? const Color(0xFF059669)
                            : grossYield >= 4
                                ? const Color(0xFFD4A017)
                                : const Color(0xFFC0392B),
                        cardGradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildYieldCard(
                        label: 'Net Yield',
                        val: '${netYield.toStringAsFixed(2)}%',
                        sub: 'After expenses',
                        badgeText: netYield >= 4
                            ? 'Target Met ✓'
                            : netYield >= 3
                                ? 'Below Target'
                                : 'Low Yield',
                        badgeColor: netYield >= 4
                            ? const Color(0xFF059669)
                            : netYield >= 3
                                ? const Color(0xFFD4A017)
                                : const Color(0xFFC0392B),
                        cardGradient: const LinearGradient(
                          colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cash Flow Analysis
                Text(
                  'Cash Flow Analysis',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Gauge Painter
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: 220,
                              height: 120,
                              child: CustomPaint(
                                painter: _NZRentalYieldGaugePainter(
                                  netYield: netYield,
                                  theme: theme,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      _buildCostRow(
                        dotColor: const Color(0xFF1A6B4A),
                        label: 'Annual Rent Income',
                        note: '52 weeks × weekly rent',
                        val: CurrencyFormatter.format(annualRent, currencyCode: 'NZD'),
                        isPositive: true,
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFFC0392B),
                        label: 'Annual Expenses',
                        note: 'Rates, insurance, maintenance',
                        val: '–${CurrencyFormatter.format(exp, currencyCode: 'NZD')}',
                        isPositive: false,
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFFD4A017),
                        label: 'Mortgage Interest',
                        note: 'Interest-only equivalent',
                        val: '–${CurrencyFormatter.format(mortInt, currencyCode: 'NZD')}',
                        isPositive: false,
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFF334155),
                        label: 'Property Management (8%)',
                        note: 'If using a PM company',
                        val: '–${CurrencyFormatter.format(mgmt, currencyCode: 'NZD')}',
                        isPositive: false,
                      ),
                      const Divider(height: 20, thickness: 1.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Annual Cash Flow',
                            style: AppTextStyles.dmSans(
                              size: 11.5,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context),
                            ),
                          ),
                          Text(
                            (cashflow < 0 ? '–' : '') + CurrencyFormatter.format(cashflow.abs(), currencyCode: 'NZD'),
                            style: AppTextStyles.playfair(
                              size: 15,
                              weight: FontWeight.w800,
                              color: cashflow >= 0 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          cashflow >= 0
                              ? '✅ Positive cash flow of ${CurrencyFormatter.compact(monthly, symbol: 'NZ\$')}/month. This property is self-funding. Strong result in current NZ market.'
                              : '⚠️ Negative cash flow of –${CurrencyFormatter.compact(monthly.abs(), symbol: 'NZ\$')}/month. This property requires top-up from other income. Review interest deductibility rules.',
                          style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        onPressed: _saveCalculation,
                        icon: const Text('💾', style: TextStyle(fontSize: 14)),
                        label: Text(
                          'Save Yield Calculation',
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
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // NZ City Yield Benchmarks
        Text(
          'NZ City Yield Benchmarks',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            _buildBenchmarkCard('Auckland', '3.6%', 'Avg Gross', const Color(0xFFC0392B)),
            _buildBenchmarkCard('Wellington', '4.0%', 'Avg Gross', const Color(0xFFD4A017)),
            _buildBenchmarkCard('Christchurch', '5.1%', 'Avg Gross', const Color(0xFF1A6B4A)),
            _buildBenchmarkCard('Hamilton', '4.8%', 'Avg Gross', const Color(0xFF1A6B4A)),
            _buildBenchmarkCard('Tauranga', '4.2%', 'Avg Gross', const Color(0xFFD4A017)),
            _buildBenchmarkCard('Dunedin', '5.5%', 'Avg Gross', const Color(0xFF1A6B4A)),
          ],
        ),
        const SizedBox(height: 20),

        // NZ Yield Rules of Thumb
        Text(
          'NZ Yield Rules of Thumb',
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
                icon: '🎯',
                title: 'Gross Yield Targets (NZ)',
                desc: '5%+ gross = strong return · 4–5% = moderate · Below 4% = capital growth play. Net yield should be at least 3.5% to cover costs in high-rate environment.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🔢',
                title: 'The 1% Rule (Adapted NZ)',
                desc: 'Weekly rent ÷ purchase price × 52 = gross yield. For a NZ\$750K property, you need ~NZ\$721/wk rent to achieve 5% gross yield.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '📉',
                title: 'Net vs Gross Gap',
                desc: 'Typical NZ deductions reduce gross yield by 1–2%. Rates (~\$2,500–\$5,000/yr), insurance (~\$2,000–\$3,000/yr), maintenance (~1% of value), property management (8% of rent).',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '⚠️',
                title: 'Interest Deductibility (2025)',
                desc: 'From 1 Apr 2024: 80% of mortgage interest is deductible. From 1 Apr 2025: 100% deductible again for most properties. Brightline changes apply — check your property date.',
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
    String prefix = '',
    String suffix = '',
    String? errorText,
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
          height: errorText != null ? 52 : 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (prefix.isNotEmpty)
                      Text(
                        '$prefix ',
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
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              if (errorText != null)
                Text(
                  errorText,
                  style: AppTextStyles.dmSans(size: 7, color: Colors.red[300], weight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYieldCard({
    required String label,
    required String val,
    required String sub,
    required String badgeText,
    required Color badgeColor,
    required Gradient cardGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: AppTextStyles.playfair(size: 22, weight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white54),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow({
    required Color dotColor,
    required String label,
    required String note,
    required String val,
    required bool isPositive,
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
            color: isPositive ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkCard(String city, String yieldVal, String type, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            city,
            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getTextColor(context)),
          ),
          const SizedBox(height: 3),
          Text(
            yieldVal,
            style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: valColor),
          ),
          const SizedBox(height: 2),
          Text(
            type,
            style: AppTextStyles.dmSans(size: 7.5, color: widget.theme.getMutedColor(context)),
          ),
        ],
      ),
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

class _NZRentalYieldGaugePainter extends CustomPainter {
  final double netYield;
  final CountryTheme theme;

  _NZRentalYieldGaugePainter({
    required this.netYield,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final double radius = min(size.width - 20, (size.height - 10) * 2) / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Draw background arc
    final paintBg = Paint()
      ..color = theme.borderColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, pi, pi, false, paintBg);

    // Draw active arc with a colored gradient
    final pct = (netYield / 8.0).clamp(0.0, 1.0);
    final paintFill = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFFC0392B), Color(0xFFD4A017), Color(0xFF1A6B4A)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, pi, pi * pct, false, paintFill);

    // Draw needle
    final angle = -pi + (pct * pi);
    final needleLength = radius - 12;
    final needleTip = Offset(cx + needleLength * cos(angle), cy + needleLength * sin(angle));

    final paintNeedle = Paint()
      ..color = theme.textColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, cy), needleTip, paintNeedle);

    // Needle pivot
    final paintPivot = Paint()..color = theme.textColor;
    canvas.drawCircle(Offset(cx, cy), 6, paintPivot);

    // Text labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, double x, double y, TextAlign align) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 7.5,
          color: theme.mutedColor,
          fontFamily: 'Helvetica Neue',
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          align == TextAlign.left
              ? x
              : align == TextAlign.right
                  ? x - textPainter.width
                  : x - textPainter.width / 2,
          y,
        ),
      );
    }

    drawLabel('0%', cx - radius + 4, cy + 2, TextAlign.center);
    drawLabel('4%', cx, cy - radius - 12, TextAlign.center);
    drawLabel('8%+', cx + radius - 4, cy + 2, TextAlign.center);

    // Large center label
    textPainter.text = TextSpan(
      text: 'Net ${netYield.toStringAsFixed(1)}%',
      style: const TextStyle(
        fontSize: 10,
        color: Color(0xFF0D3B2E),
        fontFamily: 'Palatino',
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - 24));
  }

  @override
  bool shouldRepaint(covariant _NZRentalYieldGaugePainter oldDelegate) {
    return oldDelegate.netYield != netYield;
  }
}
