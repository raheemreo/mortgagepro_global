// lib/features/canada/tools/ca_renewal_planner.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CARenewalPlanner extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CARenewalPlanner({super.key, required this.theme});

  @override
  ConsumerState<CARenewalPlanner> createState() => _CARenewalPlannerState();
}

class _CARenewalPlannerState extends ConsumerState<CARenewalPlanner> {
  final _balanceController = TextEditingController(text: '480000');
  final _currentRateController = TextEditingController(text: '2.39');
  final _remAmortController = TextEditingController(text: '20');
  final _newRateController = TextEditingController(text: '4.99');
  final _bestRateController = TextEditingController(text: '4.64');
  final _penaltyController = TextEditingController(text: '0');

  @override
  void dispose() {
    _balanceController.dispose();
    _currentRateController.dispose();
    _remAmortController.dispose();
    _newRateController.dispose();
    _bestRateController.dispose();
    _penaltyController.dispose();
    super.dispose();
  }

  double _pmt(double loan, double annualRate, double years) {
    if (loan <= 0 || annualRate <= 0 || years <= 0) return 0;
    final ea = dm.pow(1 + annualRate / 200, 2) - 1;
    final r = ea / 12;
    final n = years * 12;
    if (r == 0) return loan / n;
    return loan * r / (1 - dm.pow(1 + r, -n));
  }

  double _cumulativeInterest(double loan, double annualRate, double years, int months) {
    final ea = dm.pow(1 + annualRate / 200, 2) - 1;
    final r = ea / 12;
    final n = years * 12;
    final p = _pmt(loan, annualRate, years);
    double bal = loan;
    double totalInt = 0;
    for (int i = 0; i < dm.min(months, n.round()); i++) {
      final ip = bal * r;
      totalInt += ip;
      bal -= dm.min(p - ip, bal);
    }
    return totalInt;
  }

  void _saveCalculation() async {
    final double bal = double.tryParse(_balanceController.text) ?? 480000;
    final double curRate = double.tryParse(_currentRateController.text) ?? 2.39;
    final double remAmort = double.tryParse(_remAmortController.text) ?? 20;
    final double newRate = double.tryParse(_newRateController.text) ?? 4.99;
    final double bestRate = double.tryParse(_bestRateController.text) ?? 4.64;
    final double penaltyVal = double.tryParse(_penaltyController.text) ?? 0;

    final double oldPmtVal = _pmt(bal, curRate, remAmort);
    final double newPmtVal = _pmt(bal, newRate, remAmort);
    final double bestPmtVal = _pmt(bal, bestRate, remAmort);
    final double diff = newPmtVal - oldPmtVal;

    final labelCtrl = TextEditingController(text: 'Renewal Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_renewal_planner/save'),
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
              'Saving: Change ${CurrencyFormatter.compact(diff, symbol: 'CA\$')}/mo · Balance: ${CurrencyFormatter.compact(bal, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. Scotiabank Offer)',
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
          : 'Renewal Planner';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Renewal Planner',
        inputs: {
          'Balance': bal,
          'CurRate': curRate,
          'Amort': remAmort,
          'NewRate': newRate,
          'BestRate': bestRate,
          'Penalty': penaltyVal,
        },
        results: {
          'OldPmt': oldPmtVal,
          'NewPmt': newPmtVal,
          'BestPmt': bestPmtVal,
          'Diff': diff,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Renewal scenario saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _ratesInitialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Watch rates provider to initialize default rates
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    if (ratesAsync.hasValue && !_ratesInitialized) {
      final defaultRate = ratesAsync.value!.rate5yrFixed;
      _newRateController.text = defaultRate.toStringAsFixed(2);
      _bestRateController.text = (defaultRate - 0.35).toStringAsFixed(2);
      _ratesInitialized = true;
    }

    final double bal = double.tryParse(_balanceController.text) ?? 480000;
    final double curRate = double.tryParse(_currentRateController.text) ?? 2.39;
    final double remAmort = double.tryParse(_remAmortController.text) ?? 20;
    final double newRate = double.tryParse(_newRateController.text) ?? 4.99;
    final double bestRate = double.tryParse(_bestRateController.text) ?? 4.64;
    final double penaltyVal = double.tryParse(_penaltyController.text) ?? 0;

    final double oldPmtVal = _pmt(bal, curRate, remAmort);
    final double newPmtVal = _pmt(bal, newRate, remAmort);
    final double bestPmtVal = _pmt(bal, bestRate, remAmort);

    final double diff = newPmtVal - oldPmtVal;
    final double extra5yr = diff * 60;
    final double diffVsNew = newPmtVal - bestPmtVal;

    final double maxPmt = dm.max(oldPmtVal, dm.max(newPmtVal, bestPmtVal));
    final double barOldW = maxPmt > 0 ? (oldPmtVal / maxPmt) : 0;
    final double barNewW = maxPmt > 0 ? (newPmtVal / maxPmt) : 0;
    final double barBestW = maxPmt > 0 ? (bestPmtVal / maxPmt) : 0;

    // Cumulative 5-yr Interest comparisons
    final List<Map<String, double>> cumInterestData = [];
    double maxInterestVal = 1.0;
    for (int y = 1; y <= 5; y++) {
      final double ni = _cumulativeInterest(bal, newRate, remAmort, y * 12);
      final double bi = _cumulativeInterest(bal, bestRate, remAmort, y * 12);
      if (ni > maxInterestVal) maxInterestVal = ni;
      if (bi > maxInterestVal) maxInterestVal = bi;
      cumInterestData.add({'new': ni, 'best': bi});
    }

    final saved = ref.watch(savedProvider);
    final localSaved = saved
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType.toLowerCase() == 'renewal planner')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Mortgage Details
        Text(
          'CURRENT MORTGAGE',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField('Outstanding Balance at Renewal', _balanceController, prefix: 'CA\$'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Current Rate (Expiring)', _currentRateController, suffix: '%'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Remaining Amortization', _remAmortController, suffix: 'yrs'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // New Term Options
        Text(
          'NEW TERM OPTIONS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField('New Rate — Lender Offer', _newRateController, suffix: '%'),
              const SizedBox(height: 12),
              _buildInputField('Best Rate You\'ve Found', _bestRateController, suffix: '%'),
              const SizedBox(height: 12),
              _buildInputField('Break Penalty (if breaking early)', _penaltyController, prefix: 'CA\$'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8102E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '🔄 Compare Renewal Options',
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _saveCalculation,
                    child: Container(
                      width: 50,
                      height: 46,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💾', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Renewal Impact
        Text(
          'RENEWAL IMPACT',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONTHLY PAYMENT CHANGE AT RENEWAL',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: Colors.white60,
                  weight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _resBox('Old Payment', CurrencyFormatter.format(oldPmtVal, symbol: 'CA\$'), const Color(0xFF6EDFA0)),
                  _resBox('New Payment', CurrencyFormatter.format(newPmtVal, symbol: 'CA\$'), const Color(0xFFFF8A9A)),
                  _resBox('Monthly Change', '${diff >= 0 ? '+' : ''}${CurrencyFormatter.format(diff, symbol: 'CA\$')}', const Color(0xFFFFD580)),
                  _resBox('5-Yr Extra Cost', '${extra5yr >= 0 ? '+' : ''}${CurrencyFormatter.format(extra5yr, symbol: 'CA\$')}', const Color(0xFFFF8A9A)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Visual Analysis
        Text(
          'VISUAL ANALYSIS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Payment Comparison',
                style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
              ),
              const SizedBox(height: 14),

              // Expiring Rate Bar
              _compareBar('Expiring Rate', CurrencyFormatter.format(oldPmtVal, symbol: 'CA\$'), 'At ${curRate.toStringAsFixed(2)}%', barOldW, const Color(0xFF6EDFA0)),
              const Divider(height: 20, thickness: 0.5),

              // Lender Offer Bar
              _compareBar('Lender Offer', CurrencyFormatter.format(newPmtVal, symbol: 'CA\$'), 'At ${newRate.toStringAsFixed(2)}%', barNewW, const Color(0xFFFF8A9A)),
              const Divider(height: 20, thickness: 0.5),

              // Best Rate Bar
              _compareBar('🏆 Best Rate', CurrencyFormatter.format(bestPmtVal, symbol: 'CA\$'), 'At ${bestRate.toStringAsFixed(2)}%', barBestW, const Color(0xFFFFD580)),

              const SizedBox(height: 24),
              Text(
                '5-Year Cumulative Interest Cost',
                style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
              ),
              const SizedBox(height: 16),
              // Cumulative double bars chart
              SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: cumInterestData.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value;

                    final double nh = (d['new']! / maxInterestVal) * 50;
                    final double bh = (d['best']! / maxInterestVal) * 50;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 8,
                                height: nh.clamp(2.0, 50.0),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF8A9A),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 8,
                                height: bh.clamp(2.0, 50.0),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD580),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yr ${idx + 1}',
                            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chartLeg('Lender Offer', const Color(0xFFFF8A9A)),
                  const SizedBox(width: 14),
                  _chartLeg('Best Rate', const Color(0xFFFFD580)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Scenario Comparison
        Text(
          'SCENARIO COMPARISON',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        _scenarioCard('Your Expiring Rate', '${curRate.toStringAsFixed(2)}% Fixed', CurrencyFormatter.format(oldPmtVal, symbol: 'CA\$'), 'This rate expires at renewal — for reference only', const Color(0xFFDCF4E8), const Color(0xFF1A5C35)),
        const SizedBox(height: 8),
        _scenarioCard('Lender Renewal Offer', '${newRate.toStringAsFixed(2)}% Fixed', CurrencyFormatter.format(newPmtVal, symbol: 'CA\$'), '+${CurrencyFormatter.format(diff, symbol: 'CA\$')}/mo vs expiring rate', const Color(0xFFFFE4E8), const Color(0xFFC8102E), diffTag: '↑ +${CurrencyFormatter.format(diff.abs(), symbol: 'CA\$')}/mo'),
        const SizedBox(height: 8),
        _scenarioCard('🏆 Best Rate Found', '${bestRate.toStringAsFixed(2)}% Fixed', CurrencyFormatter.format(bestPmtVal, symbol: 'CA\$'), 'Save ${CurrencyFormatter.format(diffVsNew, symbol: 'CA\$')}/mo vs lender offer', const Color(0xFFFEF3C7), const Color(0xFFD97706), diffTag: '↓ Save ${CurrencyFormatter.format(diffVsNew.abs(), symbol: 'CA\$')}/mo'),
        const SizedBox(height: 20),

        // Early break penalty analysis if applicable
        if (penaltyVal > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Early Break Penalty Analysis',
                  style: AppTextStyles.dmSans(size: 12, color: const Color(0xFF92400E), weight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _penItem('Break Penalty', CurrencyFormatter.format(penaltyVal, symbol: 'CA\$')),
                const Divider(color: Colors.black12, height: 16),
                _penItem('Monthly Savings (by switching)', '${CurrencyFormatter.format(diffVsNew.abs(), symbol: 'CA\$')}/mo'),
                const Divider(color: Colors.black12, height: 16),
                _penItem('Break-Even Period', diffVsNew > 0 ? '${(penaltyVal / diffVsNew).ceil()} months' : '— months'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Checklist Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Renewal Checklist',
                style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
              ),
              const SizedBox(height: 12),
              _checkItem('🔔', 'Start shopping 120 days early', 'Lenders can hold rates for up to 120 days before renewal', const Color(0xFFDCF4E8)),
              const Divider(height: 18, thickness: 0.5),
              _checkItem('🤝', 'Don\'t auto-renew with your bank', 'Banks often offer renewal rates 0.5–1% higher than best available', const Color(0xFFFEF3C7)),
              const Divider(height: 18, thickness: 0.5),
              _checkItem('📋', 'Get a mortgage broker quote', 'Brokers access 30+ lenders with no impact on credit score', const Color(0xFFDCF4E8)),
              const Divider(height: 18, thickness: 0.5),
              _checkItem('⚡', 'Negotiate — banks will often match', 'Present competing quotes; banks can improve by 0.25–0.5%', const Color(0xFFFFE4E8)),
              const Divider(height: 18, thickness: 0.5),
              _checkItem('📅', 'Consider shorter terms in 2026', 'With BoC rate cuts underway, 2–3 yr terms may outperform 5-yr', theme.getBgColor(context)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Local saved calcs
        if (localSaved.isNotEmpty) ...[
          Text(
            'SAVED SCENARIOS',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.bold,
              color: theme.getMutedColor(context),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: localSaved.length,
            itemBuilder: (context, idx) {
              final c = localSaved[idx];
              final sign = (c.results['Diff'] ?? 0) >= 0 ? '+' : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CA\$${(c.inputs['Balance'] ?? 0).toStringAsFixed(0)} · ${c.inputs['CurRate']}%→${c.inputs['NewRate']}%',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best ${c.inputs['BestRate']}% · Saves ${CurrencyFormatter.format((c.results['NewPmt']! - c.results['BestPmt']!).abs(), symbol: 'CA\$')}/mo',
                            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$sign${CurrencyFormatter.format(c.results['Diff'] ?? 0, symbol: 'CA\$')}/mo',
                      style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: (c.results['Diff'] ?? 0) > 0 ? const Color(0xFFC8102E) : const Color(0xFF1A5C35)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(savedProvider.notifier).delete(c.id),
                      child: const Text('✕', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Text(prefix, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: theme.primaryColor)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 11),
                  child: Text(suffix, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8,
              color: Colors.white60,
              weight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 13,
              weight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareBar(String label, String val, String sub, double pct, Color color) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
            Text(val, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: pct.clamp(0.01, 1.0),
              backgroundColor: theme.getBgColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _chartLeg(String title, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(title, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _scenarioCard(String tag, String name, String pmt, String detail, Color bg, Color tagColor, {String? diffTag}) {
    final theme = widget.theme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: isDark ? 0.08 : 1.0),
        border: Border.all(color: tagColor.withValues(alpha: 0.25), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.toUpperCase(),
            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: tagColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTextStyles.playfair(size: 14, weight: FontWeight.bold, color: theme.getTextColor(context))),
              Text(pmt, style: AppTextStyles.playfair(size: 18, weight: FontWeight.bold, color: tagColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(detail, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ),
              if (diffTag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diffTag,
                    style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: tagColor),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _penItem(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFB45309), weight: FontWeight.bold)),
        Text(val, style: AppTextStyles.playfair(size: 14, color: const Color(0xFF92400E), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _checkItem(String emoji, String title, String subtitle, Color color) {
    final theme = widget.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }
}
