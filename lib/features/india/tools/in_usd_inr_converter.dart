// lib/features/india/tools/in_usd_inr_converter.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INUSDINRConverter extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INUSDINRConverter({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INUSDINRConverter> createState() => _INUSDINRConverterState();
}

class _INUSDINRConverterState extends ConsumerState<INUSDINRConverter> {
  late TextEditingController _usdController;
  late TextEditingController _inrController;
  late TextEditingController _spreadController;
  late TextEditingController _wireFeeController;

  final double _baseRate = 95.42; // Live RBI reference rate as per HTML
  final List<double> _trendPoints = const [74.3, 76.5, 79.2, 81.8, 82.9, 95.42];

  @override
  void initState() {
    super.initState();
    _usdController = TextEditingController(text: '1000');
    _inrController = TextEditingController(text: '95420.00');
    _spreadController = TextEditingController(text: '1.0');
    _wireFeeController = TextEditingController(text: '20.0');
  }

  @override
  void dispose() {
    _usdController.dispose();
    _inrController.dispose();
    _spreadController.dispose();
    _wireFeeController.dispose();
    super.dispose();
  }

  double get _usdAmount => double.tryParse(_usdController.text) ?? 0.0;
  double get _spreadPct => double.tryParse(_spreadController.text) ?? 1.0;
  double get _wireFeeUsd => double.tryParse(_wireFeeController.text) ?? 20.0;

  void _onUsdChanged(String value) {
    final usd = double.tryParse(value) ?? 0.0;
    final inr = usd * _baseRate;
    _inrController.text = inr.toStringAsFixed(2);
    setState(() {});
  }

  void _onInrChanged(String value) {
    final inr = double.tryParse(value) ?? 0.0;
    final usd = inr / _baseRate;
    _usdController.text = usd.toStringAsFixed(2);
    setState(() {});
  }

  void _setUsdAmount(double amt) {
    _usdController.text = amt.toStringAsFixed(0);
    _onUsdChanged(amt.toString());
  }

  void _swapCurrencies() {
    final inrText = _inrController.text;
    _usdController.text = inrText;
    _onUsdChanged(inrText);
  }

  void _saveConversion() async {
    final double rate = _baseRate * (1 - (_spreadPct / 100));
    final double netUsd = max(_usdAmount - _wireFeeUsd, 0.0);
    final double netInrBeforeTcs = netUsd * rate;
    final double excess = max(netInrBeforeTcs - 700000.0, 0.0);
    final double tcs = excess * 0.20;
    final double netInr = netInrBeforeTcs - tcs;
    final double markupCost = _usdAmount * _baseRate * (_spreadPct / 100);

    final labelCtrl = TextEditingController(text: 'Remittance Conversion');

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_usd_inr_converter'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Conversion Snapshot', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving USD/INR Remittance: \$${Compat.round(_usdAmount).toLocaleString()} ➔ ₹${Compat.round(netInr).toLocaleString()} Net',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Property Downpayment)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'USD/INR Remittance';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'USD/INR Remittance',
        inputs: {
          'usdAmount': _usdAmount,
          'spreadPercent': _spreadPct,
          'wireFeeUsd': _wireFeeUsd,
          'baseRate': _baseRate,
        },
        results: {
          'netAmountINR': netInr,
          'effectiveRate': rate,
          'markupCostINR': markupCost,
          'tcsDeducted': tcs,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Remittance snapshot saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Remittance Computations
    final double rate = _baseRate * (1 - (_spreadPct / 100));
    final double netUsd = max(_usdAmount - _wireFeeUsd, 0.0);
    final double netInrBeforeTcs = netUsd * rate;
    
    // TCS: 20% on amount exceeding 7 Lakhs (700,000 INR)
    final double excess = max(netInrBeforeTcs - 700000.0, 0.0);
    final double tcs = excess * 0.20;
    final double netInr = netInrBeforeTcs - tcs;

    final double markupCost = _usdAmount * _baseRate * (_spreadPct / 100);

    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Rate Strip Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('USD/INR Live', '95.42', 'Live RBI', isSaffron: true),
              _buildRateStripItem('24h Change', '-0.42%', '↓ Rupee', isWarn: true),
              _buildRateStripItem('52W High', '96.57', 'May 2026', isGreen: true),
              _buildRateStripItem('52W Low', '89.86', 'Jan 2026'),
            ],
          ),
        ),

        // 2. Hero Remittance Converter Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌐 NRI REMITTANCE TOOL • 1 USD = ₹95.42',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text('Convert USD ⇄ INR\nfor Property & Remittance',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 12),

              // Quick Amount Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [1000.0, 5000.0, 10000.0, 25000.0, 50000.0].map((amt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () => _setUsdAmount(amt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('\$${Compat.round(amt).toLocaleString()}',
                              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Input Pair
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('🇺🇸', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text('USD', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 12),
                    const Expanded(child: VerticalDivider(color: Colors.white24, width: 1)),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _usdController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: Colors.white),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00', hintStyle: TextStyle(color: Colors.white24)),
                        onChanged: _onUsdChanged,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _swapCurrencies,
                  icon: const Icon(Icons.swap_vert, color: Colors.white60, size: 16),
                  label: Text('Swap Currencies', style: AppTextStyles.dmSans(size: 10, color: Colors.white60)),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text('INR', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 12),
                    const Expanded(child: VerticalDivider(color: Colors.white24, width: 1)),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _inrController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: Colors.white),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00', hintStyle: TextStyle(color: Colors.white24)),
                        onChanged: _onInrChanged,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Converted Amount Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF046A38).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Converted Amount', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
                        Text('₹${Compat.round(_usdAmount * _baseRate).toLocaleString()}',
                            style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: const Color(0xFF86EFAC))),
                        Text('At RBI Reference Rate', style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bank Rate Est. (~1% spread)', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
                        Text('₹${Compat.round(_usdAmount * _baseRate * 0.99).toLocaleString()}',
                            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white70)),
                        Text('Excluding wire fees', style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hero buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _onUsdChanged(_usdController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text('💱 Convert Now', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveConversion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        side: const BorderSide(color: Colors.white30, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white, size: 14),
                      label: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        // 3. Synced Remittance Inputs
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remittance Inputs', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 16),
              _buildSyncSliderRow(
                title: 'USD SEND AMOUNT (\$)',
                controller: _usdController,
                min: 500,
                max: 50000,
                divisions: 99,
                displayValue: '\$${Compat.round(_usdAmount).toLocaleString()}',
                onChanged: _onUsdChanged,
              ),
              const SizedBox(height: 12),
              _buildSyncSliderRow(
                title: 'BANK EXCHANGE MARKUP SPREAD (%)',
                controller: _spreadController,
                min: 0.1,
                max: 3.5,
                divisions: 34,
                displayValue: '${_spreadPct.toStringAsFixed(2)}%',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildSyncSliderRow(
                title: 'OUTWARD WIRE FEE (\$)',
                controller: _wireFeeController,
                min: 0.0,
                max: 50.0,
                divisions: 10,
                displayValue: '\$${_wireFeeUsd.toInt()}',
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // 4. Remittance Cost Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remittance Cost Breakdown', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 12),
              _buildCostRow('Amount to Send', '\$${Compat.round(_usdAmount).toLocaleString()} USD'),
              _buildCostRow('RBI Reference Rate', '₹${_baseRate.toStringAsFixed(2)} / USD'),
              _buildCostRow('Total Raw Value', numFormat.format(_usdAmount * _baseRate)),
              _buildCostRow('Bank Spread Loss (~$_spreadPct%)', '- ${numFormat.format(markupCost)}', isRed: true),
              _buildCostRow('Foreign Bank Wire Fee', '- ${numFormat.format(_wireFeeUsd * _baseRate)}', isRed: true),
              _buildCostRow('TCS (20% on excess above ₹7L)', tcs > 0 ? '- ${numFormat.format(tcs)}' : 'NIL (Under threshold)', isRed: tcs > 0),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, thickness: 1),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildCostRow('Amount Received (NRE/NRO)', numFormat.format(netInr), isBold: true, isGreen: true),
              ),
            ],
          ),
        ),

        // 5. 5-Year Historical Sparkline
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📈 USD/INR 5-Year Exchange Trend', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TrendChartPainter(points: _trendPoints, isDark: isDark),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2020: ₹74.3', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                  Text('2022: ₹79.2', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                  Text('Current: ₹95.42', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCell('Current', '95.42'),
                  _buildStatCell('52W High', '96.57', isRed: true),
                  _buildStatCell('52W Low', '89.86', isGreen: true),
                  _buildStatCell('6M Avg', '92.85'),
                ],
              ),
            ],
          ),
        ),

        // 6. Live Cross Rates
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Live Cross Rates', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NRI Remittance Currencies', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 12),
              _buildRatePair('🇺🇸🇮🇳', 'USD / INR', 'US Dollar', '95.42', '-0.42%', isUp: false),
              _buildRatePair('🇬🇧🇮🇳', 'GBP / INR', 'British Pound', '121.18', '+0.18%', isUp: true),
              _buildRatePair('🇦🇪🇮🇳', 'AED / INR', 'UAE Dirham', '25.99', '-0.42%', isUp: false),
              _buildRatePair('🇸🇬🇮🇳', 'SGD / INR', 'Singapore Dollar', '71.43', '+0.11%', isUp: true),
              _buildRatePair('🇦🇺🇮🇳', 'AUD / INR', 'Australian Dollar', '61.87', '-0.29%', isUp: false),
              _buildRatePair('🇨🇦🇮🇳', 'CAD / INR', 'Canadian Dollar', '70.12', '+0.07%', isUp: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isSaffron = false, bool isGreen = false, bool isWarn = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    } else if (isWarn) {
      valColor = const Color(0xFFFCA5A5);
    }
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildSyncSliderRow({
    required String title,
    required TextEditingController controller,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<String> onChanged,
  }) {
    final theme = widget.theme;
    final currentVal = double.tryParse(controller.text) ?? min;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white12 : const Color(0xFFF5E6D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: const Color(0xFFFF6B00),
                  inactiveTrackColor: inactiveColor,
                  thumbColor: const Color(0xFFFF6B00),
                  overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: currentVal.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (val) {
                    setState(() {
                      controller.text = val.toStringAsFixed(0);
                    });
                    onChanged(val.toString());
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              height: 32,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  filled: true,
                  fillColor: theme.getBgColor(context),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.getBorderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                ),
                onChanged: onChanged,
                onSubmitted: (val) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String value, {bool isRed = false, bool isBold = false, bool isGreen = false}) {
    final theme = widget.theme;
    Color valCol = theme.getTextColor(context);
    if (isRed) {
      valCol = const Color(0xFFFF6B00);
    } else if (isGreen) {
      valCol = const Color(0xFF046A38);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, weight: isBold ? FontWeight.w800 : FontWeight.w600, color: theme.getTextColor(context))),
          Text(value, style: AppTextStyles.dmSans(size: 12, weight: isBold ? FontWeight.w800 : FontWeight.bold, color: valCol)),
        ],
      ),
    );
  }

  Widget _buildStatCell(String title, String val, {bool isRed = false, bool isGreen = false}) {
    final theme = widget.theme;
    Color col = theme.getTextColor(context);
    if (isRed) col = const Color(0xFFFF6B00);
    if (isGreen) col = const Color(0xFF046A38);

    return Column(
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: col)),
      ],
    );
  }

  Widget _buildRatePair(String flags, String name, String sub, String rate, String change, {required bool isUp}) {
    final theme = widget.theme;
    Color chgColor = isUp ? const Color(0xFF046A38) : const Color(0xFFFF6B00);
    String chgSign = isUp ? '▲' : '▼';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(flags, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                  Text(sub, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rate, style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('$chgSign $change', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: chgColor)),
            ],
          )
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> points;
  final bool isDark;

  _TrendChartPainter({required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF3E8D0)
      ..strokeWidth = 1;

    final double width = size.width;
    final double height = size.height;

    // Draw horizontal grid lines
    canvas.drawLine(const Offset(0, 0), Offset(width, 0), gridPaint);
    canvas.drawLine(Offset(0, height / 2), Offset(width, height / 2), gridPaint);
    canvas.drawLine(Offset(0, height), Offset(width, height), gridPaint);

    if (points.isEmpty) return;

    const double minVal = 70.0;
    const double maxVal = 100.0;
    const double valRange = maxVal - minVal;

    final double stepX = width / (points.length - 1);
    final path = Path();
    final fillPath = Path();

    fillPath.moveTo(0, height);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final val = points[i];
      final y = height - ((val - minVal) / valRange) * height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    // Fill under path
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFF6B00).withValues(alpha: 0.2), const Color(0xFFFF6B00).withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = const Color(0xFFFF6B00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => oldDelegate.points != points;
}
