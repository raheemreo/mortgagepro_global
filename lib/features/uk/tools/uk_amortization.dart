// lib/features/uk/tools/uk_amortization.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKAmortization extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKAmortization({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKAmortization> createState() => _UKAmortizationState();
}

class _UKAmortizationState extends ConsumerState<UKAmortization> {
  final _loanController = TextEditingController(text: '250000');
  final _termController = TextEditingController(text: '25');
  final _rateController = TextEditingController(text: '4.75');
  final _extraController = TextEditingController(text: '0');

  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  String _viewMode = 'year'; // year, month

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanController.text = (inputs['loan'] ?? 250000.0).toStringAsFixed(0);
      _termController.text = (inputs['term'] ?? 25.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _rateController.text = (inputs['rate'] ?? 4.75).toString();
      _extraController.text = (inputs['extra'] ?? 0.0).toStringAsFixed(0);
      _calculate();
    }
  }

  @override
  void dispose() {
    _loanController.dispose();
    _termController.dispose();
    _rateController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c, double defaultVal) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};

    final loan = double.tryParse(_loanController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (loan <= 0) errors['loan'] = 'Enter valid mortgage amount';

    final term = double.tryParse(_termController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (term <= 0 || term > 50) errors['term'] = 'Enter term (1 - 50 years)';

    final rate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (rate <= 0 || rate > 25) errors['rate'] = 'Enter interest rate (0.1% - 25%)';

    final extra = double.tryParse(_extraController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (extra < 0) errors['extra'] = 'Enter valid extra payment';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_loanController] = loan;
      _calcSnapshot[_termController] = term;
      _calcSnapshot[_rateController] = rate;
      _calcSnapshot[_extraController] = extra;
      _showResults = true;
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

  void _resetInputs() {
    setState(() {
      _loanController.text = '250000';
      _termController.text = '25';
      _rateController.text = '4.75';
      _extraController.text = '0';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final double loanVal = _val(_loanController, 250000);
    final double termVal = _val(_termController, 25);
    final double rateVal = _val(_rateController, 4.75);
    final double extraVal = _val(_extraController, 0);

    final rMo = rateVal / 100 / 12;
    final totalMonths = (termVal * 12).toInt();
    final basePmt = _pmt(rMo, totalMonths.toDouble(), loanVal);
    final totalPmt = basePmt + extraVal;

    // Generate schedule
    final List<Map<String, dynamic>> yearlyData = [];
    final List<Map<String, dynamic>> monthlyData = [];

    double bal = loanVal;
    double totalInt = 0;
    double totalPrin = 0;
    int? halfwayYr;
    int? extraEndYr;

    Map<String, dynamic>? ms75;
    Map<String, dynamic>? ms50;
    Map<String, dynamic>? ms25;
    Map<String, dynamic>? ms10;

    for (int mo = 1; mo <= totalMonths && bal > 0.01; mo++) {
      final intPaid = bal * rMo;
      double prinPaid = totalPmt - intPaid;
      if (prinPaid > bal) prinPaid = bal;
      bal -= prinPaid;
      totalInt += intPaid;
      totalPrin += prinPaid;

      final yr = (mo / 12).ceil();
      if (yearlyData.length < yr) {
        yearlyData.add({
          'yr': yr,
          'payment': 0.0,
          'principal': 0.0,
          'interest': 0.0,
          'balance': 0.0,
        });
      }

      yearlyData[yr - 1]['payment'] = (yearlyData[yr - 1]['payment'] as double) + totalPmt;
      yearlyData[yr - 1]['principal'] = (yearlyData[yr - 1]['principal'] as double) + prinPaid;
      yearlyData[yr - 1]['interest'] = (yearlyData[yr - 1]['interest'] as double) + intPaid;
      yearlyData[yr - 1]['balance'] = bal;

      monthlyData.add({
        'mo': mo,
        'payment': totalPmt,
        'principal': prinPaid,
        'interest': intPaid,
        'balance': bal,
      });

      if (halfwayYr == null && bal <= loanVal / 2) halfwayYr = yr;
      if (extraVal > 0 && extraEndYr == null && bal <= 0.01) extraEndYr = yr;

      if (ms75 == null && bal <= loanVal * 0.75) ms75 = {'yr': yr, 'val': bal};
      if (ms50 == null && bal <= loanVal * 0.5) ms50 = {'yr': yr, 'val': bal};
      if (ms25 == null && bal <= loanVal * 0.25) ms25 = {'yr': yr, 'val': bal};
      if (ms10 == null && bal <= loanVal * 0.1) ms10 = {'yr': yr, 'val': bal};
    }

    final totalRepaid = totalPrin + totalInt;
    final intRatio = totalRepaid > 0 ? (totalInt / totalRepaid * 100) : 0.0;
    final actualTermYrs = yearlyData.length;
    final termSavedYrs = extraVal > 0 ? (termVal - actualTermYrs).clamp(0.0, termVal) : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
    final fixed5yr = ukRates?.fixed5yr.value ?? 4.35;
    final isLive   = ukRates?.isLive == true;

    final isDirty = _showResults && (
      (double.tryParse(_loanController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_loanController] ?? 0.0) ||
      (double.tryParse(_termController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_termController] ?? 0.0) ||
      (double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_rateController] ?? 0.0) ||
      (double.tryParse(_extraController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_extraController] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            children: [
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', 'Official Rate', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('2-Yr Fixed', '${fixed2yr.toStringAsFixed(2)}%', 'Typical fixed', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('5-Yr Fixed', '${fixed5yr.toStringAsFixed(2)}%', 'Longer term', textThemeColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MORTGAGE DETAILS',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w700,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: widget.theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Mortgage inputs card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(label: 'Mortgage Amount (£)', controller: _loanController, errorText: _errors['loan']),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Term (Years)', controller: _termController, errorText: _errors['term'])),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Interest Rate (%)', controller: _rateController, errorText: _errors['rate'])),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(label: 'Monthly Extra Payment (£) (Optional)', controller: _extraController, errorText: _errors['extra']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _calculate,
                  child: Text(
                    'Calculate Schedule',
                    style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate Schedule to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        extraVal > 0 ? 'MONTHLY PAYMENT WITH OVERPAYMENT' : 'ESTIMATED MONTHLY PAYMENT',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormatter.format(totalPmt, symbol: '£').split('.').first,
                            style: AppTextStyles.dmSans(
                              size: 34,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFFD700),
                            ).copyWith(fontFamily: 'Georgia'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final calc = SavedCalc.create(
                                country: 'UK',
                                calcType: 'Amortization',
                                inputs: {
                                  'loan': loanVal,
                                  'term': termVal,
                                  'rate': rateVal,
                                  'extra': extraVal,
                                },
                                results: {
                                  'Base Pmt': basePmt,
                                  'Total Pmt': totalPmt,
                                  'Total Interest': totalInt,
                                  'Years Saved': termSavedYrs,
                                },
                                label: '${CurrencyFormatter.compact(loanVal, symbol: '£')} over ${termVal.toInt()}yrs @ ${rateVal.toStringAsFixed(2)}%',
                                currencyCode: 'GBP',
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              await ref.read(savedProvider.notifier).save(calc);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Amortization schedule saved'),
                                  backgroundColor: Color(0xFF0D9488),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.save, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Save', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (extraVal > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Saves ${termSavedYrs.toStringAsFixed(1)} years off mortgage term · Paid off in $actualTermYrs years',
                          style: AppTextStyles.dmSans(size: 11, color: const Color(0xFF90EE90)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                ResultPanel(
                  primaryColor: widget.theme.primaryColor,
                  rows: [
                    ResultRow(label: 'Total Paid', value: totalRepaid, currencyCode: 'GBP'),
                    ResultRow(label: 'Total Interest', value: totalInt, currencyCode: 'GBP'),
                    ResultRow(label: 'Interest Ratio', value: intRatio / 100, isPercent: true, isHighlighted: true),
                    if (extraVal > 0) ResultRow(label: 'Years Saved', value: termSavedYrs, isPercent: false),
                  ],
                ),
                const SizedBox(height: 16),

                // Milestone timelines
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mortgage Milestones 🏁',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 12),
                      _milestoneItem('75% Balance Left', ms75 != null ? 'Year ${ms75['yr']}' : '—', isDark),
                      const Divider(height: 16, thickness: 0.5),
                      _milestoneItem('Halfway Paid (50% left)', halfwayYr != null ? 'Year $halfwayYr' : '—', isDark),
                      const Divider(height: 16, thickness: 0.5),
                      _milestoneItem('25% Balance Left', ms25 != null ? 'Year ${ms25['yr']}' : '—', isDark),
                      const Divider(height: 16, thickness: 0.5),
                      _milestoneItem('Fully Paid Off (10% left → 0)', ms10 != null ? 'Year ${ms10['yr']}' : '—', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chart Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amortization Balance Over Time',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: AmortizationChartPainter(
                            yearlyData: yearlyData,
                            loan: loanVal,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(color: isDark ? Colors.white : const Color(0xFF0D0D2B), label: 'Balance'),
                          const SizedBox(width: 14),
                          _legendDot(color: const Color(0xFF059669), label: 'Principal'),
                          const SizedBox(width: 14),
                          _legendDot(color: const Color(0xFFC8102E), label: 'Interest'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Table View Toggles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AMORTIZATION SCHEDULE',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: widget.theme.getMutedColor(context),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Row(
                      children: [
                        _tabTextButton(label: 'Yearly', active: _viewMode == 'year', onTap: () => setState(() => _viewMode = 'year')),
                        const SizedBox(width: 8),
                        _tabTextButton(label: 'Monthly', active: _viewMode == 'month', onTap: () => setState(() => _viewMode = 'month')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Schedule list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _viewMode == 'year' ? yearlyData.length : monthlyData.length.clamp(0, 120), // Cap monthly at 10 yrs to prevent lag
                  itemBuilder: (context, index) {
                    if (_viewMode == 'year') {
                      final d = yearlyData[index];
                      return _tableRow(
                        title: 'Year ${d['yr']}',
                        principal: d['principal'] as double,
                        interest: d['interest'] as double,
                        balance: d['balance'] as double,
                        isDark: isDark,
                      );
                    } else {
                      final d = monthlyData[index];
                      return _tableRow(
                        title: 'Month ${d['mo']}',
                        principal: d['principal'] as double,
                        interest: d['interest'] as double,
                        balance: d['balance'] as double,
                        isDark: isDark,
                      );
                    }
                  },
                ),
                if (_viewMode == 'month' && monthlyData.length > 120)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Showing first 120 months. Switch to Yearly view for full term.',
                        style: AppTextStyles.dmSans(size: 10.5, color: widget.theme.getMutedColor(context)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _milestoneItem(String title, String val, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w600, color: widget.theme.getTextColor(context))),
        Text(
          val,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: isDark ? const Color(0xFF93C5FD) : widget.theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _tabTextButton({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyles.dmSans(
          size: 11,
          weight: FontWeight.bold,
          color: active ? widget.theme.primaryColor : Colors.grey,
        ),
      ),
    );
  }

  Widget _tableRow({required String title, required double principal, required double interest, required double balance, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prin: ${CurrencyFormatter.format(principal, symbol: '£').split('.').first}',
                  style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF059669), weight: FontWeight.w700),
                ),
                Text(
                  'Int: ${CurrencyFormatter.format(interest, symbol: '£').split('.').first}',
                  style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFFC8102E), weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(balance, symbol: '£').split('.').first,
                    style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                  ),
                  Text(
                    'Balance',
                    style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _inputField({required String label, required TextEditingController controller, String? errorText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            setState(() {});
          },
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            enabledBorder: errorText != null ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ) : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class AmortizationChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> yearlyData;
  final double loan;
  final bool isDark;

  AmortizationChartPainter({
    required this.yearlyData,
    required this.loan,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (yearlyData.isEmpty) return;

    const double padLeft = 40.0;
    const double padBottom = 20.0;
    const double padTop = 10.0;
    const double padRight = 10.0;

    final cw = size.width - padLeft - padRight;
    final ch = size.height - padTop - padBottom;

    final maxVal = loan;

    // Draw gridlines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFF0F0F5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padTop + ch - (ch * i / 4);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    // Draw Balance Line (Outstanding balance)
    final balPath = Path();
    final prinPath = Path();
    final intPath = Path();

    double cumPrin = 0;
    double cumInt = 0;

    for (int i = 0; i < yearlyData.length; i++) {
      final d = yearlyData[i];
      final double x = padLeft + (i / (yearlyData.length - 1)) * cw;

      final double balVal = d['balance'] as double;
      final double yBal = padTop + ch * (1 - balVal / maxVal);
      if (i == 0) {
        balPath.moveTo(x, yBal);
      } else {
        balPath.lineTo(x, yBal);
      }

      cumPrin += d['principal'] as double;
      final double yPrin = padTop + ch * (1 - cumPrin / maxVal);
      if (i == 0) {
        prinPath.moveTo(x, yPrin);
      } else {
        prinPath.lineTo(x, yPrin);
      }

      cumInt += d['interest'] as double;
      final double yInt = padTop + ch * (1 - math.min(cumInt, maxVal) / maxVal);
      if (i == 0) {
        intPath.moveTo(x, yInt);
      } else {
        intPath.lineTo(x, yInt);
      }
    }

    // Paint Balance Line
    canvas.drawPath(
      balPath,
      Paint()
        ..color = isDark ? Colors.white : const Color(0xFF0D0D2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Paint Principal Line
    canvas.drawPath(
      prinPath,
      Paint()
        ..color = const Color(0xFF059669)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Paint Interest Line (dashed-like)
    canvas.drawPath(
      intPath,
      Paint()
        ..color = const Color(0xFFC8102E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant AmortizationChartPainter oldDelegate) {
    return oldDelegate.yearlyData != yearlyData || oldDelegate.loan != loan || oldDelegate.isDark != isDark;
  }
}
