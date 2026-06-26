// lib/features/usa/screens/usa_fed_funds_rate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../providers/usa_rates_provider.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class _FomcMeeting {
  final String date;
  final String name;
  final String note;
  final _MeetingResult result;
  final bool isPast;
  final bool isNext;
  final bool hasSep;
  const _FomcMeeting({
    required this.date,
    required this.name,
    required this.note,
    required this.result,
    this.isPast = false,
    this.isNext = false,
    this.hasSep = false,
  });
}

enum _MeetingResult { hold, cut, hike, tbd }

const List<_FomcMeeting> _fomcMeetings = [
  _FomcMeeting(
      date: 'Jan 28–29',
      name: 'Meeting 1',
      note: 'No SEP · Rate unchanged · Pause continues',
      result: _MeetingResult.hold,
      isPast: true),
  _FomcMeeting(
      date: 'Mar 18–19',
      name: 'Meeting 2',
      note: 'SEP released · 2 cuts projected 2025 · Dot plot revised',
      result: _MeetingResult.hold,
      isPast: true,
      hasSep: true),
  _FomcMeeting(
      date: 'May 6–7',
      name: 'Meeting 3',
      note: 'No SEP · Tariff uncertainty cited · Unanimous hold',
      result: _MeetingResult.hold,
      isPast: true),
  _FomcMeeting(
      date: 'Jun 17–18',
      name: 'Meeting 4',
      note: 'SEP + dot plot · ~22% cut probability (CME FedWatch)',
      result: _MeetingResult.tbd,
      isNext: true,
      hasSep: true),
  _FomcMeeting(
      date: 'Jul 29–30',
      name: 'Meeting 5',
      note: 'No SEP · ~45% cumulative cut probability',
      result: _MeetingResult.tbd),
  _FomcMeeting(
      date: 'Sep 16–17',
      name: 'Meeting 6',
      note: 'SEP released · Most likely first cut window',
      result: _MeetingResult.tbd,
      hasSep: true),
  _FomcMeeting(
      date: 'Oct 28–29',
      name: 'Meeting 7',
      note: 'No SEP · Pre-election meeting',
      result: _MeetingResult.tbd),
  _FomcMeeting(
      date: 'Dec 9–10',
      name: 'Meeting 8',
      note: 'Year-end SEP · 2026 projections released',
      result: _MeetingResult.tbd,
      hasSep: true),
];

class _RateRow {
  final String label;
  final double widthFactor; // 0.0–1.0
  final Color barColor1;
  final Color barColor2;
  final String value;
  const _RateRow({
    required this.label,
    required this.widthFactor,
    required this.barColor1,
    required this.barColor2,
    required this.value,
  });
}

class _ToolItem {
  final String emoji;
  final String title;
  final String subtitle;
  final _CardVariant variant;
  final String? badge;
  const _ToolItem(this.emoji, this.title, this.subtitle, this.variant,
      {this.badge});
}

enum _CardVariant { light, dark, red, gold, teal }

const List<_ToolItem> _relatedTools = [
  _ToolItem('📉', 'FRED Rate History', 'Full historical data back to 1954',
      _CardVariant.dark,
      badge: 'FEDFUNDS'),
  _ToolItem('🎯', 'FedWatch Tool', 'CME probabilities per meeting',
      _CardVariant.light),
  _ToolItem('📊', 'Yield Curve', '2s10s spread · inversion tracker',
      _CardVariant.red),
  _ToolItem('💵', 'CPI vs Fed Rate', 'Inflation vs policy rate gap',
      _CardVariant.gold),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class USAFedFundsRateScreen extends ConsumerStatefulWidget {
  const USAFedFundsRateScreen({super.key});

  @override
  ConsumerState<USAFedFundsRateScreen> createState() =>
      _USAFedFundsRateScreenState();
}

class _USAFedFundsRateScreenState extends ConsumerState<USAFedFundsRateScreen>
    with SingleTickerProviderStateMixin {
  static const _theme = CountryThemes.usa;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  int _selectedChartTab = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _saveBenchmarkRates() async {
    final labelCtrl = TextEditingController(text: 'US Fed Funds Benchmark');
    final fedRate = ref.read(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
    final primeRate = ref.read(fredPrimeProvider).valueOrNull?.value ?? 8.50;
    final mtgeRate =
        ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    final rate15Val =
        ref.read(fredMortgage15Provider).valueOrNull?.value ?? 6.11;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Benchmark Rates',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Fed Funds ${fedRate.toStringAsFixed(2)}% · Prime ${primeRate.toStringAsFixed(2)}% · 30-Yr Mtge ${mtgeRate.toStringAsFixed(2)}%',
              style: AppTextStyles.dmSans(
                  size: 11, color: _theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: _theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Fed Funds Jun 2025)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: _theme.getBgColor(context),
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
              backgroundColor: _theme.primaryColor,
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
          : 'Fed Funds Benchmark';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Fed Funds Rate',
        inputs: {
          'TargetMin': fedRate - 0.08,
          'TargetMax': fedRate + 0.17,
        },
        results: {
          'FedFunds': fedRate,
          'PrimeRate': primeRate,
          'Mortgage30': mtgeRate,
          'Mortgage15': rate15Val,
          'Treasury10': mtgeRate - 2.35,
          'SavingsAPY': fedRate - 1.13,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Benchmark rates saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: _theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: CustomScrollView(
        slivers: [
          _buildHeader(isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Current Rate ──────────────────────────────────────────
                _sectionLabel('Current Rate', trailing: _liveDot()),
                const SizedBox(height: 8),
                _buildHeroRateCard(isDark),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _saveBenchmarkRates,
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    'Save Benchmark Rates',
                    style: AppTextStyles.dmSans(
                        size: 12, color: Colors.white, weight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _theme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Rate History Chart ────────────────────────────────────
                _sectionLabel('Rate History', trailing: _moreLink('FRED Data')),
                const SizedBox(height: 8),
                _buildRateHistoryChart(isDark),
                const SizedBox(height: 20),

                // ── FOMC 2025 Calendar ───────────────────────────────────
                _sectionLabel('FOMC 2025 Meeting Calendar'),
                const SizedBox(height: 8),
                _buildFomcCalendar(isDark),
                const SizedBox(height: 20),

                // ── SEP Dot Plot ──────────────────────────────────────────
                _sectionLabel('SEP Dot Plot Projections'),
                const SizedBox(height: 8),
                _buildDotPlot(),
                const SizedBox(height: 20),

                // ── Key Rate Comparison ───────────────────────────────────
                _sectionLabel('Key Rate Comparison'),
                const SizedBox(height: 8),
                _buildRateComparison(isDark),
                const SizedBox(height: 20),

                // ── Related Fed Tools ─────────────────────────────────────
                _sectionLabel('Related Fed Tools'),
                const SizedBox(height: 8),
                _buildRelatedTools(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 176,
      pinned: true,
      backgroundColor: const Color(0xFF0B1D3A),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          alignment: Alignment.center,
          child: Text('←',
              style: AppTextStyles.dmSans(size: 18, color: Colors.white)),
        ),
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
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFB91C1C)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 50,
                child: Text('🏛️',
                    style: TextStyle(
                        fontSize: 72,
                        color: Colors.white.withValues(alpha: 0.07))),
              ),
              // Title
              Positioned(
                bottom: 54,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text('🏛️', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text('Fed Funds Rate',
                        style: AppTextStyles.playfair(
                          size: 19,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        )),
                    const SizedBox(height: 2),
                    Text('Federal Reserve · FRED · FOMC 2026',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.52),
                        )),
                  ],
                ),
              ),
              // Rate strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Builder(builder: (context) {
                  final fedRate =
                      ref.watch(fredFedFundsProvider).valueOrNull?.formatted ??
                          '4.33%';
                  final sofrRate =
                      ref.watch(fredSofrProvider).valueOrNull?.formatted ??
                          '4.30%';
                  final primeRate =
                      ref.watch(fredPrimeProvider).valueOrNull?.formatted ??
                          '7.50%';
                  final rawFedRate =
                      ref.watch(fredFedFundsProvider).valueOrNull?.value ??
                          5.33;
                  final ioerRate = '${(rawFedRate + 0.07).toStringAsFixed(2)}%';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: _stripCell('Fed Funds', fedRate,
                                'FOMC Target', const Color(0xFFFCD34D))),
                        _stripVDivider(),
                        Expanded(
                            child: _stripCell(
                                'SOFR', sofrRate, 'Overnight', Colors.white)),
                        _stripVDivider(),
                        Expanded(
                            child: _stripCell('Prime Rate', primeRate,
                                'WSJ Prime', Colors.white)),
                        _stripVDivider(),
                        Expanded(
                            child: _stripCell('IOER', ioerRate,
                                'Interest on Res.', const Color(0xFF6EE7B7))),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stripVDivider() => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.14));

  Widget _stripCell(String label, String value, String note, Color valColor) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8.5,
                color: Colors.white.withValues(alpha: 0.48),
                weight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 15, weight: FontWeight.w800, color: valColor)),
        Text(note,
            style: AppTextStyles.dmSans(
                size: 8, color: Colors.white.withValues(alpha: 0.38))),
      ],
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color: _theme.getMutedColor(context),
              letterSpacing: 1,
            )),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _moreLink(String text) => Text(text,
      style: AppTextStyles.dmSans(
          size: 11, weight: FontWeight.w600, color: _theme.primaryColor));

  Widget _liveDot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _pulseAnim,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text('FRED Live',
            style: AppTextStyles.dmSans(
                size: 11, weight: FontWeight.w600, color: _theme.primaryColor)),
      ],
    );
  }

  // ── Hero Rate Card ─────────────────────────────────────────────────────────
  Widget _buildHeroRateCard(bool isDark) {
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
              offset: const Offset(0, 8)),
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
              Text('FEDERAL OPEN MARKET COMMITTEE · FOMC TARGET RANGE',
                  style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: Colors.white.withValues(alpha: 0.48),
                      weight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final rawFedRate =
                    ref.watch(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
                final targetMin = (rawFedRate - 0.08).toStringAsFixed(2);
                final targetMax = (rawFedRate + 0.17).toStringAsFixed(2);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(targetMin,
                        style: AppTextStyles.dmSans(
                            size: 48,
                            weight: FontWeight.w800,
                            color: const Color(0xFFFCD34D))),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('– $targetMax%',
                          style: AppTextStyles.dmSans(
                              size: 14,
                              weight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.65))),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              // Status pills
              Row(
                children: [
                  _heroPill('⏸ HOLD — No Change', isHold: true),
                  const SizedBox(width: 8),
                  _heroPill('Last: May 7, 2025'),
                ],
              ),
              const SizedBox(height: 14),
              // 3-col info grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
                children: [
                  _heroBox('Peak Rate', '5.25–5.50%',
                      color: const Color(0xFFFCD34D)),
                  _heroBox('Total Cuts', '-100 bps',
                      color: const Color(0xFF6EE7B7)),
                  _heroBox('Since Peak', 'Sep 2024'),
                  _heroBox('Next FOMC', 'Jun 17–18'),
                  _heroBox('Cut Prob.', '~22%', color: const Color(0xFF6EE7B7)),
                  _heroBox('Fed Chair', 'J. Powell'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label, {bool isHold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHold
            ? const Color(0xFFD97706).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: isHold
              ? const Color(0xFFD97706).withValues(alpha: 0.40)
              : Colors.white.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w800,
            color: isHold
                ? const Color(0xFFFCD34D)
                : Colors.white.withValues(alpha: 0.75),
          )),
    );
  }

  Widget _heroBox(String label, String value, {Color? color}) {
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
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.3),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: color ?? Colors.white),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Rate History Chart (SVG-like via Canvas) ───────────────────────────────
  Widget _buildRateHistoryChart(bool isDark) {
    const chartTabs = ['2018–25', '5 Yr', '10 Yr', 'Historical'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Fed Funds Rate — 2018 to 2025',
                    style: AppTextStyles.playfair(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: _theme.getTextColor(context))),
              ),
              Text('FRED · FEDFUNDS',
                  style: AppTextStyles.dmSans(
                      size: 10, color: _theme.primaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Federal Reserve target rate — key hiking & cutting cycles',
              style: AppTextStyles.dmSans(
                  size: 9.5, color: _theme.getMutedColor(context))),
          const SizedBox(height: 12),
          // Chart tabs
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chartTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final isActive = i == _selectedChartTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChartTab = i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0B1D3A)
                          : _theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF0B1D3A)
                            : _theme.getBorderColor(context),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(chartTabs[i],
                        style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : _theme.getMutedColor(context),
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // Chart
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _RateChartPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── FOMC Calendar ──────────────────────────────────────────────────────────
  Widget _buildFomcCalendar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Federal Open Market Committee 2025',
                        style: AppTextStyles.playfair(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 1),
                    Text('8 scheduled meetings · Rate decisions & projections',
                        style: AppTextStyles.dmSans(
                            size: 9,
                            color: Colors.white.withValues(alpha: 0.50))),
                  ],
                ),
              ],
            ),
          ),
          // Meeting rows
          ..._fomcMeetings.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final isLast = i == _fomcMeetings.length - 1;
            return _fomcRow(m, isDark, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _fomcRow(_FomcMeeting m, bool isDark, {bool isLast = false}) {
    Color resultColor;
    String resultText;
    switch (m.result) {
      case _MeetingResult.hold:
        resultColor = const Color(0xFFD97706);
        resultText = 'Hold';
        break;
      case _MeetingResult.cut:
        resultColor = const Color(0xFF15803D);
        resultText = 'Cut';
        break;
      case _MeetingResult.hike:
        resultColor = const Color(0xFFB91C1C);
        resultText = 'Hike';
        break;
      case _MeetingResult.tbd:
        resultColor = const Color(0xFF3D5280);
        resultText = 'TBD';
        break;
    }

    Color? rowBg;
    if (m.isNext) {
      rowBg = isDark ? const Color(0xFF0D2A16) : const Color(0xFFF0FDF4);
    } else if (m.isPast && !isDark) {
      rowBg = null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
      decoration: BoxDecoration(
        color: rowBg,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: _theme.getBorderColor(context), width: 0.8),
              ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(17))
            : null,
      ),
      child: Opacity(
        opacity: (m.isPast && !m.isNext) ? 0.55 : 1.0,
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(m.date,
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w800,
                      color: _theme.getTextColor(context))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.name + (m.hasSep ? ' + SEP' : ''),
                          style: AppTextStyles.dmSans(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: _theme.getTextColor(context))),
                      if (m.isNext) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF14532D)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('NEXT',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF15803D))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(m.note,
                      style: AppTextStyles.dmSans(
                          size: 9, color: _theme.getMutedColor(context))),
                ],
              ),
            ),
            Text(resultText,
                style: AppTextStyles.dmSans(
                    size: 11, weight: FontWeight.w800, color: resultColor)),
          ],
        ),
      ),
    );
  }

  // ── SEP Dot Plot ───────────────────────────────────────────────────────────
  Widget _buildDotPlot() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOMC Median Rate Projections (March 2025 SEP)',
              style: AppTextStyles.playfair(
                  size: 12, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 3),
          Text('Summary of Economic Projections · Federal Reserve',
              style: AppTextStyles.dmSans(
                  size: 9.5, color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _dotCol('2025', '3.9%', '2 cuts · Range 3.75–4.0%')),
              Expanded(child: _dotCol('2026', '3.4%', '2 more cuts')),
              Expanded(child: _dotCol('2027', '3.1%', '1 cut projected')),
              Expanded(child: _dotCol('Long-Run', '3.0%', 'Neutral rate est.')),
            ],
          ),
          Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.white.withValues(alpha: 0.10)),
          Text(
              'Source: Federal Reserve March 2025 SEP · Next update: June 18, 2025',
              style: AppTextStyles.dmSans(
                  size: 9, color: Colors.white.withValues(alpha: 0.40)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _dotCol(String year, String median, String range) {
    return Column(
      children: [
        Text(year.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.50),
                letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Text(median,
            style: AppTextStyles.dmSans(
                size: 18,
                weight: FontWeight.w800,
                color: const Color(0xFFFCD34D))),
        const SizedBox(height: 2),
        Text(range,
            style: AppTextStyles.dmSans(
                size: 8.5, color: Colors.white.withValues(alpha: 0.45)),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Key Rate Comparison ────────────────────────────────────────────────────
  Widget _buildRateComparison(bool isDark) {
    final fedRate = ref.watch(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
    final rate30 = ref.watch(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    final rate15 = ref.watch(fredMortgage15Provider).valueOrNull?.value ?? 6.11;
    final primeRate = ref.watch(fredPrimeProvider).valueOrNull?.value ?? 8.50;

    final keyRatesList = [
      _RateRow(
          label: 'Fed Funds',
          widthFactor: (fedRate / 10).clamp(0.0, 1.0),
          barColor1: const Color(0xFF1B3F72),
          barColor2: const Color(0xFF0B1D3A),
          value: '${fedRate.toStringAsFixed(2)}%'),
      _RateRow(
          label: '30-Yr Mortgage',
          widthFactor: (rate30 / 10).clamp(0.0, 1.0),
          barColor1: const Color(0xFFB91C1C),
          barColor2: const Color(0xFF991B1B),
          value: '${rate30.toStringAsFixed(2)}%'),
      _RateRow(
          label: '15-Yr Mortgage',
          widthFactor: (rate15 / 10).clamp(0.0, 1.0),
          barColor1: const Color(0xFFD97706),
          barColor2: const Color(0xFFB45309),
          value: '${rate15.toStringAsFixed(2)}%'),
      _RateRow(
          label: '10-Yr Treasury',
          widthFactor: ((rate30 - 2.35) / 10).clamp(0.0, 1.0),
          barColor1: const Color(0xFF0F766E),
          barColor2: const Color(0xFF0D9488),
          value: '${(rate30 - 2.35).toStringAsFixed(2)}%'),
      _RateRow(
          label: 'Prime Rate',
          widthFactor: (primeRate / 10).clamp(0.0, 1.0),
          barColor1: const Color(0xFF334155),
          barColor2: const Color(0xFF1E293B),
          value: '${primeRate.toStringAsFixed(2)}%'),
      _RateRow(
          label: 'HY Savings APY',
          widthFactor: ((fedRate - 1.13) / 10).clamp(0.0, 1.0),
          barColor1: const Color(0xFF15803D),
          barColor2: const Color(0xFF166534),
          value: '${(fedRate - 1.13).toStringAsFixed(2)}%'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 US Benchmark Rates vs Fed Funds',
              style: AppTextStyles.playfair(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: _theme.getTextColor(context))),
          const SizedBox(height: 12),
          ...keyRatesList.map((r) => _rateCompareRow(r, isDark)),
        ],
      ),
    );
  }

  Widget _rateCompareRow(_RateRow r, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(r.label,
                style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: _theme.getMutedColor(context))),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                widthFactor: r.widthFactor,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [r.barColor1, r.barColor2]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(r.value,
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: _theme.getTextColor(context)),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ── Related Tools Grid ─────────────────────────────────────────────────────
  Widget _buildRelatedTools(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: _relatedTools.map((t) => _toolCard(t, isDark)).toList(),
    );
  }

  Widget _toolCard(_ToolItem t, bool isDark) {
    final isColored = t.variant != _CardVariant.light;
    LinearGradient? grad;
    Color textCol;
    Color bgCol;

    switch (t.variant) {
      case _CardVariant.dark:
        grad = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]);
        textCol = Colors.white;
        bgCol = Colors.transparent;
        break;
      case _CardVariant.red:
        grad = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]);
        textCol = Colors.white;
        bgCol = Colors.transparent;
        break;
      case _CardVariant.gold:
        grad = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD97706), Color(0xFFB45309)]);
        textCol = Colors.white;
        bgCol = Colors.transparent;
        break;
      case _CardVariant.teal:
        grad = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF0D9488)]);
        textCol = Colors.white;
        bgCol = Colors.transparent;
        break;
      case _CardVariant.light:
        grad = null;
        textCol = _theme.getTextColor(context);
        bgCol = _theme.getCardColor(context);
        break;
    }

    return GestureDetector(
      onTap: () {
        if (t.title == 'FRED Rate History') {
          context.push('/usa/fred-rate-history');
        } else if (t.title == 'FedWatch Tool') {
          context.push('/usa/fedwatch');
        } else if (t.title == 'Yield Curve') {
          context.push('/usa/yield-curve');
        } else if (t.title == 'CPI vs Fed Rate') {
          context.push('/usa/cpi-vs-fed-rate');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: grad != null ? null : bgCol,
          gradient: grad,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isColored
                  ? Colors.transparent
                  : _theme.getBorderColor(context)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isColored
                        ? Colors.white.withValues(alpha: 0.14)
                        : _theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(t.emoji, style: const TextStyle(fontSize: 17)),
                ),
                const SizedBox(height: 8),
                Text(t.title,
                    style: AppTextStyles.playfair(
                        size: 12, weight: FontWeight.w800, color: textCol),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(t.subtitle,
                    style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: isColored
                            ? textCol.withValues(alpha: 0.58)
                            : _theme.getMutedColor(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (t.badge != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isColored
                          ? Colors.white.withValues(alpha: 0.22)
                          : (isDark
                              ? const Color(0xFF1D4ED8).withValues(alpha: 0.25)
                              : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t.badge!,
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: isColored
                                ? Colors.white
                                : const Color(0xFF1D4ED8))),
                  ),
                ],
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Text('›',
                  style: AppTextStyles.dmSans(
                    size: 18,
                    color: isColored
                        ? Colors.white.withValues(alpha: 0.22)
                        : _theme.getMutedColor(context).withValues(alpha: 0.3),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rate History Custom Painter ───────────────────────────────────────────────
class _RateChartPainter extends CustomPainter {
  final bool isDark;
  const _RateChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (final yFrac in [0.2, 0.4, 0.6, 0.8]) {
      final y = h * yFrac;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Y-axis labels
    final labelStyle = TextStyle(
      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
      fontSize: 8,
    );
    const yLabels = ['6%', '4.5%', '3%', '1.5%', '0%'];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, h * (i / 4) - 6));
    }

    // Data points (normalized: rate/6 → fraction, y = h * (1 - fraction))
    final rawPoints = [
      // [xFrac, rate]
      [0.08, 1.5], [0.18, 2.5], [0.26, 2.0], [0.33, 0.25], [0.37, 0.25],
      [0.47, 0.25], [0.61, 4.0], [0.71, 5.25], [0.78, 5.50], [0.82, 5.50],
      [0.90, 4.50], [0.99, 4.25],
    ];
    final pts =
        rawPoints.map((p) => Offset(w * p[0], h * (1 - p[1] / 6.0))).toList();

    // Area fill
    final gradientRect = Rect.fromLTWH(0, 0, w, h);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B3F72).withValues(alpha: 0.35),
          const Color(0xFF1B3F72).withValues(alpha: 0.03),
        ],
      ).createShader(gradientRect);

    final fillPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(pts.last.dx, h);
    fillPath.lineTo(pts.first.dx, h);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Current rate dot (pulsing simulation with outer ring)
    final dotPt = pts.last;
    canvas.drawCircle(dotPt, 9,
        Paint()..color = const Color(0xFFB91C1C).withValues(alpha: 0.35));
    canvas.drawCircle(dotPt, 5, Paint()..color = const Color(0xFFB91C1C));

    // Peak dot & label
    final peakPt = pts[8]; // 5.50%
    canvas.drawCircle(peakPt, 4, Paint()..color = const Color(0xFFD97706));
    final peakTp = TextPainter(
      text: const TextSpan(
          text: 'PEAK 5.50%',
          style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 8,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    peakTp.paint(canvas, Offset(peakPt.dx - 38, peakPt.dy + 6));

    // COVID label
    final covidColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final covidTp = TextPainter(
      text: TextSpan(
          text: 'COVID Cut',
          style: TextStyle(color: covidColor, fontSize: 7.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    covidTp.paint(canvas, Offset(w * 0.33, h - 14));

    // X-axis labels
    const xLabels = [
      ('2018', 0.06),
      ('2020', 0.31),
      ('2022', 0.46),
      ('2023', 0.68),
      ('2025', 0.87)
    ];
    for (final xl in xLabels) {
      final tp = TextPainter(
        text: TextSpan(text: xl.$1, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w * xl.$2, h - 12));
    }
  }

  @override
  bool shouldRepaint(covariant _RateChartPainter old) => old.isDark != isDark;
}
