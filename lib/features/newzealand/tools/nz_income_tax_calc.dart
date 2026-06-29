// lib/features/newzealand/tools/nz_income_tax_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZIncomeTaxCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZIncomeTaxCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZIncomeTaxCalc> createState() => _NZIncomeTaxCalcState();
}

class _NZIncomeTaxCalcState extends ConsumerState<NZIncomeTaxCalc> {
  final _incomeController = TextEditingController(text: '75000');

  int _frequency = 12; // 52 = Weekly, 26 = Fortnightly, 12 = Monthly, 1 = Annual
  double _ksRate = 3.0; // 0, 3, 4, 6, 8, 10
  bool _studentLoan = false;
  bool _accLevy = true;
  bool _secondaryTax = false;

  final bool _showResults = true;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _saveCalculation(
    double gross,
    double paye,
    double acc,
    double ks,
    double sl,
    double net,
    double takeHome,
  ) async {
    final labelCtrl = TextEditingController(text: 'NZ PAYE Tax Calculation');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_income_tax_calc/save'),
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
              'Gross: ${CurrencyFormatter.compact(gross, symbol: 'NZ\$')} · Take-Home: ${CurrencyFormatter.compact(takeHome, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. My Monthly Take-home)',
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
          : 'Income Tax Calc';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Income Tax Calc',
        inputs: {
          'gross': gross,
          'freq': _frequency.toDouble(),
          'ksRate': _ksRate,
          'studentLoan': _studentLoan ? 1.0 : 0.0,
          'accLevy': _accLevy ? 1.0 : 0.0,
        },
        results: {
          'paye': paye,
          'acc': acc,
          'ks': ks,
          'sl': sl,
          'netAnnual': net,
          'takeHome': takeHome,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tax calculation saved!',
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

    final double income = double.tryParse(_incomeController.text) ?? 75000;

    // PAYE brackets 2025-26
    double tax = 0;
    if (income > 180000) tax += (income - 180000) * 0.39;
    if (income > 70000) tax += min(income - 70000, 110000) * 0.33;
    if (income > 48000) tax += min(income - 48000, 22000) * 0.30;
    if (income > 14000) tax += min(income - 14000, 34000) * 0.175;
    tax += min(income, 14000) * 0.105;

    final double acc = _accLevy ? min(income, 139384) * 0.016 : 0.0;
    final double ks = income * _ksRate / 100;
    final double slDeduct = _studentLoan ? max(0.0, income - 22828) * 0.12 : 0.0;
    final double netAnnual = income - tax - acc - ks - slDeduct;

    final int periodDivider = _frequency == 1
        ? 1
        : _frequency == 12
            ? 12
            : _frequency == 26
                ? 26
                : 52;
    final double takeHome = netAnnual / periodDivider;

    final Map<int, String> freqLabels = {
      52: 'week',
      26: 'fortnight',
      12: 'month',
      1: 'year'
    };

    final double effRate = income > 0 ? ((tax + acc + ks + slDeduct) / income * 100) : 0.0;
    final double taxPct = income > 0 ? (tax / income * 100) : 0.0;
    final double accPct = income > 0 ? (acc / income * 100) : 0.0;
    final double ksPct = income > 0 ? (ks / income * 100) : 0.0;
    final double slPct = income > 0 ? (slDeduct / income * 100) : 0.0;
    final double netPct = income > 0 ? (netAnnual / income * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYE & ACC Calculator',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border.all(color: const Color(0xFFA7F3D0)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'FY2025–26',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: const Color(0xFF065F46),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Calculator Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
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
                'NEW ZEALAND PAYE · ACC · KIWISAVER · IRD 2025–26',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white70,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  text: 'Calculate Your ',
                  style: AppTextStyles.playfair(size: 16, weight: FontWeight.w800, color: Colors.white),
                  children: [
                    TextSpan(
                      text: 'Take-Home Pay',
                      style: AppTextStyles.playfair(size: 16, weight: FontWeight.w800, color: const Color(0xFFF5D060)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ANNUAL INCOME (NZD)',
                            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: TextField(
                            controller: _incomeController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 11),
                            ),
                            onChanged: (_) => setState(() {}),
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
                        Text('PAY FREQUENCY',
                            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _frequency,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0D3B2E),
                              iconEnabledColor: Colors.white,
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 52, child: Text('Weekly')),
                                DropdownMenuItem(value: 26, child: Text('Fortnightly')),
                                DropdownMenuItem(value: 12, child: Text('Monthly')),
                                DropdownMenuItem(value: 1, child: Text('Annual')),
                              ],
                              onChanged: (val) => setState(() => _frequency = val ?? 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KIWISAVER RATE',
                            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _ksRate,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0D3B2E),
                              iconEnabledColor: Colors.white,
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 0.0, child: Text('Not enrolled')),
                                DropdownMenuItem(value: 3.0, child: Text('3% (minimum)')),
                                DropdownMenuItem(value: 4.0, child: Text('4%')),
                                DropdownMenuItem(value: 6.0, child: Text('6%')),
                                DropdownMenuItem(value: 8.0, child: Text('8%')),
                                DropdownMenuItem(value: 10.0, child: Text('10%')),
                              ],
                              onChanged: (val) => setState(() => _ksRate = val ?? 3.0),
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
                        Text('STUDENT LOAN',
                            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: _studentLoan,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0D3B2E),
                              iconEnabledColor: Colors.white,
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: false, child: Text('No')),
                                DropdownMenuItem(value: true, child: Text('Yes — 12%')),
                              ],
                              onChanged: (val) => setState(() => _studentLoan = val ?? false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'Secondary income / other deductions',
                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      label: 'ACC Levy',
                      value: _accLevy,
                      onTap: () => setState(() => _accLevy = !_accLevy),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Secondary Tax',
                      value: _secondaryTax,
                      onTap: () => setState(() => _secondaryTax = !_secondaryTax),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Card
        if (_showResults) ...[
          Text(
            'Your PAYE Breakdown',
            style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Take Home Pay Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TAKE-HOME PAY',
                        style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.compact(takeHome, symbol: 'NZ\$'),
                        style: AppTextStyles.playfair(
                            size: 32, weight: FontWeight.w800, color: const Color(0xFFF5D060)),
                      ),
                      Text(
                        'per ${freqLabels[_frequency]}',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Grid Details
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.8,
                  children: [
                    _buildResultBox('Gross Income', CurrencyFormatter.compact(income, symbol: 'NZ\$'), 'Annual / year', theme.getTextColor(context)),
                    _buildResultBox('Total Tax (PAYE)', CurrencyFormatter.compact(tax, symbol: 'NZ\$'), 'Annual PAYE', const Color(0xFFC0392B)),
                    _buildResultBox('ACC Levy', CurrencyFormatter.compact(acc, symbol: 'NZ\$'), '1.60% of income', const Color(0xFFC2410C)),
                    _buildResultBox('KiwiSaver', CurrencyFormatter.compact(ks, symbol: 'NZ\$'), 'Your contribution', const Color(0xFFD4A017)),
                    _buildResultBox('Effective Tax Rate', '${effRate.toStringAsFixed(1)}%', 'All deductions', theme.getTextColor(context)),
                    _buildResultBox('Net Annual', CurrencyFormatter.compact(netAnnual, symbol: 'NZ\$'), 'After deductions', const Color(0xFF1A6B4A)),
                  ],
                ),
                const SizedBox(height: 16),

                // Breakdown list bars
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
                        'Where Your Dollar Goes',
                        style: AppTextStyles.dmSans(
                            size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 10),
                      _buildBreakdownRow('PAYE Tax', tax, income, taxPct, const Color(0xFFC0392B)),
                      _buildBreakdownRow('ACC Levy', acc, income, accPct, const Color(0xFFD97706)),
                      if (_ksRate > 0)
                        _buildBreakdownRow('KiwiSaver', ks, income, ksPct, const Color(0xFFD4A017)),
                      if (_studentLoan)
                        _buildBreakdownRow('Student Loan', slDeduct, income, slPct, const Color(0xFF0EA5E9)),
                      _buildBreakdownRow('Take-Home', netAnnual, income, netPct, const Color(0xFF1A6B4A)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () => _saveCalculation(income, tax, acc, ks, slDeduct, netAnnual, takeHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor, width: 1.5),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text('Save Calculation',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: theme.primaryColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Tax brackets 2025-26
        Text(
          'NZ PAYE Tax Brackets 2025–26',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('INCOME BAND', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: Colors.white70))),
                    Expanded(child: Text('RATE', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: Colors.white70))),
                    Expanded(child: Text('TAX IN BAND', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: Colors.white70))),
                  ],
                ),
              ),
              _buildBracketRow('\$0 – \$14,000', '10.5%', '\$1,470', income <= 14000),
              _buildBracketRow('\$14,001 – \$48,000', '17.5%', '\$5,950', income > 14000 && income <= 48000),
              _buildBracketRow('\$48,001 – \$70,000', '30%', '\$6,600', income > 48000 && income <= 70000),
              _buildBracketRow('\$70,001 – \$180,000', '33%', 'up to \$36,300', income > 70000 && income <= 180000),
              _buildBracketRow('\$180,001+', '39%', '39¢ per \$1', income > 180000),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildToggleButton({required String label, required bool value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: value ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.18),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.bold,
            color: value ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox(String title, String val, String sub, Color valColor) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.dmSans(size: 7.5, color: theme.getMutedColor(context), weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: valColor),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double val, double total, double pct, Color color) {
    final theme = widget.theme;
    final displayPct = total > 0 ? (val / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context)),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 20,
                color: const Color(0xFFE8F0EC),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: displayPct,
                  child: Container(
                    padding: const EdgeInsets.only(left: 7),
                    alignment: Alignment.centerLeft,
                    color: color,
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              CurrencyFormatter.compact(val, symbol: 'NZ\$'),
              textAlign: TextAlign.right,
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketRow(String band, String rate, String inBand, bool active) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: active ? theme.primaryColor.withValues(alpha: 0.07) : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  band,
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: active ? FontWeight.bold : FontWeight.normal,
                    color: theme.getTextColor(context),
                  ),
                ),
                if (active)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(10)),
                    child: Text('Active', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white, weight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              rate,
              style: AppTextStyles.dmSans(
                size: 11,
                weight: active ? FontWeight.bold : FontWeight.normal,
                color: theme.getTextColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              inBand,
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.bold,
                color: active ? theme.primaryColor : theme.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
