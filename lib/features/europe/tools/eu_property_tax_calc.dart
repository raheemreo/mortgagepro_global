// lib/features/europe/tools/eu_property_tax_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUPropertyTaxCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUPropertyTaxCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUPropertyTaxCalc> createState() => _EUPropertyTaxCalcState();
}

class _EUPropertyTaxCalcState extends ConsumerState<EUPropertyTaxCalc>
    with SingleTickerProviderStateMixin {
  String _countryCode = 'DE';
  double _price = 420000;
  String _propertyType = 'new'; // new, resale, land
  String _buyerType = 'resident'; // resident, nonresident, investor
  bool _hasCalculated = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Map<String, double> _propertyTypeToDouble = {
    'new': 0.0,
    'resale': 1.0,
    'land': 2.0,
  };

  static final Map<double, String> _doubleToPropertyType = {
    0.0: 'new',
    1.0: 'resale',
    2.0: 'land',
  };

  static const Map<String, double> _buyerTypeToDouble = {
    'resident': 0.0,
    'nonresident': 1.0,
    'investor': 2.0,
  };

  static final Map<double, String> _doubleToBuyerType = {
    0.0: 'resident',
    1.0: 'nonresident',
    2.0: 'investor',
  };

  final Map<String, Map<String, dynamic>> _countryData = {
    'DE': {
      'name': 'Germany',
      'flag': '🇩🇪',
      'taxRange': '3.5–6.5%',
      'taxes': {
        'new': {'transfer': 3.5, 'notary': 1.2, 'registry': 0.5, 'agent': 1.2},
        'resale': {'transfer': 6.5, 'notary': 1.2, 'registry': 0.5, 'agent': 3.5},
        'land': {'transfer': 6.5, 'notary': 1.2, 'registry': 0.5, 'agent': 1.5},
      },
      'transferName': 'Grunderwerbsteuer',
      'euRank': 3,
      'timeline': [
        {'icon': '📝', 'phase': 'Notarvertrag (Notary)', 'desc': 'Notary drafts & signs contract', 'when': 'Week 1–2'},
        {'icon': '💰', 'phase': 'Grunderwerbsteuer', 'desc': 'Land Transfer Tax to state', 'when': '4–6 weeks'},
        {'icon': '📜', 'phase': 'Land Registry (Grundbuch)', 'desc': 'Ownership registration', 'when': '6–12 weeks'},
      ],
    },
    'FR': {
      'name': 'France',
      'flag': '🇫🇷',
      'taxRange': '2–8%',
      'taxes': {
        'new': {'transfer': 2.0, 'notary': 2.5, 'registry': 0.5, 'agent': 3.0},
        'resale': {'transfer': 5.8, 'notary': 2.5, 'registry': 1.0, 'agent': 3.0},
        'land': {'transfer': 5.8, 'notary': 2.5, 'registry': 1.0, 'agent': 2.5},
      },
      'transferName': 'Droits de Mutation',
      'euRank': 5,
      'timeline': [
        {'icon': '📋', 'phase': 'Compromis de Vente', 'desc': 'Preliminary sale agreement', 'when': 'Day 1'},
        {'icon': '🏛️', 'phase': 'Frais de Notaire', 'desc': 'Notary fees + state taxes', 'when': 'At completion'},
        {'icon': '📜', 'phase': 'Acte Authentique', 'desc': 'Final deed & registration', 'when': '3–4 months'},
      ],
    },
    'ES': {
      'name': 'Spain',
      'flag': '🇪🇸',
      'taxRange': '6–10%',
      'taxes': {
        'new': {'transfer': 1.0, 'notary': 0.8, 'registry': 0.4, 'agent': 3.0},
        'resale': {'transfer': 7.0, 'notary': 0.8, 'registry': 0.4, 'agent': 3.0},
        'land': {'transfer': 8.0, 'notary': 0.8, 'registry': 0.4, 'agent': 2.0},
      },
      'transferName': 'ITP / AJD',
      'euRank': 6,
      'timeline': [
        {'icon': '📝', 'phase': 'Contrato de Arras', 'desc': 'Reservation deposit (10%)', 'when': 'Day 1'},
        {'icon': '💰', 'phase': 'ITP Tax Payment', 'desc': 'Transfer tax to Hacienda', 'when': '30 days'},
        {'icon': '📜', 'phase': 'Escritura Pública', 'desc': 'Final deed at Notary', 'when': '4–8 weeks'},
      ],
    },
    'IT': {
      'name': 'Italy',
      'flag': '🇮🇹',
      'taxRange': '2–9%',
      'taxes': {
        'new': {'transfer': 4.0, 'notary': 1.5, 'registry': 0.2, 'agent': 3.0},
        'resale': {'transfer': 9.0, 'notary': 1.5, 'registry': 0.2, 'agent': 3.0},
        'land': {'transfer': 9.0, 'notary': 1.5, 'registry': 0.2, 'agent': 2.0},
      },
      'transferName': 'Imposta Registro',
      'euRank': 6,
      'timeline': [
        {'icon': '📋', 'phase': 'Proposta Irrevocabile', 'desc': 'Irrevocable offer', 'when': 'Week 1'},
        {'icon': '🏛️', 'phase': 'Rogito Notarile', 'desc': 'Final notarial deed', 'when': '4–8 weeks'},
        {'icon': '💰', 'phase': 'Imposta di Registro', 'desc': 'Registration/transfer tax', 'when': 'At closing'},
      ],
    },
    'NL': {
      'name': 'Netherlands',
      'flag': '🇳🇱',
      'taxRange': '2%',
      'taxes': {
        'new': {'transfer': 0.0, 'notary': 1.0, 'registry': 0.3, 'agent': 1.0},
        'resale': {'transfer': 2.0, 'notary': 1.0, 'registry': 0.3, 'agent': 1.0},
        'land': {'transfer': 8.0, 'notary': 1.0, 'registry': 0.3, 'agent': 1.0},
      },
      'transferName': 'Overdrachtsbelasting',
      'euRank': 1,
      'timeline': [
        {'icon': '📝', 'phase': 'Koopovereenkomst', 'desc': 'Purchase agreement signed', 'when': 'Day 1'},
        {'icon': '💰', 'phase': 'Overdrachtsbelasting', 'desc': 'Transfer tax (2% resale)', 'when': 'At notary'},
        {'icon': '📜', 'phase': 'Akte van Levering', 'desc': 'Transfer deed at notary', 'when': '4–6 weeks'},
      ],
    },
    'PT': {
      'name': 'Portugal',
      'flag': '🇵🇹',
      'taxRange': '0.8–6.5%',
      'taxes': {
        'new': {'transfer': 0.8, 'notary': 1.2, 'registry': 0.3, 'agent': 3.0},
        'resale': {'transfer': 6.5, 'notary': 1.2, 'registry': 0.3, 'agent': 3.0},
        'land': {'transfer': 6.5, 'notary': 1.2, 'registry': 0.3, 'agent': 2.5},
      },
      'transferName': 'IMT Tax',
      'euRank': 4,
      'timeline': [
        {'icon': '📋', 'phase': 'Contrato Promessa', 'desc': 'Promissory purchase contract', 'when': 'Week 1'},
        {'icon': '💰', 'phase': 'IMT Payment', 'desc': 'Municipal property transfer tax', 'when': 'Before deeds'},
        {'icon': '📜', 'phase': 'Escritura Pública', 'desc': 'Final deed at Notary/IRN', 'when': '4–8 weeks'},
      ],
    },
  };

  final List<Map<String, dynamic>> _compareData = [
    {'flag': '🇳🇱', 'name': 'Netherlands', 'pct': 2.0, 'col': const Color(0xFF9A3412)},
    {'flag': '🇩🇪', 'name': 'Germany', 'pct': 5.0, 'col': const Color(0xFF003399)},
    {'flag': '🇵🇹', 'name': 'Portugal', 'pct': 6.5, 'col': const Color(0xFF4338CA)},
    {'flag': '🇫🇷', 'name': 'France', 'pct': 7.5, 'col': const Color(0xFF1E3A8A)},
    {'flag': '🇪🇸', 'name': 'Spain', 'pct': 8.5, 'col': const Color(0xFFDC2626)},
    {'flag': '🇮🇹', 'name': 'Italy', 'pct': 9.0, 'col': const Color(0xFF166534)},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _price = inputs['price'] ?? 420000.0;
      final propVal = inputs['propertyType'] ?? 0.0;
      _propertyType = _doubleToPropertyType[propVal] ?? 'new';
      final buyerVal = inputs['buyerType'] ?? 0.0;
      _buyerType = _doubleToBuyerType[buyerVal] ?? 'resident';
      _countryCode = widget.savedCalc!.label.split(' - ').last;
      _hasCalculated = true;
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _runCalc() {
    setState(() => _hasCalculated = true);
    _animController.forward(from: 0.0);
  }

  void _savePropertyTax(double totalTax, double totalPct) async {
    final labelCtrl = TextEditingController(text: 'Property Taxes');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Property Tax',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Total Taxes ${CurrencyFormatter.compact(totalTax, symbol: '€')} (${totalPct.toStringAsFixed(1)}%)',
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
                hintText: 'Label (e.g. Lisbon Villa Tax)',
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
          : 'Property Taxes';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Property Tax Calc',
        inputs: {
          'price': _price,
          'propertyType': _propertyTypeToDouble[_propertyType] ?? 0.0,
          'buyerType': _buyerTypeToDouble[_buyerType] ?? 0.0,
        },
        results: {
          'Tax Amount': totalTax,
          'Tax Percent': totalPct,
        },
        label: '$label - $_countryCode',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Property tax analysis saved!',
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

    final c = _countryData[_countryCode]!;
    final String countryName = c['name'];
    final taxes = c['taxes'][_propertyType] ?? c['taxes']['resale'];

    double transferRate = taxes['transfer'];
    if (_buyerType == 'nonresident') transferRate *= 1.20;
    if (_buyerType == 'investor') transferRate *= 1.35;

    final transferVal = _price * (transferRate / 100);
    final notaryVal = _price * (taxes['notary'] / 100);
    final registryVal = _price * (taxes['registry'] / 100);
    final agentVal = _price * (taxes['agent'] / 100);

    final totalTax = transferVal + notaryVal + registryVal + agentVal;
    final totalPct = _price > 0 ? (totalTax / _price) * 100 : 0.0;
    final monthlySpread = totalTax / 360.0;

    final List<Map<String, dynamic>> segments = [
      {'name': c['transferName'] ?? 'Transfer Tax', 'val': transferVal, 'pct': transferRate, 'color': const Color(0xFF003399), 'icon': '📅'},
      {'name': 'Notary / Legal Fee', 'val': notaryVal, 'pct': taxes['notary'], 'color': const Color(0xFF6D28D9), 'icon': '🏛️'},
      {'name': 'Land Registry', 'val': registryVal, 'pct': taxes['registry'], 'color': const Color(0xFF0F766E), 'icon': '📜'},
      {'name': 'Agency Fee', 'val': agentVal, 'pct': taxes['agent'], 'color': const Color(0xFFB45309), 'icon': '🤝'},
    ];

    // Insight
    String insightTitle;
    String insightText;
    if (totalPct <= 3.5) {
      insightTitle = '🟢 Low Tax Burden';
      insightText = 'At ${totalPct.toStringAsFixed(1)}% of purchase price, $countryName is one of Europe\'s most buyer-friendly markets for this property type.';
    } else if (totalPct <= 6.0) {
      insightTitle = '🟡 Moderate Cost';
      insightText = '${totalPct.toStringAsFixed(1)}% total tax burden is typical for $countryName. Budget ${CurrencyFormatter.compact(totalTax, symbol: '€')} on top of your purchase price.';
    } else {
      insightTitle = '🔴 High Tax Load';
      insightText = 'At ${totalPct.toStringAsFixed(1)}%, your upfront costs are significant. Consider factoring this into your financing plan from day one.';
    }
    if (_buyerType == 'nonresident') insightText += ' Non-resident surcharge of 20% applies to transfer tax.';
    if (_buyerType == 'investor') insightText += ' Investor bracket attracts a 35% transfer tax premium.';

    final rankLabels = ['1st', '2nd', '3rd', '4th', '5th', '6th'];
    final euRank = c['euRank'] as int;
    final rankLabel = euRank >= 1 && euRank <= 6 ? rankLabels[euRank - 1] : '—';

    final List<Map<String, dynamic>> timeline = List<Map<String, dynamic>>.from(c['timeline']);

    // Live ECB rate
    final liveEcb = ref.watch(europeRatesProvider).valueOrNull?.ecbRate.value ?? 4.00;
    final isLive = ref.watch(europeRatesProvider).valueOrNull?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Rate Strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rateStripItem('🇩🇪 GrESt', '3.5–6.5%', 'Transfer Tax', mutedText, textColor),
              _rateDivider(borderCol),
              _rateStripItem('🇫🇷 Notaire', '7–8%', 'Old Build', mutedText, textColor),
              _rateDivider(borderCol),
              _rateStripItem('🇪🇸 ITP', '6–10%', 'Resale', mutedText, textColor),
              _rateDivider(borderCol),
              _rateStripItem('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Rate', mutedText, const Color(0xFFFFD700)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Country Grid ──
        Text('SELECT COUNTRY',
            style: AppTextStyles.dmSans(
                size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: _countryData.keys.map((code) {
            final active = _countryCode == code;
            final data = _countryData[code]!;
            return GestureDetector(
              onTap: () => setState(() => _countryCode = code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: active ? (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.08) : cardBg,
                  border: Border.all(
                      color: active ? (isDark ? theme.accentColor : theme.primaryColor) : borderCol,
                      width: active ? 2.0 : 1.0),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [BoxShadow(color: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data['flag'], style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text(data['name'],
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            weight: FontWeight.bold,
                            color: active ? (isDark ? theme.accentColor : theme.primaryColor) : textColor)),
                    Text(data['taxRange'],
                        style: AppTextStyles.playfair(
                            size: 10,
                            weight: FontWeight.w800,
                            color: active ? (isDark ? theme.accentColor : theme.primaryColor) : mutedText)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // ── Property Details Card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏠 Property Details', style: AppTextStyles.cardTitle(textColor)),
              const SizedBox(height: 14),

              // Price slider
              _sliderHeader('Purchase Price', CurrencyFormatter.format(_price, symbol: '€'), mutedText),
              Slider(
                value: _price,
                min: 50000,
                max: 3000000,
                divisions: 590,
                activeColor: isDark ? theme.accentColor : theme.primaryColor,
                inactiveColor: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15),
                onChanged: (v) => setState(() => _price = v),
              ),

              // Property Type
              const SizedBox(height: 4),
              Text('PROPERTY TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9.5, weight: FontWeight.w700, color: mutedText, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _segButton('new', 'New Build', _propertyType, (t) => setState(() => _propertyType = t)),
                  const SizedBox(width: 6),
                  _segButton('resale', 'Resale', _propertyType, (t) => setState(() => _propertyType = t)),
                  const SizedBox(width: 6),
                  _segButton('land', 'Land', _propertyType, (t) => setState(() => _propertyType = t)),
                ],
              ),

              // Buyer Type
              const SizedBox(height: 14),
              Text('BUYER TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9.5, weight: FontWeight.w700, color: mutedText, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _segButton('resident', 'Resident', _buyerType, (t) => setState(() => _buyerType = t)),
                  const SizedBox(width: 6),
                  _segButton('nonresident', 'Non-Resident', _buyerType, (t) => setState(() => _buyerType = t)),
                  const SizedBox(width: 6),
                  _segButton('investor', 'Investor', _buyerType, (t) => setState(() => _buyerType = t)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Action Row: Calculate + Save ──
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _runCalc,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003399), Color(0xFF1A0040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF003399).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🧮', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Calculate Tax',
                          style: AppTextStyles.dmSans(
                              size: 14, weight: FontWeight.w800, color: const Color(0xFFFFCC00))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _hasCalculated ? () => _savePropertyTax(totalTax, totalPct) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _hasCalculated ? (isDark ? theme.accentColor : theme.primaryColor) : cardBg,
                  border: Border.all(
                      color: _hasCalculated ? (isDark ? theme.accentColor : theme.primaryColor) : borderCol,
                      width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  _hasCalculated ? '✅' : '💾',
                  style: TextStyle(
                      fontSize: 18,
                      color: _hasCalculated ? (isDark ? Colors.black : const Color(0xFFFFCC00)) : mutedText),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Results Section (animated) ──
        if (_hasCalculated)
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero result
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
                      Text('Total Tax & Fees',
                          style: AppTextStyles.dmSans(
                              size: 11, color: Colors.white70, weight: FontWeight.w600, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalTax, symbol: '€'),
                        style: AppTextStyles.playfair(
                            size: 36, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c['flag']} ${c['name']} · ${_propertyType[0].toUpperCase()}${_propertyType.substring(1)} · ${_buyerType[0].toUpperCase()}${_buyerType.substring(1)}',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                      ),
                      const SizedBox(height: 14),
                      // 2×2 result grid
                      Row(
                        children: [
                          _rhBox('Transfer Tax', CurrencyFormatter.format(transferVal, symbol: '€'),
                              '${(totalTax > 0 ? (transferVal / totalTax * 100) : 0).toStringAsFixed(1)}% of total'),
                          const SizedBox(width: 8),
                          _rhBox('Notary/Legal', CurrencyFormatter.format(notaryVal, symbol: '€'),
                              '${(totalTax > 0 ? (notaryVal / totalTax * 100) : 0).toStringAsFixed(1)}% of total'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _rhBox('Land Registry', CurrencyFormatter.format(registryVal, symbol: '€'),
                              '${(totalTax > 0 ? (registryVal / totalTax * 100) : 0).toStringAsFixed(1)}% of total'),
                          const SizedBox(width: 8),
                          _rhBox('Agent Fee', CurrencyFormatter.format(agentVal, symbol: '€'),
                              '${(totalTax > 0 ? (agentVal / totalTax * 100) : 0).toStringAsFixed(1)}% of total'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stat Row (3 boxes)
                Row(
                  children: [
                    _statBox('of Price', '${totalPct.toStringAsFixed(1)}%', cardBg, borderCol, textColor, mutedText),
                    const SizedBox(width: 8),
                    _statBox('Spread / mo', CurrencyFormatter.compact(monthlySpread, symbol: '€'), cardBg, borderCol, textColor, mutedText),
                    const SizedBox(width: 8),
                    _statBox('EU Rank', rankLabel, cardBg, borderCol, textColor, mutedText),
                  ],
                ),
                const SizedBox(height: 14),

                // Donut Fee Composition Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🥧 Fee Composition', style: AppTextStyles.cardTitle(textColor)),
                      const SizedBox(height: 14),
                      // SVG-style donut with CustomPaint
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(160, 160),
                                painter: PropertyTaxDonutPainter(
                                  segments: segments,
                                  total: totalTax,
                                  isDark: isDark,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('TOTAL',
                                      style: AppTextStyles.dmSans(
                                          size: 9, weight: FontWeight.w700, color: isDark ? Colors.purple.shade200 : const Color(0xFF6B21A8))),
                                  Text(
                                    CurrencyFormatter.compact(totalTax, symbol: '€'),
                                    style: AppTextStyles.playfair(
                                        size: 14, weight: FontWeight.w900, color: isDark ? theme.accentColor : const Color(0xFF003399)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2×2 legend grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        children: segments.map((seg) {
                          final share = totalTax > 0 ? (seg['val'] / totalTax * 100) : 0.0;
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (seg['color'] as Color).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: (seg['color'] as Color).withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                      color: seg['color'] as Color,
                                      borderRadius: BorderRadius.circular(3)),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(seg['name'],
                                          style: AppTextStyles.dmSans(
                                              size: 9, weight: FontWeight.w700, color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text('${share.toStringAsFixed(1)}%',
                                          style: AppTextStyles.dmSans(
                                              size: 9, color: isDark ? Colors.purple.shade200 : const Color(0xFF6B21A8))),
                                    ],
                                  ),
                                ),
                                Text(CurrencyFormatter.compact(seg['val'], symbol: '€'),
                                    style: AppTextStyles.playfair(
                                        size: 10,
                                        weight: FontWeight.w800,
                                        color: seg['color'] as Color)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tax Breakdown Timeline
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Tax Breakdown Timeline', style: AppTextStyles.cardTitle(textColor)),
                      const SizedBox(height: 12),
                      // Fee timeline items
                      ...segments.asMap().entries.map((entry) {
                        final seg = entry.value;
                        final isLast = entry.key == segments.length - 1;
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (seg['color'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(seg['icon'], style: const TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(seg['name'],
                                          style: AppTextStyles.dmSans(
                                              size: 12.5, weight: FontWeight.w800, color: textColor)),
                                      Text(
                                        '${(seg['pct'] as double).toStringAsFixed(2)}% fee rate',
                                        style: AppTextStyles.dmSans(size: 10, color: mutedText),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(seg['val'], symbol: '€'),
                                  style: AppTextStyles.playfair(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: seg['color'] as Color),
                                ),
                              ],
                            ),
                            if (!isLast) ...[
                              const SizedBox(height: 10),
                              Divider(height: 1, color: borderCol),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      // Country-specific timeline
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c['name']} Purchase Milestones',
                                style: AppTextStyles.dmSans(
                                    size: 11, weight: FontWeight.w800, color: isDark ? theme.accentColor : theme.primaryColor)),
                            const SizedBox(height: 10),
                            ...timeline.map((step) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Text(step['icon'], style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(step['phase'],
                                              style: AppTextStyles.dmSans(
                                                  size: 11, weight: FontWeight.w700, color: textColor)),
                                          Text(step['desc'],
                                              style: AppTextStyles.dmSans(
                                                  size: 9.5, color: mutedText)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(step['when'],
                                          style: AppTextStyles.dmSans(
                                              size: 9,
                                              weight: FontWeight.w700,
                                              color: isDark ? theme.accentColor : theme.primaryColor)),
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
                ),
                const SizedBox(height: 14),

                // Insight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B21A8), Color(0xFF1A0040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(insightTitle,
                                style: AppTextStyles.dmSans(
                                    size: 12, color: const Color(0xFFFFCC00), weight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(insightText,
                                style: AppTextStyles.dmSans(
                                    size: 11, color: Colors.white.withValues(alpha: 0.8), height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // EU Transfer Tax Comparison bars
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 EU Transfer Tax Comparison', style: AppTextStyles.cardTitle(textColor)),
                      const SizedBox(height: 4),
                      Text('Average transfer taxes across target countries',
                          style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                      const SizedBox(height: 12),
                      ...(_compareData
                        ..sort((a, b) => (a['pct'] as double).compareTo(b['pct'] as double)))
                          .map((d) {
                        final active = d['name'] == c['name'];
                        final double val = d['pct'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(d['flag'], style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      d['name'],
                                      style: AppTextStyles.dmSans(
                                        size: 11,
                                        weight: active ? FontWeight.w800 : FontWeight.w500,
                                        color: active ? (isDark ? theme.accentColor : theme.primaryColor) : textColor,
                                      ),
                                    ),
                                  ),
                                  if (active)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? theme.accentColor : theme.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('YOU',
                                          style: AppTextStyles.dmSans(
                                              size: 8, weight: FontWeight.w800, color: isDark ? Colors.black : const Color(0xFFFFCC00))),
                                    ),
                                  Text(
                                    '${val.toStringAsFixed(1)}%',
                                    style: AppTextStyles.playfair(
                                      size: 12,
                                      weight: active ? FontWeight.bold : FontWeight.normal,
                                      color: active ? (isDark ? theme.accentColor : theme.primaryColor) : textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  height: 10,
                                  color: theme.getBgColor(context),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: val / 10.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: active
                                              ? (isDark ? theme.accentColor : theme.primaryColor)
                                              : (d['col'] as Color).withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                    ),
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
              ],
            ),
          )
        else
          // Empty state
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Calculate Property Tax',
                    style: AppTextStyles.playfair(
                        size: 15, weight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  'Select a country, adjust the sliders,\nthen tap Calculate Tax to see results.',
                  style: AppTextStyles.dmSans(size: 11, color: mutedText, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _rateStripItem(String label, String val, String subtitle, Color mutedText, Color textColor) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedText)),
        const SizedBox(height: 2),
        Text(val,
            style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 1),
        Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: mutedText)),
      ],
    );
  }

  Widget _rateDivider(Color borderCol) {
    return Container(width: 0.5, height: 26, color: borderCol);
  }

  Widget _sliderHeader(String label, String value, Color mutedText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText)),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 13, color: isDark ? widget.theme.accentColor : widget.theme.primaryColor, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _segButton(String key, String label, String currentVal, ValueChanged<String> onChanged) {
    final active = currentVal == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF003399) : widget.theme.getCardColor(context),
            border: Border.all(
                color: active ? const Color(0xFF003399) : widget.theme.getBorderColor(context),
                width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w700,
              color: active ? const Color(0xFFFFCC00) : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rhBox(String label, String value, String pct) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(value,
                style: AppTextStyles.playfair(
                    size: 13, color: Colors.white, weight: FontWeight.w800)),
            Text(pct, style: AppTextStyles.dmSans(size: 9, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color cardBg, Color borderCol,
      Color textColor, Color mutedText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderCol),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.playfair(
                    size: 16, weight: FontWeight.w900, color: isDark ? widget.theme.accentColor : widget.theme.primaryColor)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, weight: FontWeight.w700, color: mutedText, letterSpacing: 0.3),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class PropertyTaxDonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final double total;
  final bool isDark;

  PropertyTaxDonutPainter({
    required this.segments,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 22.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE0E7FF);
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;

    for (final seg in segments) {
      final double val = seg['val'];
      final double share = total > 0 ? (val / total) : 0.0;
      if (share <= 0.0) continue;
      final double sweepAngle = share * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = seg['color'];

      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
