// lib/features/home/home_screen.dart
// Redesigned: Full 8-tab country dashboard
// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/ads/native_ad_widget.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../core/navigation/tool_navigation.dart';
import '../../providers/saved_tools_provider.dart';
import '../../providers/canada_rates_provider.dart';
import '../../providers/europe_rates_provider.dart';
import '../../providers/uk_rates_provider.dart';
import '../../providers/nz_rates_provider.dart';
import '../../services/remote_config_service.dart';
import '../notifications/providers/notifications_provider.dart';

import '../../services/analytics_service.dart';
import '../../services/analytics/analytics_screen.dart';
import '../../services/analytics/analytics_country.dart';
import '../../core/analytics/screen_timer_mixin.dart';
import '../../core/analytics/scroll_depth_tracker.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
class _DT {
  // Global / shared
  static Color navy = const Color(0xFF0B1D3A);
  static Color royal = const Color(0xFF1A3A8F);
  static Color gold = const Color(0xFFD97706);
  static Color goldLt = const Color(0xFFFCD34D);
  static Color teal = const Color(0xFF0D9488);
  static Color bg = const Color(0xFFF0F4FF);
  static Color card = const Color(0xFFFFFFFF);
  static Color muted = const Color(0xFF5B6E8F);
  static Color border = const Color(0x171B3A8F);
  static Color upColor = const Color(0xFF15803D);
  static Color dnColor = const Color(0xFFC0392B);

  static void update(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    navy = isDark ? Colors.white : const Color(0xFF0B1D3A);
    royal = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1A3A8F);
    gold = const Color(0xFFD97706);
    goldLt = const Color(0xFFFCD34D);
    teal = const Color(0xFF0D9488);
    bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    card = isDark ? const Color(0xFF141C33) : const Color(0xFFFFFFFF);
    muted = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    border =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);
    upColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    dnColor = isDark ? const Color(0xFFF87171) : const Color(0xFFC0392B);
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB META
// ═══════════════════════════════════════════════════════════════
class _TabMeta {
  final String flag;
  final String label;
  const _TabMeta(this.flag, this.label);
}

const _tabs = [
  _TabMeta('🌐', 'Global'),
  _TabMeta('🇺🇸', 'United States'),
  _TabMeta('🇨🇦', 'Canada'),
  _TabMeta('🇬🇧', 'United Kingdom'),
  _TabMeta('🇦🇺', 'Australia'),
  _TabMeta('🇳🇿', 'New Zealand'),
  _TabMeta('🇪🇺', 'Europe'),
  _TabMeta('🇮🇳', 'India'),
];

// ═══════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 8, vsync: this);
    _tabCtrl.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabCtrl.indexIsChanging) {
      final currentIndex = _tabCtrl.index;
      if (currentIndex != _previousIndex) {
        final previousCountry = _getCountryName(_previousIndex);
        final currentCountry = _getCountryName(currentIndex);
        AnalyticsService.instance.logCountryTabSelected(
          currentCountry,
          previousCountry,
        );
        _previousIndex = currentIndex;
      }
      setState(() {});
    }
  }

  String _getCountryName(int index) {
    switch (index) {
      case 0:
        return 'Global';
      case 1:
        return AnalyticsCountry.usa;
      case 2:
        return AnalyticsCountry.canada;
      case 3:
        return AnalyticsCountry.uk;
      case 4:
        return AnalyticsCountry.australia;
      case 5:
        return AnalyticsCountry.newZealand;
      case 6:
        return AnalyticsCountry.europe;
      case 7:
        return AnalyticsCountry.india;
      default:
        return 'Global';
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_handleTabChange);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _DT.update(context);
    final textScale = MediaQuery.textScalerOf(context);
    final expandedHeight = textScale.scale(160.0);
    final collapsedHeight = textScale.scale(110.0);

    return Scaffold(
      backgroundColor: _DT.bg,
      body: Stack(
        children: [
          NestedScrollView(
            physics: const ClampingScrollPhysics(),
            headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  tabCtrl: _tabCtrl,
                  expandedHeight: expandedHeight,
                  collapsedHeight: collapsedHeight,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _GlobalTab(tabController: _tabCtrl),
                _UsaTab(tabController: _tabCtrl),
                _CanadaTab(tabController: _tabCtrl),
                _UkTab(tabController: _tabCtrl),
                _AustraliaTab(tabController: _tabCtrl),
                _NewZealandTab(tabController: _tabCtrl),
                _EuropeTab(tabController: _tabCtrl),
                _IndiaTab(tabController: _tabCtrl),
              ],
            ),
          ),
          // ── Bottom Nav ─────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 0,
              activeColor: _DT.royal,
              countryIcon: '🛠️',
              countryLabel: 'Tools',
              countryRoute: '/tools',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STICKY HEADER DELEGATE
// ═══════════════════════════════════════════════════════════════
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabCtrl;
  final double expandedHeight;
  final double collapsedHeight;

  const _HomeHeaderDelegate({
    required this.tabCtrl,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  double get minExtent => collapsedHeight;
  @override
  double get maxExtent => expandedHeight;

  @override
  bool shouldRebuild(_HomeHeaderDelegate old) =>
      old.tabCtrl != tabCtrl ||
      old.expandedHeight != expandedHeight ||
      old.collapsedHeight != collapsedHeight;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) {
    final progress =
        (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
    return Container(
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
          // ── Brand bar (Fade & Hide on scroll) ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Visibility(
                visible: progress < 0.9,
                child: Opacity(
                  opacity: (1.0 - progress * 1.8).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _DT.gold,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _DT.gold.withValues(alpha: 0.40),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child:
                              const Text('🏦', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: 'Mortgage',
                                  style: AppTextStyles.playfair(
                                      size: 19, color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Pro',
                                  style: AppTextStyles.playfair(
                                      size: 19, color: _DT.goldLt),
                                ),
                              ]),
                            ),
                            Text(
                              '7 Countries · 100+ Tools',
                              style: AppTextStyles.dmSans(
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.50),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Consumer(
                          builder: (context, ref, child) {
                            final unreadCount =
                                ref.watch(unreadNotificationsCountProvider);
                            return GestureDetector(
                              onTap: () => context.push('/notifications'),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.18)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('🔔',
                                        style: TextStyle(fontSize: 15)),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: -3,
                                      right: -3,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Tab Bar (Pinned at bottom) ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TabBar(
              controller: tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: _DT.goldLt, width: 2.5),
                insets: const EdgeInsets.symmetric(horizontal: 6),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: _DT.goldLt,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: _tabs.map((t) {
                return Tab(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.flag, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(t.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED SECTION LABEL
// ═══════════════════════════════════════════════════════════════
class _SecLabel extends StatelessWidget {
  final String text;
  final String? more;
  final Color? textColor;
  final Color? moreColor;
  const _SecLabel({
    required this.text,
    this.more,
    this.textColor,
    this.moreColor,
  });

  @override
  Widget build(BuildContext context) {
    _DT.update(context);
    final resolvedTextColor = textColor ?? _DT.muted;
    final resolvedMoreColor = moreColor ?? _DT.royal;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: resolvedTextColor,
              letterSpacing: 1.0,
              fontFamily: 'DMSans',
            ),
          ),
          const Spacer(),
          if (more != null)
            GestureDetector(
              child: Text(
                more!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: resolvedMoreColor,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED TOOL CARD
// ═══════════════════════════════════════════════════════════════
enum _CardStyle { white, navy, red, gold, teal, green, slate, violet, custom }

class _ToolCard extends ConsumerWidget {
  final String? toolId;
  final String? flagIcon;
  final String icon;
  final String name;
  final String desc;
  final _CardStyle style;
  final String? badge;
  final Color? customGrad1;
  final Color? customGrad2;
  final Color? customBadgeBg;
  final Color? customBadgeText;
  final VoidCallback? onTap;
  final double iconSize = 36.0;
  final double iconBgSize = 60.0;

  const _ToolCard({
    this.toolId,
    this.flagIcon,
    required this.icon,
    required this.name,
    required this.desc,
    this.style = _CardStyle.white,
    this.badge,
    this.customGrad1,
    this.customGrad2,
    this.customBadgeBg,
    this.customBadgeText,
    this.onTap,
  });

  Gradient? _gradient() {
    switch (style) {
      case _CardStyle.navy:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]);
      case _CardStyle.red:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]);
      case _CardStyle.gold:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD97706), Color(0xFFB45309)]);
      case _CardStyle.teal:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D9488), Color(0xFF0F766E)]);
      case _CardStyle.green:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF15803D), Color(0xFF166534)]);
      case _CardStyle.slate:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF334155), Color(0xFF1E293B)]);
      case _CardStyle.violet:
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)]);
      case _CardStyle.custom:
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [customGrad1!, customGrad2!]);
      default:
        return null;
    }
  }

  bool get _isDark => style != _CardStyle.white;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _DT.update(context);
    final grad = _gradient();
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final cardIsDark = _isDark || isDarkTheme;
    final savedTools =
        toolId != null ? ref.watch(savedToolsProvider) : <String>[];
    final isFavorite = toolId != null && savedTools.contains(toolId);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: grad,
            color: grad == null ? _DT.card : null,
            borderRadius: BorderRadius.circular(16),
            border: grad == null ? Border.all(color: _DT.border) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.18 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
          child: Stack(
            children: [
              if (flagIcon != null || toolId != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (flagIcon != null)
                        Text(
                          flagIcon!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (flagIcon != null && toolId != null)
                        const SizedBox(width: 5),
                      if (toolId != null)
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(savedToolsProvider.notifier)
                                .toggleFavorite(toolId!);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cardIsDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isFavorite
                                  ? const Color(0xFFFCD34D)
                                  : (cardIsDark
                                      ? Colors.white70
                                      : Colors.black45),
                              size: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: iconBgSize,
                      height: iconBgSize,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.13)
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : _DT.bg),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: TextStyle(fontSize: iconSize)),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _isDark ? Colors.white : _DT.navy,
                        fontFamily: 'DMSans',
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.57)
                            : _DT.muted,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: customBadgeBg ?? const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: customBadgeText ?? const Color(0xFF1D4ED8),
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Text(
                  '›',
                  style: TextStyle(
                    fontSize: 18,
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : _DT.navy.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED INFO LIST ITEM
// ═══════════════════════════════════════════════════════════════
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
    _DT.update(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: _DT.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _DT.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _DT.bg,
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
                      color: _DT.navy,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _DT.muted,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: TextStyle(
                  fontSize: 18, color: _DT.navy.withValues(alpha: 0.18)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED MINI RATE CARD (horizontal scroll)
// ═══════════════════════════════════════════════════════════════
class _MiniRateCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String sub;
  final String change;
  final bool isUp;
  const _MiniRateCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.change,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    _DT.update(context);
    return Container(
      width: 112,
      padding: const EdgeInsets.fromLTRB(11, 13, 11, 13),
      decoration: BoxDecoration(
        color: _DT.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _DT.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: _DT.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _DT.navy,
              fontFamily: 'DMSans',
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: _DT.muted,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isUp ? _DT.upColor : _DT.dnColor,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED HERO CALC CARD
// ═══════════════════════════════════════════════════════════════
class _HeroCalcCard extends StatelessWidget {
  final String tag;
  final String titleStart;
  final String titleHighlight;
  final String titleEnd;
  final String field1Label;
  final String field1Value;
  final String field2Label;
  final String field2Value;
  final String field3Label;
  final String field3Value;
  final String buttonText;
  final Color grad1;
  final Color grad2;
  final Color accentCircle;
  final Color buttonColor;
  final Color buttonTextColor;
  final String watermarkEmoji;
  final VoidCallback? onTap;

  const _HeroCalcCard({
    required this.tag,
    required this.titleStart,
    required this.titleHighlight,
    this.titleEnd = '',
    required this.field1Label,
    required this.field1Value,
    required this.field2Label,
    required this.field2Value,
    required this.field3Label,
    required this.field3Value,
    required this.buttonText,
    required this.grad1,
    required this.grad2,
    required this.accentCircle,
    required this.buttonColor,
    this.buttonTextColor = Colors.white,
    this.watermarkEmoji = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0, -1),
            end: const Alignment(1, 1),
            colors: [grad1, grad2],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: grad1.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
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
                  color: accentCircle,
                ),
              ),
            ),
            if (watermarkEmoji.isNotEmpty)
              Positioned(
                right: 12,
                bottom: 12,
                child: Text(
                  watermarkEmoji,
                  style: TextStyle(
                    fontSize: 54,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withValues(alpha: 0.48),
                      letterSpacing: 0.8,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: titleStart,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'DMSans',
                          height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: titleHighlight,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _DT.goldLt,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      if (titleEnd.isNotEmpty)
                        TextSpan(
                          text: titleEnd,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'DMSans',
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _HeroBox(label: field1Label, value: field1Value),
                      const SizedBox(width: 7),
                      _HeroBox(label: field2Label, value: field2Value),
                      const SizedBox(width: 7),
                      _HeroBox(label: field3Label, value: field3Value),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: buttonTextColor,
                        fontFamily: 'DMSans',
                      ),
                    ),
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

class _HeroBox extends StatelessWidget {
  final String label;
  final String value;
  const _HeroBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: Colors.white.withValues(alpha: 0.48),
                fontFamily: 'DMSans',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED ALERT BANNER CARD
// ═══════════════════════════════════════════════════════════════
class _AlertBanner extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color bg1;
  final Color bg2;
  final Color borderColor;
  final Color buttonColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  const _AlertBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.bg1,
    required this.bg2,
    required this.borderColor,
    required this.buttonColor,
    this.titleColor = const Color(0xFF92400E),
    this.subtitleColor = const Color(0xFFB45309),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: subtitleColor,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED MARKET TICKER
// ═══════════════════════════════════════════════════════════════
class _MarketTicker extends StatelessWidget {
  final String title;
  final List<_TickerItem> items;
  const _MarketTicker({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: _DT.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DT.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _DT.navy,
                  fontFamily: 'DMSans',
                ),
              ),
              const Spacer(),
              Text(
                '● Live',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _DT.teal,
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final m = items[i];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: _DT.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontFamily: 'DMSans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    m.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _DT.navy,
                      fontFamily: 'DMSans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    m.change,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: m.isUp == null
                          ? _DT.muted
                          : (m.isUp! ? _DT.upColor : _DT.dnColor),
                      fontFamily: 'DMSans',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TickerItem {
  final String name;
  final String value;
  final String change;
  final bool? isUp;
  const _TickerItem(this.name, this.value, this.change, this.isUp);
}

// ═══════════════════════════════════════════════════════════════
//  COUNTRY RATE STRIP (inside tab content, below hero area)
// ═══════════════════════════════════════════════════════════════
enum _RateColor { gold, green, red, normal }

class _RateItem {
  final String label;
  final String value;
  final _RateColor colorType;
  const _RateItem(this.label, this.value, this.colorType);
}

class _CountryRateStrip extends StatelessWidget {
  final List<_RateItem> items;
  final Color? borderColor;
  const _CountryRateStrip({
    required this.items,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    _DT.update(context);
    final resolvedBorderColor = borderColor ?? _DT.border;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: _DT.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: resolvedBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: i < items.length - 1
                      ? Border(right: BorderSide(color: resolvedBorderColor))
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 8,
                        color: _DT.muted,
                        letterSpacing: 0.3,
                        fontFamily: 'DMSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: item.colorType == _RateColor.gold
                            ? const Color(0xFFD97706)
                            : item.colorType == _RateColor.green
                                ? const Color(0xFF15803D)
                                : item.colorType == _RateColor.red
                                    ? const Color(0xFFB91C1C)
                                    : _DT.navy,
                        fontFamily: 'DMSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AI ADVISOR BANNER  (matches HTML .ai-banner layout)
// ═══════════════════════════════════════════════════════════════
class _AIAdvisorBanner extends StatelessWidget {
  final String route;
  const _AIAdvisorBanner({required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2D6B).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🤖 icon (34px per HTML .ai-icon)
            const Text('🤖', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            // ai-body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 'POWERED BY AI' label (9px, uppercase, white44)
                  Text(
                    'POWERED BY AI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.44),
                      letterSpacing: 0.7,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Title: 'Global Mortgage\nAI Advisor' (17px Playfair)
                  const Text(
                    'Global Mortgage\nAI Advisor',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'DMSans',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // subtitle (10px, white55)
                  Text(
                    'Ask anything · 8 countries · instant answers',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 'Ask Now' gold button (navy text per HTML .ai-btn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: _DT.gold,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _DT.gold.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Ask Now',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1D3A),
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TOOLS 2-COLUMN GRID HELPER
// ═══════════════════════════════════════════════════════════════
Widget _toolGrid(List<_ToolCard> cards) {
  return GridView.count(
    shrinkWrap: true,
    primary: false,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.9,
    children: cards,
  );
}

// ═══════════════════════════════════════════════════════════════
// ██████  GLOBAL TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _GlobalTab extends StatefulWidget {
  final TabController tabController;
  const _GlobalTab({required this.tabController});

  @override
  State<_GlobalTab> createState() => _GlobalTabState();
}

class _GlobalTabState extends State<_GlobalTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.home;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 0) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.home,
      isActive: () => widget.tabController.index == 0,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 0) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('global'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // AI Advisor Banner (Placed under tab bar per HTML)
              const _AIAdvisorBanner(route: '/ai/usa'),

              // Quick Estimate
              const _SecLabel(text: 'Quick Estimate'),
              _HeroCalcCard(
                tag: 'Instant Mortgage Calculator',
                titleStart: 'How much is your ',
                titleHighlight: 'monthly payment?',
                titleEnd: '',
                field1Label: 'Home Price',
                field1Value: '\$450,000',
                field2Label: 'Down Pmt.',
                field2Value: '20%',
                field3Label: 'Term',
                field3Value: '30 yr',
                buttonText: '⚡ Calculate Mortgage Payment',
                grad1: const Color(0xFF0B1D3A),
                grad2: const Color(0xFF1B3F72),
                accentCircle: const Color(0x24C0392B),
                buttonColor: const Color(0xFFB91C1C),
                watermarkEmoji: '',
                onTap: () => context.push('/usa'),
              ),

              // Live Markets
              const _SecLabel(text: 'Live Markets'),
              const _MarketTicker(
                title: 'US Financial Indices',
                items: [
                  _TickerItem('S&P 500', '5,304', '+0.74%', true),
                  _TickerItem('Dow Jones', '38,886', '+0.51%', true),
                  _TickerItem('NASDAQ', '16,742', '-0.21%', false),
                  _TickerItem('Fed Rate', '5.33%', 'FOMC', null),
                  _TickerItem('10-Yr Bond', '4.47%', '-0.03', false),
                  _TickerItem('Gold', '\$2,352', '+0.32%', true),
                ],
              ),

              // Top Tools
              const _SecLabel(text: 'Top Tools', more: 'All 100+ →'),
              _toolGrid([
                _ToolCard(
                  icon: '📊',
                  name: 'PITI Calculator',
                  desc: 'Full payment breakdown',
                  style: _CardStyle.navy,
                  badge: 'United States',
                  onTap: () => navigateToTool(
                      context, 'usa', 'usa_core_piti_calculator'),
                ),
                _ToolCard(
                  icon: '🛡️',
                  name: 'CMHC Insurance',
                  desc: 'Premium calculator',
                  badge: 'Canada',
                  onTap: () => navigateToTool(context, 'canada', 'canada_cmhc'),
                ),
                _ToolCard(
                  icon: '🏢',
                  name: 'Stamp Duty (SDLT)',
                  desc: 'Tax on purchase',
                  badge: 'United Kingdom',
                  onTap: () =>
                      navigateToTool(context, 'uk', 'uk_stamp_duty_sdlt'),
                ),
                _ToolCard(
                  icon: '🥝',
                  name: 'KiwiSaver Calc',
                  desc: 'First-home withdrawal',
                  style: _CardStyle.teal,
                  badge: 'New Zealand',
                  onTap: () => navigateToTool(
                      context, 'newzealand', 'nz_kiwisaver_calc'),
                ),
                _ToolCard(
                  icon: '🏠',
                  name: 'Property Tax Calc',
                  desc: 'Country-specific taxes',
                  style: _CardStyle.gold,
                  badge: 'Europe',
                  onTap: () => navigateToTool(
                      context, 'europe', 'europe_property_tax_calc'),
                ),
                _ToolCard(
                  icon: '🏦',
                  name: 'Offset Account',
                  desc: 'Interest savings calc',
                  style: _CardStyle.red,
                  badge: 'Australia',
                  onTap: () =>
                      navigateToTool(context, 'australia', 'australia_offset'),
                ),
              ]),

              // ── Native Ad (Global tab) ──────────────────────────────────────────
              // AdMob Policy: ≥32dp clearance from any interactive element above/below. (24dp vertical clear zone on widget + surrounding elements)
              const NativeAdWidget(
                screenName: 'global_home_native',
                adType: 'mediumCard',
              ),

              // Global Rates Today
              const _SecLabel(text: 'Global Rates Today'),
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(145),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  clipBehavior: Clip.none,
                  children: const [
                    _MiniRateCard(
                      icon: '🇺🇸',
                      label: 'USA 30yr',
                      value: '6.82%',
                      sub: 'Freddie Mac',
                      change: '↑ +0.05',
                      isUp: true,
                    ),
                    SizedBox(width: 9),
                    _MiniRateCard(
                      icon: '🇨🇦',
                      label: 'CA 5yr',
                      value: '4.99%',
                      sub: 'BoC',
                      change: '↓ -0.10',
                      isUp: false,
                    ),
                    SizedBox(width: 9),
                    _MiniRateCard(
                      icon: '🇬🇧',
                      label: 'UK 2yr',
                      value: '4.75%',
                      sub: 'BoE',
                      change: '↑ +0.05',
                      isUp: true,
                    ),
                    SizedBox(width: 9),
                    _MiniRateCard(
                      icon: '🇦🇺',
                      label: 'AU Var',
                      value: '6.09%',
                      sub: 'RBA',
                      change: '↓ -0.25',
                      isUp: false,
                    ),
                    SizedBox(width: 9),
                    _MiniRateCard(
                      icon: '🇳🇿',
                      label: 'NZ 1yr',
                      value: '6.59%',
                      sub: 'RBNZ',
                      change: '↓ -0.10',
                      isUp: false,
                    ),
                    SizedBox(width: 9),
                    _MiniRateCard(
                      icon: '🇪🇺',
                      label: 'EU DE',
                      value: '3.85%',
                      sub: 'ECB',
                      change: '↑ +0.02',
                      isUp: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Access
              const _SecLabel(text: 'Quick Access'),
              _InfoItem(
                icon: '🏛️',
                name: 'Top Mortgage Lenders',
                sub: 'USA · Canada · UK · Australia · NZ · Europe · India',
                onTap: () => context.push('/global/top-lenders'),
              ),
              _InfoItem(
                icon: '🏡',
                name: 'Home Prices by Region',
                sub: 'Property values across 6 countries',
                onTap: () => context.push('/global'),
              ),
              _InfoItem(
                icon: '💱',
                name: 'Currency Converter',
                sub: 'USD · CAD · GBP · AUD · NZD · EUR · INR',
                onTap: () => context.push('/global'),
              ),
              // ── Banner Ad (Global tab footer) ───────────────────────────────────
              // AdMob Policy: ≥32dp from last interactive element; collapses on failure.
              // DO NOT reduce this spacing — prevents accidental taps on content above.
              const SizedBox(height: 32),
              const BannerAdWidget(screenName: 'global_home_bottom_banner'),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── TableRow helper ──────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════
// ██████  USA TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _UsaTab extends StatefulWidget {
  final TabController tabController;
  const _UsaTab({required this.tabController});

  @override
  State<_UsaTab> createState() => _UsaTabState();
}

class _UsaTabState extends State<_UsaTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.usa;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 1) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.usa,
      isActive: () => widget.tabController.index == 1,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 1) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('usa'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _CountryRateStrip(items: [
                _RateItem('30-Yr Fixed', '6.82%', _RateColor.green),
                _RateItem('15-Yr Fixed', '6.11%', _RateColor.normal),
                _RateItem('5/1 ARM', '6.05%', _RateColor.red),
                _RateItem('Fed Funds', '5.33%', _RateColor.gold),
              ]),
              const _SecLabel(text: 'Quick Estimate'),
              _HeroCalcCard(
                tag: 'USA MORTGAGE CALCULATOR',
                titleStart: 'PITI · DTI · ',
                titleHighlight: 'Amortization',
                titleEnd: '\nAll-in-one payment',
                field1Label: 'Home Price',
                field1Value: '\$450,000',
                field2Label: 'Down Pmt.',
                field2Value: '20%',
                field3Label: 'Term',
                field3Value: '30 yr',
                buttonText: '🦅 Calculate USA Mortgage (PITI)',
                grad1: const Color(0xFF0B1D3A),
                grad2: const Color(0xFF1B3F72),
                accentCircle: const Color(0x26B91C1C),
                buttonColor: const Color(0xFFB91C1C),
                watermarkEmoji: '🦅',
                onTap: () => context.push('/usa'),
              ),
              const _SecLabel(text: 'Federal Reserve', more: 'FOMC Calendar →'),
              _AlertBanner(
                icon: '🏛️',
                title: 'Fed Funds Rate: 5.25 – 5.50%',
                subtitle: 'Next FOMC: Jul 30 · Rate cut watch: 65%',
                buttonText: 'FRED Live',
                bg1: const Color(0xFF0B1D3A),
                bg2: const Color(0xFF1B3F72),
                borderColor: const Color(0xFF1B3F72),
                buttonColor: _DT.gold,
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
                onTap: () => context.push('/usa'),
              ),
              const _SecLabel(text: 'Market Snapshot'),
              const _MarketTicker(
                title: 'US Financial Indices',
                items: [
                  _TickerItem('S&P 500', '5,304', '+0.74%', true),
                  _TickerItem('Dow Jones', '38,886', '+0.51%', true),
                  _TickerItem('NASDAQ', '16,742', '-0.21%', false),
                  _TickerItem('10-Yr T-Bill', '4.47%', '-0.03', false),
                  _TickerItem('30-Yr Bond', '4.61%', '+0.02', true),
                  _TickerItem('VIX', '13.4', '-0.80', false),
                ],
              ),
              const _SecLabel(
                  text: 'Live Mortgage Rates', more: 'Rate Trends →'),
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(155),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 2, bottom: 8, right: 4),
                  clipBehavior: Clip.none,
                  children: const [
                    _MiniRateCard(
                        icon: '🏠',
                        label: '30-Yr Fixed',
                        value: '6.82%',
                        sub: 'Freddie Mac',
                        change: '↑ +0.05',
                        isUp: false),
                    SizedBox(width: 9),
                    _MiniRateCard(
                        icon: '🏡',
                        label: '15-Yr Fixed',
                        value: '6.11%',
                        sub: 'National Avg',
                        change: '↓ -0.02',
                        isUp: true),
                    SizedBox(width: 9),
                    _MiniRateCard(
                        icon: '📊',
                        label: '5/1 ARM',
                        value: '6.05%',
                        sub: 'Adjustable',
                        change: '↓ -0.03',
                        isUp: true),
                    SizedBox(width: 9),
                    _MiniRateCard(
                        icon: '🏢',
                        label: 'Jumbo 30yr',
                        value: '7.04%',
                        sub: '>\$766K',
                        change: '↑ +0.08',
                        isUp: false),
                    SizedBox(width: 9),
                    _MiniRateCard(
                        icon: '🎖️',
                        label: 'VA Loan',
                        value: '6.25%',
                        sub: 'Veterans',
                        change: '↑ +0.01',
                        isUp: false),
                    SizedBox(width: 9),
                    _MiniRateCard(
                        icon: '🌾',
                        label: 'USDA Rural',
                        value: '6.35%',
                        sub: 'Rural areas',
                        change: '↓ -0.01',
                        isUp: true),
                  ],
                ),
              ),
              const _SecLabel(text: 'Core Mortgage Tools'),
              _toolGrid([
                _ToolCard(
                    icon: '📊',
                    name: 'PITI Calculator',
                    desc: 'Principal+Interest+Tax+Ins',
                    style: _CardStyle.navy,
                    badge: 'Full Breakdown',
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_piti_calculator')),
                _ToolCard(
                    icon: '🧮',
                    name: 'Mortgage Calc',
                    desc: 'Monthly payment estimate',
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_mortgage_calc')),
                _ToolCard(
                    icon: '📈',
                    name: 'DTI Calculator',
                    desc: 'Debt-to-income ratio',
                    badge: '28/36 Rule',
                    customBadgeBg: const Color(0xFFFEF2F2),
                    customBadgeText: const Color(0xFFB91C1C),
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_dti_calculator')),
                _ToolCard(
                    icon: '📅',
                    name: 'Amortization',
                    desc: 'Full payment schedule',
                    style: _CardStyle.red,
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_amortization')),
                _ToolCard(
                    icon: '💰',
                    name: 'Affordability',
                    desc: 'How much house?',
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_affordability')),
                _ToolCard(
                    icon: '🔑',
                    name: 'Down Payment',
                    desc: '3% · 5% · 10% · 20%',
                    style: _CardStyle.gold,
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_down_payment')),
                _ToolCard(
                    icon: '🔄',
                    name: 'Refinance Calc',
                    desc: 'Break-even & savings',
                    onTap: () => navigateToTool(
                        context, 'usa', 'usa_core_refinance_calc')),
                _ToolCard(
                    icon: '🏎️',
                    name: 'Auto Loan',
                    desc: 'Vehicle financing',
                    style: _CardStyle.teal,
                    onTap: () =>
                        navigateToTool(context, 'usa', 'usa_core_auto_loan')),
              ]),
              // ── Native Ad (USA tab) ─────────────────────────────────────────────
              const NativeAdWidget(
                screenName: 'usa_home_native',
                adType: 'mediumCard',
              ),
              const _SecLabel(text: 'Loan Programs'),
              _toolGrid([
                _ToolCard(
                    icon: '🏦',
                    name: 'FHA Loan Calc',
                    desc: '3.5% down · MIP included',
                    badge: '580+ Score',
                    customBadgeBg: const Color(0xFFF0FDF4),
                    customBadgeText: const Color(0xFF15803D),
                    onTap: () =>
                        navigateToTool(context, 'usa', 'usa_loan_fha')),
                _ToolCard(
                    icon: '🎖️',
                    name: 'VA Loan Calc',
                    desc: '0% down · Veterans only',
                    style: _CardStyle.navy,
                    badge: 'No PMI',
                    onTap: () => navigateToTool(context, 'usa', 'usa_loan_va')),
                _ToolCard(
                    icon: '🌾',
                    name: 'USDA Loan',
                    desc: 'Rural 0% down payment',
                    style: _CardStyle.green,
                    onTap: () =>
                        navigateToTool(context, 'usa', 'usa_loan_usda')),
                _ToolCard(
                    icon: '🏢',
                    name: 'Jumbo Loan',
                    desc: '>\$766,550 conforming',
                    onTap: () =>
                        navigateToTool(context, 'usa', 'usa_loan_jumbo')),
              ]),

              const _SecLabel(text: 'Housing Market Data'),
              _InfoItem(
                  icon: '📉',
                  name: 'FRED Rate History',
                  sub: 'Federal Reserve Economic Data live',
                  onTap: () => context.push('/usa')),
              _InfoItem(
                  icon: '🏡',
                  name: 'US Home Price Index (HPI)',
                  sub: 'S&P/Case-Shiller · FHFA index',
                  onTap: () => context.push('/usa')),
              _InfoItem(
                  icon: '📊',
                  name: 'Median Home Prices by State',
                  sub: 'NAR · Zillow · Redfin data',
                  onTap: () => context.push('/usa')),
              _InfoItem(
                  icon: '🏦',
                  name: 'Top US Mortgage Lenders',
                  sub: 'Rocket · UWM · Chase · Wells Fargo',
                  onTap: () => context.push('/usa')),
              _InfoItem(
                  icon: '🤖',
                  name: 'USA AI Mortgage Advisor',
                  sub: 'FRED rates · FHA/VA/USDA guidance',
                  onTap: () => context.push('/usa/ai-advisor')),
            ]),
          ),
        ),
      ],
    );
  }
}

Widget _alertBannerYellow({
  required String icon,
  required String title,
  required String subtitle,
  required String buttonText,
  VoidCallback? onTap,
}) {
  return _AlertBanner(
    icon: icon,
    title: title,
    subtitle: subtitle,
    buttonText: buttonText,
    bg1: const Color(0xFFFEF3C7),
    bg2: const Color(0xFFFDE68A),
    borderColor: const Color(0xFFF59E0B),
    buttonColor: const Color(0xFFD97706),
    titleColor: const Color(0xFF92400E),
    subtitleColor: const Color(0xFFB45309),
    onTap: onTap,
  );
}

// ═══════════════════════════════════════════════════════════════
// ██████  CANADA TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _CanadaTab extends StatefulWidget {
  final TabController tabController;
  const _CanadaTab({required this.tabController});

  @override
  State<_CanadaTab> createState() => _CanadaTabState();
}

class _CanadaTabState extends State<_CanadaTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.canada;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 2) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.canada,
      isActive: () => widget.tabController.index == 2,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 2) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('canada'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Consumer(
                builder: (ctx, ref, _) {
                  final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
                  final r = ratesAsync.valueOrNull;
                  final r5yr = r?.rate5yrFixed ?? 4.99;
                  final r3yr = r?.rate3yrFixed ?? 5.14;
                  final rVar = r?.rateVariable ?? 5.95;
                  final rSt = r?.stressTestRate ?? 7.00;
                  final isLive = r?.isLive == true;
                  return _CountryRateStrip(
                    borderColor: const Color(0x141A5C35),
                    items: [
                      _RateItem(
                        '5-Yr Fixed',
                        '${r5yr.toStringAsFixed(2)}%',
                        isLive ? _RateColor.green : _RateColor.red,
                      ),
                      _RateItem(
                        '3-Yr Fixed',
                        '${r3yr.toStringAsFixed(2)}%',
                        _RateColor.normal,
                      ),
                      _RateItem(
                        'Variable',
                        '${rVar.toStringAsFixed(2)}%',
                        _RateColor.green,
                      ),
                      _RateItem(
                        'Stress Test',
                        '${rSt.toStringAsFixed(2)}%',
                        _RateColor.gold,
                      ),
                    ],
                  );
                },
              ),
              const _SecLabel(
                  text: 'Quick Estimate', textColor: Color(0xFF3D6650)),
              Consumer(
                builder: (ctx, ref, _) {
                  final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
                  final r = ratesAsync.valueOrNull;
                  final r5yr = r?.rate5yrFixed ?? 4.99;
                  final rSt = r?.stressTestRate ?? 7.00;
                  final isLive = r?.isLive == true;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCalcCard(
                        tag: 'CANADIAN MORTGAGE CALCULATOR',
                        titleStart: 'Calculate your ',
                        titleHighlight: 'CMHC',
                        titleEnd: '\ninsured payment',
                        field1Label: 'Home Price',
                        field1Value: 'CA\$650K',
                        field2Label: '5-Yr Fixed',
                        field2Value:
                            '${r5yr.toStringAsFixed(2)}%${isLive ? " 🟢" : ""}',
                        field3Label: 'Amort.',
                        field3Value: '25 yr',
                        buttonText: '🍁 Calculate Canadian Mortgage',
                        grad1: const Color(0xFF0A2E1A),
                        grad2: const Color(0xFF1A5C35),
                        accentCircle: const Color(0x26B20D28),
                        buttonColor: const Color(0xFFC8102E),
                        watermarkEmoji: '🍁',
                        onTap: () => ctx.push('/canada'),
                      ),
                      const _SecLabel(
                          text: 'Stress Test', textColor: Color(0xFF3D6650)),
                      _alertBannerYellow(
                        icon: '⚠️',
                        title: 'Mortgage Stress Test',
                        subtitle:
                            'Qualify at ${rSt.toStringAsFixed(2)}% or contract+2% — whichever is higher',
                        buttonText: 'Test Now',
                        onTap: () => ctx.push('/canada'),
                      ),
                    ],
                  );
                },
              ),
              const _SecLabel(text: 'Core Tools', textColor: Color(0xFF3D6650)),
              _toolGrid([
                _ToolCard(
                    icon: '🏠',
                    name: 'Mortgage Calc',
                    desc: 'Monthly payment + CMHC',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF0A2E1A),
                    customGrad2: const Color(0xFF1A5C35),
                    badge: '25yr Max',
                    customBadgeBg: const Color(0xFFF0FDF4),
                    customBadgeText: const Color(0xFF166534),
                    onTap: () => navigateToTool(
                        context, 'canada', 'canada_mortgage_calc')),
                _ToolCard(
                    icon: '🛡️',
                    name: 'CMHC Insurance',
                    desc: 'Premium calculator',
                    badge: '<20% down',
                    customBadgeBg: const Color(0xFFFEF3C7),
                    customBadgeText: const Color(0xFF92400E),
                    onTap: () =>
                        navigateToTool(context, 'canada', 'canada_cmhc')),
                _ToolCard(
                    icon: '📊',
                    name: 'GDS / TDS Ratio',
                    desc: 'Gross debt service',
                    onTap: () =>
                        navigateToTool(context, 'canada', 'canada_gds_tds')),
                _ToolCard(
                    icon: '🧪',
                    name: 'Stress Test Calc',
                    desc: 'Can you qualify?',
                    style: _CardStyle.red,
                    onTap: () => navigateToTool(
                        context, 'canada', 'canada_stress_test')),
                _ToolCard(
                    icon: '💰',
                    name: 'Affordability',
                    desc: 'Max home price, CAD',
                    onTap: () => navigateToTool(
                        context, 'canada', 'canada_affordability')),
                _ToolCard(
                    icon: '📅',
                    name: 'Amortization',
                    desc: 'Bi-weekly schedule',
                    style: _CardStyle.gold,
                    onTap: () => navigateToTool(
                        context, 'canada', 'canada_amortization')),
                _ToolCard(
                    icon: '🔄',
                    name: 'Renewal Planner',
                    desc: 'Term renewal analysis',
                    onTap: () => navigateToTool(
                        context, 'canada', 'canada_renewal_planner')),
                _ToolCard(
                    icon: '📈',
                    name: 'Prepayment Calc',
                    desc: 'Lump sum savings',
                    onTap: () => navigateToTool(
                        context, 'canada', 'canada_prepayment_calc')),
              ]),
              // ── Native Ad (Canada tab) ──────────────────────────────────────────
              const NativeAdWidget(
                screenName: 'canada_home_native',
                adType: 'mediumCard',
              ),
              const _SecLabel(
                  text: 'Province & Resources', textColor: Color(0xFF3D6650)),
              _InfoItem(
                  icon: '🏛️',
                  name: 'Land Transfer Tax',
                  sub: 'By Province: ON, BC, AB, QC, MB…',
                  onTap: () => context.push('/canada')),
              _InfoItem(
                  icon: '🏡',
                  name: 'First-Home Buyer Incentive',
                  sub: 'FHBI · RRSP Home Buyers\' Plan',
                  onTap: () => context.push('/canada')),
              _InfoItem(
                  icon: '📉',
                  name: 'BoC Rate History',
                  sub: 'Live Bank of Canada rate tracker',
                  onTap: () => context.push('/canada')),
              _InfoItem(
                  icon: '🤖',
                  name: 'Canada AI Advisor',
                  sub: 'CMHC rules · stress test guidance',
                  onTap: () => context.push('/tool/canada/aiadvisor')),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ██████  UK TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _UkTab extends StatefulWidget {
  final TabController tabController;
  const _UkTab({required this.tabController});

  @override
  State<_UkTab> createState() => _UkTabState();
}

class _UkTabState extends State<_UkTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.uk;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 3) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.uk,
      isActive: () => widget.tabController.index == 3,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 3) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('uk'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Live BoE rate strip
              Consumer(
                builder: (ctx, ref, _) {
                  final r = ref.watch(ukRatesProvider).valueOrNull;
                  final boeBase = r?.boeBase.value ?? 4.25;
                  final fixed2yr = r?.fixed2yr.value ?? 4.75;
                  final fixed5yr = r?.fixed5yr.value ?? 4.35;
                  final isLive = r?.isLive == true;
                  return _CountryRateStrip(
                    borderColor: const Color(0x141A1A5E),
                    items: [
                      _RateItem('2-Yr Fixed', '${fixed2yr.toStringAsFixed(2)}%',
                          isLive ? _RateColor.green : _RateColor.red),
                      _RateItem('5-Yr Fixed', '${fixed5yr.toStringAsFixed(2)}%',
                          _RateColor.normal),
                      _RateItem(
                          'Tracker',
                          '${(boeBase + 0.25).toStringAsFixed(2)}%',
                          _RateColor.green),
                      _RateItem(
                          'BoE Base',
                          '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}',
                          _RateColor.gold),
                    ],
                  );
                },
              ),
              const _SecLabel(
                  text: 'Quick Estimate', textColor: Color(0xFF505080)),
              _HeroCalcCard(
                tag: 'UK MORTGAGE CALCULATOR',
                titleStart: 'Calculate your ',
                titleHighlight: 'Stamp Duty',
                titleEnd: '\n& monthly payment',
                field1Label: 'Property Value',
                field1Value: '£380,000',
                field2Label: 'Deposit',
                field2Value: '15%',
                field3Label: 'Term',
                field3Value: '25 yr',
                buttonText: '👑 Calculate UK Mortgage',
                grad1: const Color(0xFF0D0D2B),
                grad2: const Color(0xFF1a1a5e),
                accentCircle: const Color(0x26C8102E),
                buttonColor: const Color(0xFFC8102E),
                watermarkEmoji: '👑',
                onTap: () => context.push('/uk'),
              ),
              const _SecLabel(
                  text: 'Stamp Duty (SDLT)', textColor: Color(0xFF505080)),
              _AlertBanner(
                icon: '🏛️',
                title: 'Stamp Duty Land Tax',
                subtitle:
                    'First-time buyer relief up to £425,000 — calculate now',
                buttonText: 'Calculate',
                bg1: const Color(0xFFEEF2FF),
                bg2: const Color(0xFFE0E7FF),
                borderColor: const Color(0xFFA5B4FC),
                buttonColor: const Color(0xFF4F46E5),
                titleColor: const Color(0xFF1e1b4b),
                subtitleColor: const Color(0xFF4338ca),
                onTap: () => context.push('/uk'),
              ),
              const _SecLabel(text: 'Core Tools', textColor: Color(0xFF505080)),
              _toolGrid([
                _ToolCard(
                    icon: '🏠',
                    name: 'Mortgage Calc',
                    desc: 'Monthly repayment',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF0D0D2B),
                    customGrad2: const Color(0xFF1a1a5e),
                    badge: 'Repayment',
                    customBadgeBg: const Color(0xFFEEF2FF),
                    customBadgeText: const Color(0xFF3730A3),
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_mortgage_calc')),
                _ToolCard(
                    icon: '🏛️',
                    name: 'Stamp Duty (SDLT)',
                    desc: 'Tax on purchase',
                    badge: 'FTB Relief',
                    customBadgeBg: const Color(0xFFFEF2F2),
                    customBadgeText: const Color(0xFF991B1B),
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_stamp_duty_sdlt')),
                _ToolCard(
                    icon: '📊',
                    name: 'LTV Calculator',
                    desc: 'Loan-to-value ratio',
                    style: _CardStyle.violet,
                    onTap: () => navigateToTool(context, 'uk', 'uk_ltv_calc')),
                _ToolCard(
                    icon: '🔁',
                    name: 'Remortgage Tool',
                    desc: 'Switch & save calc',
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_remortgage_tool')),
                _ToolCard(
                    icon: '💷',
                    name: 'Affordability',
                    desc: 'Max borrowing GBP',
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_affordability')),
                _ToolCard(
                    icon: '🏘️',
                    name: 'Help to Buy',
                    desc: 'Equity loan scheme',
                    style: _CardStyle.red,
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_help_to_buy')),
                _ToolCard(
                    icon: '📅',
                    name: 'Amortization',
                    desc: 'Repayment schedule',
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_amortization')),
                _ToolCard(
                    icon: '🏢',
                    name: 'Buy-to-Let Calc',
                    desc: 'Rental yield & BTL',
                    style: _CardStyle.gold,
                    onTap: () =>
                        navigateToTool(context, 'uk', 'uk_buy_to_let')),
              ]),
              // ── Native Ad (UK tab) ──────────────────────────────────────────────
              const NativeAdWidget(
                screenName: 'uk_home_native',
                adType: 'mediumCard',
              ),
              const _SecLabel(
                  text: 'UK Resources', textColor: Color(0xFF505080)),
              _InfoItem(
                  icon: '📉',
                  name: 'BoE Base Rate Tracker',
                  sub: 'Live Bank of England rate history',
                  onTap: () => context.push('/uk')),
              _InfoItem(
                  icon: '🏡',
                  name: 'UK House Price Index',
                  sub: 'HM Land Registry · regional data',
                  onTap: () => context.push('/uk')),
              _InfoItem(
                  icon: '🤝',
                  name: 'Shared Ownership Calc',
                  sub: 'Part-buy part-rent scheme',
                  onTap: () => context.push('/uk')),
              _InfoItem(
                  icon: '🤖',
                  name: 'UK AI Mortgage Advisor',
                  sub: 'FCA-aware guidance · SDLT help',
                  onTap: () => context.push('/uk/ai-advisor')),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ██████  AUSTRALIA TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _AustraliaTab extends StatefulWidget {
  final TabController tabController;
  const _AustraliaTab({required this.tabController});

  @override
  State<_AustraliaTab> createState() => _AustraliaTabState();
}

class _AustraliaTabState extends State<_AustraliaTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.australia;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 4) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.australia,
      isActive: () => widget.tabController.index == 4,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 4) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('australia'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _SecLabel(
                  text: 'Quick Estimate', textColor: Color(0xFF7A3A1A)),
              _HeroCalcCard(
                tag: 'AUSTRALIAN MORTGAGE CALCULATOR',
                titleStart: 'Calculate with ',
                titleHighlight: 'LMI',
                titleEnd: '\n& offset account',
                field1Label: 'Property Value',
                field1Value: 'AU\$750K',
                field2Label: 'Deposit',
                field2Value: '10%',
                field3Label: 'Term',
                field3Value: '30 yr',
                buttonText: '🦘 Calculate Australian Mortgage',
                grad1: const Color(0xFF1A0A00),
                grad2: const Color(0xFF7C2D12),
                accentCircle: const Color(0x26002868),
                buttonColor: const Color(0xFF002868),
                watermarkEmoji: '🦘',
                onTap: () => context.push('/australia'),
              ),
              const _SecLabel(
                  text: 'LMI Calculator', textColor: Color(0xFF7A3A1A)),
              _AlertBanner(
                icon: '🛡️',
                title: 'Lenders Mortgage Insurance',
                subtitle:
                    'Required when deposit is below 20% — calculate LMI cost',
                buttonText: 'Calculate',
                bg1: const Color(0xFFFFF7ED),
                bg2: const Color(0xFFFFEDD5),
                borderColor: const Color(0xFFFCA5A5),
                buttonColor: const Color(0xFFEA580C),
                titleColor: const Color(0xFF7C2D12),
                subtitleColor: const Color(0xFFC2410C),
                onTap: () => context.push('/australia'),
              ),
              const _SecLabel(text: 'Core Tools', textColor: Color(0xFF7A3A1A)),
              _toolGrid([
                _ToolCard(
                    icon: '🏠',
                    name: 'Mortgage Calc',
                    desc: 'Variable & fixed rates',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF1A0A00),
                    customGrad2: const Color(0xFF7C2D12),
                    badge: 'LMI Incl.',
                    customBadgeBg: const Color(0xFFFFF7ED),
                    customBadgeText: const Color(0xFFC2410C),
                    onTap: () => navigateToTool(
                        context, 'australia', 'australia_mortgage_calc')),
                _ToolCard(
                    icon: '🛡️',
                    name: 'LMI Calculator',
                    desc: 'Insurance premium',
                    badge: '<20% dep.',
                    customBadgeBg: const Color(0xFFEFF6FF),
                    customBadgeText: const Color(0xFF1D4ED8),
                    onTap: () =>
                        navigateToTool(context, 'australia', 'australia_lmi')),
                _ToolCard(
                    icon: '🏦',
                    name: 'Offset Account',
                    desc: 'Interest savings calc',
                    style: _CardStyle.teal,
                    onTap: () => navigateToTool(
                        context, 'australia', 'australia_offset')),
                _ToolCard(
                    icon: '📊',
                    name: 'DTI Ratio',
                    desc: 'Debt-to-income AUS',
                    onTap: () =>
                        navigateToTool(context, 'australia', 'australia_dti')),
                _ToolCard(
                    icon: '💰',
                    name: 'Affordability',
                    desc: 'Borrowing capacity AUD',
                    onTap: () => navigateToTool(
                        context, 'australia', 'australia_affordability')),
                _ToolCard(
                    icon: '📅',
                    name: 'Amortization',
                    desc: 'Fortnightly schedule',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF002868),
                    customGrad2: const Color(0xFF1e3a8a),
                    onTap: () => navigateToTool(
                        context, 'australia', 'australia_amortization')),
                _ToolCard(
                    icon: '🏘️',
                    name: 'Stamp Duty (AUS)',
                    desc: 'State-by-state calc',
                    style: _CardStyle.gold,
                    onTap: () => navigateToTool(
                        context, 'australia', 'australia_stamp_duty')),
                _ToolCard(
                    icon: '🔄',
                    name: 'Refinance Tool',
                    desc: 'Switch lender savings',
                    onTap: () => navigateToTool(
                        context, 'australia', 'australia_refinance_tool')),
              ]),
              // ── Native Ad (Australia tab) ───────────────────────────────────────
              const NativeAdWidget(
                screenName: 'australia_home_native',
                adType: 'mediumCard',
              ),
              const _SecLabel(
                  text: 'State & Resources', textColor: Color(0xFF7A3A1A)),
              _InfoItem(
                  icon: '📋',
                  name: 'Stamp Duty by State',
                  sub: 'NSW, VIC, QLD, WA, SA, TAS…',
                  onTap: () => context.push('/australia')),
              _InfoItem(
                  icon: '🏡',
                  name: 'First Home Owner Grant',
                  sub: 'FHOG · First Home Guarantee',
                  onTap: () => context.push('/australia')),
              _InfoItem(
                  icon: '📉',
                  name: 'RBA Rate History',
                  sub: 'Reserve Bank of Australia tracker',
                  onTap: () => context.push('/australia')),
              _InfoItem(
                  icon: '🤖',
                  name: 'Australia AI Advisor',
                  sub: 'RBA rules · LMI · offset guidance',
                  onTap: () => context.push('/ai/au')),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ██████  NEW ZEALAND TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _NewZealandTab extends ConsumerStatefulWidget {
  final TabController tabController;
  const _NewZealandTab({required this.tabController});

  @override
  ConsumerState<_NewZealandTab> createState() => _NewZealandTabState();
}

class _NewZealandTabState extends ConsumerState<_NewZealandTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.newZealand;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 5) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.newZealand,
      isActive: () => widget.tabController.index == 5,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 5) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('nz'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _SecLabel(
                  text: 'Quick Estimate', textColor: Color(0xFF4A6358)),
              _HeroCalcCard(
                tag: 'NZ MORTGAGE CALCULATOR',
                titleStart: 'Calculate your ',
                titleHighlight: 'NZ Home Loan',
                titleEnd: '\nwith LVR & fees',
                field1Label: 'Property Value',
                field1Value: 'NZ\$850K',
                field2Label: 'Deposit',
                field2Value: '20%',
                field3Label: 'Term',
                field3Value: '30 yr',
                buttonText: '🌿 Calculate NZ Home Loan',
                grad1: const Color(0xFF0A0F0D),
                grad2: const Color(0xFF0D3B2E),
                accentCircle: const Color(0x361A6B4A),
                buttonColor: const Color(0xFF1A6B4A),
                watermarkEmoji: '🌿',
                onTap: () => context.push('/newzealand'),
              ),
              const _SecLabel(
                  text: 'Reserve Bank NZ', textColor: Color(0xFF4A6358)),
              Consumer(
                builder: (context, ref, _) {
                  final rc = RemoteConfigService.instance;
                  final ocr = rc.nzOcrRate;
                  final nextMeeting = rc.nzNextMeeting;
                  final cutProb = rc.nzCutProbability;
                  return _AlertBanner(
                    icon: '🏛️',
                    title: 'OCR Rate · RBNZ: $ocr%',
                    subtitle:
                        'Next RBNZ Review: $nextMeeting · Cut probability: $cutProb',
                    buttonText: 'RBNZ Live',
                    bg1: const Color(0xFF0A0F0D),
                    bg2: const Color(0xFF0D3B2E),
                    borderColor: const Color(0xFF0D3B2E),
                    buttonColor: _DT.teal,
                    titleColor: Colors.white,
                    subtitleColor: Colors.white70,
                    onTap: () => context.push('/newzealand'),
                  );
                },
              ),
              const _SecLabel(
                  text: 'NZ Market Snapshot', textColor: Color(0xFF4A6358)),
              Consumer(
                builder: (context, ref, _) {
                  final r = ref.watch(nzRatesProvider).valueOrNull;
                  final rc = RemoteConfigService.instance;
                  final nzdUsd = r?.nzdUsd.value ?? 0.5995;
                  final nzdAud = r?.nzdAud.value ?? 0.9240;
                  final nzdGbp = r?.nzdGbp.value ?? 0.4780;
                  final isLive = r?.isLive == true;
                  final badge = isLive ? '🟢 Live' : 'Est.';
                  return _MarketTicker(
                    title: 'NZX & Economic Indicators',
                    items: [
                      _TickerItem('NZD/USD', nzdUsd.toStringAsFixed(4),
                          isLive ? badge : 'Daily', isLive),
                      _TickerItem('NZD/AUD', nzdAud.toStringAsFixed(4),
                          isLive ? badge : 'Daily', isLive),
                      _TickerItem('NZD/GBP', nzdGbp.toStringAsFixed(4),
                          isLive ? badge : 'Daily', isLive),
                      _TickerItem('2-Yr Bond',
                          '${rc.nzBond2yr.toStringAsFixed(2)}%', 'Govt', false),
                      _TickerItem('10-Yr Bond',
                          '${rc.nzBond10yr.toStringAsFixed(2)}%', 'Govt', true),
                      _TickerItem('CPI', '${rc.nzCpi.toStringAsFixed(1)}%',
                          '↓ Easing', true),
                    ],
                  );
                },
              ),
              const _SecLabel(
                  text: 'Live Home Loan Rates',
                  more: 'Compare Lenders →',
                  textColor: Color(0xFF4A6358),
                  moreColor: Color(0xFF1A6B4A)),
              Consumer(
                builder: (context, ref, _) {
                  final r = ref.watch(nzRatesProvider).valueOrNull;
                  final f1 = r?.fixed1yr.value ?? 5.59;
                  final f2 = r?.fixed2yr.value ?? 5.29;
                  final f3 = r?.fixed3yr.value ?? 5.19;
                  final f5 = r?.fixed5yr.value ?? 5.09;
                  final fl = r?.floating.value ?? 7.24;
                  final live = r?.isLive == true;
                  final chg = live ? '🟢 Live' : 'Est.';
                  return SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(145),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.none,
                      children: [
                        _MiniRateCard(
                            icon: '🏠',
                            label: '1-Yr Fixed',
                            value: '${f1.toStringAsFixed(2)}%',
                            sub: 'ANZ / ASB',
                            change: chg,
                            isUp: true),
                        const SizedBox(width: 9),
                        _MiniRateCard(
                            icon: '📅',
                            label: '2-Yr Fixed',
                            value: '${f2.toStringAsFixed(2)}%',
                            sub: 'Kiwibank',
                            change: chg,
                            isUp: true),
                        const SizedBox(width: 9),
                        _MiniRateCard(
                            icon: '📆',
                            label: '3-Yr Fixed',
                            value: '${f3.toStringAsFixed(2)}%',
                            sub: 'Westpac',
                            change: chg,
                            isUp: true),
                        const SizedBox(width: 9),
                        _MiniRateCard(
                            icon: '📊',
                            label: '5-Yr Fixed',
                            value: '${f5.toStringAsFixed(2)}%',
                            sub: 'BNZ / Avg',
                            change: chg,
                            isUp: true),
                        const SizedBox(width: 9),
                        _MiniRateCard(
                            icon: '🔄',
                            label: 'Floating',
                            value: '${fl.toStringAsFixed(2)}%',
                            sub: 'Variable',
                            change: chg,
                            isUp: false),
                      ],
                    ),
                  );
                },
              ),
              const _SecLabel(
                  text: 'Core Home Loan Tools', textColor: Color(0xFF4A6358)),
              _toolGrid([
                _ToolCard(
                    icon: '🏠',
                    name: 'Mortgage Calc',
                    desc: 'NZD monthly payment',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF0A0F0D),
                    customGrad2: const Color(0xFF0D3B2E),
                    badge: 'Fixed & Float',
                    customBadgeBg: const Color(0xFFECFDF5),
                    customBadgeText: const Color(0xFF065F46),
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_core_mortgage_calc')),
                _ToolCard(
                    icon: '📊',
                    name: 'Repayment Calc',
                    desc: 'P&I vs interest only',
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_core_repayment_calc')),
                _ToolCard(
                    icon: '📈',
                    name: 'DTI Calculator',
                    desc: 'Debt-to-income NZ',
                    badge: '6x Cap',
                    customBadgeBg: const Color(0xFFFEF2F2),
                    customBadgeText: const Color(0xFFC0392B),
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_core_dti_calculator')),
                _ToolCard(
                    icon: '📅',
                    name: 'Amortization',
                    desc: 'Full repayment schedule',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF1A6B4A),
                    customGrad2: const Color(0xFF0D3B2E),
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_core_amortization')),
                _ToolCard(
                    icon: '💰',
                    name: 'Affordability Calc',
                    desc: 'Max borrowing NZD',
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_core_affordability_calc')),
                _ToolCard(
                    icon: '🔄',
                    name: 'Refixing Calc',
                    desc: 'Best term to refix',
                    style: _CardStyle.teal,
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_core_refixing_calc')),
              ]),
              const _SecLabel(
                  text: 'LVR Restrictions', textColor: Color(0xFF4A6358)),
              _alertBannerYellow(
                icon: '⚠️',
                title: 'Loan-to-Value Restrictions (LVR)',
                subtitle:
                    'Owner-occ: 20% min deposit · Investor: 35% min deposit (RBNZ 2024)',
                buttonText: 'Check LVR',
                onTap: () => context.push('/newzealand'),
              ),
              const _SecLabel(text: 'KiwiSaver', textColor: Color(0xFF4A6358)),
              _AlertBanner(
                icon: '🥝',
                title: 'KiwiSaver First-Home Withdrawal',
                subtitle:
                    'Use KiwiSaver savings as deposit · \$10K HomeStart Grant eligible',
                buttonText: 'Calculate',
                bg1: const Color(0xFFF0FDFA),
                bg2: const Color(0xFFCCFBF1),
                borderColor: const Color(0xFF5EEAD4),
                buttonColor: _DT.teal,
                titleColor: const Color(0xFF0F766E),
                subtitleColor: const Color(0xFF0D9488),
                onTap: () => context.push('/newzealand'),
              ),
              _toolGrid([
                _ToolCard(
                    icon: '🥝',
                    name: 'KiwiSaver Calc',
                    desc: 'First-home withdrawal',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF1A6B4A),
                    customGrad2: const Color(0xFF0D3B2E),
                    badge: '3yr min',
                    customBadgeBg: const Color(0xFFF0FDFA),
                    customBadgeText: const Color(0xFF0F766E),
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_kiwisaver_calc')),
                _ToolCard(
                    icon: '🎁',
                    name: 'HomeStart Grant',
                    desc: '\$10K new / \$5K existing',
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_kiwisaver_homestart_grant')),
                _ToolCard(
                    icon: '📦',
                    name: 'KiwiSaver Balance',
                    desc: 'Projection calculator',
                    onTap: () => navigateToTool(
                        context, 'newzealand', 'nz_kiwisaver_balance')),
                _ToolCard(
                    icon: '👥',
                    name: 'Employer Contrib.',
                    desc: '3% match tracker',
                    style: _CardStyle.teal,
                    onTap: () => navigateToTool(context, 'newzealand',
                        'nz_kiwisaver_employer_contrib')),
              ]),
              // ── Native Ad (New Zealand tab) ─────────────────────────────────────
              const NativeAdWidget(
                screenName: 'newzealand_home_native',
                adType: 'mediumCard',
              ),
              const _SecLabel(
                  text: 'Region House Prices',
                  more: 'All Regions →',
                  textColor: Color(0xFF4A6358),
                  moreColor: Color(0xFF1A6B4A)),
              Consumer(
                builder: (context, ref, _) {
                  final rc = RemoteConfigService.instance;
                  return SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(130),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      clipBehavior: Clip.none,
                      children: [
                        _RegionCard(
                            icon: '🏙️',
                            name: 'Auckland',
                            sub: 'Metro',
                            price: 'NZ\$${rc.nzPriceAuckland}K',
                            change: '↓ -1.2%',
                            isUp: false),
                        const SizedBox(width: 9),
                        _RegionCard(
                            icon: '🌊',
                            name: 'Wellington',
                            sub: 'Capital',
                            price: 'NZ\$${rc.nzPriceWellington}K',
                            change: '↓ -2.4%',
                            isUp: false),
                        const SizedBox(width: 9),
                        _RegionCard(
                            icon: '🏔️',
                            name: 'Christchurch',
                            sub: 'South Island',
                            price: 'NZ\$${rc.nzPriceChristchurch}K',
                            change: '↑ +1.8%',
                            isUp: true),
                        const SizedBox(width: 9),
                        _RegionCard(
                            icon: '🌺',
                            name: 'Hamilton',
                            sub: 'Waikato',
                            price: 'NZ\$${rc.nzPriceHamilton}K',
                            change: '↑ +0.5%',
                            isUp: true),
                        const SizedBox(width: 9),
                        _RegionCard(
                            icon: '🍇',
                            name: 'Dunedin',
                            sub: 'Otago',
                            price: 'NZ\$${rc.nzPriceDunedin}K',
                            change: '↑ +2.1%',
                            isUp: true),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const _SecLabel(
                  text: 'Government & Resources', textColor: Color(0xFF4A6358)),
              _InfoItem(
                  icon: '🏡',
                  name: 'Kāinga Ora (Housing NZ)',
                  sub: 'Public housing · First Home Partner scheme',
                  onTap: () => context.push('/newzealand')),
              _InfoItem(
                  icon: '🏛️',
                  name: 'RBNZ OCR Rate History',
                  sub: 'Official Cash Rate decisions since 1999',
                  onTap: () => context.push('/newzealand')),
              _InfoItem(
                  icon: '📊',
                  name: 'REINZ House Price Index',
                  sub: 'Real Estate Institute NZ · monthly HPI',
                  onTap: () => context.push('/newzealand')),
              _InfoItem(
                  icon: '🤖',
                  name: 'NZ AI Mortgage Advisor',
                  sub: 'LVR · KiwiSaver · bright-line guidance',
                  onTap: () => context.push('/ai/nz')),
            ]),
          ),
        ),
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  final String icon;
  final String name;
  final String sub;
  final String price;
  final String change;
  final bool isUp;
  const _RegionCard(
      {required this.icon,
      required this.name,
      required this.sub,
      required this.price,
      required this.change,
      required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
      decoration: BoxDecoration(
        color: _DT.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _DT.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _DT.navy,
                  fontFamily: 'DMSans')),
          Text(sub,
              style: TextStyle(
                  fontSize: 9, color: _DT.muted, fontFamily: 'DMSans')),
          const SizedBox(height: 6),
          Text(price,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A6B4A),
                  fontFamily: 'DMSans')),
          Text(change,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isUp ? _DT.upColor : _DT.dnColor,
                  fontFamily: 'DMSans')),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ██████  EUROPE TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _EuropeTab extends StatefulWidget {
  final TabController tabController;
  const _EuropeTab({required this.tabController});

  @override
  State<_EuropeTab> createState() => _EuropeTabState();
}

class _EuropeTabState extends State<_EuropeTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.europe;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 6) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.europe,
      isActive: () => widget.tabController.index == 6,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 6) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      key: const PageStorageKey('europe'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Live ECB rate strip
              Consumer(
                builder: (context, ref, _) {
                  final ratesAsync = ref.watch(europeRatesProvider);
                  final r = ratesAsync.valueOrNull;
                  final ecb = r?.ecbRate.value ?? 4.00;
                  final eu6m = r?.euribor6m.value ?? 3.42;
                  final isLive = r?.isLive == true;
                  return _CountryRateStrip(
                    borderColor: const Color(0x14003399),
                    items: [
                      _RateItem(
                          '🇩🇪 Germany',
                          '${(ecb + 0.85).toStringAsFixed(2)}%',
                          _RateColor.green),
                      _RateItem(
                          '🇫🇷 France',
                          '${(ecb + 0.60).toStringAsFixed(2)}%',
                          _RateColor.normal),
                      _RateItem(
                          '🇪🇸 Spain',
                          '${(eu6m + 1.10).toStringAsFixed(2)}%',
                          _RateColor.red),
                      _RateItem(
                          'ECB Rate',
                          '${ecb.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}',
                          _RateColor.gold),
                    ],
                  );
                },
              ),
              const _SecLabel(
                  text: 'Select Country',
                  more: 'Compare all →',
                  textColor: Color(0xFF6B21A8),
                  moreColor: Color(0xFF003399)),
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(44),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  clipBehavior: Clip.none,
                  children: const [
                    _CountryPill(
                        flag: '🇩🇪', label: 'Germany', isActive: true),
                    SizedBox(width: 8),
                    _CountryPill(flag: '🇫🇷', label: 'France'),
                    SizedBox(width: 8),
                    _CountryPill(flag: '🇪🇸', label: 'Spain'),
                    SizedBox(width: 8),
                    _CountryPill(flag: '🇮🇹', label: 'Italy'),
                    SizedBox(width: 8),
                    _CountryPill(flag: '🇳🇱', label: 'Netherlands'),
                    SizedBox(width: 8),
                    _CountryPill(flag: '🇵🇹', label: 'Portugal'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Consumer(
                builder: (context, ref, _) {
                  final ratesAsync = ref.watch(europeRatesProvider);
                  final r = ratesAsync.valueOrNull;
                  final eu3m = r?.euribor3m.value ?? 3.65;
                  final isLive = r?.isLive == true;
                  return _HeroCalcCard(
                    tag: 'EUROPEAN MORTGAGE CALCULATOR',
                    titleStart: 'Calculate your ',
                    titleHighlight: 'Baufinanzierung',
                    titleEnd: '\npayment in EUR',
                    field1Label: 'Property Value',
                    field1Value: '€420,000',
                    field2Label: 'Euribor 3M',
                    field2Value:
                        '${eu3m.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}',
                    field3Label: 'Term',
                    field3Value: '20 yr',
                    buttonText: '⭐ Calculate European Mortgage',
                    grad1: const Color(0xFF003399),
                    grad2: const Color(0xFF1A0040),
                    accentCircle: const Color(0x20FFCC00),
                    buttonColor: const Color(0xFFFFCC00),
                    buttonTextColor: const Color(0xFF003399),
                    watermarkEmoji: '⭐',
                    onTap: () => context.push('/europe'),
                  );
                },
              ),
              const _SecLabel(
                  text: 'ECB Rate Monitor', textColor: Color(0xFF6B21A8)),
              // Live ECB Rate Monitor banner
              Consumer(
                builder: (context, ref, _) {
                  final ratesAsync = ref.watch(europeRatesProvider);
                  final r = ratesAsync.valueOrNull;
                  final ecb = r?.ecbRate.value ?? 4.00;
                  final isLive = r?.isLive == true;
                  return _AlertBanner(
                    icon: '🏛️',
                    title:
                        'ECB Rate: ${ecb.toStringAsFixed(2)}%${isLive ? '  🟢 Live' : ''}',
                    subtitle:
                        'European Central Bank — affects all Eurozone mortgages',
                    buttonText: 'View ECB',
                    bg1: const Color(0xFFEEF2FF),
                    bg2: const Color(0xFFE0E7FF),
                    borderColor: const Color(0xFF818CF8),
                    buttonColor: const Color(0xFF4F46E5),
                    titleColor: const Color(0xFF1e1b4b),
                    subtitleColor: const Color(0xFF4338ca),
                    onTap: () => context.push('/europe'),
                  );
                },
              ),
              const SizedBox(height: 10),
              const _SecLabel(text: 'Core Tools', textColor: Color(0xFF6B21A8)),
              _toolGrid([
                _ToolCard(
                    icon: '🏠',
                    name: 'Mortgage Calc',
                    desc: 'EUR monthly payment',
                    style: _CardStyle.custom,
                    customGrad1: const Color(0xFF003399),
                    customGrad2: const Color(0xFF1A0040),
                    badge: 'Multi-country',
                    customBadgeBg: const Color(0xFFEEF2FF),
                    customBadgeText: const Color(0xFF3730A3),
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_mortgage_calc')),
                _ToolCard(
                    icon: '📊',
                    name: 'DTI Ratio EUR',
                    desc: 'Debt-to-income Europe',
                    onTap: () =>
                        navigateToTool(context, 'europe', 'europe_dti')),
                _ToolCard(
                    icon: '🏛️',
                    name: 'Property Tax Calc',
                    desc: 'Country-specific taxes',
                    style: _CardStyle.violet,
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_property_tax_calc')),
                _ToolCard(
                    icon: '💶',
                    name: 'Affordability EUR',
                    desc: 'Borrowing capacity',
                    badge: 'Per country',
                    customBadgeBg: const Color(0xFFF0FDF4),
                    customBadgeText: const Color(0xFF166534),
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_affordability')),
                _ToolCard(
                    icon: '📅',
                    name: 'Amortization',
                    desc: 'European schedule',
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_amortization')),
                _ToolCard(
                    icon: '🔄',
                    name: 'Euribor Tracker',
                    desc: 'Variable rate index',
                    style: _CardStyle.gold,
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_euribor_tracker')),
                _ToolCard(
                    icon: '🌍',
                    name: 'Country Comparison',
                    desc: 'Compare EU rates',
                    style: _CardStyle.teal,
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_country_comparison')),
                _ToolCard(
                    icon: '📜',
                    name: 'Notary Fee Calc',
                    desc: 'DE/FR/ES closing costs',
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_notary_fee_calc')),
                _ToolCard(
                    icon: '🏘️',
                    name: 'Non-Resident Calc',
                    desc: 'Foreign buyer guide',
                    style: _CardStyle.slate,
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_non_resident_calc')),
                _ToolCard(
                    icon: '💱',
                    name: 'Currency Converter',
                    desc: 'EUR · GBP · USD · CHF',
                    onTap: () => navigateToTool(
                        context, 'europe', 'europe_currency_converter')),
              ]),
              // ── Native Ad (Europe tab) ──────────────────────────────────────────
              const NativeAdWidget(
                screenName: 'europe_home_native',
                adType: 'mediumCard',
              ),
              const _SecLabel(
                  text: 'Countries & Resources', textColor: Color(0xFF6B21A8)),
              _InfoItem(
                  icon: '🇩🇪',
                  name: 'Germany – Baufinanzierung',
                  sub: '10yr fixed · Grunderwerbsteuer',
                  onTap: () => context.push('/europe')),
              _InfoItem(
                  icon: '🇫🇷',
                  name: 'France – Prêt Immobilier',
                  sub: '20yr fixed · Frais de notaire',
                  onTap: () => context.push('/europe')),
              _InfoItem(
                  icon: '🇪🇸',
                  name: 'Spain – Hipoteca',
                  sub: 'Euribor variable · ITP/AJD tax',
                  onTap: () => context.push('/europe')),
              _InfoItem(
                  icon: '🤖',
                  name: 'Europe AI Advisor',
                  sub: 'ECB rules · multi-country guidance',
                  onTap: () => context.push('/ai/eu')),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CountryPill extends StatelessWidget {
  final String flag;
  final String label;
  final bool isActive;
  const _CountryPill(
      {required this.flag, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF003399) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isActive ? const Color(0xFF003399) : const Color(0x26003399)),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: const Color(0xFF003399).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFF1A0040),
                  fontFamily: 'DMSans')),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ██████  INDIA TAB  ██████
// ═══════════════════════════════════════════════════════════════
class _IndiaTab extends StatefulWidget {
  final TabController tabController;
  const _IndiaTab({required this.tabController});

  @override
  State<_IndiaTab> createState() => _IndiaTabState();
}

class _IndiaTabState extends State<_IndiaTab>
    with AutomaticKeepAliveClientMixin, ScreenTimerMixin {
  int _selectedCategory = 0; // 0 = Core Loan Calcs, 1 = Tax & Govt Tools

  @override
  String get screenName => AnalyticsScreen.india;

  ScrollDepthTracker? _scrollTracker;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    if (widget.tabController.index == 7) {
      startScreenTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollTracker ??= ScrollDepthTracker(
      controller: PrimaryScrollController.of(context),
      screenName: AnalyticsScreen.india,
      isActive: () => widget.tabController.index == 7,
    );
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    stopScreenTimer();
    _scrollTracker?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 7) {
      startScreenTimer();
    } else {
      stopScreenTimer();
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secLabelColor =
        isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C);

    return CustomScrollView(
      key: const PageStorageKey('india'),
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.textScalerOf(context).scale(0.0),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            15,
            16,
            15,
            MediaQuery.of(context).padding.bottom + 80,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Quick EMI Estimate ────────────────────────────────────────
              _SecLabel(text: 'Quick EMI Estimate', textColor: secLabelColor),
              _IndiaHeroCard(
                onTap: () => context.push('/india'),
              ),
              const SizedBox(height: 4),

              // ── Reserve Bank of India ─────────────────────────────────────
              _SecLabel(
                  text: 'Reserve Bank of India', textColor: secLabelColor),
              _AlertBanner(
                icon: '🏛️',
                title: 'RBI Repo Rate: 6.50%',
                subtitle: 'Next MPC Meeting: Jun 7 · Rate cut expected Q3 2024',
                buttonText: 'RBI Live',
                bg1: const Color(0xFF0B1F48),
                bg2: const Color(0xFF1A3A8F),
                borderColor: const Color(0xFF1A3A8F),
                buttonColor: const Color(0xFFFF6B00),
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
                onTap: () => context.push('/india'),
              ),
              const SizedBox(height: 4),

              // ── Segmented Category Selector ──────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _DT.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedCategory == 0
                                ? (isDark
                                    ? const Color(0xFF334155)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _selectedCategory == 0
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Core Loan Calcs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _selectedCategory == 0
                                  ? _DT.royal
                                  : _DT.muted,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedCategory == 1
                                ? (isDark
                                    ? const Color(0xFF334155)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _selectedCategory == 1
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tax & Govt Tools',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _selectedCategory == 1
                                  ? _DT.royal
                                  : _DT.muted,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Grid Display ──────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _selectedCategory == 0
                    ? _toolGrid([
                        _ToolCard(
                            icon: '🏠',
                            name: 'EMI Calculator',
                            desc: 'Monthly installment',
                            style: _CardStyle.custom,
                            customGrad1: const Color(0xFF0B1F48),
                            customGrad2: const Color(0xFF1A3A8F),
                            badge: '₹ INR',
                            customBadgeBg: const Color(0xFFFFF3E0),
                            customBadgeText: const Color(0xFFE05A00),
                            onTap: () => navigateToTool(
                                context, 'india', 'india_core_emi_calculator')),
                        _ToolCard(
                            icon: '📊',
                            name: 'Amortization',
                            desc: 'Full repayment schedule',
                            onTap: () => navigateToTool(
                                context, 'india', 'india_core_amortization')),
                        _ToolCard(
                            icon: '💰',
                            name: 'Loan Eligibility',
                            desc: 'Max loan on salary',
                            badge: 'FOIR Check',
                            customBadgeBg: const Color(0xFFECFDF5),
                            customBadgeText: const Color(0xFF065F46),
                            onTap: () => navigateToTool(context, 'india',
                                'india_core_loan_eligibility')),
                        _ToolCard(
                            icon: '📅',
                            name: 'Prepayment Calc',
                            desc: 'Part payment savings',
                            style: _CardStyle.custom,
                            customGrad1: const Color(0xFFFF6B00),
                            customGrad2: const Color(0xFFE05A00),
                            onTap: () => navigateToTool(context, 'india',
                                'india_core_prepayment_calc')),
                        _ToolCard(
                            icon: '🔄',
                            name: 'Balance Transfer',
                            desc: 'Switch bank savings',
                            onTap: () => navigateToTool(context, 'india',
                                'india_core_balance_transfer')),
                        _ToolCard(
                            icon: '📈',
                            name: 'FOIR Calculator',
                            desc: 'Fixed obligation ratio',
                            style: _CardStyle.custom,
                            customGrad1: const Color(0xFF046A38),
                            customGrad2: const Color(0xFF07543A),
                            onTap: () => navigateToTool(context, 'india',
                                'india_core_foir_calculator')),
                        _ToolCard(
                            icon: '🏗️',
                            name: 'Under Construction',
                            desc: 'Pre-EMI vs full EMI',
                            onTap: () => navigateToTool(context, 'india',
                                'india_core_under_construction')),
                        _ToolCard(
                            icon: '🤝',
                            name: 'Joint Loan Calc',
                            desc: 'Co-applicant benefit',
                            style: _CardStyle.gold,
                            onTap: () => navigateToTool(context, 'india',
                                'india_core_joint_loan_calc')),
                      ])
                    : _toolGrid([
                        _ToolCard(
                            icon: '🏛️',
                            name: 'Stamp Duty Calc',
                            desc: 'State-wise stamp duty',
                            style: _CardStyle.custom,
                            customGrad1: const Color(0xFF0B1F48),
                            customGrad2: const Color(0xFF1A3A8F),
                            badge: 'All States',
                            customBadgeBg: const Color(0xFFFFF3E0),
                            customBadgeText: const Color(0xFFE05A00),
                            onTap: () => navigateToTool(context, 'india',
                                'india_govt_stamp_duty_calc')),
                        _ToolCard(
                            icon: '📋',
                            name: 'GST Calculator',
                            desc: 'Under-constr. 5%',
                            onTap: () => navigateToTool(
                                context, 'india', 'india_govt_gst_calculator')),
                        _ToolCard(
                            icon: '🏠',
                            name: 'PMAY Subsidy',
                            desc: 'Interest subsidy calc',
                            badge: '₹2.67L max',
                            customBadgeBg: const Color(0xFFECFDF5),
                            customBadgeText: const Color(0xFF065F46),
                            onTap: () => navigateToTool(
                                context, 'india', 'india_govt_pmay_subsidy')),
                        _ToolCard(
                            icon: '💳',
                            name: 'CIBIL Score Impact',
                            desc: 'Score → loan rate',
                            badge: '750+ ideal',
                            customBadgeBg: const Color(0xFFEFF6FF),
                            customBadgeText: const Color(0xFF1D4ED8),
                            onTap: () => navigateToTool(context, 'india',
                                'india_govt_cibil_score_impact')),
                      ]),
              ),
              const SizedBox(height: 14),

              // ── Native Ad (India tab) ───────────────────────────────────────────
              const NativeAdWidget(
                screenName: 'india_home_native',
                adType: 'mediumCard',
              ),

              _SecLabel(
                  text: 'Government & Resources', textColor: secLabelColor),
              _InfoItem(
                  icon: '🏛️',
                  name: 'RBI Monetary Policy',
                  sub: 'Repo rate decisions · MPC calendar',
                  onTap: () => context.push('/india')),
              _InfoItem(
                  icon: '🏡',
                  name: 'NHB House Price Index',
                  sub: 'National Housing Bank · city data',
                  onTap: () => context.push('/india')),
              _InfoItem(
                  icon: '🏡',
                  name: 'PMAY Housing Scheme',
                  sub: 'Check urban/rural interest subsidy',
                  onTap: () => context.push('/india')),
              _InfoItem(
                  icon: '🤖',
                  name: 'India AI Mortgage Advisor',
                  sub: 'RBI · PMAY · 80C guidance',
                  onTap: () => context.push('/tool/india/in_india_ai_advisor')),
            ]),
          ),
        ),
      ],
    );
  }
}

class _IndiaHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _IndiaHeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0B1F48)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9933).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background circle accents
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0CFF9933),
              ),
            ),
          ),
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x0C128807),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x26FF9933),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x33FF9933)),
                      ),
                      child: const Text(
                        'भारत HOME LOAN EMI',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF9933),
                          letterSpacing: 0.5,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text('☸',
                        style: TextStyle(fontSize: 16, color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.2),
                    children: [
                      TextSpan(text: 'Calculate your '),
                      TextSpan(
                        text: 'Home Loan EMI',
                        style: TextStyle(
                            color: Color(0xFFFF9933),
                            fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '\nwith visual breakdown'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Highlight fields
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallSpec(
                          'Loan Amount', '₹50 Lakhs', const Color(0x1F22C55E)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSmallSpec('Interest Rate', '8.50% p.a.',
                          const Color(0x1FEAB308)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSmallSpec(
                          'Tenure', '20 Years', const Color(0x1F3B82F6)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Visual bar representation (Principal vs Interest)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🟢 Principal: 42%',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans'),
                        ),
                        Text(
                          '🟠 Interest: 58%',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'DMSans'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 7,
                        width: double.infinity,
                        color: const Color(0x1AFFFFFF),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 42,
                              child: Container(color: const Color(0xFF128807)),
                            ),
                            Expanded(
                              flex: 58,
                              child: Container(color: const Color(0xFFFF9933)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Button
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9933), Color(0xFFFF6B00)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFF6B00).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Calculate India EMI & Save Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSpec(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 8,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSans'),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'DMSans'),
          ),
        ],
      ),
    );
  }
}
