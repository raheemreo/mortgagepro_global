// lib/features/newzealand/tools/nz_employer_contrib.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZEmployerContrib extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZEmployerContrib({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZEmployerContrib> createState() => _NZEmployerContribState();
}

class _NZEmployerContribState extends ConsumerState<NZEmployerContrib> {
  final _salaryController = TextEditingController(text: '75000');
  int _payFreq = 26; // 52 = weekly, 26 = fortnightly, 12 = monthly
  int _empExtra = 0; // 0 = 3%, 1 = 4%, 2 = 5%
  double _contribRate = 3.0; // 3, 4, 6, 8, 10
  double _taxRate = 17.5; // marginal ESCT tax rate

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _salaryController.text = '75000';
      _payFreq = 26;
      _empExtra = 0;
      _contribRate = 3.0;
      _taxRate = 17.5;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final salary = double.tryParse(_salaryController.text) ?? 0.0;

    if (salary <= 0) {
      errors['salary'] = 'Enter valid annual gross salary';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['salary'] = salary;
      _calcSnapshot['payFreq'] = _payFreq;
      _calcSnapshot['empExtra'] = _empExtra;
      _calcSnapshot['contribRate'] = _contribRate;
      _calcSnapshot['taxRate'] = _taxRate;
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
    final double snapSalary = _calcSnapshot['salary'] ?? (double.tryParse(_salaryController.text) ?? 75000.0);
    final double snapTaxRate = _calcSnapshot['taxRate'] ?? _taxRate;
    final int snapEmpExtra = _calcSnapshot['empExtra'] ?? _empExtra;
    final double snapContribRate = _calcSnapshot['contribRate'] ?? _contribRate;

    final esct = snapTaxRate / 100;
    final empRate = 0.03 + (snapEmpExtra / 100);

    final annualYou = snapSalary * (snapContribRate / 100);
    final annualEmpGross = snapSalary * empRate;
    final annualEmpNet = annualEmpGross * (1 - esct);
    final annualGovt = min(annualYou * 0.5, 521.43);
    final annualTotal = annualYou + annualEmpNet + annualGovt;
    final annualESCT = annualEmpGross - annualEmpNet;
    final empFree = annualEmpNet + annualGovt;

    final inputs = <String, double>{
      'salary': snapSalary,
      'payFreq': (_calcSnapshot['payFreq'] ?? _payFreq).toDouble(),
      'empExtra': snapEmpExtra.toDouble(),
      'contribRate': snapContribRate,
      'taxRate': snapTaxRate,
    };
    final results = <String, double>{
      'annualTotal': annualTotal,
      'employerFree': empFree,
      'annualYou': annualYou,
      'annualESCT': annualESCT,
    };

    final labelCtrl = TextEditingController(text: 'NZ KiwiSaver Match');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_employer_contrib/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save KiwiSaver Details',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total KiwiSaver: ${CurrencyFormatter.compact(annualTotal, symbol: 'NZ\$')}/yr · Free money: ${CurrencyFormatter.compact(empFree, symbol: 'NZ\$')}/yr',
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
                hintText: 'Label (e.g. My KiwiSaver Match)',
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
          : 'KiwiSaver Match';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Employer Contrib',
        inputs: inputs,
        results: results,
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Savings profile saved!',
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

    final double rawSalary = double.tryParse(_salaryController.text) ?? 75000;
    final int rawPayFreq = _payFreq;
    final int rawEmpExtra = _empExtra;
    final double rawContribRate = _contribRate;
    final double rawTaxRate = _taxRate;

    final double salary = _showResults ? (_calcSnapshot['salary'] ?? rawSalary) : rawSalary;
    final int payFreq = _showResults ? (_calcSnapshot['payFreq'] ?? rawPayFreq) : rawPayFreq;
    final int empExtra = _showResults ? (_calcSnapshot['empExtra'] ?? rawEmpExtra) : rawEmpExtra;
    final double contribRate = _showResults ? (_calcSnapshot['contribRate'] ?? rawContribRate) : rawContribRate;
    final double taxRate = _showResults ? (_calcSnapshot['taxRate'] ?? rawTaxRate) : rawTaxRate;

    final esct = taxRate / 100;
    final empRate = 0.03 + (empExtra / 100);

    final annualYou = salary * (contribRate / 100);
    final annualEmpGross = salary * empRate;
    final annualEmpNet = annualEmpGross * (1 - esct);
    final annualGovt = min(annualYou * 0.5, 521.43);
    final annualTotal = annualYou + annualEmpNet + annualGovt;
    final annualESCT = annualEmpGross - annualEmpNet;
    final empFree = annualEmpNet + annualGovt;

    // Per pay calculations
    final perPayYou = annualYou / payFreq;
    final perPayEmpNet = annualEmpNet / payFreq;
    final perPayGovt = annualGovt / payFreq;
    final perPayTotal = perPayYou + perPayEmpNet + perPayGovt;

    // Monthly calculations
    final monthlyYou = annualYou / 12;
    final monthlyEmpNet = annualEmpNet / 12;
    final monthlyGovt = annualGovt / 12;
    final monthlyTotal = annualTotal / 12;

    final isDirty = _showResults && (
      _salaryController.text != (_calcSnapshot['salary']?.toString() ?? '') ||
      _payFreq != (_calcSnapshot['payFreq'] ?? 0) ||
      _empExtra != (_calcSnapshot['empExtra'] ?? 0) ||
      _contribRate != (_calcSnapshot['contribRate'] ?? 0.0) ||
      _taxRate != (_calcSnapshot['taxRate'] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Annual Summary',
              style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            GestureDetector(
              onTap: _reset,
              child: Text(
                'Reset ↺',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: const Color(0xFFC0392B),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Details Inputs
        Text(
          'Your Employment Details',
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
              Text(
                '💼 Income & Contribution',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),

              _buildTextInput(
                label: 'Annual Gross Salary (NZD)',
                controller: _salaryController,
                errorText: _errors['salary'],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Pay Frequency',
                      value: _payFreq,
                      items: const [
                        DropdownMenuItem(value: 52, child: Text('Weekly')),
                        DropdownMenuItem(value: 26, child: Text('Fortnightly')),
                        DropdownMenuItem(value: 12, child: Text('Monthly')),
                      ],
                      onChanged: (val) => setState(() => _payFreq = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Employer Extra %',
                      value: _empExtra,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('3% only (min)')),
                        DropdownMenuItem(value: 1, child: Text('4% (generous)')),
                        DropdownMenuItem(value: 2, child: Text('5% (v. generous)')),
                      ],
                      onChanged: (val) => setState(() => _empExtra = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contrib Rate Buttons
              Text(
                'Your Contribution Rate',
                style: AppTextStyles.dmSans(
                    size: 9, weight: FontWeight.w700, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [3.0, 4.0, 6.0, 8.0, 10.0].map((rate) {
                  final active = _contribRate == rate;
                  return InkWell(
                    onTap: () => setState(() => _contribRate = rate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? theme.primaryColor : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? theme.primaryColor : theme.getBorderColor(context)),
                      ),
                      child: Text(
                        '${rate.toInt()}%',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.bold,
                          color: active ? Colors.white : theme.getTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // ESCT Tax Dropdown
              _buildDropdown(
                label: 'Your Marginal Tax Rate (ESCT)',
                value: _taxRate,
                items: const [
                  DropdownMenuItem(value: 10.5, child: Text('10.5% (income ≤ \$14K)')),
                  DropdownMenuItem(value: 17.5, child: Text('17.5% (\$14K–\$48K)')),
                  DropdownMenuItem(value: 30.0, child: Text('30.0% (\$48K–\$70K)')),
                  DropdownMenuItem(value: 33.0, child: Text('33.0% (\$70K–\$180K)')),
                  DropdownMenuItem(value: 39.0, child: Text('39.0% (above \$180K)')),
                ],
                onChanged: (val) => setState(() => _taxRate = val!),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A017),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '👥 Calculate Employer Match',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Card
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
                      'Inputs have changed. Tap Calculate Employer Match to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Hero grid
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
                        'KIWISAVER EMPLOYER MATCH · ANNUAL TOTALS',
                        style: AppTextStyles.dmSans(
                          size: 8,
                          color: Colors.white70,
                          weight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.6,
                        children: [
                          _buildHeroGridBox(
                            label: 'Total Into KiwiSaver',
                            val: CurrencyFormatter.format(annualTotal, currencyCode: 'NZD'),
                            valColor: const Color(0xFFF5D060),
                            sub: 'Per year (all sources)',
                          ),
                          _buildHeroGridBox(
                            label: 'Employer "Free Money"',
                            val: CurrencyFormatter.format(empFree, currencyCode: 'NZD'),
                            valColor: const Color(0xFF5EEAD4),
                            sub: '3% match + Govt',
                          ),
                          _buildHeroGridBox(
                            label: 'Your Weekly Contrib',
                            val: CurrencyFormatter.format(annualYou / 52, currencyCode: 'NZD'),
                            valColor: Colors.white,
                            sub: 'From your pay',
                          ),
                          _buildHeroGridBox(
                            label: 'Employer ESCT Tax',
                            val: CurrencyFormatter.format(annualESCT, currencyCode: 'NZD'),
                            valColor: const Color(0xFFFCA5A5),
                            sub: 'Deducted before deposit',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Per-Pay Breakdown table
                Text(
                  'Per-Pay Breakdown',
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
                        '📊 Contribution Split',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header Row
                      Row(
                        children: [
                          Expanded(flex: 2, child: Text('Source', style: _hStyle(theme, context))),
                          Expanded(child: Text('Per Pay', style: _hStyle(theme, context), textAlign: TextAlign.right)),
                          Expanded(child: Text('Monthly', style: _hStyle(theme, context), textAlign: TextAlign.right)),
                          Expanded(child: Text('Annual', style: _hStyle(theme, context), textAlign: TextAlign.right)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),

                      // Row 1: You
                      _buildTableRow(
                        title: '👤 You',
                        sub: '${contribRate.toInt()}% of salary',
                        v1: CurrencyFormatter.compact(perPayYou, symbol: 'NZ\$'),
                        v2: CurrencyFormatter.compact(monthlyYou, symbol: 'NZ\$'),
                        v3: CurrencyFormatter.compact(annualYou, symbol: 'NZ\$'),
                        vColor: const Color(0xFF0D9488),
                      ),
                      const Divider(height: 1),

                      // Row 2: Employer
                      _buildTableRow(
                        title: '🏢 Employer',
                        sub: '${(empRate * 100).toInt()}% match (net ESCT)',
                        v1: CurrencyFormatter.compact(perPayEmpNet, symbol: 'NZ\$'),
                        v2: CurrencyFormatter.compact(monthlyEmpNet, symbol: 'NZ\$'),
                        v3: CurrencyFormatter.compact(annualEmpNet, symbol: 'NZ\$'),
                        vColor: const Color(0xFFD4A017),
                      ),
                      const Divider(height: 1),

                      // Row 3: Govt
                      _buildTableRow(
                        title: '🏛️ Govt Contrib',
                        sub: '50c/\$1 up to \$521',
                        v1: CurrencyFormatter.compact(perPayGovt, symbol: 'NZ\$'),
                        v2: CurrencyFormatter.compact(monthlyGovt, symbol: 'NZ\$'),
                        v3: CurrencyFormatter.compact(annualGovt, symbol: 'NZ\$'),
                        vColor: const Color(0xFF1A6B4A),
                      ),
                      const Divider(height: 1),

                      // Row 4: Total (highlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0FDFA), Color(0xFFECFDF5)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF5EEAD4)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('✅ Total',
                                      style: AppTextStyles.dmSans(
                                          size: 11, weight: FontWeight.bold, color: const Color(0xFF0F766E))),
                                  Text('All sources',
                                      style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF0D9488))),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.compact(perPayTotal, symbol: 'NZ\$'),
                                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF0F766E)),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.compact(monthlyTotal, symbol: 'NZ\$'),
                                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF0F766E)),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.compact(annualTotal, symbol: 'NZ\$'),
                                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF0F766E)),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Donut & Bar Charts Card
                Text(
                  'Contribution Split',
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
                      Text(
                        'Annual Mix',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Row with Donut chart and Legend
                      Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CustomPaint(
                              painter: _NZEmployerDonutPainter(
                                you: annualYou,
                                emp: annualEmpNet,
                                govt: annualGovt,
                                theme: theme,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildLegendItem(
                                  dotColor: const Color(0xFF5EEAD4),
                                  label: 'You',
                                  val: '${CurrencyFormatter.compact(annualYou, symbol: 'NZ\$')}/yr (${(annualYou / annualTotal * 100).round()}%)',
                                ),
                                const SizedBox(height: 8),
                                _buildLegendItem(
                                  dotColor: const Color(0xFFF5D060),
                                  label: 'Employer',
                                  val: '${CurrencyFormatter.compact(annualEmpNet, symbol: 'NZ\$')}/yr (${(annualEmpNet / annualTotal * 100).round()}%)',
                                ),
                                const SizedBox(height: 8),
                                _buildLegendItem(
                                  dotColor: const Color(0xFF6EE7B7),
                                  label: 'Government',
                                  val: '${CurrencyFormatter.compact(annualGovt, symbol: 'NZ\$')}/yr (${(annualGovt / annualTotal * 100).round()}%)',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Annual track bars
                      _buildProgressTrack(
                        label: '🧑 You',
                        val: '${CurrencyFormatter.compact(annualYou, symbol: 'NZ\$')} / yr',
                        pct: annualYou / annualTotal,
                        color: const Color(0xFF5EEAD4),
                      ),
                      const SizedBox(height: 10),
                      _buildProgressTrack(
                        label: '🏢 Employer',
                        val: '${CurrencyFormatter.compact(annualEmpNet, symbol: 'NZ\$')} / yr',
                        pct: annualEmpNet / annualTotal,
                        color: const Color(0xFFF5D060),
                      ),
                      const SizedBox(height: 10),
                      _buildProgressTrack(
                        label: '🏛️ Government',
                        val: '${CurrencyFormatter.compact(annualGovt, symbol: 'NZ\$')} / yr',
                        pct: annualGovt / annualTotal,
                        color: const Color(0xFF6EE7B7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ESCT Warning Alert
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ESCT Tax Alert',
                        style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.bold,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your employer contributes ${CurrencyFormatter.compact(annualEmpGross, symbol: 'NZ\$')}/yr gross, but after ESCT (${taxRate.toStringAsFixed(1)}%), only ${CurrencyFormatter.compact(annualEmpNet, symbol: 'NZ\$')}/yr actually reaches your KiwiSaver. That\'s ${CurrencyFormatter.compact(annualESCT, symbol: 'NZ\$')}/yr in tax deducted by the employer before deposit.',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Snap Button
                ElevatedButton.icon(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor, width: 1.5),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text('Save KiwiSaver Details',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: theme.primaryColor)),
                ),
              ],
            ),
          ),
        ],

        // IRD Rules List card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 2025 Employer Contribution Rules (IRD)',
                style: AppTextStyles.dmSans(
                  size: 11.5,
                  weight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletItem('Employer must contribute minimum 3% of gross salary'),
              _buildBulletItem('Employer contributions attract ESCT tax before deposit'),
              _buildBulletItem('ESCT rate based on employee\'s prior-year total remuneration + employer KiwiSaver'),
              _buildBulletItem('Government contributes 50 cents per \$1 you contribute (max \$521.43/yr)'),
              _buildBulletItem('To get max Govt contribution: contribute at least \$1,042.86/yr'),
              _buildBulletItem('Employer cannot opt-out of contributing once employee is enrolled'),
              _buildBulletItem('Contributions go to your chosen KiwiSaver provider (or default)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroGridBox({
    required String label,
    required String val,
    required Color valColor,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white54, weight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.bold, color: valColor),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({required String label, required TextEditingController controller, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: widget.theme.getMutedColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: errorText != null ? Colors.red : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(
                size: 14,
                color: widget.theme.getTextColor(context),
                weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 2),
          Text(errorText, style: AppTextStyles.dmSans(size: 9, color: Colors.red, weight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
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
            size: 9,
            weight: FontWeight.bold,
            color: widget.theme.getMutedColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: widget.theme.getCardColor(context),
              style: AppTextStyles.dmSans(size: 11, color: widget.theme.getTextColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _hStyle(CountryTheme theme, BuildContext context) {
    return AppTextStyles.dmSans(
      size: 8,
      weight: FontWeight.w800,
      color: theme.getMutedColor(context),
    );
  }

  Widget _buildTableRow({
    required String title,
    required String sub,
    required String v1,
    required String v2,
    required String v3,
    required Color vColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.bold,
                    color: widget.theme.getTextColor(context),
                  ),
                ),
                Text(
                  sub,
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: widget.theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              v1,
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: vColor),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              v2,
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: vColor),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              v3,
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: vColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color dotColor, required String label, required String val}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
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
                val,
                style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTrack({
    required String label,
    required String val,
    required double pct,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context)),
            ),
            Text(
              val,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF92400E), fontSize: 10)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NZEmployerDonutPainter extends CustomPainter {
  final double you;
  final double emp;
  final double govt;
  final CountryTheme theme;

  _NZEmployerDonutPainter({
    required this.you,
    required this.emp,
    required this.govt,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = you + emp + govt;
    if (total <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final double outerRadius = min(size.width, size.height) / 2;
    final double innerRadius = outerRadius * 0.65;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius);

    double startAngle = -pi / 2;

    final segments = [
      {'val': you, 'color': const Color(0xFF5EEAD4)},
      {'val': emp, 'color': const Color(0xFFF5D060)},
      {'val': govt, 'color': const Color(0xFF6EE7B7)},
    ];

    for (var seg in segments) {
      final val = seg['val'] as double;
      final color = seg['color'] as Color;
      if (val <= 0) continue;

      final sweepAngle = (val / total) * 2 * pi;
      paint.color = color;

      // Draw outer arc, lines, and inner arc in a closed path
      final path = Path();
      path.moveTo(cx + innerRadius * cos(startAngle), cy + innerRadius * sin(startAngle));
      path.lineTo(cx + outerRadius * cos(startAngle), cy + outerRadius * sin(startAngle));
      path.arcTo(rect, startAngle, sweepAngle, false);
      path.lineTo(cx + innerRadius * cos(startAngle + sweepAngle), cy + innerRadius * sin(startAngle + sweepAngle));
      path.arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      startAngle += sweepAngle;
    }

    // Inner text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: 'Annual',
      style: TextStyle(
        fontSize: 7.5,
        color: theme.mutedColor,
        fontFamily: 'Helvetica Neue',
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height - 1));

    textPainter.text = TextSpan(
      text: 'Total',
      style: TextStyle(
        fontSize: 8,
        color: theme.textColor,
        fontFamily: 'Helvetica Neue',
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 1));
  }

  @override
  bool shouldRepaint(covariant _NZEmployerDonutPainter oldDelegate) {
    return oldDelegate.you != you || oldDelegate.emp != emp || oldDelegate.govt != govt;
  }
}
