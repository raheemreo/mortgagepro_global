// lib/features/newzealand/tools/nz_ring_fencing.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZRingFencingRules extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZRingFencingRules({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZRingFencingRules> createState() => _NZRingFencingRulesState();
}

class _NZRingFencingRulesState extends ConsumerState<NZRingFencingRules> {
  final _incomeController = TextEditingController(text: '31200');
  final _expensesController = TextEditingController(text: '10000');
  final _interestController = TextEditingController(text: '34500');
  final _taxRateController = TextEditingController(text: '33');

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _incomeController.dispose();
    _expensesController.dispose();
    _interestController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _incomeController.text = '31200';
      _expensesController.text = '10000';
      _interestController.text = '34500';
      _taxRateController.text = '33';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final double inc = double.tryParse(_incomeController.text) ?? 0.0;
    final double exp = double.tryParse(_expensesController.text) ?? 0.0;
    final double interest = double.tryParse(_interestController.text) ?? 0.0;
    final double tax = double.tryParse(_taxRateController.text) ?? 33.0;

    if (inc < 0) {
      errors['income'] = 'Income cannot be negative';
    }
    if (exp < 0) {
      errors['expenses'] = 'Expenses cannot be negative';
    }
    if (interest < 0) {
      errors['interest'] = 'Interest cannot be negative';
    }
    if (tax < 0 || tax > 100) {
      errors['taxRate'] = 'Enter tax rate between 0 and 100%';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['income'] = inc;
      _calcSnapshot['expenses'] = exp;
      _calcSnapshot['interest'] = interest;
      _calcSnapshot['taxRate'] = tax;
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
    final double inc = _calcSnapshot['income'] ?? (double.tryParse(_incomeController.text) ?? 31200.0);
    final double exp = _calcSnapshot['expenses'] ?? (double.tryParse(_expensesController.text) ?? 10000.0);
    final double interest = _calcSnapshot['interest'] ?? (double.tryParse(_interestController.text) ?? 34500.0);
    final double tax = _calcSnapshot['taxRate'] ?? (double.tryParse(_taxRateController.text) ?? 33.0);

    final netResult = inc - exp - interest;
    final ringFenced = netResult < 0 ? netResult.abs() : 0.0;

    final labelCtrl = TextEditingController(text: 'NZ Ring-Fencing');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_ring_fencing/save'),
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
              'Saving: Ring-fenced: ${CurrencyFormatter.compact(ringFenced, symbol: 'NZ\$')} · Loss: ${CurrencyFormatter.compact(netResult.abs(), symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Queenstown Loss)',
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
          : 'Ring-Fencing Rules';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Ring-Fencing Rules',
        inputs: {
          'rentalIncome': inc,
          'rentalExpenses': exp,
          'mortInterest': interest,
          'taxRate': tax,
        },
        results: {
          'netResult': netResult,
          'ringFenced': ringFenced,
          'taxLost': ringFenced * (tax / 100),
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ring-fencing calculation saved!',
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
    final double inc = _showResults
        ? (_calcSnapshot['income'] ?? 0.0)
        : (double.tryParse(_incomeController.text) ?? 0.0);
    final double exp = _showResults
        ? (_calcSnapshot['expenses'] ?? 0.0)
        : (double.tryParse(_expensesController.text) ?? 0.0);
    final double interest = _showResults
        ? (_calcSnapshot['interest'] ?? 0.0)
        : (double.tryParse(_interestController.text) ?? 0.0);
    final double tax = _showResults
        ? (_calcSnapshot['taxRate'] ?? 33.0)
        : (double.tryParse(_taxRateController.text) ?? 33.0);

    final netResult = inc - exp - interest;
    final ringFenced = netResult < 0 ? netResult.abs() : 0.0;
    final taxLost = ringFenced * (tax / 100);

    final isDirty = _showResults && (
      (double.tryParse(_incomeController.text) ?? 0.0) != (_calcSnapshot['income'] ?? 0.0) ||
      (double.tryParse(_expensesController.text) ?? 0.0) != (_calcSnapshot['expenses'] ?? 0.0) ||
      (double.tryParse(_interestController.text) ?? 0.0) != (_calcSnapshot['interest'] ?? 0.0) ||
      (double.tryParse(_taxRateController.text) ?? 33.0) != (_calcSnapshot['taxRate'] ?? 33.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ring-Fencing Calculator',
              style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '2019 Law',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFF991B1B), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B0D0D), Color(0xFF7F1D1D), Color(0xFFC0392B)],
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
                    'RENTAL LOSS RING-FENCING · IRD INCOME TAX ACT 2007',
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
                        color: const Color(0xFFFCA5A5),
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
                    TextSpan(text: 'Check if your '),
                    TextSpan(text: 'rental losses', style: TextStyle(color: Color(0xFFFCA5A5))),
                    TextSpan(text: '\ncan offset income'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildHeroInputBox(
                label: 'Annual Rental Income',
                controller: _incomeController,
                errorText: _errors['income'],
              ),
              const SizedBox(height: 8),

              _buildHeroInputBox(
                label: 'Annual Rental Expenses (excl. interest)',
                controller: _expensesController,
                errorText: _errors['expenses'],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Mortgage Interest (rental property)',
                      controller: _interestController,
                      errorText: _errors['interest'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Your Personal Tax Rate',
                      controller: _taxRateController,
                      suffix: '%',
                      errorText: _errors['taxRate'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '💼 Check Ring-Fencing Impact',
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
                      'Inputs have changed. Tap Check Ring-Fencing Impact to refresh results.',
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
                // Result Card
                Text(
                  'Ring-Fencing Result',
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
                          gradient: netResult < 0
                              ? const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFECACA)])
                              : const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)]),
                          border: Border.all(
                            color: netResult < 0 ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              netResult < 0 ? '🚫' : '✅',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    netResult < 0
                                        ? 'Loss Ring-Fenced — Cannot Offset Income'
                                        : 'Rental Profit — No Ring-Fencing Needed',
                                    style: AppTextStyles.dmSans(
                                        size: 11, weight: FontWeight.bold, color: const Color(0xFF0A0F0D)),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    netResult < 0
                                        ? 'Your rental loss of ${CurrencyFormatter.format(ringFenced, currencyCode: 'NZD')} is ring-fenced. It can only offset future rental profits, not your salary.'
                                        : 'Your rental portfolio shows a profit of ${CurrencyFormatter.format(netResult, currencyCode: 'NZD')}. This is taxable income.',
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
                        label: 'Rental Income',
                        note: 'Annual rent received',
                        val: CurrencyFormatter.format(inc, currencyCode: 'NZD'),
                        isPositive: true,
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFFC0392B),
                        label: 'Expenses (excl. interest)',
                        note: 'Rates, insurance, maintenance, PM',
                        val: '–${CurrencyFormatter.format(exp, currencyCode: 'NZD')}',
                        isPositive: false,
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFFD4A017),
                        label: 'Deductible Interest',
                        note: '100% from 1 Apr 2025',
                        val: '–${CurrencyFormatter.format(interest, currencyCode: 'NZD')}',
                        isPositive: false,
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Rental Result',
                            style: AppTextStyles.dmSans(
                              size: 11.5,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context),
                            ),
                          ),
                          Text(
                            (netResult < 0 ? '–' : '') + CurrencyFormatter.format(netResult.abs(), currencyCode: 'NZD'),
                            style: AppTextStyles.playfair(
                              size: 15,
                              weight: FontWeight.w800,
                              color: netResult >= 0 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFF6D28D9),
                        label: 'Amount Ring-Fenced',
                        note: 'Cannot offset other income',
                        val: CurrencyFormatter.format(ringFenced, currencyCode: 'NZD'),
                        isPositive: false,
                        customColor: const Color(0xFFD97706),
                      ),
                      const Divider(height: 16),
                      _buildCostRow(
                        dotColor: const Color(0xFF334155),
                        label: 'Tax Saving Lost',
                        note: 'At your personal rate',
                        val: '–${CurrencyFormatter.format(taxLost, currencyCode: 'NZD')}',
                        isPositive: false,
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Carried Forward Loss',
                                style: AppTextStyles.dmSans(
                                    size: 10.5,
                                    weight: FontWeight.bold,
                                    color: theme.getTextColor(context)),
                              ),
                              Text(
                                'Usable against future rental profits',
                                style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(ringFenced, currencyCode: 'NZD'),
                            style: AppTextStyles.playfair(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What this means for you',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.bold,
                                  color: theme.getTextColor(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              netResult < 0
                                  ? 'Under ring-fencing, you cannot use your ${CurrencyFormatter.compact(ringFenced, symbol: 'NZ\$')} rental loss to reduce your salary tax. The loss is carried forward and can be used when the property turns profitable or when you sell.'
                                  : 'Your rental property is profitable (${CurrencyFormatter.compact(netResult, symbol: 'NZ\$')}). This profit is added to your taxable income at your marginal tax rate of ${tax.toInt()}%.',
                              style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        onPressed: _saveCalculation,
                        icon: const Text('💾', style: TextStyle(fontSize: 14)),
                        label: Text(
                          'Save Ring-Fencing Assessment',
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

        // Timeline
        Text(
          'Ring-Fencing Timeline',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        _buildTimelineItem(
          yearColor: const Color(0xFFC0392B),
          dotBorder: const Color(0xFFFCA5A5),
          yearText: '2019 — Law Introduced',
          title: 'Ring-Fencing Rules Begin',
          desc: 'Residential rental losses can no longer offset other income (salary, business). Losses are "ring-fenced" to rental portfolio only. Applies to properties acquired before and after.',
          showLine: true,
        ),
        _buildTimelineItem(
          yearColor: const Color(0xFFD4A017),
          dotBorder: const Color(0xFFF5D060),
          yearText: '2021–2024 — Interest Phase-Out',
          title: 'Mortgage Interest Deductibility Phased Out',
          desc: 'From Oct 2021: interest deductibility began phasing out for investment properties. By 2024, only 80% was deductible, compounding losses for landlords.',
          showLine: true,
        ),
        _buildTimelineItem(
          yearColor: const Color(0xFF1A6B4A),
          dotBorder: const Color(0xFF6EE7B7),
          yearText: '1 Apr 2025 — Interest Restored',
          title: 'Full Interest Deductibility Returns',
          desc: 'National-led government restored 100% mortgage interest deductibility from 1 April 2025. Ring-fencing rules remain — losses still cannot offset non-rental income.',
          showLine: true,
        ),
        _buildTimelineItem(
          yearColor: const Color(0xFF0D9488),
          dotBorder: const Color(0xFF5EEAD4),
          yearText: '2025+ — Current Rules',
          title: 'Ring-Fencing Still Active',
          desc: 'Rental losses remain ring-fenced to rental income. Carried-forward losses can be used when property generates profit, or all remaining losses are released at the time of sale.',
          showLine: false,
        ),
        const SizedBox(height: 20),

        // Key Rules to Know
        Text(
          'Key Rules to Know',
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
                icon: '🔒',
                title: 'What\'s Ring-Fenced',
                desc: 'Losses from residential rental property (houses, apartments, units). Cannot offset salary, self-employment, or business income. Commercial property is NOT ring-fenced.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🔄',
                title: 'Carry Forward Losses',
                desc: 'Ring-fenced losses carry forward indefinitely. Use them when rental portfolio turns profitable in future years. All losses released on sale of the property.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '🏢',
                title: 'Portfolio vs Individual',
                desc: 'You can elect to pool all rental properties together. A profitable property can absorb another\'s loss within the same portfolio. Useful if you own multiple rentals.',
              ),
              const Divider(height: 16),
              _buildGuideRow(
                icon: '⚠️',
                title: 'Bright-Line Interaction',
                desc: 'If you sell a property subject to the bright-line test, accumulated ring-fenced losses from that property are released and can offset the taxable gain on sale.',
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

  Widget _buildCostRow({
    required Color dotColor,
    required String label,
    required String note,
    required String val,
    required bool isPositive,
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
            color: customColor ?? (isPositive ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required Color yearColor,
    required Color dotBorder,
    required String yearText,
    required String title,
    required String desc,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: yearColor,
                shape: BoxShape.circle,
                border: Border.all(color: dotBorder, width: 2),
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 70,
                color: widget.theme.getBorderColor(context),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: widget.theme.getCardColor(context),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: widget.theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yearText,
                  style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: yearColor),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: widget.theme.getTextColor(context)),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
                ),
              ],
            ),
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
