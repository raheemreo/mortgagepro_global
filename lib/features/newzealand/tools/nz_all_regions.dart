// lib/features/newzealand/tools/nz_all_regions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZAllRegions extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZAllRegions({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZAllRegions> createState() => _NZAllRegionsState();
}

class _NZAllRegionsState extends ConsumerState<NZAllRegions> {
  String _activeFilter = 'All'; // 'All', 'North Island', 'South Island', 'Rising ↑', 'Falling ↓'

  final List<RegionData> _regions = [
    RegionData('Auckland', 'Metro · Largest city', 950000, -1.2, 3102, 'North Island', '🏙️'),
    RegionData('Queenstown', 'Otago Lakes · Luxury', 900000, 1.4, 188, 'South Island', '💎'),
    RegionData('Tauranga', 'Bay of Plenty', 785000, -0.8, 412, 'North Island', '🌿'),
    RegionData('Wellington', 'Capital Region', 720000, -6.8, 618, 'North Island', '🌊'),
    RegionData('Hamilton', 'Waikato', 650000, 0.5, 389, 'North Island', '🌺'),
    RegionData('Napier/HB', 'Hawke\'s Bay', 640000, -2.9, 231, 'North Island', '🌞'),
    RegionData('Nelson', 'Nelson-Tasman', 625000, 1.1, 198, 'South Island', '🌊'),
    RegionData('Christchurch', 'Canterbury', 610000, 1.8, 1104, 'South Island', '🏔️'),
    RegionData('Whangarei', 'Northland', 555000, -1.9, 142, 'North Island', '🌿'),
    RegionData('Palmerston N.', 'Manawatū', 545000, -3.4, 178, 'North Island', '🌿'),
    RegionData('Dunedin', 'Otago', 520000, 2.1, 312, 'South Island', '🍇'),
    RegionData('Rotorua', 'Bay of Plenty', 500000, 0.9, 143, 'North Island', '🌲'),
    RegionData('Gisborne', 'East Coast', 450000, -1.7, 82, 'North Island', '🌱'),
    RegionData('New Plymouth', 'Taranaki', 445000, 0.4, 118, 'North Island', '🌋'),
    RegionData('Whanganui', 'Manawatū-Whanganui', 425000, -2.2, 89, 'North Island', '🏝️'),
    RegionData('Invercargill', 'Southland', 420000, 3.2, 156, 'South Island', '🦅'),
  ];

  List<RegionData> get _filteredRegions {
    switch (_activeFilter) {
      case 'North Island':
        return _regions.where((r) => r.island == 'North Island').toList();
      case 'South Island':
        return _regions.where((r) => r.island == 'South Island').toList();
      case 'Rising ↑':
        return _regions.where((r) => r.change > 0).toList();
      case 'Falling ↓':
        return _regions.where((r) => r.change < 0).toList();
      default:
        return _regions;
    }
  }

  void _saveSnapshot() async {
    final results = {
      'NZ Median': 730000.0,
      'Auckland Median': 950000.0,
      'Wellington Median': 720000.0,
      'Christchurch Median': 610000.0,
    };
    final inputs = {
      'Filtered Count': _filteredRegions.length.toDouble(),
    };

    final labelCtrl = TextEditingController(text: 'NZ Regional Prices');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Price Snapshot',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'National Median: NZ\$730,000 · View: $_activeFilter',
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
                hintText: 'Label (e.g. June 2025 REINZ Data)',
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
        calcType: 'All Regions',
        inputs: inputs,
        results: results,
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${labelCtrl.text}" Snapshot successfully!'),
            backgroundColor: widget.theme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);
    final borderCol = theme.getBorderColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // National Median Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 REINZ HOUSE PRICE INDEX · NZ NATIONAL',
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: Colors.white70,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'NZ\$730,000',
                  style: AppTextStyles.playfair(
                    size: 38,
                    weight: FontWeight.w800,
                    color: const Color(0xFFF5D060),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'National median sale price · ↓ -2.1% annual · REINZ May 2025',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PEAK (NOV 2021)', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text('\$925K', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FROM PEAK', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text('-21.1%', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: const Color(0xFFFCA5A5))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SOURCE', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
                            const SizedBox(height: 2),
                            Text('REINZ HPI', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sort & Filter
          Text('FILTER REGIONS', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'North Island', 'South Island', 'Rising ↑', 'Falling ↓'].map((f) {
                final active = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: active,
                    selectedColor: const Color(0xFF0D3B2E),
                    labelStyle: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: active ? Colors.white : textCol,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _activeFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Performers
          Text('BEST & WORST — ANNUAL CHANGE', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)]),
              border: Border.all(color: const Color(0xFFA7F3D0)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Southland — Top Performer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                      Text('Invercargill · Strong regional demand', style: TextStyle(fontSize: 9.5, color: Color(0xFF059669))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('+3.2%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                    Text('Median \$420K', style: TextStyle(fontSize: 10, color: Color(0xFF065F46))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFECACA)]),
              border: Border.all(color: const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Text('📉', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wellington — Biggest Drop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                      Text('Capital region · Affordability correction', style: TextStyle(fontSize: 9.5, color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('–6.8%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFC0392B))),
                    Text('Median \$720K', style: TextStyle(fontSize: 10, color: Color(0xFF991B1B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save price Snapshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save Price Snapshot', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: Colors.white)),
                      Text('National median: NZ\$730,000 snapshot', style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveSnapshot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5D060),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Save', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart comparison card
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
                    Text('Median Price by Region', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                    Text('REINZ May 2025', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: theme.primaryColor)),
                  ],
                ),
                Text('Sorted by median sale price · NZD thousands', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                const SizedBox(height: 14),
                ..._regions.take(9).map((reg) {
                  const double maxForScale = 1000000;
                  final double pct = (reg.price / maxForScale).clamp(0.0, 1.0);
                  final isNegative = reg.change < 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(reg.name, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: textCol)),
                        ),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: Text(
                            'K\$${(reg.price / 1000).toInt()}',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: textCol),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${isNegative ? "" : "+"}${reg.change.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.dmSans(
                              size: 9,
                              weight: FontWeight.bold,
                              color: isNegative ? const Color(0xFFC0392B) : const Color(0xFF15803D),
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
          const SizedBox(height: 16),

          // Affordability Snapshot box
          Text('AFFORDABILITY SNAPSHOT', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚡ NZ Median Affordability — Jun 2025', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF92400E))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildAffBox('Price-to-Income', '8.4×', 'NZ median')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAffBox('Auckland P/I', '11.2×', 'Least affordable')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAffBox('Southland P/I', '4.8×', 'Most affordable')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // All 16 Regions card grid
          Text('ALL 16 NZ REGIONS', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredRegions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final reg = _filteredRegions[index];
              final isNegative = reg.change < 0;
              const double maxVal = 1000000;
              final double barFill = (reg.price / maxVal).clamp(0.0, 1.0);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(reg.emoji, style: const TextStyle(fontSize: 20)),
                        Text(reg.island.replaceAll(' Island', ''), style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reg.name, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textCol), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(reg.sub, style: AppTextStyles.dmSans(size: 8, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.compact(reg.price, symbol: 'NZ\$'),
                      style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: theme.primaryColor),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${isNegative ? "↓" : "↑"} ${isNegative ? "" : "+"}${reg.change.toStringAsFixed(1)}%',
                          style: AppTextStyles.dmSans(
                            size: 9.5,
                            weight: FontWeight.bold,
                            color: isNegative ? const Color(0xFFC0392B) : const Color(0xFF15803D),
                          ),
                        ),
                        Text('${reg.sales} sales', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                      ],
                    ),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: barFill,
                        child: Container(decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAffBox(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFF92400E), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFF78350F))),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF92400E))),
        ],
      ),
    );
  }
}

class RegionData {
  final String name;
  final String sub;
  final double price;
  final double change;
  final int sales;
  final String island;
  final String emoji;

  RegionData(this.name, this.sub, this.price, this.change, this.sales, this.island, this.emoji);
}
