// lib/features/india/tools/in_nhb_residex.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INNHBResidex extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INNHBResidex({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INNHBResidex> createState() => _INNHBResidexState();
}

class _INNHBResidexState extends ConsumerState<INNHBResidex> {
  String _selectedCity = 'All India';

  final Map<String, _CityResidexData> _cityData = {
    'All India': _CityResidexData(hpi: 196.3, qoq: 2.1, yoy: 8.4, points: [150.0, 162.0, 171.0, 180.0, 188.0, 196.3], subtitle: 'Composite Base 2017=100'),
    'Mumbai': _CityResidexData(hpi: 218.4, qoq: 2.4, yoy: 11.2, points: [152.0, 161.0, 170.0, 179.0, 195.0, 218.4], subtitle: 'Maharashtra · MMR'),
    'Delhi NCR': _CityResidexData(hpi: 197.6, qoq: 1.8, yoy: 7.9, points: [145.0, 153.0, 160.0, 168.0, 182.0, 197.6], subtitle: 'Delhi / Gurugram'),
    'Bengaluru': _CityResidexData(hpi: 224.7, qoq: 3.1, yoy: 12.8, points: [155.0, 166.0, 178.0, 189.0, 205.0, 224.7], subtitle: 'Karnataka'),
    'Hyderabad': _CityResidexData(hpi: 231.2, qoq: 3.5, yoy: 14.1, points: [160.0, 173.0, 186.0, 198.0, 212.0, 231.2], subtitle: 'Telangana'),
    'Pune': _CityResidexData(hpi: 209.3, qoq: 2.0, yoy: 10.5, points: [146.0, 154.0, 162.0, 171.0, 190.0, 209.3], subtitle: 'Maharashtra'),
    'Chennai': _CityResidexData(hpi: 186.8, qoq: 1.5, yoy: 6.3, points: [142.0, 149.0, 156.0, 163.0, 175.0, 186.8], subtitle: 'Tamil Nadu'),
    'Kolkata': _CityResidexData(hpi: 174.5, qoq: 1.2, yoy: 4.8, points: [138.0, 144.0, 150.0, 156.0, 165.0, 174.5], subtitle: 'West Bengal'),
    'Ahmedabad': _CityResidexData(hpi: 191.2, qoq: 2.1, yoy: 8.1, points: [140.0, 148.0, 157.0, 166.0, 178.0, 191.2], subtitle: 'Gujarat'),
  };

  void _saveSnapshot() async {
    final d = _cityData[_selectedCity]!;
    final labelCtrl = TextEditingController(text: 'NHB Residex - $_selectedCity');

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_nhb_residex'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save HPI Snapshot', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving NHB Residex Snapshot: HPI ${d.hpi} (+${d.yoy}% YoY)',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Q3 2024 Index)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'NHB Residex Snapshot';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'NHB Residex — Property Index',
        inputs: {
          'cityIndex': _cityData.keys.toList().indexOf(_selectedCity).toDouble(),
        },
        results: {
          'hpi': d.hpi,
          'qoqGrowth': d.qoq,
          'yoyGrowth': d.yoy,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Residex snapshot bookmarked successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = _cityData[_selectedCity]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('All-India HPI', '196.3', 'Base 2017=100', isSaffron: true),
              _infoCell('QoQ Growth', '+2.1%', 'Q3 2024', isGreen: true),
              _infoCell('YoY Growth', '+8.4%', 'Annual Trend', isGreen: true),
              _infoCell('Cities Tracked', '50', 'NHB Report'),
            ],
          ),
        ),

        // Hero overview card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: Text(
                    '📊',
                    style: TextStyle(fontSize: 70, color: Colors.white),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NATIONAL HOUSING BANK · RESIDEX HPI',
                      style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text("India's Official Property Index",
                      style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Quarterly price indicators for under-construction and ready homes',
                      style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _hBox('Composite HPI', '196.3', '▲ +8.4% YoY'),
                      const SizedBox(width: 8),
                      _hBox('Residential', '204.1', '▲ +9.2% YoY'),
                      const SizedBox(width: 8),
                      _hBox('Under Const.', '188.7', '▲ +7.6% YoY'),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),

        // City Selector Chips
        Text('Filter Trend by Major City', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: _cityData.keys.map((city) {
              final isSelected = _selectedCity == city;
              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF6B00) : theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : theme.getBorderColor(context), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    city,
                    style: AppTextStyles.dmSans(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: isSelected ? Colors.white : theme.getTextColor(context),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Trend Chart Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📈 HPI Trend Comparison',
                      style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Q1 2022 – Q3 2024',
                        style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF065F46), weight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MultiHpiChartPainter(
                    selectedCity: _selectedCity,
                    cityData: _cityData,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _chartLegendItem('Mumbai', const Color(0xFFFF6B00), isDashed: false),
                  _chartLegendItem('Bengaluru', const Color(0xFF046A38), isDashed: true),
                  _chartLegendItem('Hyderabad', const Color(0xFF0D9488), isDashed: false),
                  _chartLegendItem('Delhi NCR', const Color(0xFF1A3A8F), isDashed: true),
                  if (_selectedCity != 'All India' &&
                      _selectedCity != 'Mumbai' &&
                      _selectedCity != 'Bengaluru' &&
                      _selectedCity != 'Hyderabad' &&
                      _selectedCity != 'Delhi NCR')
                    _chartLegendItem(_selectedCity, Colors.purple, isDashed: false),
                ],
              ),

              const SizedBox(height: 12),
              
              Text(
                'Focus: $_selectedCity (HPI: ${d.hpi.toStringAsFixed(1)}, QoQ: ${d.qoq > 0 ? '+' : ''}${d.qoq}%, YoY: ${d.yoy > 0 ? '+' : ''}${d.yoy}%)',
                style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: const Color(0xFFFF6B00)),
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _saveSnapshot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.bookmark, color: Colors.white, size: 16),
                  label: Text('Save City Index Snapshot', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        // City-Wise HPI Grid
        Text('City-Wise HPI Summary', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: _cityData.entries.where((e) => e.key != 'All India').map((e) {
            final isSelected = _selectedCity == e.key;
            final val = e.value;
            // percentage width for progress indicator
            final double scale = (val.hpi / 231.2).clamp(0.1, 1.0);
            
            return GestureDetector(
              onTap: () => setState(() => _selectedCity = e.key),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF1D2847) : const Color(0xFFEFF6FF)) : theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : theme.getBorderColor(context), width: isSelected ? 1.8 : 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e.key == 'Mumbai' ? '🏙️ Mumbai' :
                      e.key == 'Bengaluru' ? '💻 Bengaluru' :
                      e.key == 'Hyderabad' ? '🏗️ Hyderabad' :
                      e.key == 'Delhi NCR' ? '🏛️ Delhi NCR' :
                      e.key == 'Pune' ? '🌸 Pune' :
                      e.key == 'Chennai' ? '🌊 Chennai' :
                      e.key == 'Kolkata' ? '🎶 Kolkata' :
                      '🌴 Ahmedabad',
                      style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                    ),
                    Text(val.subtitle, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(val.hpi.toStringAsFixed(1), style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w900, color: const Color(0xFFFF6B00))),
                        Text('▲ +${val.yoy}%', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: const Color(0xFF046A38))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Strength bar
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(color: isDark ? Colors.white12 : const Color(0xFFF3E8D0), borderRadius: BorderRadius.circular(2)),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFF5A623)]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Segment Table Card
        Text('Index by Property Segment', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _segRow('🏢', 'Affordable Housing', '< ₹40 Lakh · EWS / LIG', '182.4', '▲ +5.2% YoY'),
              _segRow('🏗️', 'Mid-Segment', '₹40L – ₹1.5Cr · MIG', '198.7', '▲ +9.3% YoY'),
              _segRow('🏰', 'Premium Segment', '₹1.5Cr – ₹4Cr', '214.3', '▲ +13.1% YoY'),
              _segRow('✨', 'Luxury Segment', '> ₹4 Crore', '236.9', '▲ +17.4% YoY'),
            ],
          ),
        ),

        // Quarterly comparison table
        Text('Quarterly HPI Table', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1F48),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('City', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.white))),
                    Expanded(flex: 2, child: Text("Q1 '24", style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("Q2 '24", style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("Q3 '24", style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              _qtRow('Mumbai', '206.8', '212.4', '218.4', isHigh: true),
              _qtRow('Bengaluru', '211.3', '217.9', '224.7', isHigh: true),
              _qtRow('Hyderabad', '216.5', '223.8', '231.2', isHigh: true),
              _qtRow('Delhi NCR', '188.4', '193.1', '197.6'),
              _qtRow('Pune', '197.6', '203.4', '209.3'),
              _qtRow('Chennai', '179.2', '182.9', '186.8', isLow: true),
              _qtRow('Kolkata', '168.7', '171.4', '174.5', isLow: true),
            ],
          ),
        ),

        // Market Insights
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C2A1C) : const Color(0xFFECFDF5),
            border: Border.all(color: isDark ? const Color(0xFF0F5A3B) : const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('NHB Residex Insights — Q3 2024',
                      style: AppTextStyles.dmSans(size: 12, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A), weight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              _insightBullet('Hyderabad leads all metros with 14.1% YoY appreciation, driven by IT sector demand in Gachibowli & HITEC City.'),
              _insightBullet('Luxury segment (>₹4Cr) surged 17.4% — highest across all categories; demand for gated communities continues.'),
              _insightBullet('Affordable housing in Tier-2 cities (Nagpur, Jaipur, Surat) gained momentum with PMAY push.'),
              _insightBullet('All-India HPI at 196.3 — up 8.4% annually, above CPI inflation of 5.1%, creating real positive returns.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    }
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _hBox(String label, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(val, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 1),
            Text(sub, style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFF86EFAC), weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _chartLegendItem(String label, Color color, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(1),
          ),
          child: isDashed
              ? Row(
                  children: [
                    Container(width: 4, height: 3, color: color),
                    const Spacer(),
                    Container(width: 4, height: 3, color: color),
                  ],
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getTextColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _segRow(String emoji, String title, String subtitle, String val, String yoy) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFFF6B00).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                Text(subtitle, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w900, color: theme.getTextColor(context))),
              Text(yoy, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: const Color(0xFF046A38))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtRow(String city, String q1, String q2, String q3, {bool isHigh = false, bool isLow = false}) {
    final theme = widget.theme;
    Color q3Color = theme.getTextColor(context);
    if (isHigh) {
      q3Color = const Color(0xFF046A38);
    } else if (isLow) {
      q3Color = const Color(0xFFE05A00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(city, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)))),
          Expanded(flex: 2, child: Text(q1, style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.w500), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(q2, style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.w500), textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Text(
              q3,
              style: AppTextStyles.dmSans(size: 11, color: q3Color, weight: (isHigh || isLow) ? FontWeight.w900 : FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightBullet(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('▸', style: TextStyle(color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF046A38), fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF07543A), height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _CityResidexData {
  final double hpi;
  final double qoq;
  final double yoy;
  final List<double> points;
  final String subtitle;

  _CityResidexData({required this.hpi, required this.qoq, required this.yoy, required this.points, required this.subtitle});
}

class _MultiHpiChartPainter extends CustomPainter {
  final String selectedCity;
  final Map<String, _CityResidexData> cityData;
  final bool isDark;

  _MultiHpiChartPainter({required this.selectedCity, required this.cityData, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3E8D0)
      ..strokeWidth = 1;

    const double paddingLeft = 32;
    const double paddingRight = 12;
    const double paddingTop = 12;
    const double paddingBottom = 22;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    // Draw horizontal grid lines
    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = paddingTop + (height / gridLines) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Graph limits
    const double minVal = 130.0;
    const double maxVal = 240.0;
    const double valRange = maxVal - minVal;

    // Define X coordinate step (6 points from Q1'22 to Q3'24)
    final double stepX = width / 5.0;

    // Helper to draw a single city line
    void drawCityLine(String city, Color color, bool isDashed, bool isFocused) {
      final data = cityData[city];
      if (data == null) return;
      final points = data.points;

      final path = Path();
      final fillPath = Path();
      fillPath.moveTo(paddingLeft, paddingTop + height);

      for (int i = 0; i < points.length; i++) {
        final x = paddingLeft + i * stepX;
        final val = points[i];
        final y = paddingTop + height - ((val - minVal) / valRange) * height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        fillPath.lineTo(x, y);
      }
      fillPath.lineTo(paddingLeft + width, paddingTop + height);
      fillPath.close();

      // If focused, draw area gradient under it
      if (isFocused) {
        final fillPaint = Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, size.height - paddingBottom))
          ..style = PaintingStyle.fill;
        canvas.drawPath(fillPath, fillPaint);
      }

      // Draw stroke
      final linePaint = Paint()
        ..color = isFocused ? color : color.withValues(alpha: 0.3)
        ..strokeWidth = isFocused ? 3.0 : 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isDashed) {
        // Draw dashed path
        const double dashWidth = 5.0;
        const double dashSpace = 3.0;
        
        final pathMetrics = path.computeMetrics();
        for (var metric in pathMetrics) {
          double distance = 0.0;
          bool draw = true;
          while (distance < metric.length) {
            final double len = draw ? dashWidth : dashSpace;
            final double nextDistance = (distance + len).clamp(0.0, metric.length);
            if (draw) {
              final segmentPath = metric.extractPath(distance, nextDistance);
              canvas.drawPath(segmentPath, linePaint);
            }
            distance = nextDistance;
            draw = !draw;
          }
        }
      } else {
        canvas.drawPath(path, linePaint);
      }

      // Draw dot on the last point
      if (points.isNotEmpty) {
        final double finalX = paddingLeft + (points.length - 1) * stepX;
        final double finalY = paddingTop + height - ((points.last - minVal) / valRange) * height;

        final dotPaint = Paint()..color = isFocused ? color : color.withValues(alpha: 0.5);
        final borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(Offset(finalX, finalY), isFocused ? 4.5 : 3.0, dotPaint);
        canvas.drawCircle(Offset(finalX, finalY), isFocused ? 4.5 : 3.0, borderPaint);
      }
    }

    // Draw background lines first
    final backgroundCities = ['Mumbai', 'Bengaluru', 'Hyderabad', 'Delhi NCR'];
    for (var city in backgroundCities) {
      if (city != selectedCity) {
        bool isDashed = city == 'Bengaluru' || city == 'Delhi NCR';
        Color col = city == 'Mumbai' ? const Color(0xFFFF6B00) :
                    city == 'Bengaluru' ? const Color(0xFF046A38) :
                    city == 'Hyderabad' ? const Color(0xFF0D9488) :
                    const Color(0xFF1A3A8F);
        drawCityLine(city, col, isDashed, false);
      }
    }

    // Draw selected city line on top
    if (selectedCity == 'All India') {
      drawCityLine('All India', const Color(0xFFFF6B00), false, true);
    } else {
      bool isDashed = selectedCity == 'Bengaluru' || selectedCity == 'Delhi NCR';
      Color col = selectedCity == 'Mumbai' ? const Color(0xFFFF6B00) :
                  selectedCity == 'Bengaluru' ? const Color(0xFF046A38) :
                  selectedCity == 'Hyderabad' ? const Color(0xFF0D9488) :
                  selectedCity == 'Delhi NCR' ? const Color(0xFF1A3A8F) :
                  Colors.purple;
      drawCityLine(selectedCity, col, isDashed, true);
    }

    // Draw custom axis labels text manually
    final labelStyle = AppTextStyles.dmSans(size: 8, color: const Color(0xFF7A5C3A), weight: FontWeight.w600);
    
    // Y labels
    final double stepY = height / gridLines;
    const List<String> yLabels = ['240', '212', '185', '157', '130'];
    for (int i = 0; i <= gridLines; i++) {
      final y = paddingTop + stepY * i;
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - tp.height / 2));
    }

    // X labels
    const List<String> xLabels = ["Q1'22", "Q3'22", "Q1'23", "Q3'23", "Q1'24", "Q3'24"];
    for (int i = 0; i < xLabels.length; i++) {
      final x = paddingLeft + i * stepX;
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, paddingTop + height + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _MultiHpiChartPainter oldDelegate) =>
      oldDelegate.selectedCity != selectedCity || oldDelegate.isDark != isDark;
}
