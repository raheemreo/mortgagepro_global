// lib/features/india/tools/in_fema_compliance.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INFEMACompliance extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INFEMACompliance({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INFEMACompliance> createState() => _INFEMAComplianceState();
}

class _INFEMAComplianceState extends ConsumerState<INFEMACompliance> {
  String _activeTab = 'nri'; // 'nri', 'foreign', 'lrs'

  void _saveFemaSnapshot() async {
    final labelCtrl = TextEditingController(text: 'FEMA Compliance Guide');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Compliance Guide', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving FEMA compliance bookmark for: ${_activeTab.toUpperCase()}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. FEMA Property Rules)',
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
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'FEMA Compliance Bookmark';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'FEMA Compliance Guide',
        inputs: {
          'activeTab': _activeTab == 'nri' ? 0.0 : (_activeTab == 'foreign' ? 1.0 : 2.0),
        },
        results: {
          'lrsLimitUSD': 250000.0,
          'nroRepatriationUSD': 1000000.0,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Compliance guide bookmarked!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
        // 1. Rate Strip Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('FEMA Act', '1999', 'In force', isSaffron: true),
              _buildRateStripItem('LRS Limit', '\$250K', 'Per FY', isGreen: true),
              _buildRateStripItem('Repatriation', '\$1.0M', 'Annual', isSaffron: true),
              _buildRateStripItem('Max Properties', '2 Res', 'NRI Limit'),
            ],
          ),
        ),

        // 2. Hero Banner
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
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🇮🇳 भारत • FOREIGN EXCHANGE MANAGEMENT ACT, 1999',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text('NRI Property Rules\nunder FEMA 2024–25',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildPillTag('NRI'),
                  const SizedBox(width: 4),
                  _buildPillTag('PIO'),
                  const SizedBox(width: 4),
                  _buildPillTag('OCI'),
                  const SizedBox(width: 4),
                  _buildPillTag('Foreigner'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildHeroSubStat('RBI Master Direction', 'No.13/2015-16'),
                  const SizedBox(width: 8),
                  _buildHeroSubStat('Last Updated', 'Jan 2025'),
                  const SizedBox(width: 8),
                  _buildHeroSubStat('Governing Body', 'RBI + ED'),
                ],
              )
            ],
          ),
        ),

        // 3. WARNING ALERT
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FEMA Violation Can Lead to Imprisonment',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF9A3412))),
                    const SizedBox(height: 4),
                    Text(
                      'Non-compliance can result in up to 3× the transaction amount as penalty + imprisonment up to 5 years. Always obtain RBI/AD bank approval before transacting.',
                      style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFC2410C), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. Tab Selector Bar
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTabBtn('NRI & OCI', 'nri'),
              _buildTabBtn('Foreigners', 'foreign'),
              _buildTabBtn('LRS limits', 'lrs'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. Tab Content
        _buildTabContent(),
        const SizedBox(height: 20),

        // 6. Annual Remittance Limits (Progress Bars)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Liberalised Remittance Scheme (LRS)', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Annual Remittance Limits – FY 2025–26', style: AppTextStyles.cardTitle(theme.getTextColor(context))),
              const SizedBox(height: 16),
              _buildRemitBar('LRS Outward Remittance (Resident Indian)', 'USD 250,000', 0.75, Colors.green),
              _buildRemitBar('NRI Repatriation from NRO Account', 'USD 1,000,000', 0.55, Colors.amber),
              _buildRemitBar('NRE Account — Full Repatriation', 'Unlimited', 1.0, Colors.green),
              _buildRemitBar('Property Sale Proceeds (held < 2 yrs)', 'USD 1,000,000', 0.45, Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 7. Compliance Checklist Grid (2x2)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('NRI Home Loan Compliance Checklist', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildChecklistCard('📋', 'Before Buying', [
              'Verify RERA registration',
              'Check title / encumbrance',
              'Open NRE/NRO account',
              'Obtain PAN (mandatory)',
            ]),
            _buildChecklistCard('🏦', 'Loan Disbursement', [
              'Route via AD bank',
              'INR mode only',
              'PoA notarised if abroad',
              'CIBIL score ≥ 700',
            ]),
            _buildChecklistCard('💸', 'EMI Repayment', [
              'NRE/NRO/FCNR debit',
              'Foreign remittance in',
              'Rental income for EMI',
              'Form 15CA for TDS',
            ]),
            _buildChecklistCard('🔄', 'On Property Sale', [
              'TDS: 20% (long-term)',
              'Form 15CA/15CB filing',
              'Max 2 repatriations',
              'AD bank clearance',
            ]),
          ],
        ),
        const SizedBox(height: 20),

        // 8. Process Timeline Steps
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('NRI Home Loan Process Timeline', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildTimelineItem('📄', 'Step 1 • Documents', 'Submit KYC + Income Proof', 'Passport, Visa, NRE/NRO statement, 6-month foreign salary slips, overseas employment letter, PAN card.', isFirst: true),
              _buildTimelineItem('🏦', 'Step 2 • Eligibility', 'Bank Assesses Loan-to-Value', 'NRI loans: max 80% LTV for ≤₹75L, 75% for ₹75L–₹5Cr. CIBIL score ≥700 required. Tenure max 30 years.'),
              _buildTimelineItem('✅', 'Step 3 • Sanction', 'Sanction Letter Issued', 'Valid 3–6 months. Interest rate linked to RLLR (Repo Rate + Spread). Power of Attorney notarised.'),
              _buildTimelineItem('🔑', 'Step 4 • Disbursement', 'Funds Released in INR Only', 'Credited directly to seller/builder. FEMA mandates INR disbursement via AD bank channel.'),
              _buildTimelineItem('💰', 'Step 5 • Repayment', 'NRE/NRO Auto-Debit EMI', 'EMI via inward remittance, NRE/NRO debit, or rental income from property (Section 24b applies).', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 9. FEMA Penalties Table
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('FEMA Penalties & Enforcement', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPenaltyRow('Unauthorized Purchase (Agri/Farm)', 'Buying restricted property without RBI approval', '3x Value', isRed: true),
              _buildPenaltyRow('Exceeding Repatriation Limit', 'Without RBI permission over USD 1M/year', '3x Amount', isRed: true),
              _buildPenaltyRow('Late Form 15CA/15CB Filing', 'Not filing before remittance abroad', '₹1L/day', isAmber: true),
              _buildPenaltyRow('Using Foreign Currency for Purchase', 'Direct payment in USD/GBP/AED etc.', 'Confiscation', isRed: true),
              _buildPenaltyRow('Criminal Offence (Serious Breach)', 'Willful FEMA violation', 'Up to 5 Yrs', isRed: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 10. Useful Links
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('Official Resources', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
        ),
        Column(
          children: [
            _buildResourceItem('🏛️', 'RBI FEMA Master Direction', 'No.13/2015-16 • Full text at rbi.org.in'),
            _buildResourceItem('📋', 'Form 15CA / 15CB Guide', 'Income Tax Portal • e-filing mandatory'),
            _buildResourceItem('⚖️', 'ED Adjudicating Authority', 'Enforcement Directorate • FEMA Sections 3–9'),
          ],
        ),
        const SizedBox(height: 20),

        // Bookmark Snapshot Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _saveFemaSnapshot,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
            icon: const Icon(Icons.bookmark, color: Colors.white, size: 16),
            label: Text('Bookmark FEMA Compliance Rules', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    }
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white)),
    );
  }

  Widget _buildHeroSubStat(String title, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(val, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, String code) {
    final isSelected = _activeTab == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = code),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color: isSelected ? Colors.white : widget.theme.getTextColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final theme = widget.theme;
    if (_activeTab == 'nri') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NRI & OCI Property Rights', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          _ruleItem('✅ ALLOWED', 'Residential & Commercial Properties', 'NRIs and OCIs can purchase unlimited residential and commercial properties in India without RBI approval.'),
          _ruleItem('❌ PROHIBITED', 'Agricultural & Plantation Land', 'Acquisition of agricultural land, farmhouses, or plantation properties is strictly prohibited unless received via inheritance.'),
          _ruleItem('💰 PAYMENTS', 'Approved Channels only', 'Payments must be funded via inward remittances (NRE/FCNR accounts) or NRO local balances. No foreign currency cash is allowed.'),
        ],
      );
    } else if (_activeTab == 'foreign') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foreign Nationals Regulations', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          _ruleItem('❌ GENERAL BAN', 'Non-Indian Origin Foreigners', 'Foreign nationals of non-Indian origin cannot buy real estate in India unless they reside in India for > 182 days in a financial year.'),
          _ruleItem('🔍 RBI PERMISSION', 'Special Approval Route', 'Prior approval from the Reserve Bank of India is required for any commercial/residential acquisition by a foreign national.'),
          _ruleItem('🤝 LEASE ROUTE', 'Long-term leases (Up to 5 years)', 'Foreigners can lease residential property for up to 5 years without prior RBI registration.'),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remittance & Repatriation limits', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          _ruleItem('💵 NRO REPATRIATION', '\$1,000,000 USD / Fiscal Year', 'NRIs can repatriate sale proceeds of up to two residential properties plus local rental income from NRO account up to \$1M USD per year.'),
          _ruleItem('🌿 LRS SCHEME', '\$250,000 USD / Fiscal Year', 'Resident Indians can remit up to \$250K USD annually overseas for education, travel, or foreign asset investments.'),
          _ruleItem('📜 DOCUMENTATION', 'Form 15CA & 15CB Certificates', 'Remittance requires Chartered Accountant certificates validating that local taxes (including capital gains tax) have been fully paid in India.'),
        ],
      );
    }
  }

  Widget _ruleItem(String status, String title, String desc) {
    final theme = widget.theme;
    Color statusCol = status.contains('ALLOWED') ? const Color(0xFF046A38) : const Color(0xFFFF6B00);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text(status, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: statusCol)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.45)),
        ],
      ),
    );
  }

  Widget _buildRemitBar(String label, String value, double fillPercent, Color barColor) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: theme.getTextColor(context))),
              Text(value, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: const Color(0xFFFF6B00))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 7,
              color: Colors.orange.withValues(alpha: 0.1),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fillPercent,
                child: Container(
                  color: barColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(String emoji, String title, List<String> items) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.map((item) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('✓ ', style: TextStyle(color: Color(0xFF046A38), fontSize: 10, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String dot, String step, String title, String desc, {bool isFirst = false, bool isLast = false}) {
    final theme = widget.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F48).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(dot, style: const TextStyle(fontSize: 14)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: const Color(0xFF0B1F48))),
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.4)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPenaltyRow(String name, String sub, String val, {bool isRed = false, bool isAmber = false}) {
    final theme = widget.theme;
    Color valCol = theme.getTextColor(context);
    if (isRed) valCol = Colors.red;
    if (isAmber) valCol = Colors.amber.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.4), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Text(val, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: valCol)),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String emoji, String title, String sub) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Text('›', style: AppTextStyles.dmSans(size: 20, color: theme.getMutedColor(context).withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
