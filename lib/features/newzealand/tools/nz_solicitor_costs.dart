// lib/features/newzealand/tools/nz_solicitor_costs.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZSolicitorCosts extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZSolicitorCosts({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZSolicitorCosts> createState() => _NZSolicitorCostsState();
}

class _NZSolicitorCostsState extends ConsumerState<NZSolicitorCosts> {
  final _priceController = TextEditingController(text: '750000');

  String _propType = 'existing'; // existing | new | unit | leasehold | auction
  bool _limReport = true;
  bool _buildInspect = true;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _priceController.text = '750000';
      _propType = 'existing';
      _limReport = true;
      _buildInspect = true;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final double price = double.tryParse(_priceController.text) ?? 0.0;

    if (price <= 0) {
      errors['price'] = 'Enter valid purchase price';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['price'] = price;
      _calcSnapshot['propType'] = _propType;
      _calcSnapshot['limReport'] = _limReport;
      _calcSnapshot['buildInspect'] = _buildInspect;
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

  void _saveCalculation(double total, double legal, double limCost, double bldCost) async {
    final double price = _calcSnapshot['price'] ?? (double.tryParse(_priceController.text) ?? 750000.0);
    final String snapPropType = _calcSnapshot['propType'] ?? _propType;
    final bool snapLimReport = _calcSnapshot['limReport'] ?? _limReport;
    final bool snapBuildInspect = _calcSnapshot['buildInspect'] ?? _buildInspect;

    final labelCtrl = TextEditingController(text: 'NZ Solicitor Costs');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_solicitor_costs/save'),
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
              'Property Price: ${CurrencyFormatter.compact(price, symbol: 'NZ\$')} · Total Legal: ${CurrencyFormatter.compact(total, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Legal fees for my house)',
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
          : 'Solicitor Costs';

      // Map propType to double
      double propTypeVal = 0.0;
      if (snapPropType == 'new') propTypeVal = 1.0;
      if (snapPropType == 'unit') propTypeVal = 2.0;
      if (snapPropType == 'leasehold') propTypeVal = 3.0;
      if (snapPropType == 'auction') propTypeVal = 4.0;

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Solicitor Costs',
        inputs: {
          'price': price,
          'propType': propTypeVal,
          'limReport': snapLimReport ? 1.0 : 0.0,
          'buildInspect': snapBuildInspect ? 1.0 : 0.0,
        },
        results: {
          'legalBase': legal,
          'limCost': limCost,
          'buildInspectCost': bldCost,
          'titleSearch': 100.0,
          'bankDocs': 300.0,
          'disbursements': 200.0,
          'total': total,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Solicitor costs saved!',
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
    final double rawPrice = double.tryParse(_priceController.text) ?? 750000.0;
    final double price = _showResults ? (_calcSnapshot['price'] ?? rawPrice) : rawPrice;
    final String propType = _showResults ? (_calcSnapshot['propType'] ?? _propType) : _propType;
    final bool limReport = _showResults ? (_calcSnapshot['limReport'] ?? _limReport) : _limReport;
    final bool buildInspect = _showResults ? (_calcSnapshot['buildInspect'] ?? _buildInspect) : _buildInspect;

    // Base legal fee scaled by price
    double legal = 1600;
    if (price > 1000000) {
      legal = 2200;
    } else if (price > 700000) {
      legal = 1850;
    }

    // Property Type additions
    if (propType == 'leasehold') {
      legal += 600;
    } else if (propType == 'unit') {
      legal += 300;
    } else if (propType == 'auction') {
      legal += 350;
    } else if (propType == 'new') {
      legal += 150;
    }

    final double limCost = limReport ? 400.0 : 0.0;
    final double bldCost = buildInspect ? 650.0 : 0.0;
    const double titleCost = 100.0;
    const double bankCost = 300.0;
    const double disbCost = 200.0;

    final double total = legal + limCost + bldCost + titleCost + bankCost + disbCost;

    final isDirty = _showResults && (
      (double.tryParse(_priceController.text) ?? 0.0) != (_calcSnapshot['price'] ?? 0.0) ||
      _propType != (_calcSnapshot['propType'] ?? '') ||
      _limReport != (_calcSnapshot['limReport'] ?? false) ||
      _buildInspect != (_calcSnapshot['buildInspect'] ?? false)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title banner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Solicitor & Legal Costs',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'FHB Guide',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: const Color(0xFF92400E),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Panel matching HTML
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92400E), Color(0xFFD4A017), Color(0xFF0D3B2E)],
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
                    'SOLICITOR & CONVEYANCING ESTIMATOR',
                    style: AppTextStyles.dmSans(
                      size: 8,
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
                        color: const Color(0xFFFDE68A),
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Estimate your legal costs for buying a home',
                style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // Inputs inside Hero
              Text('PROPERTY PURCHASE PRICE',
                  style: AppTextStyles.dmSans(
                      size: 8,
                      weight: FontWeight.w800,
                      color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                height: _errors['price'] != null ? 58 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _errors['price'] != null ? Colors.red : Colors.white.withValues(alpha: 0.22)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      child: Text('NZ\$',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: Colors.white70)),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.dmSans(
                                  size: 14, weight: FontWeight.w700, color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: '750,000',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_errors['price'] != null)
                            Text(
                              _errors['price']!,
                              style: AppTextStyles.dmSans(size: 7, color: Colors.red[300], weight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROPERTY TYPE',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _propType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0D3B2E),
                              iconEnabledColor: Colors.white,
                              style: AppTextStyles.dmSans(
                                  size: 12, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: 'existing', child: Text('Existing Home')),
                                DropdownMenuItem(
                                    value: 'new', child: Text('New Build')),
                                DropdownMenuItem(
                                    value: 'unit', child: Text('Unit / Apartment')),
                                DropdownMenuItem(
                                    value: 'leasehold', child: Text('Leasehold Property')),
                                DropdownMenuItem(
                                    value: 'auction', child: Text('Auction Purchase')),
                              ],
                              onChanged: (val) =>
                                  setState(() => _propType = val ?? 'existing'),
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
                        Text('NEED A LIM REPORT?',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: _limReport,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0D3B2E),
                              iconEnabledColor: Colors.white,
                              style: AppTextStyles.dmSans(
                                  size: 12, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: true, child: Text('Yes — from council (\$400)')),
                                DropdownMenuItem(
                                    value: false, child: Text('No / Already obtained')),
                              ],
                              onChanged: (val) =>
                                  setState(() => _limReport = val ?? true),
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
                        Text('BUILDING INSPECTION?',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: Colors.white70)),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: _buildInspect,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0D3B2E),
                              iconEnabledColor: Colors.white,
                              style: AppTextStyles.dmSans(
                                  size: 12, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: true, child: Text('Yes — pre-purchase (\$655)')),
                                DropdownMenuItem(
                                    value: false, child: Text('No')),
                              ],
                              onChanged: (val) =>
                                  setState(() => _buildInspect = val ?? true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0F0D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('⚖️ Calculate Legal Costs', style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: Colors.white)),
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
                      'Inputs have changed. Tap Calculate Legal Costs to refresh results.',
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
                // Results Card
                Text(
                  'Cost Breakdown',
                  style: AppTextStyles.playfair(
                    size: 12,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL ESTIMATED LEGAL COSTS',
                                style: AppTextStyles.dmSans(
                                    size: 8,
                                    weight: FontWeight.w800,
                                    color: theme.getMutedColor(context)),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                textBaseline: TextBaseline.alphabetic,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                children: [
                                  Text('NZ\$',
                                      style: AppTextStyles.playfair(
                                          size: 14,
                                          weight: FontWeight.w700,
                                          color: theme.primaryColor)),
                                  Text(
                                    CurrencyFormatter.compact(total, symbol: '').replaceAll('\$', ''),
                                    style: AppTextStyles.playfair(
                                        size: 28,
                                        weight: FontWeight.w800,
                                        color: theme.primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'GST INCLUDED',
                                style: AppTextStyles.dmSans(
                                    size: 8,
                                    weight: FontWeight.w800,
                                    color: theme.getMutedColor(context)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '15% GST',
                                style: AppTextStyles.dmSans(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: theme.getMutedColor(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Custom Waterfall chart
                      Text(
                        'COST DISTRIBUTION',
                        style: AppTextStyles.dmSans(
                            size: 8,
                            weight: FontWeight.w800,
                            color: theme.getMutedColor(context),
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      _buildWaterfallChart(
                        total,
                        legal,
                        limCost,
                        bldCost,
                        titleCost,
                        bankCost,
                        disbCost,
                      ),
                      const SizedBox(height: 20),

                      // Detailed cost rows
                      _buildCostRow(
                        color: const Color(0xFF1A6B4A),
                        title: 'Legal / Conveyancing',
                        sub: 'Solicitor fee + GST (incl.)',
                        amount: legal,
                        range: 'Range: \$1,500–\$2,500',
                      ),
                      _buildCostRow(
                        color: const Color(0xFFD4A017),
                        title: 'LIM Report',
                        sub: 'Land Information Memorandum',
                        amount: limCost,
                        range: 'Range: \$250–\$500',
                      ),
                      _buildCostRow(
                        color: const Color(0xFF0EA5E9),
                        title: 'Building Inspection',
                        sub: 'Pre-purchase structural report',
                        amount: bldCost,
                        range: 'Range: \$500–\$900',
                      ),
                      _buildCostRow(
                        color: const Color(0xFF6D28D9),
                        title: 'LINZ Title Search',
                        sub: 'Land Information NZ registration',
                        amount: titleCost,
                        range: 'Fixed ~\$100',
                      ),
                      _buildCostRow(
                        color: const Color(0xFFC0392B),
                        title: 'Mortgage / Bank Docs',
                        sub: 'Lender security documentation',
                        amount: bankCost,
                        range: 'Range: \$250–\$400',
                      ),
                      _buildCostRow(
                        color: const Color(0xFF334155),
                        title: 'Disbursements / Other',
                        sub: 'Couriers, searches, registration',
                        amount: disbCost,
                        range: '~\$150–\$250',
                      ),

                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Estimated',
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  weight: FontWeight.w800,
                                  color: theme.getTextColor(context)),
                            ),
                            Text(
                              CurrencyFormatter.compact(total, symbol: 'NZ\$'),
                              style: AppTextStyles.dmSans(
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: theme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Budget extra 10–15% buffer · Costs vary by solicitor and complexity',
                        style: AppTextStyles.dmSans(
                            size: 8, color: theme.getMutedColor(context)),
                      ),
                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        onPressed: () => _saveCalculation(total, legal, limCost, bldCost),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Text('💾', style: TextStyle(fontSize: 14)),
                        label: Text('Save Calculation',
                            style: AppTextStyles.playfair(
                                size: 13,
                                weight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],

        // Info Section
        Text(
          "What's Included",
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
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
              _buildInfoRow(
                icon: '⚖️',
                title: 'Conveyancing Work',
                desc: 'Title search, contract review, settlement prep, transfer registration. Typically NZ\$1,500–\$2,500 + GST.',
              ),
              _buildInfoRow(
                icon: '📄',
                title: 'LIM Report (Council)',
                desc: 'Shows zoning, consents, hazards. Cost: \$250–\$500 depending on council. Urgent reports cost extra.',
              ),
              _buildInfoRow(
                icon: '🔍',
                title: 'Building Inspection',
                desc: 'Independent structural report. Strongly recommended to check weathertightness. Cost: \$500–\$900.',
              ),
              _buildInfoRow(
                icon: '🏦',
                title: 'Bank / Lender Docs',
                desc: 'Solicitor prepares mortgage security documents for lender. Most charge \$250–\$400.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Alert Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leasehold & Auction Properties Cost More',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Leasehold titles, cross-lease, and unit titles require additional checks. Auction purchases may need pre-auction legal check (\$300–\$500 extra). Budget a 15% contingency.',
                      style: AppTextStyles.dmSans(
                          size: 9,
                          color: const Color(0xFFB45309),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWaterfallChart(
    double total,
    double legal,
    double limCost,
    double bldCost,
    double titleCost,
    double bankCost,
    double disbCost,
  ) {
    return Column(
      children: [
        _buildBarItem('Legal / Conveyancing', legal, total, const Color(0xFF1A6B4A)),
        const SizedBox(height: 8),
        _buildBarItem('LIM Report', limCost, total, const Color(0xFFD4A017)),
        const SizedBox(height: 8),
        _buildBarItem('Building Inspection', bldCost, total, const Color(0xFF0EA5E9)),
        const SizedBox(height: 8),
        _buildBarItem('Title Search (LINZ)', titleCost, total, const Color(0xFF6D28D9)),
        const SizedBox(height: 8),
        _buildBarItem('Bank / Mortgage Docs', bankCost, total, const Color(0xFFC0392B)),
        const SizedBox(height: 8),
        _buildBarItem('Disbursements', disbCost, total, const Color(0xFF334155)),
      ],
    );
  }

  Widget _buildBarItem(String name, double val, double total, Color color) {
    final pct = total > 0 ? (val / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: AppTextStyles.dmSans(
                    size: 9.5,
                    weight: FontWeight.w600,
                    color: widget.theme.getTextColor(context))),
            Text(CurrencyFormatter.compact(val, symbol: 'NZ\$'),
                style: AppTextStyles.dmSans(
                    size: 9.5, weight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 8,
            width: double.infinity,
            color: widget.theme.getBorderColor(context),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow({
    required Color color,
    required String title,
    required String sub,
    required double amount,
    required String range,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: theme.getTextColor(context)),
                ),
                Text(
                  sub,
                  style: AppTextStyles.dmSans(
                      size: 9, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.compact(amount, symbol: 'NZ\$'),
                style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context)),
              ),
              Text(
                range,
                style: AppTextStyles.dmSans(
                    size: 8, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String title,
    required String desc,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
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
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
