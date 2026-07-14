// lib/features/europe/tools/eu_affordability_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUAffordabilityCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUAffordabilityCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUAffordabilityCalc> createState() => _EUAffordabilityCalcState();
}

class _EUAffordabilityCalcState extends ConsumerState<EUAffordabilityCalc>
    with SingleTickerProviderStateMixin {
  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  String _countryCode = 'DE';
  double _annualInc = 72000;
  double _partnerInc = 0;
  double _savings = 60000;
  double _debts = 300;
  double _rate = 3.85;

  bool _hasCalculated = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final Map<String, Map<String, dynamic>> _cData = {
    'DE': {
      'name': 'Germany',
      'flag': '🇩🇪',
      'multiple': 4.0,
      'rate': 3.85,
      'minDeposit': 0.10,
      'dtiLimit': 0.40,
      'tips': [
        'Savings must cover 10–20% deposit plus ~5–6% closing costs (Grunderwerbsteuer, notary, registry)',
        'Germany uses income multiples of 4–5× annual gross income',
        'No DTI cap but lenders prefer under 40%',
        'Consider KfW subsidised loans for first buyers (as low as 2.5%)',
      ],
    },
    'FR': {
      'name': 'France',
      'flag': '🇫🇷',
      'multiple': 4.5,
      'rate': 3.60,
      'minDeposit': 0.10,
      'dtiLimit': 0.35,
      'tips': [
        'France HCSF regulation caps DTI strictly at 35%',
        'Notaire fees of 7–8% apply to resale properties (2.5% on new builds)',
        'PTZ (Prêt à Taux Zéro) zero-interest loan available for first buyers',
        'Maximum term is 25 years (27 years with construction)',
      ],
    },
    'ES': {
      'name': 'Spain',
      'flag': '🇪🇸',
      'multiple': 4.0,
      'rate': 4.10,
      'minDeposit': 0.20,
      'dtiLimit': 0.40,
      'tips': [
        'Spanish lenders typically require 20% minimum deposit',
        'ITP tax is 6–10% on resale properties depending on region',
        'Euribor-linked variable mortgages are popular but carry rate risk',
        'Non-residents usually get max 70% LTV from Spanish banks',
      ],
    },
    'IT': {
      'name': 'Italy',
      'flag': '🇮🇹',
      'multiple': 3.5,
      'rate': 3.95,
      'minDeposit': 0.20,
      'dtiLimit': 0.40,
      'tips': [
        'Italian banks use conservative 3.5× income multiples',
        'Notary (Rogito) costs approx 1.5% of property value',
        'First home buyers get reduced Imposta di Registro at 2%',
        'Mutuo Agevolato subsidised mortgages available under age 36',
      ],
    },
    'NL': {
      'name': 'Netherlands',
      'flag': '🇳🇱',
      'multiple': 4.5,
      'rate': 3.75,
      'minDeposit': 0.10,
      'dtiLimit': 0.43,
      'tips': [
        'NHG (Nationale Hypotheek Garantie) allows up to 4.5× and lower rates',
        'NHG guarantee available on properties up to €435,000 (2025)',
        'Transfer tax is only 2% (0% for buyers under 35 purchasing first home)',
        'Dutch mortgages up to 100% of property value (LTV)',
      ],
    },
    'PT': {
      'name': 'Portugal',
      'flag': '🇵🇹',
      'multiple': 4.0,
      'rate': 3.50,
      'minDeposit': 0.15,
      'dtiLimit': 0.50,
      'tips': [
        'Portugal allows up to 50% DTI but 36% is preferred by lenders',
        'NHR (Non-Habitual Resident) tax regime available to new residents',
        'IMT tax applies on resale; new builds attract 23% VAT instead',
        'Maximum term is 40 years for borrowers under 30',
      ],
    },
  };

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
      _annualInc = inputs['annualInc'] ?? 72000;
      _partnerInc = inputs['partnerInc'] ?? 0;
      _savings = inputs['savings'] ?? 60000;
      _debts = inputs['debts'] ?? 300;
      _rate = inputs['rate'] ?? 3.85;
      _countryCode = widget.savedCalc!.label.split(' - ').last;

      _calcSnapshot['annualInc'] = _annualInc;
      _calcSnapshot['partnerInc'] = _partnerInc;
      _calcSnapshot['savings'] = _savings;
      _calcSnapshot['debts'] = _debts;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['countryCode'] = _countryCode;

      _hasCalculated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animController.forward(from: 0.0);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _calcMonthly(double loanAmt, double annualRate, int termYrs) {
    final r = (annualRate / 100) / 12;
    final n = termYrs * 12;
    return r == 0 ? loanAmt / n : loanAmt * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  void _runCalc() {
    setState(() {
      _calcSnapshot['annualInc'] = _annualInc;
      _calcSnapshot['partnerInc'] = _partnerInc;
      _calcSnapshot['savings'] = _savings;
      _calcSnapshot['debts'] = _debts;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['countryCode'] = _countryCode;
      _hasCalculated = true;
    });
    _animController.forward(from: 0.0);
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
      _annualInc = 72000;
      _partnerInc = 0;
      _savings = 60000;
      _debts = 300;
      _rate = 3.85;
      _countryCode = 'DE';
      _hasCalculated = false;
      _calcSnapshot.clear();
    });
    _animController.reverse();
  }

  void _saveCalculation() async {
    final double annualInc = _calcSnapshot['annualInc'] ?? _annualInc;
    final double partnerInc = _calcSnapshot['partnerInc'] ?? _partnerInc;
    final double savings = _calcSnapshot['savings'] ?? _savings;
    final double debts = _calcSnapshot['debts'] ?? _debts;
    final double rate = _calcSnapshot['rate'] ?? _rate;
    final String countryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final c = _cData[countryCode]!;
    final double multiple = c['multiple'];
    final double dtiLimit = c['dtiLimit'];

    final totalInc = annualInc + partnerInc;
    final monthlyInc = totalInc / 12;
    final maxDTIPayment = monthlyInc * dtiLimit - debts;

    final r = (rate / 100) / 12;
    const n = 25 * 12;
    final double maxLoanDTI = maxDTIPayment > 0
        ? maxDTIPayment * (math.pow(1 + r, n) - 1) / (r * math.pow(1 + r, n))
        : 0;

    final maxLoanMult = totalInc * multiple;
    final double maxLoan = math.min(maxLoanDTI, maxLoanMult).clamp(0, double.infinity);
    final depositAvail = savings * (1 - 0.07);
    final double maxProperty = maxLoan + depositAvail;
    final double monthly = _calcMonthly(maxLoan, rate, 25);

    final labelCtrl = TextEditingController(text: 'Europe Affordability');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/eu_affordability_calc/save'),
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
              'Max Loan: ${CurrencyFormatter.compact(maxLoan, symbol: '€')} · Max Property: ${CurrencyFormatter.compact(maxProperty, symbol: '€')}',
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
                hintText: 'Label (e.g. Budget Plan)',
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
          : 'Europe Affordability';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Affordability Calc',
        inputs: {
          'annualInc': annualInc,
          'partnerInc': partnerInc,
          'savings': savings,
          'debts': debts,
          'rate': rate,
        },
        results: {
          'Max Loan': maxLoan,
          'Max Property': maxProperty,
          'Monthly Payment': monthly,
        },
        label: '$label - $countryCode',
        currencyCode: 'EUR',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Affordability saved!',
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
    final sliderActiveColor = isDark ? theme.accentColor : theme.primaryColor;
    final sliderInactiveColor = (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15);

    final double snapAnnualInc = _calcSnapshot['annualInc'] ?? _annualInc;
    final double snapPartnerInc = _calcSnapshot['partnerInc'] ?? _partnerInc;
    final double snapSavings = _calcSnapshot['savings'] ?? _savings;
    final double snapDebts = _calcSnapshot['debts'] ?? _debts;
    final double snapRate = _calcSnapshot['rate'] ?? _rate;
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final c = _cData[snapCountryCode]!;
    final double multiple = c['multiple'];
    final double dtiLimit = c['dtiLimit'];

    final totalInc = snapAnnualInc + snapPartnerInc;
    final monthlyInc = totalInc / 12;
    final maxDTIPayment = monthlyInc * dtiLimit - snapDebts;

    final r = (snapRate / 100) / 12;
    const n = 25 * 12;
    final double maxLoanDTI = maxDTIPayment > 0
        ? maxDTIPayment * (math.pow(1 + r, n) - 1) / (r * math.pow(1 + r, n))
        : 0;

    final maxLoanMult = totalInc * multiple;
    final double maxLoan = math.min(maxLoanDTI, maxLoanMult).clamp(0, double.infinity);
    final depositAvail = snapSavings * (1 - 0.07);
    final double maxProperty = maxLoan + depositAvail;
    final double monthly = _calcMonthly(maxLoan, snapRate, 25);

    final conservative = maxLoan * 0.75;
    final stretch = maxLoan * 1.1;

    final isDirty = _hasCalculated && (
      _annualInc != snapAnnualInc ||
      _partnerInc != snapPartnerInc ||
      _savings != snapSavings ||
      _debts != snapDebts ||
      _rate != snapRate ||
      _countryCode != snapCountryCode
    );

    // Live ECB rate context
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveEcb = ratesAsync.valueOrNull?.ecbRate.value ?? 4.00;
    final isLive = ratesAsync.valueOrNull?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Live Rate Context Strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rateStripItem('🇩🇪 4× rule', '4–4.5×', 'Income Multi', mutedText, textColor),
              _rateDivider(borderCol),
              _rateStripItem('🇫🇷 35% DTI', 'HCSF', 'Hard Limit', mutedText, textColor),
              _rateDivider(borderCol),
              _rateStripItem('🇳🇱 NHG', '4.5×', 'With NHG', mutedText, textColor),
              _rateDivider(borderCol),
              _rateStripItem('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Rate', mutedText, textColor),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Country Row ──
        Text('COUNTRY',
            style: AppTextStyles.dmSans(
                size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _countryPill('DE', '🇩🇪 Germany', 3.85),
              const SizedBox(width: 8),
              _countryPill('FR', '🇫🇷 France', 3.60),
              const SizedBox(width: 8),
              _countryPill('ES', '🇪🇸 Spain', 4.10),
              const SizedBox(width: 8),
              _countryPill('IT', '🇮🇹 Italy', 3.95),
              const SizedBox(width: 8),
              _countryPill('NL', '🇳🇱 Netherlands', 3.75),
              const SizedBox(width: 8),
              _countryPill('PT', '🇵🇹 Portugal', 3.50),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Inputs Card with Calculate button ──
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💼 Income & Finances', style: AppTextStyles.cardTitle(textColor)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset',
                        style: AppTextStyles.dmSans(
                            size: 11, color: theme.primaryColor, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _sliderHeader('Annual Gross Income',
                  CurrencyFormatter.format(_annualInc, symbol: '€'), mutedText),
              Slider(
                value: _annualInc,
                min: 20000,
                max: 300000,
                divisions: 280,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) => setState(() => _annualInc = v),
              ),

              _sliderHeader('Partner Annual Income',
                  CurrencyFormatter.format(_partnerInc, symbol: '€'), mutedText),
              Slider(
                value: _partnerInc,
                min: 0,
                max: 200000,
                divisions: 200,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) => setState(() => _partnerInc = v),
              ),

              _sliderHeader('Total Savings / Deposit',
                  CurrencyFormatter.format(_savings, symbol: '€'), mutedText),
              Slider(
                value: _savings,
                min: 5000,
                max: 500000,
                divisions: 198,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) => setState(() => _savings = v),
              ),

              _sliderHeader('Existing Monthly Debts',
                  CurrencyFormatter.format(_debts, symbol: '€'), mutedText),
              Slider(
                value: _debts,
                min: 0,
                max: 5000,
                divisions: 100,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) => setState(() => _debts = v),
              ),

              _sliderHeader('Interest Rate', '${_rate.toStringAsFixed(2)}%', mutedText),
              Slider(
                value: _rate,
                min: 1,
                max: 10,
                divisions: 180,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) => setState(() => _rate = v),
              ),

              const SizedBox(height: 6),
              GestureDetector(
                onTap: _runCalc,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFCC00), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Calculate Affordability',
                          style: AppTextStyles.dmSans(
                              size: 14, weight: FontWeight.w900, color: const Color(0xFF1A0040))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Results (shown after calculation) ──
        if (_hasCalculated)
          FadeTransition(
            key: _resultsKey,
            opacity: _fadeAnim,
            child: Column(
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
                // Quick Stats Row
                Text('QUICK STATS',
                    style: AppTextStyles.dmSans(
                        size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _quickStatBox('🏷️', 'Income Multiple', '$multiple×', cardBg, borderCol, textColor, mutedText),
                    const SizedBox(width: 8),
                    _quickStatBox('💰', 'Deposit Used',
                        CurrencyFormatter.compact(depositAvail, symbol: '€'), cardBg, borderCol, textColor, mutedText),
                    const SizedBox(width: 8),
                    _quickStatBox('📅', 'Est. Term', '25 yrs', cardBg, borderCol, textColor, mutedText),
                  ],
                ),
                const SizedBox(height: 14),

                // Hero borrowing card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
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
                      Text('Maximum Borrowing',
                          style: AppTextStyles.dmSans(
                              size: 11, color: Colors.white70, weight: FontWeight.w600, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(maxLoan, symbol: '€'),
                        style: AppTextStyles.playfair(
                            size: 38, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c['name']} · $multiple× income rule · ${snapRate.toStringAsFixed(2)}%',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _ahBox('Max Property', CurrencyFormatter.format(maxProperty, symbol: '€')),
                          const SizedBox(width: 8),
                          _ahBox('Monthly Pymt', CurrencyFormatter.format(monthly, symbol: '€')),
                          const SizedBox(width: 8),
                          _ahBox('Income Multi', '$multiple×'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 0.5, color: Colors.white12),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _saveCalculation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00).withValues(alpha: 0.18),
                            border: Border.all(
                                color: const Color(0xFFFFCC00).withValues(alpha: 0.45)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text('💾 Save Calculation',
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  color: const Color(0xFFFFCC00),
                                  weight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Borrowing Capacity Card
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
                      Text('📊 Borrowing Capacity', style: AppTextStyles.cardTitle(textColor)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Conservative',
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.bold, color: const Color(0xFF22C55E))),
                          Text('Standard',
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.bold, color: const Color(0xFFFFCC00))),
                          Text('Maximum',
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.bold, color: const Color(0xFF003399))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          height: 14,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFFFFCC00), Color(0xFF003399)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(CurrencyFormatter.compact(conservative, symbol: '€'),
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.w700, color: mutedText)),
                          Text(CurrencyFormatter.compact(maxLoan, symbol: '€'),
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.w700, color: mutedText)),
                          Text(CurrencyFormatter.compact(stretch, symbol: '€'),
                              style: AppTextStyles.dmSans(
                                  size: 10, weight: FontWeight.w700, color: mutedText)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _scenarioRow('Conservative (3.5× income)', 'Lower risk, easier approval',
                          totalInc * 3.5, false, cardBg, borderCol, textColor, mutedText),
                      const SizedBox(height: 8),
                      _scenarioRow('Standard ($multiple× income)', '${c['name']} standard',
                          maxLoan, true, cardBg, borderCol, textColor, mutedText),
                      const SizedBox(height: 8),
                      _scenarioRow('Stretch (5× income)', 'Subject to affordability check',
                          totalInc * 5, false, cardBg, borderCol, textColor, mutedText),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Country Tips Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Country Affordability Tips',
                          style: AppTextStyles.cardTitle(Colors.white)),
                      const SizedBox(height: 10),
                      ...(c['tips'] as List<String>).map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('•',
                                    style: TextStyle(color: Color(0xFFFFCC00), fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(tip,
                                    style: AppTextStyles.dmSans(
                                        size: 11,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        height: 1.4)),
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
                const Text('💶', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Enter Your Details Above',
                    style: AppTextStyles.playfair(
                        size: 15, weight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  'Adjust the sliders, then tap\nCalculate Affordability to see your borrowing power.',
                  style: AppTextStyles.dmSans(size: 11, color: mutedText, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _countryPill(String code, String name, double rate) {
    final active = _countryCode == code;
    return GestureDetector(
      onTap: () => setState(() {
        _countryCode = code;
        _rate = rate;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF003399) : widget.theme.getCardColor(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? const Color(0xFF003399) : widget.theme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        child: Text(
          name,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w700,
            color: active ? const Color(0xFFFFCC00) : widget.theme.getTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _rateStripItem(String label, String val, String subtitle, Color mutedText, Color textColor) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: mutedText)),
        const SizedBox(height: 2),
        Text(val,
            style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 1),
        Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: mutedText)),
      ],
    );
  }

  Widget _rateDivider(Color borderCol) => Container(width: 0.5, height: 26, color: borderCol);

  Widget _sliderHeader(String label, String value, Color mutedText) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText)),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? widget.theme.accentColor
                      : widget.theme.primaryColor,
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _quickStatBox(String icon, String label, String value,
      Color cardBg, Color borderCol, Color textColor, Color mutedText) {
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
            Text(icon, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: mutedText, weight: FontWeight.w700, letterSpacing: 0.3),
                textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(value,
                style: AppTextStyles.playfair(size: 13, color: textColor, weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _ahBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
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
                style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _scenarioRow(String name, String desc, double loan, bool best,
      Color cardBg, Color borderCol, Color textColor, Color mutedText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? widget.theme.accentColor : widget.theme.primaryColor;
    final activeBg = isDark ? widget.theme.accentColor.withValues(alpha: 0.12) : widget.theme.primaryColor.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: best ? activeBg : cardBg,
        border: Border.all(
            color: best ? activeColor : borderCol,
            width: best ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name${best ? ' ⭐' : ''}',
                  style: AppTextStyles.dmSans(
                      size: 12, weight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 10, color: mutedText)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.compact(loan, symbol: '€'),
            style: AppTextStyles.playfair(
                size: 15, color: activeColor, weight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
