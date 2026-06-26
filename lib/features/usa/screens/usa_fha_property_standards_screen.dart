// lib/features/usa/screens/usa_fha_property_standards_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAFhaPropertyStandardsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFhaPropertyStandardsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFhaPropertyStandardsScreen> createState() => _USAFhaPropertyStandardsScreenState();
}

class _USAFhaPropertyStandardsScreenState extends ConsumerState<USAFhaPropertyStandardsScreen> {
  static const _theme = CountryThemes.usa;

  final List<bool> _checkedItems = List.filled(8, false);
  bool _calculated = false;

  // Outputs
  int _checkedCount = 0;
  double _checkedPercent = 0.0;
  String _resultTitle = '';
  String _resultSub = '';
  String _resultStatus = 'pass'; // pass, partial, fail

  final List<Map<String, String>> _checklistItems = [
    {
      'title': 'Roof in good condition',
      'detail': 'No major leaks, missing shingles, or structural sagging',
    },
    {
      'title': 'Foundation is stable',
      'detail': 'No major cracks, shifting, or signs of water intrusion',
    },
    {
      'title': 'Electrical system is safe',
      'detail': 'No exposed wiring, all outlets functional, panel up to code',
    },
    {
      'title': 'Plumbing & water heater work',
      'detail': 'Functioning hot/cold water, no leaks, working water heater',
    },
    {
      'title': 'Heating system functional',
      'detail': 'Permanent heat source able to maintain 50°F+ in main rooms',
    },
    {
      'title': 'No peeling paint (pre-1978 homes)',
      'detail': 'Lead-based paint hazard check for homes built before 1978',
    },
    {
      'title': 'Safe access to property',
      'detail': 'Adequate pedestrian/vehicle access from a public or private street',
    },
    {
      'title': 'No standing water / drainage issues',
      'detail': 'Proper grading directs water away from the foundation',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      for (int i = 0; i < 8; i++) {
        _checkedItems[i] = (inputs['item_$i'] ?? 0.0) == 1.0;
      }
      _calculate();
    }
  }

  void _calculate() {
    int checked = 0;
    for (final val in _checkedItems) {
      if (val) checked++;
    }
    final pct = checked / 8.0;

    setState(() {
      _checkedCount = checked;
      _checkedPercent = pct;
      if (pct >= 0.875) {
        _resultStatus = 'pass';
        _resultTitle = 'Likely to Pass';
        _resultSub = '$checked of 8 items confirmed. Your home shows strong signs of meeting FHA\'s minimum standards.';
      } else if (pct >= 0.5) {
        _resultStatus = 'partial';
        _resultTitle = 'Repairs May Be Needed';
        _resultSub = '$checked of 8 items confirmed. Some issues could trigger an appraiser repair request before closing.';
      } else {
        _resultStatus = 'fail';
        _resultTitle = 'Significant Issues Likely';
        _resultSub = '$checked of 8 items confirmed. Address these before ordering the FHA appraisal to avoid delays.';
      }
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;
    
    final Map<String, double> inputs = {};
    for (int i = 0; i < 8; i++) {
      inputs['item_$i'] = _checkedItems[i] ? 1.0 : 0.0;
    }

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FHA Property Standards',
      label: 'Property Standards: $_checkedCount/8 check',
      currencyCode: 'USD',
      inputs: inputs,
      results: {
        'CheckedPercent': _checkedPercent * 100,
        'CheckedCount': _checkedCount.toDouble(),
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Property standards check saved!'),
        backgroundColor: Colors.green,
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
                    colors: [Color(0xFF0B1D3A), Color(0xFF15803D), Color(0xFF166534)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏠', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Property Standards',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('HUD Minimum Property Requirements · Appraisal',
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
                    child: _buildStripItem('Appraisal Cost', '\$300–600', 'Buyer pays', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Validity', '180 Days', 'From issue', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Handbook', '4000.1', 'HUD Reference', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('FHA Property Standards', badgeText: 'HUD Handbook 4000.1'),

                // Hero Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FHA Minimum Property Standards (MPS) & Requirements (MPR)'.toUpperCase(),
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 5),
                      Text('Every FHA home must be safe, sound, and secure',
                          style: AppTextStyles.dmSans(
                              size: 16,
                              color: Colors.white,
                              weight: FontWeight.w800,
                              height: 1.25)),
                      const SizedBox(height: 6),
                      Text(
                          'A specially trained FHA appraiser checks the home twice: once for market value, once against HUD\'s habitability checklist. Fail it, and repairs are required before closing.',
                          style: AppTextStyles.dmSans(
                              size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTierBox('New Construction', 'MPS Rules'),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTierBox('Existing Homes', 'MPR Rules', isGold: true),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTierBox('First-Time Buyers', '80%+ of FHA'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('The Three Pillars'),

                // Three S Columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSColumn('S', 'Safety', 'No hazards to health or life — exposed wiring, gas leaks, lead paint', cardBg, textCol, mutedCol, borderCol),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSColumn('S', 'Security', 'Property protects occupants & investment — locks, access, boundaries', cardBg, textCol, mutedCol, borderCol),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSColumn('S', 'Soundness', 'Structurally stable — foundation, roof, systems all functional', cardBg, textCol, mutedCol, borderCol),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Pre-Appraisal Self-Check'),

                // Checklist Card
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
                      Text('✅ Will Your Home Pass?',
                          style: AppTextStyles.dmSans(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Tap each item to mark it as confirmed. This is a guide only — the FHA appraiser makes the final call.',
                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.4)),
                      const SizedBox(height: 12),
                      
                      // Checklist View
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 8,
                        separatorBuilder: (context, index) => Divider(color: borderCol),
                        itemBuilder: (context, index) {
                          final item = _checklistItems[index];
                          final isChecked = _checkedItems[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _checkedItems[index] = !isChecked;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isChecked ? const Color(0xFF15803D) : Colors.transparent,
                                      border: Border.all(color: isChecked ? const Color(0xFF15803D) : borderCol, width: 2),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    alignment: Alignment.center,
                                    child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['title']!, style: AppTextStyles.dmSans(size: 11.5, color: textCol, weight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(item['detail']!, style: AppTextStyles.dmSans(size: 9, color: mutedCol, height: 1.3)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🏠 Calculate My Readiness Score',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Calculation Results Card
                if (_calculated) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _resultStatus == 'pass'
                            ? [const Color(0xFF0B1D3A), const Color(0xFF15803D)]
                            : _resultStatus == 'partial'
                                ? [const Color(0xFF92400E), const Color(0xFFD97706)]
                                : [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _resultStatus == 'pass' ? '✅ ' : _resultStatus == 'partial' ? '⚠️ ' : '❌ ',
                              style: const TextStyle(fontSize: 22),
                            ),
                            Text(
                              _resultTitle,
                              style: AppTextStyles.dmSans(size: 17, color: Colors.white, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_resultSub,
                            style: AppTextStyles.dmSans(
                                size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                        const SizedBox(height: 14),
                        
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _checkedPercent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: const LinearGradient(colors: [Color(0xFF86EFAC), Color(0xFFFCD34D)]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                '$_checkedCount / 8 Items Confirmed (${(_checkedPercent * 100).toStringAsFixed(0)}%)',
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, weight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _saveCalc,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🔖 Save This Checklist',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Pass vs. Repair Order'),

                // Side by Side Pass/Fail Cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildPassFailCard(
                        title: '✅ Usually Forgiven',
                        subtitle: 'Cosmetic / Non-safety',
                        items: ['Worn carpet/flooring', 'Outdated finishes', 'Small drywall holes', 'Faded paint (post-1978)', 'Minor cabinet wear'],
                        isPass: true,
                        borderCol: borderCol,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPassFailCard(
                        title: '❌ Requires Repair',
                        subtitle: 'Safety / Soundness',
                        items: ['Exposed/frayed wiring', 'Active roof leaks', 'Broken windows', 'No working heat source', 'Peeling paint (pre-1978)'],
                        isPass: false,
                        borderCol: borderCol,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Appraisal & Inspection Costs'),

                // Cost Chart Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💰 Typical Buyer Costs at Closing',
                          style: AppTextStyles.dmSans(
                              size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildChartBar('FHA Appraisal Fee', '\$300–\$600', 0.45, [const Color(0xFF1B3F72), const Color(0xFF0B1D3A)], '~\$450'),
                      const SizedBox(height: 10),
                      _buildChartBar('General Home Inspection (Optional)', '\$300–\$500', 0.38, [const Color(0xFFD97706), const Color(0xFFB45309)], '~\$400'),
                      const SizedBox(height: 10),
                      _buildChartBar('Larger Property Inspection', '\$500–\$700+', 0.55, [const Color(0xFF15803D), const Color(0xFF166534)], '~\$600'),
                      const SizedBox(height: 10),
                      Text('FHA appraisal is mandatory and paid by the buyer. A separate full home inspection is optional but strongly recommended — the appraisal alone does not replace it.',
                          style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('2025–2026 Rule Updates'),

                // Updates List
                Column(
                  children: [
                    _buildUpdateCard('🌊', 'New Flood Elevation Rule (Jan 2025)', 'New construction in flood zones needs lowest floor 2ft above base flood elevation', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildUpdateCard('📝', 'Streamlined Appraisal Protocols', 'HUD Mortgagee Letter 2025-18 aligns some FHA steps closer to conventional appraisals', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildUpdateCard('🔍', 'Value Reconsideration Process', 'Updated borrower-initiated process to dispute a low appraisal value', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildUpdateCard('📋', 'Appraisal Valid 180 Days', 'Must close within validity window or a new appraisal may be required', cardBg, textCol, mutedCol, borderCol),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
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
                color: isDark ? const Color(0xFF134E5E) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
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
            style: AppTextStyles.dmSans(
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

  Widget _buildTierBox(String label, String value, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: isGold ? const Color(0xFFFCD34D) : Colors.white,
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSColumn(String letter, String label, String desc, Color cardColor, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderCol),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(letter, style: AppTextStyles.dmSans(size: 24, weight: FontWeight.w800, color: const Color(0xFF15803D))),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: textCol)),
          const SizedBox(height: 4),
          Text(desc, style: AppTextStyles.dmSans(size: 8, color: mutedCol, height: 1.35), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPassFailCard({required String title, required String subtitle, required List<String> items, required bool isPass, required Color borderCol}) {
    final cardBg = isPass ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final headCol = isPass ? const Color(0xFF166534) : const Color(0xFF991B1B);
    final borderL = isPass ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderL, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.dmSans(size: 11, color: headCol, weight: FontWeight.w800)),
          Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: headCol.withValues(alpha: 0.70))),
          const SizedBox(height: 8),
          ...items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text('• $it', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF0B1D3A), height: 1.25)),
          )),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, String limit, double fillFactor, List<Color> colors, String valueLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w600, color: _theme.getTextColor(context)))),
            Text(limit, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: _theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fillFactor,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  valueLabel,
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(
    String emoji,
    String title,
    String sub,
    Color bg,
    Color textCol,
    Color mutedCol,
    Color borderCol,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
