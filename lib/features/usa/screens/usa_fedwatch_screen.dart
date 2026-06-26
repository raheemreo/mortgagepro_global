// lib/features/usa/screens/usa_fedwatch_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

class USAFedWatchScreen extends ConsumerStatefulWidget {
  const USAFedWatchScreen({super.key});

  @override
  ConsumerState<USAFedWatchScreen> createState() => _USAFedWatchScreenState();
}

class _USAFedWatchScreenState extends ConsumerState<USAFedWatchScreen> {
  static const _theme = CountryThemes.usa;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    final fedFundsAsync = ref.watch(fredFedFundsProvider);
    final rawFedFunds = fedFundsAsync.valueOrNull?.value ?? 5.33;
    final liveFundsStr = '${rawFedFunds.toStringAsFixed(2)}%';

    return Scaffold(
      backgroundColor: bgCol,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('⚠️', style: TextStyle(fontSize: 16)),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFB91C1C)],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text(
                            'FedWatch Tool',
                            style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800),
                          ),
                          Text(
                            'CME Group · FOMC Meeting Probabilities · 2026',
                            style: AppTextStyles.dmSans(size: 9, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Rate Strip
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1D3A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _stripCell('Current', liveFundsStr, 'Fed Funds', const Color(0xFFFCD34D))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Jun Cut?', '~22%', 'Probability', const Color(0xFFFCA5A5))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Hold Prob', '~78%', 'Jun 17–18', const Color(0xFF6EE7B7))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Year-End', '4.00%', 'Mkt Implied', Colors.white)),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Next Meeting Odds Title
                    _buildSectionHeader('Next Meeting Odds', isLive: true),
                    const SizedBox(height: 8),

                    // Hero Probability Card
                    _buildHeroProbabilityCard(isDark),
                    const SizedBox(height: 20),

                    // Probability History Chart
                    _buildSectionHeader('Probability History — Jun Meeting'),
                    const SizedBox(height: 8),
                    _buildChartCard(isDark, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 20),

                    // 2025/2026 Meetings List
                    _buildSectionHeader('2026 FOMC Meeting Probabilities'),
                    const SizedBox(height: 8),
                    _buildMeetingsList(isDark, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 20),

                    // Market Implied Year-End Rate
                    _buildSectionHeader('Market Implied Year-End Rate'),
                    const SizedBox(height: 8),
                    _buildImpliedYearEndCard(isDark),
                    const SizedBox(height: 20),

                    // Terminal Rate
                    _buildSectionHeader('Terminal Rate Projections'),
                    const SizedBox(height: 8),
                    _buildTerminalRateCard(isDark, cardBg, textCol, mutedCol, borderCol),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 1,
              activeColor: _theme.primaryColor,
              countryIcon: _theme.flag,
              countryLabel: 'USA',
              countryRoute: '/usa',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stripVDivider() => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.14));

  Widget _stripCell(String label, String value, String note, Color valColor) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: valColor)),
        Text(note,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.38))),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool isLive = false, String? tagText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w800,
            color: _theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        if (isLive)
          Row(
            children: [
              _liveDot(),
              const SizedBox(width: 4),
              Text(
                'CME Live',
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: _theme.primaryColor),
              ),
            ],
          ),
        if (tagText != null)
          Text(
            tagText,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: _theme.primaryColor),
          ),
      ],
    );
  }

  Widget _liveDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeroProbabilityCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB91C1C).withValues(alpha: 0.14),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jun 17–18, 2026 · FOMC Meeting 4 + SEP Update',
                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '78%',
                    style: AppTextStyles.playfair(size: 54, weight: FontWeight.w800, color: const Color(0xFFFCD34D)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⏸ HOLD',
                          style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.22),
                            border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.38)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Hold: 4.25–4.50%',
                            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: const Color(0xFFFCD34D)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cut: 22% · Hike: <1% · CME FedWatch',
                          style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Gauge
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFFCD34D)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
                children: [
                  _hpBox('Hold', '78%', const Color(0xFFFCD34D)),
                  _hpBox('-25 bps Cut', '21%', const Color(0xFF6EE7B7)),
                  _hpBox('-50 bps Cut', '1%', const Color(0xFF6EE7B7)),
                  _hpBox('Hike', '<1%', const Color(0xFFFCA5A5)),
                  _hpBox('SEP Release', 'Yes', Colors.white),
                  _hpBox('Updated', 'Jun 16', Colors.white),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hpBox(String label, String value, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: valColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cut Probability Trend — Jun 17–18 Meeting',
                style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
              ),
              Text(
                'CME FedWatch',
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w500, color: _theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '30-day rolling probability of ≥25bps rate cut at June FOMC',
            style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _FedWatchChartPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsList(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Column(
      children: [
        _meetCard(
          date: 'Jun 17–18, 2026',
          badgeText: 'NEXT · SEP',
          badgeColor: const Color(0xFFDCFCE7),
          badgeTxtColor: const Color(0xFF15803D),
          subtitle: 'Meeting 4 · SEP + Dot Plot Released · Fed Chair Press Conference',
          probs: const [
            _MeetingProbRow(label: 'Hold', pct: 78, bps: '4.25–4.50%', color: Color(0xFFD97706)),
            _MeetingProbRow(label: '-25bps', pct: 21, bps: '4.00–4.25%', color: Color(0xFF15803D)),
            _MeetingProbRow(label: '-50bps', pct: 1, bps: '3.75–4.00%', color: Color(0xFF15803D)),
          ],
          cardBg: cardBg,
          textCol: textCol,
          mutedCol: mutedCol,
          borderCol: borderCol,
        ),
        _meetCard(
          date: 'Jul 29–30, 2026',
          badgeText: 'No SEP',
          badgeColor: const Color(0xFFFFF7ED),
          badgeTxtColor: const Color(0xFFC2410C),
          subtitle: 'Meeting 5 · No Summary of Economic Projections',
          probs: const [
            _MeetingProbRow(label: 'Hold', pct: 52, bps: '4.25–4.50%', color: Color(0xFFD97706)),
            _MeetingProbRow(label: '-25bps', pct: 38, bps: '4.00–4.25%', color: Color(0xFF15803D)),
            _MeetingProbRow(label: '-50bps', pct: 10, bps: '3.75–4.00%', color: Color(0xFF15803D)),
          ],
          cardBg: cardBg,
          textCol: textCol,
          mutedCol: mutedCol,
          borderCol: borderCol,
        ),
        _meetCard(
          date: 'Sep 16–17, 2026',
          badgeText: 'SEP',
          badgeColor: const Color(0xFFEFF6FF),
          badgeTxtColor: const Color(0xFF1D4ED8),
          subtitle: 'Meeting 6 · SEP Released · Most likely first cut window per analysts',
          probs: const [
            _MeetingProbRow(label: 'Hold', pct: 28, bps: '4.25–4.50%', color: Color(0xFFD97706)),
            _MeetingProbRow(label: '-25bps', pct: 50, bps: '4.00–4.25%', color: Color(0xFF15803D)),
            _MeetingProbRow(label: '-50bps', pct: 22, bps: '3.75–4.00%', color: Color(0xFF15803D)),
          ],
          cardBg: cardBg,
          textCol: textCol,
          mutedCol: mutedCol,
          borderCol: borderCol,
        ),
        _meetCard(
          date: 'Oct 28–29, 2026',
          badgeText: 'No SEP',
          badgeColor: const Color(0xFFFFF7ED),
          badgeTxtColor: const Color(0xFFC2410C),
          subtitle: 'Meeting 7 · No SEP · Pre-election meeting',
          probs: const [
            _MeetingProbRow(label: 'Hold', pct: 22, bps: '4.00–4.25%', color: Color(0xFFD97706)),
            _MeetingProbRow(label: '-25bps', pct: 58, bps: '3.75–4.00%', color: Color(0xFF15803D)),
            _MeetingProbRow(label: '-50bps+', pct: 20, bps: '≤3.75%', color: Color(0xFF15803D)),
          ],
          cardBg: cardBg,
          textCol: textCol,
          mutedCol: mutedCol,
          borderCol: borderCol,
        ),
        _meetCard(
          date: 'Dec 9–10, 2026',
          badgeText: 'SEP',
          badgeColor: const Color(0xFFEFF6FF),
          badgeTxtColor: const Color(0xFF1D4ED8),
          subtitle: 'Meeting 8 · Year-End SEP · 2026 projections released',
          probs: const [
            _MeetingProbRow(label: 'Hold', pct: 12, bps: '4.00%+', color: Color(0xFFD97706)),
            _MeetingProbRow(label: '-25bps', pct: 55, bps: '3.75–4.00%', color: Color(0xFF15803D)),
            _MeetingProbRow(label: '-50bps+', pct: 33, bps: '≤3.75%', color: Color(0xFF15803D)),
          ],
          cardBg: cardBg,
          textCol: textCol,
          mutedCol: mutedCol,
          borderCol: borderCol,
        ),
      ],
    );
  }

  Widget _meetCard({
    required String date,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTxtColor,
    required String subtitle,
    required List<_MeetingProbRow> probs,
    required Color cardBg,
    required Color textCol,
    required Color mutedCol,
    required Color borderCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 $date',
                style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: badgeTxtColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.dmSans(size: 9, color: mutedCol),
          ),
          const SizedBox(height: 12),
          ...probs.map((p) {
            final isHold = p.label == 'Hold';
            final barGrad = isHold
                ? const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFFCD34D)])
                : const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      p.label,
                      style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.w700,
                        color: isHold ? const Color(0xFFD97706) : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: p.pct / 100.0,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: barGrad,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${p.pct}%',
                      style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 54,
                    child: Text(
                      p.bps,
                      style: AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImpliedYearEndCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cumulative Rate Projections — 2026',
            style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            'Fed Funds Futures implied rate by meeting · CME Group',
            style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _cumCol('Jun \'26', '4.25%', '0–1 cut')),
              Expanded(child: _cumCol('Sep \'26', '4.00%', '1–2 cuts')),
              Expanded(child: _cumCol('Oct \'26', '3.85%', '2 cuts')),
              Expanded(child: _cumCol('Dec \'26', '3.75%', '2–3 cuts')),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white.withValues(alpha: 0.10),
          ),
          Text(
            'Source: CME FedWatch · Fed Funds Futures · Updated Jun 16, 2025',
            style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.40)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _cumCol(String meeting, String rate, String cuts) {
    return Column(
      children: [
        Text(
          meeting.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.50), weight: FontWeight.w700, letterSpacing: 0.4),
        ),
        const SizedBox(height: 6),
        Text(
          rate,
          style: AppTextStyles.playfair(size: 17, weight: FontWeight.w800, color: const Color(0xFFFCD34D)),
        ),
        const SizedBox(height: 2),
        Text(
          cuts,
          style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.45)),
        ),
      ],
    );
  }

  Widget _buildTerminalRateCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📉 Where Markets See Rates Landing',
            style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
          ),
          const SizedBox(height: 12),
          _terminalRow('End 2025', 0.52, '3.75%', const [Color(0xFF1B3F72), Color(0xFF0B1D3A)], textCol, mutedCol),
          _terminalRow('End 2026', 0.45, '3.25%', const [Color(0xFFD97706), Color(0xFFB45309)], textCol, mutedCol),
          _terminalRow('FOMC Median', 0.54, '3.88%', const [Color(0xFFB91C1C), Color(0xFF991B1B)], textCol, mutedCol),
          _terminalRow('Neutral Rate', 0.42, '3.00%', const [Color(0xFF0F766E), Color(0xFF0D9488)], textCol, mutedCol),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: borderCol,
          ),
          Center(
            child: Text(
              'Fed Funds Futures · OIS Swaps · CME FedWatch · Jun 16, 2025',
              style: AppTextStyles.dmSans(size: 9, color: mutedCol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalRow(String label, double scale, String value, List<Color> barColors, Color textCol, Color mutedCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: mutedCol),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: barColors),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              value,
              style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingProbRow {
  final String label;
  final int pct;
  final String bps;
  final Color color;

  const _MeetingProbRow({required this.label, required this.pct, required this.bps, required this.color});
}

class _FedWatchChartPainter extends CustomPainter {
  final bool isDark;
  const _FedWatchChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (final yFrac in [0.166, 0.416, 0.666, 0.916]) {
      final y = h * yFrac;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Y Labels
    final labelStyle = TextStyle(
      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
      fontSize: 8,
    );
    const yLabels = ['80%', '60%', '40%', '20%'];
    final yPositions = [0.166, 0.416, 0.666, 0.916];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, h * yPositions[i] - 10));
    }

    // Coordinates points
    // p = [68.0, 76.7, 72.0, 63.3, 53.3, 48.0, 43.3, 38.7, 33.3, 22.0]
    // X indices are spaced evenly from left to right.
    final rawPoints = [68.0, 76.7, 72.0, 63.3, 53.3, 48.0, 43.3, 38.7, 33.3, 22.0];
    final n = rawPoints.length;

    // Scale function
    double scaleX(int index) {
      final start = w * 0.08;
      final end = w * 1.0;
      return start + (index / (n - 1)) * (end - start);
    }

    double scaleY(double pct) {
      // 20% to 80% maps from yFrac 0.916 to 0.166
      // yield equation: yFrac = 0.916 - ((pct - 20) / 60) * 0.75
      final yFrac = 0.916 - ((pct - 20) / 60.0) * 0.75;
      return h * yFrac;
    }

    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      pts.add(Offset(scaleX(i), scaleY(rawPoints[i])));
    }

    // Area fill
    final gradientRect = Rect.fromLTWH(0, 0, w, h);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF15803D).withValues(alpha: 0.30),
          const Color(0xFF15803D).withValues(alpha: 0.02),
        ],
      ).createShader(gradientRect);

    final fillPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(pts.last.dx, h * 0.916);
    fillPath.lineTo(pts.first.dx, h * 0.916);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Current dot
    final dotPt = pts.last;
    canvas.drawCircle(dotPt, 9, Paint()..color = const Color(0xFF15803D).withValues(alpha: 0.40));
    canvas.drawCircle(dotPt, 5, Paint()..color = const Color(0xFF15803D));

    // Annotation
    final tp = TextPainter(
      text: const TextSpan(
        text: '22%',
        style: TextStyle(color: Color(0xFF15803D), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pts[n - 2].dx - 10, pts[n - 2].dy - 12));

    // X Labels
    final xLabels = [
      ('May 7', 0),
      ('May 15', 2),
      ('May 22', 4),
      ('Jun 1', 7),
      ('Jun 16', 9),
    ];
    for (final xl in xLabels) {
      final textTp = TextPainter(
        text: TextSpan(text: xl.$1, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textTp.paint(canvas, Offset(scaleX(xl.$2) - textTp.width / 2, h - 12));
    }
  }

  @override
  bool shouldRepaint(covariant _FedWatchChartPainter old) => old.isDark != isDark;
}
