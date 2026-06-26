// lib/features/europe/tools/eu_nonresident_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUNonResidentCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUNonResidentCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUNonResidentCalc> createState() => _EUNonResidentCalcState();
}

class _EUNonResidentCalcState extends ConsumerState<EUNonResidentCalc> {
  String _countryCode = 'DE';
  double _price = 400000;
  String _buyerOrigin = 'eu_nonres'; // eu_nonres, uk, us, other
  String _purpose = 'holiday'; // holiday, investment, relocation, goldvisa
  double _income = 90000;
  double _existingDebt = 0;
  bool _calculated = false;

  static const Map<String, double> _originToDouble = {
    'eu_nonres': 0.0,
    'uk': 1.0,
    'us': 2.0,
    'other': 3.0,
  };

  static final Map<double, String> _doubleToOrigin = {
    0.0: 'eu_nonres',
    1.0: 'uk',
    2.0: 'us',
    3.0: 'other',
  };

  static const Map<String, double> _purposeToDouble = {
    'holiday': 0.0,
    'investment': 1.0,
    'relocation': 2.0,
    'goldvisa': 3.0,
  };

  static final Map<double, String> _doubleToPurpose = {
    0.0: 'holiday',
    1.0: 'investment',
    2.0: 'relocation',
    3.0: 'goldvisa',
  };

  final Map<String, Map<String, dynamic>> _countryData = {
    'DE': {
      'name': 'Germany',
      'flag': '🇩🇪',
      'maxLTV': {'eu_nonres': 60.0, 'uk': 60.0, 'us': 50.0, 'other': 50.0},
      'rateAdder': 0.5,
      'closingPct': 10.57,
      'steps': [
        'Appoint a German solicitor (Notar) – required by law',
        'Obtain German tax ID (Steuer-ID) from Finanzamt',
        'Open a German bank account (required for mortgage)',
        'Get credit pre-approval from German bank',
        'Sign preliminary contract (Vorvertrag)',
        'Notarize sale contract',
        'Pay Grunderwerbsteuer within 1 month',
        'Register in Grundbuch (land registry)'
      ]
    },
    'FR': {
      'name': 'France',
      'flag': '🇫🇷',
      'maxLTV': {'eu_nonres': 75.0, 'uk': 70.0, 'us': 65.0, 'other': 65.0},
      'rateAdder': 0.4,
      'closingPct': 8.00,
      'steps': [
        'Get Numéro Fiscal from Direction des Finances Publiques',
        'Engage notaire – represents both parties',
        'Sign Compromis de Vente (preliminary contract)',
        'Obtain mortgage offer (30-day cooling off period)',
        'Satisfy conditions suspensives (mortgage, survey)',
        'Sign Acte Authentique at notaire',
        'Pay all taxes and fees',
        'Register with Service de publicité foncière'
      ]
    },
    'ES': {
      'name': 'Spain',
      'flag': '🇪🇸',
      'maxLTV': {'eu_nonres': 70.0, 'uk': 70.0, 'us': 60.0, 'other': 60.0},
      'rateAdder': 0.6,
      'closingPct': 13.00,
      'steps': [
        'Obtain NIE number (at Spanish consulate or in Spain)',
        'Open Spanish bank account',
        'Engage Spanish lawyer (abogado)',
        'Request Nota Simple from Land Registry',
        'Sign Arras contract with 10% deposit',
        'Secure mortgage from Spanish bank',
        'Sign before Spanish notary (Escritura)',
        'Register with Registro de Propiedad'
      ]
    },
    'IT': {
      'name': 'Italy',
      'flag': '🇮🇹',
      'maxLTV': {'eu_nonres': 60.0, 'uk': 60.0, 'us': 50.0, 'other': 50.0},
      'rateAdder': 0.75,
      'closingPct': 14.00,
      'steps': [
        'Obtain Codice Fiscale from Italian consulate',
        'Hire geometra for property survey',
        'Sign preliminary contract (Compromesso)',
        'Pay 10–20% deposit in escrow',
        'Apply for Italian mortgage (codice fiscale required)',
        'Final deed (Atto Rogito) before notaio',
        'Pay all taxes within legal deadlines',
        'Register with Agenzia delle Entrate'
      ]
    },
    'NL': {
      'name': 'Netherlands',
      'flag': '🇳🇱',
      'maxLTV': {'eu_nonres': 80.0, 'uk': 75.0, 'us': 70.0, 'other': 70.0},
      'rateAdder': 0.3,
      'closingPct': 12.00,
      'steps': [
        'Register at local gemeente to get BSN',
        'Open Dutch bank account',
        'Engage mortgage advisor (verplicht)',
        'Commission building inspection (bouwtechnische keuring)',
        'Sign preliminary purchase agreement',
        '3-day cooling off period by law',
        'Final transfer at notaris',
        'Register mortgage with Kadaster'
      ]
    },
    'PT': {
      'name': 'Portugal',
      'flag': '🇵🇹',
      'maxLTV': {'eu_nonres': 70.0, 'uk': 65.0, 'us': 65.0, 'other': 65.0},
      'rateAdder': 0.5,
      'closingPct': 10.50,
      'steps': [
        'Obtain NIF from Finanças (or consulate)',
        'Appoint fiscal representative (non-EU required)',
        'Sign CPCV (promissory contract) + 10-30% deposit',
        'Obtain Portuguese mortgage pre-approval',
        'Complete due diligence via lawyer',
        'Sign Escritura at cartório notarial',
        'Pay IMT, Stamp Duty, and fees',
        'Register in Conservatória do Registo Predial'
      ]
    }
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _price = inputs['price'] ?? 400000.0;
      final originVal = inputs['buyerOrigin'] ?? 0.0;
      _buyerOrigin = _doubleToOrigin[originVal] ?? 'eu_nonres';
      final purposeVal = inputs['purpose'] ?? 0.0;
      _purpose = _doubleToPurpose[purposeVal] ?? 'holiday';
      _income = inputs['income'] ?? 90000.0;
      _existingDebt = inputs['existingDebt'] ?? 0.0;
      _countryCode = widget.savedCalc!.label.split(' - ').last;
      _calculated = true;
    }
  }

  double _calculateMonthly(double loan, double rate, int termYrs) {
    final r = (rate / 100) / 12;
    final n = termYrs * 12;
    if (r == 0) return loan / n;
    return loan * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  void _saveAnalysis(double maxLoan, double rate, double monthly, double upfrontCash, double dti) async {
    final labelCtrl = TextEditingController(text: 'Europe Non-Resident');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Max Loan ${CurrencyFormatter.compact(maxLoan, symbol: '€')} at ${rate.toStringAsFixed(2)}% · Cash Needed: ${CurrencyFormatter.compact(upfrontCash, symbol: '€')}',
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
                hintText: 'Label (e.g. Spain Villa)',
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
          : 'Europe Non-Resident';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Non-Resident Calc',
        inputs: {
          'price': _price,
          'buyerOrigin': _originToDouble[_buyerOrigin] ?? 0.0,
          'purpose': _purposeToDouble[_purpose] ?? 0.0,
          'income': _income,
          'existingDebt': _existingDebt,
        },
        results: {
          'Loan': maxLoan,
          'Rate': rate,
          'Monthly': monthly,
          'Upfront Cash': upfrontCash,
          'DTI': dti,
        },
        label: '$label - $_countryCode',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Non-resident analysis saved!',
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
    final double ltvLimit = (c['maxLTV'] as Map)[_buyerOrigin] ?? 50.0;
    final double closingPct = c['closingPct'];
    final double rateAdder = c['rateAdder'];
    // Live ECB base rate
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveEcb = ratesAsync.valueOrNull?.ecbRate.value ?? 4.00;
    final isLive = ratesAsync.valueOrNull?.isLive == true;
    final rate = liveEcb + rateAdder;

    final maxLoan = _price * (ltvLimit / 100);
    final deposit = _price - maxLoan;
    final closingTotal = _price * (closingPct / 100);
    final totalUpfrontCash = deposit + closingTotal;

    final monthlyPayment = _calculateMonthly(maxLoan, rate, 20); // standard 20yr term
    final monthlyIncome = _income / 12;
    final dtiPct = monthlyIncome > 0 ? ((monthlyPayment + _existingDebt) / monthlyIncome * 100) : 0.0;
    final bool dtiOk = dtiPct <= 33.0;

    final steps = List<String>.from(c['steps']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top LTV limit strip
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
              _rateStripItem('🇩🇪 Max LTV', '60%', 'Germany NR'),
              _rateDivider(),
              _rateStripItem('🇪🇸 Max LTV', '70%', 'Spain NR'),
              _rateDivider(),
              _rateStripItem('🇵🇹 Gold Visa', '€280k', 'Min invest'),
              _rateDivider(),
              _rateStripItem('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Base Rate'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Target Country
        Text('TARGET COUNTRY', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _countryData.keys.map((code) {
              final active = _countryCode == code;
              final data = _countryData[code]!;
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

        // Warning Banner
        Container(
           padding: const EdgeInsets.all(14),
           decoration: BoxDecoration(
             color: isDark ? const Color(0x33F59E0B) : Colors.amber.shade50,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : Colors.amber.shade300),
           ),
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const Text('⚠️', style: TextStyle(fontSize: 20)),
               const SizedBox(width: 10),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('Non-Resident Surcharges & Constraints',
                         style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900)),
                     const SizedBox(height: 2),
                     Text(
                       'Lenders enforce stricter LTV caps (typically 50-70% instead of 80-100% for residents), higher interest margins, and require notarized translation of tax returns.',
                       style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : Colors.amber.shade900, height: 1.4),
                     ),
                   ],
                 ),
               ),
             ],
           ),
         ),
        const SizedBox(height: 16),

        // Inputs Card
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
              Text('🏠 Property & Buyer Profiles', style: AppTextStyles.cardTitle(textColor)),
              const SizedBox(height: 14),

              // Property Purchase Price Slider
              _sliderHeader('Property Purchase Price', CurrencyFormatter.format(_price, symbol: '€')),
              Slider(
                value: _price,
                min: 100000,
                max: 3000000,
                divisions: 290,
                 activeColor: isDark ? theme.accentColor : theme.primaryColor,
                 inactiveColor: (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15),
                onChanged: (v) => setState(() => _price = v),
              ),

              // Buyer Origin
              const SizedBox(height: 8),
              Text('BUYER ORIGIN', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              _originSelector(),

              // Purpose
              const SizedBox(height: 14),
              Text('PURPOSE OF PURCHASE', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              _purposeSelector(),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _numericInputBox('Annual Income (€)', _income, (v) => setState(() => _income = v), min: 20000, max: 500000),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numericInputBox('Existing EU Debt (€/mo)', _existingDebt, (v) => setState(() => _existingDebt = v), min: 0, max: 10000, step: 100),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => setState(() => _calculated = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003399), Color(0xFF1A0040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF003399).withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌐', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Calculate Non-Resident Costs',
                          style: AppTextStyles.dmSans(
                              size: 13, weight: FontWeight.w800, color: const Color(0xFFFFCC00))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_calculated) ...[
          // Summary Hero Card
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
                Text('Maximum Non-Resident Loan', style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(maxLoan, symbol: '€'),
                  style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on ${ltvLimit.toStringAsFixed(0)}% LTV limit · $countryName',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _resultMiniBox('LTV Limit', '${ltvLimit.toStringAsFixed(0)}%'),
                    _resultMiniBox('Rate (NR)', '${rate.toStringAsFixed(2)}%'),
                    _resultMiniBox('Monthly Pay', CurrencyFormatter.format(monthlyPayment, symbol: '€')),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 0.5, color: Colors.white12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _saveAnalysis(maxLoan, rate, monthlyPayment, totalUpfrontCash, dtiPct),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00).withValues(alpha: 0.18),
                            border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.45)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text('💾 Save Analysis', style: AppTextStyles.dmSans(size: 12, color: const Color(0xFFFFCC00), weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total upfront costs card
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
                Text('💶 Upfront Cost Breakdown', style: AppTextStyles.cardTitle(textColor)),
                const SizedBox(height: 12),
                _costItemRow('Property Price', CurrencyFormatter.format(_price, symbol: '€'), 'Base purchase price', textColor, mutedText),
                _costItemRow('Required Deposit', CurrencyFormatter.format(deposit, symbol: '€'), '${(100 - ltvLimit).toStringAsFixed(0)}% down payment required', textColor, mutedText),
                _costItemRow('Estimated Closing Costs', CurrencyFormatter.format(closingTotal, symbol: '€'), 'Taxes, notary, registry fees (~${closingPct.toStringAsFixed(2)}%)', textColor, mutedText),
                const Divider(height: 24),
                _costItemRow('Total Upfront Cash Required', CurrencyFormatter.format(totalUpfrontCash, symbol: '€'), 'Deposit + closing costs', isDark ? theme.accentColor : theme.primaryColor, mutedText, isTotal: true),
                const SizedBox(height: 16),
                // Visual horizontal bars
                Text('Cash Requirement Split', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                _costSplitBar('Deposit', deposit, totalUpfrontCash, Colors.blue),
                const SizedBox(height: 6),
                _costSplitBar('Closing Costs', closingTotal, totalUpfrontCash, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Affordability Assessment Card
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
                Text('📊 DTI / Affordability Analysis', style: AppTextStyles.cardTitle(textColor)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: dtiPct / 100,
                        backgroundColor: theme.getBgColor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(dtiOk ? Colors.green : Colors.red),
                        strokeWidth: 8,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Debt-to-Income', style: AppTextStyles.dmSans(size: 11, color: mutedText, weight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${dtiPct.toStringAsFixed(1)}% DTI',
                              style: AppTextStyles.playfair(size: 18, color: dtiOk ? Colors.green : Colors.red, weight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(dtiOk ? '✅ Within 33% standard guideline' : '⚠️ Exceeds 33% safety cap — review needed',
                              style: AppTextStyles.dmSans(size: 10, color: textColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Steps Guide
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
                Text('📋 Step-by-Step Buying Guide', style: AppTextStyles.cardTitle(textColor)),
                const SizedBox(height: 4),
                Text('How to buy in $countryName as a non-resident', style: AppTextStyles.dmSans(size: 10.5, color: mutedText)),
                const SizedBox(height: 14),
                ...steps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: isDark ? theme.accentColor : theme.primaryColor, borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: Text((idx + 1).toString(), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(step, style: AppTextStyles.dmSans(size: 12, color: textColor))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _rateStripItem(String label, String val, String subtitle) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
        const SizedBox(height: 1),
        Text(subtitle, style: AppTextStyles.dmSans(size: 7.5, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _rateDivider() {
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

  Widget _originSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, String>> origins = [
      {'code': 'eu_nonres', 'name': 'EU Non-Res'},
      {'code': 'uk', 'name': 'UK Buyer'},
      {'code': 'us', 'name': 'US / Canada'},
      {'code': 'other', 'name': 'Other Non-EU'},
    ];
    return Row(
      children: origins.map((o) {
        final active = _buyerOrigin == o['code'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _buyerOrigin = o['code']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? (isDark ? widget.theme.accentColor : widget.theme.primaryColor) : widget.theme.getBgColor(context),
                border: Border.all(color: active ? (isDark ? widget.theme.accentColor : widget.theme.primaryColor) : widget.theme.getBorderColor(context)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(o['name']!,
                  style: AppTextStyles.dmSans(
                      size: 9.5,
                      weight: FontWeight.bold,
                      color: active ? (isDark ? Colors.black : const Color(0xFFFFCC00)) : widget.theme.getTextColor(context)),
                  textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _purposeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, String>> purposes = [
      {'code': 'holiday', 'name': 'Holiday'},
      {'code': 'investment', 'name': 'Investment'},
      {'code': 'relocation', 'name': 'Relocate'},
      {'code': 'goldvisa', 'name': 'Gold Visa'},
    ];
    return Row(
      children: purposes.map((p) {
        final active = _purpose == p['code'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _purpose = p['code']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? (isDark ? widget.theme.accentColor : widget.theme.primaryColor) : widget.theme.getBgColor(context),
                border: Border.all(color: active ? (isDark ? widget.theme.accentColor : widget.theme.primaryColor) : widget.theme.getBorderColor(context)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(p['name']!,
                  style: AppTextStyles.dmSans(
                      size: 9.5,
                      weight: FontWeight.bold,
                      color: active ? (isDark ? Colors.black : const Color(0xFFFFCC00)) : widget.theme.getTextColor(context)),
                  textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _numericInputBox(String label, double value, ValueChanged<double> onChanged,
      {required double min, required double max, double step = 5000.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  step >= 1.0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2),
                  style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(math.max(min, value - step)),
                child: Icon(Icons.remove_circle_outline, size: 16, color: isDark ? widget.theme.accentColor : widget.theme.primaryColor),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onChanged(math.min(max, value + step)),
                child: Icon(Icons.add_circle_outline, size: 16, color: isDark ? widget.theme.accentColor : widget.theme.primaryColor),
              ),
            ],
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
            Text(value, style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _costItemRow(String label, String value, String desc, Color mainCol, Color subCol, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: mainCol)),
                Text(desc, style: AppTextStyles.dmSans(size: 10, color: subCol)),
              ],
            ),
          ),
          Text(value, style: AppTextStyles.playfair(size: isTotal ? 16 : 13.5, color: mainCol, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _costSplitBar(String label, double val, double total, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double pct = total > 0 ? (val / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context))),
            Text('${pct.toStringAsFixed(0)}%', style: AppTextStyles.playfair(size: 10, color: isDark ? widget.theme.accentColor : widget.theme.primaryColor, weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            width: double.infinity,
            color: widget.theme.getBgColor(context),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct / 100,
                child: Container(color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
