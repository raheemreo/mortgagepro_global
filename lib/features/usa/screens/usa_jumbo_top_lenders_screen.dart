// lib/features/usa/screens/usa_jumbo_top_lenders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAJumboTopLendersScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAJumboTopLendersScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAJumboTopLendersScreen> createState() => _USAJumboTopLendersScreenState();
}

class _USAJumboTopLendersScreenState extends ConsumerState<USAJumboTopLendersScreen> {
  static const _theme = CountryThemes.usa;

  String _selectedCategory = 'all'; // all, bank, nonqm, online, portfolio
  final List<String> _comparedLenders = [];

  final List<Map<String, dynamic>> _lenders = [
    {
      'id': 'chase',
      'name': 'JPMorgan Chase',
      'category': 'bank',
      'logo': '🏦',
      'rating': 4.8,
      'isTopPick': true,
      'rate30': '6.74%',
      'rate15': '6.31%',
      'maxLoan': '\$9.5M',
      'pills': ['✓ Up to \$9.5M', '✓ No PMI', 'Interest-Only Option', '720+ FICO', '10% Down Avail.', '5/1, 7/1, 10/1 ARM'],
      'minDown': '10%',
      'minFico': '720',
      'maxDti': '43%',
      'reserves': '12 Mo',
      'details': 'JPMorgan Chase is a premier portfolio Jumbo lender, holding high-value loans in its own asset sheets. This allows for highly flexible relationship pricing discounts (typically up to 0.25% off for clients holding significant deposits/investments). Offers unique interest-only programs on 5/1 and 7/1 ARMs.',
    },
    {
      'id': 'wellsfargo',
      'name': 'Wells Fargo',
      'category': 'bank',
      'logo': '🔴',
      'rating': 4.5,
      'isTopPick': false,
      'rate30': '6.85%',
      'rate15': '6.42%',
      'maxLoan': '\$5M',
      'pills': ['✓ Relationship Discount', 'ARM Programs', '700+ FICO', 'Self-Employed OK'],
      'minDown': '15%',
      'minFico': '700',
      'maxDti': '43%',
      'reserves': '12 Mo',
      'details': 'Wells Fargo is one of the largest Jumbo mortgage originators in the United States. They offer extensive program variety, including super-jumbo loans up to \$5M. Known for relationship rate reductions and flexible underwriting for self-employed professionals with complex tax returns.',
    },
    {
      'id': 'bofa',
      'name': 'Bank of America',
      'category': 'bank',
      'logo': '🏛️',
      'rating': 4.4,
      'isTopPick': false,
      'rate30': '6.91%',
      'rate15': '6.48%',
      'maxLoan': '\$5M',
      'pills': ['✓ Rewards Rate Discount', '720+ FICO', 'Digital Process', 'No Closing Cost Option'],
      'minDown': '20%',
      'minFico': '720',
      'maxDti': '45%',
      'reserves': '18 Mo',
      'details': 'Bank of America offers steep interest rate discounts (up to 0.50% off) for participants in their Preferred Rewards program. They feature a streamlined digital mortgage experience and offer a custom no-closing-cost jumbo option by slightly adjusting interest rate structures.',
    },
    {
      'id': 'flagstar',
      'name': 'Flagstar Bank',
      'category': 'portfolio',
      'logo': '🌟',
      'rating': 4.3,
      'isTopPick': false,
      'rate30': '6.98%',
      'rate15': '6.55%',
      'maxLoan': '\$3M',
      'pills': ['✓ Non-Warrantable Condo', 'Bank Statement Loans', '680+ FICO', 'Flexible DTI'],
      'minDown': '10%',
      'minFico': '680',
      'maxDti': '50%',
      'reserves': '6 Mo',
      'details': 'Flagstar is renowned for its flexible portfolio guidelines, underwriting non-warrantable condominiums and offering specialized bank-statement programs for business owners. They allow credit scores down to 680 and debt-to-income ratios up to 50% under selective conditions.',
    },
    {
      'id': 'usbank',
      'name': 'U.S. Bank',
      'category': 'bank',
      'logo': '🦅',
      'rating': 4.2,
      'isTopPick': false,
      'rate30': '7.04%',
      'rate15': '6.62%',
      'maxLoan': '\$2.5M',
      'pills': ['✓ Smart Rate ARM', '720+ FICO', 'Physician Loan', '10% Down (720+)'],
      'minDown': '10%',
      'minFico': '720',
      'maxDti': '43%',
      'reserves': '12 Mo',
      'details': 'U.S. Bank features highly competitive hybrid ARMs alongside specialized jumbo programs, including zero-down physician mortgages for high-earning medical residents. Their Smart Rate ARM caps adjustment metrics effectively for premium borrowers.',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      final catIdx = (inputs['category'] ?? 0.0).toInt();
      const categories = ['all', 'bank', 'nonqm', 'online', 'portfolio'];
      if (catIdx >= 0 && catIdx < categories.length) {
        _selectedCategory = categories[catIdx];
      }

      if ((inputs['lender_0'] ?? 0.0) == 1.0) _comparedLenders.add('JPMorgan Chase');
      if ((inputs['lender_1'] ?? 0.0) == 1.0) _comparedLenders.add('Wells Fargo');
      if ((inputs['lender_2'] ?? 0.0) == 1.0) _comparedLenders.add('Bank of America');
      if ((inputs['lender_3'] ?? 0.0) == 1.0) _comparedLenders.add('Flagstar Bank');
      if ((inputs['lender_4'] ?? 0.0) == 1.0) _comparedLenders.add('U.S. Bank');
    }
  }

  void _toggleCompare(String lenderName) {
    setState(() {
      if (_comparedLenders.contains(lenderName)) {
        _comparedLenders.remove(lenderName);
        _showSnackBar('Removed $lenderName from comparison');
      } else {
        if (_comparedLenders.length >= 3) {
          _showSnackBar('⚠️ Max 3 lenders at a time');
        } else {
          _comparedLenders.add(lenderName);
          _showSnackBar('✅ Added $lenderName to comparison');
        }
      }
    });
  }

  void _saveCompare() {
    if (_comparedLenders.isEmpty) return;

    final categories = ['all', 'bank', 'nonqm', 'online', 'portfolio'];
    final catIdx = categories.indexOf(_selectedCategory);

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Jumbo Top Lenders',
      label: 'Jumbo Compare: ${_comparedLenders.join(" vs ")}',
      currencyCode: 'USD',
      inputs: {
        'category': catIdx.toDouble(),
        'lender_0': _comparedLenders.contains('JPMorgan Chase') ? 1.0 : 0.0,
        'lender_1': _comparedLenders.contains('Wells Fargo') ? 1.0 : 0.0,
        'lender_2': _comparedLenders.contains('Bank of America') ? 1.0 : 0.0,
        'lender_3': _comparedLenders.contains('Flagstar Bank') ? 1.0 : 0.0,
        'lender_4': _comparedLenders.contains('U.S. Bank') ? 1.0 : 0.0,
      },
      results: {},
    );

    ref.read(savedProvider.notifier).save(calc);
    _showSnackBar('✅ Jumbo lenders comparison saved!');
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: _theme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLenderDetails(Map<String, dynamic> lender) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      routeSettings: const RouteSettings(name: '/lender_details'),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(lender['logo'], style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lender['name'],
                                style: AppTextStyles.playfair(
                                    size: 20, color: textCol, weight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(lender['type'] ?? lender['category'].toString().toUpperCase(),
                                style: AppTextStyles.dmSans(size: 11, color: mutedCol)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Text('Overview Details',
                      style: AppTextStyles.dmSans(
                          size: 12.5, color: textCol, weight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    lender['details'],
                    style: AppTextStyles.dmSans(size: 11, color: mutedCol, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text('Program Guidelines',
                      style: AppTextStyles.dmSans(
                          size: 12.5, color: textCol, weight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _buildDetailRow('Minimum Down Payment', lender['minDown']),
                  _buildDetailRow('Minimum Credit Score', lender['minFico']),
                  _buildDetailRow('Maximum DTI Ratio', lender['maxDti']),
                  _buildDetailRow('Asset Reserves Required', lender['reserves']),
                  _buildDetailRow('Max Loan Limit', lender['maxLoan']),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleCompare(lender['name']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _theme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _comparedLenders.contains(lender['name'])
                                ? '⚖️ Remove from Compare'
                                : '⚖️ Add to Compare',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11.5, color: _theme.getMutedColor(context))),
          Text(value, style: AppTextStyles.dmSans(size: 11.5, color: _theme.getTextColor(context), weight: FontWeight.w800)),
        ],
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

    final filteredLenders = _lenders.where((l) {
      if (_selectedCategory == 'all') return true;
      return l['category'] == _selectedCategory;
    }).toList();

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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF334155), Color(0xFF1E293B)],
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
                      Text('Top Jumbo Lenders 2025',
                          style: AppTextStyles.playfair(
                              size: 19,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Best-in-class for Loans Above \$766,550',
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
                    child: _buildStripItem('Jumbo 30-Yr', '7.04%', 'Jun 2025 Avg', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Jumbo 15-Yr', '6.62%', 'Avg', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Best Rate', '6.74%', 'Chase 30-Yr', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Lenders', '5', 'Reviewed', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Market Overview'),

                // Market Overview Banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF334155)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBannerStat('Jumbo Volume', '\$398B', '2025 YTD', isGold: true),
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Expanded(
                        child: _buildBannerStat('Avg Loan Size', '\$1.24M', 'National'),
                      ),
                      Container(width: 1, height: 36, color: Colors.white12),
                      Expanded(
                        child: _buildBannerStat('Rate Spread', '+0.30%', 'vs Conforming'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterTab('All Lenders', 'all'),
                      _buildFilterTab('Big Banks', 'bank'),
                      _buildFilterTab('Portfolio', 'portfolio'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Rate comparison chart card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 30-Yr Jumbo Rate Comparison',
                          style: AppTextStyles.playfair(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      Text('June 2025 · Rates vary by credit score, LTV & loan size',
                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                      const SizedBox(height: 14),
                      _buildRateBar('Chase', '6.74%', 0.92, [const Color(0xFF0B1D3A), const Color(0xFF334155)]),
                      const SizedBox(height: 8),
                      _buildRateBar('Wells Fargo', '6.85%', 0.88, [const Color(0xFF1B3F72), const Color(0xFF2563EB)]),
                      const SizedBox(height: 8),
                      _buildRateBar('Bank of America', '6.91%', 0.86, [const Color(0xFF334155), const Color(0xFF475569)]),
                      const SizedBox(height: 8),
                      _buildRateBar('Flagstar', '6.98%', 0.84, [const Color(0xFFD97706), const Color(0xFFB45309)]),
                      const SizedBox(height: 8),
                      _buildRateBar('US Bank', '7.04%', 0.81, [const Color(0xFF4A5C7A), const Color(0xFF64748B)]),
                      const SizedBox(height: 8),
                      _buildRateBar('PNC Bank', '7.09%', 0.79, [const Color(0xFF64748B), const Color(0xFF94A3B8)]),
                      const SizedBox(height: 10),
                      Text('*Rates for 760+ FICO, 20% down, \$1M–\$2M loan. Not a guarantee.',
                          style: AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                          textAlign: TextAlign.right),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Key Market Stats', badgeText: '2025 Data'),

                // Market Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  children: [
                    _buildStatCard('📈', 'Approval Rate', '68%', 'Jumbo applicants 2025', '▲ 3% vs 2024', isGreenTrend: true),
                    _buildStatCard('⏱️', 'Avg Close Time', '38 days', 'Jumbo avg vs 30 conv.', '▼ 2 days faster', isGreenTrend: true),
                    _buildStatCard('💰', 'Min Reserves', '12 mo', 'PITI in liquid assets', 'Industry median'),
                    _buildStatCard('🎯', 'Min FICO', '700+', 'Most lenders require 720+', '720 for best rates'),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Top Lenders Ranked', badgeText: "Editor's Picks"),

                // Lender Cards
                ...filteredLenders.map((l) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: bgCol,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(l['logo'], style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                  Text(l['name'],
                                      style: AppTextStyles.playfair(
                                          size: 15, color: textCol, weight: FontWeight.w800)),
                                  Text(l['type'] ?? l['category'].toString().toUpperCase(),
                                      style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Text('★', style: TextStyle(color: Color(0xFFD97706), fontSize: 11)),
                                const SizedBox(width: 2),
                                Text('${l['rating']}', style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildRateGridItem('30-Yr Rate', l['rate30'], isGreen: true)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildRateGridItem('15-Yr Rate', l['rate15'])),
                            const SizedBox(width: 8),
                            Expanded(child: _buildRateGridItem('Max Loan', l['maxLoan'], isGold: true)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (l['pills'] as List<String>).map((p) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.startsWith('✓')
                                    ? const Color(0xFFF0FDF4)
                                    : p.contains('FICO')
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFEFF6FF),
                                border: Border.all(
                                  color: p.startsWith('✓')
                                      ? const Color(0xFFBBF7D0)
                                      : p.contains('FICO')
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFBFDBFE),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p,
                                style: AppTextStyles.dmSans(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: p.startsWith('✓')
                                      ? const Color(0xFF15803D)
                                      : p.contains('FICO')
                                          ? const Color(0xFF92400E)
                                          : const Color(0xFF1B3F72),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniMetric('Min Down', l['minDown']),
                            _buildMiniMetric('Min FICO', l['minFico']),
                            _buildMiniMetric('Max DTI', l['maxDti']),
                            _buildMiniMetric('Reserves', l['reserves']),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showLenderDetails(l),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('📋 View Details',
                                      style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleCompare(l['name']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: bgCol,
                                    border: Border.all(color: borderCol),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                      _comparedLenders.contains(l['name']) ? '✓ Comparing' : '⚖️ Compare',
                                      style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Pro Tip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Expert Tip: Rate Shopping for Jumbo Loans',
                          style: AppTextStyles.playfair(size: 11, color: const Color(0xFF92400E), weight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(
                        'Jumbo rates are not published on Freddie Mac/Fannie Mae indices — each bank sets its own. Shopping at least 3 lenders can save \$200–\$600/month on a \$1.5M loan. Always compare APR (not just rate) to account for points and fees. Relationship discounts of 0.125%–0.25% are common at banks where you hold ≥\$250K in deposits.',
                        style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF92400E), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: _comparedLenders.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFF0B1D3A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('COMPARING',
                            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(
                          _comparedLenders.join(' vs '),
                          style: AppTextStyles.dmSans(size: 11.5, color: Colors.white, weight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _comparedLenders.clear()),
                        child: Text('Clear', style: AppTextStyles.dmSans(size: 10, color: Colors.white70, weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveCompare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text('Save Compare', style: AppTextStyles.dmSans(size: 10.5, color: Colors.white, weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title, {String? badgeText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: _theme.getMutedColor(context),
              letterSpacing: 1.0,
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF5D4017) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                ),
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

  Widget _buildBannerStat(String label, String value, String sub, {bool isGold = false}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.playfair(
                size: 18,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white)),
        const SizedBox(height: 2),
        Text(sub, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
      ],
    );
  }

  Widget _buildFilterTab(String label, String category) {
    final active = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B1D3A) : _theme.getCardColor(context),
          border: Border.all(color: active ? const Color(0xFF0B1D3A) : _theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: active ? Colors.white : _theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRateBar(String label, String value, double fill, List<Color> colors) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: _theme.getTextColor(context))),
        ),
        Expanded(
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value,
                    style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, String sub, String trend, {bool isGreenTrend = false}) {
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label.toUpperCase(),
                    style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.playfair(size: 16, weight: FontWeight.w800, color: textCol)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(trend,
              style: AppTextStyles.dmSans(
                  size: 8,
                  weight: FontWeight.w700,
                  color: isGreenTrend ? const Color(0xFF15803D) : const Color(0xFFB91C1C))),
        ],
      ),
    );
  }

  Widget _buildRateGridItem(String label, String value, {bool isGreen = false, bool isGold = false}) {
    Color valCol = _theme.getTextColor(context);
    if (isGreen) valCol = const Color(0xFF15803D);
    if (isGold) valCol = const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: _theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context), weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: valCol)),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.playfair(size: 10, weight: FontWeight.w800, color: _theme.getTextColor(context))),
      ],
    );
  }
}
