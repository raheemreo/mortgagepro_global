// lib/features/usa/screens/usa_median_home_prices_state_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../core/utils/currency_formatter.dart';

class USAMedianHomePricesStateScreen extends ConsumerStatefulWidget {
  const USAMedianHomePricesStateScreen({super.key});

  @override
  ConsumerState<USAMedianHomePricesStateScreen> createState() => _USAMedianHomePricesStateScreenState();
}

class _StatePriceData {
  final String name;
  final String abbr;
  final double price;
  final double yoy;
  final String region;
  final String icon;

  const _StatePriceData({
    required this.name,
    required this.abbr,
    required this.price,
    required this.yoy,
    required this.region,
    required this.icon,
  });
}

class _USAMedianHomePricesStateScreenState extends ConsumerState<USAMedianHomePricesStateScreen> {
  static const _theme = CountryThemes.usa;

  final _searchController = TextEditingController();

  String _currentFilter = 'all';
  String _currentSort = 'price';
  String _searchTerm = '';

  static const List<_StatePriceData> _states = [
    _StatePriceData(name: 'Alabama', abbr: 'AL', price: 248000, yoy: 5.8, region: 'so', icon: '🌳'),
    _StatePriceData(name: 'Alaska', abbr: 'AK', price: 338000, yoy: 3.1, region: 'we', icon: '🏔️'),
    _StatePriceData(name: 'Arizona', abbr: 'AZ', price: 436000, yoy: 1.7, region: 'we', icon: '🌵'),
    _StatePriceData(name: 'Arkansas', abbr: 'AR', price: 218000, yoy: 6.2, region: 'so', icon: '🌾'),
    _StatePriceData(name: 'California', abbr: 'CA', price: 880000, yoy: 5.9, region: 'we', icon: '🌴'),
    _StatePriceData(name: 'Colorado', abbr: 'CO', price: 575000, yoy: -0.4, region: 'we', icon: '⛰️'),
    _StatePriceData(name: 'Connecticut', abbr: 'CT', price: 449000, yoy: 8.7, region: 'ne', icon: '🍁'),
    _StatePriceData(name: 'Delaware', abbr: 'DE', price: 376000, yoy: 6.1, region: 'ne', icon: '🏛️'),
    _StatePriceData(name: 'Florida', abbr: 'FL', price: 420000, yoy: 0.8, region: 'so', icon: '🌞'),
    _StatePriceData(name: 'Georgia', abbr: 'GA', price: 348000, yoy: 5.2, region: 'so', icon: '🍑'),
    _StatePriceData(name: 'Hawaii', abbr: 'HI', price: 948000, yoy: 3.8, region: 'we', icon: '🌺'),
    _StatePriceData(name: 'Idaho', abbr: 'ID', price: 450000, yoy: 2.1, region: 'we', icon: '🥔'),
    _StatePriceData(name: 'Illinois', abbr: 'IL', price: 295000, yoy: 7.1, region: 'mw', icon: '🏙️'),
    _StatePriceData(name: 'Indiana', abbr: 'IN', price: 258000, yoy: 6.8, region: 'mw', icon: '🌽'),
    _StatePriceData(name: 'Iowa', abbr: 'IA', price: 228000, yoy: 5.5, region: 'mw', icon: '🌾'),
    _StatePriceData(name: 'Kansas', abbr: 'KS', price: 242000, yoy: 6.0, region: 'mw', icon: '🌻'),
    _StatePriceData(name: 'Kentucky', abbr: 'KY', price: 241000, yoy: 7.2, region: 'so', icon: '🐎'),
    _StatePriceData(name: 'Louisiana', abbr: 'LA', price: 228000, yoy: 3.3, region: 'so', icon: '🎷'),
    _StatePriceData(name: 'Maine', abbr: 'ME', price: 389000, yoy: 9.4, region: 'ne', icon: '🦞'),
    _StatePriceData(name: 'Maryland', abbr: 'MD', price: 469000, yoy: 6.8, region: 'ne', icon: '🦀'),
    _StatePriceData(name: 'Massachusetts', abbr: 'MA', price: 625000, yoy: 5.5, region: 'ne', icon: '🫘'),
    _StatePriceData(name: 'Michigan', abbr: 'MI', price: 268000, yoy: 7.8, region: 'mw', icon: '🚗'),
    _StatePriceData(name: 'Minnesota', abbr: 'MN', price: 349000, yoy: 4.9, region: 'mw', icon: '❄️'),
    _StatePriceData(name: 'Mississippi', abbr: 'MS', price: 181000, yoy: 4.2, region: 'so', icon: '🌊'),
    _StatePriceData(name: 'Missouri', abbr: 'MO', price: 262000, yoy: 5.9, region: 'mw', icon: '🌉'),
    _StatePriceData(name: 'Montana', abbr: 'MT', price: 498000, yoy: 1.2, region: 'we', icon: '🦌'),
    _StatePriceData(name: 'Nebraska', abbr: 'NE', price: 284000, yoy: 5.1, region: 'mw', icon: '🌽'),
    _StatePriceData(name: 'Nevada', abbr: 'NV', price: 455000, yoy: 3.9, region: 'we', icon: '🎰'),
    _StatePriceData(name: 'New Hampshire', abbr: 'NH', price: 499000, yoy: 11.4, region: 'ne', icon: '⛰️'),
    _StatePriceData(name: 'New Jersey', abbr: 'NJ', price: 560000, yoy: 8.9, region: 'ne', icon: '🗽'),
    _StatePriceData(name: 'New Mexico', abbr: 'NM', price: 332000, yoy: 4.5, region: 'we', icon: '🌶️'),
    _StatePriceData(name: 'New York', abbr: 'NY', price: 750000, yoy: 8.2, region: 'ne', icon: '🗽'),
    _StatePriceData(name: 'North Carolina', abbr: 'NC', price: 368000, yoy: 5.3, region: 'so', icon: '🌲'),
    _StatePriceData(name: 'North Dakota', abbr: 'ND', price: 282000, yoy: 4.0, region: 'mw', icon: '🌾'),
    _StatePriceData(name: 'Ohio', abbr: 'OH', price: 248000, yoy: 8.4, region: 'mw', icon: '🏭'),
    _StatePriceData(name: 'Oklahoma', abbr: 'OK', price: 215000, yoy: 3.8, region: 'so', icon: '🤠'),
    _StatePriceData(name: 'Oregon', abbr: 'OR', price: 485000, yoy: 1.9, region: 'we', icon: '🌲'),
    _StatePriceData(name: 'Pennsylvania', abbr: 'PA', price: 306000, yoy: 7.9, region: 'ne', icon: '🔔'),
    _StatePriceData(name: 'Rhode Island', abbr: 'RI', price: 488000, yoy: 10.1, region: 'ne', icon: '⚓'),
    _StatePriceData(name: 'South Carolina', abbr: 'SC', price: 318000, yoy: 4.8, region: 'so', icon: '🌙'),
    _StatePriceData(name: 'South Dakota', abbr: 'SD', price: 316000, yoy: 3.7, region: 'mw', icon: '🏔️'),
    _StatePriceData(name: 'Tennessee', abbr: 'TN', price: 356000, yoy: 2.9, region: 'so', icon: '🎸'),
    _StatePriceData(name: 'Texas', abbr: 'TX', price: 355000, yoy: 0.5, region: 'so', icon: '🤠'),
    _StatePriceData(name: 'Utah', abbr: 'UT', price: 555000, yoy: 2.2, region: 'we', icon: '🏜️'),
    _StatePriceData(name: 'Vermont', abbr: 'VT', price: 378000, yoy: 9.8, region: 'ne', icon: '🍁'),
    _StatePriceData(name: 'Virginia', abbr: 'VA', price: 420000, yoy: 6.2, region: 'so', icon: '🌿'),
    _StatePriceData(name: 'Washington', abbr: 'WA', price: 578000, yoy: 3.5, region: 'we', icon: '☕'),
    _StatePriceData(name: 'West Virginia', abbr: 'WV', price: 189000, yoy: 5.6, region: 'so', icon: '⛏️'),
    _StatePriceData(name: 'Wisconsin', abbr: 'WI', price: 322000, yoy: 6.5, region: 'mw', icon: '🧀'),
    _StatePriceData(name: 'Wyoming', abbr: 'WY', price: 398000, yoy: 1.5, region: 'we', icon: '🐂')
  ];

  static const Map<String, String> _regionNames = {
    'ne': 'Northeast',
    'mw': 'Midwest',
    'so': 'South',
    'we': 'West'
  };


  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_StatePriceData> get _dynamicStates {
    final stateMediansAsync = ref.watch(censusStateMedianHomeValuesProvider);
    final medians = stateMediansAsync.valueOrNull;

    if (medians == null || medians.isEmpty) {
      return _states;
    }

    return _states.map((s) {
      final livePrice = medians[s.name];
      if (livePrice != null) {
        return _StatePriceData(
          name: s.name,
          abbr: s.abbr,
          price: livePrice,
          yoy: s.yoy,
          region: s.region,
          icon: s.icon,
        );
      }
      return s;
    }).toList();
  }

  List<_StatePriceData> get _filteredStates {
    List<_StatePriceData> list = [..._dynamicStates];

    if (_searchTerm.isNotEmpty) {
      list = list.where((s) => s.name.toLowerCase().contains(_searchTerm) || s.abbr.toLowerCase().contains(_searchTerm)).toList();
    }

    if (_currentFilter == 'ne') list = list.where((s) => s.region == 'ne').toList();
    if (_currentFilter == 'mw') list = list.where((s) => s.region == 'mw').toList();
    if (_currentFilter == 'so') list = list.where((s) => s.region == 'so').toList();
    if (_currentFilter == 'we') list = list.where((s) => s.region == 'we').toList();

    if (_currentSort == 'price') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_currentSort == 'alpha') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else if (_currentSort == 'yoy') {
      list.sort((a, b) => b.yoy.compareTo(a.yoy));
    }

    if (_currentFilter == 'top10') {
      list.sort((a, b) => b.price.compareTo(a.price));
      list = list.take(10).toList();
    } else if (_currentFilter == 'bot10') {
      list.sort((a, b) => a.price.compareTo(b.price));
      list = list.take(10).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    final censusMedianAsync = ref.watch(censusMedianHomeValueProvider);
    final usMedianVal = censusMedianAsync.valueOrNull?.value ?? 416900.0;
    final formattedUsMedian = '\$${usMedianVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    final dynamicStates = _dynamicStates;
    final maxPrice = dynamicStates.isEmpty ? 880000.0 : dynamicStates.map((s) => s.price).reduce(math.max);

    final sortedByPrice = [...dynamicStates]..sort((a, b) => b.price.compareTo(a.price));
    final highestState = sortedByPrice.isNotEmpty ? sortedByPrice.first : _states.first;
    final lowestState = sortedByPrice.isNotEmpty ? sortedByPrice.last : _states.last;

    double getRegionAverage(String regionKey) {
      final regionStates = dynamicStates.where((s) => s.region == regionKey).toList();
      if (regionStates.isEmpty) return 0.0;
      final total = regionStates.map((s) => s.price).reduce((a, b) => a + b);
      return total / regionStates.length;
    }

    final dynamicRegionData = [
      {'r': 'Northeast', 'avg': getRegionAverage('ne'), 'color': const Color(0xFF0B1D3A)},
      {'r': 'West', 'avg': getRegionAverage('we'), 'color': const Color(0xFF1B3F72)},
      {'r': 'Midwest', 'avg': getRegionAverage('mw'), 'color': const Color(0xFFD97706)},
      {'r': 'South', 'avg': getRegionAverage('so'), 'color': const Color(0xFF15803D)},
    ];

    final maxReg = dynamicRegionData.map((r) => r['avg'] as double).reduce(math.max);
    final rankedStates = [...dynamicStates]..sort((a, b) => b.price.compareTo(a.price));

    final filtered = _filteredStates;

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
                          const Text('🗺️', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('Median Home Prices by State', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('NAR · Zillow · Redfin · Q1 2025 Data', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                      _buildStripItem('US Median', formattedUsMedian, censusMedianAsync.valueOrNull?.isLive == true ? 'Census Live' : 'NAR Q1 2025', Colors.amber),
                      _buildStripItem('YoY Change', '+5.1%', 'National', Colors.green),
                      _buildStripItem('Highest', '\$${(highestState.price / 1000).toStringAsFixed(0)}K', '${highestState.icon} ${highestState.abbr}', textCol),
                      _buildStripItem('Lowest', '\$${(lowestState.price / 1000).toStringAsFixed(0)}K', '${lowestState.icon} ${lowestState.abbr}', textCol),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // National Overview Hero
                    _buildSectionHeader('National Overview', 'Q1 2025', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF334155)]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('USA Median Home Price · ${censusMedianAsync.valueOrNull?.isLive == true ? "US Census ACS Live" : "NAR Q1 2025"}', style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text('National Median: $formattedUsMedian', style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.5,
                            children: [
                              _buildHeroGrid('YoY Growth', '+5.1%', const Color(0xFF6EE7B7)),
                              _buildHeroGrid('vs 2020', '+42%', const Color(0xFFFCD34D)),
                              _buildHeroGrid('Inventory', '1.11M', Colors.white),
                              _buildHeroGrid('Months Supply', '3.8 mo', Colors.white),
                              _buildHeroGrid('Days on Market', '36', Colors.white),
                              _buildHeroGrid('All-Cash Sales', '28%', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Extremes Summary Cards Grid
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final sortedByYoy = [...dynamicStates]..sort((a, b) => b.yoy.compareTo(a.yoy));
                        final fastestGrowing = sortedByYoy.isNotEmpty ? sortedByYoy.first : _states.first;
                        final slowestGrowing = sortedByYoy.isNotEmpty ? sortedByYoy.last : _states.last;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                          childAspectRatio: 1.8,
                          children: [
                            _buildExtremesCard('Most Expensive', '\$${(highestState.price / 1000).toStringAsFixed(0)}K', '${highestState.icon} ${highestState.name}', '${highestState.yoy >= 0 ? "↑" : "↓"} ${highestState.yoy.toStringAsFixed(1)}%', highestState.yoy >= 0 ? Colors.green : Colors.red, cardBg, textCol, mutedCol, borderCol),
                            _buildExtremesCard('Most Affordable', '\$${(lowestState.price / 1000).toStringAsFixed(0)}K', '${lowestState.icon} ${lowestState.name}', '${lowestState.yoy >= 0 ? "↑" : "↓"} ${lowestState.yoy.toStringAsFixed(1)}%', lowestState.yoy >= 0 ? Colors.green : Colors.red, cardBg, textCol, mutedCol, borderCol),
                            _buildExtremesCard('Fastest Growing', '${fastestGrowing.yoy >= 0 ? "+" : ""}${fastestGrowing.yoy.toStringAsFixed(1)}%', '${fastestGrowing.icon} ${fastestGrowing.name}', 'YoY Price Growth', Colors.green, cardBg, textCol, mutedCol, borderCol),
                            _buildExtremesCard(slowestGrowing.yoy < 0 ? 'Biggest Decline' : 'Slowest Growing', '${slowestGrowing.yoy >= 0 ? "+" : ""}${slowestGrowing.yoy.toStringAsFixed(1)}%', '${slowestGrowing.icon} ${slowestGrowing.name}', 'YoY Price Growth', slowestGrowing.yoy >= 0 ? Colors.green : Colors.red, cardBg, textCol, mutedCol, borderCol),
                          ],
                        );
                      },
                    ),

                    // Regional Price bars
                    _buildSectionHeader('Regional Averages', '4 Regions', mutedCol),
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
                          Text('📊 Median Price by US Census Region', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: dynamicRegionData.map((r) {
                              final name = r['r'] as String;
                              final avg = r['avg'] as double;
                              final color = r['color'] as Color;
                              final pct = avg / maxReg;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    SizedBox(width: 80, child: Text(name, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                    Expanded(
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(7)),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: pct,
                                            child: Container(
                                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.only(left: 8),
                                              child: pct > 0.4 ? Text('\$${(avg / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)) : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 60, child: Text(CurrencyFormatter.format(avg, decimalDigits: 0), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Search and filters
                    _buildSectionHeader('All 50 States', '${filtered.length} States', mutedCol),
                    TextField(
                      controller: _searchController,
                      style: AppTextStyles.dmSans(size: 13, color: textCol),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardBg,
                        hintText: '🔍 Search state name or abbreviation…',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderCol)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderCol)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _theme.primaryColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterButton('All States', 'all'),
                          _buildFilterButton('Northeast', 'ne'),
                          _buildFilterButton('Midwest', 'mw'),
                          _buildFilterButton('South', 'so'),
                          _buildFilterButton('West', 'we'),
                          _buildFilterButton('Top 10 💰', 'top10'),
                          _buildFilterButton('Most Affordable', 'bot10'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSortButton('Sort: Price ↓', 'price'),
                        const SizedBox(width: 6),
                        _buildSortButton('A–Z', 'alpha'),
                        const SizedBox(width: 6),
                        _buildSortButton('YoY Change', 'yoy'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // State list container
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('State', style: TextStyle(color: Colors.grey, fontSize: 9.5, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Median Price', style: TextStyle(color: Colors.grey, fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text('YoY %', style: TextStyle(color: Colors.grey, fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(color: borderCol, height: 1),
                            itemBuilder: (context, i) {
                              final s = filtered[i];
                              final pct = s.price / maxPrice;
                              final barCol = s.price > 700000 ? Colors.red : s.price > 500000 ? Colors.orange : s.price > 350000 ? Colors.blue : Colors.green;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${s.icon} ${s.name}', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text('${s.abbr} · ${_regionNames[s.region]}', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 6,
                                            width: double.infinity,
                                            decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(3)),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: FractionallySizedBox(
                                                widthFactor: pct,
                                                child: Container(
                                                  decoration: BoxDecoration(color: barCol, borderRadius: BorderRadius.circular(3)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(CurrencyFormatter.format(s.price, decimalDigits: 0), style: AppTextStyles.playfair(size: 13.5, color: textCol, weight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text('#${rankedStates.indexWhere((x) => x.name == s.name) + 1} rank', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${s.yoy >= 0 ? '+' : ''}${s.yoy.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              color: s.yoy >= 0 ? Colors.green : Colors.red,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('YoY', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                                        ],
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

  Widget _buildHeroGrid(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.white54), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildExtremesCard(String label, String val, String sub, String chg, Color chgCol, Color bg, Color txt, Color muted, Color border) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 8, color: muted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.playfair(size: 18, weight: FontWeight.bold, color: txt)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sub, style: TextStyle(fontSize: 9.5, color: muted)),
              Text(chg, style: TextStyle(fontSize: 10, color: chgCol, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final active = _currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        selectedColor: _theme.primaryColor,
        labelStyle: AppTextStyles.dmSans(
          size: 10,
          weight: FontWeight.bold,
          color: active ? Colors.white : _theme.getTextColor(context),
        ),
        onSelected: (sel) {
          if (sel) setState(() => _currentFilter = value);
        },
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final active = _currentSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      selectedColor: _theme.primaryColor,
      labelStyle: AppTextStyles.dmSans(
        size: 9.5,
        weight: FontWeight.bold,
        color: active ? Colors.white : _theme.getTextColor(context),
      ),
      onSelected: (sel) {
        if (sel) setState(() => _currentSort = value);
      },
    );
  }
}
