// lib/features/usa/tools/usa_home_equity_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAHomeEquityLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAHomeEquityLoanCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAHomeEquityLoanCalc> createState() => _USAHomeEquityLoanCalcState();
}

class _USAHomeEquityLoanCalcState extends ConsumerState<USAHomeEquityLoanCalc> {
  final _homeValController = TextEditingController(text: '550000');
  final _mortBalController = TextEditingController(text: '310000');
  final _loanAmtController = TextEditingController(text: '60000');
  final _rateController = TextEditingController(text: '8.36');

  int _termYears = 10;
  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final controllers = [
      _homeValController,
      _mortBalController,
      _loanAmtController,
      _rateController,
    ];
    for (final c in controllers) {
      c.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _homeValController.dispose();
    _mortBalController.dispose();
    _loanAmtController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  double _calcPI(double loan, double rate, int yrs) {
    final mo = rate / 1200;
    final n = yrs * 12;
    return mo == 0 ? loan / n : loan * mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1);
  }

  void _resetInputs() {
    setState(() {
      _homeValController.text = '550000';
      _mortBalController.text = '310000';
      _loanAmtController.text = '60000';
      _rateController.text = '8.36';
      _termYears = 10;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _calculate() async {
    final hv = _val(_homeValController);
    final mb = _val(_mortBalController);
    final loan = _val(_loanAmtController);

    if (mb >= hv) {
      _showError('⚠️ Mortgage balance must be less than home value');
      return;
    }
    if (loan <= 0) {
      _showError('⚠️ Loan amount must be greater than 0');
      return;
    }

    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveCalculation() async {
    final hv = _val(_homeValController);
    final mb = _val(_mortBalController);
    final loan = _val(_loanAmtController);
    final rate = _val(_rateController);

    final monthly = _calcPI(loan, rate, _termYears);
    final totalInt = monthly * _termYears * 12 - loan;
    final cltv = hv > 0 ? ((mb + loan) / hv * 100) : 0.0;

    final labelCtrl = TextEditingController(text: 'Home Equity Loan');
    final confirmed = await showDialog<bool>(
      context: context,
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
              'Saving: Loan: ${CurrencyFormatter.compact(loan, symbol: r'$')} · Payment: ${CurrencyFormatter.compact(monthly, symbol: r'$')}/mo · CLTV: ${cltv.toStringAsFixed(1)}%',
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
                hintText: 'Label (e.g. My Home Equity Loan)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Home Equity Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Home Equity Loan',
        inputs: {
          'HomeVal': hv,
          'MortBal': mb,
          'LoanAmt': loan,
          'Rate': rate,
          'TermYears': _termYears.toDouble(),
        },
        results: {
          'MonthlyPayment': monthly,
          'TotalInterest': totalInt,
          'CLTV': cltv,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hv = _val(_homeValController);
    final mb = _val(_mortBalController);
    final loan = _val(_loanAmtController);
    final rate = _val(_rateController);

    final monthly = _calcPI(loan, rate, _termYears);
    final totalInt = monthly * _termYears * 12 - loan;
    final maxAvail = max(0.0, 0.85 * hv - mb);
    final cltv = hv > 0 ? ((mb + loan) / hv * 100) : 0.0;
    final totalRepaid = monthly * _termYears * 12;
    final cltvWarn = cltv > 85;

    // Amortization values projection
    final double mo = rate / 1200;
    double bal = loan;
    final List<Map<String, dynamic>> amortizationList = [];
    for (int yr = 1; yr <= _termYears; yr++) {
      double intYr = 0;
      double prinYr = 0;
      for (int m = 0; m < 12; m++) {
        final double intM = bal * mo;
        final double prinM = monthly - intM;
        intYr += intM;
        prinYr += prinM;
        bal = max(0.0, bal - prinM);
      }
      amortizationList.add({'yr': yr, 'bal': bal, 'prin': prinYr, 'int': intYr});
    }
    final step = max(1, (_termYears / 5).floor());
    final displayAmortization = amortizationList.where((e) {
      final y = e['yr'] as int;
      return y == 1 || y % step == 0 || y == _termYears;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate strip header — Live Prime Rate from FRED
        LightRateStripBanner(items: [
          RateStripItem(label: 'HEL 10yr\n(Prime+~0.5%)', provider: fredPrimeProvider, fallback: 8.36),
          RateStripItem(label: 'HEL 15yr', provider: fredPrimeProvider, fallback: 8.41),
          RateStripItem(label: 'Max CLTV', provider: fredMortgage30Provider, fallback: 85, suffix: '', isGold: true),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 16),

        Text('LOAN DETAILS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildInputField(_homeValController, 'HOME VALUE', r'$')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField(_mortBalController, 'MORTGAGE BALANCE', r'$')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField(_loanAmtController, 'LOAN AMOUNT', r'$')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField(_rateController, 'INTEREST RATE', '', suffix: '%')),
                ],
              ),
              const SizedBox(height: 12),
              Text('LOAN TERM', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [5, 10, 15].map((t) {
                  final isActive = _termYears == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _termYears = t;
                        _markDirty();
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isActive ? const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]) : null,
                          color: isActive ? null : theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isActive ? const Color(0xFF15803D) : theme.getBorderColor(context)),
                        ),
                        alignment: Alignment.center,
                        child: Text('$t yr',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                color: isActive ? Colors.white : theme.getMutedColor(context),
                                weight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15803D), Color(0xFF166534)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _calculate,
                        child: _calculating
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('💵 Calculate Loan', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _resetInputs,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Reset', style: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showResults ? _saveCalculation : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _showResults ? const Color(0xFFD97706) : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('💾 Save',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: _showResults ? Colors.white : theme.getMutedColor(context),
                              weight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
          // Results Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF15803D), Color(0xFF166534)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MONTHLY PAYMENT (FIXED)', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(CurrencyFormatter.format(monthly, symbol: r'$'),
                    style: AppTextStyles.playfair(size: 36, color: Colors.white, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Fixed rate $rate% · $_termYears-year term${cltvWarn ? ' ⚠️ CLTV exceeds 85%' : ''}',
                    style: AppTextStyles.dmSans(size: 10, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroStatItem('Max Available', CurrencyFormatter.format(maxAvail, symbol: r'$')),
                    _buildHeroStatItem('Total Interest', CurrencyFormatter.compact(totalInt, symbol: r'$'), color: const Color(0xFFFCD34D)),
                    _buildHeroStatItem('CLTV Ratio', '${cltv.toStringAsFixed(1)}%${cltvWarn ? ' ⚠️' : ''}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Rows
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Repaid', CurrencyFormatter.format(totalRepaid, symbol: r'$'), 'Principal + interest', theme, context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Effective APR', '$rate%', 'Fixed for full term', theme, context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payoff Progress (Amortization List)
          Text('PAYOFF PROGRESS BY YEAR', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...displayAmortization.map((e) {
                  final y = e['yr'] as int;
                  final p = e['prin'] as double;
                  final i = e['int'] as double;
                  final double scalePrin = p / (p + i);
                  final double scaleInt = i / (p + i);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 38, child: Text('Yr $y', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context), weight: FontWeight.bold))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: SizedBox(
                              height: 7,
                              child: Row(
                                children: [
                                  Expanded(flex: (scalePrin * 100).round(), child: Container(color: const Color(0xFF15803D))),
                                  Expanded(flex: (scaleInt * 100).round(), child: Container(color: const Color(0xFFD97706))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(CurrencyFormatter.format(e['bal'] as double, symbol: r'$'), style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Principal', const Color(0xFF15803D), theme, context),
                    const SizedBox(width: 16),
                    _buildLegendItem('Interest', const Color(0xFFD97706), theme, context),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment composition donut
          Text('PAYMENT COMPOSITION', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 90,
                  width: 90,
                  child: CustomPaint(
                    painter: _PayoffDonutPainter2(
                      principal: loan,
                      interest: totalInt,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDonutLegendItem('Principal', CurrencyFormatter.format(loan, symbol: r'$'), const Color(0xFF15803D), theme, context),
                      const SizedBox(height: 6),
                      _buildDonutLegendItem('Interest', CurrencyFormatter.format(totalInt, symbol: r'$'), const Color(0xFFD97706), theme, context),
                      const SizedBox(height: 6),
                      _buildDonutLegendItem('Total Repaid', CurrencyFormatter.format(totalRepaid, symbol: r'$'), theme.getTextColor(context), theme, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Common Uses Grid
        Text('COMMON USES FOR HOME EQUITY LOANS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            _buildUseCard('🔨', 'Home Rehab', 'Renovations', theme, context),
            _buildUseCard('🎓', 'Education', 'College Fees', theme, context),
            _buildUseCard('💳', 'Consolidate', 'Pay off cards', theme, context),
            _buildUseCard('🏥', 'Medical Bills', 'Emergency costs', theme, context),
            _buildUseCard('🚘', 'Vehicle purchase', 'Low fixed rate', theme, context),
            _buildUseCard('🏖️', 'Investment', 'Property down pmt', theme, context),
          ],
        ),
        const SizedBox(height: 16),

        // Facts List
        Text('HOME EQUITY LOAN VS HELOC', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildFactCard('🔒', 'Fixed Rate Security', 'Home equity loan rate remains locked for the entire term · no payment surprises', theme, context),
        _buildFactCard('💰', 'Lump Sum Disbursement', 'Receive the full cash amount upfront · best for large, immediate projects', theme, context),
        _buildFactCard('🏛️', 'Possible Tax Deduction', 'Interest is deductible if proceeds are directly used to buy, build, or substantially improve the home securing the loan', theme, context),
      ],
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, String prefix, {String suffix = ''}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              if (prefix.isNotEmpty)
                Text(prefix, style: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context))),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(_markDirty),
                  style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
              if (suffix.isNotEmpty)
                Text(suffix, style: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.playfair(size: 14, color: color ?? Colors.white, weight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, CountryTheme theme, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String sub, CountryTheme theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(String label, String value, Color color, CountryTheme theme, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getTextColor(context), weight: FontWeight.w600))),
        Text(value, style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUseCard(String icon, String title, String subtitle, CountryTheme theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.playfair(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFactCard(String icon, String title, String subtitle, CountryTheme theme, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoffDonutPainter2 extends CustomPainter {
  final double principal;
  final double interest;
  final bool isDark;

  _PayoffDonutPainter2({
    required this.principal,
    required this.interest,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final total = principal + interest;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF2F8)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    final double prinPct = principal / total;
    final double intPct = interest / total;

    const double startAngle = -pi / 2;

    final prinPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final intPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi * prinPct,
      false,
      prinPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (2 * pi * prinPct),
      2 * pi * intPct,
      false,
      intPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PayoffDonutPainter2 oldDelegate) {
    return oldDelegate.principal != principal || oldDelegate.interest != interest || oldDelegate.isDark != isDark;
  }
}


