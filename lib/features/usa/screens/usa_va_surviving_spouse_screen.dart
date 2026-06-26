// lib/features/usa/screens/usa_va_surviving_spouse_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAVaSurvivingSpouseScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAVaSurvivingSpouseScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAVaSurvivingSpouseScreen> createState() => _USAVaSurvivingSpouseScreenState();
}

class _USAVaSurvivingSpouseScreenState extends ConsumerState<USAVaSurvivingSpouseScreen> {
  static const _theme = CountryThemes.usa;

  // Form inputs
  String _selectedDeathCause = 'service'; // service, totaldis, mia, other
  String _selectedRemarriage = 'never'; // never, after57, before57
  String _selectedDicStatus = 'yes'; // yes, no

  // Checked documents
  final Set<String> _checkedDocs = {};

  // Outputs
  bool _calculated = false;
  String _resultTitle = '✅ Likely Eligible';
  String _resultSub = 'Apply for your COE using VA Form 26-1817 — DIC status streamlines processing';

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      final causeIdx = (inputs['deathCause'] ?? 0.0).toInt();
      _selectedDeathCause = causeIdx == 0 ? 'service' : (causeIdx == 1 ? 'totaldis' : (causeIdx == 2 ? 'mia' : 'other'));
      final remIdx = (inputs['remarriage'] ?? 0.0).toInt();
      _selectedRemarriage = remIdx == 0 ? 'never' : (remIdx == 1 ? 'after57' : 'before57');
      _selectedDicStatus = (inputs['dicStatus'] ?? 0.0) == 0.0 ? 'yes' : 'no';
      _calculate();
    } else {
      _calculate();
    }
  }

  void _calculate() {
    String title = '';
    String sub = '';

    if (_selectedRemarriage == 'before57') {
      title = '⚠️ Likely Not Eligible';
      sub = 'Remarriage before age 57 generally ends VA loan eligibility — confirm with VA';
    } else if (_selectedDeathCause == 'other') {
      title = '❓ Eligibility Unclear';
      sub = 'Speak with a VA-approved lender or Regional Loan Center to confirm your category';
    } else {
      title = '✅ Likely Eligible';
      sub = _selectedDicStatus == 'yes'
          ? 'Apply for your COE using VA Form 26-1817 — DIC status streamlines processing'
          : 'Apply for your COE using VA Form 26-1817 — extra documentation may be requested';
    }

    setState(() {
      _resultTitle = title;
      _resultSub = sub;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;

    double causeIdx = _selectedDeathCause == 'service' ? 0.0 : (_selectedDeathCause == 'totaldis' ? 1.0 : (_selectedDeathCause == 'mia' ? 2.0 : 3.0));
    double remIdx = _selectedRemarriage == 'never' ? 0.0 : (_selectedRemarriage == 'after57' ? 1.0 : 2.0);
    double dicIdx = _selectedDicStatus == 'yes' ? 0.0 : 1.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'VA Surviving Spouse Benefits',
      label: 'VA Spouse Check: ${_resultTitle.replaceAll("Likely ", "")}',
      currencyCode: 'USD',
      inputs: {
        'deathCause': causeIdx,
        'remarriage': remIdx,
        'dicStatus': dicIdx,
      },
      results: {
        'Eligible': _resultTitle.contains('Not Eligible') ? 0.0 : 1.0,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Surviving spouse eligibility saved!'),
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

    final documentList = [
      {'name': 'Veteran\'s DD Form 214', 'note': 'Discharge or separation papers of the deceased veteran'},
      {'name': 'Marriage License', 'note': 'To verify your relationship to the veteran'},
      {'name': 'Death Certificate', 'note': 'Confirms service-connected or qualifying death'},
      {'name': 'VA Form 26-1817', 'note': 'Request for Determination of Loan Guaranty Eligibility — Unmarried Surviving Spouses'},
      {'name': 'DIC Award Letter (if applicable)', 'note': 'Streamlines the process if you already receive DIC'},
    ];

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
                      const Text('🪖', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Surviving Spouse Benefits',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('VA home loan eligibility for spouses',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // summary strip
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
                  Expanded(child: _buildStripItem('Funding Fee', 'Exempt', '\$0 If Qualified', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Down Payment', '0%', 'Same as Veterans', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Benefit Window', 'Lifetime', 'No Expiration', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Note Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3F72).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1B3F72).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎖️ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Unremarried surviving spouses of veterans who died in service or from a service-connected cause may qualify for a VA-guaranteed home loan — \$0 down, no PMI, and typically no funding fee.',
                          style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF1B3F72), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Check Your Likely Eligibility'),

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
                        label: 'Circumstance of Death',
                        value: _selectedDeathCause,
                        items: const [
                          DropdownMenuItem(value: 'service', child: Text('Died on active duty or from service-connected cause')),
                          DropdownMenuItem(value: 'totaldis', child: Text('Rated totally disabled, died (any cause)')),
                          DropdownMenuItem(value: 'mia', child: Text('Missing in Action / POW 90+ days')),
                          DropdownMenuItem(value: 'other', child: Text('Other / not sure')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDeathCause = val);
                            _calculate();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField<String>(
                        label: 'Remarriage Status',
                        value: _selectedRemarriage,
                        items: const [
                          DropdownMenuItem(value: 'never', child: Text('Never remarried')),
                          DropdownMenuItem(value: 'after57', child: Text('Remarried at 57+, on/after Dec 16, 2003')),
                          DropdownMenuItem(value: 'before57', child: Text('Remarried before age 57')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRemarriage = val);
                            _calculate();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField<String>(
                        label: 'Receiving DIC Benefits?',
                        value: _selectedDicStatus,
                        items: const [
                          DropdownMenuItem(value: 'yes', child: Text('Yes')),
                          DropdownMenuItem(value: 'no', child: Text('No / Not Sure')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDicStatus = val);
                            _calculate();
                          }
                        },
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
                            Text('LIKELY VA LOAN ELIGIBILITY',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(_resultTitle,
                                style: AppTextStyles.playfair(size: 20, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(_resultSub,
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

                const SizedBox(height: 12),

                // savings banner
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF4C1D95)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Funding Fee Fully Waived',
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.w800, color: const Color(0xFFFCD34D)).copyWith(fontFamily: 'Georgia')),
                            const SizedBox(height: 2),
                            Text('On a \$450,000 loan, that\'s ~\$9,675 you don\'t pay at closing vs. a 1st-use veteran',
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Surviving Spouse vs. Standard VA Borrower'),

                // Comparison bar chart card
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
                      Text('⚖️ Surviving Spouse vs. Standard VA Borrower',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildCompareBarRow('Funding Fee Owed', 'Spouse \$0', 'Veteran ~2.15%', 0.02, 0.70, textCol),
                      _buildCompareBarRow('Down Payment Required', 'Spouse \$0', 'Conv. ~20%', 0.02, 0.80, textCol),
                      const SizedBox(height: 6),
                      Text('■ Navy = Surviving Spouse   |   ■ Amber = Comparison Borrower',
                          style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Breakdown Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                  children: [
                    _buildBreakdownCard('✅', 'Funding Fee', '\$0', 'If COE shows code 06/07', const Color(0xFF15803D), mutedCol),
                    _buildBreakdownCard('🏠', 'Min. Down Payment', '\$0', 'Same as veteran benefit', textCol, mutedCol),
                    _buildBreakdownCard('📋', 'Form Required', '26-1817', 'Determination of eligibility', textCol, mutedCol),
                    _buildBreakdownCard('⏳', 'Benefit Expiration', 'None', 'Lifetime benefit', textCol, mutedCol),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Documents You\'ll Likely Need'),

                // Document checklist
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
                      Text('📋 Document Checklist',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ...documentList.map((doc) {
                        final name = doc['name'] ?? '';
                        final note = doc['note'] ?? '';
                        final isChecked = _checkedDocs.contains(name);
                        return _buildDocChecklistRow(name, note, isChecked, textCol, mutedCol);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Key Eligibility Rules'),

                // Rules card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCompareRow('Service-Connected Death', '✅ Directly qualifies', textCol),
                      _buildCompareRow('MIA / POW 90+ Days', '✅ Qualifies', textCol),
                      _buildCompareRow('Remarried at 57+ (after 12/16/03)', '✅ Retains eligibility', textCol),
                      _buildCompareRow('Remarried Before Age 57', '⚡ Generally loses eligibility', textCol, isGold: true),
                      _buildCompareRow('Receiving DIC', '✅ Streamlines COE process', textCol),
                      _buildCompareRow('Not Receiving DIC', '⚡ More documentation needed', textCol, isGold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer note
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
                          'The "10-year rule": if the veteran was rated 100% Permanent and Total for at least 10 years before death, the surviving spouse generally qualifies for DIC — and the related VA loan benefit — even if the death itself wasn\'t service-connected.',
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
          label.toString().toUpperCase(),
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

  Widget _buildCompareBarRow(String title, String activeVal, String otherVal, double actRatio, double otherRatio, Color textCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600)),
              Text('$activeVal vs $otherVal', style: AppTextStyles.dmSans(size: 9.5, color: textCol, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F8),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // other bar (Gold/Amber)
              FractionallySizedBox(
                widthFactor: otherRatio,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // active bar (Navy)
              FractionallySizedBox(
                widthFactor: actRatio,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF4C1D95)]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String emoji, String label, String value, String sub, Color valColor, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: _theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15.5, color: valColor, weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
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
}
