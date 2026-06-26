// lib/features/india/tools/in_cibil_score_impact.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INCIBILScoreImpact extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INCIBILScoreImpact({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INCIBILScoreImpact> createState() => _INCIBILScoreImpactState();
}

class _INCIBILScoreImpactState extends ConsumerState<INCIBILScoreImpact> {
  double _score = 750.0;
  bool _calculated = false;
  String _selBureau = 'CIBIL';
  late TextEditingController _scoreCtrl;

  final Map<int, _ScoreInfo> _scoreData = {
    300: _ScoreInfo(
        zone: '❌ Poor – Likely Rejected',
        rate: 10.75,
        maxLoan: 0,
        color: const Color(0xFFEF4444)),
    600: _ScoreInfo(
        zone: '⚠️ Fair – High Interest Rate',
        rate: 10.00,
        maxLoan: 30,
        color: const Color(0xFFF59E0B)),
    650: _ScoreInfo(
        zone: '⚠️ Fair – Above Average Rate',
        rate: 9.75,
        maxLoan: 40,
        color: const Color(0xFFF59E0B)),
    700: _ScoreInfo(
        zone: '✓ Good – Standard Rate',
        rate: 9.25,
        maxLoan: 55,
        color: const Color(0xFF86EFAC)),
    750: _ScoreInfo(
        zone: '✅ Excellent – Best Rates',
        rate: 8.50,
        maxLoan: 75,
        color: const Color(0xFF22C55E)),
    800: _ScoreInfo(
        zone: '🏆 Exceptional – Best Rate',
        rate: 8.25,
        maxLoan: 90,
        color: const Color(0xFF047857)),
    850: _ScoreInfo(
        zone: '🏆 Exceptional – Best Rate',
        rate: 8.25,
        maxLoan: 90,
        color: const Color(0xFF047857)),
    900: _ScoreInfo(
        zone: '🏆 Exceptional – Lowest Rate',
        rate: 8.10,
        maxLoan: 100,
        color: const Color(0xFF047857)),
  };

  _ScoreInfo _getScoreInfo(int score) {
    final keys = [300, 600, 650, 700, 750, 800, 850, 900];
    for (int i = keys.length - 1; i >= 0; i--) {
      if (score >= keys[i]) {
        return _scoreData[keys[i]]!;
      }
    }
    return _scoreData[300]!;
  }

  double _calcEMI(double p, double ratePercent, int months) {
    if (ratePercent <= 0) return 0;
    final r = ratePercent / (12 * 100);
    return p * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} Lakh';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  @override
  void initState() {
    super.initState();
    _scoreCtrl = TextEditingController(text: _score.toInt().toString());
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _score = 750.0;
      _calculated = false;
      _selBureau = 'CIBIL';
      _scoreCtrl.text = '750';
    });
  }

  void _saveCalculation() async {
    final scoreInt = _score.toInt();
    final info = _getScoreInfo(scoreInt);
    final emi = _calcEMI(5000000, info.rate, 240);
    final basEmi = _calcEMI(5000000, 9.75, 240);
    final savings = (basEmi - emi) * 240;

    final labelCtrl = TextEditingController(text: 'CIBIL Score Impact');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save CIBIL Score Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Score $scoreInt (${info.rate}% Rate) · EMI ${_fmt(emi)}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My CIBIL 2025)',
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
              backgroundColor: const Color(0xFFE05F00),
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
          : 'CIBIL Score Analysis';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'CIBIL Score Impact',
        inputs: {
          'score': _score,
        },
        results: {
          'rate': info.rate,
          'emi': emi,
          'maxLoan': info.maxLoan.toDouble() * 100000,
          'savings': savings,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Analysis saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
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

    final scoreInt = _score.toInt();
    final info = _getScoreInfo(scoreInt);

    // Calculate Personalised Loan Impact
    final emi = _calcEMI(5000000, info.rate, 240);
    final basEmi = _calcEMI(5000000, 9.75, 240);
    final savingsLakhs = ((basEmi - emi) * 240) / 100000;
    final savingsText = savingsLakhs > 0
        ? '${savingsLakhs.toStringAsFixed(1)} Lakh'
        : '0 (Base Rate)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score Meter Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Credit Bureau Analyser',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFE05F00),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bureau Selector Tabs
              Row(
                children: ['CIBIL', 'Experian', 'Equifax', 'CRIF'].map((b) {
                  final active = _selBureau == b;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selBureau = b),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFF6B00)
                              : Colors.transparent,
                          border: Border.all(
                              color: active
                                  ? const Color(0xFFFF6B00)
                                  : theme.getBorderColor(context)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(b,
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                weight: FontWeight.w800,
                                color: active
                                    ? Colors.white
                                    : theme.getTextColor(context))),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Gauge Widget
              Center(
                child: SizedBox(
                  width: 220,
                  height: 120,
                  child: CustomPaint(
                    painter: _CibilGaugePainter(score: _score),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Score display values
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _scoreCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.playfair(
                            size: 42,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v) ?? 0;
                          if (parsed >= 300 && parsed <= 900) {
                            setState(() {
                              _score = parsed;
                            });
                          }
                        },
                      ),
                    ),
                    Text(
                      'CIBIL SCORE',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.zone,
                      style: AppTextStyles.dmSans(
                          size: 13, color: info.color, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Score Slider
              Slider(
                value: _score,
                min: 300,
                max: 900,
                divisions: 120, // 5 point steps
                activeColor: info.color,
                inactiveColor: info.color.withValues(alpha: 0.15),
                onChanged: (val) {
                  setState(() {
                    _score = val;
                    _scoreCtrl.text = val.toInt().toString();
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('300 (Poor)',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                    Text('900 (Exceptional)',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _calculated = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE05F00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('☸ Calculate Loan Impact',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Personalized Results Hero Box
        if (_calculated) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF046A38), Color(0xFF07543A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
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
                Text('YOUR PERSONALISED LOAN IMPACT',
                    style: AppTextStyles.dmSans(
                        size: 9,
                        color: Colors.white60,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _resBox('Your Score', '$scoreInt', 'Standard Band'),
                    const SizedBox(width: 8),
                    _resBox('Interest Rate', '${info.rate}%', 'Floating p.a.'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _resBox(
                        'Monthly EMI',
                        NumberFormat.currency(
                                locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                            .format(emi),
                        '₹50L · 20yr'),
                    const SizedBox(width: 8),
                    _resBox(
                        'Max Loan',
                        info.maxLoan > 0 ? '₹${info.maxLoan}L' : 'Ineligible',
                        'Based on Score'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Interest Savings vs. Score 650',
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: Colors.white60,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('₹$savingsText',
                                style: AppTextStyles.dmSans(
                                    size: 20,
                                    color: const Color(0xFFFFDEA0),
                                    weight: FontWeight.w800)),
                            Text('Over 20-year loan tenure of ₹50 Lakhs',
                                style: AppTextStyles.dmSans(
                                    size: 9, color: Colors.white70)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Score Band Pricing Card
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
              Text('How Banks Price Your Score',
                  style: AppTextStyles.playfair(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              _scoreBandRow(scoreInt, 300, 599, 'Poor · High Risk', '10.50%+',
                  'or Rejected', const Color(0xFFEF4444), '❌ Refused', context),
              _scoreBandRow(
                  scoreInt,
                  600,
                  699,
                  'Fair · Moderate Risk',
                  '9.75–10.50%',
                  'Higher premium',
                  const Color(0xFFF59E0B),
                  '⚠️ High Rate',
                  context),
              _scoreBandRow(
                  scoreInt,
                  700,
                  749,
                  'Good · Low-Moderate',
                  '9.00–9.75%',
                  'Standard offer',
                  const Color(0xFF86EFAC),
                  '✓ Eligible',
                  context),
              _scoreBandRow(
                  scoreInt,
                  750,
                  799,
                  'Very Good · Low Risk',
                  '8.50–9.00%',
                  'Preferred rate',
                  const Color(0xFF22C55E),
                  '⭐ Preferred',
                  context),
              _scoreBandRow(
                  scoreInt,
                  800,
                  900,
                  'Exceptional · Best Rate',
                  '8.25–8.50%',
                  'Best available',
                  const Color(0xFF047857),
                  '🏆 Best Rate',
                  context),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // EMI Comparison Bars (Visually matching HTML)
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
              Text('📊 EMI Comparison Across Score Bands',
                  style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              Text('(Based on ₹50L · 20yr loan)',
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 20),
              SizedBox(
                height: 130,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _barCol('≤599', 60490, 100, const Color(0xFFEF4444),
                        scoreInt < 600),
                    _barCol('600–699', 52160, 86, const Color(0xFFF59E0B),
                        scoreInt >= 600 && scoreInt < 700),
                    _barCol('700–749', 47048, 68, const Color(0xFF22C55E),
                        scoreInt >= 700 && scoreInt < 750),
                    _barCol('750–799', 43391, 55, const Color(0xFFFF6B00),
                        scoreInt >= 750 && scoreInt < 800),
                    _barCol('800–900', 42130, 48, const Color(0xFF047857),
                        scoreInt >= 800),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : const Color(0xFFFFFAF2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Lower EMI = More savings. Score 750 saves ₹8.77 Lakhs vs Score 650 over 20 years.',
                  style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: theme.getMutedColor(context),
                      height: 1.35),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CIBIL Improvement Tips
        Text('How to Improve Your CIBIL Score',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: [
            _tipCard(
                '💳',
                'Pay EMIs & Credit Card on Time',
                'Payment history is 35% of your CIBIL score. Even one missed payment can drop your score by 50–70 points. Set auto-debit mandates.',
                context),
            _tipCard(
                '📉',
                'Keep Credit Utilisation Below 30%',
                'If your credit limit is ₹1L, keep usage below ₹30,000. High utilisation signals credit hunger. CIBIL weighs this at 30%.',
                context),
            _tipCard(
                '🚫',
                'Avoid Multiple Loan Applications',
                'Each hard inquiry reduces your score by 5–10 points. Space applications 6 months apart. Comparison portals use soft checks — safe to use.',
                context),
            _tipCard(
                '📋',
                'Check Your CIBIL Report for Errors',
                '1 in 5 credit reports has errors. Get your free annual report at mycibil.com. Dispute wrong entries — they must be resolved within 30 days.',
                context),
            _tipCard(
                '⏳',
                'Maintain Old Credit Accounts',
                'Length of credit history counts 15% in the score. Keep your oldest credit card active. Closing old accounts reduces average credit age.',
                context),
          ],
        ),

        const SizedBox(height: 20),

        // Save Calculation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save This Analysis',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF07543A))),
                    Text('Keep a record of your score impact',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF046A38))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white,
                        weight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resBox(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTextStyles.dmSans(
                    size: 14, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 1),
            Text(sub,
                style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _scoreBandRow(
      int currentScore,
      int minScore,
      int maxScore,
      String title,
      String rateRange,
      String rateSub,
      Color barColor,
      String badgeText,
      BuildContext context) {
    final active = currentScore >= minScore && currentScore <= maxScore;
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: active
            ? (isDark
                ? theme.primaryColor.withValues(alpha: 0.15)
                : const Color(0xFFFFFAF2))
            : Colors.transparent,
        border: Border.all(
            color: active ? theme.getBorderColor(context) : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
                color: barColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$minScore – $maxScore',
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 9, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rateRange,
                  style: AppTextStyles.dmSans(
                      size: 11.5, weight: FontWeight.w800, color: barColor)),
              Text(rateSub,
                  style: AppTextStyles.dmSans(
                      size: 8, color: theme.getMutedColor(context))),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.dmSans(
                      size: 7.5, weight: FontWeight.w800, color: barColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barCol(
      String label, int val, int pctHeight, Color color, bool isActive) {
    final theme = widget.theme;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '₹${(val / 1000).toStringAsFixed(1)}k',
            style: AppTextStyles.dmSans(
                size: 8,
                weight: isActive ? FontWeight.w900 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFFE05F00)
                    : theme.getTextColor(context)),
          ),
          const SizedBox(height: 4),
          Container(
            height: pctHeight * 0.8,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, -2))
                    ]
                  : null,
            ),
            child: isActive
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('You',
                          style: AppTextStyles.dmSans(
                              size: 7, weight: FontWeight.w900, color: color)),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.dmSans(
                size: 8,
                weight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFFE05F00)
                    : theme.getMutedColor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tipCard(
      String icon, String title, String desc, BuildContext context) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: theme.getMutedColor(context),
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreInfo {
  final String zone;
  final double rate;
  final int maxLoan;
  final Color color;

  _ScoreInfo({
    required this.zone,
    required this.rate,
    required this.maxLoan,
    required this.color,
  });
}

class _CibilGaugePainter extends CustomPainter {
  final double score;
  _CibilGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 15;

    // Track arc paint
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    // Colored arc segments
    // Total score range: 300 to 900 (span of 600)
    // 300 to 600 is 300 points (50% of arc) -> pi * 0.5 sweep
    // 600 to 750 is 150 points (25% of arc) -> pi * 0.25 sweep
    // 750 to 800 is 50 points (8.33% of arc) -> pi * 0.0833 sweep
    // 800 to 900 is 100 points (16.67% of arc) -> pi * 0.1667 sweep

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Red Segment (300 to 600)
    canvas.drawArc(
      arcRect,
      pi,
      pi * 0.5,
      false,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Orange Segment (600 to 750)
    canvas.drawArc(
      arcRect,
      pi + pi * 0.5,
      pi * 0.25,
      false,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Light Green Segment (750 to 800)
    canvas.drawArc(
      arcRect,
      pi + pi * 0.75,
      pi * 0.0833,
      false,
      Paint()
        ..color = const Color(0xFF86EFAC)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Green Segment (800 to 900)
    canvas.drawArc(
      arcRect,
      pi + pi * (0.75 + 0.0833),
      pi * 0.1667,
      false,
      Paint()
        ..color = const Color(0xFF22C55E)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round, // round at the right end
    );

    // Draw Needle
    // Map score 300 -> angle pi, 900 -> angle 2*pi
    final pct = ((score - 300) / 600.0).clamp(0.0, 1.0);
    final needleAngle = pi + pi * pct;

    final needleLen = radius - 15;
    final needleEnd = Offset(
      center.dx + needleLen * cos(needleAngle),
      center.dy + needleLen * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, centerPaint);

    // Draw a small white indicator inside the center circle
    canvas.drawCircle(center, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CibilGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
