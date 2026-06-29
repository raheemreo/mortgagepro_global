// lib/features/newzealand/tools/nz_bright_line.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZBrightLineTest extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZBrightLineTest({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZBrightLineTest> createState() => _NZBrightLineTestState();
}

class _NZBrightLineTestState extends ConsumerState<NZBrightLineTest> {
  DateTime _acquireDate = DateTime(2022, 6, 15);
  DateTime _saleDate = DateTime(2025, 8, 1);

  String _propUse = 'investment'; // 'investment' | 'main' | 'mixed' | 'new'
  final _buyPriceController = TextEditingController(text: '650000');
  final _sellPriceController = TextEditingController(text: '780000');
  final _taxRateController = TextEditingController(text: '33');

  bool _showResults = true;

  @override
  void dispose() {
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }



  void _saveCalculation() async {
    final double buy = double.tryParse(_buyPriceController.text) ?? 650000;
    final double sell = double.tryParse(_sellPriceController.text) ?? 780000;
    final double tax = double.tryParse(_taxRateController.text) ?? 33;

    final result = _runCalculation(buy, sell, tax);

    final labelCtrl = TextEditingController(text: 'NZ Bright-Line Test');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_bright_line/save'),
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
              'Saving: Gain: ${CurrencyFormatter.compact(result.capGain, symbol: 'NZ\$')} · Tax Owed: ${CurrencyFormatter.compact(result.taxOwed, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Rental Sale)',
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
          : 'Bright-Line Test';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Bright-Line Test',
        inputs: {
          'acquireDate': _acquireDate.millisecondsSinceEpoch.toDouble(),
          'saleDate': _saleDate.millisecondsSinceEpoch.toDouble(),
          'buyPrice': buy,
          'sellPrice': sell,
          'taxRate': tax,
          'propUse': _propUse == 'main'
              ? 0.0
              : _propUse == 'investment'
                  ? 1.0
                  : _propUse == 'new'
                      ? 2.0
                      : 3.0,
        },
        results: {
          'capitalGain': result.capGain,
          'taxableGain': result.taxableGain,
          'taxOwed': result.taxOwed,
          'monthsHeld': result.monthsHeld.toDouble(),
          'isTaxable': result.isTaxable ? 1.0 : 0.0,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Bright-line assessment saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  _BrightLineResult _runCalculation(double buy, double sell, double taxRate) {
    final monthsHeld = (_saleDate.year - _acquireDate.year) * 12 + (_saleDate.month - _acquireDate.month);
    final yrsHeld = monthsHeld / 12.0;
    final int yrs = yrsHeld.floor();
    final int mos = ((yrsHeld - yrs) * 12).round();

    final holdStr = yrs > 0 ? '$yrs yr${yrs > 1 ? 's' : ''} $mos mo' : '$mos months';

    // Rules Mapping
    int blYears;
    String blLabel;

    if (_acquireDate.isBefore(DateTime(2018, 3, 29))) {
      blYears = 2;
      blLabel = '2-Year Rule';
    } else if (_acquireDate.isBefore(DateTime(2021, 3, 27))) {
      blYears = 5;
      blLabel = '5-Year Rule';
    } else if (_acquireDate.isBefore(DateTime(2024, 7, 1))) {
      blYears = _propUse == 'new' ? 5 : 10;
      blLabel = _propUse == 'new' ? '5-Year Rule (New Build)' : '10-Year Rule';
    } else {
      blYears = 2;
      blLabel = '2-Year Rule (Jul 2024)';
    }

    final isMainHome = _propUse == 'main';
    final isTaxable = !isMainHome && yrsHeld < blYears;
    final capGain = sell - buy;
    final taxableGain = isTaxable ? capGain : 0.0;
    final taxOwed = taxableGain > 0 ? taxableGain * (taxRate / 100) : 0.0;

    return _BrightLineResult(
      monthsHeld: monthsHeld,
      yrsHeld: yrsHeld,
      holdStr: holdStr,
      blYears: blYears,
      blLabel: blLabel,
      isMainHome: isMainHome,
      isTaxable: isTaxable,
      capGain: capGain,
      taxableGain: taxableGain,
      taxOwed: taxOwed,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isAcquire) async {
    final initial = isAcquire ? _acquireDate : _saleDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.primaryColor,
              onPrimary: Colors.white,
              onSurface: widget.theme.getTextColor(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isAcquire) {
          _acquireDate = picked;
        } else {
          _saleDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final double buy = double.tryParse(_buyPriceController.text) ?? 650000;
    final double sell = double.tryParse(_sellPriceController.text) ?? 780000;
    final double tax = double.tryParse(_taxRateController.text) ?? 33;

    final result = _runCalculation(buy, sell, tax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bright-Line Test Calculator',
              style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                border: Border.all(color: const Color(0xFFF59E0B)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Capital Gains',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFFC2410C), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Inputs Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFFD97706), Color(0xFFF59E0B)],
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
                'BRIGHT-LINE TEST · NZ CAPITAL GAINS · INCOME TAX ACT',
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
                    TextSpan(text: 'Check if your '),
                    TextSpan(text: 'property sale', style: TextStyle(color: Color(0xFFFEF3C7))),
                    TextSpan(text: '\nis taxable'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date selectors
              Row(
                children: [
                  Expanded(
                    child: _buildHeroDateBox(
                      label: 'Date Acquired (Settlement)',
                      valText: _formatDate(_acquireDate),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDateBox(
                      label: 'Date Sold / Planned',
                      valText: _formatDate(_saleDate),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Property Use',
                      value: _propUse,
                      items: const [
                        DropdownMenuItem(value: 'investment', child: Text('Investment Property')),
                        DropdownMenuItem(value: 'main', child: Text('Main Home (Primary)')),
                        DropdownMenuItem(value: 'mixed', child: Text('Mixed Use (part main)')),
                        DropdownMenuItem(value: 'new', child: Text('New Build')),
                      ],
                      onChanged: (val) => setState(() => _propUse = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Your Income Tax Rate',
                      controller: _taxRateController,
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
                      label: 'Purchase Price',
                      controller: _buyPriceController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Sale Price',
                      controller: _sellPriceController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () => setState(() => _showResults = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92400E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🚫 Check Bright-Line Test',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Result Card
        if (_showResults) ...[
          Text(
            'Bright-Line Result',
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
                // Verdict Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: result.isTaxable
                        ? const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)])
                        : const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)]),
                    border: Border.all(
                      color: result.isTaxable ? const Color(0xFFFB923C) : const Color(0xFF6EE7B7),
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.isTaxable ? '⚠️' : '✅',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.isMainHome
                                  ? 'Main Home Exemption Applies'
                                  : result.isTaxable
                                      ? 'Bright-Line Tax Applies'
                                      : 'Outside Bright-Line — Tax-Free Sale',
                              style: AppTextStyles.dmSans(
                                  size: 11, weight: FontWeight.bold, color: const Color(0xFF0A0F0D)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              result.isMainHome
                                  ? 'As your primary residence, this property is exempt from bright-line tax.'
                                  : result.isTaxable
                                      ? 'Gain of ${CurrencyFormatter.format(result.capGain, currencyCode: 'NZD')} is taxable. Held for ${result.holdStr} (under ${result.blYears}-year threshold).'
                                      : 'You held this property for ${result.holdStr}, beyond the ${result.blYears}-year bright-line threshold.',
                              style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF4A6358)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildCostRow(
                  dotColor: const Color(0xFF1A6B4A),
                  label: 'Holding Period',
                  note: 'From acquisition to sale',
                  val: result.holdStr,
                ),
                const Divider(height: 16),
                _buildCostRow(
                  dotColor: const Color(0xFFD97706),
                  label: 'Applicable Bright-Line',
                  note: 'Rule that applies to purchase date',
                  val: result.blLabel,
                  customColor: const Color(0xFFD97706),
                ),
                const Divider(height: 16),
                _buildCostRow(
                  dotColor: const Color(0xFF334155),
                  label: 'Capital Gain',
                  note: 'Sale price minus purchase price',
                  val: CurrencyFormatter.format(result.capGain, currencyCode: 'NZD'),
                  isPositive: result.capGain >= 0,
                ),
                const Divider(height: 16),
                _buildCostRow(
                  dotColor: const Color(0xFFC0392B),
                  label: 'Taxable Gain',
                  note: 'Gain subject to income tax',
                  val: result.isTaxable
                      ? CurrencyFormatter.format(result.taxableGain, currencyCode: 'NZD')
                      : 'NZ\$0 (Exempt)',
                  customColor: result.isTaxable ? const Color(0xFFD97706) : const Color(0xFF1A6B4A),
                ),
                const Divider(height: 20, thickness: 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Tax Liability',
                      style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.bold,
                        color: theme.getTextColor(context),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(result.taxOwed, currencyCode: 'NZD'),
                      style: AppTextStyles.playfair(
                        size: 17,
                        weight: FontWeight.w800,
                        color: result.taxOwed > 0 ? const Color(0xFFC0392B) : const Color(0xFF1A6B4A),
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
                    result.isMainHome
                        ? 'Main home exemption applies. Ensure property was your primary residence for most of the ownership period. Keep records showing your main home use.'
                        : result.isTaxable
                            ? '⚠️ This gain must be declared to IRD in your income tax return. It is taxed at your marginal rate of ${tax.toInt()}%. Costs of sale and capital improvements may reduce the taxable gain. Consult a tax advisor.'
                            : '✅ You are outside the bright-line period. This gain is not taxable under bright-line. Note: land trader or developer rules may still apply — consult a tax advisor.',
                    style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: _saveCalculation,
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    'Save Bright-Line Assessment',
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

          // Timeline ruler
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
                  'Your Holding Period vs Bright-Line Threshold',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),

                // Ruler Visual track
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxYrs = max(result.blYears.toDouble(), result.yrsHeld) + 1.0;
                    final double pct = (result.yrsHeld / maxYrs).clamp(0.0, 1.0);
                    final double needleOffset = pct * (constraints.maxWidth - 4);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Colored gradient bar
                        Opacity(
                          opacity: 0.4,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6EE7B7), Color(0xFFF59E0B), Color(0xFFFCA5A5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.getBorderColor(context)),
                            ),
                          ),
                        ),

                        // Needle
                        Positioned(
                          left: needleOffset,
                          top: -6,
                          child: Column(
                            children: [
                              Container(
                                width: 3,
                                height: 36,
                                color: theme.textColor,
                              ),
                              const Text('▲', style: TextStyle(fontSize: 8, height: 0.6)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0yr', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                    Text('2yr', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: const Color(0xFF1A6B4A))),
                    Text('5yr', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: const Color(0xFFD97706))),
                    Text('10yr', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: const Color(0xFFC0392B))),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'You held for ${result.holdStr} — ${result.isTaxable ? 'within' : 'outside'} the ${result.blYears}-year bright-line',
                    style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Bright-Line Bands grid
        Text(
          'Bright-Line Bands (NZ)',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: [
            _buildBandCard(
              years: '2 Years',
              label: 'Pre-March 2018',
              rule: 'Original rule. Sold within 2yr of purchase = taxable gain.',
              color: const Color(0xFF065F46),
              bgColor: const Color(0xFFECFDF5),
            ),
            _buildBandCard(
              years: '5 Years',
              label: 'Mar 2018 – Mar 2021',
              rule: 'Extended to 5yr. Applies to properties bought in this period.',
              color: const Color(0xFF92400E),
              bgColor: const Color(0xFFFEF9C3),
            ),
            _buildBandCard(
              years: '10 Years',
              label: 'Mar 2021 – Jun 2024',
              rule: 'Extended to 10yr under Labour govt. Investment property + new builds (5yr).',
              color: const Color(0xFFC2410C),
              bgColor: const Color(0xFFFFF7ED),
            ),
            _buildBandCard(
              years: '2 Years',
              label: 'From 1 Jul 2024',
              rule: 'National govt reduced back to 2yr. Applies to properties acquired from Jul 2024.',
              color: const Color(0xFF065F46),
              bgColor: const Color(0xFFECFDF5),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Key Exemptions
        Text(
          'Key Exemptions',
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
                icon: '🏠',
                title: 'Main Home Exemption',
                desc: 'Your primary residence (main home) is exempt from bright-line tax. Must be your main home for most of the ownership period. Mixed-use properties are partially taxable.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🏗️',
                title: 'New Builds (5yr Rule)',
                desc: 'Under the 10yr era, new builds were subject to a shorter 5yr bright-line. From 1 Jul 2024, all properties are back to 2yr regardless of build type.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '📅',
                title: 'Inherited Property',
                desc: 'Property inherited from deceased estates is generally exempt from bright-line. The clock starts from when you received the inheritance if you later sell.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '👨‍👩‍👧',
                title: 'Relationship Property',
                desc: 'Transfers under the Property (Relationships) Act are generally exempt from bright-line. However, the receiving party inherits the original purchase date for future sales.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroDateBox({required String label, required String valText, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
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
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  valText,
                  style: AppTextStyles.dmSans(size: 11.5, color: Colors.white, weight: FontWeight.bold),
                ),
                const Icon(Icons.calendar_month, color: Colors.white60, size: 14),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildHeroDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
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
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF78350F),
              style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              isExpanded: true,
            ),
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

  Widget _buildBandCard({
    required String years,
    required String label,
    required String rule,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            years,
            style: AppTextStyles.playfair(size: 18, weight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            rule,
            style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
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

class _BrightLineResult {
  final int monthsHeld;
  final double yrsHeld;
  final String holdStr;
  final int blYears;
  final String blLabel;
  final bool isMainHome;
  final bool isTaxable;
  final double capGain;
  final double taxableGain;
  final double taxOwed;

  _BrightLineResult({
    required this.monthsHeld,
    required this.yrsHeld,
    required this.holdStr,
    required this.blYears,
    required this.blLabel,
    required this.isMainHome,
    required this.isTaxable,
    required this.capGain,
    required this.taxableGain,
    required this.taxOwed,
  });
}
