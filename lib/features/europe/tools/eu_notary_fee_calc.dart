// lib/features/europe/tools/eu_notary_fee_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUNotaryFeeCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUNotaryFeeCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUNotaryFeeCalc> createState() => _EUNotaryFeeCalcState();
}

class _EUNotaryFeeCalcState extends ConsumerState<EUNotaryFeeCalc> {
  String _countryCode = 'DE';
  double _price = 350000;
  String _buyerType = 'resident'; // resident, nonresident, firsttime
  String _propertyType = 'resale'; // new, resale

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  bool _hasCalculated = false;

  static const Map<String, double> _buyerTypeToDouble = {
    'resident': 0.0,
    'nonresident': 1.0,
    'firsttime': 2.0,
  };

  static final Map<double, String> _doubleToBuyerType = {
    0.0: 'resident',
    1.0: 'nonresident',
    2.0: 'firsttime',
  };

  static const Map<String, double> _propertyTypeToDouble = {
    'new': 0.0,
    'resale': 1.0,
  };

  static final Map<double, String> _doubleToPropertyType = {
    0.0: 'new',
    1.0: 'resale',
  };

  final Map<String, Map<String, dynamic>> _countryClosingData = {
    'DE': {
      'name': 'Germany',
      'flag': '🇩🇪',
      'totalTypical': 10.57,
      'fees': [
        {'name': 'Grunderwerbsteuer', 'sub': 'Property Transfer Tax', 'icon': '🏛️', 'col': const Color(0xFF003399), 'pct': {'resident': 5.0, 'nonresident': 5.0, 'firsttime': 5.0}, 'newBld': true},
        {'name': 'Notarkosten', 'sub': 'Notary Fees (GNotKG)', 'icon': '📜', 'col': const Color(0xFF6D28D9), 'pct': {'resident': 1.5, 'nonresident': 1.5, 'firsttime': 1.5}, 'newBld': true},
        {'name': 'Grundbucheintrag', 'sub': 'Land Registry Fee', 'icon': '📗', 'col': const Color(0xFF0F766E), 'pct': {'resident': 0.5, 'nonresident': 0.5, 'firsttime': 0.5}, 'newBld': true},
        {'name': 'Maklergebühr', 'sub': 'Estate Agent commission', 'icon': '🏠', 'col': const Color(0xFFB45309), 'pct': {'resident': 3.57, 'nonresident': 3.57, 'firsttime': 3.57}, 'newBld': false},
      ],
      'notes': [
        'Transfer tax varies by state: 3.5% (Bavaria) to 6.5% (Saarland). National average used is 5%.',
        'Notary fees are statutory (GNotKG) and apply to both buyer and seller.',
        'Land registry fee is ~0.5% for mortgage registration.',
        'Agent commission is typically split 50/50 between buyer and seller since 2020.'
      ]
    },
    'FR': {
      'name': 'France',
      'flag': '🇫🇷',
      'totalTypical': 8.0,
      'fees': [
        {'name': 'Droits de mutation', 'sub': 'Transfer Tax (resale)', 'icon': '🏛️', 'col': const Color(0xFF003399), 'pct': {'resident': 5.8, 'nonresident': 5.8, 'firsttime': 5.8}, 'newBld': false},
        {'name': 'Frais de notaire', 'sub': 'Notary Professional Fees', 'icon': '📜', 'col': const Color(0xFF6D28D9), 'pct': {'resident': 0.8, 'nonresident': 0.8, 'firsttime': 0.8}, 'newBld': true},
        {'name': 'Emoluments & débours', 'sub': 'Disbursements & Admin', 'icon': '📗', 'col': const Color(0xFF0F766E), 'pct': {'resident': 0.4, 'nonresident': 0.4, 'firsttime': 0.4}, 'newBld': true},
        {'name': 'Honoraires agence', 'sub': 'Estate Agent (avg)', 'icon': '🏠', 'col': const Color(0xFFB45309), 'pct': {'resident': 4.5, 'nonresident': 4.5, 'firsttime': 4.5}, 'newBld': false},
      ],
      'notes': [
        'For new builds (VEFA), transfer tax is only ~0.7% instead of 5.8%.',
        'Notary fees in France include both taxes and professional fees — total ~7–8% for resale.',
        'New builds attract reduced fees (~2–3%) as VAT (20%) is paid at source.',
        'First-time buyer discounts may apply in certain municipalities.'
      ]
    },
    'ES': {
      'name': 'Spain',
      'flag': '🇪🇸',
      'totalTypical': 9.5,
      'fees': [
        {'name': 'ITP / AJD', 'sub': 'Transfer Tax (resale)', 'icon': '🏛️', 'col': const Color(0xFF003399), 'pct': {'resident': 8.0, 'nonresident': 8.0, 'firsttime': 6.0}, 'newBld': false},
        {'name': 'Gastos de notaría', 'sub': 'Notary Fees', 'icon': '📜', 'col': const Color(0xFF6D28D9), 'pct': {'resident': 0.3, 'nonresident': 0.3, 'firsttime': 0.3}, 'newBld': true},
        {'name': 'Registro de Propiedad', 'sub': 'Land Registry', 'icon': '📗', 'col': const Color(0xFF0F766E), 'pct': {'resident': 0.2, 'nonresident': 0.2, 'firsttime': 0.2}, 'newBld': true},
        {'name': 'Gestión', 'sub': 'Administration Fees', 'icon': '🗂️', 'col': const Color(0xFFB45309), 'pct': {'resident': 0.15, 'nonresident': 0.15, 'firsttime': 0.15}, 'newBld': true},
      ],
      'notes': [
        'ITP (resale) varies by region: 6–10%. Most regions average 8%; Madrid 6% for first-time buyers.',
        'New builds pay 10% VAT + 1.5% AJD (Stamp Duty) instead of ITP.',
        'Non-residents face the same taxes but should budget extra for fiscal representative costs.',
        'Spanish mortgage lender now pays the AJD since 2019 (Ley Hipotecaria).'
      ]
    },
    'IT': {
      'name': 'Italy',
      'flag': '🇮🇹',
      'totalTypical': 14.0,
      'fees': [
        {'name': 'Imposta di Registro', 'sub': 'Registration Tax (resale)', 'icon': '🏛️', 'col': const Color(0xFF003399), 'pct': {'resident': 2.0, 'nonresident': 9.0, 'firsttime': 2.0}, 'newBld': false},
        {'name': 'Onorario Notaio', 'sub': 'Notary Professional Fees', 'icon': '📜', 'col': const Color(0xFF6D28D9), 'pct': {'resident': 1.0, 'nonresident': 1.0, 'firsttime': 1.0}, 'newBld': true},
        {'name': 'Imposta Ipotecaria', 'sub': 'Mortgage Tax', 'icon': '🏦', 'col': const Color(0xFF0F766E), 'pct': {'resident': 0.25, 'nonresident': 0.25, 'firsttime': 0.25}, 'newBld': true},
        {'name': 'Provvigione agente', 'sub': 'Estate Agent', 'icon': '🏠', 'col': const Color(0xFFB45309), 'pct': {'resident': 3.0, 'nonresident': 3.0, 'firsttime': 3.0}, 'newBld': false},
      ],
      'notes': [
        'Italian residents buying primary residence pay just 2% registration tax; non-residents pay 9%.',
        'Mortgage tax (imposta ipotecaria) is 0.25% of loan for primary residence; 2% otherwise.',
        'Notary fees in Italy are regulated (DM 140/2012) on a sliding scale.',
        'First home (prima casa) concessions reduce most taxes significantly for residents.'
      ]
    },
    'NL': {
      'name': 'Netherlands',
      'flag': '🇳🇱',
      'totalTypical': 3.0,
      'fees': [
        {'name': 'Overdrachtsbelasting', 'sub': 'Transfer Tax', 'icon': '🏛️', 'col': const Color(0xFF003399), 'pct': {'resident': 2.0, 'nonresident': 2.0, 'firsttime': 0.0}, 'newBld': false},
        {'name': 'Notariskosten', 'sub': 'Notary Fees (regulated)', 'icon': '📜', 'col': const Color(0xFF6D28D9), 'pct': {'resident': 0.4, 'nonresident': 0.4, 'firsttime': 0.4}, 'newBld': true},
        {'name': 'Kadaster', 'sub': 'Land Registry', 'icon': '📗', 'col': const Color(0xFF0F766E), 'pct': {'resident': 0.1, 'nonresident': 0.1, 'firsttime': 0.1}, 'newBld': true},
        {'name': 'Hypotheekadvies', 'sub': 'Mortgage Advice', 'icon': '💬', 'col': const Color(0xFFB45309), 'pct': {'resident': 0.5, 'nonresident': 0.5, 'firsttime': 0.5}, 'newBld': true},
      ],
      'notes': [
        'First-time buyers under 35 pay 0% transfer tax (vrijstelling) as of 2021.',
        'Repeat buyers pay 2% transfer tax. Investors/non-owner-occupiers pay 10.4% (2024).',
        'NHG is available for properties under €435,000.',
        'The Netherlands allows 100% LTV for owner-occupiers.'
      ]
    },
    'PT': {
      'name': 'Portugal',
      'flag': '🇵🇹',
      'totalTypical': 10.5,
      'fees': [
        {'name': 'IMT', 'sub': 'Municipal Transfer Tax', 'icon': '🏛️', 'col': const Color(0xFF003399), 'pct': {'resident': 3.0, 'nonresident': 6.5, 'firsttime': 1.5}, 'newBld': true},
        {'name': 'Imposto do Selo', 'sub': 'Stamp Duty (0.8%)', 'icon': '🏛️', 'col': const Color(0xFF1E3A8A), 'pct': {'resident': 0.8, 'nonresident': 0.8, 'firsttime': 0.8}, 'newBld': true},
        {'name': 'Escritura', 'sub': 'Notary / Deed Fees', 'icon': '📜', 'col': const Color(0xFF6D28D9), 'pct': {'resident': 0.5, 'nonresident': 0.5, 'firsttime': 0.5}, 'newBld': true},
        {'name': 'Registo', 'sub': 'Land Registry', 'icon': '📗', 'col': const Color(0xFF0F766E), 'pct': {'resident': 0.3, 'nonresident': 0.3, 'firsttime': 0.3}, 'newBld': true},
        {'name': 'Mediação imobiliária', 'sub': 'Estate Agent', 'icon': '🏠', 'col': const Color(0xFFB45309), 'pct': {'resident': 3.0, 'nonresident': 5.0, 'firsttime': 3.0}, 'newBld': false},
      ],
      'notes': [
        'IMT rate depends on purchase price and buyer type. Rates range 0–6.5% on a sliding scale.',
        'NHR (Non-Habitual Resident) status offers 10% flat tax for 10 years for qualifying buyers.',
        'Stamp duty applies on both the property price (0.8%) and mortgage amount (0.6%).',
        'The Golden Visa program uses real estate investment thresholds (€280,000+).'
      ]
    }
  };

  final List<Map<String, dynamic>> _comparisonData = [
    {'flag': '🇩🇪', 'name': 'Germany', 'pct': 10.6, 'col': const Color(0xFF003399)},
    {'flag': '🇫🇷', 'name': 'France', 'pct': 8.0, 'col': const Color(0xFF1E3A8A)},
    {'flag': '🇪🇸', 'name': 'Spain', 'pct': 9.5, 'col': Colors.red},
    {'flag': '🇮🇹', 'name': 'Italy', 'pct': 14.0, 'col': Colors.green},
    {'flag': '🇳🇱', 'name': 'Netherlands', 'pct': 3.0, 'col': Colors.orange},
    {'flag': '🇵🇹', 'name': 'Portugal', 'pct': 10.5, 'col': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _price = inputs['price'] ?? 350000.0;
      final buyerVal = inputs['buyerType'] ?? 0.0;
      _buyerType = _doubleToBuyerType[buyerVal] ?? 'resident';
      final propVal = inputs['propertyType'] ?? 0.0;
      _propertyType = _doubleToPropertyType[propVal] ?? 'resale';
      _countryCode = widget.savedCalc!.label.split(' - ').last;

      _calcSnapshot['countryCode'] = _countryCode;
      _calcSnapshot['price'] = _price;
      _calcSnapshot['buyerType'] = _buyerType;
      _calcSnapshot['propertyType'] = _propertyType;
      _hasCalculated = true;
    }
  }

  void _runCalc() {
    setState(() {
      _calcSnapshot['countryCode'] = _countryCode;
      _calcSnapshot['price'] = _price;
      _calcSnapshot['buyerType'] = _buyerType;
      _calcSnapshot['propertyType'] = _propertyType;
      _hasCalculated = true;
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

  void _reset() {
    setState(() {
      _countryCode = 'DE';
      _price = 350000;
      _buyerType = 'resident';
      _propertyType = 'resale';
      _hasCalculated = false;
      _calcSnapshot.clear();
    });
  }

  void _saveNotaryFees() async {
    if (!_hasCalculated) return;

    final double snapPrice = _calcSnapshot['price'] ?? _price;
    final String snapBuyerType = _calcSnapshot['buyerType'] ?? _buyerType;
    final String snapPropertyType = _calcSnapshot['propertyType'] ?? _propertyType;
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final cd = _countryClosingData[snapCountryCode]!;
    final isNew = snapPropertyType == 'new';

    List<Map<String, dynamic>> items = [];
    double totalFees = 0;

    final List<dynamic> rawFees = cd['fees'];
    for (final f in rawFees) {
      if (isNew && !f['newBld']) {
        continue;
      }
      final Map<String, dynamic> pctMap = f['pct'];
      final double pct = pctMap[snapBuyerType] ?? pctMap['resident'] ?? 0.0;
      if (pct > 0.0) {
        final double amt = snapPrice * (pct / 100);
        totalFees += amt;
        items.add({
          'name': f['name'],
          'pct': pct,
          'amt': amt,
        });
      }
    }

    if (snapCountryCode == 'ES' && isNew) {
      items = items.where((i) => i['name'] != 'ITP / AJD').toList();
      items.insert(0, {
        'name': 'IVA',
        'pct': 10.0,
        'amt': snapPrice * 0.10,
      });
      items.add({
        'name': 'AJD',
        'pct': 1.5,
        'amt': snapPrice * 0.015,
      });
      totalFees = items.fold(0.0, (sum, i) => sum + i['amt']);
    }

    if (snapCountryCode == 'FR' && isNew) {
      items = items.map((i) {
        if (i['name'] == 'Droits de mutation') {
          return {
            ...i,
            'pct': 0.7,
            'amt': snapPrice * 0.007,
          };
        }
        return i;
      }).toList();
      totalFees = items.fold(0.0, (sum, i) => sum + i['amt']);
    }

    final double deposit = snapPrice * 0.20;
    final double totalOutlay = snapPrice + totalFees;
    final double cashNeeded = deposit + totalFees;

    final labelCtrl = TextEditingController(text: 'Closing costs');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/eu_notary_fee_calc/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Closing Costs',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Total Fees ${CurrencyFormatter.compact(totalFees, symbol: '€')} · Cash Needed: ${CurrencyFormatter.compact(cashNeeded, symbol: '€')}',
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
                hintText: 'Label (e.g. Rome Flat Costs)',
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
              backgroundColor: widget.theme.primaryColor,
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
          : 'Closing costs';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Notary Fee Calc',
        inputs: {
          'price': snapPrice,
          'buyerType': _buyerTypeToDouble[snapBuyerType] ?? 0.0,
          'propertyType': _propertyTypeToDouble[snapPropertyType] ?? 0.0,
        },
        results: {
          'Total Fees': totalFees,
          'Total Outlay': totalOutlay,
          'Cash Needed': cashNeeded,
        },
        label: '$label - $snapCountryCode',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Closing costs saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedText = theme.getMutedColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double snapPrice = _calcSnapshot['price'] ?? _price;
    final String snapBuyerType = _calcSnapshot['buyerType'] ?? _buyerType;
    final String snapPropertyType = _calcSnapshot['propertyType'] ?? _propertyType;
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    // Dynamic fee calculations based on snapshot
    final cd = _countryClosingData[snapCountryCode]!;
    final String countryName = cd['name'];
    final isNew = snapPropertyType == 'new';

    List<Map<String, dynamic>> items = [];
    double totalFees = 0;

    final List<dynamic> rawFees = cd['fees'];
    for (final f in rawFees) {
      if (isNew && !f['newBld']) {
        continue; // skip agent/resale-only fees on new builds
      }

      final Map<String, dynamic> pctMap = f['pct'];
      final double pct = pctMap[snapBuyerType] ?? pctMap['resident'] ?? 0.0;
      
      if (pct > 0.0) {
        final double amt = snapPrice * (pct / 100);
        totalFees += amt;
        items.add({
          'name': f['name'],
          'sub': f['sub'],
          'icon': f['icon'],
          'col': f['col'],
          'pct': pct,
          'amt': amt,
        });
      }
    }

    // Special Spain calculations for new builds
    if (snapCountryCode == 'ES' && isNew) {
      items = items.where((i) => i['name'] != 'ITP / AJD').toList();
      items.insert(0, {
        'name': 'IVA',
        'sub': 'VAT 10% (New Build)',
        'icon': '🏛️',
        'col': const Color(0xFF003399),
        'pct': 10.0,
        'amt': snapPrice * 0.10,
      });
      items.add({
        'name': 'AJD',
        'sub': 'Stamp Duty 1.5%',
        'icon': '🏛️',
        'col': const Color(0xFF1E3A8A),
        'pct': 1.5,
        'amt': snapPrice * 0.015,
      });
      totalFees = items.fold(0.0, (sum, i) => sum + i['amt']);
    }

    // French VEFA transfer tax reduction
    if (snapCountryCode == 'FR' && isNew) {
      items = items.map((i) {
        if (i['name'] == 'Droits de mutation') {
          return {
            ...i,
            'pct': 0.7,
            'amt': snapPrice * 0.007,
            'sub': 'Reduced Transfer Tax (VEFA)',
          };
        }
        return i;
      }).toList();
      totalFees = items.fold(0.0, (sum, i) => sum + i['amt']);
    }

    final double deposit = snapPrice * 0.20; // assumed 20% down
    final double totalOutlay = snapPrice + totalFees;
    final double cashNeeded = deposit + totalFees;

    final notes = List<String>.from(cd['notes']);

    // Live ECB rate
    final liveEcb = ref.watch(europeRatesProvider).valueOrNull?.ecbRate.value ?? 4.00;
    final isLive = ref.watch(europeRatesProvider).valueOrNull?.isLive == true;

    final isDirty = _hasCalculated && (
      _price != snapPrice ||
      _buyerType != snapBuyerType ||
      _propertyType != snapPropertyType ||
      _countryCode != snapCountryCode
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate strip on top
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _closingStripItem('🇩🇪 Germany', '~1.5%', 'Notary'),
              _closingDivider(),
              _closingStripItem('🇫🇷 France', '~7.0%', 'Frais'),
              _closingDivider(),
              _closingStripItem('🇪🇸 Spain', '~0.5%', 'Notaría'),
              _closingDivider(),
              _closingStripItem('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Rate'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Country Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SELECT COUNTRY', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
            GestureDetector(
              onTap: _reset,
              child: Text('Reset', style: AppTextStyles.dmSans(size: 11, color: theme.primaryColor, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _countryClosingData.keys.map((code) {
              final active = _countryCode == code;
              final data = _countryClosingData[code]!;
              return GestureDetector(
                onTap: () => setState(() => _countryCode = code),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? (isDark ? theme.accentColor : theme.primaryColor) : cardBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: active ? (isDark ? theme.accentColor : theme.primaryColor) : borderCol),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${data['flag']} ${data['name']}',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: active
                          ? (isDark ? Colors.black : const Color(0xFFFFCC00))
                          : (isDark ? theme.getMutedColor(context) : theme.primaryColor),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏠 Purchase Details', style: AppTextStyles.cardTitle(textColor)),
              const SizedBox(height: 14),

              // Property price slider
              _sliderHeader('Property Purchase Price', CurrencyFormatter.format(_price, symbol: '€')),
              Slider(
                value: _price,
                min: 50000,
                max: 1500000,
                divisions: 145,
                activeColor: isDark ? theme.accentColor : theme.primaryColor,
                inactiveColor: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15),
                onChanged: (v) => setState(() => _price = v),
              ),

              // Buyer Type & Property Type Selectors
              Row(
                children: [
                  Expanded(
                    child: _dropdownInputBox(
                      'Buyer Profile',
                      _buyerType,
                      [
                        const DropdownMenuItem(value: 'resident', child: Text('EU Resident', style: TextStyle(fontSize: 12))),
                        const DropdownMenuItem(value: 'nonresident', child: Text('Non-Resident', style: TextStyle(fontSize: 12))),
                        const DropdownMenuItem(value: 'firsttime', child: Text('First-Time Buyer', style: TextStyle(fontSize: 12))),
                      ],
                      (val) {
                        if (val != null) setState(() => _buyerType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdownInputBox(
                      'Property Condition',
                      _propertyType,
                      [
                        const DropdownMenuItem(value: 'new', child: Text('New Build', style: TextStyle(fontSize: 12))),
                        const DropdownMenuItem(value: 'resale', child: Text('Resale / Used', style: TextStyle(fontSize: 12))),
                      ],
                      (val) {
                        if (val != null) setState(() => _propertyType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _runCalc,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFCC00), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📜', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Calculate Closing Costs',
                          style: AppTextStyles.dmSans(
                              size: 14, weight: FontWeight.w900, color: const Color(0xFF1A0040))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_hasCalculated) ...[
          Column(
            key: _resultsKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDirty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Inputs have changed. Calculate again to update results.',
                          style: AppTextStyles.dmSans(
                            size: 11.5,
                            color: const Color(0xFFB45309),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Results Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: theme.headerGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Closing Costs / Fees', style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalFees, symbol: '€'),
                      style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((totalFees / snapPrice) * 100).toStringAsFixed(1)}% of price · $countryName',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _resultMiniBox('Purchase Price', CurrencyFormatter.format(snapPrice, symbol: '€')),
                        _resultMiniBox('Total Outlay', CurrencyFormatter.format(totalOutlay, symbol: '€')),
                        _resultMiniBox('Cash Needed', CurrencyFormatter.format(cashNeeded, symbol: '€')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 0.5, color: Colors.white12),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _saveNotaryFees,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC00).withValues(alpha: 0.18),
                                border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.45)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('💾 Save Calculation', style: AppTextStyles.dmSans(size: 12, color: const Color(0xFFFFCC00), weight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Card (Donut Chart + List)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost Breakdown', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 14),
                    // Stacked Ratio Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Row(
                          children: items.map((it) {
                            final double share = totalFees > 0 ? (it['amt'] / totalFees) : 0.0;
                            return Expanded(
                              flex: (share * 100).round(),
                              child: Container(color: it['col']),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Donut Chart Row
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: NotaryDonutPainter(
                              items: items,
                              total: totalFees,
                              pctTotal: (totalFees / snapPrice) * 100,
                              isDark: isDark,
                              theme: theme,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: items.map((it) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: it['col'], shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        it['name'],
                                        style: AppTextStyles.dmSans(size: 10.5, color: textColor, weight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.compact(it['amt'], symbol: '€'),
                                      style: AppTextStyles.playfair(size: 11, color: isDark ? theme.accentColor : theme.primaryColor, weight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Detailed list
                    ...items.map((it) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: (it['col'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text(it['icon'], style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(it['name'], style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textColor)),
                                  Text(it['sub'], style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(CurrencyFormatter.format(it['amt'], symbol: '€'),
                                    style: AppTextStyles.playfair(size: 12.5, color: isDark ? theme.accentColor : theme.primaryColor, weight: FontWeight.bold)),
                                Text('${it['pct'].toStringAsFixed(2)}% of price',
                                    style: AppTextStyles.dmSans(size: 9.5, color: mutedText)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Closing Costs', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textColor)),
                        Text(CurrencyFormatter.format(totalFees, symbol: '€'),
                            style: AppTextStyles.playfair(size: 15, color: isDark ? theme.accentColor : theme.primaryColor, weight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Country comparison card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Country Cost Comparison', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 4),
                    Text('Typical closing fees as % of purchase price', style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                    const SizedBox(height: 14),
                    ..._comparisonData.map((d) {
                      final active = d['name'] == countryName;
                      final double val = d['pct'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text(d['flag'], style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: Text(
                                d['name'],
                                style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: active ? FontWeight.bold : FontWeight.normal,
                                  color: active ? (isDark ? theme.accentColor : theme.primaryColor) : textColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Container(
                                  height: 8,
                                  color: theme.getBgColor(context),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: val / 14.0,
                                      child: Container(color: active ? (isDark ? theme.accentColor : theme.primaryColor) : (d['col'] as Color).withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${val.toStringAsFixed(1)}%',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.playfair(
                                  size: 11,
                                  weight: active ? FontWeight.bold : FontWeight.normal,
                                  color: active ? (isDark ? theme.accentColor : theme.primaryColor) : textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Country notes card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B).withValues(alpha: 0.4), const Color(0xFF1E1B4B).withValues(alpha: 0.15)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFF818CF8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏛️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text('$countryName – Important Notes', style: AppTextStyles.cardTitle(isDark ? Colors.white : const Color(0xFF1E1B4B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...notes.map((n) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•', style: TextStyle(color: isDark ? Colors.purpleAccent : const Color(0xFF4338CA), fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                n,
                                style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF4338CA), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                const Text('📜', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Calculate Closing Costs',
                    style: AppTextStyles.playfair(
                        size: 15, weight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  'Select country, property price, buyer type, and condition,\nthen tap Calculate to see a detailed notary & tax breakdown.',
                  style: AppTextStyles.dmSans(size: 11, color: mutedText, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _closingStripItem(String country, String val, String subtitle) {
    return Column(
      children: [
        Text(country, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
        const SizedBox(height: 1),
        Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _closingDivider() {
    return Container(
      width: 0.5,
      height: 26,
      color: widget.theme.getBorderColor(context),
    );
  }

  Widget _sliderHeader(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))),
          Text(value, style: AppTextStyles.playfair(size: 13, color: isDark ? widget.theme.accentColor : widget.theme.primaryColor, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _dropdownInputBox(String label, String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultMiniBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.playfair(size: 11.5, color: Colors.white, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class NotaryDonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final double total;
  final double pctTotal;
  final bool isDark;
  final CountryTheme theme;

  NotaryDonutPainter({
    required this.items,
    required this.total,
    required this.pctTotal,
    required this.isDark,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (final it in items) {
      final double share = total > 0 ? (it['amt'] / total) : 0.0;
      if (share <= 0.0) continue;
      final double sweepAngle = share * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = it['col'];

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Inside text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final titleSpan = TextSpan(
      text: 'Fees',
      style: TextStyle(
          color: isDark ? Colors.purple.shade200 : Colors.purple.shade900,
          fontSize: 8,
          fontWeight: FontWeight.bold),
    );
    textPainter.text = titleSpan;
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height - 1));

    final valSpan = TextSpan(
      text: '${pctTotal.toStringAsFixed(1)}%',
      style: TextStyle(
          color: isDark ? theme.accentColor : const Color(0xFF003399),
          fontSize: 10,
          fontWeight: FontWeight.w900),
    );
    textPainter.text = valSpan;
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy + 1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
