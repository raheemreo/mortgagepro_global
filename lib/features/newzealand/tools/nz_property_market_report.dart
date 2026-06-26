// lib/features/newzealand/tools/nz_property_market_report.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZPropertyMarketReport extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZPropertyMarketReport({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZPropertyMarketReport> createState() => _NZPropertyMarketReportState();
}

class _NZPropertyMarketReportState extends ConsumerState<NZPropertyMarketReport> with SingleTickerProviderStateMixin {
  String _selectedTab = 'All NZ';
  bool _isRefreshing = false;
  late AnimationController _refreshController;

  static const List<String> _tabs = ['All NZ', 'Auckland', 'Wellington', 'Canterbury', 'Waikato', 'BOP'];

  static const List<_RegionData> _allRegions = [
    _RegionData('Auckland', '🏙️', 950000, -1.2, 38, 0.95, 'green'),
    _RegionData('Tauranga', '🌊', 810000, -0.8, 41, 0.81, 'teal'),
    _RegionData('Wellington', '🌊', 780000, -2.4, 43, 0.78, 'sky'),
    _RegionData('Hamilton', '🌺', 650000, 0.5, 46, 0.65, 'gold'),
    _RegionData('Christchurch', '🏔️', 610000, 1.8, 35, 0.61, 'green'),
    _RegionData('Nelson/Tasman', '🌿', 570000, -0.6, 39, 0.57, 'teal'),
    _RegionData('Dunedin', '🍇', 520000, 2.1, 50, 0.52, 'sky'),
    _RegionData('Hawke\'s Bay', '🍇', 550000, -1.9, 42, 0.55, 'slate'),
    _RegionData('Manawatū', '🌿', 440000, 0.3, 52, 0.44, 'red'),
    _RegionData('Southland', '🌄', 360000, 3.2, 58, 0.36, 'gold'),
  ];

  static const _signals = [
    ('RBNZ OCR Trajectory', '5.25%', 'Cutting', Color(0xFF22C55E), Color(0xFFECFDF5), Color(0xFF065F46)),
    ('Listings Inventory', '22,180', 'Elevated', Color(0xFFC0392B), Color(0xFFFEF2F2), Color(0xFFC0392B)),
    ('Auction Clearance Rate', '42.3%', 'Soft', Color(0xFFD4A017), Color(0xFFFFF7ED), Color(0xFFC2410C)),
    ('Net Migration (annual)', '+62,500', 'Strong', Color(0xFF22C55E), Color(0xFFECFDF5), Color(0xFF065F46)),
    ('Building Consents (mo.)', '2,840', 'Stable', Color(0xFF0D9488), Color(0xFFF3F4F6), Color(0xFF374151)),
    ('Mortgage Stress Index', '38.2%', 'High', Color(0xFFC0392B), Color(0xFFFEF2F2), Color(0xFFC0392B)),
    ('FHB Market Share', '28.6%', 'Rising', Color(0xFF22C55E), Color(0xFFECFDF5), Color(0xFF065F46)),
    ('Price-to-Rent Ratio', '26.8×', 'Elevated', Color(0xFFD4A017), Color(0xFFFFF7ED), Color(0xFFC2410C)),
  ];

  static const _forecasts = [
    ('Q3 2025', '\$795K', '↑ +1.3%'),
    ('Q4 2025', '\$812K', '↑ +2.2%'),
    ('Q1 2026', '\$830K', '↑ +2.2%'),
    ('12-Mo Target', '\$835K', '↑ +6.4%'),
    ('Auckland \'26', '\$985K', '↑ +3.7%'),
    ('ChCh \'26', '\$645K', '↑ +5.7%'),
  ];

  static const _insights = [
    ('📉', 'OCR Cuts Spurring Buyer Return', 'RBNZ\'s OCR reductions from 5.50% to 5.25% in May 2025 have begun flowing through to fixed mortgage rates, with 1-year rates falling from 6.89% (peak) to 6.59%. Buyer activity is recovering, particularly among first-home buyers leveraging KiwiSaver.', Color(0xFFECFDF5)),
    ('⚠️', 'Oversupply Caution in Auckland', 'Active listings remain 28% above the 5-year average in Auckland. High inventory combined with cautious buyer sentiment means further price softening is expected in 2025 before stabilisation in Q3. Days-on-market average 38 days vs 29 days in 2022.', Color(0xFFFFF7ED)),
    ('🌟', 'Christchurch & Southland Outperform', 'Christchurch (+1.8% YoY) and Southland (+3.2% YoY) are the standout performers in 2025. Relative affordability, strong employment in the South Island, and growing infrastructure investment are driving demand in these regions.', Color(0xFFECFDF5)),
    ('🏗️', 'Building Consents: Gradual Recovery', 'New building consents issued nationally were 2,840 in April 2025, down 18% from the 2022 peak but stabilising. The government\'s Fast Track Approvals Bill is expected to lift medium-density supply, particularly in Auckland and Hamilton from 2026.', Color(0xFFEFF6FF)),
    ('📊', 'Migration Underpins Long-Term Demand', 'Net annual migration of +62,500 continues to support underlying housing demand. However, with rental vacancy rates at 2.8% nationally, pressure on rental yields is increasing, making buy-to-let investing more attractive as mortgage rates fall.', Color(0xFFF5F3FF)),
  ];

  static const _sources = [
    ('📊', 'REINZ House Price Index', 'Real Estate Institute NZ · Monthly HPI · reinz.co.nz'),
    ('🏢', 'CoreLogic NZ Property Report', 'Best of the Best quarterly · corelogic.co.nz'),
    ('🏷️', 'QV Quotable Value', 'Government valuations · property data · qv.co.nz'),
    ('📰', 'Stats NZ Housing Data', 'Building consents · population · stats.govt.nz'),
    ('🏛️', 'RBNZ Financial Stability Report', 'Mortgage stress · LVR · credit data · rbnz.govt.nz'),
    ('🔍', 'OneRoof / Trade Me Property', 'Live listing data · market trends · oneroof.co.nz'),
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    _refreshController.forward(from: 0.0).then((_) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔄 Market report snapshot updated with latest Q1 2025 data!'),
          backgroundColor: widget.theme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _saveReport() async {
    final labelCtrl = TextEditingController(text: 'NZ Property Market Report');
    final double activeTabIdx = _tabs.indexOf(_selectedTab).toDouble();
    final currentStats = _getTabStats();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Report Snapshot',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving Property Market Snapshot:\nFilter: $_selectedTab · Median: ${currentStats.medianStr}\nSales/mo: ${currentStats.salesVol} · HPI: ${currentStats.hpiIndex}',
              style: AppTextStyles.dmSans(
                  size: 11.5, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Q1 2025 Market Overview)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
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
                    size: 12,
                    weight: FontWeight.bold,
                    color: widget.theme.getMutedColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && labelCtrl.text.isNotEmpty && mounted) {
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'NZ Property Market Report',
        inputs: {
          'tabIndex': activeTabIdx,
        },
        results: {
          'medianPrice': currentStats.medianPrice.toDouble(),
          'yoyChange': currentStats.yoyChange,
          'hpiIndex': currentStats.hpiIndex.toDouble(),
          'salesVol': currentStats.salesVol.toDouble(),
          'daysOnMarket': currentStats.daysOnMarket.toDouble(),
        },
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Property market report snapshot saved!'),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteSaved(String id) async {
    await ref.read(savedProvider.notifier).delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🗑 Snapshot removed'),
          backgroundColor: widget.theme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearAllSaved() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        title: Text('Clear Reports', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Text('Are you sure you want to clear all saved market reports?', style: AppTextStyles.dmSans(size: 13, color: widget.theme.getMutedColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primaryColor),
            child: Text('Clear All', style: AppTextStyles.dmSans(size: 12, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final saved = ref.read(savedProvider);
      final reportIds = saved
          .where((c) => c.calcType == 'NZ Property Market Report' && c.country == 'New Zealand')
          .map((c) => c.id)
          .toList();
      for (var id in reportIds) {
        await ref.read(savedProvider.notifier).delete(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑 All saved reports cleared'),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  _TabStats _getTabStats() {
    switch (_selectedTab) {
      case 'Auckland':
        return const _TabStats(medianPrice: 950000, medianStr: '\$950K', yoyChange: -1.2, salesVol: 1840, hpiIndex: 3180, daysOnMarket: 38, piRatio: 13.1, needlePos: 0.85);
      case 'Wellington':
        return const _TabStats(medianPrice: 780000, medianStr: '\$780K', yoyChange: -2.4, salesVol: 860, hpiIndex: 3220, daysOnMarket: 43, piRatio: 9.2, needlePos: 0.60);
      case 'Canterbury':
        return const _TabStats(medianPrice: 610000, medianStr: '\$610K', yoyChange: 1.8, salesVol: 1120, hpiIndex: 3380, daysOnMarket: 35, piRatio: 7.2, needlePos: 0.45);
      case 'Waikato':
        return const _TabStats(medianPrice: 650000, medianStr: '\$650K', yoyChange: 0.5, salesVol: 720, hpiIndex: 3260, daysOnMarket: 46, piRatio: 7.8, needlePos: 0.50);
      case 'BOP':
        return const _TabStats(medianPrice: 810000, medianStr: '\$810K', yoyChange: -0.8, salesVol: 540, hpiIndex: 3290, daysOnMarket: 41, piRatio: 8.5, needlePos: 0.55);
      default:
        return const _TabStats(medianPrice: 785000, medianStr: '\$785K', yoyChange: -3.8, salesVol: 6420, hpiIndex: 3241, daysOnMarket: 44, piRatio: 9.7, needlePos: 0.65);
    }
  }

  List<_RegionData> _getFilteredRegions() {
    if (_selectedTab == 'All NZ') {
      return _allRegions;
    }
    return _allRegions.where((r) {
      if (_selectedTab == 'Canterbury') return r.name == 'Christchurch';
      if (_selectedTab == 'Waikato') return r.name == 'Hamilton';
      if (_selectedTab == 'BOP') return r.name == 'Tauranga';
      return r.name.toLowerCase() == _selectedTab.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);
    final borderCol = theme.getBorderColor(context);

    final stats = _getTabStats();
    final filteredRegions = _getFilteredRegions();

    // Saved calcs list from Riverpod
    final savedList = ref.watch(savedProvider);
    final reportCalcs = savedList
        .where((c) => c.calcType == 'NZ Property Market Report' && c.country == 'New Zealand')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Row
        Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStripItem('Median NZ', stats.medianStr, 'All NZ', Colors.white),
              _buildStripItem('YoY Chg', '${stats.yoyChange > 0 ? "+" : ""}${stats.yoyChange}%', 'Annual', stats.yoyChange > 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
              _buildStripItem('Sales Vol', '${stats.salesVol}', 'Monthly', Colors.white),
              _buildStripItem('Days on Mkt', '${stats.daysOnMarket}', 'Avg NZ', const Color(0xFFF5D060)),
            ],
          ),
        ),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Market Overview', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(color: Color(0xFFECFDF5), borderRadius: BorderRadius.all(Radius.circular(20))),
              child: const Text('June 2025', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
            )
          ],
        ),
        const SizedBox(height: 10),

        // Hero KPI Card
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CORELOGIC HPI · REINZ · QUOTABLE VALUE · JUNE 2025',
                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
                  children: [
                    const TextSpan(text: 'NZ Property Market '),
                    const TextSpan(text: 'Live Report', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: '\n$_selectedTab · Q1 2025 statistics'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Grid Row
              Row(
                children: [
                  Expanded(
                    child: _buildHeroKpi(
                      label: 'Median Price',
                      value: stats.medianStr,
                      change: '${stats.yoyChange > 0 ? "+" : ""}${stats.yoyChange}% YoY',
                      isUp: stats.yoyChange > 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroKpi(
                      label: 'Sales Volume',
                      value: '${stats.salesVol}',
                      change: '+8.2% MoM',
                      isUp: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroKpi(
                      label: 'HPI Index',
                      value: '${stats.hpiIndex}',
                      change: '-1.4% QoQ',
                      isUp: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Source row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📡 Sources: CoreLogic · REINZ · QV · Stats NZ',
                    style: AppTextStyles.dmSans(size: 8, color: Colors.white38),
                  ),
                  GestureDetector(
                    onTap: _refreshData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      child: Row(
                        children: [
                          RotationTransition(
                            turns: _refreshController,
                            child: const Text('🔄', style: TextStyle(fontSize: 10)),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Refresh',
                            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Save Snapshot Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A6B4A), Color(0xFF0D3B2E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A6B4A).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🔖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save This Report', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 1),
                    Text('Snapshot market data for your records', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5D060),
                  foregroundColor: const Color(0xFF0A0F0D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                ),
                child: Text('💾 Save', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Live Data Banner
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
            border: Border.all(color: const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('📡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Data: CoreLogic + REINZ HPI', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                    const SizedBox(height: 2),
                    Text('Real Estate Institute NZ monthly HPI · Updated May 2025', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF3B82F6))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                child: const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter Tabs
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _tabs.length,
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isActive = tab == _selectedTab;
              return Container(
                margin: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  label: Text(tab),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    }
                  },
                  selectedColor: theme.primaryColor,
                  backgroundColor: cardBg,
                  labelStyle: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.bold,
                    color: isActive ? Colors.white : mutedCol,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isActive ? theme.primaryColor : borderCol),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),

        // Key Market Metrics Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Key Market Metrics', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('CoreLogic →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard('🏡', stats.medianStr, 'NZ Median House Price', '${stats.yoyChange > 0 ? "+" : ""}${stats.yoyChange}% YoY', stats.yoyChange > 0, bg: cardBg, text: textCol, muted: mutedCol, border: borderCol),
            _buildMetricCard('📈', '${stats.hpiIndex}', 'CoreLogic HPI (May 2025)', '-1.4% vs Q4 2024', false, bg: cardBg, text: textCol, muted: mutedCol, border: borderCol),
            _buildMetricCard('🔄', '${stats.salesVol}', 'Monthly Sales (Apr 2025)', '+8.2% month-on-month', true, bg: cardBg, text: textCol, muted: mutedCol, border: borderCol),
            _buildMetricCard('⏱️', '${stats.daysOnMarket} days', 'Avg Days on Market', '-3 days vs prior month', false, bg: cardBg, text: textCol, muted: mutedCol, border: borderCol),
            _buildMetricCard('🏘️', '22,180', 'Active Listings (May 2025)', '+12.4% vs year ago', true, bg: cardBg, text: textCol, muted: mutedCol, border: borderCol),
            _buildMetricCard('💰', '${stats.piRatio}×', 'Price-to-Income Ratio', 'down from 11.2× peak', false, bg: cardBg, text: textCol, muted: mutedCol, border: borderCol),
          ],
        ),
        const SizedBox(height: 20),

        // Regional Price Bars Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Regional Median Prices', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('REINZ →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Median Price by Region', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                      const SizedBox(height: 2),
                      Text('REINZ data · April 2025 · NZD', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: const BoxDecoration(color: Color(0xFFECFDF5), borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: Text('${filteredRegions.length} Regions', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRegions.length,
                itemBuilder: (context, index) {
                  final reg = filteredRegions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 11),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 105,
                          child: Text(reg.name, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: textCol)),
                        ),
                        Expanded(
                          child: Container(
                            height: 26,
                            decoration: BoxDecoration(
                              color: theme.getBgColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Container(
                                      width: constraints.maxWidth * reg.widthPct,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _getBarColors(reg.colorType),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.compact(reg.medianPrice, symbol: '\$'),
                                      style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 45,
                          child: Text(
                            '${reg.yoyChange > 0 ? "+" : ""}${reg.yoyChange}%',
                            style: AppTextStyles.dmSans(
                              size: 9.5,
                              weight: FontWeight.bold,
                              color: reg.yoyChange > 0 ? const Color(0xFF15803D) : const Color(0xFFC0392B),
                            ),
                            textAlign: TextAlign.right,
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
        const SizedBox(height: 20),

        // CoreLogic HPI Trend Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CoreLogic HPI Trend', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('12 Months →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('House Price Index — NZ National', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                      const SizedBox(height: 2),
                      Text('CoreLogic HPI · Jun 2024 – May 2025', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: const BoxDecoration(color: Color(0xFFECFDF5), borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: const Text('CoreLogic', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  )
                ],
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 370 / 140,
                child: CustomPaint(
                  painter: _HPIReportTrendPainter(isDark: isDark, theme: theme),
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jun\'24', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  Text('Aug\'24', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  Text('Oct\'24', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  Text('Dec\'24', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  Text('Feb\'25', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  Text('Apr\'25', style: TextStyle(fontSize: 8, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChartLegend('NZ National HPI', theme.primaryColor, isDashed: false),
                  const SizedBox(width: 14),
                  _buildChartLegend('Auckland HPI', const Color(0xFF0EA5E9), isDashed: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quarterly Snapshots Sparklines
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quarterly Snapshots', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('QV →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            _buildSparkCard('New Listings', '5,840', '↑ +5.3% MoM', true, theme.primaryColor, [28.0, 25.0, 22.0, 27.0, 20.0, 15.0, 12.0], cardBg, textCol, mutedCol, borderCol),
            _buildSparkCard('Avg Asking Price', '\$812K', '↓ -1.6% MoM', false, const Color(0xFFC0392B), [14.0, 16.0, 22.0, 25.0, 28.0, 30.0, 27.0], cardBg, textCol, mutedCol, borderCol),
            _buildSparkCard('Investor Activity', '23.4%', '↑ +2.1% vs Q4', true, const Color(0xFFD4A017), [30.0, 28.0, 26.0, 24.0, 20.0, 18.0, 15.0], cardBg, textCol, mutedCol, borderCol),
            _buildSparkCard('FHB Share', '28.6%', '↑ +1.4% vs Q4', true, const Color(0xFF0D9488), [24.0, 22.0, 20.0, 18.0, 14.0, 12.0, 10.0], cardBg, textCol, mutedCol, borderCol),
          ],
        ),
        const SizedBox(height: 20),

        // Buyer Type Breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Buyer Type Breakdown', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('REINZ →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Who\'s Buying in 2025?', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                      const SizedBox(height: 2),
                      Text('REINZ buyer profile · April 2025', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: const BoxDecoration(color: Color(0xFFECFDF5), borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: const Text('Apr 2025', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _BuyerBreakdownDonutPainter(isDark: isDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDonutLegendRow('First Home Buyers', 'KiwiSaver eligible', '28.6%', theme.primaryColor, textCol, mutedCol),
                        _buildDonutLegendRow('Investors', '35% LVR applies', '23.4%', const Color(0xFF0D9488), textCol, mutedCol),
                        _buildDonutLegendRow('Home Movers', 'Existing owners', '29.8%', const Color(0xFF0EA5E9), textCol, mutedCol),
                        _buildDonutLegendRow('Other / Corp', 'Trusts, entities', '18.2%', const Color(0xFFD4A017), textCol, mutedCol),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Affordability stress gauge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Affordability Gauge', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('Stats NZ →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Housing Affordability Stress', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                      const SizedBox(height: 2),
                      Text('Price-to-income ratio across NZ regions', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: const BoxDecoration(color: Color(0xFFFEE2E2), borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: const Text('Stressed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Affordability stress linear meter
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final needleOffset = (width * stats.needlePos) - 11.0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFFFBBF24), Color(0xFFEF4444)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: needleOffset,
                        top: -3,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF0A0F0D), width: 3),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Affordable', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedCol)),
                  Text('Moderate', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedCol)),
                  Text('Stressed', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedCol)),
                  Text('Severe', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedCol)),
                ],
              ),
              const SizedBox(height: 16),

              // KPI stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAffordKpi('NZ Price/Income', '${stats.piRatio}×', const Color(0xFFC0392B), mutedCol),
                  _buildAffordKpi('Auckland P/I', '13.1×', const Color(0xFFC0392B), mutedCol),
                  _buildAffordKpi('Southland P/I', '6.4×', theme.primaryColor, mutedCol),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Supply vs Demand Grouped Bars
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Supply vs Demand', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('All →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Listings vs Demand Index', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                      const SizedBox(height: 2),
                      Text('Quarterly 2024–2025 · Relative scale', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: const BoxDecoration(color: Color(0xFFF3F4F6), borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: const Text('Balanced', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Grouped bars row
              SizedBox(
                height: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildGroupedBarPair('Q2\n2024', 52, 44, theme, mutedCol),
                    _buildGroupedBarPair('Q3\n2024', 58, 47, theme, mutedCol),
                    _buildGroupedBarPair('Q4\n2024', 65, 55, theme, mutedCol),
                    _buildGroupedBarPair('Q1\n2025', 70, 58, theme, mutedCol),
                    _buildGroupedBarPair('Q2\n2025', 72, 60, theme, mutedCol),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChartLegend('New Listings', theme.primaryColor, isDashed: false),
                  const SizedBox(width: 14),
                  _buildChartLegend('Buyer Demand Index', const Color(0xFF0EA5E9), isDashed: false),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Regional Detail Table
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Regional Detail Table', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('All 16 →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.0),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderCol, width: 1.0)),
                ),
                children: [
                  _buildTableHeaderCell('Region', isLeft: true, mutedCol: mutedCol),
                  _buildTableHeaderCell('Median', mutedCol: mutedCol),
                  _buildTableHeaderCell('YoY', mutedCol: mutedCol),
                  _buildTableHeaderCell('DOM', isRight: true, mutedCol: mutedCol),
                ],
              ),
              ...filteredRegions.map((reg) {
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text(reg.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(reg.name, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: textCol)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        CurrencyFormatter.compact(reg.medianPrice, symbol: '\$'),
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.primaryColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '${reg.yoyChange > 0 ? "+" : ""}${reg.yoyChange}%',
                        style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.bold,
                          color: reg.yoyChange > 0 ? const Color(0xFF15803D) : const Color(0xFFC0392B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '${reg.daysOnMarket}d',
                        style: AppTextStyles.dmSans(size: 11, color: mutedCol),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Market Health Signals
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Market Health Signals', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('Full →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            children: _signals.map((sig) {
              return _buildSignalRow(sig.$1, sig.$2, sig.$3, sig.$4, sig.$5, sig.$6, textCol);
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // 12-Month Forecast Outlook
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12-Month Outlook', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('CoreLogic →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'NZ Price Forecast '),
                    TextSpan(text: '2025–2026', style: TextStyle(color: Color(0xFFF5D060))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
                children: _forecasts.map((fc) {
                  return _buildForecastBox(fc.$1, fc.$2, fc.$3);
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '📊 Forecasts: CoreLogic NZ, Westpac NZ, ANZ Research · Indicative only',
                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Expert Insights
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Expert Insights', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            Text('All →', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: theme.primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: _insights.map((ins) {
            return _buildInsightCard(ins.$1, ins.$2, ins.$3, ins.$4, cardBg, textCol, mutedCol, borderCol);
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Saved calculation snapshots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Snapshots', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            if (reportCalcs.isNotEmpty)
              GestureDetector(
                onTap: _clearAllSaved,
                child: Text('Clear All', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFFC0392B))),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (reportCalcs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              'No saved report snapshots yet. Tap 💾 Save to snapshot data.',
              style: AppTextStyles.dmSans(size: 11, color: mutedCol),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...reportCalcs.map((c) {
            final double activeTabIdx = c.inputs['tabIndex'] ?? 0;
            final double medPrice = c.results['medianPrice'] ?? 785000;
            final double yoyCh = c.results['yoyChange'] ?? -3.8;
            final double hpi = c.results['hpiIndex'] ?? 3241;
            final String tabName = _tabs[activeTabIdx.toInt() % _tabs.length];
            final savedDateStr = '${c.savedAt.day} ${_getMonthName(c.savedAt.month)} ${c.savedAt.year}';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.label} ($tabName)',
                          style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textCol),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Median: ${CurrencyFormatter.compact(medPrice, symbol: "NZ\$")} (${yoyCh > 0 ? "+" : ""}$yoyCh%) · HPI: ${hpi.toInt()} · $savedDateStr',
                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteSaved(c.id),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('✕', style: TextStyle(color: Color(0xFFC0392B), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),

        // Official Data Sources
        Text('Official Data Sources', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Column(
          children: _sources.map((src) {
            return _buildSourceLinkCard(src.$1, src.$2, src.$3, cardBg, textCol, mutedCol, borderCol);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStripItem(String label, String value, String sub, Color valColor) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: valColor)),
        const SizedBox(height: 2),
        Text(sub, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
      ],
    );
  }

  Widget _buildHeroKpi({
    required String label,
    required String value,
    required String change,
    required bool isUp,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            change,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.bold,
              color: isUp ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String emoji,
    String value,
    String label,
    String change,
    bool isUp, {
    required Color bg,
    required Color text,
    required Color muted,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.dmSans(size: 15.5, weight: FontWeight.w800, color: text)),
          Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: muted)),
          const Spacer(),
          Text(
            change,
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.bold,
              color: isUp ? const Color(0xFF15803D) : const Color(0xFFC0392B),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getBarColors(String type) {
    switch (type) {
      case 'teal':
        return const [Color(0xFF0D9488), Color(0xFF14B8A6)];
      case 'sky':
        return const [Color(0xFF0EA5E9), Color(0xFF38BDF8)];
      case 'gold':
        return const [Color(0xFFD4A017), Color(0xFFFBBF24)];
      case 'red':
        return const [Color(0xFFC0392B), Color(0xFFEF4444)];
      case 'slate':
        return const [Color(0xFF334155), Color(0xFF64748B)];
      default: // green
        return const [Color(0xFF1A6B4A), Color(0xFF22C55E)];
    }
  }

  Widget _buildChartLegend(String label, Color col, {required bool isDashed}) {
    return Row(
      children: [
        if (isDashed)
          Row(
            children: [
              Container(width: 5, height: 2, color: col),
              const SizedBox(width: 2),
              Container(width: 5, height: 2, color: col),
            ],
          )
        else
          Container(
            width: 12,
            height: 2,
            decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2)),
          ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildSparkCard(
    String label,
    String value,
    String change,
    bool isUp,
    Color strokeCol,
    List<double> points,
    Color bg,
    Color text,
    Color muted,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: muted)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 16.5, weight: FontWeight.w800, color: text)),
          const Spacer(),
          SizedBox(
            height: 32,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparklinePainter(points: points, strokeColor: strokeCol),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.bold,
              color: isUp ? const Color(0xFF15803D) : const Color(0xFFC0392B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow(String label, String sub, String pct, Color col, Color text, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2.5)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: text)),
                Text(sub, style: AppTextStyles.dmSans(size: 8, color: muted)),
              ],
            ),
          ),
          Text(pct, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: text)),
        ],
      ),
    );
  }

  Widget _buildAffordKpi(String label, String value, Color valColor, Color muted) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: valColor)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: muted)),
      ],
    );
  }

  Widget _buildGroupedBarPair(String quarter, double val1, double val2, CountryTheme theme, Color muted) {
    const double maxH = 65.0;
    const double scaleFactor = maxH / 100.0;
    final h1 = val1 * scaleFactor;
    final h2 = val2 * scaleFactor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 14,
              height: h1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 14,
              height: h2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          quarter,
          style: AppTextStyles.dmSans(size: 7.5, color: muted, height: 1.15),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String label, {bool isLeft = false, bool isRight = false, required Color mutedCol}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedCol),
        textAlign: isLeft ? TextAlign.left : (isRight ? TextAlign.right : TextAlign.center),
      ),
    );
  }

  Widget _buildSignalRow(String name, String val, String signal, Color sigColor, Color badgeBg, Color badgeTxt, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.theme.getBorderColor(context), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: sigColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: textCol)),
          ),
          Text(val, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: textCol)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              signal,
              style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: badgeTxt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastBox(String period, String val, String chg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(period, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            chg,
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: const Color(0xFF6EE7B7)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String emoji,
    String title,
    String desc,
    Color bgOpacityCol,
    Color bgCard,
    Color textCol,
    Color mutedCol,
    Color borderCol,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgOpacityCol,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 3),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLinkCard(
    String emoji,
    String title,
    String subtitle,
    Color bgCard,
    Color textCol,
    Color mutedCol,
    Color borderCol,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: textCol.withValues(alpha: 0.18)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }
}

class _RegionData {
  final String name;
  final String icon;
  final double medianPrice;
  final double yoyChange;
  final int daysOnMarket;
  final double widthPct;
  final String colorType;

  const _RegionData(
    this.name,
    this.icon,
    this.medianPrice,
    this.yoyChange,
    this.daysOnMarket,
    this.widthPct,
    this.colorType,
  );
}

class _TabStats {
  final double medianPrice;
  final String medianStr;
  final double yoyChange;
  final int salesVol;
  final int hpiIndex;
  final int daysOnMarket;
  final double piRatio;
  final double needlePos;

  const _TabStats({
    required this.medianPrice,
    required this.medianStr,
    required this.yoyChange,
    required this.salesVol,
    required this.hpiIndex,
    required this.daysOnMarket,
    required this.piRatio,
    required this.needlePos,
  });
}

// ── CUSTOM PAINTERS ──

class _HPIReportTrendPainter extends CustomPainter {
  final bool isDark;
  final CountryTheme theme;

  const _HPIReportTrendPainter({required this.isDark, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 370.0;
    final scaleY = size.height / 130.0;

    final borderPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0x170D3B2E)
      ..strokeWidth = 1.0;

    // Horizontal grid lines
    final yTicks = [25.0, 55.0, 85.0, 112.0];
    final yLabels = ['3,350', '3,280', '3,210', ''];

    for (int i = 0; i < yTicks.length; i++) {
      final y = yTicks[i] * scaleY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), borderPaint);

      if (yLabels[i].isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: yLabels[i],
            style: TextStyle(
              fontSize: 8,
              color: isDark ? Colors.white54 : const Color(0xFF4A6358),
              fontFamily: 'Helvetica Neue',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(2 * scaleX, y - 10 * scaleY));
      }
    }

    // Line 1: NZ National HPI
    const nzPts = [
      Offset(10, 88), Offset(43, 85), Offset(76, 84), Offset(109, 90), Offset(142, 93),
      Offset(175, 91), Offset(208, 87), Offset(241, 83), Offset(274, 80), Offset(307, 78),
      Offset(340, 76), Offset(370, 73)
    ];

    // Line 2: Auckland HPI
    const aucPts = [
      Offset(10, 72), Offset(43, 68), Offset(76, 66), Offset(109, 74), Offset(142, 79),
      Offset(175, 77), Offset(208, 72), Offset(241, 67), Offset(274, 63), Offset(307, 60),
      Offset(340, 57), Offset(370, 54)
    ];

    final scaledNz = nzPts.map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY)).toList();
    final scaledAuc = aucPts.map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY)).toList();

    // Areas Fills
    if (scaledNz.length >= 2) {
      final fillPath = Path()..moveTo(scaledNz.first.dx, scaledNz.first.dy);
      for (int i = 1; i < scaledNz.length; i++) {
        fillPath.lineTo(scaledNz[i].dx, scaledNz[i].dy);
      }
      fillPath.lineTo(scaledNz.last.dx, 112 * scaleY);
      fillPath.lineTo(scaledNz.first.dx, 112 * scaleY);
      fillPath.close();

      final fillPaint = Paint()
        ..color = theme.primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    if (scaledAuc.length >= 2) {
      final fillPath = Path()..moveTo(scaledAuc.first.dx, scaledAuc.first.dy);
      for (int i = 1; i < scaledAuc.length; i++) {
        fillPath.lineTo(scaledAuc[i].dx, scaledAuc[i].dy);
      }
      fillPath.lineTo(scaledAuc.last.dx, 112 * scaleY);
      fillPath.lineTo(scaledAuc.first.dx, 112 * scaleY);
      fillPath.close();

      final fillPaint = Paint()
        ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // NZ Line Paint
    final nzPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Auckland Line Paint (Dashed effect drawn by manually drawing segment lines)
    final aucPaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (scaledNz.length >= 2) {
      final path = Path()..moveTo(scaledNz.first.dx, scaledNz.first.dy);
      for (int i = 1; i < scaledNz.length; i++) {
        path.lineTo(scaledNz[i].dx, scaledNz[i].dy);
      }
      canvas.drawPath(path, nzPaint);
    }

    // Custom dash path drawing for Auckland line
    if (scaledAuc.length >= 2) {
      final path = Path()..moveTo(scaledAuc.first.dx, scaledAuc.first.dy);
      for (int i = 1; i < scaledAuc.length; i++) {
        path.lineTo(scaledAuc[i].dx, scaledAuc[i].dy);
      }
      canvas.drawPath(path, aucPaint);
    }

    // Points indicators (NZ line circles)
    final dotPaint = Paint()..color = theme.primaryColor;
    final whiteBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw some indicator dots matching coordinates: cx="10", cx="109", cx="175", cx="370"
    if (scaledNz.isNotEmpty) canvas.drawCircle(scaledNz[0], 3.0, dotPaint);
    if (scaledNz.length > 3) canvas.drawCircle(scaledNz[3], 3.0, dotPaint);
    if (scaledNz.length > 5) canvas.drawCircle(scaledNz[5], 3.5, dotPaint);
    if (scaledNz.isNotEmpty) {
      canvas.drawCircle(scaledNz.last, 4.0, dotPaint);
      canvas.drawCircle(scaledNz.last, 4.0, whiteBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _HPIReportTrendPainter oldDelegate) => oldDelegate.isDark != isDark;
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color strokeColor;

  const _SparklinePainter({required this.points, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final double stepX = size.width / (points.length - 1);
    final double minVal = points.reduce(math.min);
    final double maxVal = points.reduce(math.max);
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final fillPath = Path();

    // Map y coordinates (height is size.height, pad slightly)
    final double pad = size.height * 0.15;
    final double h = size.height - 2 * pad;

    double getX(int index) => index * stepX;
    double getY(double val) {
      final normalized = (val - minVal) / range;
      // Invert Y axis
      return size.height - pad - (normalized * h);
    }

    path.moveTo(getX(0), getY(points[0]));
    fillPath.moveTo(getX(0), getY(points[0]));

    for (int i = 1; i < points.length; i++) {
      path.lineTo(getX(i), getY(points[i]));
      fillPath.lineTo(getX(i), getY(points[i]));
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor || oldDelegate.points != points;
}

class _BuyerBreakdownDonutPainter extends CustomPainter {
  final bool isDark;

  const _BuyerBreakdownDonutPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const strokeW = 18.0;
    final ringRadius = radius - strokeW / 2;

    final basePaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    // Fractions: FHB (28.6%), Investors (23.4%), Movers (29.8%), Other (18.2%)
    const fractions = [0.286, 0.234, 0.298, 0.182];
    const colors = [
      Color(0xFF1A6B4A),
      Color(0xFF0D9488),
      Color(0xFF0EA5E9),
      Color(0xFFD4A017),
    ];

    double startAngle = -math.pi / 2; // Starts at -90 degrees

    for (int i = 0; i < fractions.length; i++) {
      final sweepAngle = fractions[i] * 2 * math.pi;
      final segmentPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;

      canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);
      startAngle += sweepAngle;
    }

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '6,420',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0A0F0D),
          fontFamily: 'Palatino',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'Sales/mo',
        style: TextStyle(
          fontSize: 7.5,
          color: isDark ? Colors.white38 : const Color(0xFF4A6358),
          fontFamily: 'Helvetica Neue',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -textPainter.height / 2 - 6));
    subPainter.paint(canvas, center + Offset(-subPainter.width / 2, -subPainter.height / 2 + 10));
  }

  @override
  bool shouldRepaint(covariant _BuyerBreakdownDonutPainter oldDelegate) => oldDelegate.isDark != isDark;
}
