// lib/features/india/tools/in_nri_home_loan.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INNRIHomeLoan extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INNRIHomeLoan({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INNRIHomeLoan> createState() => _INNRIHomeLoanState();
}

class _INNRIHomeLoanState extends ConsumerState<INNRIHomeLoan> {
  String _activeCategory = 'NRI'; // 'NRI', 'PIO', 'OCI'
  String _selCountry = 'US'; // US, AE, GB, CA, AU, SG, SA, DE

  late TextEditingController _incomeController;
  late TextEditingController _propValueController;
  late TextEditingController _rateController;
  
  double _downPmtPct = 25.0; // 20, 25, 30, 40
  int _tenureYears = 20;

  final Map<String, double> _fxRates = {
    'US': 83.52,
    'AE': 22.74,
    'GB': 106.10,
    'CA': 61.80,
    'AU': 55.20,
    'SG': 62.30,
    'SA': 22.27,
    'DE': 90.20,
  };

  final Map<String, String> _fxSymbols = {
    'US': '\$',
    'AE': 'AED ',
    'GB': '£',
    'CA': 'CA\$',
    'AU': 'A\$',
    'SG': 'S\$',
    'SA': 'SAR ',
    'DE': '€',
  };

  final Map<String, String> _countryNames = {
    'US': '🇺🇸 USA (USD)',
    'AE': '🇦🇪 UAE (AED)',
    'GB': '🇬🇧 UK (GBP)',
    'CA': '🇨🇦 Canada (CAD)',
    'AU': '🇦🇺 Australia (AUD)',
    'SG': '🇸🇬 Singapore (SGD)',
    'SA': '🇸🇦 Saudi (SAR)',
    'DE': '🇩🇪 Germany (EUR)',
  };

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController(text: '8000');
    _propValueController = TextEditingController(text: '100'); // Default ₹100 Lakhs
    _rateController = TextEditingController(text: '8.75');
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _propValueController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double get _income => double.tryParse(_incomeController.text) ?? 8000.0;
  double get _propValue => double.tryParse(_propValueController.text) ?? 100.0;
  double get _rate => double.tryParse(_rateController.text) ?? 8.75;

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveNriCalculation() async {
    final double inrRate = _fxRates[_selCountry] ?? 83.52;
    final double inrIncome = _income * inrRate;
    final double loanAmt = _propValue * 100000 * (1 - _downPmtPct / 100);
    final double downAmt = _propValue * 100000 * (_downPmtPct / 100);
    final double mr = _rate / 12 / 100;
    final int nMonths = _tenureYears * 12;
    final double emi = mr > 0
        ? (loanAmt * mr * pow(1 + mr, nMonths)) / (pow(1 + mr, nMonths) - 1)
        : loanAmt / nMonths;
    final double totalPaid = emi * nMonths;
    final double totalInt = totalPaid - loanAmt;

    final labelCtrl = TextEditingController(text: 'NRI Home Loan - $_activeCategory');

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_nri_home_loan'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save NRI Calculation', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving eligibility calculation: EMI ₹${Compat.round(emi).toLocaleString()}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Dream Home Mumbai)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'NRI Home Loan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'NRI Home Loan',
        inputs: {
          'category': _activeCategory == 'NRI' ? 0.0 : (_activeCategory == 'PIO' ? 1.0 : 2.0),
          'foreignIncome': _income,
          'propertyValueLakhs': _propValue,
          'downPaymentPct': _downPmtPct,
          'interestRate': _rate,
          'tenureYears': _tenureYears.toDouble(),
          'exchangeRate': inrRate,
        },
        results: {
          'emiINR': emi,
          'loanAmountINR': loanAmt,
          'downPaymentINR': downAmt,
          'totalInterestINR': totalInt,
          'totalPayableINR': totalPaid,
          'inrIncome': inrIncome,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ NRI Home Loan calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    // Financial Calculation Math
    final double inrRate = _fxRates[_selCountry] ?? 83.52;
    final double inrIncome = _income * inrRate;
    final double loanAmt = _propValue * 100000 * (1 - _downPmtPct / 100);
    final double downAmt = _propValue * 100000 * (_downPmtPct / 100);
    final double mr = _rate / 12 / 100;
    final int nMonths = _tenureYears * 12;
    
    final double emi = mr > 0
        ? (loanAmt * mr * pow(1 + mr, nMonths)) / (pow(1 + mr, nMonths) - 1)
        : loanAmt / nMonths;
    final double totalPaid = emi * nMonths;
    final double totalInt = totalPaid - loanAmt;
    
    final double foir = inrIncome > 0 ? (emi / inrIncome * 100) : 0.0;
    final double emiInForeign = emi / inrRate;
    final String symbol = _fxSymbols[_selCountry] ?? '\$';

    final double pctPrincipal = totalPaid > 0 ? (loanAmt / totalPaid) : 0.5;
    final double pctInterest = totalPaid > 0 ? (totalInt / totalPaid) : 0.5;

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
              _buildRateStripItem('NRI Rate (SBI)', '8.50%', 'Floating', isSaffron: true),
              _buildRateStripItem('Max Tenure', '30 Yrs', 'NRI Cap', isGreen: true),
              _buildRateStripItem('Max LTV', '75–80%', 'Of Value'),
              _buildRateStripItem('USD/INR', '₹83.52', 'Live Ref'),
            ],
          ),
        ),

        // 2. FEMA / RBI Rules Hero Banner
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
              Text('FEMA • RBI • INCOME TAX ACT — INDIA',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text('Buy property in India\nas an NRI / PIO / OCI',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 10),
              Text('NRIs, PIOs and OCIs can purchase residential and commercial property in India under FEMA. Loan in INR, EMI via NRE/NRO account.',
                  style: AppTextStyles.dmSans(size: 10, color: Colors.white70, height: 1.4)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildHeroStat('Best NRI Rate', '8.50% p.a.', isGreen: true),
                  const SizedBox(width: 8),
                  _buildHeroStat('Processing Fee', '0.35–0.50%'),
                  const SizedBox(width: 8),
                  _buildHeroStat('Max Loan', '₹10 Cr'),
                ],
              )
            ],
          ),
        ),

        // 3. Category Selector
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Select Your Category', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Row(
          children: [
            _buildCategoryPill('🌍 NRI', 'NRI'),
            const SizedBox(width: 6),
            _buildCategoryPill('🇮🇳 PIO', 'PIO'),
            const SizedBox(width: 6),
            _buildCategoryPill('📘 OCI', 'OCI'),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏠 EMI & Eligibility Calculator', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 16),

              // Country Dropdown
              Text('COUNTRY OF RESIDENCE', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selCountry,
                    isExpanded: true,
                    dropdownColor: theme.getCardColor(context),
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: theme.getTextColor(context)),
                    items: _countryNames.keys.map((code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(_countryNames[code]!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selCountry = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Synced Monthly Income
              _buildSyncSliderRow(
                title: 'Monthly Income (Foreign)',
                controller: _incomeController,
                min: 1000,
                max: 50000,
                divisions: 98,
                displayValue: '$symbol${Compat.round(_income).toLocaleString()}',
                isCurrency: true,
                hint: 'In foreign currency',
              ),
              const SizedBox(height: 16),

              // Property Value (Lakhs)
              _buildSyncSliderRow(
                title: 'Property Value (₹ Lakhs)',
                controller: _propValueController,
                min: 10,
                max: 1000,
                divisions: 99,
                displayValue: '₹${_propValue.toStringAsFixed(0)} Lakhs',
                hint: '1 Lakh = ₹100,000',
              ),
              const SizedBox(height: 16),

              // Down Payment Dropdown and Tenure Dropdown
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DOWN PAYMENT (%)', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: theme.getBorderColor(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _downPmtPct,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: theme.getTextColor(context)),
                              items: const [
                                DropdownMenuItem(value: 20.0, child: Text('20% (Standard)')),
                                DropdownMenuItem(value: 25.0, child: Text('25% (Preferred)')),
                                DropdownMenuItem(value: 30.0, child: Text('30% (Conservative)')),
                                DropdownMenuItem(value: 40.0, child: Text('40% (Lower EMI)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _downPmtPct = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TENURE (YEARS)', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: theme.getBorderColor(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _tenureYears,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: theme.getTextColor(context)),
                              items: const [
                                DropdownMenuItem(value: 10, child: Text('10 Years')),
                                DropdownMenuItem(value: 15, child: Text('15 Years')),
                                DropdownMenuItem(value: 20, child: Text('20 Years')),
                                DropdownMenuItem(value: 25, child: Text('25 Years')),
                                DropdownMenuItem(value: 30, child: Text('30 Years (Max)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _tenureYears = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Synced Interest Rate
              _buildSyncSliderRow(
                title: 'Interest Rate (%)',
                controller: _rateController,
                min: 7.0,
                max: 15.0,
                divisions: 160,
                displayValue: '${_rate.toStringAsFixed(2)}%',
                hint: 'NRI rate typically 0.25% above resident',
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Calculations updated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF046A38),
                      duration: const Duration(milliseconds: 600),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '✈️ Calculate NRI Home Loan',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 5. Result Card Analyser
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NRI Home Loan — EMI Analysis', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 16),

              // EMI Big Display
              Center(
                child: Column(
                  children: [
                    Text('Monthly EMI (INR)', style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('₹', style: AppTextStyles.dmSans(size: 18, color: const Color(0xFFFFDEA0), weight: FontWeight.w800)),
                        Text(
                          Compat.round(emi).toLocaleString(),
                          style: AppTextStyles.playfair(size: 34, color: Colors.white, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '≈ $symbol${Compat.round(emiInForeign).toLocaleString()} • $_tenureYears yr @ ${_rate.toStringAsFixed(2)}%',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Result grid (6 metrics)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildResultGridItem('Loan Amount', _fmt(loanAmt), 'INR Val'),
                  _buildResultGridItem('Down Payment', _fmt(downAmt), '${_downPmtPct.toStringAsFixed(0)}% upfront', isWarn: true),
                  _buildResultGridItem('Total Interest', _fmt(totalInt), 'Cost of Credit'),
                  _buildResultGridItem('Total Paid', _fmt(totalPaid), 'Principal + Interest'),
                  _buildResultGridItem('INR Equiv. of Income', _fmt(inrIncome), 'At Reference Rate'),
                  _buildResultGridItem('FOIR (EMI/Income)', '${foir.toStringAsFixed(1)}%', 'Limit 55%', isFoirHighlight: true, foirVal: foir),
                ],
              ),
              const SizedBox(height: 16),

              // Amortization progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Principal: ${(pctPrincipal * 100).toStringAsFixed(0)}%', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                      Text('Interest: ${(pctInterest * 100).toStringAsFixed(0)}%', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 14,
                      color: Colors.white12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (pctPrincipal * 100).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFF5A623)]),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: (pctInterest * 100).round(),
                            child: Container(
                              color: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveNriCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: const Icon(Icons.save, size: 16),
                  label: Text('Save This Calculation', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 6. Top Banks Card
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Top Banks for NRI Home Loans', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
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
              Text('🏦 Current NRI Home Loan Rates (2025)', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 12),
              _buildBankRow('🏦', 'SBI NRI Home Loan', 'PSU • Floating • NRE/NRO', '8.50%', 'Best'),
              _buildBankRow('🏛️', 'HDFC Bank NRI', 'Private • Floating • Global', '8.70%', 'Popular'),
              _buildBankRow('💼', 'ICICI NRI Loan', 'Private • App-based • Fast', '8.75%', 'Digital'),
              _buildBankRow('⚡', 'Axis Bank NRI', 'Private • Doorstep in US/UAE', '8.75%', 'Premium'),
              _buildBankRow('🏗️', 'LIC HFL NRI', 'HFC • Long tenure • Fixed opt.', '8.65%', 'HFC'),
              _buildBankRow('🌿', 'Bank of Baroda NRI', 'PSU • Low charges • Global', '8.55%', 'PSU'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 7. Key FEMA Rules List
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('NRI Loan — Must Know Rules', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Column(
          children: [
            _buildRuleItem('💳', 'EMI via NRE/NRO Account Only', 'All loan repayments must be through NRE or NRO account. Direct foreign currency transfer is also allowed via FCNR. Cash payments not permitted under FEMA.', 'FEMA Rule'),
            _buildRuleItem('🏠', 'Only Residential & Commercial — No Agricultural', 'NRIs can buy residential and commercial property. Agricultural land, farmhouse, and plantation property are prohibited under FEMA without special RBI permission.', 'Restriction'),
            _buildRuleItem('📋', 'PoA (Power of Attorney) Needed', 'Since NRI cannot always be present in India, a notarised and registered PoA is required for property registration and loan documents.', 'Documentation'),
            _buildRuleItem('💰', 'Rental Income — Taxable in India', 'Rental income from Indian property is taxable in India at 30% TDS (for NRI). Available deductions: municipal taxes, 30% standard deduction, interest on loan.', 'Tax Note'),
          ],
        ),
      ],
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
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

  Widget _buildHeroStat(String label, String val, {bool isGreen = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(val, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: isGreen ? const Color(0xFF86EFAC) : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label, String catCode) {
    final isSelected = _activeCategory == catCode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeCategory = catCode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B1F48) : widget.theme.getCardColor(context),
            border: Border.all(color: isSelected ? const Color(0xFF0B1F48) : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: isSelected ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
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
    bool isCurrency = false,
    String? hint,
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
                onSubmitted: (val) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
        ]
      ],
    );
  }

  Widget _buildResultGridItem(String label, String value, String sub, {bool isWarn = false, bool isFoirHighlight = false, double foirVal = 0.0}) {
    Color valColor = Colors.white;
    if (isWarn) {
      valColor = const Color(0xFFFDE68A);
    } else if (isFoirHighlight) {
      valColor = foirVal > 55 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: valColor)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildBankRow(String emoji, String name, String sub, String rate, String badge) {
    final theme = widget.theme;
    Color badgeBg = const Color(0xFFEFF6FF);
    Color badgeTxt = const Color(0xFF1D4ED8);
    if (badge == 'Best' || badge == 'PSU') {
      badgeBg = const Color(0xFFECFDF5);
      badgeTxt = const Color(0xFF065F46);
    } else if (badge == 'Premium') {
      badgeBg = const Color(0xFFFFF3E0);
      badgeTxt = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Text(rate, style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: const Color(0xFFFF6B00))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: badgeTxt)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String desc, String badgeText) {
    final theme = widget.theme;
    Color badgeBg = const Color(0xFFEFF6FF);
    Color badgeTxt = const Color(0xFF1D4ED8);
    if (badgeText == 'Restriction') {
      badgeBg = const Color(0xFFFEF2F2);
      badgeTxt = const Color(0xFFB91C1C);
    } else if (badgeText == 'Documentation') {
      badgeBg = const Color(0xFFFFF3E0);
      badgeTxt = const Color(0xFFE05A00);
    } else if (badgeText == 'Tax Note') {
      badgeBg = const Color(0xFFECFDF5);
      badgeTxt = const Color(0xFF065F46);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.4)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeText, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: badgeTxt)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
