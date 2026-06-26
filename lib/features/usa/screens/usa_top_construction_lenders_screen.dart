// lib/features/usa/screens/usa_top_construction_lenders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USATopConstructionLendersScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USATopConstructionLendersScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USATopConstructionLendersScreen> createState() => _USATopConstructionLendersScreenState();
}

class _USATopConstructionLendersScreenState extends ConsumerState<USATopConstructionLendersScreen> {
  static const _theme = CountryThemes.usa;

  // Static Lender Data
  final List<Map<String, dynamic>> _lenders = [
    {
      'id': 'naf',
      'name': 'New American Funding',
      'nmls': '6606',
      'rating': 4.0,
      'credit': 620, // estimated default
      'down': 10,
      'tag': 'Best for flexible requirements',
      'cat': ['flex'],
      'desc': 'Wide menu of purchase, refinance and buyer-assistance programs, including a HELOC usable on a second home.',
    },
    {
      'id': 'truist',
      'name': 'Truist',
      'nmls': '399803',
      'rating': 5.0,
      'credit': 620,
      'down': 3,
      'tag': 'Best for renovation loans',
      'cat': ['low-down', 'renovation'],
      'desc': 'Broad range of affordability-focused mortgage options with generous grants for qualifying buyers in select areas.',
    },
    {
      'id': 'flagstar',
      'name': 'Flagstar Bank',
      'nmls': '417490',
      'rating': 5.0,
      'credit': 600,
      'down': 3,
      'tag': 'Best for jumbo construction loans',
      'cat': ['low-credit', 'low-down'],
      'desc': 'Wide variety of home loan options including harder-to-find products; reported average close in 25 days.',
    },
    {
      'id': 'usbank',
      'name': 'U.S. Bank',
      'nmls': '402761',
      'rating': 4.5,
      'credit': 620,
      'down': 3,
      'tag': 'Best for variety of loan types',
      'cat': ['low-down'],
      'desc': 'Broad mortgage selection with deep construction and renovation loan experience, plus up to \$17,500 in assistance.',
    },
    {
      'id': 'guild',
      'name': 'Guild Mortgage',
      'nmls': '3274',
      'rating': 4.0,
      'credit': 600,
      'down': 3,
      'tag': 'Best for online convenience',
      'cat': ['low-credit', 'low-down'],
      'desc': 'Wide range of loans including 0%–1% down options; builder interest buy-down programs available via StrongStart.',
    },
    {
      'id': 'rate',
      'name': 'Rate',
      'nmls': '2611',
      'rating': 4.0,
      'credit': 580,
      'down': 3,
      'tag': 'Best for renovation loans',
      'cat': ['low-credit', 'low-down', 'renovation'],
      'desc': 'Streamlined process with full underwriting in as little as one business day; government-backed and renovation loans.',
    },
    {
      'id': 'prime',
      'name': 'PrimeLending',
      'nmls': '13649',
      'rating': 4.0,
      'credit': 620,
      'down': 5,
      'tag': 'Best for custom homes',
      'cat': ['renovation'],
      'desc': 'Strong fit for fixer-uppers and custom builds, including financing for manufactured and 3D-printed homes.',
    },
    {
      'id': 'alliant',
      'name': 'Alliant Credit Union',
      'nmls': '197185',
      'rating': 5.0,
      'credit': 620,
      'down': 3,
      'tag': 'Best for credit union lending',
      'cat': ['credit-union', 'low-down'],
      'desc': 'Competitive rate-and-fee combination; membership only required once you reach closing, not at application.',
    },
    {
      'id': 'pnc',
      'name': 'PNC Bank',
      'nmls': '446303',
      'rating': 5.0,
      'credit': 620,
      'down': 3,
      'tag': 'Best for borrowers in eligible states',
      'cat': ['low-down'],
      'desc': 'Down payment grants and no-PMI options. Construction loans limited to AL, AZ, CA, CO, FL, GA, NJ, NM, NC, OH, PA, SC, TN, TX, VA, WA.',
    },
    {
      'id': 'north',
      'name': 'Northpointe Bank',
      'nmls': '447490',
      'rating': 4.5,
      'credit': 620,
      'down': 3,
      'tag': 'Best for all-in-one financing',
      'cat': ['low-down'],
      'desc': 'Niche offerings like doctor loans, condo loans and investment-property loans alongside standard construction financing.',
    },
  ];

  // Filters
  final List<Map<String, String>> _filters = [
    {'id': 'all', 'label': 'All Lenders'},
    {'id': 'low-credit', 'label': 'Lowest Credit Score'},
    {'id': 'low-down', 'label': 'Low Down Payment'},
    {'id': 'credit-union', 'label': 'Credit Unions'},
    {'id': 'renovation', 'label': 'Renovation-Friendly'},
  ];

  String _activeFilter = 'all';
  final Set<String> _shortlist = {};
  bool _showShortlistPanel = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      for (var lender in _lenders) {
        final id = lender['id'] as String;
        if (inputs[id] == 1.0) {
          _shortlist.add(id);
        }
      }
    }
  }

  void _toggleShortlist(String id) {
    setState(() {
      if (_shortlist.contains(id)) {
        _shortlist.remove(id);
      } else {
        _shortlist.add(id);
      }
    });
  }

  void _clearShortlist() {
    setState(() {
      _shortlist.clear();
    });
  }

  void _saveShortlist() {
    final Map<String, double> inputs = {};
    for (var lender in _lenders) {
      final id = lender['id'] as String;
      inputs[id] = _shortlist.contains(id) ? 1.0 : 0.0;
    }

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Top Construction Lenders Shortlist',
      label: 'Lenders Shortlist · ${_shortlist.length} Saved',
      currencyCode: 'USD',
      inputs: inputs,
      results: {
        'ShortlistedCount': _shortlist.length.toDouble(),
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Lender shortlist saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _renderStars(double rating) {
    final full = rating.round();
    return '${'★' * full}${'☆' * (5 - full)} ${rating.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtered Lenders
    final filteredLenders = _activeFilter == 'all'
        ? _lenders
        : _lenders.where((l) => (l['cat'] as List<String>).contains(_activeFilter)).toList();

    // Chart Data (sorted by credit score ascending, filter non-null credits)
    final chartLenders = _lenders.where((l) => l['credit'] != null).toList()..sort((a, b) => (a['credit'] as int).compareTo(b['credit'] as int));

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
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
            actions: [
              GestureDetector(
                onTap: () {
                  setState(() => _showShortlistPanel = !_showShortlistPanel);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: _showShortlistPanel ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔖', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C), Color(0xFF991B1B)],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏦', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Top Construction Lenders',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Ranked U.S. Lenders · Updated 2026',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white60)),
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
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStripItem('Reviewed', '40+', 'lenders', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Avg Min Credit', '~610', 'top 10', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Avg Min Down', '3%', 'most lenders', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Top Rated', '5.0★', '4 lenders', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Shortlist panel
                if (_showShortlistPanel) ...[
                  _buildSectionHeader('📌 My Lender Shortlist'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Lenders for Vetting',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textCol),
                            ),
                            GestureDetector(
                              onTap: _clearShortlist,
                              child: Text(
                                'Clear All',
                                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: const Color(0xFFB91C1C)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_shortlist.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No lenders saved yet. Tap "Save Lender" below.',
                              style: AppTextStyles.dmSans(size: 10.5, color: mutedCol),
                            ),
                          )
                        else ...[
                          ..._lenders.where((l) => _shortlist.contains(l['id'])).map((l) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: _theme.getBgColor(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l['name'] as String, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: textCol)),
                                        Text('NMLS #${l['nmls']} · ${l['tag']}', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                                      ],
                                    ),
                                  ),
                                  Text('${l['credit']} FICO', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: const Color(0xFFB91C1C))),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _toggleShortlist(l['id'] as String),
                                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _saveShortlist,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Save Shortlist Calculation',
                                style: AppTextStyles.dmSans(size: 11.5, color: Colors.white, weight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                _buildSectionHeader('Filter Lenders'),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final active = f['id'] == _activeFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _activeFilter = f['id']!);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: active ? const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]) : null,
                              color: active ? null : cardBg,
                              border: Border.all(color: active ? const Color(0xFFB91C1C) : borderCol, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              f['label']!,
                              style: AppTextStyles.dmSans(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: active ? Colors.white : mutedCol,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Min. Credit Score Comparison'),

                // Credit comparison chart card
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
                      Text('📊 Lowest Minimum Credit Score Required',
                          style: AppTextStyles.dmSans(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      ...List.generate(chartLenders.length, (idx) {
                        final l = chartLenders[idx];
                        final score = l['credit'] as int;
                        // Map FICO scores to width. Max FICO is usually 850, base limit on 650.
                        final scale = score / 680;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 85,
                                child: Text(l['name'].toString().split(' ')[0], style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: mutedCol)),
                              ),
                              Expanded(
                                child: Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFEEF2F8),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: min(scale, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: idx < 2 ? const Color(0xFFD97706) : const Color(0xFFB91C1C),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$score',
                                  style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: textCol),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Lender Directory'),

                // List count pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔖 ', style: TextStyle(fontSize: 10)),
                      Text(
                        '${_shortlist.length} Lenders in Shortlist',
                        style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Lenders list
                ...filteredLenders.map((l) {
                  final id = l['id'] as String;
                  final inShortlist = _shortlist.contains(id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l['name'] as String, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol)),
                                  const SizedBox(height: 1),
                                  Text('NMLS #${l['nmls']}', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                                ],
                              ),
                            ),
                            Text(_renderStars(l['rating'] as double), style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFFD97706), weight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            l['tag'] as String,
                            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricMini('Min. Credit', l['credit']?.toString() ?? 'N/A', cardBg, borderCol, textCol, mutedCol),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricMini('Min. Down', '${l['down']}%', cardBg, borderCol, textCol, mutedCol),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricMini('NW Rating', '${l['rating'].toStringAsFixed(1)}', cardBg, borderCol, textCol, mutedCol),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(l['desc'] as String, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.45)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _toggleShortlist(id),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: inShortlist ? const LinearGradient(colors: [Color(0xFFFCD34D), Color(0xFFD97706)]) : null,
                              color: inShortlist ? null : _theme.getBgColor(context),
                              border: Border.all(color: inShortlist ? const Color(0xFFD97706) : borderCol),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              inShortlist ? '✓ In Shortlist' : '🔖 Save Lender',
                              style: AppTextStyles.dmSans(size: 10.5, color: inShortlist ? Colors.white : textCol, weight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Ratings, NMLS IDs and qualification minimums reflect NerdWallet\'s June 2026 construction-lender rankings and individual lender disclosures. Rates and terms change — confirm current details directly with each lender, and verify license status at nmlsconsumeraccess.org.',
                      style: AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                      textAlign: TextAlign.center,
                    ),
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
                color: isDark ? Colors.white54 : _theme.getMutedColor(context),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : (isDark ? Colors.white : _theme.getTextColor(context)))),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : _theme.getMutedColor(context).withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.dmSans(
          size: 10,
          weight: FontWeight.w800,
          color: _theme.getMutedColor(context),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMetricMini(String label, String value, Color cardBg, Color borderCol, Color textCol, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: _theme.getBgColor(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: textCol),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 7.5, color: mutedCol, letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
