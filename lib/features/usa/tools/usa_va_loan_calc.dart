import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAVaLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAVaLoanCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAVaLoanCalc> createState() => _USAVaLoanCalcState();
}

class _USAVaLoanCalcState extends ConsumerState<USAVaLoanCalc> {
  final _homePriceController = TextEditingController(text: '450000');
  final _downPmtController = TextEditingController(text: '0');
  final _rateController = TextEditingController(text: '6.25');
  final _propTaxController = TextEditingController(text: '5400');
  final _insuranceController = TextEditingController(text: '1800');

  int _termYears = 30;
  String _serviceType = 'first_active';
  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final controllers = [
      _homePriceController,
      _downPmtController,
      _rateController,
      _propTaxController,
      _insuranceController,
    ];
    for (final controller in controllers) {
      controller.addListener(_markDirty);
    }
    if (widget.savedCalc != null) {
      _loadSavedCalculation(widget.savedCalc!);
    }
  }

  @override
  void dispose() {
    final controllers = [
      _homePriceController,
      _downPmtController,
      _rateController,
      _propTaxController,
      _insuranceController,
    ];
    for (final controller in controllers) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _resetInputs() {
    setState(() {
      _homePriceController.text = '450000';
      _downPmtController.text = '0';
      _rateController.text = '6.25';
      _termYears = 30;
      _serviceType = 'first_active';
      _propTaxController.text = '5400';
      _insuranceController.text = '1800';
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _homePriceController.text = (calc.inputs['HomePrice'] ?? 450000.0).toStringAsFixed(0);
      _downPmtController.text = (calc.inputs['DownPmt'] ?? 0.0).toStringAsFixed(0);
      _rateController.text = (calc.inputs['InterestRate'] ?? 6.25).toStringAsFixed(2);
      _termYears = (calc.inputs['TermYears'] ?? 30.0).toInt();
      _serviceType = calc.inputs['ServiceTypeIndex'] == 0.0 ? 'first_active' :
                     calc.inputs['ServiceTypeIndex'] == 1.0 ? 'subsequent_active' :
                     calc.inputs['ServiceTypeIndex'] == 2.0 ? 'first_reserve' :
                     calc.inputs['ServiceTypeIndex'] == 3.0 ? 'subsequent_reserve' : 'exempt';
      _propTaxController.text = (calc.inputs['PropTax'] ?? 5400.0).toStringAsFixed(0);
      _insuranceController.text = (calc.inputs['HomeInsurance'] ?? 1800.0).toStringAsFixed(0);
      _showResults = true;
      _isCalcDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveCalculation() async {
    final price = _val(_homePriceController);
    final down = _val(_downPmtController);
    final rateAnnual = _val(_rateController) / 100;
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);

    final downPct = price > 0 ? down / price : 0.0;
    double ffRate = 0.0215; // default
    if (_serviceType == 'exempt') {
      ffRate = 0.0;
    } else if (downPct >= 0.10) {
      ffRate = 0.0125;
    } else if (downPct >= 0.05) {
      ffRate = 0.0150;
    } else {
      if (_serviceType == 'first_active') {
        ffRate = 0.0215;
      } else if (_serviceType == 'subsequent_active') {
        ffRate = 0.0330;
      } else if (_serviceType == 'first_reserve') {
        ffRate = 0.0240;
      } else if (_serviceType == 'subsequent_reserve') {
        ffRate = 0.0330;
      }
    }

    final baseLoan = price - down;
    final fundingFee = baseLoan * ffRate;
    final loanAmt = baseLoan + fundingFee;
    final months = _termYears * 12;
    final mr = rateAnnual / 12;
    final pi = mr == 0 ? loanAmt / months : loanAmt * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + taxMonthly + insMonthly;

    final convBaseLoan0 = price;
    final convPMI0 = (price * 0.006) / 12;
    final convPI0 = mr == 0 ? convBaseLoan0 / months : convBaseLoan0 * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
    final convTotal0 = convPI0 + convPMI0 + taxMonthly + insMonthly;
    final mthSavings = convTotal0 - total;

    double serviceTypeIdx = 0.0;
    if (_serviceType == 'subsequent_active') {
      serviceTypeIdx = 1.0;
    } else if (_serviceType == 'first_reserve') {
      serviceTypeIdx = 2.0;
    } else if (_serviceType == 'subsequent_reserve') {
      serviceTypeIdx = 3.0;
    } else if (_serviceType == 'exempt') {
      serviceTypeIdx = 4.0;
    }

    final labelCtrl = TextEditingController(text: 'VA Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_va_loan_calc/save'),
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
              'Saving: VA Monthly Payment: ${CurrencyFormatter.compact(total, symbol: '\$')} · Fee: ${CurrencyFormatter.compact(fundingFee, symbol: '\$')}',
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
                hintText: 'Label (e.g. VA Home Loan)',
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
          : 'VA Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'VA Loan Calculator',
        inputs: {
          'HomePrice': price,
          'DownPmt': down,
          'InterestRate': _val(_rateController),
          'TermYears': _termYears.toDouble(),
          'ServiceTypeIndex': serviceTypeIdx,
          'PropTax': propTaxAnnual,
          'HomeInsurance': insAnnual,
        },
        results: {
          'MonthlyPayment': total,
          'FundingFee': fundingFee,
          'LoanAmount': loanAmt,
          'MonthlySavings': mthSavings,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _runCalculate() {
    setState(() {
      _calculating = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _showResults = true;
          _isCalcDirty = false;
          _calculating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = widget.theme;

    // Fetch values for UI
    final price = _val(_homePriceController);
    final down = _val(_downPmtController);
    final rateAnnual = _val(_rateController) / 100;
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);

    final downPct = price > 0 ? down / price : 0.0;
    double ffRate = 0.0215; // default
    if (_serviceType == 'exempt') {
      ffRate = 0.0;
    } else if (downPct >= 0.10) {
      ffRate = 0.0125;
    } else if (downPct >= 0.05) {
      ffRate = 0.0150;
    } else {
      if (_serviceType == 'first_active') {
        ffRate = 0.0215;
      } else if (_serviceType == 'subsequent_active') {
        ffRate = 0.0330;
      } else if (_serviceType == 'first_reserve') {
        ffRate = 0.0240;
      } else if (_serviceType == 'subsequent_reserve') {
        ffRate = 0.0330;
      }
    }

    final baseLoan = price - down;
    final fundingFee = baseLoan * ffRate;
    final loanAmt = baseLoan + fundingFee;
    final months = _termYears * 12;
    final mr = rateAnnual / 12;
    final pi = mr == 0 ? loanAmt / months : loanAmt * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + taxMonthly + insMonthly;

    // Conventional comparison
    final convLoanAmt = baseLoan;
    final ltv = price > 0 ? (convLoanAmt / price * 100) : 0;
    final pmiMonthly = ltv > 80 ? (convLoanAmt * 0.006) / 12 : 0.0;
    final convDown = price * 0.20;

    // Conventional 0% down comparison
    final convPI0 = mr == 0 ? price / months : price * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
    final convPMI0 = (price * 0.006) / 12;
    final convTotal0 = convPI0 + convPMI0 + taxMonthly + insMonthly;
    final mthSavings = convTotal0 - total;
    final lifetimePMISavings = pmiMonthly * months;

    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'VA Loan Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip — Live FRED data
        LightRateStripBanner(items: [
          RateStripItem(label: 'VA Rate\n(30-Yr)', provider: fredMortgage30Provider, fallback: 6.25),
          RateStripItem(label: 'Min. Down', provider: fredMortgage30Provider, fallback: 0, suffix: '', isGold: true),
          RateStripItem(label: 'No PMI', provider: fredMortgage30Provider, fallback: 0, suffix: ''),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 12),

        // Veterans savings banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF4C1D95)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🎖️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$0 Down · No PMI · Competitive Rates',
                      style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.w800, color: const Color(0xFFFCD34D)).copyWith(fontFamily: 'Georgia'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'VA loans saved veterans avg \$3,500/yr vs conventional in 2024',
                      style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('Loan Details', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Inputs Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildInputField('Home Price (\$)', _homePriceController, hint: 'No VA limit (2020+)')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField('Down Payment (\$)', _downPmtController, hint: '0% down available')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInputField('Interest Rate (%)', _rateController, hint: 'Jun 2025 VA avg')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField<int>(
                      label: 'Loan Term',
                      value: _termYears,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 Years')),
                        DropdownMenuItem(value: 20, child: Text('20 Years')),
                        DropdownMenuItem(value: 15, child: Text('15 Years')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _termYears = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDropdownField<String>(
                label: 'Service Type',
                value: _serviceType,
                items: const [
                  DropdownMenuItem(value: 'first_active', child: Text('Active Duty (1st Use)')),
                  DropdownMenuItem(value: 'subsequent_active', child: Text('Active Duty (Subsequent)')),
                  DropdownMenuItem(value: 'first_reserve', child: Text('Reserves/Guard (1st Use)')),
                  DropdownMenuItem(value: 'subsequent_reserve', child: Text('Reserves/Guard (Sub.)')),
                  DropdownMenuItem(value: 'exempt', child: Text('Exempt (10%+ Disability)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _serviceType = val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInputField('Property Tax (\$/yr)', _propTaxController, hint: '~1.1% avg U.S.')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField('Home Insurance (\$/yr)', _insuranceController, hint: 'National avg ~\$1.8K')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculate / Save Button row
        Row(
          children: [
            Expanded(
              flex: 7,
              child: GestureDetector(
                onTap: _runCalculate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B3F72).withValues(alpha: _isCalcDirty ? 0.40 : 0.20),
                        blurRadius: _isCalcDirty ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _calculating ? '⏳ Calculating…' : '🎖️ Calculate VA Monthly Payment',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '💾 Save',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
          // Monthly Payment Breakdown (Hero)
          _buildSectionHeader('Monthly Payment Breakdown', onReset: null),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL MONTHLY PAYMENT (PITI, NO PMI)',
                  style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: Colors.white54, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(total, symbol: '').split('.').first,
                      style: AppTextStyles.dmSans(size: 36, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                    ),
                    Text(
                      ' /mo',
                      style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w700, color: const Color(0xFFFCD34D)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Loan: ${CurrencyFormatter.format(loanAmt)} · ${CurrencyFormatter.format(down)} down · Funding Fee: ${CurrencyFormatter.format(fundingFee)} financed',
                  style: AppTextStyles.dmSans(size: 10, color: Colors.white54),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildHeroStatBox('Fund. Fee', CurrencyFormatter.format(fundingFee))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildHeroStatBox('PMI Saved', '${CurrencyFormatter.format(pmiMonthly)}/mo')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildHeroStatBox('Lifetime PMI', CurrencyFormatter.format(lifetimePMISavings))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // VA vs Conventional comparison card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              border: Border.all(color: theme.getBorderColor(context)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚔️ VA vs. Conventional Comparison',
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('🎖️ VA LOAN', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: const Color(0xFF1D4ED8))),
                            const SizedBox(height: 4),
                            Text(CurrencyFormatter.format(total).split('.').first, style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w800, color: const Color(0xFF1D4ED8)).copyWith(fontFamily: 'Georgia')),
                            Text('per month', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          border: Border.all(color: theme.getBorderColor(context)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('🏦 CONVENTIONAL', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: theme.getMutedColor(context))),
                            const SizedBox(height: 4),
                            Text(CurrencyFormatter.format(convTotal0).split('.').first, style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia')),
                            Text('per month', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildComparisonDetailRow('Down Payment', CurrencyFormatter.format(down), '0% Down (Conv 3%+)'),
                _buildComparisonDetailRow('PMI / Funding Fee', fundingFee > 0 ? '${CurrencyFormatter.format(fundingFee)} fee' : 'Exempt', '${CurrencyFormatter.format(convPMI0)}/mo'),
                const SizedBox(height: 8),
                Text(
                  'VA saves: ${CurrencyFormatter.format(mthSavings.abs())}/mo vs. 0%-down conv.',
                  style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment breakdown grid
          _buildSectionHeader('Payment Details', onReset: null),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.5,
            children: [
              _buildBreakdownGridCard('💵', 'P&I Payment', CurrencyFormatter.format(pi), 'Base mortgage'),
              _buildBreakdownGridCard('✅', 'PMI / MIP', '\$0', 'VA benefit — none!', customValueColor: Colors.green),
              _buildBreakdownGridCard('🏛️', 'Property Tax', CurrencyFormatter.format(taxMonthly), 'Monthly escrow'),
              _buildBreakdownGridCard('🔥', 'Home Insurance', CurrencyFormatter.format(insMonthly), 'Monthly escrow'),
              _buildBreakdownGridCard('⚡', 'VA Funding Fee', CurrencyFormatter.format(fundingFee), 'Financed into loan'),
              _buildBreakdownGridCard('💰', 'PMI Savings vs Conv.', '${CurrencyFormatter.format(pmiMonthly)}/mo', 'Approx. PMI avoided'),
            ],
          ),
          const SizedBox(height: 20),

          // Lifetime benefit card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF4C1D95)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎖️ Lifetime VA Benefit Summary',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFFFCD34D)).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBenefitVisualBox('Down Saved', CurrencyFormatter.format(convDown), isGreen: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBenefitVisualBox('PMI Avoided (30yr)', CurrencyFormatter.format(lifetimePMISavings), isGreen: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildBenefitVisualBox('Funding Fee Paid', CurrencyFormatter.format(fundingFee), isGreen: false)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // VA Funding Fee rates card
        _buildSectionHeader('2025 VA Funding Fee Schedule', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border.all(color: const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎖️ VA Funding Fee Rates (2025)',
                style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF1E3A5F)).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 10),
              _buildFfRow('Active Duty – 1st Use (0–4.9% down)', '2.15%'),
              _buildFfRow('Active Duty – Subsequent Use', '3.30%'),
              _buildFfRow('Reserves/Guard – 1st Use', '2.40%'),
              _buildFfRow('Reserves/Guard – Subsequent', '3.30%'),
              _buildFfRow('5% or more down', '1.50%'),
              _buildFfRow('10% or more down', '1.25%'),
              _buildFfRow('10%+ Service-Connected Disability', 'EXEMPT (\$0)', customColor: Colors.green),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF1E40AF), weight: FontWeight.w700),
                    children: [
                      const TextSpan(text: 'Your rate: '),
                      TextSpan(
                        text: _serviceType == 'exempt' ? 'Exempt (0%)' :
                              downPct >= 0.10 ? '1.25% (10%+ down)' :
                              downPct >= 0.05 ? '1.50% (5–9.9% down)' :
                              _serviceType == 'first_active' ? '2.15% (Active 1st)' :
                              _serviceType == 'subsequent_active' ? '3.30% (Active Sub.)' :
                              _serviceType == 'first_reserve' ? '2.40% (Reserve 1st)' : '3.30% (Reserve Sub.)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Eligibility
        _buildSectionHeader('VA Eligibility Requirements', onReset: null),
        const SizedBox(height: 8),
        _buildEligibilityCard(),
        const SizedBox(height: 20),

        // Saved list
        if (savedCalcs.isNotEmpty) ...[
          _buildSectionHeader(
            'Saved Calculations',
            onReset: () async {
              final messenger = ScaffoldMessenger.of(context);
              for (final calc in savedCalcs) {
                await ref.read(savedProvider.notifier).delete(calc.id);
              }
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('All saved calculations cleared!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            resetLabel: 'Clear All',
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  border: Border.all(color: theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _loadSavedCalculation(calc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc.label,
                              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Price: ${CurrencyFormatter.compact(calc.inputs['HomePrice'] ?? 0.0, symbol: '\$')} · Down: ${CurrencyFormatter.compact(calc.inputs['DownPmt'] ?? 0.0, symbol: '\$')} · ${calc.inputs['TermYears']?.toInt() ?? 30}yr',
                              style: AppTextStyles.dmSans(size: 9.0, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.compact(calc.results['MonthlyPayment'] ?? 0.0, symbol: '\$'),
                      style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.primaryColor).copyWith(fontFamily: 'Georgia'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: theme.getMutedColor(context).withValues(alpha: 0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).delete(calc.id);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Removed saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],

        // Resources
        _buildSectionHeader('VA Loan Resources', onReset: null),
        const SizedBox(height: 8),
        _buildResourcesList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String resetLabel = 'Reset'}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w800,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1,
          ),
        ),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              '$resetLabel →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? prefix,
    String? hint,
  }) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              color: theme.getMutedColor(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              border: Border.all(color: theme.getBorderColor(context), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (prefix != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      prefix,
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w800,
                        color: theme.getMutedColor(context),
                      ),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.dmSans(
                      size: 15,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                hint,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: theme.getMutedColor(context).withValues(alpha: 0.75),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              color: theme.getMutedColor(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              border: Border.all(color: theme.getBorderColor(context), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                style: AppTextStyles.dmSans(
                  size: 14,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
                dropdownColor: theme.getCardColor(context),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonDetailRow(String key, String vaValue, String convValue) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(key, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.w600))),
          Text(vaValue, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: const Color(0xFF1D4ED8))),
          const SizedBox(width: 20),
          Text(convValue, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: theme.getTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildBreakdownGridCard(String emoji, String label, String value, String sub, {Color? customValueColor}) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: theme.getMutedColor(context), letterSpacing: 0.4),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 16,
              weight: FontWeight.w800,
              color: customValueColor ?? theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildBenefitVisualBox(String label, String value, {required bool isGreen}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.w600, letterSpacing: 0.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: isGreen ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
            ).copyWith(fontFamily: 'Georgia'),
          ),
        ],
      ),
    );
  }

  Widget _buildFfRow(String label, String value, {Color? customColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1F93C5FD))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: customColor ?? const Color(0xFF1D4ED8))),
        ],
      ),
    );
  }

  Widget _buildEligibilityCard() {
    final theme = widget.theme;
    final eligibility = [
      ('Active Duty Service', '✅ 90 consecutive days wartime / 181 peacetime', Colors.green),
      ('National Guard/Reserve', '✅ 6 yrs service or 90 days active', Colors.green),
      ('Certificate of Eligibility', '⚡ Required – Apply at VA.gov', const Color(0xFFD97706)),
      ('Min. Credit Score (VA)', '✅ No VA min · Lenders ~620', Colors.green),
      ('Max DTI', '✅ 41% guideline (residual income)', Colors.green),
      ('Occupancy Requirement', '✅ Primary residence only', Colors.green),
    ];
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: eligibility.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.$1, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia')),
                Text(e.$2, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: e.$3)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResourcesList() {
    final theme = widget.theme;
    final resources = [
      ('Certificate of Eligibility (COE)', 'Apply online at VA.gov · eBenefits · Lender assist', '📋'),
      ('VA Entitlement & Loan Limits', 'Full entitlement: no limit in 2025 · Bonus entitlement', '🏠'),
      ('Surviving Spouse Benefits', 'Unmarried surviving spouses may qualify for VA loan', '🪖'),
      ('VA IRRRL (Streamline Refi)', 'Interest Rate Reduction Refinance Loan – low cost', '🔄'),
    ];
    return Column(
      children: resources.asMap().entries.map((entry) {
        final idx = entry.key;
        final r = entry.value;
        String route = '';
        if (idx == 0) {
          route = '/usa/va-coe';
        } else if (idx == 1) {
          route = '/usa/va-entitlement-limits';
        } else if (idx == 2) {
          route = '/usa/va-surviving-spouse';
        } else if (idx == 3) {
          route = '/usa/va-irrrl';
        }

        return GestureDetector(
          onTap: () {
            if (route.isNotEmpty) {
              context.push(route);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              border: Border.all(color: theme.getBorderColor(context)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(r.$3, style: const TextStyle(fontSize: 17)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.$1,
                        style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.$2,
                        style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
