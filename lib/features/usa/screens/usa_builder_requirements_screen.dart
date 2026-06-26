// lib/features/usa/screens/usa_builder_requirements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USABuilderRequirementsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USABuilderRequirementsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USABuilderRequirementsScreen> createState() => _USABuilderRequirementsScreenState();
}

class _USABuilderRequirementsScreenState extends ConsumerState<USABuilderRequirementsScreen> {
  static const _theme = CountryThemes.usa;

  // The 10 Checklist Items
  final List<Map<String, dynamic>> _checklistItems = [
    {
      'id': 'license',
      'label': 'Valid contractor license',
      'sub': 'State or local license/registration, where required',
      'checked': false,
    },
    {
      'id': 'gl',
      'label': 'General liability insurance',
      'sub': 'Typically \$500K–\$1M+ coverage minimum',
      'checked': false,
    },
    {
      'id': 'wc',
      'label': 'Workers\' compensation coverage',
      'sub': 'Required if the builder has employees',
      'checked': false,
    },
    {
      'id': 'bond',
      'label': 'Posted license/surety bond',
      'sub': 'Amount varies \$5,000–\$25,000 by state',
      'checked': false,
    },
    {
      'id': 'exp',
      'label': '2+ years verified experience',
      'sub': 'Comparable project history in this build type',
      'checked': false,
    },
    {
      'id': 'approved',
      'label': 'Lender-approved builder status',
      'sub': 'On the lender\'s list, or willing to complete approval',
      'checked': false,
    },
    {
      'id': 'fin',
      'label': 'Financials provided to lender',
      'sub': 'Bank statements, credit check, bonding capacity',
      'checked': false,
    },
    {
      'id': 'refs',
      'label': 'References & project portfolio',
      'sub': 'Recent comparable builds, verifiable contacts',
      'checked': false,
    },
    {
      'id': 'risk',
      'label': 'Builder\'s risk insurance secured',
      'sub': 'Covers the structure during construction',
      'checked': false,
    },
    {
      'id': 'clean',
      'label': 'No active liens or board complaints',
      'sub': 'Clean standing with the state licensing board',
      'checked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      for (var item in _checklistItems) {
        final val = inputs[item['id']];
        if (val != null) {
          item['checked'] = val == 1.0;
        }
      }
    }
  }

  int get _checkedCount => _checklistItems.where((i) => i['checked']).length;
  double get _readinessScore => _checklistItems.isEmpty ? 0.0 : _checkedCount / _checklistItems.length;

  String _getReadinessStatus() {
    final score = _readinessScore;
    if (score >= 0.9) return 'Lender-Ready';
    if (score >= 0.6) return 'Nearly There';
    if (score >= 0.3) return 'In Progress';
    return 'Getting Started';
  }

  String _getReadinessSubtext() {
    final score = _readinessScore;
    if (score >= 0.9) return 'This builder meets most standard approval criteria.';
    if (score >= 0.6) return 'A few gaps remain before full lender approval.';
    if (score >= 0.3) return 'Keep collecting documentation for lender review.';
    return 'Check off items as your builder completes them.';
  }

  Color _getScoreColor() {
    final score = _readinessScore;
    if (score >= 0.9) return const Color(0xFFFCD34D); // Gold/yellow
    if (score >= 0.6) return const Color(0xFFD97706); // Dark Gold
    if (score >= 0.3) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  void _toggleItem(int index) {
    setState(() {
      _checklistItems[index]['checked'] = !_checklistItems[index]['checked'];
    });
  }

  void _saveChecklist() {
    final scorePct = (_readinessScore * 100).round().toDouble();
    final Map<String, double> inputs = {};
    for (var item in _checklistItems) {
      inputs[item['id']] = item['checked'] ? 1.0 : 0.0;
    }

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Construction Builder Requirements',
      label: 'Builder Readiness · $_checkedCount/${_checklistItems.length} Complete',
      currencyCode: 'USD',
      inputs: inputs,
      results: {
        'ReadinessScore': scorePct,
        'CheckedCount': _checkedCount.toDouble(),
        'TotalCount': _checklistItems.length.toDouble(),
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Builder requirements checklist saved!'),
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
                      const Text('📋', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Builder Requirements',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Licensed Contractor & Lender Approval Standards',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white54)),
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
                    child: _buildStripItem('Bond Range', '\$5K–25K', 'by state', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Experience', '2–5 yrs', 'typical min.', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('GL Insurance', '\$500K+', 'min. typical', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('No State Lic.', '4 states', 'TX·CO·KS·WY', isDark),
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
                _buildSectionHeader('Builder Readiness Score'),

                // Score Ring card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Score Ring Visualizer
                      CustomPaint(
                        size: const Size(80, 80),
                        painter: _ScoreRingPainter(
                          score: _readinessScore,
                          ringColor: _getScoreColor(),
                          totalCount: _checklistItems.length,
                          checkedCount: _checkedCount,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LENDER APPROVAL READINESS',
                              style: AppTextStyles.dmSans(
                                size: 8.5,
                                weight: FontWeight.w700,
                                color: Colors.white54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _getReadinessStatus(),
                              style: AppTextStyles.dmSans(
                                size: 19,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _getReadinessSubtext(),
                              style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _saveChecklist,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔖 ', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    Text(
                                      'Save Checklist',
                                      style: AppTextStyles.dmSans(size: 10.5, color: Colors.white, weight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Builder Readiness Checklist'),

                // Checklist Items
                ...List.generate(_checklistItems.length, (idx) {
                  final item = _checklistItems[idx];
                  final checked = item['checked'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _toggleItem(idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: checked ? (isDark ? const Color(0xFF282015) : const Color(0xFFFFFBEB)) : cardBg,
                          border: Border.all(color: checked ? const Color(0xFFD97706) : borderCol, width: checked ? 1.5 : 1.0),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: checked ? const Color(0xFFD97706) : Colors.transparent,
                                border: Border.all(color: checked ? const Color(0xFFD97706) : mutedCol.withValues(alpha: 0.3), width: 2.0),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label'],
                                    style: AppTextStyles.dmSans(
                                      size: 11.5,
                                      weight: FontWeight.w700,
                                      color: checked ? textCol.withValues(alpha: 0.8) : textCol,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['sub'],
                                    style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      color: mutedCol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                _buildSectionHeader('Typical Requirements by Category'),

                // What Lenders Weigh Most Chart
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
                      Text('📊 What Lenders Weigh Most',
                          style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _buildWeightRow('License & Insurance', 0.90, const Color(0xFFB91C1C), textCol),
                      const SizedBox(height: 12),
                      _buildWeightRow('Financial Strength', 0.75, const Color(0xFFD97706), textCol),
                      const SizedBox(height: 12),
                      _buildWeightRow('Experience & References', 0.70, const Color(0xFF0B1D3A), textCol),
                      const SizedBox(height: 12),
                      _buildWeightRow('Bonding & Liens', 0.55, const Color(0xFF1B3F72), textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('State Licensing Snapshot'),

                // State snaps
                Column(
                  children: [
                    _buildStateCard('🐻', 'California', 'CSLB state license · \$25,000 contractor bond · 4 yrs verified experience · ~\$650 initial fees', 'License Req.', true, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildStateCard('⭐', 'Texas', 'No statewide GC license — local permits & registration apply (Houston, Dallas, Austin, San Antonio)', 'No State Lic.', false, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildStateCard('🚗', 'Michigan', 'Residential Builder license (LARA) · required for jobs ≥\$600 · 60-hr prelicensure course + exam', 'License Req.', true, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildStateCard('🦞', 'Massachusetts', 'Construction Supervisor License · 3 yrs verified experience · general liability insurance required', 'License Req.', true, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildStateCard('⛰️', 'Colorado / Kansas / Wyoming', 'No statewide general contractor license — local city/county permitting governs instead', 'No State Lic.', false, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildStateCard('🎰', 'Nevada', 'Licensed through the State Contractors Board · experience and qualifying-individual rules apply', 'License Req.', true, cardBg, textCol, mutedCol, borderCol),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Licensing varies by state and changes often — verify current rules with your state contractor licensing board.',
                    style: AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Lender Builder-Approval Package'),

                // Lender Builder-Approval Package list
                Column(
                  children: [
                    _buildPackageRow('🪪', 'Contractor License Copy', 'Active state/local license or registration, where applicable', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildPackageRow('🛡️', 'Certificate of Insurance', 'General liability (\$500K–\$1M+) and workers\' compensation if employees', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildPackageRow('📑', 'Signed Construction Contract', 'Fixed-price or cost-plus agreement with detailed scope of work', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildPackageRow('💵', 'Builder Financials', 'Bank statements, credit check, and proof of bonding capacity', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildPackageRow('🏗️', 'Builder\'s Risk Insurance', 'Covers the structure during the build before homeowner\'s policy starts', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildPackageRow('📋', 'Cost Breakdown / Draw Schedule', 'Line-item budget matching the lender\'s disbursement phases', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildPackageRow('⭐', 'References & Past Projects', 'Recent comparable builds with contact info for verification', cardBg, textCol, mutedCol, borderCol),
                  ],
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
                size: 12.5,
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

  Widget _buildWeightRow(String label, double fillPct, Color color, Color textCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: textCol)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 11,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFEEF2F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fillPct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 28,
              child: Text(
                '${(fillPct * 100).round()}%',
                style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: color),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateCard(String flag, String name, String details, String badgeText, bool required, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(flag, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: textCol)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: required ? const Color(0x1CB91C1C) : const Color(0x1C4A5C7A),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTextStyles.dmSans(
                          size: 7.5,
                          weight: FontWeight.w800,
                          color: required ? const Color(0xFFB91C1C) : mutedCol,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(details, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageRow(String emoji, String title, String subtitle, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color ringColor;
  final int totalCount;
  final int checkedCount;

  _ScoreRingPainter({
    required this.score,
    required this.ringColor,
    required this.totalCount,
    required this.checkedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = score * 2 * pi;
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);

    // Draw text inside
    final textPainterVal = TextPainter(
      text: TextSpan(
        text: '${(score * 100).round()}%',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Georgia'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterVal.layout();
    textPainterVal.paint(
      canvas,
      Offset(center.dx - textPainterVal.width / 2, center.dy - textPainterVal.height / 2 - 5),
    );

    final textPainterSub = TextPainter(
      text: TextSpan(
        text: '$checkedCount / $totalCount',
        style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w500, color: Colors.white60, fontFamily: 'DMSans'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterSub.layout();
    textPainterSub.paint(
      canvas,
      Offset(center.dx - textPainterSub.width / 2, center.dy - textPainterSub.height / 2 + 10),
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.ringColor != ringColor || oldDelegate.totalCount != totalCount || oldDelegate.checkedCount != checkedCount;
  }
}
