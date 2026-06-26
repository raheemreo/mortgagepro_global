// lib/features/usa/screens/usa_jumbo_documentation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAJumboDocumentationScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAJumboDocumentationScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAJumboDocumentationScreen> createState() => _USAJumboDocumentationScreenState();
}

class _USAJumboDocumentationScreenState extends ConsumerState<USAJumboDocumentationScreen> {
  static const _theme = CountryThemes.usa;

  final List<bool> _checkedItems = List.filled(18, false);
  String _borrowerType = 'w2'; // w2, self-employed, retired, investor
  final Map<String, bool> _categoryOpen = {
    'income': true,
    'assets': false,
    'credit': false,
    'property': false,
    'insurance': false,
  };

  final List<Map<String, dynamic>> _checklistItems = [
    // Income (0 to 5)
    {
      'id': 'd1',
      'category': 'income',
      'name': 'W-2 Forms (Last 2 Years)',
      'detail': 'From all employers. Must include employer name, EIN, wages & federal withholding.',
      'type': 'required',
    },
    {
      'id': 'd2',
      'category': 'income',
      'name': 'Federal Tax Returns (1040, 2 Years)',
      'detail': 'All pages, all schedules. Signed & dated. IRS transcripts may also be required via 4506-C.',
      'type': 'required',
    },
    {
      'id': 'd3',
      'category': 'income',
      'name': '30-Day Pay Stubs (Most Recent)',
      'detail': 'Year-to-date earnings must match W-2 trajectory. Some lenders require 60 days.',
      'type': 'required',
    },
    {
      'id': 'd4',
      'category': 'income',
      'name': 'Employer Verification Letter (VOE)',
      'detail': 'Confirmation of employment, position, salary, start date on employer letterhead.',
      'type': 'required',
    },
    {
      'id': 'd5',
      'category': 'income',
      'name': 'Bonus / Commission History (2 Years)',
      'detail': 'Required if variable income used in qualification. Must average over 24 months.',
      'type': 'preferred',
    },
    {
      'id': 'd6',
      'category': 'income',
      'name': 'IRS 4506-C Form (Signed)',
      'detail': 'Authorization for lender to obtain tax transcripts directly from IRS.',
      'type': 'required',
    },
    // Assets (6 to 9)
    {
      'id': 'd7',
      'category': 'assets',
      'name': 'Bank Statements (2–3 Months)',
      'detail': 'All pages, all accounts. Large deposits ≥\$5,000 must be documented with source letters.',
      'type': 'required',
    },
    {
      'id': 'd8',
      'category': 'assets',
      'name': 'Investment / Brokerage Statements',
      'detail': 'Most recent 3 months. Stocks, bonds, mutual funds. 70% of value counted for liquid reserves.',
      'type': 'required',
    },
    {
      'id': 'd9',
      'category': 'assets',
      'name': 'Retirement Account Statements (401k/IRA)',
      'detail': 'Most recent quarter. 60–70% of vested balance counted if under 59½ due to early withdrawal penalty.',
      'type': 'preferred',
    },
    {
      'id': 'd10',
      'category': 'assets',
      'name': 'Gift Letter (if applicable)',
      'detail': 'For jumbo loans, gifts typically must be 100% from immediate family. Letter must state no repayment expected.',
      'type': 'optional',
    },
    // Credit (10 to 12)
    {
      'id': 'd11',
      'category': 'credit',
      'name': 'Government-Issued Photo ID',
      'detail': 'Driver\'s license, passport, or state ID. Must be current and not expired. Both sides required.',
      'type': 'required',
    },
    {
      'id': 'd12',
      'category': 'credit',
      'name': 'Social Security Number / Card',
      'detail': 'Used for credit pull authorization. Most lenders accept last 4 digits after verification.',
      'type': 'required',
    },
    {
      'id': 'd13',
      'category': 'credit',
      'name': 'Credit Report Explanation Letters',
      'detail': 'Written explanation for any derogatory marks, late payments, or collections in last 7 years.',
      'type': 'preferred',
    },
    // Property (13 to 15)
    {
      'id': 'd14',
      'category': 'property',
      'name': 'Signed Purchase Agreement',
      'detail': 'Fully executed contract with all addendums, seller disclosures, and contingency waivers.',
      'type': 'required',
    },
    {
      'id': 'd15',
      'category': 'property',
      'name': 'Property Appraisal (Ordered by Lender)',
      'detail': 'Jumbo loans often require 2 appraisals for loans over \$2M. USPAP-compliant, full interior inspection.',
      'type': 'required',
    },
    {
      'id': 'd16',
      'category': 'property',
      'name': 'Title Report / Preliminary Title Search',
      'detail': 'Confirm property is free of liens, judgments, or encumbrances. Title insurance required at closing.',
      'type': 'required',
    },
    // Insurance (16 to 17)
    {
      'id': 'd17',
      'category': 'insurance',
      'name': 'Homeowner\'s Insurance Binder',
      'detail': 'Coverage must equal replacement cost or loan amount, whichever is less. Named mortgagee clause required.',
      'type': 'required',
    },
    {
      'id': 'd18',
      'category': 'insurance',
      'name': 'Flood Insurance (FEMA Zone)',
      'detail': 'Mandatory if property in FEMA Special Flood Hazard Area (Zone A or V). Min. coverage = loan amount or max available.',
      'type': 'optional',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      for (int i = 0; i < 18; i++) {
        _checkedItems[i] = (inputs['item_$i'] ?? 0.0) == 1.0;
      }
      final typeIdx = (inputs['borrowerType'] ?? 0.0).toInt();
      const types = ['w2', 'self-employed', 'retired', 'investor'];
      if (typeIdx >= 0 && typeIdx < types.length) {
        _borrowerType = types[typeIdx];
      }
    }
  }

  void _toggleDoc(int index) {
    setState(() {
      _checkedItems[index] = !_checkedItems[index];
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_checkedItems[index] ? '✅ Document checked off!' : 'Removed checked document'),
        backgroundColor: _theme.primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  int get _checkedCount => _checkedItems.where((c) => c).length;
  double get _checkedPercent => _checkedCount / 18.0;
  int get _readinessScore => (_checkedPercent * 100).round();

  String get _readinessTitle {
    final score = _readinessScore;
    if (score >= 80) return 'Ready to Apply';
    if (score >= 50) return 'Almost There';
    if (score > 0) return 'Getting Started';
    return 'Not Started';
  }

  String get _readinessSub {
    final score = _readinessScore;
    if (score >= 80) return 'You have the documents most lenders require.';
    if (score >= 50) return 'A few more items and you can submit your application.';
    if (score > 0) return 'Keep gathering documents to improve your score.';
    return 'Start checking off documents above.';
  }

  void _saveProgress() {
    final types = ['w2', 'self-employed', 'retired', 'investor'];
    final typeIdx = types.indexOf(_borrowerType);

    final Map<String, double> inputs = {};
    for (int i = 0; i < 18; i++) {
      inputs['item_$i'] = _checkedItems[i] ? 1.0 : 0.0;
    }
    inputs['borrowerType'] = typeIdx.toDouble();

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Jumbo Doc Checklist',
      label: 'Jumbo Docs: $_checkedCount/18 check (${_borrowerType.toUpperCase()})',
      currencyCode: 'USD',
      inputs: inputs,
      results: {
        'ReadinessScore': _readinessScore.toDouble(),
        'CheckedCount': _checkedCount.toDouble(),
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Checklist progress saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incomeCount = _checklistItems.where((it) => it['category'] == 'income').length;
    final incomeChecked = _checklistItems
        .asMap()
        .entries
        .where((e) => e.value['category'] == 'income' && _checkedItems[e.key])
        .length;

    final assetsCount = _checklistItems.where((it) => it['category'] == 'assets').length;
    final assetsChecked = _checklistItems
        .asMap()
        .entries
        .where((e) => e.value['category'] == 'assets' && _checkedItems[e.key])
        .length;

    final creditCount = _checklistItems.where((it) => it['category'] == 'credit').length;
    final creditChecked = _checklistItems
        .asMap()
        .entries
        .where((e) => e.value['category'] == 'credit' && _checkedItems[e.key])
        .length;

    final propertyCount = _checklistItems.where((it) => it['category'] == 'property').length;
    final propertyChecked = _checklistItems
        .asMap()
        .entries
        .where((e) => e.value['category'] == 'property' && _checkedItems[e.key])
        .length;

    final insuranceCount = _checklistItems.where((it) => it['category'] == 'insurance').length;
    final insuranceChecked = _checklistItems
        .asMap()
        .entries
        .where((e) => e.value['category'] == 'insurance' && _checkedItems[e.key])
        .length;

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
                      const Text('📋', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Documentation Required',
                          style: AppTextStyles.playfair(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Jumbo Loan Application Checklist · 2025',
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
                    child: _buildStripItem('Doc Types', '6', 'Categories', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Required', '18', 'Must-have', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Avg Prep', '7-14', 'Days', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Close Time', '38', 'Days Avg', isDark),
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
                // Progress Hero
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR DOCUMENT READINESS',
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 5),
                      Text('$_checkedCount of 18 Complete',
                          style: AppTextStyles.playfair(
                              size: 18,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Check off documents as you gather them',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white54)),
                      const SizedBox(height: 14),
                      Container(
                        height: 10,
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
                                gradient: const LinearGradient(colors: [Color(0xFFFCD34D), Color(0xFFD97706)]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPhStat('$_checkedCount', 'Checked'),
                          _buildPhStat('${18 - _checkedCount}', 'Remaining'),
                          _buildPhStat('$_readinessScore%', 'Complete'),
                          _buildPhStat(_checkedCount == 18 ? 'Ready' : '${14 - (_checkedPercent * 14).round()}', 'Est. Days'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _saveProgress,
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
                            '💾 Save Progress',
                            style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Borrower Type'),

                // Borrower Type Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildBorrowerTypeCard('👔 W-2 Employee', 'Salaried / Hourly', 'w2'),
                    _buildBorrowerTypeCard('💼 Self-Employed', '1099 / Owner', 'self-employed'),
                    _buildBorrowerTypeCard('🏖️ Retired', 'SSA / Investments', 'retired'),
                    _buildBorrowerTypeCard('📈 Investor', 'DSCR / Asset-Based', 'investor'),
                  ],
                ),

                const SizedBox(height: 12),

                // Readiness Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 Document Readiness Score',
                          style: AppTextStyles.playfair(size: 12, color: const Color(0xFF92400E), weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$_readinessScore', style: AppTextStyles.playfair(size: 22, color: const Color(0xFF92400E), weight: FontWeight.w800)),
                                Text('/ 100', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFFB45309), weight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_readinessTitle, style: AppTextStyles.playfair(size: 12, color: const Color(0xFF92400E), weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(_readinessSub, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E).withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildScoreTier('80–100: Ready', const Color(0xFF15803D)),
                          _buildScoreTier('50–79: Almost', const Color(0xFFD97706)),
                          _buildScoreTier('0–49: Need Docs', const Color(0xFFB91C1C)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Document Checklist'),

                // Categories
                _buildCategoryHeader('income', '💵', 'Income Verification', '$incomeChecked/$incomeCount'),
                if (_categoryOpen['income'] == true)
                  _buildCategoryList('income'),

                _buildCategoryHeader('assets', '💰', 'Assets & Reserves', '$assetsChecked/$assetsCount'),
                if (_categoryOpen['assets'] == true)
                  _buildCategoryList('assets'),

                _buildCategoryHeader('credit', '🎯', 'Credit & Identity', '$creditChecked/$creditCount'),
                if (_categoryOpen['credit'] == true)
                  _buildCategoryList('credit'),

                _buildCategoryHeader('property', '🏛️', 'Property Documents', '$propertyChecked/$propertyCount'),
                if (_categoryOpen['property'] == true)
                  _buildCategoryList('property'),

                _buildCategoryHeader('insurance', '🔥', 'Insurance Documents', '$insuranceChecked/$insuranceCount'),
                if (_categoryOpen['insurance'] == true)
                  _buildCategoryList('insurance'),

                const SizedBox(height: 20),
                _buildSectionHeader('Application Timeline'),

                // Timeline Card
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
                      Text('📅 Jumbo Loan Process Timeline',
                          style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildTimelineItem('📋', 'Step 1 · Day 1', 'Pre-Application & Doc Gathering', 'Collect all documents from this checklist • 7–14 days', isLast: false),
                      _buildTimelineItem('🔍', 'Step 2 · Day 7–14', 'Pre-Approval Letter', 'Lender reviews income, assets, credit • 3–5 business days', isLast: false),
                      _buildTimelineItem('🏛️', 'Step 3 · Day 15–25', 'Underwriting & Appraisal', 'Full file review, property appraisal ordered • 7–10 days', isLast: false),
                      _buildTimelineItem('✅', 'Step 4 · Day 35–45', 'Clear to Close', 'Final approval, CD issued • 3 days before closing', isLast: true),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Speed tip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF334155)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Speed Up Your Jumbo Approval',
                          style: AppTextStyles.playfair(size: 11, color: const Color(0xFFFCD34D), weight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(
                        'Jumbo underwriters manually review every file. Organize documents digitally in labeled folders (Income, Assets, Property) before uploading. Pre-write explanation letters for any credit inquiries or large deposits. Having 18 months of PITI in liquid reserves — not just 12 — can fast-track approval at most top-tier lenders.',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white70, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.playfair(size: 15, color: Colors.white, weight: FontWeight.w800)),
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
      ],
    );
  }

  Widget _buildBorrowerTypeCard(String label, String sub, String type) {
    final active = _borrowerType == type;
    final textCol = _theme.getTextColor(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _borrowerType = type;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist updated for ${label.substring(2)}!'),
            backgroundColor: _theme.primaryColor,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B1D3A) : _theme.getCardColor(context),
          border: Border.all(color: active ? const Color(0xFF0B1D3A) : _theme.getBorderColor(context), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.playfair(size: 11, color: active ? Colors.white : textCol, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(sub, style: AppTextStyles.dmSans(size: 8, color: active ? Colors.white60 : _theme.getMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTier(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E))),
      ],
    );
  }

  Widget _buildCategoryHeader(String category, String icon, String title, String count) {
    final isOpen = _categoryOpen[category] == true;
    final textCol = _theme.getTextColor(context);
    final borderCol = _theme.getBorderColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: borderCol),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _categoryOpen[category] = !isOpen;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: _theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _theme.getBgColor(context), borderRadius: BorderRadius.circular(8)),
                child: Text(count, style: AppTextStyles.dmSans(size: 10, color: _theme.getMutedColor(context), weight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Icon(isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: _theme.getMutedColor(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(String category) {
    final textCol = _theme.getTextColor(context);
    final borderCol = _theme.getBorderColor(context);
    final mutedCol = _theme.getMutedColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: borderCol),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: _checklistItems.asMap().entries.where((e) => e.value['category'] == category).map((entry) {
          final idx = entry.key;
          final doc = entry.value;
          final isChecked = _checkedItems[idx];
          
          // Determine custom status based on borrower profile
          String reqText = doc['type'].toString().toUpperCase();
          Color reqBg = const Color(0xFFFEE2E2);
          Color reqFg = const Color(0xFFB91C1C);

          if (doc['type'] == 'preferred') {
            reqBg = const Color(0xFFFEF3C7);
            reqFg = const Color(0xFFB45309);
          } else if (doc['type'] == 'optional') {
            reqBg = const Color(0xFFE0F2FE);
            reqFg = const Color(0xFF0369A1);
          }

          // Override details based on borrower profile
          if (_borrowerType == 'self-employed' && doc['id'] == 'd2') {
            reqText = 'BUSINESS TAX TAX OK';
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _toggleDoc(idx),
                  child: Container(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['name'], style: AppTextStyles.dmSans(size: 11.5, color: textCol, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(doc['detail'], style: AppTextStyles.dmSans(size: 9, color: mutedCol, height: 1.3)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: reqBg, borderRadius: BorderRadius.circular(5)),
                        child: Text(reqText, style: AppTextStyles.dmSans(size: 8, color: reqFg, weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineItem(String dot, String step, String title, String time, {required bool isLast}) {
    final textCol = _theme.getTextColor(context);
    final borderCol = _theme.getBorderColor(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: _theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(dot, style: const TextStyle(fontSize: 16)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: borderCol, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context), weight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 1),
                  Text(title, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(time, style: AppTextStyles.dmSans(size: 9, color: _theme.getMutedColor(context))),
                ],
              ),
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
}
