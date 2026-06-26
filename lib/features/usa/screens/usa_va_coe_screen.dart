// lib/features/usa/screens/usa_va_coe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAVaCoeScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAVaCoeScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAVaCoeScreen> createState() => _USAVaCoeScreenState();
}

class _USAVaCoeScreenState extends ConsumerState<USAVaCoeScreen> {
  static const _theme = CountryThemes.usa;

  // Form states
  String _selectedSvcCat = 'active'; // active, guard, spouse, other
  String _selectedPriorUse = 'no'; // no, yes
  String _selectedDisability = 'none'; // none, lt10, gte10

  // Checked documents
  final Set<String> _checkedDocs = {};

  bool _calculated = false;
  String _resultTitle = 'Full Entitlement';
  String _resultSub = 'No loan limit in 2026 · \$0 down possible';
  String _resultFf = 'Funding fee: 2.15% (1st use, 0% down, Active Duty)';

  final Map<String, List<Map<String, String>>> _docSets = {
    'active': [
      {'name': 'DD Form 214', 'note': 'Certificate of Release or Discharge from Active Duty'},
      {'name': 'Statement of Service (if currently serving)', 'note': 'Signed by your commander, adjutant, or personnel officer'},
      {'name': 'Social Security Number', 'note': 'Used to verify service records electronically'}
    ],
    'guard': [
      {'name': 'NGB Form 22', 'note': 'Report of Separation and Record of Service (Guard)'},
      {'name': 'Points Statements', 'note': 'Annual retirement points statements covering your full service'},
      {'name': 'Statement of Service', 'note': 'Required if currently on active status'}
    ],
    'spouse': [
      {'name': 'Veteran\'s DD Form 214', 'note': 'Discharge papers of the deceased veteran'},
      {'name': 'Marriage License', 'note': 'To verify your relationship to the veteran'},
      {'name': 'Death Certificate', 'note': 'Confirms service-connected or qualifying death'},
      {'name': 'VA Form 26-1817', 'note': 'Request for Determination of Loan Guaranty Eligibility'}
    ],
    'other': [
      {'name': 'DD Form 214 or equivalent', 'note': 'Discharge or separation record for your service type'},
      {'name': 'Supporting Service Records', 'note': 'Varies by category — lender can advise exactly what\'s needed'}
    ]
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      final svcIdx = (inputs['svcCat'] ?? 0.0).toInt();
      _selectedSvcCat = svcIdx == 0 ? 'active' : (svcIdx == 1 ? 'guard' : (svcIdx == 2 ? 'spouse' : 'other'));
      _selectedPriorUse = (inputs['priorUse'] ?? 0.0) == 0.0 ? 'no' : 'yes';
      final disIdx = (inputs['disability'] ?? 0.0).toInt();
      _selectedDisability = disIdx == 0 ? 'none' : (disIdx == 1 ? 'lt10' : 'gte10');
      _calculate();
    } else {
      _calculate();
    }
  }

  void _calculate() {
    String title = '';
    String sub = '';
    String ffNote = '';

    if (_selectedSvcCat == 'spouse') {
      title = 'Likely Eligible — Surviving Spouse';
      sub = 'Full entitlement available · \$0 down possible';
      ffNote = 'Funding fee: Exempt (\$0) for qualifying surviving spouses';
    } else if (_selectedPriorUse == 'no') {
      title = 'Full Entitlement';
      sub = 'No loan limit in 2026 · \$0 down possible';
      ffNote = _selectedDisability == 'gte10'
          ? 'Funding fee: Exempt (\$0) — 10%+ service-connected disability'
          : (_selectedSvcCat == 'guard'
              ? 'Funding fee: 2.40% (1st use, 0% down, Guard/Reserve)'
              : 'Funding fee: 2.15% (1st use, 0% down, Active Duty)');
    } else {
      title = 'Partial Entitlement (Likely)';
      sub = 'County limit (\$832,750 baseline) may apply · Confirm via COE';
      ffNote = _selectedDisability == 'gte10'
          ? 'Funding fee: Exempt (\$0) — 10%+ service-connected disability'
          : 'Funding fee: 3.30% (subsequent use, 0% down)';
    }

    setState(() {
      _resultTitle = title;
      _resultSub = sub;
      _resultFf = ffNote;
      _calculated = true;
      _checkedDocs.clear(); // reset docs checklist
    });
  }

  void _saveCalc() {
    if (!_calculated) return;

    double svcIdx = _selectedSvcCat == 'active' ? 0.0 : (_selectedSvcCat == 'guard' ? 1.0 : (_selectedSvcCat == 'spouse' ? 2.0 : 3.0));
    double priorIdx = _selectedPriorUse == 'no' ? 0.0 : 1.0;
    double disIdx = _selectedDisability == 'none' ? 0.0 : (_selectedDisability == 'lt10' ? 1.0 : 2.0);

    final catLabel = _selectedSvcCat == 'active' ? 'Active' : (_selectedSvcCat == 'guard' ? 'Guard' : (_selectedSvcCat == 'spouse' ? 'Spouse' : 'Other'));
    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'VA Certificate of Eligibility',
      label: 'COE Check: $catLabel (${_resultTitle.replaceAll("Likely ", "")})',
      currencyCode: 'USD',
      inputs: {
        'svcCat': svcIdx,
        'priorUse': priorIdx,
        'disability': disIdx,
      },
      results: {
        'Eligible': _resultTitle.contains('Not Eligible') ? 0.0 : 1.0,
        'IsExempt': _resultFf.contains('Exempt') ? 1.0 : 0.0,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ COE eligibility check saved!'),
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

    final currentDocs = _docSets[_selectedSvcCat] ?? [];

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar
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
                    colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF4C1D95)],
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
                      Text('Certificate of Eligibility',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('Your proof of VA loan benefit · COE',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Summary Rate Strip
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
                  Expanded(child: _buildStripItem('Fastest Path', 'Minutes', 'Via Lender', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Online Portal', '1–3 Days', 'VA.gov', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('By Mail', '~30 Days', 'Form 26-1880', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Alert Note Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚡ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'You don\'t always need to apply yourself — most VA-approved lenders pull your COE electronically in seconds using the VA\'s automated system (WebLGY).',
                          style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF1E3A5F), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Check Your Likely Entitlement'),

                // Input Card
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
                      _buildDropdownField<String>(
                        label: 'Service Category',
                        value: _selectedSvcCat,
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Veteran / Active Duty')),
                          DropdownMenuItem(value: 'guard', child: Text('National Guard / Reserve')),
                          DropdownMenuItem(value: 'spouse', child: Text('Surviving Spouse')),
                          DropdownMenuItem(value: 'other', child: Text('Other Qualifying Service')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSvcCat = val);
                            _calculate();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'VA Loan Used Before?',
                              value: _selectedPriorUse,
                              items: const [
                                DropdownMenuItem(value: 'no', child: Text('No, First Time')),
                                DropdownMenuItem(value: 'yes', child: Text('Yes, Used Before')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedPriorUse = val);
                                  _calculate();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Disability Rating',
                              value: _selectedDisability,
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('0% / None')),
                                DropdownMenuItem(value: 'lt10', child: Text('1–9%')),
                                DropdownMenuItem(value: 'gte10', child: Text('10% or More')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedDisability = val);
                                  _calculate();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Result Hero Card
                if (_calculated) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LIKELY ENTITLEMENT STATUS',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(_resultTitle,
                                style: AppTextStyles.playfair(size: 20, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(_resultSub,
                                style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text(_resultFf,
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _saveCalc,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark_border, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Save', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Three Ways to Get Your COE'),

                // Three paths checklist
                _buildPathCard(
                  '🏦',
                  'Ask Your Lender',
                  'Most VA-approved lenders retrieve your COE instantly through the VA\'s WebLGY system — often you do nothing yourself.',
                  'Minutes',
                  isBest: true,
                  mutedCol: mutedCol,
                  textCol: textCol,
                ),
                const SizedBox(height: 8),
                _buildPathCard(
                  '💻',
                  'Apply Online at VA.gov',
                  'Sign in with ID.me, Login.gov, DS Logon, or My HealtheVet to request, check, or print your COE yourself.',
                  'Often same-day to 3 days',
                  mutedCol: mutedCol,
                  textCol: textCol,
                ),
                const SizedBox(height: 8),
                _buildPathCard(
                  '✉️',
                  'Mail VA Form 26-1880',
                  'Download "Request for a Certificate of Eligibility," complete it, and mail it with your service documents to your Regional Loan Center.',
                  '~30 days',
                  mutedCol: mutedCol,
                  textCol: textCol,
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Typical Processing Time by Path'),

                // Horizontal chart card
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
                      Text('⏱️ Typical Processing Time by Path',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildHBarRow('Lender (WebLGY)', '~5 min', 0.03, textCol),
                      _buildHBarRow('VA.gov Online Portal', '1–3 days', 0.18, textCol),
                      _buildHBarRow('Mail-In Form 26-1880', '~30 days', 1.00, textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Documents You\'ll Likely Need'),

                // Checklist card
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
                      Text('📋 Document Checklist (${_selectedSvcCat.toUpperCase()})',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (currentDocs.isEmpty)
                        Text('No documents mapped.', style: AppTextStyles.dmSans(size: 10.5, color: mutedCol))
                      else
                        ...currentDocs.map((doc) {
                          final name = doc['name'] ?? '';
                          final note = doc['note'] ?? '';
                          final isChecked = _checkedDocs.contains(name);
                          return _buildDocChecklistRow(name, note, isChecked, textCol, mutedCol);
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('What\'s On Your COE'),

                // COE Features Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCompareRow('Entitlement Amount', 'Basic + bonus entitlement', textCol),
                      _buildCompareRow('Funding Fee Status', 'Exempt or payable (indicated by code)', textCol, isGold: true),
                      _buildCompareRow('Loan Type Eligible', 'Purchase · IRRRL · Cash-out', textCol),
                      _buildCompareRow('Entitlement Code', 'e.g. 01–10 (lender reads this to apply)', textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Common COE Entitlement Codes'),

                // Entitlement codes Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Common COE Entitlement Codes',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F), fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 10),
                      _buildCodeRow('01 – WWII Veteran', 'Legacy', const Color(0xFF1E40AF)),
                      _buildCodeRow('05 – Veteran (general)', 'Most common', const Color(0xFF1E40AF)),
                      _buildCodeRow('06 / 07 – Surviving Spouse', 'Fee exempt', const Color(0xFF1E40AF)),
                      _buildCodeRow('09 – Active Duty', 'Standard', const Color(0xFF1E40AF)),
                      _buildCodeRow('10 – Selected Reserves/Guard', '+0.25% fee', const Color(0xFF1E40AF)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer note strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Common errors that delay a COE: misspelled name, wrong SSN, incorrect date of birth, or a service number entered in the SSN field. Your lender can often fix these directly in the VA\'s LGY portal.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), height: 1.4),
                        ),
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

  Widget _buildStripItem(String label, String value, String sub, bool isDark, {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.sectionLabel(_theme.getMutedColor(context)),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ).copyWith(fontFamily: 'Georgia'),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathCard(String icon, String title, String desc, String time, {bool isBest = false, required Color mutedCol, required Color textCol}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _theme.getCardColor(context),
            border: Border.all(color: _theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.45)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3F72).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text('⏱ $time', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF1B3F72), weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isBest)
          Positioned(
            top: -7,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FASTEST',
                style: AppTextStyles.dmSans(size: 7.5, color: Colors.white, weight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHBarRow(String label, String value, double ratio, Color textCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600)),
              Text(value, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF1B3F72), weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F8),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF4C1D95)]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocChecklistRow(String name, String note, bool isChecked, Color textCol, Color mutedCol) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isChecked) {
            _checkedDocs.remove(name);
          } else {
            _checkedDocs.add(name);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF15803D) : Colors.transparent,
                border: Border.all(color: isChecked ? const Color(0xFF15803D) : _theme.getBorderColor(context), width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 10) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700)),
                  Text(note, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareRow(String label, String value, Color textCol, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700).copyWith(fontFamily: 'Georgia')),
          Text(value, style: AppTextStyles.dmSans(size: 10.5, color: isGold ? const Color(0xFFD97706) : const Color(0xFF15803D), weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildCodeRow(String key, String value, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x3393C5FD)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(fontSize: 9.5, color: textCol, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 9.5, color: textCol, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
