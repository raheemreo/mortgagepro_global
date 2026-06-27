// lib/features/global/screens/global_top_lenders_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_tools_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

class GlobalTopLendersScreen extends ConsumerStatefulWidget {
  const GlobalTopLendersScreen({super.key});

  @override
  ConsumerState<GlobalTopLendersScreen> createState() => _GlobalTopLendersScreenState();
}

class _Lender {
  final String name;
  final String icon;
  final String type;
  final double rate;
  final double share;
  final double stars;

  const _Lender({
    required this.name,
    required this.icon,
    required this.type,
    required this.rate,
    required this.share,
    required this.stars,
  });
}

class _CountryData {
  final String flag;
  final String name;
  final String rateLabel;
  final List<_Lender> lenders;

  const _CountryData({
    required this.flag,
    required this.name,
    required this.rateLabel,
    required this.lenders,
  });
}

class _GlobalTopLendersScreenState extends ConsumerState<GlobalTopLendersScreen> {
  String _selectedCountry = 'us';

  static const Map<String, _CountryData> _data = {
    'us': _CountryData(
      flag: '🇺🇸',
      name: 'United States',
      rateLabel: '30-Yr Fixed',
      lenders: [
        _Lender(name: 'Rocket Mortgage', icon: '🚀', type: 'Online / Direct Lender', rate: 6.52, share: 8.4, stars: 4.6),
        _Lender(name: 'United Wholesale Mortgage', icon: '🏦', type: 'Wholesale Lender', rate: 6.48, share: 7.1, stars: 4.3),
        _Lender(name: 'Wells Fargo', icon: '🏦', type: 'National Bank', rate: 6.61, share: 5.2, stars: 4.0),
        _Lender(name: 'Chase', icon: '🏦', type: 'National Bank', rate: 6.58, share: 4.8, stars: 4.1),
        _Lender(name: 'Bank of America', icon: '🏦', type: 'National Bank', rate: 6.63, share: 4.1, stars: 3.9),
        _Lender(name: 'CrossCountry Mortgage', icon: '🏠', type: 'Direct Lender', rate: 6.55, share: 3.2, stars: 4.4),
      ],
    ),
    'ca': _CountryData(
      flag: '🇨🇦',
      name: 'Canada',
      rateLabel: '5-Yr Fixed',
      lenders: [
        _Lender(name: 'Scotiabank', icon: '🏦', type: 'Big 6 Bank', rate: 4.34, share: 14.2, stars: 4.2),
        _Lender(name: 'RBC Royal Bank', icon: '🏦', type: 'Big 6 Bank', rate: 4.49, share: 18.5, stars: 4.3),
        _Lender(name: 'TD Canada Trust', icon: '🏦', type: 'Big 6 Bank', rate: 4.44, share: 16.1, stars: 4.1),
        _Lender(name: 'CIBC', icon: '🏦', type: 'Big 6 Bank', rate: 4.54, share: 11.3, stars: 4.0),
        _Lender(name: 'BMO', icon: '🏦', type: 'Big 6 Bank', rate: 4.49, share: 10.8, stars: 4.0),
        _Lender(name: 'Tangerine / True North', icon: '🍊', type: 'Digital Lender', rate: 4.04, share: 6.4, stars: 4.5),
      ],
    ),
    'uk': _CountryData(
      flag: '🇬🇧',
      name: 'United Kingdom',
      rateLabel: '2-Yr Fixed',
      lenders: [
        _Lender(name: 'Barclays', icon: '🏦', type: 'High Street Bank', rate: 4.39, share: 11.2, stars: 4.2),
        _Lender(name: 'HSBC UK', icon: '🏦', type: 'High Street Bank', rate: 4.43, share: 13.8, stars: 4.3),
        _Lender(name: 'Nationwide', icon: '🏛️', type: 'Building Society', rate: 4.55, share: 15.4, stars: 4.4),
        _Lender(name: 'Lloyds Bank', icon: '🏦', type: 'High Street Bank', rate: 4.58, share: 12.6, stars: 4.0),
        _Lender(name: 'NatWest', icon: '🏦', type: 'High Street Bank', rate: 4.61, share: 10.9, stars: 3.9),
        _Lender(name: 'Santander UK', icon: '🏦', type: 'High Street Bank', rate: 4.52, share: 9.7, stars: 4.1),
      ],
    ),
    'au': _CountryData(
      flag: '🇦🇺',
      name: 'Australia',
      rateLabel: 'Variable Owner-Occ',
      lenders: [
        _Lender(name: 'Commonwealth Bank', icon: '🏦', type: 'Big 4 Bank', rate: 6.09, share: 24.8, stars: 4.0),
        _Lender(name: 'Westpac', icon: '🏦', type: 'Big 4 Bank', rate: 6.14, share: 20.1, stars: 3.9),
        _Lender(name: 'ANZ', icon: '🏦', type: 'Big 4 Bank', rate: 6.19, share: 14.6, stars: 3.9),
        _Lender(name: 'NAB', icon: '🏦', type: 'Big 4 Bank', rate: 6.11, share: 14.2, stars: 4.0),
        _Lender(name: 'ING Australia', icon: '🦁', type: 'Digital Bank', rate: 5.84, share: 5.3, stars: 4.5),
        _Lender(name: 'Macquarie Bank', icon: '🏦', type: 'Non-Major Bank', rate: 5.89, share: 4.7, stars: 4.4),
      ],
    ),
    'nz': _CountryData(
      flag: '🇳🇿',
      name: 'New Zealand',
      rateLabel: '1-Yr Fixed',
      lenders: [
        _Lender(name: 'ANZ NZ', icon: '🏦', type: 'Major Bank', rate: 6.59, share: 30.2, stars: 4.0),
        _Lender(name: 'ASB Bank', icon: '🏦', type: 'Major Bank', rate: 6.59, share: 23.1, stars: 4.1),
        _Lender(name: 'Westpac NZ', icon: '🏦', type: 'Major Bank', rate: 6.65, share: 18.4, stars: 3.9),
        _Lender(name: 'BNZ', icon: '🏦', type: 'Major Bank', rate: 6.59, share: 15.7, stars: 4.0),
        _Lender(name: 'Kiwibank', icon: '🥝', type: 'NZ-Owned Bank', rate: 6.55, share: 9.8, stars: 4.4),
        _Lender(name: 'SBS Bank', icon: '🏦', type: 'Building Society', rate: 6.70, share: 2.8, stars: 4.2),
      ],
    ),
  };

  static const List<Color> _chartColors = [
    Color(0xFF1A3A8F),
    Color(0xFF0D9488),
    Color(0xFFD97706),
    Color(0xFFC0392B),
    Color(0xFF15803D),
    Color(0xFF3B82F6),
  ];

  String _starString(double score) {
    final full = score.floor();
    final half = (score - full) >= 0.5;
    return '★' * full + (half ? '½' : '') + '☆' * (5 - full - (half ? 1 : 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgCol = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    final cardCol = isDark ? const Color(0xFF141C33) : Colors.white;
    final navyCol = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedCol = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);

    final countryData = _data[_selectedCountry]!;
    final sortedByRate = List<_Lender>.from(countryData.lenders)..sort((a, b) => a.rate.compareTo(b.rate));
    final topLenderByShare = (List<_Lender>.from(countryData.lenders)..sort((a, b) => b.share.compareTo(a.share))).first;

    final savedTools = ref.watch(savedToolsProvider);
    final isSaved = savedTools.contains('global_top_lenders');

    return Scaffold(
      backgroundColor: bgCol,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 12, 18, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFB91C1C)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('←', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Top Mortgage Lenders',
                            style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'USA · Canada · UK · Australia · NZ',
                            style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.50)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(savedToolsProvider.notifier).toggleFavorite('global_top_lenders');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSaved ? 'Removed from Saved Tools' : 'Saved to Favorite Tools!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isSaved ? '🔖' : '🏷️',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Country Pills
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _data.entries.map((entry) {
                      final code = entry.key;
                      final d = entry.value;
                      final isActive = _selectedCountry == code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCountry = code;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFD97706) : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isActive ? const Color(0xFFD97706) : Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(d.flag, style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  d.name,
                                  style: AppTextStyles.dmSans(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: isActive ? const Color(0xFF0B1D3A) : Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Content Scroll View ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 16, 15, 110),
              children: [
                // Section: Top Ranked Lender
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Ranked Lender'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1.0),
                    ),
                    Text(
                      'June 2026',
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1A3A8F)),
                    ),
                  ],
                ),
                const SizedBox(height: 11),

                // Leader Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Watermark background circle
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD97706).withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leading Lender by Market Share · ${countryData.flag} ${countryData.name}',
                            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(topLenderByShare.icon, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topLenderByShare.name,
                                      style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${topLenderByShare.type} · ${_starString(topLenderByShare.stars)} ${topLenderByShare.stars}',
                                      style: AppTextStyles.dmSans(size: 10.5, color: Colors.white.withValues(alpha: 0.55)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildLeaderMetricBox(countryData.rateLabel, '${topLenderByShare.rate}%'),
                              const SizedBox(width: 8),
                              _buildLeaderMetricBox('Market Share', '${topLenderByShare.share}%'),
                              const SizedBox(width: 8),
                              _buildLeaderMetricBox('Rating', '${topLenderByShare.stars}/5'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Section: All Lenders Ranked
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Lenders Ranked'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1.0),
                    ),
                    Text(
                      'By Volume →',
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1A3A8F)),
                    ),
                  ],
                ),
                const SizedBox(height: 11),

                // Ranked List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedByRate.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final lender = sortedByRate[index];
                    final rank = index + 1;
                    
                    LinearGradient rankGrad;
                    if (rank == 1) {
                      rankGrad = const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]);
                    } else if (rank == 2) {
                      rankGrad = const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)]);
                    } else if (rank == 3) {
                      rankGrad = const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF92400E)]);
                    } else {
                      rankGrad = const LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0B1D3A)]);
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardCol,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B2D3A).withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: rankGrad,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$rank',
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${lender.icon} ${lender.name}',
                                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: navyCol),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  lender.type,
                                  style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_starString(lender.stars)} ${lender.stars}',
                                  style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFD97706), weight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${lender.rate}%',
                                style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: const Color(0xFF1A3A8F)),
                              ),
                              Text(
                                countryData.rateLabel,
                                style: AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Section: Rate Comparison Chart
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardCol,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B2D3A).withValues(alpha: 0.05),
                        blurRadius: 16,
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
                            'Rate Comparison',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: navyCol),
                          ),
                          Text(
                            countryData.rateLabel,
                            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w500, color: const Color(0xFF0D9488)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(sortedByRate.length, (i) {
                        final lender = sortedByRate[i];
                        final maxRate = sortedByRate.map((l) => l.rate).reduce(max);
                        final minRate = sortedByRate.map((l) => l.rate).reduce(min);
                        final double range = maxRate - minRate + 0.3;
                        final double pct = range > 0 ? (lender.rate - minRate + 0.3) / range : 1.0;

                        final color = i == 0
                            ? const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF16A34A)])
                            : LinearGradient(colors: [_chartColors[i % _chartColors.length], _chartColors[i % _chartColors.length]]);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 78,
                                child: Text(
                                  lender.name.split(' ').first,
                                  style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol),
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: bgCol,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: (pct * 100).round(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: color,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            '${lender.rate}%',
                                            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white, weight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: ((1 - pct) * 100).round(),
                                        child: const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Section: Market Share Donut Chart
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardCol,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B2D3A).withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Share by Volume',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: navyCol),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CustomPaint(
                              painter: _DonutChartPainter(
                                lenders: countryData.lenders,
                                colors: _chartColors,
                                trackColor: bgCol,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: List.generate(countryData.lenders.length, (i) {
                                final lender = countryData.lenders[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(top: 3),
                                        decoration: BoxDecoration(
                                          color: _chartColors[i % _chartColors.length],
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lender.name,
                                              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: navyCol),
                                            ),
                                            Text(
                                              '${lender.share}% market share',
                                              style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Nav ─────────────────────────────────────────────────────
          BottomNav(
            activeIndex: 3, // Global
            activeColor: isDark ? const Color(0xFFF97316) : const Color(0xFF7C2D12),
            countryIcon: '🌐',
            countryLabel: 'Global',
            countryRoute: '/global',
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderMetricBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.46), letterSpacing: 0.4),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFFFCD34D)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_Lender> lenders;
  final List<Color> colors;
  final Color trackColor;

  _DonutChartPainter({
    required this.lenders,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 9; // 9px is half of 18px strokeWidth

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    canvas.drawCircle(center, radius, trackPaint);

    final totalShare = lenders.fold<double>(0, (sum, item) => sum + item.share);
    double startAngle = -pi / 2;

    for (int i = 0; i < lenders.length; i++) {
      final sweepAngle = (lenders[i].share / totalShare) * 2 * pi;
      final slicePaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        slicePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
