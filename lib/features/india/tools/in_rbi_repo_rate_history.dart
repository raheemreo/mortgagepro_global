// lib/features/india/tools/in_rbi_repo_rate_history.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INRBIRepoRateHistory extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INRBIRepoRateHistory({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INRBIRepoRateHistory> createState() => _INRBIRepoRateHistoryState();
}

class _INRBIRepoRateHistoryState extends ConsumerState<INRBIRepoRateHistory> {
  final List<Map<String, dynamic>> _timelineData = const [
    {'date': 'Mar\n20', 'val': 4.40, 'type': 'cut'},
    {'date': 'May\n20', 'val': 4.00, 'type': 'cut'},
    {'date': 'May\n22', 'val': 4.40, 'type': 'hike'},
    {'date': 'Jun\n22', 'val': 4.90, 'type': 'hike'},
    {'date': 'Aug\n22', 'val': 5.40, 'type': 'hike'},
    {'date': 'Sep\n22', 'val': 5.90, 'type': 'hike'},
    {'date': 'Dec\n22', 'val': 6.25, 'type': 'hike'},
    {'date': 'Feb\n23', 'val': 6.50, 'type': 'hike'},
    {'date': 'Apr\n23', 'val': 6.50, 'type': 'hold'},
    {'date': 'Jun\n23', 'val': 6.50, 'type': 'hold'},
    {'date': 'Aug\n23', 'val': 6.50, 'type': 'hold'},
    {'date': 'Oct\n23', 'val': 6.50, 'type': 'hold'},
    {'date': 'Dec\n23', 'val': 6.50, 'type': 'hold'},
    {'date': 'Feb\n24', 'val': 6.50, 'type': 'hold'},
    {'date': 'Jun\n24', 'val': 6.50, 'type': 'hold'},
    {'date': 'Feb\n25', 'val': 6.25, 'type': 'cut'},
    {'date': 'Apr\n25', 'val': 6.25, 'type': 'cut'},
  ];

  final List<Map<String, dynamic>> _mpcDecisions = const [
    {'date': 'Apr 9, 2025', 'rate': '6.25%', 'action': '−25 bps', 'type': 'cut', 'eff': 'Immediate'},
    {'date': 'Feb 7, 2025', 'rate': '6.25%', 'action': '−25 bps', 'type': 'cut', 'eff': 'Feb 8, 2025'},
    {'date': 'Dec 6, 2024', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Oct 9, 2024', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Aug 8, 2024', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Jun 7, 2024', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Apr 5, 2024', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Feb 8, 2024', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Dec 8, 2023', 'rate': '6.50%', 'action': 'Hold', 'type': 'hold', 'eff': 'Unchanged'},
    {'date': 'Feb 8, 2023', 'rate': '6.50%', 'action': '+25 bps', 'type': 'hike', 'eff': 'Feb 9, 2023'},
    {'date': 'Dec 7, 2022', 'rate': '6.25%', 'action': '+35 bps', 'type': 'hike', 'eff': 'Dec 8, 2022'},
    {'date': 'May 4, 2022', 'rate': '4.40%', 'action': '+40 bps', 'type': 'hike', 'eff': 'May 5, 2022'},
  ];

  int? _hoveredBarIndex;

  void _saveCalculation() async {
    final labelCtrl = TextEditingController(text: 'RBI Repo Rate Snapshot');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Rate Snapshot', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving RBI policy repo rate details: 6.25% (Accommodative)',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. RBI Rate Apr 2025)',
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
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'RBI Repo Rate Snapshot';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'RBI Repo Rate History',
        inputs: {
          'repoRate': 6.25,
          'sdfRate': 6.00,
          'msfRate': 6.50,
          'crr': 4.00,
          'slr': 18.00,
        },
        results: {
          'currentRate': 6.25,
          'stanceIndex': 1.0,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ RBI rate snapshot saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
              _infoCell('Current Rate', '6.25%', 'Apr 2025', isSaffron: true),
              _infoCell('Change', '−0.25%', 'Rate Cut', isGreen: true),
              _infoCell('SDF Rate', '6.00%', 'Corridor'),
              _infoCell('Next MPC', 'Jun 25', '2025', isSaffron: true),
            ],
          ),
        ),

        // Live card
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
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.06,
                  child: Text(
                    '☸',
                    style: AppTextStyles.dmSans(size: 80, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RBI MONETARY POLICY COMMITTEE · भारतीय रिज़र्व बैंक',
                      style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('6.25%',
                          style: AppTextStyles.playfair(size: 48, color: const Color(0xFFFFDEA0), weight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Repo Rate · Apr 2025',
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                            Text('↓ Cut by 25 bps',
                                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF86EFAC))),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.8,
                    children: [
                      _lcBox('MSF Rate', '6.50%'),
                      _lcBox('SDF Rate', '6.00%'),
                      _lcBox('CRR', '4.00%'),
                      _lcBox('SLR', '18.00%'),
                      _lcBox('Bank Rate', '6.50%'),
                      _lcBox('Stance', 'Accommodative', isStance: true),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),

        // Rate Movement (2020–2025)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rate Movement (2020–2025)', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162544) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('25 Decisions', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF1D4ED8), weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              Text('RBI Repo Rate Timeline', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('Bar height = rate level · Color = action taken by MPC', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 18),
              
              // Non-scrolling, responsive Row of all 17 decisions
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_timelineData.length, (index) {
                    final d = _timelineData[index];
                    final double val = d['val'] as double;
                    final String type = d['type'] as String;
                    const minRate = 3.8;
                    const maxRate = 7.0;
                    final double pct = ((val - minRate) / (maxRate - minRate)).clamp(0.05, 1.0);

                    Color barColor = const Color(0xFF1A3A8F);
                    if (type == 'hike') {
                      barColor = const Color(0xFFFF6B00);
                    } else if (type == 'cut') {
                      barColor = const Color(0xFF046A38);
                    }

                    final isHovered = _hoveredBarIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _hoveredBarIndex = index),
                        onTapUp: (_) => setState(() => _hoveredBarIndex = null),
                        onTapCancel: () => setState(() => _hoveredBarIndex = null),
                        child: Container(
                          color: Colors.transparent, // expand hit test area
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Tooltip value
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${val.toStringAsFixed(2)}%',
                                  style: AppTextStyles.dmSans(
                                    size: isHovered ? 8 : 6.5,
                                    weight: FontWeight.w800,
                                    color: isHovered ? const Color(0xFFFF6B00) : theme.getTextColor(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Bar
                              Expanded(
                                child: FractionallySizedBox(
                                  heightFactor: pct,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      boxShadow: isHovered
                                          ? [BoxShadow(color: barColor.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Label
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  d['date'] as String,
                                  style: AppTextStyles.dmSans(
                                    size: 6,
                                    color: theme.getMutedColor(context),
                                    weight: isHovered ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(const Color(0xFFFF6B00), 'Rate Hike'),
                  const SizedBox(width: 14),
                  _legendDot(const Color(0xFF046A38), 'Rate Cut'),
                  const SizedBox(width: 14),
                  _legendDot(const Color(0xFF1A3A8F), 'Hold'),
                ],
              ),
            ],
          ),
        ),

        // Historical Rate Trend (2010-2025)
        Text('Historical Rate Trend (2010–2025)', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
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
              Text('Historical Rate Trend Line', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('MPC decisions plotted over 15 years', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RepoRateLinePainter(isDark: isDark),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2010', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                  Text('2013', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                  Text('2016', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                  Text('2019', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                  Text('2022', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                  Text('2025', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Range: 4.00% – 8.50%', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w700)),
              )
            ],
          ),
        ),

        // Context indicators
        Text('Rate Context Indicators', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _ctxCard('📊', 'CPI Inflation', '4.83%', 'Apr 2025 · Target 4%', isSaffron: true),
            _ctxCard('📈', 'GDP Growth', '7.6%', 'FY2025 Estimate', isGreen: true),
            _ctxCard('💵', 'USD/INR', '84.20', 'Jun 2025', isSaffron: false),
            _ctxCard('🏦', '10-Yr G-Sec', '6.85%', 'Bond Yield', isSaffron: false),
          ],
        ),

        const SizedBox(height: 20),

        // MPC decisions history table
        Text('MPC Decisions — Recent History', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1F48),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monetary Policy Committee Decisions',
                        style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: Colors.white)),
                    Text('Last 12 decisions',
                        style: AppTextStyles.dmSans(size: 9, color: Colors.white38, weight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('MEETING DATE', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context)))),
                    Expanded(flex: 1, child: Text('RATE', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context)))),
                    Expanded(flex: 1, child: Text('ACTION', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context)))),
                    Expanded(flex: 1, child: Text('EFFECT', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context)))),
                  ],
                ),
              ),
              ..._mpcDecisions.map((d) {
                final String actType = d['type'] as String;
                Color actionBg = const Color(0xFFEFF6FF);
                Color actionText = const Color(0xFF1D4ED8);
                if (actType == 'cut') {
                  actionBg = const Color(0xFFECFDF5);
                  actionText = const Color(0xFF065F46);
                } else if (actType == 'hike') {
                  actionBg = const Color(0xFFFEF2F2);
                  actionText = const Color(0xFFB91C1C);
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(d['date'] as String, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.getTextColor(context)))),
                      Expanded(flex: 1, child: Text(d['rate'] as String, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: const Color(0xFFFF6B00)))),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: actionBg, borderRadius: BorderRadius.circular(10)),
                            child: Text(d['action'] as String, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: actionText)),
                          ),
                        ),
                      ),
                      Expanded(flex: 1, child: Text(d['eff'] as String, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Impact on ₹50L Home Loan (20 yr)
        Text('Impact on ₹50L Home Loan (20 yr)', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
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
              Text('How Rate Changes Affect Your EMI', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              _impactRow('At 6.50% (Peak 2024)', '₹44,300/mo', 'Higher EMI', isRed: true),
              _impactRow('At 6.25% (Apr 2025)', '₹43,700/mo', 'Save ₹600/mo', isGreen: true),
              _impactRow('At 5.75% (Projected)', '₹42,200/mo', 'Save ₹2,100/mo', isGreen: true),
              _impactRow('COVID Low (4.00%)', '₹37,100/mo', 'Lowest in history', isGreen: true),
            ],
          ),
        ),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C2A1C) : const Color(0xFFECFDF5),
            border: Border.all(color: isDark ? const Color(0xFF0F5A3B) : const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📌 How Repo Rate affects Home Loans', 
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A))),
              const SizedBox(height: 6),
              Text(
                "RBI's Repo Rate is the rate at which commercial banks borrow from RBI. When the repo rate falls, banks typically reduce their EBLR (External Benchmark Lending Rate), directly reducing your floating home loan EMI within 3 months. All new home loans since Oct 2019 are linked to an external benchmark (usually repo rate + spread). A 25 bps repo cut saves approx ₹600–₹800/month on a ₹50L 20-year loan.",
                style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38), height: 1.5),
              ),
            ],
          ),
        ),

        // Save Snapshot Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _saveCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.save, color: Colors.white, size: 16),
            label: Text('Save Policy Snapshot', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800)),
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
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
      ],
    );
  }

  Widget _lcBox(String label, String val, {bool isStance = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: isStance ? 9.5 : 12,
                  weight: FontWeight.w800,
                  color: isStance ? const Color(0xFFFFDEA0) : Colors.white)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context), weight: FontWeight.w600)),
      ],
    );
  }

  Widget _ctxCard(String emoji, String label, String value, String note, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = widget.theme.getTextColor(context);
    if (isSaffron) {
      valColor = const Color(0xFFFF6B00);
    } else if (isGreen) {
      valColor = const Color(0xFF046A38);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w800)),
          Text(value, style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: valColor)),
          Text(note, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _impactRow(String label, String emi, String desc, {bool isRed = false, bool isGreen = false}) {
    Color descColor = Colors.grey;
    if (isRed) {
      descColor = const Color(0xFFB91C1C);
    } else if (isGreen) {
      descColor = const Color(0xFF046A38);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: widget.theme.getBorderColor(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
              const SizedBox(height: 2),
              Text('Repo: ${label.contains('6.50') ? '6.50%' : label.contains('6.25') ? '6.25%' : label.contains('5.75') ? '5.75%' : '4.00%'}',
                  style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(emi, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFFFF6B00))),
              Text(desc, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: descColor)),
            ],
          )
        ],
      ),
    );
  }
}

class _RepoRateLinePainter extends CustomPainter {
  final bool isDark;
  const _RepoRateLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFFF6B00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF6B00).withValues(alpha: 0.25),
          const Color(0xFFFF6B00).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final paintGridDash = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFF0B1F48).withValues(alpha: 0.07)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw reference lines
    canvas.drawLine(const Offset(0, 15), Offset(size.width, 15), paintGridDash);
    canvas.drawLine(const Offset(0, 50), Offset(size.width, 50), paintGridDash);
    canvas.drawLine(const Offset(0, 85), Offset(size.width, 85), paintGridDash);

    // Points mapped from HTML SVG path
    const List<Offset> points = [
      Offset(0, 42),
      Offset(18, 36),
      Offset(36, 30),
      Offset(54, 22),
      Offset(72, 14),
      Offset(90, 18),
      Offset(108, 28),
      Offset(126, 48),
      Offset(144, 68),
      Offset(162, 72),
      Offset(180, 72),
      Offset(198, 60),
      Offset(216, 48),
      Offset(234, 40),
      Offset(252, 35),
      Offset(270, 38),
      Offset(288, 38),
      Offset(306, 35),
      Offset(324, 35),
      Offset(342, 40),
      Offset(360, 42),
    ];

    // Scale points to actual Canvas size
    final double scaleX = size.width / 360.0;
    final double scaleY = size.height / 100.0;

    final pathLine = Path();
    final pathFill = Path();

    for (int i = 0; i < points.length; i++) {
      final double x = points[i].dx * scaleX;
      final double y = points[i].dy * scaleY;
      if (i == 0) {
        pathLine.moveTo(x, y);
        pathFill.moveTo(x, y);
      } else {
        pathLine.lineTo(x, y);
        pathFill.lineTo(x, y);
      }
    }

    pathFill.lineTo(size.width, size.height);
    pathFill.lineTo(0, size.height);
    pathFill.close();

    canvas.drawPath(pathFill, paintFill);
    canvas.drawPath(pathLine, paintLine);

    // Draw key events dots
    final paintDotOuter = Paint()..color = Colors.white;
    final paintDotSaffron = Paint()..color = const Color(0xFFFF6B00);
    final paintDotGreen = Paint()..color = const Color(0xFF046A38);

    // Key event 1 (2012 Peak)
    final Offset p1 = Offset(72 * scaleX, 14 * scaleY);
    canvas.drawCircle(p1, 5, paintDotOuter);
    canvas.drawCircle(p1, 3.5, paintDotSaffron);

    // Key event 2 (COVID Low)
    final Offset p2 = Offset(162 * scaleX, 72 * scaleY);
    canvas.drawCircle(p2, 5, paintDotOuter);
    canvas.drawCircle(p2, 3.5, paintDotGreen);

    // Key event 3 (Current)
    final Offset p3 = Offset(360 * scaleX, 42 * scaleY);
    canvas.drawCircle(p3, 5, paintDotOuter);
    canvas.drawCircle(p3, 3.5, paintDotSaffron);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
