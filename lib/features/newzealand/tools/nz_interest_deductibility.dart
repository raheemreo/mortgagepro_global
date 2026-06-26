// lib/features/newzealand/tools/nz_interest_deductibility.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZInterestDeductibility extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZInterestDeductibility({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZInterestDeductibility> createState() => _NZInterestDeductibilityState();
}

class _NZInterestDeductibilityState extends ConsumerState<NZInterestDeductibility> {
  final _interestController = TextEditingController(text: '24000');

  double _taxYear = 100.0; // 100 (FY26) | 80 (FY25) | 50 (FY24) | 75 (FY23)
  double _taxRate = 30.0; // 10.5 | 17.5 | 30 | 33 | 39
  String _propType = 'existing'; // 'existing' | 'newbuild'

  bool _showResults = true;

  @override
  void dispose() {
    _interestController.dispose();
    super.dispose();
  }



  void _saveCalculation() async {
    final double interest = double.tryParse(_interestController.text) ?? 24000;
    final effectivePct = _propType == 'newbuild' ? 100.0 : _taxYear;
    final deductAmt = interest * effectivePct / 100;
    final taxSaving = deductAmt * (_taxRate / 100);

    final labelCtrl = TextEditingController(text: 'NZ Interest Deductibility');
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
              'Saving: Tax Saving: ${CurrencyFormatter.compact(taxSaving, symbol: 'NZ\$')} · Deductible: ${CurrencyFormatter.compact(deductAmt, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. FY25 Deductions)',
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
          : 'Interest Deductibility';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Interest Deductibility',
        inputs: {
          'interest': interest,
          'taxYear': _taxYear,
          'taxRate': _taxRate,
          'propType': _propType == 'newbuild' ? 1.0 : 0.0,
        },
        results: {
          'deductAmt': deductAmt,
          'taxSaving': taxSaving,
          'effectivePct': effectivePct,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deductibility calculation saved!',
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

    final double interest = double.tryParse(_interestController.text) ?? 24000;
    final effectivePct = _propType == 'newbuild' ? 100.0 : _taxYear;
    final deductAmt = interest * effectivePct / 100;
    final nonDeduct = interest - deductAmt;
    final taxSaving = deductAmt * (_taxRate / 100);
    final monthly = taxSaving / 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Policy Update',
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
                '2024 Restored',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFF0F766E), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Policy Update Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏛️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Deductibility Fully Restored from 1 April 2025',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The National-led Government reversed Labour\'s 2021 restrictions. From 1 April 2025, landlords can again deduct 100% of mortgage interest on rental properties against rental income. New builds always retained full deductibility.',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Calculator Inputs Card
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
                'INTEREST DEDUCTIBILITY CALCULATOR · IRD NZ',
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
                    TextSpan(text: 'Your '),
                    TextSpan(text: 'Rental Interest', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: ' Tax Benefit'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Annual Interest Paid (NZD)',
                      controller: _interestController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Tax Year',
                      value: _taxYear,
                      items: const [
                        DropdownMenuItem(value: 100.0, child: Text('FY2025–26 (100%)')),
                        DropdownMenuItem(value: 80.0, child: Text('FY2024–25 (80%)')),
                        DropdownMenuItem(value: 50.0, child: Text('FY2023–24 (50%)')),
                        DropdownMenuItem(value: 75.0, child: Text('FY2022–23 (75%)')),
                      ],
                      onChanged: (val) => setState(() => _taxYear = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Your Tax Rate',
                      value: _taxRate,
                      items: const [
                        DropdownMenuItem(value: 10.5, child: Text('10.5% (up to \$14K)')),
                        DropdownMenuItem(value: 17.5, child: Text('17.5% (\$14K–\$48K)')),
                        DropdownMenuItem(value: 30.0, child: Text('30.0% (\$48K–\$70K)')),
                        DropdownMenuItem(value: 33.0, child: Text('33.0% (\$70K–\$180K)')),
                        DropdownMenuItem(value: 39.0, child: Text('39.0% (over \$180K)')),
                      ],
                      onChanged: (val) => setState(() => _taxRate = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Property Type',
                      value: _propType,
                      items: const [
                        DropdownMenuItem(value: 'existing', child: Text('Existing Property')),
                        DropdownMenuItem(value: 'newbuild', child: Text('New Build (100%)')),
                      ],
                      onChanged: (val) => setState(() => _propType = val!),
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
                  '📝 Calculate Deductibility Saving',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Card
        if (_showResults) ...[
          Text(
            'Your Deductibility Analysis',
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
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _buildResultBox(
                      label: 'Deductible Amount',
                      val: CurrencyFormatter.format(deductAmt, currencyCode: 'NZD'),
                      sub: '${effectivePct.toInt()}% of interest',
                      valColor: const Color(0xFF1A6B4A),
                    ),
                    _buildResultBox(
                      label: 'Tax Saving',
                      val: CurrencyFormatter.format(taxSaving, currencyCode: 'NZD'),
                      sub: 'Annual benefit',
                      valColor: const Color(0xFF1A6B4A),
                    ),
                    _buildResultBox(
                      label: 'Non-deductible',
                      val: CurrencyFormatter.format(nonDeduct, currencyCode: 'NZD'),
                      sub: 'Cannot claim',
                      valColor: const Color(0xFFC0392B),
                    ),
                    _buildResultBox(
                      label: 'Monthly Saving',
                      val: CurrencyFormatter.format(monthly, currencyCode: 'NZD'),
                      sub: 'Per month benefit',
                      valColor: const Color(0xFFD4A017),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Year-by-Year comparison bar chart
                Text(
                  'Year-by-Year Deductibility Comparison',
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDeductCompareBar(
                  label: 'FY25–26',
                  pct: _propType == 'newbuild' ? 1.0 : 1.0,
                  saving: interest * 1.0 * (_taxRate / 100),
                  barColor: const Color(0xFF1A6B4A),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildDeductCompareBar(
                  label: 'FY24–25',
                  pct: _propType == 'newbuild' ? 1.0 : 0.8,
                  saving: interest * (_propType == 'newbuild' ? 1.0 : 0.8) * (_taxRate / 100),
                  barColor: const Color(0xFFD4A017),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildDeductCompareBar(
                  label: 'FY23–24',
                  pct: _propType == 'newbuild' ? 1.0 : 0.5,
                  saving: interest * (_propType == 'newbuild' ? 1.0 : 0.5) * (_taxRate / 100),
                  barColor: const Color(0xFF6EE7B7),
                  textColor: const Color(0xFF0D3B2E),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildDeductCompareBar(
                  label: 'FY22–23',
                  pct: _propType == 'newbuild' ? 1.0 : 0.75,
                  saving: interest * (_propType == 'newbuild' ? 1.0 : 0.75) * (_taxRate / 100),
                  barColor: const Color(0xFF6EE7B7),
                  textColor: const Color(0xFF0D3B2E),
                  theme: theme,
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _saveCalculation,
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    'Save Deductibility Analysis',
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
        const SizedBox(height: 20),

        // Phased Restoration Timeline
        Text(
          'Phased Restoration Timeline',
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
                '📅 IRD Interest Deductibility Phases',
                style: AppTextStyles.dmSans(
                  size: 11.5,
                  weight: FontWeight.bold,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildPhaseRow(
                badge: '✓',
                year: '1 Apr 2020 – 26 Mar 2021',
                pctText: '100%',
                sub: 'Full deductibility (pre-restriction)',
                pctWidth: 1.0,
                isPast: true,
              ),
              _buildTimelineConnector(),
              _buildPhaseRow(
                badge: '✓',
                year: '27 Mar 2021 – 31 Mar 2022',
                pctText: '100%',
                sub: 'Transitional — still deductible',
                pctWidth: 1.0,
                isPast: true,
              ),
              _buildTimelineConnector(),
              _buildPhaseRow(
                badge: '✓',
                year: 'FY2022–23 (1 Apr 2022)',
                pctText: '75%',
                sub: 'First restriction year',
                pctWidth: 0.75,
                isPast: true,
              ),
              _buildTimelineConnector(),
              _buildPhaseRow(
                badge: '✓',
                year: 'FY2023–24 (1 Apr 2023)',
                pctText: '50%',
                sub: 'Maximum restriction',
                pctWidth: 0.50,
                isPast: true,
              ),
              _buildTimelineConnector(),
              _buildPhaseRow(
                badge: '✓',
                year: 'FY2024–25 (1 Apr 2024)',
                pctText: '80%',
                sub: 'Phase-out restoration begins',
                pctWidth: 0.80,
                isPast: true,
              ),
              _buildTimelineConnector(),
              _buildPhaseRow(
                badge: '★',
                year: 'FY2025–26 (1 Apr 2025 onward)',
                pctText: '100%',
                sub: 'Fully restored — current year',
                pctWidth: 1.0,
                isPast: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Key Rules & Exceptions
        Text(
          'Key Rules & Exceptions',
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
                icon: '🏗️',
                title: 'New Builds — Always 100%',
                desc: 'Residential new builds (consent after 27 Mar 2020) retained full interest deductibility throughout all restriction years. This incentive continues indefinitely.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🏘️',
                title: 'Ring-Fencing of Rental Losses',
                desc: 'Since April 2019, rental losses cannot offset other income (salary, business). Losses carry forward to future rental income only. Separate from deductibility rules.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '📋',
                title: 'Mixed Use Properties',
                desc: 'Properties used partly personally and partly as rental must apportion interest. IRD uses days-rented formula to determine the deductible portion.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🏦',
                title: 'Company-Owned Rentals',
                desc: 'Rental properties held in a Look-Through Company (LTC) follow same rules as individual ownership. Standard companies retain full deductibility regardless.',
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
            ],
          ),
        ),
      ],
    );
  }

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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF0D3B2E),
              style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBox({
    required String label,
    required String val,
    required String sub,
    required Color valColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 7.5, color: widget.theme.getMutedColor(context), weight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: valColor),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductCompareBar({
    required String label,
    required double pct,
    required double saving,
    required Color barColor,
    Color? textColor,
    required CountryTheme theme,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: theme.getMutedColor(context)),
          ),
        ),
        Expanded(
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0EC),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  '${(pct * 100).toInt()}%',
                  style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: textColor ?? Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 55,
          child: Text(
            CurrencyFormatter.compact(saving, symbol: 'NZ\$'),
            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseRow({
    required String badge,
    required String year,
    required String pctText,
    required String sub,
    required double pctWidth,
    required bool isPast,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isPast ? const Color(0xFFECFDF5) : widget.theme.primaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            badge,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.bold,
              color: isPast ? const Color(0xFF065F46) : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year,
                style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context)),
              ),
              Text(
                sub,
                style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              pctText,
              style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.bold,
                color: isPast ? widget.theme.mutedColor : widget.theme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 80,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pctWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Container(
      width: 2,
      height: 14,
      color: widget.theme.getBorderColor(context),
      margin: const EdgeInsets.only(left: 15),
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
