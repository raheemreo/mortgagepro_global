// lib/features/global/global_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../providers/usa_rates_provider.dart';
import '../../core/navigation/tool_navigation.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static Color navy = const Color(0xFF0B1D3A);
  static Color royal = const Color(0xFF1A3A8F);
  static Color goldLt = const Color(0xFFFCD34D);
  static Color bg = const Color(0xFFF0F4FF);
  static Color card = const Color(0xFFFFFFFF);
  static Color muted = const Color(0xFF5B6E8F);
  static Color border = const Color(0x171B3A8F);

  static void update(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    navy = isDark ? Colors.white : const Color(0xFF0B1D3A);
    royal = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1A3A8F);
    goldLt = const Color(0xFFFCD34D);
    bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    card = isDark ? const Color(0xFF141C33) : const Color(0xFFFFFFFF);
    muted = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    border =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);
  }
}

class GlobalScreen extends ConsumerWidget {
  const GlobalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _C.update(context);
    final mortgage30Async = ref.watch(fredMortgage30Provider);
    final fedFundsAsync = ref.watch(fredFedFundsProvider);

    final m30Val = mortgage30Async.valueOrNull?.value ?? 6.82;
    final fedFundsVal = fedFundsAsync.valueOrNull?.value ?? 5.33;
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Gradient Header with Central Bank Rates Grid ───────────
          const _GlobalHeader(),

          // ── Scrollable Body Content ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 110),
              children: [
                // ── Rate Comparison Table ─────────────────────────────
                const _SecLabel(
                    text: 'Rate Comparison Table', more: 'Export →'),
                const _ComparisonTable(),



                // ── Select a Country ──────────────────────────────────
                const _SecLabel(text: 'Select a Country', more: '6 Available'),
                _CountryCard(
                  flag: '🇺🇸',
                  name: 'United States',
                  sub: 'USD · Federal Reserve · All 50 States',
                  pills: [
                    _Pill(
                        text: '30yr: ${m30Val.toStringAsFixed(2)}%',
                        bg: const Color(0xFFEFF6FF),
                        fg: const Color(0xFF1D4ED8)),
                    _Pill(
                        text: 'Fed: ${fedFundsVal.toStringAsFixed(2)}%',
                        bg: const Color(0xFFFEF2F2),
                        fg: const Color(0xFFB91C1C)),
                    const _Pill(
                        text: 'FHA · VA · USDA',
                        bg: Color(0xFFF0FDF4),
                        fg: Color(0xFF15803D)),
                  ],
                  toolsCount: '25 tools',
                  onTap: () => navigateToTool(context, 'usa', null),
                ),
                _CountryCard(
                  flag: '🇨🇦',
                  name: 'Canada',
                  sub: 'CAD · Bank of Canada · CMHC',
                  pills: const [
                    _Pill(
                        text: '5yr: 4.99%',
                        bg: Color(0xFFF0FDF4),
                        fg: Color(0xFF15803D)),
                    _Pill(
                        text: 'Stress: 7.00%',
                        bg: Color(0xFFFEF2F2),
                        fg: Color(0xFFB91C1C)),
                    _Pill(
                        text: 'GDS/TDS',
                        bg: Color(0xFFFFF7ED),
                        fg: Color(0xFFC2410C)),
                  ],
                  toolsCount: '18 tools',
                  onTap: () => navigateToTool(context, 'canada', null),
                ),
                _CountryCard(
                  flag: '🇬🇧',
                  name: 'United Kingdom',
                  sub: 'GBP · Bank of England · SDLT',
                  pills: const [
                    _Pill(
                        text: '2yr: 4.75%',
                        bg: Color(0xFFEFF6FF),
                        fg: Color(0xFF1D4ED8)),
                    _Pill(
                        text: 'SDLT',
                        bg: Color(0xFFFEF2F2),
                        fg: Color(0xFFB91C1C)),
                    _Pill(
                        text: 'Help to Buy',
                        bg: Color(0xFFF5F3FF),
                        fg: Color(0xFF6D28D9)),
                  ],
                  toolsCount: '20 tools',
                  onTap: () => navigateToTool(context, 'uk', null),
                ),
                _CountryCard(
                  flag: '🇦🇺',
                  name: 'Australia',
                  sub: 'AUD · Reserve Bank of Australia · LMI',
                  pills: const [
                    _Pill(
                        text: 'Var: 6.09%',
                        bg: Color(0xFFFEF2F2),
                        fg: Color(0xFFB91C1C)),
                    _Pill(
                        text: 'LMI',
                        bg: Color(0xFFFFF7ED),
                        fg: Color(0xFFC2410C)),
                    _Pill(
                        text: 'Offset Acct',
                        bg: Color(0xFFF0FDFA),
                        fg: Color(0xFF0F766E)),
                  ],
                  toolsCount: '20 tools',
                  onTap: () => navigateToTool(context, 'australia', null),
                ),
                _CountryCard(
                  flag: '🇳🇿',
                  name: 'New Zealand',
                  sub: 'NZD · RBNZ · LVR · KiwiSaver',
                  pills: const [
                    _Pill(
                        text: '1yr: 6.59%',
                        bg: Color(0xFFFEF2F2),
                        fg: Color(0xFFB91C1C)),
                    _Pill(
                        text: 'LVR',
                        bg: Color(0xFFFFF7ED),
                        fg: Color(0xFFC2410C)),
                    _Pill(
                        text: 'KiwiSaver',
                        bg: Color(0xFFF0FDFA),
                        fg: Color(0xFF0F766E)),
                  ],
                  toolsCount: '22 tools',
                  onTap: () => navigateToTool(context, 'newzealand', null),
                ),
                _CountryCard(
                  flag: '🇪🇺',
                  name: 'Europe',
                  sub: 'EUR · ECB · DE · FR · ES · IT · NL',
                  pills: const [
                    _Pill(
                        text: 'DE: 3.85%',
                        bg: Color(0xFFF0FDF4),
                        fg: Color(0xFF15803D)),
                    _Pill(
                        text: 'FR: 3.60%',
                        bg: Color(0xFFF0FDF4),
                        fg: Color(0xFF15803D)),
                    _Pill(
                        text: 'ECB: 4.00%',
                        bg: Color(0xFFEFF6FF),
                        fg: Color(0xFF1D4ED8)),
                  ],
                  toolsCount: '18 tools',
                  onTap: () => navigateToTool(context, 'europe', null),
                ),

                // ── Currency Rates / access list ──────────────────────
                const _SecLabel(text: 'Currency Rates', more: 'Convert →'),
                _InfoItem(
                  icon: '💱',
                  name: 'USD → CAD, GBP, AUD, NZD, EUR, INR',
                  sub: 'Live forex rates · XE powered',
                  onTap: () => _showForexSheet(context, ref),
                ),
                _InfoItem(
                  icon: '📊',
                  name: 'Central Bank Calendar',
                  sub: 'Fed · BoC · BoE · RBA · RBNZ · ECB dates',
                  onTap: () {},
                ),
                _InfoItem(
                  icon: '🌐',
                  name: 'Global House Price Index',
                  sub: 'IMF · BIS international data',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Bottom Navigation ───────────────────────────────────────
          BottomNav(
            activeIndex: 3,
            activeColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF38BDF8)
                : const Color(0xFF003399),
            countryIcon: '🌐',
            countryLabel: 'Tools',
            countryRoute: '/',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  GRADIENT HEADER WITH CENTRAL BANK RATES GRID
// ════════════════════════════════════════════════════════════════════════════
class _GlobalHeader extends ConsumerWidget {
  const _GlobalHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fedFundsAsync = ref.watch(fredFedFundsProvider);
    final fedFundsVal = fedFundsAsync.valueOrNull?.value ?? 5.33;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003399),
            Color(0xFF1A0040),
            Color(0xFFFFCC00),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative Globe emoji watermark (🌍)
            Positioned(
              right: 10,
              top: 14,
              child: Text(
                '🌍',
                style: TextStyle(
                  fontSize: 90,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Back button, Title, Subtitle, and Stats button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('←',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global Markets',
                              style: AppTextStyles.playfair(
                                  size: 20, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '6 Countries · Live Rates · Central Banks',
                              style: AppTextStyles.dmSans(
                                  size: 10, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('📊', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2x3 Central Bank Rate Grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.35,
                    children: [
                      _GrItem(
                          flag: '🇺🇸',
                          label: 'Fed Funds',
                          value: '${fedFundsVal.toStringAsFixed(2)}%',
                          note: fedFundsAsync.valueOrNull?.isLive == true
                              ? 'FRED Live'
                              : 'FOMC',
                          colorStyle: _RateValStyle.gold),
                      const _GrItem(
                          flag: '🇨🇦',
                          label: 'BoC Rate',
                          value: '4.75%',
                          note: 'Bank of Canada',
                          colorStyle: _RateValStyle.down),
                      const _GrItem(
                          flag: '🇬🇧',
                          label: 'BoE Base',
                          value: '5.00%',
                          note: 'Bank of England',
                          colorStyle: _RateValStyle.normal),
                      const _GrItem(
                          flag: '🇦🇺',
                          label: 'RBA Cash',
                          value: '4.35%',
                          note: 'Reserve Bank AU',
                          colorStyle: _RateValStyle.down),
                      const _GrItem(
                          flag: '🇳🇿',
                          label: 'RBNZ OCR',
                          value: '5.50%',
                          note: 'Reserve Bank NZ',
                          colorStyle: _RateValStyle.up),
                      const _GrItem(
                          flag: '🇪🇺',
                          label: 'ECB Rate',
                          value: '4.00%',
                          note: 'Eurozone',
                          colorStyle: _RateValStyle.down),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  CENTRAL BANK RATE GRID ITEM
// ════════════════════════════════════════════════════════════════════════════
enum _RateValStyle { gold, up, down, normal }

class _GrItem extends StatelessWidget {
  final String flag, label, value, note;
  final _RateValStyle colorStyle;

  const _GrItem({
    required this.flag,
    required this.label,
    required this.value,
    required this.note,
    required this.colorStyle,
  });

  @override
  Widget build(BuildContext context) {
    _C.update(context);
    Color valColor;
    switch (colorStyle) {
      case _RateValStyle.gold:
        valColor = _C.goldLt;
      case _RateValStyle.up:
        valColor = const Color(0xFF6EE7B7);
      case _RateValStyle.down:
        valColor = const Color(0xFFFCA5A5);
      case _RateValStyle.normal:
        valColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(flag,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                fontFamily: 'DMSans',
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valColor,
                fontFamily: 'DMSans',
              ),
            ),
            Text(
              note,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.36),
                fontFamily: 'DMSans',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  RATE COMPARISON TABLE
// ════════════════════════════════════════════════════════════════════════════
class _ComparisonTable extends ConsumerWidget {
  const _ComparisonTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _C.update(context);
    final m30Val = ref.watch(fredMortgage30Provider).valueOrNull?.value ?? 6.82;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090B1D3B),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1.6),
          2: FlexColumnWidth(1.8),
          3: FlexColumnWidth(1.8),
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            children: ['Country', 'Best Rate', 'Type', 'Bank'].map((h) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  h,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _C.muted,
                    fontFamily: 'DMSans',
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
          // Rows
          _row(
              '🇺🇸 USA',
              '${m30Val.toStringAsFixed(2)}%',
              const Color(0xFFEFF6FF),
              const Color(0xFF1D4ED8),
              '30yr Fixed',
              'Freddie Mac'),
          _row('🇨🇦 Canada', '4.99%', const Color(0xFFF0FDF4),
              const Color(0xFF15803D), '5yr Fixed', 'ANZ/BoC'),
          _row('🇬🇧 UK', '4.35%', const Color(0xFFEFF6FF),
              const Color(0xFF1D4ED8), '5yr Fixed', 'BoE'),
          _row('🇦🇺 Australia', '6.09%', const Color(0xFFFEF2F2),
              const Color(0xFFB91C1C), 'Variable', 'Big 4'),
          _row('🇳🇿 New Zealand', '6.59%', const Color(0xFFFEF2F2),
              const Color(0xFFB91C1C), '1yr Fixed', 'Kiwibank'),
          _row('🇩🇪 Germany', '3.85%', const Color(0xFFF0FDF4),
              const Color(0xFF15803D), '10yr Fixed', 'Baufi',
              isLast: true),
        ],
      ),
    );
  }

  TableRow _row(
    String country,
    String rate,
    Color bg,
    Color fg,
    String type,
    String bank, {
    bool isLast = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: _C.border)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            country,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _C.navy,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: UnconstrainedBox(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rate,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            type,
            style: TextStyle(fontSize: 12, color: _C.navy),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            bank,
            style: TextStyle(fontSize: 12, color: _C.navy),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SELECT COUNTRY CARD
// ════════════════════════════════════════════════════════════════════════════
class _Pill {
  final String text;
  final Color bg;
  final Color fg;
  const _Pill({required this.text, required this.bg, required this.fg});
}

class _CountryCard extends StatelessWidget {
  final String flag;
  final String name;
  final String sub;
  final List<_Pill> pills;
  final String toolsCount;
  final VoidCallback onTap;

  const _CountryCard({
    required this.flag,
    required this.name,
    required this.sub,
    required this.pills,
    required this.toolsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x110B1D3A),
              blurRadius: 36,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _C.muted,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pills.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.text,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: p.fg,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    toolsCount,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _C.muted,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '›',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0x2E0B1D3A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  CURRENCY LIST ITEM
// ════════════════════════════════════════════════════════════════════════════
class _InfoItem extends StatelessWidget {
  final String icon;
  final String name;
  final String sub;
  final VoidCallback? onTap;

  const _InfoItem({
    required this.icon,
    required this.name,
    required this.sub,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    _C.update(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x090B1D3B),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _C.muted,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '›',
              style: TextStyle(fontSize: 18, color: Color(0x2E0B1D3A)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SHARED LABEL WIDGETS
// ════════════════════════════════════════════════════════════════════════════
class _SecLabel extends StatelessWidget {
  final String text;
  final String? more;

  const _SecLabel({required this.text, this.more});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 11),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _C.muted,
              letterSpacing: 1.0,
              fontFamily: 'DMSans',
            ),
          ),
          const Spacer(),
          if (more != null)
            Text(
              more!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.royal,
                fontFamily: 'DMSans',
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  FOREX CONVERTER SHEET
// ════════════════════════════════════════════════════════════════════════════
void _showForexSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    routeSettings: const RouteSettings(name: '/global/info'),
    builder: (_) => const _ForexSheet(),
  );
}

class _ForexSheet extends ConsumerStatefulWidget {
  const _ForexSheet();

  @override
  ConsumerState<_ForexSheet> createState() => _ForexSheetState();
}

class _ForexSheetState extends ConsumerState<_ForexSheet> {
  final TextEditingController _amountController =
      TextEditingController(text: '1000');
  double _usdAmount = 1000.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final text = _amountController.text.replaceAll(',', '');
      final val = double.tryParse(text) ?? 0.0;
      setState(() {
        _usdAmount = val;
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _C.update(context);
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _C.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pull Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: _C.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _C.royal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '💱',
                        style: TextStyle(fontSize: 22, color: _C.royal),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forex Converter',
                            style: AppTextStyles.playfair(
                              size: 20,
                              color: _C.navy,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live exchange rates relative to USD',
                            style: AppTextStyles.dmSans(
                              size: 11,
                              color: _C.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: _C.muted,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // USD Input Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _C.royal.withValues(alpha: 0.05),
                        _C.royal.withValues(alpha: 0.01),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _C.royal.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      // Flag and USD Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.border),
                        ),
                        child: Row(
                          children: [
                            const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'USD',
                              style: AppTextStyles.dmSans(
                                size: 14,
                                color: _C.navy,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Amount input
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _C.navy,
                            fontFamily: 'DMSans',
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 22,
                              color: _C.muted.withValues(alpha: 0.4),
                              fontFamily: 'DMSans',
                            ),
                            suffixIcon: _amountController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _amountController.clear();
                                    },
                                    child: Icon(Icons.clear,
                                        color: _C.muted, size: 18),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Rates List
              Expanded(
                child: ratesAsync.when(
                  data: (rates) {
                    final targetCurrencies = [
                      _ForexTarget(
                          code: 'EUR',
                          name: 'Euro',
                          flag: '🇪🇺',
                          rate: rates['EUR'] ?? 0.92),
                      _ForexTarget(
                          code: 'GBP',
                          name: 'British Pound',
                          flag: '🇬🇧',
                          rate: rates['GBP'] ?? 0.79),
                      _ForexTarget(
                          code: 'CAD',
                          name: 'Canadian Dollar',
                          flag: '🇨🇦',
                          rate: rates['CAD'] ?? 1.37),
                      _ForexTarget(
                          code: 'AUD',
                          name: 'Australian Dollar',
                          flag: '🇦🇺',
                          rate: rates['AUD'] ?? 1.51),
                      _ForexTarget(
                          code: 'NZD',
                          name: 'New Zealand Dollar',
                          flag: '🇳🇿',
                          rate: rates['NZD'] ?? 1.63),
                      _ForexTarget(
                          code: 'INR',
                          name: 'Indian Rupee',
                          flag: '🇮🇳',
                          rate: rates['INR'] ?? 83.50),
                    ];

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: targetCurrencies.length,
                      itemBuilder: (context, index) {
                        final item = targetCurrencies[index];
                        final converted = _usdAmount * item.rate;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _C.bg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _C.border),
                          ),
                          child: Row(
                            children: [
                              // Flag & details
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _C.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _C.border),
                                ),
                                alignment: Alignment.center,
                                child: Text(item.flag,
                                    style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.code,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _C.navy,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _C.muted,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Converted amount & rate
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(converted, item.code),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _C.royal,
                                      fontFamily: 'DMSans',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '1 USD = ${item.rate.toStringAsFixed(4)} ${item.code}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _C.muted,
                                      fontFamily: 'DMSans',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Failed to load live exchange rates.',
                      style: TextStyle(color: _C.muted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount, String code) {
    if (code == 'INR') {
      return '₹${amount.toStringAsFixed(2)}';
    } else if (code == 'GBP') {
      return '£${amount.toStringAsFixed(2)}';
    } else if (code == 'EUR') {
      return '€${amount.toStringAsFixed(2)}';
    } else if (code == 'CAD' || code == 'AUD' || code == 'NZD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return amount.toStringAsFixed(2);
  }
}

class _ForexTarget {
  final String code;
  final String name;
  final String flag;
  final double rate;
  const _ForexTarget({
    required this.code,
    required this.name,
    required this.flag,
    required this.rate,
  });
}
