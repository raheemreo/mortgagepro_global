// lib/features/india/tools/in_nre_nro_account.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INNRENROAccount extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INNRENROAccount({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INNRENROAccount> createState() => _INNRENROAccountState();
}

class _INNRENROAccountState extends ConsumerState<INNRENROAccount> {
  String _acctType = 'nre'; // 'nre', 'nro', 'fcnr'
  String _compounding = 'quarterly'; // 'monthly', 'quarterly', 'half-yearly', 'yearly'

  late TextEditingController _depositController;
  late TextEditingController _rateController;
  late TextEditingController _tenureController;

  @override
  void initState() {
    super.initState();
    _depositController = TextEditingController(text: '10.0'); // 10.0 Lakhs
    _rateController = TextEditingController(text: '7.10');
    _tenureController = TextEditingController(text: '3');
  }

  @override
  void dispose() {
    _depositController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  double get _deposit => double.tryParse(_depositController.text) ?? 10.0;
  double get _rate => double.tryParse(_rateController.text) ?? 7.10;
  int get _tenure => int.tryParse(_tenureController.text) ?? 3;

  void _selectAccountType(String type) {
    setState(() {
      _acctType = type;
      if (type == 'nre' || type == 'nro') {
        _rateController.text = '7.10';
      } else {
        _rateController.text = '5.75';
      }
    });
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveFdCalculation() async {
    final double p = _deposit * 100000;
    final double r = _rate / 100;
    final double t = _tenure.toDouble();
    int n = 4;
    if (_compounding == 'monthly') n = 12;
    if (_compounding == 'half-yearly') n = 2;
    if (_compounding == 'yearly') n = 1;

    final double rawMaturity = p * pow(1 + (r / n), n * t);
    final double interest = rawMaturity - p;
    final double tdsRate = (_acctType == 'nro') ? 0.312 : 0.0;
    final double tds = interest * tdsRate;
    final double netMaturity = rawMaturity - tds;

    final labelCtrl = TextEditingController(
      text: '${_acctType.toUpperCase()} FD Maturity',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_nre_nro_account'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save FD Calculation', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving maturity: ₹${Compat.round(netMaturity).toLocaleString()}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Retirement Deposit)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'NRE/NRO FD Maturity';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'NRE/NRO Account FD',
        inputs: {
          'depositLakhs': _deposit,
          'interestRate': _rate,
          'tenureYears': t,
          'accountType': _acctType == 'nre' ? 0.0 : (_acctType == 'nro' ? 1.0 : 2.0),
          'compoundingIndex': _compounding == 'monthly' ? 12.0 : (_compounding == 'quarterly' ? 4.0 : (_compounding == 'half-yearly' ? 2.0 : 1.0)),
        },
        results: {
          'maturityRaw': rawMaturity,
          'netMaturity': netMaturity,
          'tdsDeducted': tds,
          'netInterest': interest - tds,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ FD calculation saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    // Compounding Math
    final double p = _deposit * 100000;
    final double r = _rate / 100;
    final double t = _tenure.toDouble();
    int nComp = 4;
    if (_compounding == 'monthly') nComp = 12;
    if (_compounding == 'half-yearly') nComp = 2;
    if (_compounding == 'yearly') nComp = 1;

    final double rawMaturity = p * pow(1 + (r / nComp), nComp * t);
    final double grossInt = rawMaturity - p;
    final double tdsRate = (_acctType == 'nro') ? 0.312 : 0.0;
    final double tds = grossInt * tdsRate;
    final double netAmt = rawMaturity - tds;

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
              _buildRateStripItem('NRE Tax Status', '100% Free', 'Tax-exempt', isGreen: true),
              _buildRateStripItem('NRO Tax Status', '31.2% TDS', 'On Interest', isSaffron: true),
              _buildRateStripItem('Repatriability', 'NRE: Free', 'NRO: Limit \$1M'),
              _buildRateStripItem('FD Compound', 'Quarterly', 'Govt Rule'),
            ],
          ),
        ),

        // 2. Hero A/c Difference Guide
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
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
              Text('NON-RESIDENT EXTERNAL VS NON-RESIDENT ORDINARY',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text('NRE vs NRO — Know the Difference',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 10),
              Text('Two distinct accounts with different rules on taxation, repatriation, and permitted credits. Choosing the right one saves tax and simplifies your finances.',
                  style: AppTextStyles.dmSans(size: 10, color: Colors.white70, height: 1.4)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildHeroStat('NRE Interest', 'Tax-Free', isGreen: true),
                  const SizedBox(width: 8),
                  _buildHeroStat('NRO TDS', '30%+Cess', isWarn: true),
                  const SizedBox(width: 8),
                  _buildHeroStat('USD Repatriation', '\$1M/yr'),
                ],
              )
            ],
          ),
        ),

        // 3. Side-by-Side Comparison
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Account Comparison (RBI Guidelines)', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCompareCard('NRE', 'Non-Resident External', [
              _buildCompareRow('Currency', 'INR (converted from foreign)'),
              _buildCompareRow('Taxation', 'Tax-Free Interest', isOk: true),
              _buildCompareRow('Repatriation', 'Freely Repatriable', isOk: true),
              _buildCompareRow('Joint A/c', 'With NRI only'),
              _buildCompareRow('Best For', 'Foreign income parking • Tax savings'),
            ], true)),
            const SizedBox(width: 10),
            Expanded(child: _buildCompareCard('NRO', 'Non-Resident Ordinary', [
              _buildCompareRow('Currency', 'INR only'),
              _buildCompareRow('Taxation', '31.2% TDS (incl. Cess)', isWarn: true),
              _buildCompareRow('Repatriation', 'USD 1M/yr (with CA cert)'),
              _buildCompareRow('Joint A/c', 'With Resident Indian'),
              _buildCompareRow('Best For', 'Indian income: rent, pension, dividends'),
            ], false)),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Bank Rates Table
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('FD Interest Rates (June 2025)', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
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
              Text('🏦 NRE / NRO FD Interest Rates — Major Banks', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 12),
              _buildRatesTable(theme),
              const SizedBox(height: 10),
              Text('* NRE FD interest is tax-free in India. NRO FD interest subject to 30% TDS + 4% cess. Rates as of June 2025.',
                  style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. FD Returns Calculator Inputs
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('FD Interest Calculator', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
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
              Text('💰 Calculate FD Returns', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 16),

              // Account Type Toggle Selectors
              Text('ACCOUNT TYPE', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildToggleBtn('NRE Account', _acctType == 'nre', () => _selectAccountType('nre')),
                  const SizedBox(width: 4),
                  _buildToggleBtn('NRO Account', _acctType == 'nro', () => _selectAccountType('nro')),
                  const SizedBox(width: 4),
                  _buildToggleBtn('FCNR Account', _acctType == 'fcnr', () => _selectAccountType('fcnr')),
                ],
              ),
              const SizedBox(height: 16),

              // Deposit Amount Sync Row
              _buildSyncSliderRow(
                title: 'Deposit Amount (₹ Lakh)',
                controller: _depositController,
                min: 1.0,
                max: 100.0,
                divisions: 99,
                displayValue: '₹${Compat.round(_deposit).toLocaleString()} Lakh',
              ),
              const SizedBox(height: 16),

              // Compounding Frequency Dropdown and Tenure Dropdown
              Row(
                children: [
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
                              value: _tenure,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: theme.getTextColor(context)),
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1 Year')),
                                DropdownMenuItem(value: 2, child: Text('2 Years')),
                                DropdownMenuItem(value: 3, child: Text('3 Years')),
                                DropdownMenuItem(value: 5, child: Text('5 Years')),
                                DropdownMenuItem(value: 10, child: Text('10 Years (Max)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _tenureController.text = val.toString());
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
                        Text('COMPOUNDING', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
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
                              value: _compounding,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: theme.getTextColor(context)),
                              items: const [
                                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                                DropdownMenuItem(value: 'half-yearly', child: Text('Half-Yearly')),
                                DropdownMenuItem(value: 'yearly', child: Text('Annually')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _compounding = val);
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

              // Synced FD Rate Sync Row
              _buildSyncSliderRow(
                title: 'FD Interest Rate (%)',
                controller: _rateController,
                min: 5.0,
                max: 10.0,
                divisions: 100,
                displayValue: '${_rate.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 20),

              // Calculate Returns Button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ FD returns updated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
                    '💱 Calculate FD Returns',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 6. Returns Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
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
              Text('FD Maturity — ${_acctType.toUpperCase()} Account', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 16),

              // Maturity Big Display
              Center(
                child: Column(
                  children: [
                    Text('Maturity Amount', style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${Compat.round(netAmt).toLocaleString()}',
                      style: AppTextStyles.playfair(size: 34, color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gross Interest: ₹${Compat.round(grossInt).toLocaleString()} • ${_acctType == 'nro' ? '31.2% TDS applied' : 'Tax-Free'}',
                      style: AppTextStyles.dmSans(size: 10, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4-grid returns summary
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildResultGridItem('Principal', _fmt(p), 'Deposit Amount'),
                  _buildResultGridItem('Gross Interest', _fmt(grossInt), 'Raw Earnings'),
                  _buildResultGridItem('TDS Deducted', tds > 0 ? _fmt(tds) : 'NIL (Tax-Free)', 'Indian Income Tax', isWarn: tds > 0),
                  _buildResultGridItem('Net Take-Home', _fmt(netAmt), 'Principal + Net Interest', isOk: true),
                ],
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveFdCalculation,
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

        // 7. Repatriation Rules
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Repatriation Rules', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Column(
          children: [
            _buildRuleItem('🌍', 'NRE — Freely Repatriable', 'Both principal and interest in NRE accounts can be freely repatriated (sent abroad) without any restrictions. No RBI permission needed. Use any authorised dealer bank.', 'No Limit'),
            _buildRuleItem('💰', 'NRO — USD 1 Million / Year', 'Up to USD 1,000,000 per financial year can be repatriated from NRO account. Requires Form 15CA/15CB from Chartered Accountant and bank declaration.', 'USD 1M Cap'),
            _buildRuleItem('📋', 'Documents for NRO Repatriation', 'Form 15CA (online), Form 15CB (CA certificate), A2 Form (bank), source of funds declaration, income tax clearance if applicable.', 'CA Required'),
            _buildRuleItem('🏠', 'Property Sale Proceeds — NRO Only', 'Proceeds from sale of Indian property must go into NRO account first. Can then repatriate up to USD 1M/year after tax payment and CA certification.', 'Restriction'),
          ],
        ),

        const SizedBox(height: 20),

        // 8. FCNR Info
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('FCNR — Foreign Currency Account', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Column(
          children: [
            _buildRuleItem('💵', 'FCNR — Foreign Currency Non-Resident (B)', 'Fixed deposit in foreign currency (USD, GBP, EUR, CAD, AUD, SGD). No currency risk as funds stay in original currency. Tenure: 1–5 years. Interest rate set by RBI ceiling.', 'No Currency Risk'),
            _buildRuleItem('📊', 'FCNR Interest Rates (2025 Ceiling)', 'USD: 5.50–6.50% p.a. • GBP: 4.50–5.25% • EUR: 3.00–3.75% • CAD: 4.75–5.50% • AUD: 4.25–5.00%. Interest fully repatriable and tax-free in India.', 'Tax-Free India'),
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

  Widget _buildHeroStat(String label, String val, {bool isGreen = false, bool isWarn = false}) {
    Color statColor = Colors.white;
    if (isGreen) {
      statColor = const Color(0xFF86EFAC);
    } else if (isWarn) {
      statColor = const Color(0xFFFCA5A5);
    }
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
            Text(val, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: statColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareCard(String title, String subtitle, List<Widget> children, bool isNre) {
    final startCol = isNre ? const Color(0xFF0B1F48) : const Color(0xFF07543A);
    final endCol = isNre ? const Color(0xFF1A3A8F) : const Color(0xFF046A38);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startCol, endCol], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: Colors.white)),
          Text(subtitle, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCompareRow(String label, String value, {bool isOk = false, bool isWarn = false}) {
    Color col = Colors.white;
    if (isOk) col = const Color(0xFF86EFAC);
    if (isWarn) col = const Color(0xFFFCA5A5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38, weight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: col, height: 1.3)),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildRatesTable(CountryTheme theme) {
    final rows = [
      ['SBI', '6.80%', '6.50%', '6.80%'],
      ['HDFC Bank', '7.10%', '7.00%', '7.10%'],
      ['ICICI Bank', '7.00%', '6.90%', '7.00%'],
      ['Axis Bank', '7.00%', '7.00%', '7.00%'],
      ['Kotak Bank', '7.10%', '7.10%', '7.10%'],
      ['Baroda Bank', '6.85%', '6.75%', '6.85%'],
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.4),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.0),
        3: FlexColumnWidth(1.0),
      },
      border: TableBorder(horizontalInside: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.3), width: 0.5)),
      children: [
        TableRow(
          children: [
            _tableHeaderCell('Bank'),
            _tableHeaderCell('NRE 1yr'),
            _tableHeaderCell('NRE 3yr'),
            _tableHeaderCell('NRO 1yr'),
          ],
        ),
        ...rows.map((row) {
          return TableRow(
            children: [
              _tableBodyCell(row[0], isBold: true),
              _tableBodyCell(row[1], isHighlight: true),
              _tableBodyCell(row[2]),
              _tableBodyCell(row[3]),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: widget.theme.getMutedColor(context)),
        textAlign: text == 'Bank' ? TextAlign.left : TextAlign.right,
      ),
    );
  }

  Widget _tableBodyCell(String text, {bool isBold = false, bool isHighlight = false}) {
    Color txtCol = widget.theme.getTextColor(context);
    if (isHighlight) {
      txtCol = const Color(0xFF046A38);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 10.5,
          weight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w600,
          color: txtCol,
        ),
        textAlign: isBold ? TextAlign.left : TextAlign.right,
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0B1F48) : Colors.transparent,
            border: Border.all(color: active ? const Color(0xFF0B1F48) : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: active ? Colors.white : widget.theme.getMutedColor(context),
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
      ],
    );
  }

  Widget _buildResultGridItem(String label, String value, String sub, {bool isWarn = false, bool isOk = false}) {
    Color valColor = Colors.white;
    if (isWarn) {
      valColor = const Color(0xFFFCA5A5);
    } else if (isOk) {
      valColor = const Color(0xFF86EFAC);
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

  Widget _buildRuleItem(String emoji, String title, String desc, String badgeText) {
    final theme = widget.theme;
    Color badgeBg = const Color(0xFFEFF6FF);
    Color badgeTxt = const Color(0xFF1D4ED8);
    if (badgeText == 'Restriction') {
      badgeBg = const Color(0xFFFEF2F2);
      badgeTxt = const Color(0xFFB91C1C);
    } else if (badgeText == 'USD 1M Cap' || badgeText == 'CA Required') {
      badgeBg = const Color(0xFFFFF3E0);
      badgeTxt = const Color(0xFFE05A00);
    } else if (badgeText == 'No Limit' || badgeText == 'Tax-Free India') {
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
