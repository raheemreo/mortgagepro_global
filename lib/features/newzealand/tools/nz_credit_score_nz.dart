// lib/features/newzealand/tools/nz_credit_score_nz.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZCreditScoreNZ extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZCreditScoreNZ({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZCreditScoreNZ> createState() => _NZCreditScoreNZState();
}

class _NZCreditScoreNZState extends ConsumerState<NZCreditScoreNZ> {
  double _score = 720.0;

  final List<Map<String, dynamic>> _insights = [
    {
      'max': 299.0,
      'band': 'Poor',
      'color': const Color(0xFFEF4444),
      'title': '⚠️ Poor Credit — Approval Very Difficult',
      'text': "A score below 300 will be declined by all major NZ banks. You may qualify with specialist lenders at rates of 12–20%+. Focus on clearing defaults and paying all bills on time for 12 months before applying."
    },
    {
      'max': 499.0,
      'band': 'Fair',
      'color': const Color(0xFFF59E0B),
      'title': '📋 Fair Credit — Limited Options',
      'text': "Scores 300–499 mean major banks will likely decline. Non-bank lenders like Liberty, Resimac or Pepper Money may approve at higher rates. Work on clearing outstanding defaults first."
    },
    {
      'max': 699.0,
      'band': 'Good',
      'color': const Color(0xFF3B82F6),
      'title': '✅ Good Credit — Lenders Will Approve',
      'text': "Scores 500–699 qualify for standard home loan rates at most NZ banks. ANZ, ASB, BNZ and Westpac should approve at advertised rates. You may face slightly higher rates than 800+ borrowers."
    },
    {
      'max': 799.0,
      'band': 'Very Good',
      'color': const Color(0xFF10B981),
      'title': '🌟 Very Good Credit — Competitive Rates',
      'text': "Scores 700–799 put you in a strong position. All major NZ banks will approve. You may negotiate slightly below advertised rates, especially with a mortgage broker."
    },
    {
      'max': 1000.0,
      'band': 'Excellent',
      'color': const Color(0xFF047857),
      'title': '🏆 Excellent Credit — Best Rates & Terms',
      'text': "A score of 800+ is top tier. You'll qualify for the best mortgage rates, highest borrowing limits, and have significant negotiating power with NZ banks. Well done!"
    },
  ];

  Map<String, dynamic> _getInsight(double score) {
    for (var ins in _insights) {
      if (score <= ins['max']) {
        return ins;
      }
    }
    return _insights.last;
  }

  void _saveCalculation() async {
    final ins = _getInsight(_score);
    final labelCtrl = TextEditingController(text: 'NZ Credit Score Simulator');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Score Simulation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${_score.round()} · Band: ${ins['band']}',
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
                hintText: 'Label (e.g. My Credit Goal)',
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
              backgroundColor: const Color(0xFF1A6B4A),
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
          : 'Credit Score NZ';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Credit Score Simulator',
        inputs: {
          'score': _score,
        },
        results: {
          'bandIndex': _insights.indexOf(ins).toDouble(),
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Credit score simulation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ins = _getInsight(_score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Credit Score Simulator',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('💡 Free credit checks available annually at Equifax NZ, Centrix, and illion.',
                        style: AppTextStyles.dmSans(color: Colors.white, size: 11)),
                    backgroundColor: const Color(0xFF0D3B2E),
                  ),
                );
              },
              child: Text(
                'Check Free →',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: theme.primaryColor,
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Score Hero (Gauge)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CREDIT SCORE SIMULATOR · EQUIFAX NZ SCALE',
                  style: AppTextStyles.dmSans(
                    size: 8,
                    color: Colors.white70,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: 'Understand Your ',
                    style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: Colors.white),
                    children: [
                      TextSpan(
                        text: 'Credit Rating',
                        style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: const Color(0xFFF5D060)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Half-dial Gauge
              SizedBox(
                height: 120,
                width: 220,
                child: CustomPaint(
                  painter: _NZCreditScoreGaugePainter(
                    score: _score,
                    bandColor: ins['color'],
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_score.round()}',
                          style: AppTextStyles.playfair(
                            size: 38,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Equifax NZ Score (out of 1,000)',
                          style: AppTextStyles.dmSans(
                            size: 9,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: ins['color'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ins['band'],
                            style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Slider Card
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
              Text(
                '🎛️ Adjust Your Score',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credit Score',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  Text(
                    '${_score.round()}',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Slider(
                value: _score,
                min: 0,
                max: 1000,
                activeColor: theme.primaryColor,
                inactiveColor: const Color(0xFFE8F0EC),
                onChanged: (val) => setState(() => _score = val),
              ),
              const SizedBox(height: 8),

              // Band scale display
              Row(
                children: [
                  _buildScaleItem('Poor\n0–299', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                  const SizedBox(width: 4),
                  _buildScaleItem('Fair\n300–499', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  _buildScaleItem('Good\n500–699', const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  _buildScaleItem('V.Good\n700–799', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
                  const SizedBox(width: 4),
                  _buildScaleItem('Exc.\n800-1000', const Color(0xFFECFDF5), const Color(0xFF047857)),
                ],
              ),
              const SizedBox(height: 14),

              // Dynamic Insight box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ins['title'],
                      style: AppTextStyles.dmSans(
                          size: 11.5,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ins['text'],
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Saved calculation trigger button
        ElevatedButton.icon(
          onPressed: _saveCalculation,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: const Text('💾', style: TextStyle(fontSize: 14)),
          label: Text('Save Score Goal',
              style: AppTextStyles.playfair(
                  size: 13, weight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(height: 20),

        // NZ Credit Bureaus
        Text(
          'NZ Credit Bureaus',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildBureauCard('📊', 'Equifax NZ', 'Score: 0 – 1,000', 'Free annually', true),
            _buildBureauCard('🏦', 'Centrix NZ', 'Score: 0 – 1,000', 'Free check', false),
            _buildBureauCard('📋', 'illion NZ', 'Score: 0 – 1,000', 'Free check', false),
            _buildBureauCard('🔍', 'Your Report', 'Full credit file', 'Free by law', false),
          ],
        ),
        const SizedBox(height: 20),

        // What Affects Your Score
        Text(
          'What Affects Your Score',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildFactorItem('Payment History', '35% impact', 0.35, const Color(0xFF10B981),
                  'Most important. Late or missed payments stay 5 years on file in NZ. One missed utility bill can drop score 50–100 points.'),
              _buildFactorItem('Credit Utilisation', '30% impact', 0.30, const Color(0xFF3B82F6),
                  'Keep card balances below 30% of your limit. Maxed-out cards signal financial stress to bank underwriters.'),
              _buildFactorItem('Length of Credit History', '15% impact', 0.15, const Color(0xFFF59E0B),
                  'Longer history improves score. Don\'t close old accounts — keep them open even if unused to show stability.'),
              _buildFactorItem('Credit Enquiries', '10% impact', 0.10, const Color(0xFFEF4444),
                  'Each hard enquiry (loan application) reduces score by 5–10 points. Multiple rate checks in 14 days group as one.'),
              _buildFactorItem('Credit Mix', '10% impact', 0.10, const Color(0xFF6D28D9),
                  'Having a mix of mortgage, car loan, and card shows you can manage different types responsibly.'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Improve score tips
        Text(
          'Improve Your Score — NZ Tips',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.15,
          children: [
            _buildTipCard('⏰', 'Always Pay On Time', 'Set up auto payments for minimums. Defaults stay 5 years. Judgments stay 7 years on NZ file.'),
            _buildTipCard('💳', 'Reduce Credit Limits', 'Lenders look at total available credit limits, not just balances. Lower card caps before mortgage application.'),
            _buildTipCard('🔍', 'Check for Errors', 'Get your free report. Dispute any errors. Correcting typos can boost score 50–150 points fast.'),
            _buildTipCard('🚫', 'Avoid BNPL Accounts', 'BNPL (Afterpay, Laybuy) counts as active credit commitments in NZ. Major banks deduct them from borrowing capacity.'),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildScaleItem(String text, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.dmSans(
            size: 7.5,
            weight: FontWeight.bold,
            color: textCol,
          ),
        ),
      ),
    );
  }

  Widget _buildBureauCard(String icon, String name, String range, String freeText, bool highlight) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF0D3B2E) : theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color: highlight ? Colors.white : theme.getTextColor(context),
            ),
          ),
          Text(
            range,
            style: AppTextStyles.dmSans(
              size: 9,
              color: highlight ? Colors.white60 : theme.getMutedColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              freeText,
              style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: const Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(String name, String weight, double percent, Color fillCol, String tip) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: AppTextStyles.dmSans(
                      size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  weight,
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w700, color: theme.getMutedColor(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              color: const Color(0xFFF1F5F2),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percent,
                child: Container(color: fillCol),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip,
            style: AppTextStyles.dmSans(
                size: 9, color: theme.getMutedColor(context), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String icon, String title, String desc) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.dmSans(
                size: 10.5, weight: FontWeight.w800, color: theme.getTextColor(context), height: 1.2),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              desc,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: theme.getMutedColor(context), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _NZCreditScoreGaugePainter extends CustomPainter {
  final double score;
  final Color bandColor;

  _NZCreditScoreGaugePainter({required this.score, required this.bandColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    const radius = 90.0;

    // Background track arc
    final bgPaint = Paint()
      ..color = const Color(0xFF1A3328)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Score Fill arc with linear gradient
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFEF4444), // Red
          Color(0xFFF59E0B), // Gold
          Color(0xFF3B82F6), // Blue
          Color(0xFF10B981), // Green
          Color(0xFF047857), // Forest
        ],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 1000.0) * pi;
    canvas.drawArc(
      arcRect,
      pi,
      sweepAngle,
      false,
      fillPaint,
    );

    // Draw needle indicator dot
    final needleAngle = pi + sweepAngle;
    final needleX = center.dx + radius * cos(needleAngle);
    final needleY = center.dy + radius * sin(needleAngle);

    final needlePaint = Paint()
      ..color = const Color(0xFFF5D060)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(needleX, needleY), 6.0, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _NZCreditScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.bandColor != bandColor;
  }
}
