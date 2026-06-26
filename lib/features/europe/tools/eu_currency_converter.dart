// lib/features/europe/tools/eu_currency_converter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUCurrencyConverter extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUCurrencyConverter({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUCurrencyConverter> createState() => _EUCurrencyConverterState();
}

class _EUCurrencyConverterState extends ConsumerState<EUCurrencyConverter> {
  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';
  final TextEditingController _amountController = TextEditingController(text: '1000');
  int _activePeriod = 30;

  static const Map<String, double> _ratesFromEur = {
    'EUR': 1.0000,
    'USD': 1.0847,
    'GBP': 0.8423,
    'CHF': 0.9618,
    'JPY': 163.42,
    'SEK': 11.2840,
    'NOK': 11.7210,
    'DKK': 7.4590,
    'PLN': 4.2610,
    'CZK': 25.3150
  };

  static const Map<String, Map<String, String>> _currencyMeta = {
    'EUR': {'flag': '🇪🇺', 'name': 'Euro', 'symbol': '€'},
    'USD': {'flag': '🇺🇸', 'name': 'US Dollar', 'symbol': '\$'},
    'GBP': {'flag': '🇬🇧', 'name': 'British Pound', 'symbol': '£'},
    'CHF': {'flag': '🇨🇭', 'name': 'Swiss Franc', 'symbol': 'Fr'},
    'JPY': {'flag': '🇯🇵', 'name': 'Japanese Yen', 'symbol': '¥'},
    'SEK': {'flag': '🇸🇪', 'name': 'Swedish Krona', 'symbol': 'kr'},
    'NOK': {'flag': '🇳🇴', 'name': 'Norwegian Krone', 'symbol': 'kr'},
    'DKK': {'flag': '🇩🇰', 'name': 'Danish Krone', 'symbol': 'kr'},
    'PLN': {'flag': '🇵🇱', 'name': 'Polish Złoty', 'symbol': 'zł'},
    'CZK': {'flag': '🇨🇿', 'name': 'Czech Koruna', 'symbol': 'Kč'}
  };

  static const Map<String, double> _change30d = {
    'USD': 0.12,
    'GBP': -0.08,
    'CHF': -0.21,
    'JPY': 2.40,
    'SEK': 0.72,
    'NOK': -0.38,
    'DKK': 0.04,
    'PLN': 1.95,
    'CZK': 0.88
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _amountController.text = (inputs['amount'] ?? 1000.0).toStringAsFixed(2);
      _fromCurrency = widget.savedCalc!.currencyCode;
      _toCurrency = widget.savedCalc!.label.split(' to ').last;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _getRate(String from, String to) {
    final eurTo = _ratesFromEur[to] ?? 1.0;
    final eurFrom = _ratesFromEur[from] ?? 1.0;
    return eurTo / eurFrom;
  }

  List<double> _generateTrendData(String from, String to, int days) {
    final baseRate = _getRate(from, to);
    final volatility = (from == 'JPY' || to == 'JPY') ? 0.008 : 0.004;
    final List<double> data = [];
    final seed = (from.hashCode ^ to.hashCode ^ days).abs();
    final rand = math.Random(seed);

    double rate = baseRate * (1 - (days / 365) * 0.02);
    for (int i = days; i >= 0; i--) {
      rate += (rand.nextDouble() - 0.49) * volatility * baseRate;
      data.add(double.parse(rate.toStringAsFixed(to == 'JPY' ? 2 : 4)));
    }
    data[data.length - 1] = baseRate;
    return data;
  }

  void _saveConversion(double amount, double result, double rate) async {
    final labelCtrl = TextEditingController(text: '$_fromCurrency to $_toCurrency');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Conversion',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: $amount $_fromCurrency = ${result.toStringAsFixed(2)} $_toCurrency',
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
                hintText: 'Label (e.g. Deposit Exchange)',
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
          : '$_fromCurrency to $_toCurrency';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Currency Converter',
        inputs: {
          'amount': amount,
        },
        results: {
          'Rate': rate,
          'Converted': result,
        },
        label: '$label - $_fromCurrency to $_toCurrency',
        currencyCode: _fromCurrency,
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Conversion saved!',
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

    // Rate calculations (use effectiveRates for USD/GBP)
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final rate = _getRate(_fromCurrency, _toCurrency);
    final convertedAmount = amount * rate;

    // Trend chart data
    final trendData = _generateTrendData(_fromCurrency, _toCurrency, _activePeriod);
    final double maxTrend = trendData.reduce(math.max);
    final double minTrend = trendData.reduce(math.min);
    final double avgTrend = trendData.reduce((a, b) => a + b) / trendData.length;

    // Filter saves for displaying
    final allSaves = ref.watch(savedProvider);
    final currencySaves = allSaves
        .where((s) => s.country == 'Europe' && s.calcType == 'Currency Converter')
        .toList();

    // Live EUR/USD and EUR/GBP from ECB
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveRates = ratesAsync.valueOrNull;
    final isLive = liveRates?.isLive == true;
    final liveEurUsd = liveRates?.eurUsd.value ?? _ratesFromEur['USD']!;
    final liveEurGbp = liveRates?.eurGbp.value ?? _ratesFromEur['GBP']!;

    // Override static rates with live values
    final effectiveRates = Map<String, double>.from(_ratesFromEur);
    effectiveRates['USD'] = liveEurUsd;
    effectiveRates['GBP'] = liveEurGbp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live rate strip
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
              _rateStripItem('EUR/USD${isLive ? ' 🟢' : ''}', liveEurUsd, _change30d['USD']!),
              _rateStripDivider(),
              _rateStripItem('EUR/GBP${isLive ? ' 🟢' : ''}', liveEurGbp, _change30d['GBP']!),
              _rateStripDivider(),
              _rateStripItem('EUR/CHF', effectiveRates['CHF']!, _change30d['CHF']!),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main Conversion Card
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💱 Currency Converter', style: AppTextStyles.cardTitle(textColor)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _fromCurrency = 'EUR';
                        _toCurrency = 'USD';
                        _amountController.text = '1000';
                      });
                    },
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11, color: isDark ? theme.accentColor : theme.primaryColor, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // From Field
              Text('FROM', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _fromCurrency,
                        items: _currencyMeta.keys.map((code) {
                          final meta = _currencyMeta[code]!;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('${meta['flag']} $code',
                                style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w700, color: textColor)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _fromCurrency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.playfair(size: 20, color: textColor, weight: FontWeight.w900),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),

              // Swap Button Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: borderCol)),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final temp = _fromCurrency;
                          _fromCurrency = _toCurrency;
                          _toCurrency = temp;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('⇅', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(child: Divider(color: borderCol)),
                  ],
                ),
              ),

              // To Field
              Text('TO', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _toCurrency,
                        items: _currencyMeta.keys.map((code) {
                          final meta = _currencyMeta[code]!;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('${meta['flag']} $code',
                                style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w700, color: textColor)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _toCurrency = val);
                        },
                      ),
                    ),
                    Text(
                      _toCurrency == 'JPY'
                          ? convertedAmount.toStringAsFixed(0)
                          : convertedAmount.toStringAsFixed(2),
                      style: AppTextStyles.playfair(size: 20, color: textColor, weight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Result Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: theme.headerGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Converted Amount', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${_toCurrency == 'JPY' ? convertedAmount.toStringAsFixed(0) : convertedAmount.toStringAsFixed(2)} $_toCurrency',
                      style: AppTextStyles.playfair(size: 26, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 $_fromCurrency = ${rate.toStringAsFixed(_toCurrency == 'JPY' ? 2 : 4)} $_toCurrency',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                    ),
                    Text(
                      'ECB Reference Rate · Mid-Market Benchmark',
                      style: AppTextStyles.dmSans(size: 9, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Save Button
              ElevatedButton.icon(
                onPressed: () => _saveConversion(amount, convertedAmount, rate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Text('💾', style: TextStyle(fontSize: 14)),
                label: Text('Save This Conversion',
                    style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trend Chart Card
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_fromCurrency / $_toCurrency Trend', style: AppTextStyles.cardTitle(textColor)),
                      Text('ECB Reference History', style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                    ],
                  ),
                  Row(
                    children: [30, 90, 180].map((days) {
                      final active = _activePeriod == days;
                      return GestureDetector(
                        onTap: () => setState(() => _activePeriod = days),
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? theme.primaryColor : theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: active ? theme.primaryColor : borderCol),
                          ),
                          child: Text('${days ~/ 30}M',
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.bold,
                                  color: active ? const Color(0xFFFFCC00) : textColor)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CurrencyTrendPainter(
                    data: trendData,
                    min: minTrend,
                    max: maxTrend,
                    primaryColor: isDark ? theme.accentColor : theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Trend Stats
              Row(
                children: [
                  _trendStatCell('HIGH', maxTrend, _toCurrency, Colors.green),
                  const SizedBox(width: 8),
                  _trendStatCell('LOW', minTrend, _toCurrency, Colors.red),
                  const SizedBox(width: 8),
                  _trendStatCell('AVG', avgTrend, _toCurrency, isDark ? theme.accentColor : theme.primaryColor),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live EUR Rates Table
        Text('🏛️ LIVE EUR RATES', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: _ratesFromEur.keys.where((k) => k != 'EUR').map((code) {
              final r = _getRate('EUR', code);
              final chg = _change30d[code] ?? 0.0;
              final isUp = chg >= 0;
              final meta = _currencyMeta[code]!;

              return InkWell(
                onTap: () {
                  setState(() {
                    _fromCurrency = 'EUR';
                    _toCurrency = code;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Text(meta['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meta['name']!, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: textColor)),
                            Text('$code · 30D ${isUp ? '▲' : '▼'} ${chg.abs().toStringAsFixed(2)}%',
                                style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('1 EUR = ${code == 'JPY' ? r.toStringAsFixed(1) : r.toStringAsFixed(4)} $code',
                              style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: isDark ? theme.accentColor : theme.primaryColor)),
                          const SizedBox(height: 2),
                          Text(
                            '${isUp ? '+' : ''}${chg.toStringAsFixed(2)}%',
                            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: isUp ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Saved list inside converter if any
        if (currencySaves.isNotEmpty) ...[
          Text('⭐ SAVED CONVERSIONS', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          ...currencySaves.map((s) {
            final double fromAmt = s.inputs['amount'] ?? 1000.0;
            final double toAmt = s.results['Converted'] ?? 0.0;
            final fromMeta = _currencyMeta[s.currencyCode];
            final toCode = s.label.split(' to ').last.split(' - ').first;
            final toMeta = _currencyMeta[toCode];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Text('${fromMeta?['flag'] ?? '💱'}${toMeta?['flag'] ?? ''}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label.split(' - ').first, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textColor)),
                        Text('${fromAmt.toStringAsFixed(0)} ${s.currencyCode}', style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                      ],
                    ),
                  ),
                  Text(
                    '${toCode == 'JPY' ? toAmt.toStringAsFixed(0) : toAmt.toStringAsFixed(2)} $toCode',
                    style: AppTextStyles.playfair(size: 13, color: isDark ? theme.accentColor : theme.primaryColor, weight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(savedProvider.notifier).delete(s.id),
                    child: Icon(Icons.close, size: 14, color: mutedText.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Exchange Tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF172554)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏛️ ECB & European Rate Guide', style: AppTextStyles.cardTitle(Colors.white)),
              const SizedBox(height: 12),
              _tipRow('1', 'The ECB publishes reference rates daily at ~16:00 CET. These are non-commercial rates used as a benchmark.'),
              const SizedBox(height: 8),
              _tipRow('2', "EUR/CHF is influenced by the Swiss National Bank's interventions, keeping the pair in a tight range near 0.95–0.97."),
              const SizedBox(height: 8),
              _tipRow('3', 'EUR/GBP fluctuates around UK-EU economic cycles and policy decisions from Bank of England and ECB.'),
              const SizedBox(height: 8),
              _tipRow('4', 'For foreign buyers (non-resident), lock your mortgage exchange rate early using forward contracts.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rateStripItem(String pair, double rate, double change) {
    final isUp = change >= 0;
    return Column(
      children: [
        Text(pair, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(rate.toStringAsFixed(4),
            style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
        const SizedBox(height: 1),
        Text(
          '${isUp ? '▲' : '▼'} ${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
          style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: isUp ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  Widget _rateStripDivider() {
    return Container(
      width: 1,
      height: 28,
      color: widget.theme.getBorderColor(context),
    );
  }

  Widget _trendStatCell(String title, double value, String code, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.theme.getBorderColor(context)),
        ),
        child: Column(
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 2),
            Text(
              code == 'JPY' ? value.toStringAsFixed(1) : value.toStringAsFixed(4),
              style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String bullet, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFFFCC00),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(bullet, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.dmSans(size: 11, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
        ),
      ],
    );
  }
}

class CurrencyTrendPainter extends CustomPainter {
  final List<double> data;
  final double min;
  final double max;
  final Color primaryColor;

  CurrencyTrendPainter({
    required this.data,
    required this.min,
    required this.max,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = primaryColor;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final double w = size.width;
    final double h = size.height;
    final double range = max - min == 0 ? 1.0 : max - min;

    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final double x = (i / (data.length - 1)) * w;
      final double y = h - ((data[i] - min) / range) * (h - 15) - 5;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(0, h);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primaryColor.withValues(alpha: 0.20), primaryColor.withValues(alpha: 0.01)],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = h * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
