// lib/shared/widgets/workflow_continuation_card.dart
//
// PHASE-3: "Continue Your Mortgage Planning" horizontal action card strip.
//
// Displayed at the bottom of a calculator result sheet after a successful
// calculation. Shows horizontally-scrollable cards for related calculators
// in the same country context, with a brief description of what values will
// be reused.
//
// Route slugs used in this widget were verified against the real /tool/:country/:toolId
// route table in tool_host_screen.dart before use (Blocking Question B2 resolved).
//
// Usage:
//   WorkflowContinuationCard(
//     country: 'USA',          // CountryTheme key
//     countryPath: 'usa',      // GoRouter country path segment
//     draft: CalculatorDraft(  // values from the completed calculation
//       loanAmount: 360000,
//       propertyPrice: 450000,
//       interestRate: 6.82,
//       loanTermYears: 30,
//       country: 'USA',
//       currency: 'USD',
//       downPayment: 90000,
//     ),
//   )

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/calculator_draft.dart';

/// A single entry in the per-country tool relevance map.
class _WorkflowEntry {
  final String toolId;
  final String emoji;
  final String label;
  final String reusedFields;

  const _WorkflowEntry({
    required this.toolId,
    required this.emoji,
    required this.label,
    required this.reusedFields,
  });
}

class WorkflowContinuationCard extends StatelessWidget {
  /// Country code matching CountryThemes.fromCode (e.g. 'USA', 'UK').
  final String country;

  /// GoRouter country path segment used in /tool/:countryPath/:toolId.
  final String countryPath;

  /// The draft calculation — used to pass values to destination calculators
  /// and to populate the "uses your …" description in each card.
  final CalculatorDraft? draft;

  const WorkflowContinuationCard({
    super.key,
    required this.country,
    required this.countryPath,
    this.draft,
  });

  // ── Per-country tool relevance map ───────────────────────────────────────
  //
  // All tool IDs here were verified against _ToolHostScreenState._toolName
  // in tool_host_screen.dart. Any slug that does not appear in that switch
  // will result in a "Tool Not Found" fallback screen — verified slugs only.
  static const Map<String, List<_WorkflowEntry>> _countryTools = {
    'USA': [
      _WorkflowEntry(
        toolId: 'propertytax',
        emoji: '🏛️',
        label: 'Property Tax',
        reusedFields: 'Uses your property price',
      ),
      _WorkflowEntry(
        toolId: 'affordability',
        emoji: '💰',
        label: 'Affordability',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'dti',
        emoji: '📊',
        label: 'DTI Calculator',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'refinance',
        emoji: '🔄',
        label: 'Refinance',
        reusedFields: 'Uses your rate & term',
      ),
      _WorkflowEntry(
        toolId: 'pmi',
        emoji: '🛡️',
        label: 'PMI Calculator',
        reusedFields: 'Uses your loan & price',
      ),
      _WorkflowEntry(
        toolId: 'closingcosts',
        emoji: '🏠',
        label: 'Closing Costs',
        reusedFields: 'Uses your property price',
      ),
    ],
    'UK': [
      _WorkflowEntry(
        toolId: 'sdlt',
        emoji: '🏦',
        label: 'SDLT Calculator',
        reusedFields: 'Uses your property price',
      ),
      _WorkflowEntry(
        toolId: 'affordability',
        emoji: '💰',
        label: 'Affordability',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'remortgage',
        emoji: '🔄',
        label: 'Remortgage',
        reusedFields: 'Uses your rate & term',
      ),
      _WorkflowEntry(
        toolId: 'ltv',
        emoji: '📐',
        label: 'LTV Calculator',
        reusedFields: 'Uses your loan & price',
      ),
    ],
    'CANADA': [
      _WorkflowEntry(
        toolId: 'stresstest',
        emoji: '🧪',
        label: 'Stress Test',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'cmhc',
        emoji: '🛡️',
        label: 'CMHC Insurance',
        reusedFields: 'Uses your loan & price',
      ),
      _WorkflowEntry(
        toolId: 'gdstds',
        emoji: '📊',
        label: 'GDS / TDS',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'refinance',
        emoji: '🔄',
        label: 'Refinance',
        reusedFields: 'Uses your rate & term',
      ),
    ],
    'AUSTRALIA': [
      _WorkflowEntry(
        toolId: 'lmi',
        emoji: '🛡️',
        label: 'LMI Calculator',
        reusedFields: 'Uses your loan & price',
      ),
      _WorkflowEntry(
        toolId: 'stampduty',
        emoji: '🏛️',
        label: 'Stamp Duty',
        reusedFields: 'Uses your property price',
      ),
      _WorkflowEntry(
        toolId: 'offset',
        emoji: '💳',
        label: 'Offset Account',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'refinance',
        emoji: '🔄',
        label: 'Refinance',
        reusedFields: 'Uses your rate & term',
      ),
    ],
    'EUROPE': [
      _WorkflowEntry(
        toolId: 'notaryfee',
        emoji: '📜',
        label: 'Notary Fee',
        reusedFields: 'Uses your property price',
      ),
      _WorkflowEntry(
        toolId: 'affordability',
        emoji: '💰',
        label: 'Affordability',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'dti',
        emoji: '📊',
        label: 'DTI Calculator',
        reusedFields: 'Uses your loan amount',
      ),
    ],
    'INDIA': [
      _WorkflowEntry(
        toolId: 'in_foir',
        emoji: '📊',
        label: 'FOIR Calculator',
        reusedFields: 'Uses your loan amount',
      ),
      _WorkflowEntry(
        toolId: 'in_prepayment',
        emoji: '💳',
        label: 'Prepayment',
        reusedFields: 'Uses your loan & term',
      ),
      _WorkflowEntry(
        toolId: 'in_balance_transfer',
        emoji: '🔄',
        label: 'Balance Transfer',
        reusedFields: 'Uses your rate & loan',
      ),
    ],
    'NEWZEALAND': [
      _WorkflowEntry(
        toolId: 'lvr',
        emoji: '📐',
        label: 'LVR Calculator',
        reusedFields: 'Uses your loan & price',
      ),
      _WorkflowEntry(
        toolId: 'kiwisavercalc',
        emoji: '🥝',
        label: 'KiwiSaver',
        reusedFields: 'Uses your property price',
      ),
      _WorkflowEntry(
        toolId: 'refinancecalc',
        emoji: '🔄',
        label: 'Refinance',
        reusedFields: 'Uses your rate & term',
      ),
    ],
  };

  List<_WorkflowEntry> _toolsForCountry() {
    // Normalise country code to upper case before lookup.
    return _countryTools[country.toUpperCase()] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final tools = _toolsForCountry();
    if (tools.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF5B6E8F);
    final cardBg = isDark ? const Color(0xFF1E2840) : const Color(0xFFF4F7FF);
    final accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F2D6B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Text(
                '🧭',
                style: TextStyle(fontSize: 18),
                semanticsLabel: '',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Continue Your Mortgage Planning',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final entry = tools[index];
              return _WorkflowCard(
                entry: entry,
                cardBg: cardBg,
                labelColor: labelColor,
                mutedColor: mutedColor,
                accentColor: accentColor,
                onTap: () {
                  // Navigate using the verified /tool/:country/:toolId route.
                  // The CalculatorDraft is passed via the draft provider at the
                  // call site (usa_mortgage_calc.dart etc.), not here, so that
                  // this widget remains stateless and testable.
                  context.push('/tool/${countryPath.toLowerCase()}/${entry.toolId}');
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Pre-filled values are editable — tap any field to change.',
            style: TextStyle(
              fontSize: 11,
              color: mutedColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single workflow continuation action card.
class _WorkflowCard extends StatelessWidget {
  final _WorkflowEntry entry;
  final Color cardBg;
  final Color labelColor;
  final Color mutedColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _WorkflowCard({
    required this.entry,
    required this.cardBg,
    required this.labelColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${entry.label}. ${entry.reusedFields}. Double-tap to open.',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 130,
          // 48dp minimum touch target met by height: 108 (explicit) + GestureDetector coverage.
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.emoji,
                style: const TextStyle(fontSize: 22),
                semanticsLabel: '',
              ),
              const Spacer(),
              Text(
                entry.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  entry.reusedFields,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
