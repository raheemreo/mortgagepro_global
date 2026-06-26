// lib/features/usa/screens/usa_sofr_rate_history_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USASofrRateHistoryScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USASofrRateHistoryScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USASofrRateHistoryScreen> createState() => _USASofrRateHistoryScreenState();
}

class _USASofrRateHistoryScreenState extends ConsumerState<USASofrRateHistoryScreen> {
  static const _theme = CountryThemes.usa;

  // Controllers
  final _sofrAvgController = TextEditingController(text: '3.63');
  final _marginController = TextEditingController(text: '2.50');

  // Outputs
  bool _calculated = false;
  double _estResult = 6.13;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _sofrAvgController.text = (inputs['sofrAvg'] ?? 3.63).toStringAsFixed(2);
      _marginController.text = (inputs['margin'] ?? 2.50).toStringAsFixed(2);
      _calculate();
    } else {
      _calculate();
    }
  }

  @override
  void dispose() {
    _sofrAvgController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  void _calculate() {
    final sofr = double.tryParse(_sofrAvgController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;
    setState(() {
      _estResult = sofr + margin;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;

    final sofr = double.tryParse(_sofrAvgController.text) ?? 0.0;
    final margin = double.tryParse(_marginController.text) ?? 0.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'SOFR Rate History',
      label: 'SOFR average check: ${sofr.toStringAsFixed(2)}% + ${margin.toStringAsFixed(2)}% margin = ${_estResult.toStringAsFixed(2)}%',
      currencyCode: 'USD',
      inputs: {
        'sofrAvg': sofr,
        'margin': margin,
      },
      results: {
        'EstFullyIndexedRate': _estResult,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ SOFR index estimate scenario saved!'),
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
                      const Text('📈', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('SOFR Rate History',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('NY Fed data · The index behind your ARM',
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
                  Expanded(child: _buildStripItem('SOFR Today', '3.63%', 'Jun 17, 2026', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('All-Time High', '5.40%', 'Dec 2023', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Fed Funds Rate', '3.50–3.75%', 'Current Target', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Explanatory Note Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📌 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'SOFR (Secured Overnight Financing Rate) replaced LIBOR as the standard ARM index in 2023. Most ARMs add a fixed "margin" (typically 2.25–2.75%) to SOFR to set your adjusted rate.',
                          style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF1E3A5F), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Current SOFR Index'),

                // Result Hero Card
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CURRENT SOFR (OVERNIGHT)',
                              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('3.63%',
                                  style: AppTextStyles.playfair(size: 32, color: Colors.white, weight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              Text('as of Jun 17, 2026',
                                  style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Down from an all-time high of 5.40% in December 2023.',
                            style: TextStyle(fontSize: 10, color: Colors.white70),
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

                const SizedBox(height: 20),
                _buildSectionHeader('SOFR Trend (2022–2026)'),

                // Chart Card
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
                      Text('📈 Secured Overnight Financing Rate History',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: SofrLineChartPainter(isDark: isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('2022', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('2023', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('2024', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('2025', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('2026', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Breakdown Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                  children: [
                    _buildBreakdownCard('🔺', 'Peak Rate', '5.40%', 'Dec 2023 peak', textCol, mutedCol),
                    _buildBreakdownCard('🔻', '2026 Low', '3.62%', 'Hit in March 2026', textCol, mutedCol),
                    _buildBreakdownCard('📉', 'Decline Since Peak', '-1.77%', 'Dec 2023 → Jun 2026', const Color(0xFF15803D), mutedCol),
                    _buildBreakdownCard('🏦', '2025 Fed Cuts', '-0.75%', 'Sep, Oct, Dec 2025 cuts', const Color(0xFF15803D), mutedCol),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Estimate Your Fully-Indexed Rate'),

                // Estimate input card
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
                      Row(
                        children: [
                          Expanded(child: _buildInputField('30-Day SOFR Average (%)', _sofrAvgController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Your Loan Margin (%)', _marginController, hint: 'Typically 2.25% - 2.75%')),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Result Estimation Panel
                if (_calculated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🧮 Estimated Fully-Indexed ARM Rate',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F), fontFamily: 'Georgia'),
                        ),
                        const SizedBox(height: 10),
                        _buildCompareRow('30-Day SOFR Average', '${double.tryParse(_sofrAvgController.text)?.toStringAsFixed(2) ?? "3.63"}%', const Color(0xFF1E40AF)),
                        _buildCompareRow('+ Your Margin', '${double.tryParse(_marginController.text)?.toStringAsFixed(2) ?? "2.50"}%', const Color(0xFF1E40AF)),
                        _buildCompareRow('= Fully-Indexed Rate', '${_estResult.toStringAsFixed(2)}%', const Color(0xFF1D4ED8), isGold: true),
                        const SizedBox(height: 6),
                        Text(
                          'Subject to your loan\'s caps.',
                          style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('How SOFR Feeds Your ARM'),

                // Mechanics Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔧 The ARM Rate Formula',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF064E3B), fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 10),
                      _buildCompareRow('Index', '30-day SOFR average (most common)', const Color(0xFF065F46)),
                      _buildCompareRow('+ Margin', 'Fixed spread set at origination', const Color(0xFF065F46)),
                      _buildCompareRow('= Fully-Indexed Rate', 'What you\'d pay with no caps', const Color(0xFF065F46)),
                      _buildCompareRow('Capped By', 'Initial / periodic / lifetime caps', const Color(0xFF065F46)),
                      _buildCompareRow('Publication', 'NY Fed, ~8:00 AM ET, business days', const Color(0xFF065F46)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Key SOFR Milestones'),

                // Timeline Card
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
                      Text('🗓️ SOFR Timeline Highlights',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildTimelineRow('2023', 'LIBOR officially retired → SOFR standard', textCol),
                      _buildTimelineRow('Dec 2023', 'All-time SOFR index high: 5.40%', textCol),
                      _buildTimelineRow('Sep–Dec 2024', 'Federal Reserve cuts interest rates (100bps)', textCol),
                      _buildTimelineRow('Sep–Dec 2025', 'Federal Reserve cuts interest rates (75bps)', textCol),
                      _buildTimelineRow('Jun 2026', 'Current index stabilizing around 3.63%', textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer helper note strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'SOFR moves with Federal Reserve policy, but your ARM resets on its own schedule (usually annually) using a published average, not the live overnight rate — so there\'s a lag between Fed decisions and your payment changing.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                    ],
                  ),
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
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
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

  Widget _buildCompareRow(String label, String value, Color textCol, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24, width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600).copyWith(fontFamily: 'Georgia')),
          Text(value, style: AppTextStyles.dmSans(size: 10, color: isGold ? const Color(0xFFD97706) : textCol, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String date, String desc, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context), width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: textCol)),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: textCol), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// Custom Painter to draw SOFR rate history area chart
class SofrLineChartPainter extends CustomPainter {
  final bool isDark;
  const SofrLineChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // SOFR History quarterly points
    final sofrHistory = [
      0.05, 1.20, 4.30, 5.06, 5.31, 5.40,
      5.31, 5.33, 5.56, 4.99, 4.55, 4.52,
      4.54, 3.85, 3.62, 3.63
    ];

    final double W = size.width;
    final double H = size.height;
    const double pad = 12.0;

    final double maxV = sofrHistory.reduce(max) * 1.1;
    const double minV = 0.0;
    final int n = sofrHistory.length;

    Offset toXY(int i, double val) {
      final x = pad + (i / (n - 1)) * (W - pad * 2);
      final y = H - pad - ((val - minV) / (maxV - minV)) * (H - pad * 2);
      return Offset(x, y);
    }

    final path = Path();
    for (int i = 0; i < n; i++) {
      final p = toXY(i, sofrHistory[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // area path
    final areaPath = Path()..addPath(path, Offset.zero);
    final firstP = toXY(0, sofrHistory[0]);
    final lastP = toXY(n - 1, sofrHistory[n - 1]);
    areaPath.lineTo(lastP.dx, H - pad);
    areaPath.lineTo(firstP.dx, H - pad);
    areaPath.close();

    // Draw gradient area
    final Paint areaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x400F766E), Color(0x050F766E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, W, H))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    // Draw bold line
    final Paint linePaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Draw peak point marker (5.56% at index 8)
    final peakXY = toXY(8, 5.56);
    canvas.drawCircle(peakXY, 4.0, Paint()..color = const Color(0xFFB91C1C));
    canvas.drawCircle(peakXY, 2.0, Paint()..color = Colors.white);

    // Draw peak text label
    final TextPainter tpPeak = TextPainter(textDirection: TextDirection.ltr);
    tpPeak.text = const TextSpan(
      text: '5.56%',
      style: TextStyle(color: Color(0xFFB91C1C), fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'DM Sans'),
    );
    tpPeak.layout();
    tpPeak.paint(canvas, Offset(peakXY.dx - tpPeak.width / 2, peakXY.dy - 12));

    // Draw current point marker (3.63% at index 15)
    final curXY = toXY(15, 3.63);
    canvas.drawCircle(curXY, 4.0, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(curXY, 2.0, Paint()..color = Colors.white);

    // Draw current text label
    final TextPainter tpCur = TextPainter(textDirection: TextDirection.ltr);
    tpCur.text = const TextSpan(
      text: '3.63%',
      style: TextStyle(color: Color(0xFFD97706), fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'DM Sans'),
    );
    tpCur.layout();
    tpCur.paint(canvas, Offset(curXY.dx - tpCur.width - 4, curXY.dy - 12));
  }

  @override
  bool shouldRepaint(covariant SofrLineChartPainter oldDelegate) => false;
}
