// lib/features/usa/screens/usa_top_lenders_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

class USATopLendersScreen extends ConsumerStatefulWidget {
  const USATopLendersScreen({super.key});

  @override
  ConsumerState<USATopLendersScreen> createState() => _USATopLendersScreenState();
}

class _USATopLendersScreenState extends ConsumerState<USATopLendersScreen> {
  static const _theme = CountryThemes.usa;

  static const List<Map<String, dynamic>> _lenderOriginations = [
    {'name': 'Rocket', 'pct': 6.8, 'vol': 128, 'gradient': [Color(0xFFB91C1C), Color(0xFF991B1B)], 'emoji': '🚀'},
    {'name': 'UWM', 'pct': 5.4, 'vol': 102, 'gradient': [Color(0xFF1B3F72), Color(0xFF0B1D3A)], 'emoji': '🏛️'},
    {'name': 'Chase', 'pct': 4.7, 'vol': 89, 'gradient': [Color(0xFF0F766E), Color(0xFF0D9488)], 'emoji': '🏦'},
    {'name': 'Wells', 'pct': 3.9, 'vol': 74, 'gradient': [Color(0xFFD97706), Color(0xFFB45309)], 'emoji': '🏢'},
    {'name': 'loanDepot', 'pct': 3.1, 'vol': 58, 'gradient': [Color(0xFF6D28D9), Color(0xFF4C1D95)], 'emoji': '🌐'},
    {'name': 'Fairway', 'pct': 2.4, 'vol': 45, 'gradient': [Color(0xFF15803D), Color(0xFF166534)], 'emoji': '🏠'},
    {'name': 'BofA', 'pct': 2.0, 'vol': 38, 'gradient': [Color(0xFF334155), Color(0xFF1E293B)], 'emoji': '🌟'}
  ];

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    final mortgage30Async = ref.watch(fredMortgage30Provider);
    final mortgage15Async = ref.watch(fredMortgage15Provider);
    final sofrAsync = ref.watch(fredSofrProvider);
    final fedFundsAsync = ref.watch(fredFedFundsProvider);

    final m30Val = mortgage30Async.valueOrNull?.value ?? 6.82;
    final m15Val = mortgage15Async.valueOrNull?.value ?? 6.11;
    final sofrVal = sofrAsync.valueOrNull?.value ?? 5.33;
    final fedFundsVal = fedFundsAsync.valueOrNull?.value ?? 5.33;

    final maxShare = _lenderOriginations.map((l) => l['pct'] as double).reduce((a, b) => a > b ? a : b);

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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(gradient: _theme.headerGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🦅', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('Top US Mortgage Lenders', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('2024 Originations · HMDA Data · Live Rates', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _theme.primaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStripItem('30-Yr Fixed', '${m30Val.toStringAsFixed(2)}%', mortgage30Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Freddie Mac', textCol),
                      _buildStripItem('15-Yr Fixed', '${m15Val.toStringAsFixed(2)}%', mortgage15Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Avg', textCol),
                      _buildStripItem('5/1 ARM', '${(sofrVal + 0.72).toStringAsFixed(2)}%', sofrAsync.valueOrNull?.isLive == true ? 'FRED SOFR' : 'Avg', textCol),
                      _buildStripItem('Fed Funds', '${fedFundsVal.toStringAsFixed(2)}%', fedFundsAsync.valueOrNull?.isLive == true ? 'FRED Live' : 'FOMC', Colors.amber),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Market Overview
                    _buildSectionHeader('Market Overview', '2024 Data', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('US MORTGAGE MARKET · 2024', style: TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text('\$1.7 Trillion Originated\nTop 10 Lenders = 34% Market Share', style: AppTextStyles.playfair(color: Colors.white, size: 15, weight: FontWeight.bold, height: 1.25)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildOverviewBox('\$1.7T', 'Total Market'),
                              const SizedBox(width: 8),
                              _buildOverviewBox('5,000+', 'Active Lenders'),
                              const SizedBox(width: 8),
                              _buildOverviewBox('7.2M', 'Loans Originated'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Market share originations bar chart
                    _buildSectionHeader('Market Share', 'HMDA 2024', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('2024 Origination Volume', style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.bold)),
                              const Text('Source: HMDA / CFPB', style: TextStyle(fontSize: 8.5, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: _lenderOriginations.map((l) {
                              final name = l['name'] as String;
                              final pct = l['pct'] as double;
                              final vol = l['vol'] as int;
                              final gr = l['gradient'] as List<Color>;
                              final em = l['emoji'] as String;
                              final barPct = pct / maxShare;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 65,
                                      child: Text('$em $name', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(20)),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: barPct,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: gr),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 30,
                                      child: Text('$pct%', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 38,
                                      child: Text('\$${vol}B', style: const TextStyle(fontSize: 8.5, color: Colors.grey), textAlign: TextAlign.right),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Lender #1: Rocket Mortgage
                    _buildSectionHeader('#1 Lender', 'Updated Jun 2025', mutedCol),
                    _buildLenderCard(
                      '1',
                      '🚀',
                      'Rocket Mortgage',
                      'Online / Detroit, MI · Est. 1985',
                      'Online',
                      Colors.blue.withValues(alpha: 0.1),
                      Colors.blue,
                      r'$128B', '4.8★', '8 min',
                      '${(m30Val + 0.055).toStringAsFixed(3)}%', '${(m30Val + 0.20).toStringAsFixed(2)}%',
                      '${(m15Val + 0.015).toStringAsFixed(3)}%', '${(m15Val + 0.20).toStringAsFixed(2)}%',
                      '${(m30Val - 0.32).toStringAsFixed(2)}%', '${(m30Val + 0.63).toStringAsFixed(2)}%',
                      ['✓ Fast Approval', '✓ All 50 States', '✓ Great App'],
                      ['✗ No In-Person', '✗ High Fees'],
                      'Check Rocket Mortgage Rates →',
                      const Color(0xFFB91C1C),
                      cardBg, textCol, mutedCol, borderCol, bgCol,
                    ),

                    // Lender #2: UWM
                    const SizedBox(height: 10),
                    _buildLenderCard(
                      '2',
                      '🏛️',
                      'United Wholesale Mortgage',
                      'Wholesale / Pontiac, MI · Est. 1986',
                      'Wholesale',
                      Colors.purple.withValues(alpha: 0.1),
                      Colors.purple,
                      r'$102B', '4.6★', 'Broker',
                      '${(m30Val - 0.07).toStringAsFixed(2)}%', '${(m30Val + 0.07).toStringAsFixed(2)}%',
                      '${(m15Val - 0.11).toStringAsFixed(2)}%', '${(m15Val + 0.07).toStringAsFixed(2)}%',
                      '${(m30Val - 0.57).toStringAsFixed(2)}%', '${(m30Val - 0.22).toStringAsFixed(2)}%',
                      ['✓ Low Rates', '✓ Fast Close'],
                      ['✗ Broker Only', '✗ Not Direct'],
                      'Find UWM Broker Near You →',
                      _theme.primaryColor,
                      cardBg, textCol, mutedCol, borderCol, bgCol,
                    ),

                    // Lender #3: Chase
                    const SizedBox(height: 10),
                    _buildLenderCard(
                      '3',
                      '🏦',
                      'JPMorgan Chase',
                      'Bank / New York, NY · Est. 1799',
                      'Big Bank',
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green,
                      r'$89B', '4.5★', '4,900+',
                      '${(m30Val + 0.08).toStringAsFixed(2)}%', '${(m30Val + 0.23).toStringAsFixed(2)}%',
                      '${(m15Val + 0.04).toStringAsFixed(2)}%', '${(m15Val + 0.23).toStringAsFixed(2)}%',
                      '${(m30Val + 0.18).toStringAsFixed(2)}%', '${(m30Val + 0.30).toStringAsFixed(2)}%',
                      ['✓ Existing Customers', '✓ Jumbo Loans'],
                      ['✗ Strict Criteria', '✗ Slower Process'],
                      'Explore Chase Mortgage →',
                      _theme.primaryColor,
                      cardBg, textCol, mutedCol, borderCol, bgCol,
                    ),

                    // Lender #4: Wells Fargo
                    const SizedBox(height: 10),
                    _buildLenderCard(
                      '4',
                      '🐎',
                      'Wells Fargo',
                      'Bank / San Francisco, CA · Est. 1852',
                      'Big Bank',
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green,
                      r'$74B', '4.1★', '4,500+',
                      '${(m30Val + 0.13).toStringAsFixed(3)}%', '${(m30Val + 0.28).toStringAsFixed(2)}%',
                      '${(m15Val + 0.09).toStringAsFixed(2)}%', '${(m15Val + 0.29).toStringAsFixed(2)}%',
                      '${(m30Val - 0.195).toStringAsFixed(3)}%', '${(m30Val + 0.70).toStringAsFixed(2)}%',
                      ['✓ Wide Branch Network', '✓ DPA Programs'],
                      ['✗ Past Scandals'],
                      'Explore Wells Fargo →',
                      _theme.primaryColor,
                      cardBg, textCol, mutedCol, borderCol, bgCol,
                    ),

                    // Lender #5: loanDepot
                    const SizedBox(height: 10),
                    _buildLenderCard(
                      '5',
                      '🌐',
                      'loanDepot',
                      'Non-Bank / Irvine, CA · Est. 2010',
                      'Online+Branch',
                      Colors.blue.withValues(alpha: 0.1),
                      Colors.blue,
                      r'$58B', '4.3★', '200+',
                      '${(m30Val + 0.03).toStringAsFixed(2)}%', '${(m30Val + 0.18).toStringAsFixed(2)}%',
                      '${(m15Val - 0.01).toStringAsFixed(2)}%', '${(m15Val + 0.17).toStringAsFixed(2)}%',
                      '${(m30Val - 0.445).toStringAsFixed(3)}%', '${(m30Val - 0.11).toStringAsFixed(2)}%',
                      ['✓ Lifetime Guarantee', '✓ VA Specialist'],
                      ['✗ Data Breach 2024'],
                      'Explore loanDepot →',
                      _theme.primaryColor,
                      cardBg, textCol, mutedCol, borderCol, bgCol,
                    ),

                    // Comparison Matrix
                    _buildSectionHeader('Quick Comparison', 'All Products', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          _buildCompRow('', 'Rocket', 'Chase', 'UWM', isHeader: true),
                          _buildCompRow('30-Yr Rate', '${(m30Val + 0.06).toStringAsFixed(2)}%', '${(m30Val + 0.08).toStringAsFixed(2)}%', '${(m30Val - 0.07).toStringAsFixed(2)}%', bestIdx: 3),
                          _buildCompRow('Min. Down', '3%', '3%', '3%'),
                          _buildCompRow('Min. Credit', '620', '620', '580', bestIdx: 3),
                          _buildCompRow('Pre-Approval', '8 min', '1-3 days', 'Same day', bestIdx: 1),
                          _buildCompRow('Online App', '★★★★★', '★★★★', 'N/A', bestIdx: 1),
                          _buildCompRow('J.D. Power', '4.8★', '4.5★', '4.6★', bestIdx: 1),
                        ],
                      ),
                    ),

                    // Disclosure Banner
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚠️ Rate Disclosure', style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                          const SizedBox(height: 4),
                          Text(
                            'Rates shown are estimated as of June 2025 for a 760 FICO score, 80% LTV, single-family primary residence. Your actual rate will vary. Always get multiple quotes. NMLS-registered lenders only. Data sourced from HMDA 2024 annual report.',
                            style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFB45309), height: 1.4),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildStripItem(String label, String val, String note, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.white54, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: color)),
        Text(note, style: const TextStyle(fontSize: 7.5, color: Colors.white38)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String tagText, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: labelColor, letterSpacing: 0.8)),
          if (tagText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewBox(String val, String lbl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(val, style: AppTextStyles.dmSans(size: 15, weight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(lbl, style: const TextStyle(fontSize: 8, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildLenderCard(
    String rank,
    String emoji,
    String name,
    String typeStr,
    String badgeText,
    Color badgeBg,
    Color badgeTextCol,
    String vol, String jd, String speed,
    String r30, String a30,
    String r15, String a15,
    String rOth, String aOth,
    List<String> pros,
    List<String> cons,
    String actionLabel,
    Color btnColor,
    Color cardBg, Color textCol, Color mutedCol, Color borderCol, Color bgCol,
  ) {
    final gradient = rank == '1'
        ? const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)])
        : rank == '2'
            ? const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)])
            : rank == '3'
                ? const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF92400E)])
                : const LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)]);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(9)),
                  alignment: Alignment.center,
                  child: Text(rank, style: AppTextStyles.dmSans(color: Colors.white, size: 13, weight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.playfair(size: 13.5, color: textCol, weight: FontWeight.bold)),
                      Text(typeStr, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeText, style: TextStyle(color: badgeTextCol, fontSize: 8.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildMetricItem(vol, '2024 Volume', bgCol, textCol, mutedCol),
                    const SizedBox(width: 7),
                    _buildMetricItem(jd, 'J.D. Power', bgCol, textCol, mutedCol),
                    const SizedBox(width: 7),
                    _buildMetricItem(speed, rank == '1' ? 'Pre-Approval' : rank == '2' ? 'Access' : 'Branches', bgCol, textCol, mutedCol),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildRateBox('30-Yr Fixed', r30, a30, borderCol, textCol, mutedCol),
                    const SizedBox(width: 7),
                    _buildRateBox('15-Yr Fixed', r15, a15, borderCol, textCol, mutedCol),
                    const SizedBox(width: 7),
                    _buildRateBox(name == 'JPMorgan Chase' ? 'Jumbo' : 'FHA 30-Yr', rOth, aOth, borderCol, textCol, mutedCol),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    ...pros.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(p, style: const TextStyle(color: Colors.green, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        )),
                    ...cons.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(c, style: const TextStyle(color: Colors.red, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        )),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔗 Navigating to $name...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: Text(actionLabel, style: AppTextStyles.dmSans(weight: FontWeight.bold, size: 12, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String val, String label, Color bg, Color txt, Color muted) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Column(
          children: [
            Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: txt)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8, color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildRateBox(String label, String rate, String apr, Color border, Color txt, Color muted) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(9)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 8, color: muted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(rate, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: txt)),
            Text('APR $apr', style: TextStyle(fontSize: 8, color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompRow(String label, String v1, String v2, String v3, {bool isHeader = false, int bestIdx = 0}) {
    final themeTxtCol = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1D3A);
    final rowCol = isHeader ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent;
    final textWeight = isHeader ? FontWeight.bold : FontWeight.normal;
    final double size = isHeader ? 8.5 : 10.0;

    return Container(
      color: rowCol,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Text(label, style: TextStyle(fontSize: 9.5, color: isHeader ? Colors.grey : themeTxtCol, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 7,
            child: Text(
              v1,
              style: TextStyle(
                fontSize: size,
                fontWeight: bestIdx == 1 ? FontWeight.bold : textWeight,
                color: bestIdx == 1 ? Colors.green : (isHeader ? Colors.grey : themeTxtCol),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              v2,
              style: TextStyle(
                fontSize: size,
                fontWeight: bestIdx == 2 ? FontWeight.bold : textWeight,
                color: bestIdx == 2 ? Colors.green : (isHeader ? Colors.grey : themeTxtCol),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              v3,
              style: TextStyle(
                fontSize: size,
                fontWeight: bestIdx == 3 ? FontWeight.bold : textWeight,
                color: bestIdx == 3 ? Colors.green : (isHeader ? Colors.grey : themeTxtCol),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
