// lib/features/newzealand/tools/nz_ocr_history.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZOCRHistory extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZOCRHistory({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZOCRHistory> createState() => _NZOCRHistoryState();
}

class _NZOCRHistoryState extends ConsumerState<NZOCRHistory> {
  String _selectedPeriod = '2yr'; // '2yr', '5yr', 'all'

  // Decisions list from HTML
  final List<Map<String, dynamic>> _decisions = [
    {
      'date': '9 Apr 2025',
      'note': 'Statement issued',
      'rate': '3.75%',
      'change': '−0.25%',
      'type': 'cut', // cut, hike, hold
    },
    {
      'date': '19 Feb 2025',
      'note': 'MPS released',
      'rate': '4.00%',
      'change': '−0.50%',
      'type': 'cut',
    },
    {
      'date': '27 Nov 2024',
      'note': 'MPS released',
      'rate': '4.50%',
      'change': '−0.50%',
      'type': 'cut',
    },
    {
      'date': '9 Oct 2024',
      'note': 'Statement',
      'rate': '4.75%',
      'change': '−0.50%',
      'type': 'cut',
    },
    {
      'date': '14 Aug 2024',
      'note': 'MPS – first cut',
      'rate': '5.25%',
      'change': '−0.25%',
      'type': 'cut',
    },
    {
      'date': 'May 2023',
      'note': 'Peak reached',
      'rate': '5.50%',
      'change': '+0.25%',
      'type': 'hike',
    },
  ];

  void _saveSnapshot() async {
    final labelCtrl = TextEditingController(text: 'NZ OCR Snapshot');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Snapshot',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current OCR: 3.75% · Cuts since peak: -1.75%',
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
                hintText: 'Label (e.g. April 2025 OCR Update)',
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
        calcType: 'OCR History',
        inputs: {
          'currentOcr': 3.75,
          'peakOcr': 5.50,
          'cutsSincePeak': 1.75,
        },
        results: {
          'ocr': 3.75,
        },
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ OCR Snapshot saved to profile!'),
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
        // Header info strip
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
              _buildStripItem('Current OCR', '3.75%', 'Apr 2025', const Color(0xFFF5D060)),
              _buildStripItem('Peak OCR', '5.50%', 'May-Aug \'23', const Color(0xFFFCA5A5)),
              _buildStripItem('1-Yr Fixed', '5.99%', 'Avg Lenders', Colors.white),
              _buildStripItem('Next MPC', 'May 28', '2025', const Color(0xFF6EE7B7)),
            ],
          ),
        ),

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Official Cash Rate',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'RBNZ Live →',
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

        // Current OCR Hero
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
                'RESERVE BANK OF NEW ZEALAND · TE PŪTEA MATUA · OCR',
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white60,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '3.75',
                    style: AppTextStyles.playfair(
                      size: 52,
                      weight: FontWeight.w800,
                      color: const Color(0xFFF5D060),
                    ),
                  ),
                  Text(
                    '%',
                    style: AppTextStyles.playfair(
                      size: 24,
                      weight: FontWeight.bold,
                      color: const Color(0xFFF5D060),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Effective 9 April 2025 · Cut −0.25% from 4.00%',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _buildHeroStat('Peak (Aug 2023)', '5.50%', const Color(0xFFFCA5A5))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeroStat('Cut Since Peak', '−1.75%', const Color(0xFF6EE7B7))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeroStat('Next MPC', '28 May \'25', const Color(0xFFF5D060))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Chart Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OCR History 2021–2025',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Full Data →',
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
                    'RBNZ Official Cash Rate Timeline',
                    style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
                  ),
                  Text(
                    '● Updated Apr 2025',
                    style: AppTextStyles.dmSans(size: 9.5, color: theme.primaryColor, weight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Chart period tabs
              Row(
                children: [
                  Expanded(child: _buildTabButton('2 Years', '2yr')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabButton('5 Years', '5yr')),
                  const SizedBox(width: 6),
                  Expanded(child: _buildTabButton('Since 1999', 'all')),
                ],
              ),
              const SizedBox(height: 16),

              // SVG chart replica
              AspectRatio(
                aspectRatio: 360 / 160,
                child: CustomPaint(
                  painter: _OCRHistoryPainter(
                    period: _selectedPeriod,
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Jun '22", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text("Dec '22", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text("Jun '23", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text("Dec '23", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text("Jun '24", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text("Dec '24", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                  Text("Apr '25", style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent MPC Decisions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent MPC Decisions',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'All →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Decisions Table Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Date', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol))),
                    Expanded(flex: 2, child: Text('OCR', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Change', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Decision', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const Divider(),
              // Rows
              ..._decisions.map((d) {
                final isCut = d['type'] == 'cut';
                final isHike = d['type'] == 'hike';
                final badgeColor = isCut
                    ? const Color(0xFFECFDF5)
                    : (isHike ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9));
                final badgeTextCol = isCut
                    ? const Color(0xFF065F46)
                    : (isHike ? const Color(0xFFB91C1C) : const Color(0xFF475569));

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['date'], style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: textCol)),
                            Text(d['note'], style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          d['rate'],
                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.primaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          d['change'],
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: isCut ? theme.primaryColor : (isHike ? const Color(0xFFC0392B) : mutedCol),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              d['type'].toUpperCase(),
                              style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: badgeTextCol),
                            ),
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
        const SizedBox(height: 20),

        // Forecast section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OCR Forecast 2025–2026',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'RBNZ MPS →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Forecast Timeline Card
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
                '📈 Market-Implied OCR Path (May 2025)',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(height: 2),
              Text(
                'Based on OIS pricing & RBNZ February 2025 MPS projections',
                style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF0D9488)),
              ),
              const SizedBox(height: 14),

              // Timeline Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildForecastItem('3.75%', 'Apr 2025', 'Now', isCurrent: true),
                    _buildArrowIndicator(),
                    _buildForecastItem('3.50%', 'May 2025', '71% cut'),
                    _buildArrowIndicator(),
                    _buildForecastItem('3.25%', 'Jul 2025', '60% likely'),
                    _buildArrowIndicator(),
                    _buildForecastItem('3.00%', 'Oct 2025', 'Forecast'),
                    _buildArrowIndicator(),
                    _buildForecastItem('3.00%', '2026', 'Neutral'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // How OCR Moves Affect Your Mortgage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'How OCR Moves Affect Your Mortgage',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Calculator →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Impact Card
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
              Text(
                '💰 If OCR cuts another 0.75% (to 3.00%)',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 14),

              _buildImpactRow(
                icon: '🏠',
                title: '1-Yr Fixed Rate (Est.)',
                sub: 'May fall from 5.99% → ~5.25%',
                widthPct: 0.72,
                color: theme.primaryColor,
                val: '−0.74%',
              ),
              const SizedBox(height: 12),
              _buildImpactRow(
                icon: '📅',
                title: 'Monthly Saving (NZ\$700K loan)',
                sub: 'Based on 30-year P&I mortgage',
                widthPct: 0.60,
                color: const Color(0xFF0D9488),
                val: '~\$325/mo',
              ),
              const SizedBox(height: 12),
              _buildImpactRow(
                icon: '💵',
                title: 'Total Interest Saving (30yr)',
                sub: 'Estimated over loan lifetime',
                widthPct: 0.80,
                color: const Color(0xFFD4A017),
                val: '~\$117K',
              ),
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
                'Save OCR Rate Snapshot',
                style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Historical Highs & Lows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historical Highs & Lows',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Full History →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Historical List
        Column(
          children: [
            _buildHistoricalMilestone('🔥', 'All-Time Peak: 6.50%', 'Jun 2007 · Global Financial Crisis eve', '6.50%', const Color(0xFFFEF2F2), const Color(0xFFC0392B)),
            _buildHistoricalMilestone('📉', 'All-Time Low: 0.25%', 'Mar 2020 – Oct 2021 · COVID-19 emergency', '0.25%', const Color(0xFFECFDF5), const Color(0xFF0F766E)),
            _buildHistoricalMilestone('🎯', 'Neutral Rate: ~3.00%', 'RBNZ estimated neutral OCR for NZ economy', '~3.00%', const Color(0xFFFFFBEB), const Color(0xFFD4A017)),
            _buildHistoricalMilestone('🏦', 'First OCR Set: 5.00%', '17 March 1999 · RBNZ introduced OCR system', '5.00%', const Color(0xFFF0FDFA), const Color(0xFF0D9488)),
          ],
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

  Widget _buildHeroStat(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String code) {
    final active = _selectedPeriod == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? widget.theme.primaryColor : widget.theme.getBorderColor(context)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: active ? Colors.white : widget.theme.getTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForecastItem(String rate, String date, String prob, {bool isCurrent = false}) {
    return Container(
      width: 76,
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(rate, style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: isCurrent ? const Color(0xFFD4A017) : const Color(0xFF0D3B2E))),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? const Color(0xFFD4A017) : const Color(0xFF0D9488),
              boxShadow: isCurrent ? [BoxShadow(color: const Color(0xFFD4A017).withValues(alpha: 0.25), spreadRadius: 3)] : null,
            ),
          ),
          Text(date, style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF4A6358))),
          Text(prob, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: const Color(0xFF0D9488))),
        ],
      ),
    );
  }

  Widget _buildArrowIndicator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Text('→', style: TextStyle(fontSize: 10, color: Color(0xFF0D9488))),
    );
  }

  Widget _buildImpactRow({
    required String icon,
    required String title,
    required String sub,
    required double widthPct,
    required Color color,
    required String val,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
              Text(sub, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
              const SizedBox(height: 5),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: widget.theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widthPct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          val,
          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildHistoricalMilestone(String emoji, String title, String sub, String val, Color bgCol, Color valColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.theme.getCardColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.theme.getBorderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? bgCol.withValues(alpha: 0.15) : bgCol,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
                  Text(sub, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
                ],
              ),
            ),
            Text(
              val,
              style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: isDark ? const Color(0xFFF5D060) : valColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _OCRHistoryPainter extends CustomPainter {
  final String period;
  final bool isDark;
  final CountryTheme theme;

  const _OCRHistoryPainter({
    required this.period,
    required this.isDark,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We scale SVG coordinates relative to 360 x 160 viewbox
    final scaleX = size.width / 360;
    final scaleY = size.height / 160;

    final borderPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0x170D3B2E)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines (matching HTML Y ticks)
    // 6% -> y=10, 5% -> y=42, 4% -> y=74, 3% -> y=106, 2% -> y=138
    final yTicks = [10.0, 42.0, 74.0, 106.0, 138.0];
    final rates = ['6%', '5%', '4%', '3%', '2%'];

    for (int i = 0; i < yTicks.length; i++) {
      final y = yTicks[i] * scaleY;
      canvas.drawLine(Offset(36 * scaleX, y), Offset(356 * scaleX, y), borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: rates[i],
          style: TextStyle(
            fontSize: 8,
            color: isDark ? Colors.white54 : const Color(0xFF4A6358),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(12 * scaleX, y - 5));
    }

    // Polyline coordinates from HTML
    List<Offset> pts = [];
    if (period == '2yr') {
      pts = const [
        Offset(36, 138), Offset(66, 106), Offset(96, 74), Offset(120, 42), Offset(148, 10),
        Offset(172, 10), Offset(196, 10), Offset(220, 10), Offset(244, 42), Offset(268, 74),
        Offset(290, 106), Offset(316, 117), Offset(340, 124), Offset(356, 131)
      ];
    } else if (period == '5yr') {
      pts = const [
        Offset(36, 150), Offset(60, 150), Offset(84, 142), Offset(108, 106), Offset(132, 74),
        Offset(156, 42), Offset(180, 10), Offset(204, 10), Offset(228, 10), Offset(252, 42),
        Offset(272, 74), Offset(296, 106), Offset(320, 117), Offset(344, 124), Offset(356, 131)
      ];
    } else {
      pts = const [
        Offset(36, 74), Offset(60, 106), Offset(84, 10), Offset(110, 42), Offset(134, 138),
        Offset(158, 150), Offset(182, 150), Offset(206, 106), Offset(230, 42), Offset(254, 74),
        Offset(278, 10), Offset(302, 42), Offset(324, 10), Offset(344, 42), Offset(356, 131)
      ];
    }

    // Map & scale points
    final List<Offset> scaledPts = pts.map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY)).toList();

    // Draw area fill
    if (scaledPts.length >= 2) {
      final path = Path()..moveTo(scaledPts.first.dx, scaledPts.first.dy);
      for (int i = 1; i < scaledPts.length; i++) {
        path.lineTo(scaledPts[i].dx, scaledPts[i].dy);
      }
      path.lineTo(scaledPts.last.dx, 150 * scaleY);
      path.lineTo(scaledPts.first.dx, 150 * scaleY);
      path.close();

      final fillPaint = Paint()
        ..color = theme.primaryColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
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

    // Draw Peak marker: peak is at index 4 (for 2yr, x=148, y=10)
    if (period == '2yr' && scaledPts.length > 4) {
      final peakPt = scaledPts[4];
      final peakPaint = Paint()..color = const Color(0xFFC0392B);
      canvas.drawCircle(peakPt, 4.0, peakPaint);
      canvas.drawCircle(peakPt, 4.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // Draw current marker: at the end (3.75%)
    if (scaledPts.isNotEmpty) {
      final currentPt = scaledPts.last;
      final currentPaint = Paint()..color = const Color(0xFFD4A017);
      canvas.drawCircle(currentPt, 5.0, currentPaint);
      canvas.drawCircle(currentPt, 5.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }
  }

  @override
  bool shouldRepaint(covariant _OCRHistoryPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.isDark != isDark;
}
