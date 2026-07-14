// lib/features/newzealand/tools/nz_homestart_grant.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZHomeStartGrant extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZHomeStartGrant({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZHomeStartGrant> createState() => _NZHomeStartGrantState();
}

class _NZHomeStartGrantState extends ConsumerState<NZHomeStartGrant> {
  final _yearsController = TextEditingController(text: '5');
  final _incomeController = TextEditingController(text: '80000');
  final _priceController = TextEditingController(text: '700000');

  String _propType = 'new'; // 'new' | 'exist'
  String _couple = 'no'; // 'no' | 'yes'
  String _region = 'other'; // 'auckland' | 'wellington' | 'christchurch' | 'other'

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  final Map<String, Map<String, double>> _priceCaps = {
    'auckland': {'new': 875000, 'exist': 650000},
    'wellington': {'new': 800000, 'exist': 600000},
    'christchurch': {'new': 700000, 'exist': 550000},
    'other': {'new': 650000, 'exist': 500000},
  };

  @override
  void dispose() {
    _yearsController.dispose();
    _incomeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _yearsController.text = '5';
      _incomeController.text = '80000';
      _priceController.text = '700000';
      _propType = 'new';
      _couple = 'no';
      _region = 'other';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final yrs = double.tryParse(_yearsController.text) ?? 0.0;
    final income = double.tryParse(_incomeController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (yrs < 0 || yrs > 50) {
      errors['years'] = 'Enter valid years (0-50)';
    }
    if (income < 0) {
      errors['income'] = 'Income cannot be negative';
    }
    if (price < 0) {
      errors['price'] = 'Price cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['ksYears'] = yrs;
      _calcSnapshot['propType'] = _propType;
      _calcSnapshot['income'] = income;
      _calcSnapshot['couple'] = _couple;
      _calcSnapshot['propPrice'] = price;
      _calcSnapshot['region'] = _region;
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
    final double snapYrs = _calcSnapshot['ksYears'] ?? (double.tryParse(_yearsController.text) ?? 5.0);
    final String snapPropType = _calcSnapshot['propType'] ?? _propType;
    final double snapIncome = _calcSnapshot['income'] ?? (double.tryParse(_incomeController.text) ?? 80000.0);
    final String snapCouple = _calcSnapshot['couple'] ?? _couple;
    final double snapPrice = _calcSnapshot['propPrice'] ?? (double.tryParse(_priceController.text) ?? 700000.0);
    final String snapRegion = _calcSnapshot['region'] ?? _region;

    final incomeCap = snapCouple == 'yes' ? 150000.0 : 95000.0;
    final priceCap = _priceCaps[snapRegion]?[snapPropType] ?? 500000.0;

    final yrOk = snapYrs >= 3;
    final incomeOk = snapIncome <= incomeCap;
    final priceOk = snapPrice <= priceCap;
    final eligible = yrOk && incomeOk && priceOk;

    final eligYrs = min(snapYrs.floor(), 5);
    final ratePerYr = snapPropType == 'new' ? 2000.0 : 1000.0;
    final grantAmt = eligible ? eligYrs * ratePerYr : 0.0;

    final labelCtrl = TextEditingController(text: 'NZ HomeStart Grant');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_homestart_grant/save'),
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
              'Saving: HomeStart Grant ${CurrencyFormatter.compact(grantAmt, symbol: 'NZ\$')} · Salary: ${CurrencyFormatter.compact(snapIncome, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Wellington Grant)',
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
          : 'HomeStart Grant';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'HomeStart Grant',
        inputs: <String, double>{
          'ksYears': snapYrs,
          'propType': snapPropType == 'new' ? 1.0 : 0.0,
          'income': snapIncome,
          'couple': snapCouple == 'yes' ? 1.0 : 0.0,
          'propPrice': snapPrice,
          'region': snapRegion == 'auckland'
              ? 0.0
              : snapRegion == 'wellington'
                  ? 1.0
                  : snapRegion == 'christchurch'
                      ? 2.0
                      : 3.0,
        },
        results: <String, double>{
          'grantAmount': grantAmt,
          'eligible': eligible ? 1.0 : 0.0,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ HomeStart grant calculation saved!',
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

    final double rawYrs = double.tryParse(_yearsController.text) ?? 5;
    final double rawIncome = double.tryParse(_incomeController.text) ?? 80000;
    final double rawPrice = double.tryParse(_priceController.text) ?? 700000;
    final String rawPropType = _propType;
    final String rawCouple = _couple;
    final String rawRegion = _region;

    final double yrs = _showResults ? (_calcSnapshot['ksYears'] ?? rawYrs) : rawYrs;
    final double income = _showResults ? (_calcSnapshot['income'] ?? rawIncome) : rawIncome;
    final double price = _showResults ? (_calcSnapshot['propPrice'] ?? rawPrice) : rawPrice;
    final String propType = _showResults ? (_calcSnapshot['propType'] ?? rawPropType) : rawPropType;
    final String couple = _showResults ? (_calcSnapshot['couple'] ?? rawCouple) : rawCouple;
    final String region = _showResults ? (_calcSnapshot['region'] ?? rawRegion) : rawRegion;

    final incomeCap = couple == 'yes' ? 150000.0 : 95000.0;
    final priceCap = _priceCaps[region]?[propType] ?? 500000.0;

    final yrOk = yrs >= 3;
    final incomeOk = income <= incomeCap;
    final priceOk = price <= priceCap;
    final eligible = yrOk && incomeOk && priceOk;

    final eligYrs = min(yrs.floor(), 5);
    final ratePerYr = propType == 'new' ? 2000.0 : 1000.0;
    final grantAmt = eligible ? eligYrs * ratePerYr : 0.0;

    final isDirty = _showResults && (
      _yearsController.text != (_calcSnapshot['ksYears']?.toString() ?? '') ||
      _incomeController.text != (_calcSnapshot['income']?.toString() ?? '') ||
      _priceController.text != (_calcSnapshot['propPrice']?.toString() ?? '') ||
      _propType != (_calcSnapshot['propType'] ?? '') ||
      _couple != (_calcSnapshot['couple'] ?? '') ||
      _region != (_calcSnapshot['region'] ?? '')
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Grant Calculator',
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

        // Hero Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D3B2E), Color(0xFFD4A017)],
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
                'HOMESTART GRANT · TE TŪĀPOKINA KĀINGA TUATAHI',
                style: AppTextStyles.dmSans(
                  size: 8.5,
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
                    TextSpan(text: 'Check your '),
                    TextSpan(text: 'HomeStart Grant', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: '\neligibility & amount'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inputs Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'KiwiSaver Years',
                      controller: _yearsController,
                      errorText: _errors['years'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Property Type',
                      value: _propType,
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New Build')),
                        DropdownMenuItem(value: 'exist', child: Text('Existing Home')),
                      ],
                      onChanged: (val) => setState(() => _propType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Inputs Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Annual Income (NZD)',
                      controller: _incomeController,
                      errorText: _errors['income'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Buying with partner?',
                      value: _couple,
                      items: const [
                        DropdownMenuItem(value: 'no', child: Text('Solo Buyer')),
                        DropdownMenuItem(value: 'yes', child: Text('Couple')),
                      ],
                      onChanged: (val) => setState(() => _couple = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Inputs Row 3
              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Property Price (NZD)',
                      controller: _priceController,
                      errorText: _errors['price'],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Region',
                      value: _region,
                      items: const [
                        DropdownMenuItem(value: 'auckland', child: Text('Auckland')),
                        DropdownMenuItem(value: 'wellington', child: Text('Wellington')),
                        DropdownMenuItem(value: 'christchurch', child: Text('Christchurch')),
                        DropdownMenuItem(value: 'other', child: Text('Other NZ')),
                      ],
                      onChanged: (val) => setState(() => _region = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0F0D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🏡 Check Grant Eligibility',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grant Tiers Visual cards
        Text(
          'Grant Tiers',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTierBox(
                isActive: _propType == 'new',
                title: '🏗️ New Build',
                amount: '\$10,000',
                desc: '\$2,000/yr · Max 5 yrs',
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                labelColor: const Color(0xFF92400E),
                amountColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTierBox(
                isActive: _propType == 'exist',
                title: '🏡 Existing Home',
                amount: '\$5,000',
                desc: '\$1,000/yr · Max 5 yrs',
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
                ),
                labelColor: const Color(0xFF0F766E),
                amountColor: const Color(0xFF0D9488),
              ),
            ),
          ],
        ),

        // Result Card
        if (_showResults) ...[
          if (isDirty) ...[
            const SizedBox(height: 12),
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
                      'Inputs have changed. Tap Check Grant Eligibility to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Your Grant Result',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HomeStart Grant Result',
                            style: AppTextStyles.dmSans(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: eligible ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              eligible ? 'Eligible ✓' : 'Not Eligible',
                              style: AppTextStyles.dmSans(
                                size: 9.5,
                                weight: FontWeight.w800,
                                color: eligible ? const Color(0xFF065F46) : const Color(0xFFC0392B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Your HomeStart Grant Amount',
                              style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(grantAmt, currencyCode: 'NZD'),
                              style: AppTextStyles.playfair(
                                size: 28,
                                weight: FontWeight.w800,
                                color: const Color(0xFFD4A017),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              eligible
                                  ? '$eligYrs yrs × ${CurrencyFormatter.compact(ratePerYr, symbol: 'NZ\$')}/yr · ${propType == 'new' ? 'New Build' : 'Existing Home'} grant'
                                  : 'One or more eligibility criteria not met',
                              style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              label: 'Grant',
                              val: CurrencyFormatter.compact(grantAmt, symbol: 'NZ\$'),
                              isOk: eligible,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBox(
                              label: 'KiwiSaver Yrs',
                              val: '${yrs.toInt()} yrs',
                              isOk: yrOk,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Income OK?',
                              val: incomeOk ? '✓ Yes' : '✗ Over cap',
                              isOk: incomeOk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Eligibility Checklist',
                        style: AppTextStyles.dmSans(
                          size: 10.5,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCheckRow(
                        isOk: yrOk,
                        title: '3+ Years in KiwiSaver',
                        sub: 'Minimum membership required',
                        valueText: yrOk ? '✓ ${yrs.toInt()}yrs' : '✗ ${yrs.toInt()}yrs',
                      ),
                      const Divider(height: 12),
                      _buildCheckRow(
                        isOk: incomeOk,
                        title: 'Income Under Cap',
                        sub: 'Cap: ${CurrencyFormatter.compact(incomeCap, symbol: 'NZ\$')} · Your: ${CurrencyFormatter.compact(income, symbol: 'NZ\$')}',
                        valueText: incomeOk ? '✓ Under cap' : '✗ Exceeds cap',
                      ),
                      const Divider(height: 12),
                      _buildCheckRow(
                        isOk: priceOk,
                        title: 'Price Under Cap',
                        sub: 'Cap: ${CurrencyFormatter.compact(priceCap, symbol: 'NZ\$')} · Asking: ${CurrencyFormatter.compact(price, symbol: 'NZ\$')}',
                        valueText: priceOk ? '✓ Under cap' : '✗ Exceeds cap',
                      ),
                      const Divider(height: 12),
                      _buildCheckRow(
                        isOk: true,
                        title: 'First Home Buyer',
                        sub: 'Must not have previously owned NZ property',
                        valueText: 'Required',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _saveCalculation,
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    'Save This Calculation',
                    style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Price Caps reference card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'House Price Caps 2025',
              style: AppTextStyles.playfair(
                  size: 12,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Kāinga Ora',
                style: AppTextStyles.dmSans(
                    size: 8, color: const Color(0xFF92400E), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏷️ HomeStart Property Price Caps',
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 8),
              _buildCapRow('Auckland / Queenstown', 'New: \$875K', 'Exist: \$650K'),
              _buildCapRow('Wellington / Tauranga', 'New: \$800K', 'Exist: \$600K'),
              _buildCapRow('Christchurch / Hamilton', 'New: \$700K', 'Exist: \$550K'),
              _buildCapRow('Rest of New Zealand', 'New: \$650K', 'Exist: \$500K'),
              const Divider(color: Color(0x2292400E), height: 16),
              _buildCapRow('Income cap (single)', 'NZ\$95,000 p.a.', ''),
              _buildCapRow('Income cap (couple)', 'NZ\$150,000 p.a.', ''),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroInputBox({required String label, required TextEditingController controller, String? errorText}) {
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
            border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
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
          Text(errorText, style: AppTextStyles.dmSans(size: 8, color: Colors.red, weight: FontWeight.bold)),
        ],
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

  Widget _buildTierBox({
    required bool isActive,
    required String title,
    required String amount,
    required String desc,
    required Gradient bgGradient,
    required Color labelColor,
    required Color amountColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFFD4A017) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: labelColor),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppTextStyles.playfair(size: 22, weight: FontWeight.w800, color: amountColor),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: AppTextStyles.dmSans(size: 9, color: labelColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({required String label, required String val, required bool isOk}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: isOk ? const Color(0xFF059669) : const Color(0xFFC0392B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow({
    required bool isOk,
    required String title,
    required String sub,
    required String valueText,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(isOk ? '✅' : '❌', style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.bold,
                    color: widget.theme.getTextColor(context)),
              ),
              Text(
                sub,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        Text(
          valueText,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w800,
            color: isOk ? const Color(0xFF059669) : const Color(0xFFC0392B),
          ),
        ),
      ],
    );
  }

  Widget _buildCapRow(String region, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            region,
            style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E)),
          ),
          Row(
            children: [
              Text(
                val1,
                style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: const Color(0xFFD97706)),
              ),
              if (val2.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  val2,
                  style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF92400E)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
