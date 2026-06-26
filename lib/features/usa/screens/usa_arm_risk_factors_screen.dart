// lib/features/usa/screens/usa_arm_risk_factors_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAArmRiskFactorsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAArmRiskFactorsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAArmRiskFactorsScreen> createState() => _USAArmRiskFactorsScreenState();
}

class _USAArmRiskFactorsScreenState extends ConsumerState<USAArmRiskFactorsScreen> {
  static const _theme = CountryThemes.usa;

  // Controllers
  final _balanceController = TextEditingController(text: '320000');
  final _currentController = TextEditingController(text: '3.25');
  final _indexController = TextEditingController(text: '3.63');
  final _marginController = TextEditingController(text: '2.50');
  final _periodicController = TextEditingController(text: '2.00');
  final _lifetimeController = TextEditingController(text: '5.00');
  final _yearsController = TextEditingController(text: '25');

  // Outputs
  bool _calculated = false;
  double _currentPmt = 0.0;
  double _expectedPmt = 0.0;
  double _indexedPmt = 0.0;
  double _worstPmt = 0.0;
  double _incDollar = 0.0;
  double _incPct = 0.0;
  double _rateGap = 0.0;
  double _rgPts = 0.0;
  double _piPts = 0.0;
  double _tePts = 0.0;
  int _score = 0;
  String _bandLabel = 'Calculating…';
  Color _bandColor = const Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _balanceController.text = (inputs['balance'] ?? 320000.0).toStringAsFixed(0);
      _currentController.text = (inputs['currentRate'] ?? 3.25).toStringAsFixed(2);
      _indexController.text = (inputs['indexRate'] ?? 3.63).toStringAsFixed(2);
      _marginController.text = (inputs['margin'] ?? 2.50).toStringAsFixed(2);
      _periodicController.text = (inputs['periodicCap'] ?? 2.00).toStringAsFixed(2);
      _lifetimeController.text = (inputs['lifetimeCap'] ?? 5.00).toStringAsFixed(2);
      _yearsController.text = (inputs['yearsRemaining'] ?? 25.0).toStringAsFixed(0);
      _calculate();
    } else {
      _calculate();
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _currentController.dispose();
    _indexController.dispose();
    _marginController.dispose();
    _periodicController.dispose();
    _lifetimeController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  double _pmtCalc(double loan, double annualRatePercent, int months) {
    final mr = (annualRatePercent / 100) / 12;
    if (mr <= 0 || mr.isNaN || !mr.isFinite) return loan / max(months, 1);
    final f = pow(1 + mr, months);
    return loan * (mr * f) / (f - 1);
  }

  Map<String, dynamic> _bandFor(int score) {
    if (score <= 25) {
      return {'key': 'low', 'label': 'Low Risk', 'color': const Color(0xFF22C55E)};
    } else if (score <= 50) {
      return {'key': 'mod', 'label': 'Moderate Risk', 'color': const Color(0xFFFCD34D)};
    } else if (score <= 75) {
      return {'key': 'high', 'label': 'High Risk', 'color': const Color(0xFFFB923C)};
    } else {
      return {'key': 'severe', 'label': 'Severe Risk', 'color': const Color(0xFFEF4444)};
    }
  }

  void _calculate() {
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final current = (double.tryParse(_currentController.text) ?? 0.0) / 100;
    final index = (double.tryParse(_indexController.text) ?? 0.0) / 100;
    final margin = (double.tryParse(_marginController.text) ?? 0.0) / 100;
    final periodic = (double.tryParse(_periodicController.text) ?? 0.0) / 100;
    final lifetime = (double.tryParse(_lifetimeController.text) ?? 5.0) / 100;
    final years = double.tryParse(_yearsController.text) ?? 25.0;
    final months = (years * 12).round();

    final fullyIndexedRate = index + margin;
    final periodicCapRate = current + periodic;
    final lifetimeCapRate = current + lifetime;
    final expectedRate = min(fullyIndexedRate, min(periodicCapRate, lifetimeCapRate));
    final worstRate = lifetimeCapRate;

    final currentPmt = _pmtCalc(balance, current * 100, months);
    final expectedPmt = _pmtCalc(balance, expectedRate * 100, months);
    final indexedPmt = _pmtCalc(balance, fullyIndexedRate * 100, months);
    final worstPmt = _pmtCalc(balance, worstRate * 100, months);

    final incDollar = expectedPmt - currentPmt;
    final incPct = currentPmt > 0 ? (incDollar / currentPmt) * 100 : 0.0;

    // Risk score calculation
    final rateGap = max(0.0, fullyIndexedRate - current) * 100; // in percentage points
    final rgPts = (rateGap / 5 * 40).clamp(0.0, 40.0);
    final piPts = (incPct.clamp(0.0, double.infinity) / 50 * 40).clamp(0.0, 40.0);
    final tePts = (years / 25 * 20).clamp(0.0, 20.0);
    final score = (rgPts + piPts + tePts).round();
    final band = _bandFor(score);

    setState(() {
      _currentPmt = currentPmt;
      _expectedPmt = expectedPmt;
      _indexedPmt = indexedPmt;
      _worstPmt = worstPmt;
      _incDollar = incDollar;
      _incPct = incPct;
      _rateGap = rateGap;
      _rgPts = rgPts;
      _piPts = piPts;
      _tePts = tePts;
      _score = score;
      _bandLabel = band['label'] as String;
      _bandColor = band['color'] as Color;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;

    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final current = double.tryParse(_currentController.text) ?? 0.0;
    final index = double.tryParse(_indexController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;
    final periodic = double.tryParse(_periodicController.text) ?? 0.0;
    final lifetime = double.tryParse(_lifetimeController.text) ?? 0.0;
    final years = double.tryParse(_yearsController.text) ?? 0.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'ARM Risk Factors',
      label: 'ARM Risk Score: $_score/100 · Balance: \$${CurrencyFormatter.compact(balance, symbol: "")} · Expected Reset: \$${_expectedPmt.round()}/mo',
      currencyCode: 'USD',
      inputs: {
        'balance': balance,
        'currentRate': current,
        'indexRate': index,
        'margin': margin,
        'periodicCap': periodic,
        'lifetimeCap': lifetime,
        'yearsRemaining': years,
      },
      results: {
        'RiskScore': _score.toDouble(),
        'CurrentPayment': _currentPmt,
        'ExpectedPayment': _expectedPmt,
        'WorstCasePayment': _worstPmt,
        'IncreasePercent': _incPct,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ ARM risk assessment scenario saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final savedRisks = ref.watch(savedProvider).where((c) => c.country.toLowerCase() == 'usa' && c.calcType == 'ARM Risk Factors').toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: const Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('ARM Risk Factors',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('Payment Shock · Volatility · Qualification Risk',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Summary Strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildStripItem('SOFR Index', '3.63%', 'NY Fed · 6/17', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Fed Funds', '3.50–3.75%', 'FOMC · Jun \'26', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('ARM Share', '9.4%', 'MBA · May \'26', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Serious DQ', '2.03%', 'MBA Q1 \'26', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Covers Note Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3F72).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1B3F72).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Adjustable-rate mortgages trade a lower introductory rate for several layers of risk that fixed-rate loans don\'t carry. Below you\'ll find the six core ARM risk factors, a payment-shock calculator you can save, and current U.S. rate data so you can stress-test a real loan before — or after — you sign.',
                    style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF1B3F72), height: 1.4),
                  ),
                ),

                _buildSectionHeader('Risk Snapshot'),

                // Risk Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.35,
                  children: [
                    _buildRiskChip('⚡ Payment Shock', 'High', const Color(0xFFFEE2E2), const Color(0xFFB91C1C), 'Rates reset from pandemic-era lows to today\'s ~6% range', textCol, mutedCol),
                    _buildRiskChip('📈 Rate Volatility', 'Moderate', const Color(0xFFFEF3C7), const Color(0xFF92400E), 'SOFR has swung 5.5 pts since 2022', textCol, mutedCol),
                    _buildRiskChip('🔄 Refinance / Exit', 'Moderate', const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Depends on equity, credit & rates at reset', textCol, mutedCol),
                    _buildRiskChip('📉 Neg. Amortization', 'Low', const Color(0xFFDCFCE7), const Color(0xFF15803D), 'Rare since Dodd-Frank QM rules (2014)', textCol, mutedCol),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Payment Shock Calculator'),

                // Inputs Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField('Remaining Balance (\$)', _balanceController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Current Rate (%)', _currentController, hint: 'Your rate today')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Index Rate — SOFR (%)', _indexController, hint: 'Live NY Fed SOFR')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Margin (%)', _marginController, hint: 'Typical 2.25–2.75%')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Periodic Cap (%)', _periodicController, hint: 'Max per adjustment')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Lifetime Cap (%)', _lifetimeController, hint: 'Max above start rate')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Years Remaining', _yearsController, hint: 'Time left after fixed ends')),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Result Hero Card
                if (_calculated) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: double.infinity),
                            Text(
                              'PAYMENT SHOCK RISK SCORE',
                              style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white54,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 100,
                              width: 180,
                              child: CustomPaint(
                                painter: RiskScoreGaugePainter(
                                  score: _score,
                                  activeColor: _bandColor,
                                  isDark: isDark,
                                ),
                                child: Align(
                                  alignment: const Alignment(0, 0.4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_score',
                                        style: AppTextStyles.playfair(
                                          size: 28,
                                          color: Colors.white,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'SCORE / 100',
                                        style: AppTextStyles.dmSans(
                                          size: 8,
                                          color: Colors.white54,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: _bandColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _bandLabel,
                                style: AppTextStyles.dmSans(
                                  size: 11,
                                  color: _bandColor,
                                  weight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Expected reset payment: \$${_expectedPmt.round()}/mo — up ${_incPct >= 0 ? '+' : ''}${_incPct.toStringAsFixed(1)}% (\$${_incDollar.round().abs()}) from your current \$${_currentPmt.round()}/mo payment.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, height: 1.5),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _saveCalc,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark_border, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Save', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Saved Risk Assessments
                if (savedRisks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader('Saved Risk Assessments'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in savedRisks)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bgCol,
                              border: Border.all(color: borderCol),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Reset est. \$${item.results['ExpectedPayment']?.round()}/mo (${item.results['IncreasePercent']?.toStringAsFixed(1)}%)',
                                        style: AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFB91C1C)),
                                  onPressed: () => ref.read(savedProvider.notifier).delete(item.id),
                                )
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Risk Breakdown'),

                // Breakdown Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.35,
                  children: [
                    _buildBreakdownCard('📌', 'Current Payment', '\$${_currentPmt.round()}', 'At today\'s rate', textCol, mutedCol),
                    _buildBreakdownCard('🧮', 'Expected Reset', '\$${_expectedPmt.round()}', 'After periodic cap', textCol, mutedCol),
                    _buildBreakdownCard('📡', 'Fully-Indexed', '\$${_indexedPmt.round()}', 'Index + margin, uncapped', textCol, mutedCol),
                    _buildBreakdownCard('🚨', 'Worst Case', '\$${_worstPmt.round()}', 'At lifetime cap', textCol, mutedCol),
                    _buildBreakdownCard('💵', '\$ Increase', '${_incDollar >= 0 ? '+' : '-'}\$${_incDollar.round().abs()}', 'Expected reset vs now', textCol, mutedCol),
                    _buildBreakdownCard('📊', '% Increase', '${_incPct >= 0 ? '+' : ''}${_incPct.toStringAsFixed(1)}%', 'Expected reset vs now', textCol, mutedCol),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Reset Payment Scenarios'),

                // Horizontal scenario bar charts
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildPaymentBarRow('Current', _currentPmt, Colors.teal, textCol),
                      const SizedBox(height: 10),
                      _buildPaymentBarRow('Expected', _expectedPmt, Colors.amber, textCol),
                      const SizedBox(height: 10),
                      _buildPaymentBarRow('Indexed', _indexedPmt, Colors.orange, textCol),
                      const SizedBox(height: 10),
                      _buildPaymentBarRow('Worst Case', _worstPmt, Colors.red, textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Risk Score Breakdown'),

                // Scenario Score Table Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildTableTitleRow('Factor', 'Value', 'Points', textCol),
                      const Divider(),
                      _buildTableRow('Rate Gap (Index+Margin − Current)', '${_rateGap.toStringAsFixed(2)} pts', '${_rgPts.round()} / 40', textCol),
                      _buildTableRow('Payment Increase', '${_incPct.toStringAsFixed(1)}%', '${_piPts.round()} / 40', textCol),
                      _buildTableRow('Remaining Exposure', '${double.tryParse(_yearsController.text)?.round() ?? 25} yrs', '${_tePts.round()} / 20', textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Current Market Risk Indicators'),

                // Breakdown Grid for Market data
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.35,
                  children: [
                    _buildBreakdownCard('🏦', 'Fed Funds Target', '3.50–3.75%', 'Held since Dec \'25 FOMC', textCol, mutedCol),
                    _buildBreakdownCard('📡', 'SOFR (ARM Index)', '3.63%', 'NY Fed, Jun 17 2026', textCol, mutedCol),
                    _buildBreakdownCard('📋', 'ARM App Share', '9.4%', 'MBA, week of 5/22/26', textCol, mutedCol),
                    _buildBreakdownCard('🚨', 'Foreclosure Starts', '0.24%', 'MBA, Q1 2026', textCol, mutedCol),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Fed Funds Rate Path (Upper Bound)'),

                // Fed funds path bar chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildPathBarRow('Jan 2022', 0.25, 5.50, const Color(0xFF1B3F72), textCol),
                      const SizedBox(height: 8),
                      _buildPathBarRow('Jul 2023', 5.50, 5.50, const Color(0xFFB91C1C), textCol),
                      const SizedBox(height: 8),
                      _buildPathBarRow('Dec 2024', 4.50, 5.50, const Color(0xFFD97706), textCol),
                      const SizedBox(height: 8),
                      _buildPathBarRow('Dec 2025', 3.75, 5.50, const Color(0xFF0F766E), textCol),
                      const SizedBox(height: 8),
                      _buildPathBarRow('Jun 2026', 3.75, 5.50, const Color(0xFF0F766E), textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('New Originations: ARM vs Fixed-Rate'),

                // Pie chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: DonutChartPainter(isDark: isDark),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '9.4%',
                                  style: AppTextStyles.playfair(
                                    size: 13,
                                    color: textCol,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'are ARMs',
                                  style: AppTextStyles.dmSans(
                                    size: 6.5,
                                    color: mutedCol,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendRow(const Color(0xFF1B3F72), 'Fixed-Rate Mortgages', '90.6%', textCol),
                            const SizedBox(height: 6),
                            _buildLegendRow(const Color(0xFFD97706), 'Adjustable-Rate (ARM)', '9.4%', textCol),
                            const SizedBox(height: 8),
                            Text(
                              'Source: MBA Weekly Applications Survey, week ending 5/22/2026',
                              style: AppTextStyles.dmSans(size: 8, color: mutedCol),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('The 6 Core ARM Risk Factors'),

                // Accordions
                _AccordionCard(
                  emoji: '⚡',
                  title: 'Payment Shock Risk',
                  subtitle: 'Reset payment far exceeds initial payment',
                  badgeText: 'High',
                  badgeBg: const Color(0xFFFEE2E2),
                  badgeFg: const Color(0xFFB91C1C),
                  description1: 'Payment shock happens when the rate adjustment at the end of your fixed period pushes your monthly payment up sharply. Borrowers who closed 5/1 ARMs near pandemic-era lows of roughly 2.5%–3.5% in 2020–2021 are now resetting against an index plus margin near 6%, which can mean payment increases of 30–60% or more in a single adjustment.',
                  description2: 'The size of the shock depends on how far the index has moved, your margin, and your periodic and lifetime caps — caps soften the blow but don\'t eliminate it.',
                  statText: 'SOFR: 3.63% today vs ~0.05% in early 2022',
                  textCol: textCol,
                  mutedCol: mutedCol,
                  borderCol: borderCol,
                  cardBg: cardBg,
                ),
                _AccordionCard(
                  emoji: '📈',
                  title: 'Index / Rate Volatility Risk',
                  subtitle: 'Your rate tracks an external benchmark',
                  badgeText: 'Moderate',
                  badgeBg: const Color(0xFFFEF3C7),
                  badgeFg: const Color(0xFF92400E),
                  description1: 'Most U.S. ARMs originated since 2023 use SOFR (Secured Overnight Financing Rate) as the index, replacing LIBOR. SOFR moves with the Federal Reserve\'s monetary policy and overnight repo markets, so it can shift meaningfully between adjustment dates.',
                  description2: 'Over the last four years the benchmark Fed Funds rate has ranged from near 0% (2022) to a peak of 5.25–5.50% (mid-2023) and back down to 3.50–3.75% today — a swing of more than 5 percentage points, illustrating how much an ARM index can move within a single loan term.',
                  statText: 'Fed Funds: 3.50–3.75% (held since Dec 2025)',
                  textCol: textCol,
                  mutedCol: mutedCol,
                  borderCol: borderCol,
                  cardBg: cardBg,
                ),
                _AccordionCard(
                  emoji: '📉',
                  title: 'Negative Amortization Risk',
                  subtitle: 'Balance growing instead of shrinking',
                  badgeText: 'Low',
                  badgeBg: const Color(0xFFDCFCE7),
                  badgeFg: const Color(0xFF15803D),
                  description1: 'Negative amortization occurs when a minimum payment is lower than the interest due, so unpaid interest is added to the loan balance — common on "Option ARMs" before the 2008 crisis. Today this risk is low for most borrowers: the CFPB\'s Ability-to-Repay / Qualified Mortgage rule effectively excludes negative-amortization features from Qualified Mortgages, and almost all current ARM products are fully amortizing.',
                  description2: 'The risk isn\'t zero — some non-QM and specialty interest-only ARMs still exist — so it\'s worth confirming directly in your Note and Truth-in-Lending disclosure that your loan fully amortizes.',
                  statText: 'Largely phased out since Dodd-Frank QM rule (2014)',
                  textCol: textCol,
                  mutedCol: mutedCol,
                  borderCol: borderCol,
                  cardBg: cardBg,
                ),
                _AccordionCard(
                  emoji: '📋',
                  title: 'Qualification / Underwriting Risk',
                  subtitle: 'Could you still qualify at the reset rate?',
                  badgeText: 'Moderate',
                  badgeBg: const Color(0xFFFEF3C7),
                  badgeFg: const Color(0xFF92400E),
                  description1: 'Under Regulation Z\'s Ability-to-Repay rule, lenders generally must qualify ARM borrowers using the greater of the fully-indexed rate or the introductory note rate for ARMs with an initial fixed period of five years or less — this prevents lenders from approving loans only affordable at the teaser rate.',
                  description2: 'Even so, your personal finances can change after closing. If your income drops, your credit score falls, or your debt rises before the reset, refinancing into a fixed-rate loan to escape an unfavorable adjustment may become harder, not easier.',
                  statText: '12 CFR §1026.43 — CFPB Ability-to-Repay Rule',
                  textCol: textCol,
                  mutedCol: mutedCol,
                  borderCol: borderCol,
                  cardBg: cardBg,
                ),
                _AccordionCard(
                  emoji: '🔄',
                  title: 'Refinance / Exit Risk',
                  subtitle: 'Plan B may not always be available',
                  badgeText: 'Moderate',
                  badgeBg: const Color(0xFFFEF3C7),
                  badgeFg: const Color(0xFF92400E),
                  description1: 'Many ARM borrowers plan to refinance or sell before the first adjustment. That strategy depends on market conditions cooperating: if home values fall, your loan-to-value ratio worsens and refinancing options shrink; if rates rise broadly, the fixed-rate alternative you\'re refinancing into may not be much cheaper than your new ARM rate.',
                  description2: 'With ARMs making up only about 9.4% of current applications, most borrowers still choose fixed-rate loans — a sign that the market continues to price ARMs as the higher-risk, higher-reward option for the minority who are comfortable with the tradeoff.',
                  statText: 'ARM share: 9.4% of applications (MBA, May 2026)',
                  textCol: textCol,
                  mutedCol: mutedCol,
                  borderCol: borderCol,
                  cardBg: cardBg,
                ),
                _AccordionCard(
                  emoji: '🧾',
                  title: 'Prepayment Penalty Risk',
                  subtitle: 'Cost of paying off or refinancing early',
                  badgeText: 'Low',
                  badgeBg: const Color(0xFFDCFCE7),
                  badgeFg: const Color(0xFF15803D),
                  description1: 'Prepayment penalties are largely restricted under the Dodd-Frank Act: Qualified Mortgages cannot carry a prepayment penalty, and non-QM loans that do must follow strict limits on size and duration. For the large majority of conventional, conforming ARMs sold today, this risk is minimal.',
                  description2: 'Always check Section 4 of your Loan Estimate / Closing Disclosure to confirm whether any penalty applies — it\'s required to be disclosed clearly before closing.',
                  statText: 'Dodd-Frank Act §1414 prepayment penalty limits',
                  textCol: textCol,
                  mutedCol: mutedCol,
                  borderCol: borderCol,
                  cardBg: cardBg,
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Regulatory Safeguards'),

                // Safeguards Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🛡️ Protections Built Into Every U.S. ARM',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF064E3B), fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 10),
                      _buildSafeRow('Ability-to-Repay', 'Qualify at fully-indexed rate, not teaser rate'),
                      _buildSafeRow('CHARM Booklet', 'Required ARM disclosure at application'),
                      _buildSafeRow('Initial Adj. Notice', 'Sent 210–240 days before first reset payment'),
                      _buildSafeRow('Periodic Adj. Notice', 'Sent 60–120 days before each later reset'),
                      _buildSafeRow('Prepayment Limits', 'Banned on Qualified Mortgages (Dodd-Frank)'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Risk Mitigation Tips'),

                // Tips Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Before & After You Take an ARM',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12), fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 10),
                      _buildTipRow(1, 'Budget against the lifetime-cap "worst case" payment, not just the intro rate, when deciding affordability.'),
                      _buildTipRow(2, 'Build a reserve fund covering 6–12 months at the worst-case payment before your first adjustment date.'),
                      _buildTipRow(3, 'Track SOFR periodically — it\'s published daily by the New York Fed — so resets aren\'t a surprise.'),
                      _buildTipRow(4, 'Confirm your exact cap structure (e.g. 2/2/5 vs 5/2/5) and margin in the Note before you sign, not after.'),
                      _buildTipRow(5, 'Line up a refinance or sale exit strategy 6–12 months before your fixed period ends, rather than waiting for the notice.'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Rate & survey data: New York Fed (SOFR), Federal Reserve FOMC, Freddie Mac PMMS, Bankrate, Mortgage Bankers Association. Updated June 2026. Educational estimates only — not financial, legal, or tax advice.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(size: 8, color: mutedCol, height: 1.6),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String value, String sub, bool isDark, {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white)),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : Colors.white60)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.sectionLabel(_theme.getMutedColor(context)),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint}) {
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => _calculate(),
            style: AppTextStyles.inputValue(theme.getTextColor(context)),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context).withValues(alpha: 0.4)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskChip(String name, String level, Color badgeBg, Color badgeFg, String desc, Color textCol, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.dmSans(size: 9.5, color: textCol, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  level,
                  style: AppTextStyles.dmSans(size: 7, color: badgeFg, weight: FontWeight.w700),
                ),
              )
            ],
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String emoji, String label, String value, String sub, Color valColor, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: _theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15.5, color: valColor, weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPaymentBarRow(String label, double val, Color color, Color textCol) {
    final maxBar = max(max(_currentPmt, _expectedPmt), max(_indexedPmt, _worstPmt));
    final widthFactor = (val / (maxBar > 0 ? maxBar : 1.0)).clamp(0.12, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 9.5, color: textCol, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.only(left: 7),
                alignment: Alignment.centerLeft,
                child: Text(
                  '\$${val.round()}',
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableTitleRow(String c1, String c2, String c3, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(c1, style: AppTextStyles.dmSans(size: 8.5, color: textCol, weight: FontWeight.w700))),
          Expanded(flex: 2, child: Text(c2, style: AppTextStyles.dmSans(size: 8.5, color: textCol, weight: FontWeight.w700), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(c3, style: AppTextStyles.dmSans(size: 8.5, color: textCol, weight: FontWeight.w700), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTableRow(String factor, String val, String pts, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _theme.getBorderColor(context), width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(factor, style: AppTextStyles.dmSans(size: 10, color: textCol))),
          Expanded(flex: 2, child: Text(val, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w700), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(pts, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFFD97706), weight: FontWeight.w700), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPathBarRow(String label, double val, double maxScale, Color color, Color textCol) {
    final widthPct = (val / maxScale).clamp(0.045, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: textCol, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthPct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.only(left: 6),
                alignment: Alignment.centerLeft,
                child: Text(
                  '${val.toStringAsFixed(2)}%',
                  style: AppTextStyles.dmSans(size: 8, color: Colors.white, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label, String val, Color textCol) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 9.5, color: textCol),
          ),
        ),
        Text(
          val,
          style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSafeRow(String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x336EE7B7), width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF065F46), weight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF047857), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(int num, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x33FDBA74), width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF7C2D12), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw semi-circular gauge
class RiskScoreGaugePainter extends CustomPainter {
  final int score;
  final Color activeColor;
  final bool isDark;

  RiskScoreGaugePainter({
    required this.score,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;
    final double radius = min(W / 2 - 10, H - 10);
    final center = Offset(W / 2, H - 10);

    final Paint bgPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0x1B0B1D3A)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fgPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background arc from pi to 2*pi
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Draw active arc based on score percentage
    final sweepAngle = pi * (score.clamp(0, 100) / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RiskScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDark != isDark;
  }
}

// Custom Painter to draw originations donut chart
class DonutChartPainter extends CustomPainter {
  final bool isDark;
  const DonutChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;
    final center = Offset(W / 2, H / 2);
    final radius = min(W / 2, H / 2) - 10;

    final Paint bgPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFEEF2F8)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;

    final Paint fixedPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint armPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw full background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Calculate angles:
    // ARM: 9.4% (0.094)
    // Fixed: 90.6% (0.906)
    const double startAngle = -pi / 2;
    const double fixedAngle = 2 * pi * 0.906;
    const double armAngle = 2 * pi * 0.094;

    // Draw Fixed-Rate Mortgages arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fixedAngle - 0.08,
      false,
      fixedPaint,
    );

    // Draw Adjustable-Rate (ARM) arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + fixedAngle,
      armAngle - 0.08,
      false,
      armPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => false;
}

class _AccordionCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final String description1;
  final String description2;
  final String statText;
  final Color textCol;
  final Color mutedCol;
  final Color borderCol;
  final Color cardBg;

  const _AccordionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.description1,
    required this.description2,
    required this.statText,
    required this.textCol,
    required this.mutedCol,
    required this.borderCol,
    required this.cardBg,
  });

  @override
  State<_AccordionCard> createState() => _AccordionCardState();
}

class _AccordionCardState extends State<_AccordionCard> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.cardBg,
        border: Border.all(color: widget.borderCol),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.borderCol.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTextStyles.playfair(size: 12, color: widget.textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: AppTextStyles.dmSans(size: 8.5, color: widget.mutedCol)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.badgeText,
                      style: AppTextStyles.dmSans(size: 7, color: widget.badgeFg, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _isOpen ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text('›', style: TextStyle(fontSize: 16, color: widget.textCol.withValues(alpha: 0.3))),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.description1, style: AppTextStyles.dmSans(size: 9.5, color: widget.mutedCol, height: 1.6)),
                  const SizedBox(height: 6),
                  Text(widget.description2, style: AppTextStyles.dmSans(size: 9.5, color: widget.mutedCol, height: 1.6)),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.borderCol.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      widget.statText,
                      style: AppTextStyles.dmSans(size: 8.5, color: widget.textCol, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
