// lib/features/newzealand/tools/nz_first_home_buyer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZFirstHomeBuyer extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZFirstHomeBuyer({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZFirstHomeBuyer> createState() => _NZFirstHomeBuyerState();
}

class _NZFirstHomeBuyerState extends ConsumerState<NZFirstHomeBuyer> {
  final _incomeController = TextEditingController(text: '110000');
  final _priceController = TextEditingController(text: '580000');

  int _buyers = 2; // 1 = Single, 2 = Couple / 2+
  int _ksYears = 5; // 0 = <3 yrs, 3 = 3-4 yrs, 5 = 5+ yrs
  String _region = 'christchurch'; // auckland | wellington | christchurch | hamilton | tauranga | other
  String _propType = 'new'; // new | existing

  bool _showResults = true;

  @override
  void dispose() {
    _incomeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // 2025 Kāinga Ora caps
  static const Map<String, Map<String, double>> _caps = {
    'auckland': {'new': 875000, 'existing': 650000},
    'wellington': {'new': 750000, 'existing': 650000},
    'christchurch': {'new': 650000, 'existing': 550000},
    'hamilton': {'new': 650000, 'existing': 550000},
    'tauranga': {'new': 650000, 'existing': 550000},
    'other': {'new': 650000, 'existing': 550000},
  };

  void _saveCalculation() async {
    final double income = double.tryParse(_incomeController.text) ?? 110000;
    final double price = double.tryParse(_priceController.text) ?? 580000;

    final incomeCap = _buyers >= 2 ? 150000.0 : 95000.0;
    final priceCap = _caps[_region]?[_propType] ?? 550000.0;

    final ksOk = _ksYears >= 3;
    final incOk = income <= incomeCap;
    final priceOk = price <= priceCap;
    final all3 = ksOk && incOk && priceOk;

    final labelCtrl = TextEditingController(text: 'NZ FHB Eligibility');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_first_home_buyer/save'),
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
              'Income: ${CurrencyFormatter.compact(income, symbol: 'NZ\$')} · Price: ${CurrencyFormatter.compact(price, symbol: 'NZ\$')} · ${all3 ? "Eligible" : "Not eligible"}',
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
                hintText: 'Label (e.g. Christchurch FHB)',
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
          : 'First Home Buyer';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'First Home Buyer',
        inputs: {
          'income': income,
          'buyers': _buyers.toDouble(),
          'ksYears': _ksYears.toDouble(),
          'price': price,
          'propType': _propType == 'new' ? 1.0 : 0.0,
        },
        results: {
          'eligible': all3 ? 1.0 : 0.0,
          'incomeCap': incomeCap,
          'priceCap': priceCap,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eligibility assessment saved!',
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

    final double income = double.tryParse(_incomeController.text) ?? 110000;
    final double price = double.tryParse(_priceController.text) ?? 580000;

    final incomeCap = _buyers >= 2 ? 150000.0 : 95000.0;
    final priceCap = _caps[_region]?[_propType] ?? 550000.0;
    final double grantAmt = _propType == 'new' ? 10000.0 : 5000.0;
    final double jointGrant = _buyers >= 2 ? grantAmt * 2 : grantAmt;

    final ksOk = _ksYears >= 3;
    final incOk = income <= incomeCap;
    final priceOk = price <= priceCap;
    final all3 = ksOk && incOk && priceOk;

    // Calculate score
    int score = 0;
    if (ksOk) {
      score += 35;
    } else if (_ksYears > 0) {
      score += 15;
    }
    if (incOk) {
      score += 35;
    } else if (income <= incomeCap * 1.1) {
      score += 15;
    }
    if (priceOk) {
      score += 30;
    } else if (price <= priceCap * 1.05) {
      score += 12;
    }

    final String verdictText = all3
        ? '✅ Eligible — You Qualify!'
        : score >= 50
            ? '⚠️ Partially Eligible — Review Needed'
            : '❌ Not Currently Eligible';

    final Color statusColor = all3
        ? const Color(0xFF10B981)
        : score >= 50
            ? const Color(0xFFF5D060)
            : const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Banner matching HTML
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Eligibility Score',
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
                border: Border.all(color: const Color(0xFF6EE7B7)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '2025 Kāinga Ora',
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

        // Score Hero Box
        Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FIRST HOME BUYER ELIGIBILITY · KĀINGA ORA 2025',
                  style: AppTextStyles.dmSans(
                    size: 8,
                    color: Colors.white70,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Circular score chart
              SizedBox(
                height: 90,
                width: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: AppTextStyles.playfair(
                            size: 24,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: AppTextStyles.dmSans(
                            size: 8,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                verdictText,
                style: AppTextStyles.playfair(
                  size: 14,
                  weight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildScoreBox(
                      'KiwiSaver',
                      ksOk ? '✓ $_ksYears+ yrs' : '✗ < 3 yrs',
                      ksOk ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildScoreBox(
                      'Income',
                      incOk ? '✓ Within' : '✗ Exceeds',
                      incOk ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildScoreBox(
                      'Price Cap',
                      priceOk ? '✓ Within' : '✗ Exceeds',
                      priceOk ? const Color(0xFF6EE7B7) : const Color(0xFFF5D060),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Inputs Card
        Text(
          'Your Details',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏡 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Tell Us About You',
                    style: AppTextStyles.playfair(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ANNUAL INCOME',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_incomeController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BUYERS',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _buyers,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              items: const [
                                DropdownMenuItem(
                                    value: 1, child: Text('Single')),
                                DropdownMenuItem(
                                    value: 2, child: Text('Couple / 2+')),
                              ],
                              onChanged: (val) =>
                                  setState(() => _buyers = val ?? 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KIWISAVER MEMBERSHIP',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _ksYears,
                        isExpanded: true,
                        dropdownColor: theme.getCardColor(context),
                        items: const [
                          DropdownMenuItem(
                              value: 0, child: Text('Less than 3 years')),
                          DropdownMenuItem(
                              value: 3, child: Text('3–4 years')),
                          DropdownMenuItem(value: 5, child: Text('5+ years')),
                        ],
                        onChanged: (val) =>
                            setState(() => _ksYears = val ?? 5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROPERTY REGION',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _region,
                        isExpanded: true,
                        dropdownColor: theme.getCardColor(context),
                        items: const [
                          DropdownMenuItem(
                              value: 'auckland', child: Text('Auckland')),
                          DropdownMenuItem(
                              value: 'wellington', child: Text('Wellington')),
                          DropdownMenuItem(
                              value: 'christchurch', child: Text('Christchurch')),
                          DropdownMenuItem(
                              value: 'hamilton', child: Text('Hamilton')),
                          DropdownMenuItem(
                              value: 'tauranga', child: Text('Tauranga')),
                          DropdownMenuItem(
                              value: 'other', child: Text('Other NZ')),
                        ],
                        onChanged: (val) =>
                            setState(() => _region = val ?? 'other'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROPERTY TYPE',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _propType = 'new'),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _propType == 'new'
                                  ? const Color(0xFFFEF2F2)
                                  : theme.getBgColor(context),
                              border: Border.all(
                                color: _propType == 'new'
                                    ? const Color(0xFFC0392B)
                                    : theme.getBorderColor(context),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🏗️ New Build',
                                    style: AppTextStyles.dmSans(
                                        size: 11,
                                        weight: FontWeight.bold,
                                        color: _propType == 'new'
                                            ? const Color(0xFFC0392B)
                                            : theme.getTextColor(context))),
                                Text('Off-plan / new',
                                    style: AppTextStyles.dmSans(
                                        size: 8,
                                        color: _propType == 'new'
                                            ? const Color(0xFF991B1B)
                                            : theme.getMutedColor(context))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _propType = 'existing'),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _propType == 'existing'
                                  ? const Color(0xFFFEF2F2)
                                  : theme.getBgColor(context),
                              border: Border.all(
                                color: _propType == 'existing'
                                    ? const Color(0xFFC0392B)
                                    : theme.getBorderColor(context),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🏠 Existing',
                                    style: AppTextStyles.dmSans(
                                        size: 11,
                                        weight: FontWeight.bold,
                                        color: _propType == 'existing'
                                            ? const Color(0xFFC0392B)
                                            : theme.getTextColor(context))),
                                Text('Established home',
                                    style: AppTextStyles.dmSans(
                                        size: 8,
                                        color: _propType == 'existing'
                                            ? const Color(0xFF991B1B)
                                            : theme.getMutedColor(context))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PURCHASE PRICE',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  _buildInputBox(_priceController),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => setState(() => _showResults = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text('🏡 Check My Eligibility',
                    style: AppTextStyles.playfair(
                        size: 13,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ),

        // Eligibility Checklist
        if (_showResults) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Eligibility Criteria',
                style: AppTextStyles.playfair(
                  size: 12,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Must Pass All',
                  style: AppTextStyles.dmSans(
                    size: 8,
                    color: const Color(0xFFC0392B),
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
                  '📋 Checklist',
                  style: AppTextStyles.playfair(
                    size: 13,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                _buildChecklistItem(
                  '🥝',
                  'KiwiSaver Membership',
                  'Must be member for 3+ years. Yours: ${ksOk ? "$_ksYears+ yrs" : "Less than 3 yrs"}',
                  ksOk ? 'pass' : 'fail',
                  ksOk ? 'Pass' : 'Fail',
                ),
                _buildChecklistItem(
                  '💰',
                  'Income Threshold',
                  '${_buyers >= 2 ? "Joint" : "Single"} cap: ${CurrencyFormatter.compact(incomeCap, symbol: 'NZ\$')}. Yours: ${CurrencyFormatter.compact(income, symbol: 'NZ\$')}',
                  incOk ? 'pass' : 'fail',
                  incOk ? 'Pass' : 'Exceeds',
                ),
                _buildChecklistItem(
                  '🏷️',
                  'Price Cap Compliance',
                  '${_region.substring(0, 1).toUpperCase() + _region.substring(1)} $_propType cap: ${CurrencyFormatter.compact(priceCap, symbol: 'NZ\$')}. Yours: ${CurrencyFormatter.compact(price, symbol: 'NZ\$')}',
                  priceOk ? 'pass' : 'fail',
                  priceOk ? 'Pass' : 'Exceeds',
                ),
                _buildChecklistItem(
                  '🏠',
                  'First-Home Requirement',
                  'Must not previously own property in NZ or abroad',
                  'warn',
                  'Confirm',
                ),
                _buildChecklistItem(
                  '🌏',
                  'NZ Citizenship / Residency',
                  'NZ citizen, permanent resident or resident visa holder',
                  'warn',
                  'Confirm',
                ),
                _buildChecklistItem(
                  '🏗️',
                  'Intend to Live In',
                  'Must be your principal place of residence for at least 6 months',
                  'warn',
                  'Confirm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Available Grants
          Text(
            'Available Grants & Assistance',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💰 What You Could Access',
                  style: AppTextStyles.playfair(
                    size: 13,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGrantItem(
                  all3 ? '🎁' : '⏸️',
                  'KiwiSaver HomeStart Grant',
                  '${_propType == 'new' ? 'New build' : 'Existing'} · ${_buyers >= 2 ? 'Per applicant' : 'Single buyer'}',
                  all3 ? CurrencyFormatter.compact(grantAmt, symbol: 'NZ\$') : 'Not eligible',
                  all3 ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                ),
                if (_buyers >= 2)
                  _buildGrantItem(
                    all3 ? '👫' : '⏸️',
                    'Joint Grant (Both Buyers)',
                    'Both qualify as FHB',
                    all3 ? CurrencyFormatter.compact(jointGrant, symbol: 'NZ\$') : 'Not eligible',
                    all3 ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                  ),
                _buildGrantItem(
                  '🥝',
                  'KiwiSaver Withdrawal',
                  'All contributions + returns (minus \$1,000)',
                  ksOk ? 'Eligible' : 'Not yet',
                  const Color(0xFFF0FDFA),
                ),
                _buildGrantItem(
                  '🏠',
                  'First Home Partner',
                  'Kāinga Ora co-ownership scheme',
                  'Check Eligibility',
                  const Color(0xFFEFF6FF),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💾 ', style: TextStyle(fontSize: 14)),
                      Text('Save Calculation Details',
                          style: AppTextStyles.playfair(
                              size: 12,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF2F2), Color(0xFFFECACA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ 2025 FHB Price Caps (Kāinga Ora)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
              const SizedBox(height: 6),
              ...[
                'Auckland new build: up to \$875,000',
                'Auckland existing: up to \$650,000',
                'Wellington new build: up to \$750,000',
                'Wellington existing: up to \$650,000',
                'Christchurch new build: up to \$650,000',
                'Single income cap: \$95,000 gross; joint: \$150,000'
              ].map((text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontSize: 9, color: Color(0xFFB91C1C))),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 7,
              color: Colors.white60,
              weight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller) {
    final theme = widget.theme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.dmSans(
            size: 14, weight: FontWeight.w700, color: theme.getTextColor(context)),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildChecklistItem(
      String icon, String title, String sub, String status, String label) {
    final theme = widget.theme;

    Color bg;
    Color text;
    if (status == 'pass') {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF065F46);
    } else if (status == 'fail') {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFC0392B);
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 15)),
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
                  sub,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: AppTextStyles.dmSans(
                  size: 9, weight: FontWeight.w700, color: text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrantItem(
      String icon, String title, String sub, String amount, Color iconBg) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
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
                  sub,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: theme.primaryColor),
              ),
              Text(
                'per applicant',
                style: AppTextStyles.dmSans(
                    size: 8, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
