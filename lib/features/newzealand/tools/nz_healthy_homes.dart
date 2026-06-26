// lib/features/newzealand/tools/nz_healthy_homes.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZHealthyHomes extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZHealthyHomes({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZHealthyHomes> createState() => _NZHealthyHomesState();
}

class _NZHealthyHomesState extends ConsumerState<NZHealthyHomes> {
  String _propType = 'House';
  String _buildYear = '1978–1999';
  String _region = 'Canterbury';

  // Section Expansion States
  final Map<String, bool> _expanded = {
    'heating': false,
    'insulation': false,
    'ventilation': false,
    'moisture': false,
    'draught': false,
  };

  // State of all 13 checkboxes (true=checked, false=unchecked/fail)
  final Map<String, bool> _chkState = {
    'chk-h1': false, 'chk-h2': true,  'chk-h3': true,
    'chk-i1': true,  'chk-i2': true,  'chk-i3': true,
    'chk-v1': true,  'chk-v2': true,
    'chk-m1': false, 'chk-m2': false, 'chk-m3': false,
    'chk-d1': true,  'chk-d2': true,
  };

  final Map<String, List<String>> _sectionItems = {
    'heating':    ['chk-h1', 'chk-h2', 'chk-h3'],
    'insulation': ['chk-i1', 'chk-i2', 'chk-i3'],
    'ventilation':['chk-v1', 'chk-v2'],
    'moisture':   ['chk-m1', 'chk-m2', 'chk-m3'],
    'draught':    ['chk-d1', 'chk-d2'],
  };

  void _toggleChk(String id) {
    setState(() {
      _chkState[id] = !(_chkState[id] ?? false);
    });
  }

  void _runFullCheck() {
    setState(() {
      _expanded.updateAll((key, value) => true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Compliance check complete! Review each standard below.',
            style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveReport() async {
    final passed = _chkState.values.where((v) => v).length;
    final pct = (passed / 13 * 100).round();

    final labelCtrl = TextEditingController(text: 'Healthy Homes Report');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Compliance Report',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving HHS Report:\nProperty: $_propType · Region: $_region\nCompliance Score: $pct%',
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
                hintText: 'Label (e.g. 14 Grey St HHS Check)',
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
        calcType: 'Healthy Homes Report',
        inputs: {
          'propTypeIndex': _propType == 'House'
              ? 0.0
              : (_propType == 'Apartment' ? 1.0 : (_propType == 'Unit' ? 2.0 : 3.0)),
          'buildYearIndex': _buildYear == 'Pre-1978'
              ? 0.0
              : (_buildYear == '1978–1999'
                  ? 1.0
                  : (_buildYear == '2000–2007' ? 2.0 : 3.0)),
          'regionIndex': _region == 'Auckland'
              ? 0.0
              : (_region == 'Wellington'
                  ? 1.0
                  : (_region == 'Canterbury' ? 2.0 : (_region == 'Otago' ? 3.0 : 4.0))),
        },
        results: {
          'complianceScore': pct.toDouble(),
          'passedStandardsCount': (_getSummaryStats()['pass'] ?? 0).toDouble(),
        },
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Compliance report saved to profile!'),
            backgroundColor: widget.theme.primaryColor,
          ),
        );
      }
    }
  }

  Map<String, int> _getSummaryStats() {
    int pass = 0, part = 0, fail = 0;
    _sectionItems.forEach((sec, items) {
      final p = items.where((i) => _chkState[i] ?? false).length;
      final t = items.length;
      if (p == t) {
        pass++;
      } else if (p == 0) {
        fail++;
      } else {
        part++;
      }
    });
    return {'pass': pass, 'part': part, 'fail': fail};
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final borderCol = theme.getBorderColor(context);

    // Compute compliance percentage
    final passedItems = _chkState.values.where((v) => v).length;
    final pct = (passedItems / 13 * 100).round();

    final summary = _getSummaryStats();

    // Map section checkmark fractions for radar chart
    final List<double> radarFractions = _sectionItems.keys.map((sec) {
      final items = _sectionItems[sec]!;
      final p = items.where((i) => _chkState[i] ?? false).length;
      return p / items.length;
    }).toList();

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
              _buildStripItem('Deadline', 'Jul 2025', 'All Rentals', const Color(0xFFF5D060)),
              _buildStripItem('Fine Max', '\$7,200', 'Per breach', const Color(0xFFFCA5A5)),
              _buildStripItem('Standards', '5', 'Categories', Colors.white),
              _buildStripItem('Authority', 'MBIE', 'Min. Business', const Color(0xFFF5D060)),
            ],
          ),
        ),

        // Section property details
        Text('Your Rental Property', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),

        // Property setup grid
        Row(
          children: [
            Expanded(
              child: _buildPropertySetupBox(
                label: 'Property Type',
                value: _propType,
                items: const ['House', 'Apartment', 'Unit', 'Townhouse'],
                onChanged: (val) => setState(() => _propType = val!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPropertySetupBox(
                label: 'Build Year',
                value: _buildYear,
                items: const ['Pre-1978', '1978–1999', '2000–2007', '2008+'],
                onChanged: (val) => setState(() => _buildYear = val!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPropertySetupBox(
                label: 'Region',
                value: _region,
                items: const ['Auckland', 'Wellington', 'Canterbury', 'Otago', 'Other'],
                onChanged: (val) => setState(() => _region = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Hero compliance checker
        Container(
          padding: const EdgeInsets.all(19),
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
                'HEALTHY HOMES STANDARDS · HHS 2019 (AMENDED 2021)',
                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                'Rental Compliance Checker\nfor NZ Landlords',
                style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: CustomPaint(
                      painter: _HHSDonutPainter(pct: pct, isDark: isDark),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Compliance Score', style: AppTextStyles.dmSans(size: 9, color: Colors.white54)),
                        Text('$pct%', style: AppTextStyles.dmSans(size: 28, weight: FontWeight.w800, color: const Color(0xFFF5D060))),
                        Text(
                          pct == 100
                              ? '✅ Fully Compliant'
                              : (pct >= 60 ? '⚠ Partially Compliant' : '✗ Non-Compliant'),
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.bold,
                            color: pct == 100
                                ? const Color(0xFF6EE7B7)
                                : (pct >= 60 ? const Color(0xFFF5D060) : const Color(0xFFFCA5A5)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Tick items below to update', style: AppTextStyles.dmSans(size: 9, color: Colors.white38)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _runFullCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('🏠 Run Full Compliance Check', style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A017),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('💾 Save Compliance Report', style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Compliance Summary
        Text('Compliance Summary', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('${summary["pass"]}', 'Passing', theme.primaryColor)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryBox('${summary["part"]}', 'In Progress', const Color(0xFFD4A017))),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryBox('${summary["fail"]}', 'Non-Compliant', const Color(0xFFC0392B))),
          ],
        ),
        const SizedBox(height: 20),

        // Standards checklist
        Text('Five Standards Checklist', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),

        // 1. Heating
        _buildStandardCard(
          secCode: 'heating',
          emoji: '🌡️',
          title: 'Heating Standard',
          req: 'Must heat main living room to min 18°C',
          iconColorClass: 'green',
          items: [
            _buildCheckRow('chk-h1', 'Fixed heating device in main living area', 'Must be a fixed heater (heat pump, flued gas, wood pellet burner). Portable heaters do NOT comply. Must achieve 18°C at 0°C outside.', '✓ Required for ALL rentals from 1 July 2021'),
            _buildCheckRow('chk-h2', 'Minimum heating capacity met', 'Calculated via MBIE Heating Assessment Tool. Depends on room size, insulation rating, and climate zone. NZ has 3 climate zones.', '✓ Use MBIE online calculator to confirm kW capacity'),
            _buildCheckRow('chk-h3', 'Heater energy efficiency ≥ 1.0 kW input cap', 'Low-emission heaters only in Clean Air Zones (parts of Auckland, Christchurch, Dunedin, Rotorua). No open fires or pre-2005 solid fuel burners.', '⚠ Check your council boundaries'),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Insulation
        _buildStandardCard(
          secCode: 'insulation',
          emoji: '🧱',
          title: 'Insulation Standard',
          req: 'Ceiling & underfloor insulation where practicable',
          iconColorClass: 'blue',
          items: [
            _buildCheckRow('chk-i1', 'Ceiling insulation installed', 'Min R-value: R2.9 (North Island), R3.3 (South Island). Must be installed in all accessible ceiling spaces. Existing compliant insulation (pre-2019) may be accepted if in reasonable condition.', '✓ Compliant R-values confirmed'),
            _buildCheckRow('chk-i2', 'Underfloor insulation (if suspended floor)', 'Min R1.3 (all of NZ). Must be installed if underfloor space is accessible. Concrete slab floors are exempt. Rigid board or bulk insulation acceptable.', '✓ Underfloor verified or slab foundation'),
            _buildCheckRow('chk-i3', 'Insulation statement in tenancy agreement', 'Landlords must include a statement about existing insulation (location, type, condition, R-value) in all new tenancy agreements from 1 July 2016.', '✓ Tenancy agreement includes statement'),
          ],
        ),
        const SizedBox(height: 10),

        // 3. Ventilation
        _buildStandardCard(
          secCode: 'ventilation',
          emoji: '💨',
          title: 'Ventilation Standard',
          req: 'Openable windows + extractor fans',
          iconColorClass: 'teal',
          items: [
            _buildCheckRow('chk-v1', 'Openable windows in all habitable rooms', 'Openable area ≥ 5% of floor area. Includes bedrooms, living areas, dining rooms. Garages and storage rooms excluded. Windows must open directly to outside air.', '✓ All habitable rooms have openable windows'),
            _buildCheckRow('chk-v2', 'Extractor fans in kitchen & bathroom(s)', 'Kitchen: continuous fan OR rangehood venting outside. Bathroom/laundry: minimum 25L/s (bathrooms with windows may be exempt if window ≥ 1.5% of floor area).', '✓ Extractor fans installed and venting externally'),
          ],
        ),
        const SizedBox(height: 10),

        // 4. Moisture & Drainage
        _buildStandardCard(
          secCode: 'moisture',
          emoji: '💧',
          title: 'Moisture & Drainage Standard',
          req: 'Efficient drainage + ground moisture barriers',
          iconColorClass: 'orange',
          items: [
            _buildCheckRow('chk-m1', 'Efficient drainage systems present', 'Gutters, downpipes, and drains must be in good working order. Paths and paving must direct water away from the building. No ponding near foundations.', '✗ Guttering requires repair — action needed'),
            _buildCheckRow('chk-m2', 'Ground moisture barrier (if suspended floor)', 'A polythene barrier (min 0.25mm) must cover ≥ 80% of the ground under the floor. Must overlap seams by 200mm. Slab foundations are exempt from this requirement.', '✗ Moisture barrier status unknown — inspection needed'),
            _buildCheckRow('chk-m3', 'No unreasonable moisture or dampness', 'Rental must be maintained free of damp. Landlord responsible for structural causes of moisture. Tenant responsible for lifestyle moisture.', '⚠ Inspect for signs of damp or mould'),
          ],
        ),
        const SizedBox(height: 10),

        // 5. Draught Stopping
        _buildStandardCard(
          secCode: 'draught',
          emoji: '🪟',
          title: 'Draught Stopping Standard',
          req: 'Seal unreasonable gaps in walls, ceilings & floors',
          iconColorClass: 'gold',
          items: [
            _buildCheckRow('chk-d1', 'No unreasonable gaps in building envelope', 'All gaps in walls, ceilings, floors, and around windows/doors that allow unreasonable draught must be stopped. Excludes intentional ventilation openings.', '✓ No significant draught gaps identified'),
            _buildCheckRow('chk-d2', 'Unused fireplace openings blocked', 'Unused chimneys or fireplace openings must be blocked or fitted with a draught excluder if they cause unreasonable draught. Functional fireplaces are exempt.', '✓ No unused fireplaces or openings blocked'),
          ],
        ),
        const SizedBox(height: 20),

        // Compliance Radar Chart
        Text('Your Property · Compliance Radar', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
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
              AspectRatio(
                aspectRatio: 260 / 220,
                child: CustomPaint(
                  painter: _HealthyRadarPainter(fractions: radarFractions, isDark: isDark),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRadarLegend('Compliant', theme.primaryColor),
                  const SizedBox(width: 14),
                  _buildRadarLegend('Partial', const Color(0xFFD4A017)),
                  const SizedBox(width: 14),
                  _buildRadarLegend('Non-Compliant', const Color(0xFFC0392B)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Penalty box
        Text('Non-Compliance Penalties', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Financial Penalties for Landlords', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                      Text('Residential Tenancies Act 1986 · MBIE enforcement', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPenaltyRow('Max fine per breach', '\$7,200'),
              _buildPenaltyRow('Exemplary damages (Tribunal)', 'Up to \$50,000'),
              _buildPenaltyRow('Tenant can apply for', 'Rent reduction'),
              _buildPenaltyRow('Enforcement body', 'Tenancy Tribunal'),
              _buildPenaltyRow('Compliance deadline (all rentals)', '1 July 2025'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Timeline Rollout
        Text('Compliance Timeline', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
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
              Text('HHS Rollout Phases (NZ 2021–2025)', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 16),
              _buildTimelineItem('1 July 2021', 'Phase 1 — New & Renewed Tenancies', 'All 5 standards apply to new tenancies and renewals from this date.', isDone: true),
              _buildTimelineItem('1 July 2023', 'Phase 2 — Social Housing Providers', 'Kāinga Ora and registered Community Housing Providers must comply.', isDone: true),
              _buildTimelineItem('1 July 2025', 'Phase 3 — ALL Private Rentals', 'Every private rental in NZ must meet all 5 Healthy Homes Standards regardless of tenancy start date.', isActive: true),
              _buildTimelineItem('Ongoing', 'MBIE Compliance Audits', 'MBIE may request compliance statements. Non-compliance can result in Tenancy Tribunal action.', isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // National stats
        Text('NZ Rental Compliance Stats', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
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
              Text('NZ Rental Stock Compliance by Standard (2024)', style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 14),
              _buildStatBar('Insulation', 0.88, theme.primaryColor),
              const SizedBox(height: 10),
              _buildStatBar('Ventilation', 0.79, theme.primaryColor),
              const SizedBox(height: 10),
              _buildStatBar('Heating', 0.67, const Color(0xFFD4A017)),
              const SizedBox(height: 10),
              _buildStatBar('Draught Stop', 0.72, const Color(0xFFD4A017)),
              const SizedBox(height: 10),
              _buildStatBar('Moisture', 0.54, const Color(0xFFC0392B)),
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

  Widget _buildPropertySetupBox({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 3),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
              dropdownColor: isDark ? const Color(0xFF141C33) : Colors.white,
              style: AppTextStyles.dmSans(size: 12, color: widget.theme.getTextColor(context), weight: FontWeight.w800),
              icon: const SizedBox.shrink(),
              alignment: Alignment.center,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String val, String lbl, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(val, style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w800, color: col)),
          const SizedBox(height: 3),
          Text(lbl, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context), weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStandardCard({
    required String secCode,
    required String emoji,
    required String title,
    required String req,
    required String iconColorClass,
    required List<Widget> items,
  }) {
    final isOpen = _expanded[secCode] ?? false;
    final theme = widget.theme;

    // Determine badge based on item checklist state
    final secIds = _sectionItems[secCode]!;
    final passed = secIds.where((id) => _chkState[id] ?? false).length;
    final total = secIds.length;

    String badge = 'CHECK';
    Color badgeBg = const Color(0xFFFFF7ED);
    Color badgeTxt = const Color(0xFFC2410C);

    if (passed == total) {
      badge = 'PASS';
      badgeBg = const Color(0xFFECFDF5);
      badgeTxt = const Color(0xFF065F46);
    } else if (passed == 0) {
      badge = 'FAIL';
      badgeBg = const Color(0xFFFEF2F2);
      badgeTxt = const Color(0xFFC0392B);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded[secCode] = !isOpen),
            child: Container(
              padding: const EdgeInsets.all(14),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: badgeBg,
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
                        Text(title, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context))),
                        Text(req, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(badge, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: badgeTxt)),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: items),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckRow(String id, String title, String spec, String tag) {
    final active = _chkState[id] ?? false;
    final isComply = tag.contains('✓') || tag.contains('Compliant');
    final isNon = tag.contains('✗');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleChk(id),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: active ? widget.theme.primaryColor : Colors.transparent,
                border: Border.all(color: active ? widget.theme.primaryColor : Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: active ? const Icon(Icons.check, size: 12, color: Colors.white) : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(spec, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  tag,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.bold,
                    color: isComply
                        ? widget.theme.primaryColor
                        : (isNon ? const Color(0xFFC0392B) : const Color(0xFFD4A017)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarLegend(String label, Color col) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildPenaltyRow(String key, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x3BF59E0B), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: const Color(0xFF78350F))),
          Text(val, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFFB45309))),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String date, String event, String note, {bool isActive = false, bool isDone = false, bool isLast = false}) {
    final dotColor = isActive
        ? const Color(0xFFD4A017)
        : (isDone ? widget.theme.primaryColor : const Color(0xFFD1D5DB));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: const Color(0xFFD4A017).withValues(alpha: 0.25), spreadRadius: 3)]
                    : null,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: widget.theme.getBorderColor(context)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
                Text(event, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
                Text(note, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBar(String label, double widthPct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
        ),
        Expanded(
          child: Container(
            height: 9,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthPct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${(widthPct * 100).round()}%',
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: widget.theme.getMutedColor(context)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _HHSDonutPainter extends CustomPainter {
  final int pct;
  final bool isDark;

  const _HHSDonutPainter({required this.pct, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const strokeW = 10.0;
    final ringRadius = radius - strokeW / 2;

    final basePaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    final fillPaint = Paint()
      ..color = const Color(0xFFF5D060)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (pct / 100) * 2 * 3.14159;
    canvas.drawArc(rect, -3.14159 / 2, sweepAngle, false, fillPaint);

    // Draw center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$pct%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0A0F0D),
          fontFamily: 'Palatino',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HHSDonutPainter oldDelegate) => oldDelegate.pct != pct;
}

class _HealthyRadarPainter extends CustomPainter {
  final List<double> fractions; // 5 values: Heating, Insulation, Moisture, Ventilation, Draught
  final bool isDark;

  const _HealthyRadarPainter({required this.fractions, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double maxRadius = math.min(centerX, centerY) - 20;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0x220D3B2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw pentagon grid (3 rings)
    for (int ring = 1; ring <= 3; ring++) {
      final double r = maxRadius * (ring / 3);
      final Path p = Path();
      for (int i = 0; i < 5; i++) {
        final double angle = -math.pi / 2 + i * 2 * math.pi / 5;
        final double x = centerX + r * math.cos(angle);
        final double y = centerY + r * math.sin(angle);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      canvas.drawPath(p, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < 5; i++) {
      final double angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final double x = centerX + maxRadius * math.cos(angle);
      final double y = centerY + maxRadius * math.sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(x, y), gridPaint);
    }

    // Draw labels
    const labels = ['HEATING', 'INSULATION', 'MOISTURE', 'VENTILATION', 'DRAUGHT'];
    const aligns = [TextAlign.center, TextAlign.left, TextAlign.center, TextAlign.center, TextAlign.right];
    for (int i = 0; i < 5; i++) {
      final double angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final double x = centerX + (maxRadius + 12) * math.cos(angle);
      final double y = centerY + (maxRadius + 12) * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: i == 2 ? const Color(0xFFC0392B) : (isDark ? Colors.white70 : const Color(0xFF4A6358)),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: aligns[i],
      )..layout();

      double dx = x - textPainter.width / 2;
      double dy = y - textPainter.height / 2;
      if (i == 1) {
        dx = x;
      } else if (i == 4) {
        dx = x - textPainter.width;
      }
      textPainter.paint(canvas, Offset(dx, dy));
    }

    // Draw polygon
    if (fractions.length == 5) {
      final List<Offset> polyPts = [];
      for (int i = 0; i < 5; i++) {
        final double frac = fractions[i].clamp(0.1, 1.0); // Minimum fraction to avoid degenerate shapes
        final double r = maxRadius * frac;
        final double angle = -math.pi / 2 + i * 2 * math.pi / 5;
        final double x = centerX + r * math.cos(angle);
        final double y = centerY + r * math.sin(angle);
        polyPts.add(Offset(x, y));
      }

      final polyPath = Path()..moveTo(polyPts.first.dx, polyPts.first.dy);
      for (int i = 1; i < polyPts.length; i++) {
        polyPath.lineTo(polyPts[i].dx, polyPts[i].dy);
      }
      polyPath.close();

      final fillPaint = Paint()
        ..color = const Color(0x3B1A6B4A)
        ..style = PaintingStyle.fill;
      canvas.drawPath(polyPath, fillPaint);

      final strokePaint = Paint()
        ..color = const Color(0xFF1A6B4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(polyPath, strokePaint);

      // Draw dots
      final dotColors = [
        fractions[0] == 1.0 ? const Color(0xFF1A6B4A) : (fractions[0] > 0.0 ? const Color(0xFFD4A017) : const Color(0xFFC0392B)),
        fractions[1] == 1.0 ? const Color(0xFF1A6B4A) : (fractions[1] > 0.0 ? const Color(0xFFD4A017) : const Color(0xFFC0392B)),
        fractions[2] == 1.0 ? const Color(0xFF1A6B4A) : (fractions[2] > 0.0 ? const Color(0xFFD4A017) : const Color(0xFFC0392B)),
        fractions[3] == 1.0 ? const Color(0xFF1A6B4A) : (fractions[3] > 0.0 ? const Color(0xFFD4A017) : const Color(0xFFC0392B)),
        fractions[4] == 1.0 ? const Color(0xFF1A6B4A) : (fractions[4] > 0.0 ? const Color(0xFFD4A017) : const Color(0xFFC0392B)),
      ];

      for (int i = 0; i < 5; i++) {
        canvas.drawCircle(polyPts[i], 4.5, Paint()..color = dotColors[i]);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HealthyRadarPainter oldDelegate) =>
      oldDelegate.fractions != fractions || oldDelegate.isDark != isDark;
}
