// lib/features/usa/tools/usa_credit_score_impact_calc.dart

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

class USACreditScoreImpactCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USACreditScoreImpactCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USACreditScoreImpactCalc> createState() => _USACreditScoreImpactCalcState();
}

class _USACreditScoreImpactCalcState extends ConsumerState<USACreditScoreImpactCalc> {
  final _loanAmtController = TextEditingController(text: '360000');
  double _ficoScore = 720;
  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _loanAmtController.addListener(_markDirty);
    // Auto-calculate on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _loanAmtController.dispose();
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

  final List<Map<String, dynamic>> _bands = [
    {'min': 760, 'max': 850, 'rate': 6.48, 'label': 'Exceptional', 'color': const Color(0xFF15803D)},
    {'min': 720, 'max': 759, 'rate': 6.72, 'label': 'Very Good', 'color': const Color(0xFF84CC16)},
    {'min': 700, 'max': 719, 'rate': 6.96, 'label': 'Good', 'color': const Color(0xFFEAB308)},
    {'min': 680, 'max': 699, 'rate': 7.14, 'label': 'Good', 'color': const Color(0xFFEAB308)},
    {'min': 660, 'max': 679, 'rate': 7.38, 'label': 'Fair', 'color': const Color(0xFFD97706)},
    {'min': 640, 'max': 659, 'rate': 7.74, 'label': 'Poor', 'color': const Color(0xFFB91C1C)},
    {'min': 620, 'max': 639, 'rate': 8.22, 'label': 'Very Poor', 'color': const Color(0xFF991B1B)},
  ];

  Map<String, dynamic> _getBand(double score) {
    for (final b in _bands) {
      if (score >= b['min'] && score <= b['max']) {
        return b;
      }
    }
    return _bands.last;
  }

  double _calcPI(double loan, double rate) {
    final mo = rate / 1200;
    const n = 360;
    return mo == 0 ? loan / n : loan * mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1);
  }

  void _calculate() async {
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

  void _saveCalculation() async {
    final loan = _val(_loanAmtController);
    if (loan <= 0) return;

    final activeBand = _getBand(_ficoScore);
    final rate = activeBand['rate'] as double;
    final myPI = _calcPI(loan, rate);
    final myLifeInterest = myPI * 360 - loan;

    final labelCtrl = TextEditingController(text: 'Credit Score Impact');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_credit_score_impact_calc/save'),
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
              'Saving: FICO: ${_ficoScore.toInt()} · Rate: $rate% · Monthly P&I: ${CurrencyFormatter.compact(myPI, symbol: r'$')}',
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
                hintText: 'Label (e.g. My FICO Rate Impact)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Credit Score Impact';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Credit Score Impact',
        inputs: {
          'FicoScore': _ficoScore,
          'LoanAmt': loan,
        },
        results: {
          'FICO': _ficoScore,
          'Rate': rate,
          'Monthly P&I': myPI,
          'Lifetime Interest': myLifeInterest,
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
    final loan = _val(_loanAmtController);

    final activeBand = _getBand(_ficoScore);
    final currentRate = activeBand['rate'] as double;
    final currentLabel = activeBand['label'] as String;
    final currentColor = activeBand['color'] as Color;

    final myPI = _calcPI(loan, currentRate);
    final myLifeInterest = myPI * 360 - loan;

    const bestRate = 6.48;
    final bestPI = _calcPI(loan, bestRate);
    final bestLifeInterest = bestPI * 360 - loan;

    final moDiff = max(0.0, myPI - bestPI);
    final lifeDiff = max(0.0, myLifeInterest - bestLifeInterest);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip header — Live FRED 30yr rate
        LightRateStripBanner(items: [
          RateStripItem(label: 'Excellent\n740+', provider: fredMortgage30Provider, fallback: 6.82),
          RateStripItem(label: '15-Yr Avg', provider: fredMortgage15Provider, fallback: 6.11),
          RateStripItem(label: 'Prime Rate', provider: fredPrimeProvider, fallback: 8.50),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),
        const SizedBox(height: 16),

        Text('YOUR FICO SCORE', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Score Card with gauge and slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: isDark ? 0.05 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Custom Gauge
              SizedBox(
                height: 110,
                width: 200,
                child: CustomPaint(
                  painter: _FicoGaugePainter(
                    score: _ficoScore,
                    color: currentColor,
                    label: currentLabel,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Colored fico ranges block
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(flex: 280, child: Container(color: const Color(0xFFB91C1C))),
                      Expanded(flex: 90, child: Container(color: const Color(0xFFD97706))),
                      Expanded(flex: 30, child: Container(color: const Color(0xFFEAB308))),
                      Expanded(flex: 70, child: Container(color: const Color(0xFF84CC16))),
                      Expanded(flex: 110, child: Container(color: const Color(0xFF15803D))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('300', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                  Text('580', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                  Text('670', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                  Text('700', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                  Text('740', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                  Text('850', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 8),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: currentColor,
                  inactiveTrackColor: theme.getBgColor(context),
                  thumbColor: Colors.white,
                  overlayColor: currentColor.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _ficoScore,
                  min: 300,
                  max: 850,
                  onChanged: (val) {
                    setState(() {
                      _ficoScore = val;
                      _markDirty();
                    });
                  },
                ),
              ),

              // Loan input
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: TextField(
                  controller: _loanAmtController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'LOAN AMOUNT',
                    labelStyle: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold),
                    border: InputBorder.none,
                    prefixText: r'$ ',
                    prefixStyle: AppTextStyles.dmSans(size: 14, color: theme.getMutedColor(context), weight: FontWeight.bold),
                  ),
                ),
              ),

              // Calculation / Save Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.85)],
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
                            : Text('📊 Calculate Impact', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                      ),
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
          // Result Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: theme.primaryColor.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR ESTIMATED MORTGAGE RATE', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${currentRate.toStringAsFixed(2)}%',
                    style: AppTextStyles.playfair(size: 36, color: Colors.white, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('FICO ${_ficoScore.toInt()} — $currentLabel Credit Tier',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroStatItem('Monthly P&I', CurrencyFormatter.format(myPI, symbol: r'$')),
                    _buildHeroStatItem('30-Yr Interest', CurrencyFormatter.compact(myLifeInterest, symbol: r'$'), color: const Color(0xFFFCD34D)),
                    _buildHeroStatItem('vs. 760+ Score', '+${CurrencyFormatter.format(moDiff, symbol: r'$')}/mo'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-side stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Extra Lifetime Cost', CurrencyFormatter.format(lifeDiff, symbol: r'$'), 'vs. 760+ score tier', theme, context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Monthly Overpay', '+${CurrencyFormatter.format(moDiff, symbol: r'$')}', 'vs. excellent credit', theme, context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart comparing payments
          Text('MONTHLY PAYMENT BY SCORE BAND', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
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
                ..._bands.map((b) {
                  final isCurrent = _ficoScore >= b['min'] && _ficoScore <= b['max'];
                  final pmt = _calcPI(loan, b['rate']);
                  final double scale = (pmt / _calcPI(loan, 8.22));

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${b['min']}+',
                            style: AppTextStyles.dmSans(
                              size: 10,
                              color: isCurrent ? b['color'] : theme.getTextColor(context),
                              weight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: scale,
                              child: Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isCurrent ? b['color'] : theme.getBgColor(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  CurrencyFormatter.format(pmt, symbol: r'$'),
                                  style: AppTextStyles.dmSans(
                                    size: 9,
                                    color: isCurrent ? Colors.white : theme.getTextColor(context),
                                    weight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: Text(
                            isCurrent ? '← YOU' : '',
                            style: AppTextStyles.dmSans(size: 9, color: currentColor, weight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Rate Table reference
        Text('FICO SCORE MORTGAGE RATES (30-YR FIXED)', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                color: theme.getBgColor(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('SCORE BAND', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold))),
                    Expanded(child: Text('30-YR RATE', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
                    Expanded(child: Text('EST. P&I', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              ..._bands.map((b) {
                final isCurrent = _ficoScore >= b['min'] && _ficoScore <= b['max'];
                final pmtVal = _calcPI(loan, b['rate']);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isCurrent ? theme.primaryColor.withValues(alpha: 0.05) : null,
                    border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text('${b['min']}–${b['max']}', style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold)),
                            if (isCurrent)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('YOU', style: AppTextStyles.dmSans(size: 7, color: theme.primaryColor, weight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(child: Text('${b['rate']}%', style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
                      Expanded(
                        child: Text(
                          CurrencyFormatter.format(pmtVal, symbol: r'$'),
                          style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.w600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tips List
        Text('BOOST YOUR SCORE — QUICK WINS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTipCard('💳', 'Pay Down Credit Cards', 'Keep utilization under 30% · under 10% for max score boost', theme, context),
        _buildTipCard('✅', 'Never Miss a Payment', 'Payment history = 35% of FICO score · setup autopay', theme, context),
        _buildTipCard('🚫', 'Don\'t Open New Accounts', 'Hard inquiries lower score 5–10 pts for 12 months', theme, context),
        _buildTipCard('📋', 'Dispute Errors on Report', '1 in 5 reports has errors · dispute via AnnualCreditReport.com', theme, context),
        _buildTipCard('⏳', 'Keep Old Accounts Open', 'Credit age = 15% of FICO · older accounts help your score', theme, context),
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

  Widget _buildTipCard(String icon, String title, String subtitle, CountryTheme theme, BuildContext context) {
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
            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold)),
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

class _FicoGaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final String label;
  final bool isDark;

  _FicoGaugePainter({
    required this.score,
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.height - 15;

    // Background track arc
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF2F8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Active score track arc
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double scorePct = (score - 300) / (850 - 300);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * scorePct,
      false,
      activePaint,
    );

    // Needle drawing
    final double angle = pi + (pi * scorePct);
    final needleLen = radius - 8;
    final needleTarget = Offset(
      center.dx + needleLen * cos(angle),
      center.dy + needleLen * sin(angle),
    );

    final needlePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0B1D3A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTarget, needlePaint);

    // Pin center circle
    final pinPaint = Paint()..color = isDark ? Colors.white : const Color(0xFF0B1D3A);
    canvas.drawCircle(center, 6, pinPaint);

    // Value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toInt().toString(),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 32),
    );

    // Rating Label text
    final labelPainter = TextPainter(
      text: TextSpan(
        text: '$label Credit',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white60 : const Color(0xFF4A5C7A),
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - 12),
    );
  }

  @override
  bool shouldRepaint(covariant _FicoGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color || oldDelegate.label != label || oldDelegate.isDark != isDark;
  }
}


