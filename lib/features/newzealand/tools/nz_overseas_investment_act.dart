// lib/features/newzealand/tools/nz_overseas_investment_act.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZOverseasInvestmentAct extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZOverseasInvestmentAct({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZOverseasInvestmentAct> createState() => _NZOverseasInvestmentActState();
}

class _NZOverseasInvestmentActState extends ConsumerState<NZOverseasInvestmentAct> {
  String _nationality = '';
  String _propType = 'residential';
  String _purpose = 'live';

  bool _showResult = false;

  final Map<String, Map<String, String>> _rules = {
    'nz_citizen': {
      'cls': 'allowed',
      'title': '✅ You Can Buy Freely',
      'text': 'As a NZ citizen, you can purchase any residential or other property in New Zealand without restriction. No OIO consent required.',
    },
    'nz_pr': {
      'cls': 'allowed',
      'title': '✅ You Can Buy Freely',
      'text': 'As a NZ Permanent Resident, you can purchase any residential property in NZ without OIO consent. Same rights as citizens.',
    },
    'australia': {
      'cls': 'allowed',
      'title': '✅ Allowed – Australia FTA Exemption',
      'text': 'Australian citizens and permanent residents are exempt from the foreign buyer ban under the CER/FTA. You can purchase NZ residential property without OIO consent. Note: farmland over certain thresholds may still require consent.',
    },
    'singapore': {
      'cls': 'allowed',
      'title': '✅ Allowed – Singapore FTA Exemption',
      'text': 'Singaporean citizens are exempt under the NZ-Singapore Closer Economic Partnership. Residential property purchase allowed without OIO consent for standard residential land.',
    },
    'uk_fta': {
      'cls': 'conditional',
      'title': '✅ Generally Allowed – UK FTA 2023',
      'text': 'Under the NZ-UK Free Trade Agreement (effective Feb 2023), UK citizens have expanded rights to purchase NZ residential property. Similar to Australian exemption. Verify with OIO or a solicitor for high-value or sensitive land.',
    },
    'eu_other': {
      'cls': 'restricted',
      'title': '🚫 BANNED – OIA Applies',
      'text': 'Most foreign nationals are banned from purchasing NZ residential land under the 2018 OIA amendment. You may still be able to purchase commercial property or apply for OIO consent for specific purposes (e.g., new residential development). Always seek NZ legal advice before proceeding. Contact OIO: 04 462 4699.',
    },
    'nri_work_visa': {
      'cls': 'conditional',
      'title': '⚠️ Conditional – OIO Consent Required',
      'text': 'NZ visa holders (work, student, etc.) are generally not permitted to purchase residential property unless they obtain OIO consent. Exception: buying to live in as your principal place of residence while on your visa — but you must sell when your visa expires. Apply at oio.govt.nz.',
    },
  };

  void _saveEligibility() async {
    if (_nationality.isEmpty) return;
    final rule = _rules[_nationality]!;
    final isAllowed = rule['cls'] == 'allowed';
    final isConditional = rule['cls'] == 'conditional';

    final labelCtrl = TextEditingController(text: 'OIA Eligibility Check');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_overseas_investment_act'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Eligibility',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving foreign buyer status check:\nStatus: ${rule["title"]}',
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
                hintText: 'Label (e.g. My Visa Eligibility Check)',
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
        calcType: 'OIA Eligibility',
        inputs: {
          'nationalityIndex': _nationality == 'nz_citizen'
              ? 0.0
              : _nationality == 'nz_pr'
                  ? 1.0
                  : _nationality == 'australia'
                      ? 2.0
                      : _nationality == 'singapore'
                          ? 3.0
                          : _nationality == 'uk_fta'
                              ? 4.0
                              : _nationality == 'eu_other'
                                  ? 5.0
                                  : 6.0,
          'purposeIndex': _purpose == 'live' ? 0.0 : (_purpose == 'invest' ? 1.0 : 2.0),
        },
        results: {
          'isAllowed': isAllowed ? 1.0 : 0.0,
          'isConditional': isConditional ? 1.0 : 0.0,
          'isRestricted': rule['cls'] == 'restricted' ? 1.0 : 0.0,
        },
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Eligibility result saved to profile!'),
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
    final borderCol = theme.getBorderColor(context);

    // Current selection result
    final currentRule = _nationality.isNotEmpty ? _rules[_nationality] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip header replica
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
              _buildStripItem('Status', 'BANNED', 'Foreign buyers', const Color(0xFFC0392B)),
              _buildStripItem('Since', '2018', 'OIA reform', const Color(0xFFD4A017)),
              _buildStripItem('OIO Cases', '~150', 'Per year', Colors.white),
              _buildStripItem('Fine', '\$500K+', 'Max penalty', const Color(0xFFC0392B)),
            ],
          ),
        ),

        // Section Overview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'legislation.govt.nz →',
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

        // Hero card
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
                'OVERSEAS INVESTMENT ACT 2005 (AS AMENDED 2018 & 2020)',
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white60,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'Foreign Buyers '),
                    TextSpan(text: 'Banned', style: TextStyle(color: Color(0xFFFCA5A5))),
                    TextSpan(text: ' in NZ'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Since August 2018, most overseas persons are prohibited from purchasing residential land in New Zealand. The ban was a Labour government policy to improve housing affordability for New Zealanders.',
                style: AppTextStyles.dmSans(size: 10, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildHeroStat('Effective Date', 'Aug 2018', const Color(0xFFD4A017))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeroStat('Exempt AU/SG', 'FTA rules', Colors.white)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeroStat('OIO Consent', 'Required', const Color(0xFFFCA5A5))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Eligibility Checker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Can I Buy Property in NZ?',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'OIO Guide →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Checker Card
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
              Text('🔍 Eligibility Checker – Overseas Investment Act', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 14),

              _buildDropdown(
                label: 'Your Nationality / Residency Status',
                value: _nationality,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Select your status…')),
                  DropdownMenuItem(value: 'nz_citizen', child: Text('NZ Citizen')),
                  DropdownMenuItem(value: 'nz_pr', child: Text('NZ Permanent Resident')),
                  DropdownMenuItem(value: 'australia', child: Text('Australian Citizen / PR')),
                  DropdownMenuItem(value: 'singapore', child: Text('Singapore Citizen')),
                  DropdownMenuItem(value: 'uk_fta', child: Text('UK Citizen (post-FTA 2023)')),
                  DropdownMenuItem(value: 'eu_other', child: Text('EU / Other foreign national')),
                  DropdownMenuItem(value: 'nri_work_visa', child: Text('NZ Work Visa holder')),
                ],
                onChanged: (val) => setState(() => _nationality = val!),
              ),
              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Property Type',
                value: _propType,
                items: const [
                  DropdownMenuItem(value: 'residential', child: Text('Residential Land / House')),
                  DropdownMenuItem(value: 'farmland', child: Text('Farmland / Agricultural')),
                  DropdownMenuItem(value: 'sensitive', child: Text('Sensitive Land (foreshore/seabed)')),
                  DropdownMenuItem(value: 'commercial', child: Text('Commercial Property')),
                ],
                onChanged: (val) => setState(() => _propType = val!),
              ),
              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Purchase Purpose',
                value: _purpose,
                items: const [
                  DropdownMenuItem(value: 'live', child: Text('To live in as primary home')),
                  DropdownMenuItem(value: 'invest', child: Text('Investment / rental')),
                  DropdownMenuItem(value: 'develop', child: Text('Development / build new homes')),
                ],
                onChanged: (val) => setState(() => _purpose = val!),
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: () => setState(() => _showResult = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🇳🇿 Check My Eligibility',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),

              if (_showResult && currentRule != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: currentRule['cls'] == 'allowed'
                        ? const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)])
                        : (currentRule['cls'] == 'restricted'
                            ? const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)])
                            : const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)])),
                    border: Border.all(
                      color: currentRule['cls'] == 'allowed'
                          ? const Color(0xFF6EE7B7)
                          : (currentRule['cls'] == 'restricted' ? const Color(0xFFFCA5A5) : const Color(0xFFF59E0B)),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentRule['title']!,
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: currentRule['cls'] == 'allowed'
                              ? const Color(0xFF065F46)
                              : (currentRule['cls'] == 'restricted' ? const Color(0xFFB91C1C) : const Color(0xFF92400E)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentRule['text']!,
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: currentRule['cls'] == 'allowed'
                              ? const Color(0xFF047857)
                              : (currentRule['cls'] == 'restricted' ? const Color(0xFF991B1B) : const Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_showResult && currentRule != null) ...[
          ElevatedButton(
            onPressed: _saveEligibility,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📥  ', style: TextStyle(fontSize: 14, color: Colors.white)),
                Text(
                  'Save Eligibility Result',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Who Can Buy Detail Cards
        Text('Buyer Status & Property Rights', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _buildStatusRow('🇳🇿', 'NZ Citizens & Permanent Residents', 'No restrictions · Can purchase any property anywhere in NZ', 'ALLOWED', const Color(0xFFECFDF5), const Color(0xFF065F46)),
              _buildStatusRow('🇦🇺', 'Australian & Singapore Citizens', 'Exempt via FTA — can buy residential property · OIO not required for standard residential', 'EXEMPT', const Color(0xFFECFDF5), const Color(0xFF065F46)),
              _buildStatusRow('🇬🇧', 'UK Citizens (post FTA Feb 2023)', 'UK-NZ FTA provisions · residential purchases generally permitted · check OIO for high-value', 'FTA', const Color(0xFFFFFBEB), const Color(0xFF92400E)),
              _buildStatusRow('🛂', 'NZ Work / Student Visa Holders', 'Generally banned from purchasing residential · exceptions: buying to live in while visa current — requires OIO consent', 'OIO REQ', const Color(0xFFFFFBEB), const Color(0xFF92400E)),
              _buildStatusRow('🚫', 'Other Foreign Nationals', 'Banned from purchasing residential land · commercial property still generally available · farmland requires OIO consent', 'BANNED', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Consent Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OIO Consent Statistics 2024',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'OIO Annual Report →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
              Text('📋 Overseas Investment Office (OIO) – 2024', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  _buildStatBox('Applications received', '148', 'FY 2024'),
                  _buildStatBox('Applications approved', '112', '75.7% approval rate'),
                  _buildStatBox('Avg processing time', '62 days', 'Working days'),
                  _buildStatBox('Total value approved', '\$3.4B', 'NZD investment'),
                ],
              ),
              const SizedBox(height: 16),
              Text('Approved Investments by Type (2024)', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _OIOPiePainter(isDark: isDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem('Farmland (40%)', const Color(0xFF1A6B4A)),
                        _buildLegendItem('Commercial (20%)', const Color(0xFF0D9488)),
                        _buildLegendItem('Forestry (10%)', const Color(0xFFD4A017)),
                        _buildLegendItem('Other Sensitive (12%)', const Color(0xFFC0392B)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Timeline
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OIA Legislative History',
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
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📜 Key Legal Milestones', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 16),
              _buildTimelineItem('05', 'Overseas Investment Act 2005', 'Original framework established · required OIO consent for sensitive land purchases by overseas persons', const Color(0xFF0D3B2E)),
              _buildTimelineItem('18', '2018 Amendment – Residential Ban', 'Labour government banned most overseas persons from purchasing residential land · effective 22 October 2018', const Color(0xFFC0392B)),
              _buildTimelineItem('20', '2020 Amendment – Streamlined', 'Simplified OIO consent process · introduced fast-track for lower-risk investments · new COVID provisions', const Color(0xFFC0392B)),
              _buildTimelineItem('23', 'UK FTA 2023 – New Exemptions', 'NZ-UK Free Trade Agreement granted UK citizens similar rights to Australians for residential property', const Color(0xFFD4A017)),
              _buildTimelineItem('25', '2025 – Act Remains in Force', 'National-led coalition reviewing OIA · no major changes announced as of Q1 2025 · ban remains', const Color(0xFFD4A017), isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Key penalties breach warning banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Legal Consequences of Non-Compliance',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: const Color(0xFFB91C1C)),
              ),
              const SizedBox(height: 10),
              _buildPenaltyRow('💰', 'Civil penalties up to \$500,000 per breach for individuals. Companies face up to \$5 million.'),
              const SizedBox(height: 8),
              _buildPenaltyRow('🏠', 'Forced sale orders – Courts can order disposal of the property, often at a loss.'),
              const SizedBox(height: 8),
              _buildPenaltyRow('⚖️', 'Criminal liability – Deliberate breaches can result in criminal prosecution under the OIA 2005.'),
              const SizedBox(height: 8),
              _buildPenaltyRow('📞', 'Always seek legal advice before purchasing if you are not a NZ citizen or permanent resident. Contact OIO: 04 462 4699.'),
            ],
          ),
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
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          height: 38,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: widget.theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: isDark ? const Color(0xFF141C33) : Colors.white,
              style: AppTextStyles.dmSans(size: 12, color: widget.theme.getTextColor(context), weight: FontWeight.bold),
              icon: Icon(Icons.arrow_drop_down, color: widget.theme.getTextColor(context), size: 18),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String emoji, String title, String desc, String badgeText, Color badgeBg, Color badgeTextCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.theme.getBorderColor(context), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: badgeTextCol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String val, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(val, style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: widget.theme.primaryColor)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String step, String title, String desc, Color dotColor, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                step,
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: Colors.white),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: widget.theme.getBorderColor(context)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), height: 1.4)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltyRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF991B1B), height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _OIOPiePainter extends CustomPainter {
  final bool isDark;
  const _OIOPiePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const strokeW = 14.0;
    final ringRadius = radius - strokeW / 2;

    final basePaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    // Farmland: 40% = 144 deg (starts at -90deg)
    final farmPaint = Paint()
      ..color = const Color(0xFF1A6B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawArc(rect, -3.14159 / 2, 0.40 * 2 * 3.14159, false, farmPaint);

    // Commercial: 20% = 72 deg
    final commPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawArc(rect, -3.14159 / 2 + 0.40 * 2 * 3.14159, 0.20 * 2 * 3.14159, false, commPaint);

    // Forestry: 10% = 36 deg
    final forestPaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawArc(rect, -3.14159 / 2 + 0.60 * 2 * 3.14159, 0.10 * 2 * 3.14159, false, forestPaint);

    // Other sensitive: 12% = 43.2 deg
    final otherPaint = Paint()
      ..color = const Color(0xFFC0392B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawArc(rect, -3.14159 / 2 + 0.70 * 2 * 3.14159, 0.12 * 2 * 3.14159, false, otherPaint);

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '2024',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0A0F0D),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -10));

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'OIO Data',
        style: TextStyle(
          fontSize: 7,
          color: isDark ? Colors.white54 : const Color(0xFF4A6358),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas, center + Offset(-subPainter.width / 2, 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
