// lib/features/newzealand/tools/nz_reinz_hpi.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZReinzHpi extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZReinzHpi({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZReinzHpi> createState() => _NZReinzHpiState();
}

class _NZReinzHpiState extends ConsumerState<NZReinzHpi> {
  String _activeFilter = 'all'; // 'all', 'north', 'south', 'metro'

  final List<Map<String, dynamic>> _regions = [
    {
      'name': 'Auckland',
      'sub': 'North Island · Metro',
      'median': r'$980K',
      'chg': '−1.2%',
      'up': false,
      'island': 'north',
      'type': 'metro',
      'spark': [0.6, 0.45, 0.5, 0.4, 0.35, 0.3],
      'color': Colors.red,
    },
    {
      'name': 'Wellington',
      'sub': 'North Island · Capital',
      'median': r'$790K',
      'chg': '−2.4%',
      'up': false,
      'island': 'north',
      'type': 'metro',
      'spark': [0.7, 0.55, 0.48, 0.4, 0.35, 0.28],
      'color': Colors.red,
    },
    {
      'name': 'Hamilton',
      'sub': 'North Island · Waikato',
      'median': r'$660K',
      'chg': '+0.5%',
      'up': true,
      'island': 'north',
      'type': 'non-metro',
      'spark': [0.4, 0.38, 0.42, 0.44, 0.46, 0.5],
      'color': const Color(0xFF1A6B4A),
    },
    {
      'name': 'Tauranga',
      'sub': 'North Island · Bay of Plenty',
      'median': r'$820K',
      'chg': '−0.8%',
      'up': false,
      'island': 'north',
      'type': 'non-metro',
      'spark': [0.55, 0.5, 0.48, 0.45, 0.43, 0.41],
      'color': Colors.grey,
    },
    {
      'name': 'Christchurch',
      'sub': 'South Island · Canterbury',
      'median': r'$620K',
      'chg': '+1.8%',
      'up': true,
      'island': 'south',
      'type': 'metro',
      'spark': [0.42, 0.48, 0.52, 0.58, 0.62, 0.68],
      'color': const Color(0xFF1A6B4A),
    },
    {
      'name': 'Dunedin',
      'sub': 'South Island · Otago',
      'median': r'$530K',
      'chg': '+2.1%',
      'up': true,
      'island': 'south',
      'type': 'non-metro',
      'spark': [0.38, 0.44, 0.5, 0.56, 0.60, 0.66],
      'color': const Color(0xFF1A6B4A),
    },
    {
      'name': 'Queenstown-Lakes',
      'sub': 'South Island · Otago',
      'median': r'$1.42M',
      'chg': '+3.4%',
      'up': true,
      'island': 'south',
      'type': 'non-metro',
      'spark': [0.5, 0.55, 0.6, 0.65, 0.72, 0.8],
      'color': const Color(0xFFD4A017),
    },
  ];

  List<Map<String, dynamic>> get _filteredRegions {
    if (_activeFilter == 'all') return _regions;
    if (_activeFilter == 'north') return _regions.where((r) => r['island'] == 'north').toList();
    if (_activeFilter == 'south') return _regions.where((r) => r['island'] == 'south').toList();
    return _regions.where((r) => r['type'] == 'metro').toList();
  }

  void _saveSnapshot() async {
    final labelCtrl = TextEditingController(text: 'REINZ HPI Snapshot');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_reinz_hpi'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save HPI Snapshot',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving HPI Snapshot: Index 3,412 · Ann. Chg +2.1% · Median \$785K',
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
                hintText: 'Label (e.g. March 2025 HPI Report)',
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

    if (confirmed == true && labelCtrl.text.isNotEmpty) {
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'REINZ HPI Snapshot',
        inputs: {
          'nationalHpi': 3412,
          'medianPrice': 785000,
        },
        results: {
          'annualChangePct': 2.1,
          'monthlyChangePct': -0.3,
        },
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ HPI Snapshot saved to profile!'),
            backgroundColor: widget.theme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);
    final borderCol = theme.getBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip header replica
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
              _buildStripItem('NZ HPI', '3,412', 'Mar 2025', const Color(0xFFF5D060)),
              _buildStripItem('Annual Chg', '+2.1%', 'YoY', const Color(0xFF6EE7B7)),
              _buildStripItem('Median NZ', '\$785K', 'Mar 2025', Colors.white),
              _buildStripItem('Sales Vol', '−8%', 'YoY', const Color(0xFFFCA5A5)),
            ],
          ),
        ),

        // National HPI Snapshot Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'National HPI Snapshot',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'REINZ Report →',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero HPI card
        Container(
          padding: const EdgeInsets.all(20),
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
                'REINZ · REAL ESTATE INSTITUTE OF NEW ZEALAND · HPI MARCH 2025',
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white60,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'NZ House Price Index Report',
                style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Data as at March 2025 · Released April 2025 · Seasonally adjusted',
                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  _buildHeroGridItem('National HPI', '3,412', const Color(0xFFF5D060)),
                  _buildHeroGridItem('Annual Change', '+2.1%', const Color(0xFF6EE7B7)),
                  _buildHeroGridItem('National Median', 'NZ\$785K', Colors.white),
                  _buildHeroGridItem('Monthly Change', '−0.3%', const Color(0xFFFCA5A5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // National Trend Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'National HPI Trend 2019–2025',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Download Data →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chart Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REINZ HPI – National (Rebased 2017=1000)',
                    style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
                  ),
                  Text(
                    '● Mar 2025',
                    style: AppTextStyles.dmSans(size: 9.5, color: theme.primaryColor, weight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 360 / 150,
                child: CustomPaint(
                  painter: _HPITrendPainter(isDark: isDark, theme: theme),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2019', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text('2020', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text('2021', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text('2022', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text('2023', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text('2024', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text('Mar\'25', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Regional tables
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HPI by Region – March 2025',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'All 16 Regions →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Table Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              // Region filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton('All NZ', 'all'),
                    const SizedBox(width: 6),
                    _buildFilterButton('North Island', 'north'),
                    const SizedBox(width: 6),
                    _buildFilterButton('South Island', 'south'),
                    const SizedBox(width: 6),
                    _buildFilterButton('Metro', 'metro'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Table header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 18, child: Text('Region', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol))),
                    Expanded(flex: 10, child: Text('Median', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                    Expanded(flex: 10, child: Text('HPI Chg', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                    Expanded(flex: 10, child: Text('12M Trend', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const Divider(),

              // Rows
              ..._filteredRegions.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'], style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: textCol)),
                            Text(r['sub'], style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Text(
                          r['median'],
                          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.primaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Text(
                          r['chg'],
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: r['up'] ? theme.primaryColor : const Color(0xFFC0392B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Center(
                          child: _buildSparkline(r['spark'], r['color']),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Save Snapshot Button
        ElevatedButton(
          onPressed: _saveSnapshot,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
            minimumSize: const Size(double.infinity, 44),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📥  ', style: TextStyle(fontSize: 14, color: Colors.white)),
              Text(
                'Save HPI Snapshot (Mar 2025)',
                style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sales Volume
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Sales Volume 2024–2025',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'All Data →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Sales volume bars
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REINZ Sales Count – NZ National (Monthly)', style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 14),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildVolumeBar('Apr\'24', 0.42, '5,812', const Color(0xFF0D9488)),
                    _buildVolumeBar('May', 0.46, '6,234', const Color(0xFF0D9488)),
                    _buildVolumeBar('Jun', 0.38, '5,401', const Color(0xFF0D9488)),
                    _buildVolumeBar('Jul', 0.36, '5,118', const Color(0xFF0D9488)),
                    _buildVolumeBar('Aug', 0.40, '5,680', const Color(0xFF0D9488)),
                    _buildVolumeBar('Sep', 0.50, '6,941', theme.primaryColor),
                    _buildVolumeBar('Oct', 0.54, '7,350', theme.primaryColor),
                    _buildVolumeBar('Nov', 0.58, '7,820', theme.primaryColor),
                    _buildVolumeBar('Dec', 0.44, '6,102', const Color(0xFF0D9488)),
                    _buildVolumeBar('Jan\'25', 0.48, '6,580', theme.primaryColor),
                    _buildVolumeBar('Feb', 0.52, '7,100', theme.primaryColor),
                    _buildVolumeBar('Mar', 0.56, '7,540', const Color(0xFFD4A017)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Affordability by City
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Affordability by City 2025',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'CoreLogic →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Ratios Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏠 Price-to-Income Ratio (Median House / Median HHI)', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 16),
              _buildAffordRow('Auckland', r'Median income ~$108,000 · Median house $980K', 0.91, const Color(0xFFC0392B), '9.1×'),
              const SizedBox(height: 12),
              _buildAffordRow('Wellington', r'Median income ~$102,000 · Median house $790K', 0.77, const Color(0xFFC0392B), '7.7×'),
              const SizedBox(height: 12),
              _buildAffordRow('Christchurch', r'Median income ~$95,000 · Median house $620K', 0.65, const Color(0xFFD4A017), '6.5×'),
              const SizedBox(height: 12),
              _buildAffordRow('Dunedin', r'Median income ~$88,000 · Median house $530K', 0.60, const Color(0xFF0D9488), '6.0×'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Market Context
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Context',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'CoreLogic Report →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Context Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)]),
            border: Border.all(color: const Color(0xFF5EEAD4), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📌 Key Market Insights – March 2025',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(height: 10),
              _buildContextBullet('📉', 'Prices down ~18% from 2021 peak.', r'National median fell from ~$925K (Nov 2021) to $785K (Mar 2025).'),
              const SizedBox(height: 8),
              _buildContextBullet('🔄', 'OCR cuts driving recovery.', '1.75% of OCR cuts since Aug 2024 are supporting buyer confidence and lifting sales volumes.'),
              const SizedBox(height: 8),
              _buildContextBullet('📊', 'South Island outperforming.', 'Christchurch (+1.8%) and Dunedin (+2.1%) leading national recovery vs. Auckland weakness.'),
              const SizedBox(height: 8),
              _buildContextBullet('🏗️', 'Listings rising.', 'New listing inventory up ~12% YoY — giving buyers more choice and keeping prices subdued nationally.'),
            ],
          ),
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

  Widget _buildHeroGridItem(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
          const SizedBox(height: 3),
          Text(val, style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String code) {
    final active = _activeFilter == code;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? widget.theme.primaryColor : widget.theme.getBorderColor(context)),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.bold,
            color: active ? Colors.white : widget.theme.getTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline(List<double> vals, Color color) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: vals.map((val) {
          return Container(
            margin: const EdgeInsets.only(right: 2),
            width: 3,
            height: val * 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVolumeBar(String month, double heightPct, String count, Color col) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(count, style: AppTextStyles.dmSans(size: 7, weight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 2),
          Container(
            width: 14,
            height: heightPct * 50,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 4),
          Text(month, style: AppTextStyles.dmSans(size: 7.5, color: widget.theme.getMutedColor(context)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAffordRow(String city, String details, double widthPct, Color color, String ratio) {
    return Row(
      children: [
        const Text('🏙️', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
              Text(details, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
              const SizedBox(height: 5),
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: widget.theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widthPct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          ratio,
          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildContextBullet(String emoji, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF0D3B2E), height: 1.5),
              children: [
                TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HPITrendPainter extends CustomPainter {
  final bool isDark;
  final CountryTheme theme;

  const _HPITrendPainter({required this.isDark, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 360;
    final scaleY = size.height / 150;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0x170D3B2E)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines (dashed lines from HTML)
    // Y coords: 20 (3,600), 55 (3,200), 90 (2,400), 125 (1,800)
    final yTicks = [20.0, 55.0, 90.0, 125.0];
    final labels = ['3,600', '3,200', '2,400', '1,800'];

    for (int i = 0; i < yTicks.length; i++) {
      final y = yTicks[i] * scaleY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 7.5,
            color: isDark ? Colors.white54 : const Color(0xFF4A6358),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(2 * scaleX, y - 10));
    }

    // Points from HTML polyline:
    // 36,118 72,100 108,52 144,18 180,18 216,70 252,85 288,78 324,65 360,68
    const pts = [
      Offset(36, 118), Offset(72, 100), Offset(108, 52), Offset(144, 18), Offset(180, 18),
      Offset(216, 70), Offset(252, 85), Offset(288, 78), Offset(324, 65), Offset(360, 68)
    ];

    final List<Offset> scaledPts = pts.map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY)).toList();

    // Fill under line
    if (scaledPts.length >= 2) {
      final fillPath = Path()..moveTo(scaledPts.first.dx, scaledPts.first.dy);
      for (int i = 1; i < scaledPts.length; i++) {
        fillPath.lineTo(scaledPts[i].dx, scaledPts[i].dy);
      }
      fillPath.lineTo(scaledPts.last.dx, 145 * scaleY);
      fillPath.lineTo(scaledPts.first.dx, 145 * scaleY);
      fillPath.close();

      final fillPaint = Paint()
        ..color = theme.primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (scaledPts.length >= 2) {
      final linePaint = Paint()
        ..color = theme.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()..moveTo(scaledPts.first.dx, scaledPts.first.dy);
      for (int i = 1; i < scaledPts.length; i++) {
        path.lineTo(scaledPts[i].dx, scaledPts[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Peak circle
    if (scaledPts.length > 4) {
      final peakPt = scaledPts[4]; // index 4 is x=180
      canvas.drawCircle(peakPt, 4.0, Paint()..color = const Color(0xFFC0392B));
      canvas.drawCircle(peakPt, 4.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'PEAK',
          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(peakPt.dx - textPainter.width / 2, peakPt.dy - 12));
    }

    // Current circle
    if (scaledPts.isNotEmpty) {
      final currentPt = scaledPts.last;
      canvas.drawCircle(currentPt, 4.0, Paint()..color = const Color(0xFFD4A017));
      canvas.drawCircle(currentPt, 4.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: '3,412',
          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFD4A017)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(currentPt.dx - textPainter.width - 4, currentPt.dy - 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
