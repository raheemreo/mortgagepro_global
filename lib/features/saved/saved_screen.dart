// lib/features/saved/saved_screen.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/text_styles.dart';
import '../../providers/saved_provider.dart';
import '../../shared/models/saved_calc.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../providers/saved_tools_provider.dart';
import '../tools/tools_screen.dart';
import '../../shared/widgets/tool_card.dart';

import '../../core/utils/currency_formatter.dart';

// ── Country accent colours matching HTML saved-card::before gradients ─────
Color _accentTop(String country) {
  switch (country.toLowerCase()) {
    case 'usa':
      return const Color(0xFFB91C1C);
    case 'canada':
      return const Color(0xFFC8102E);
    case 'uk':
      return const Color(0xFFC8102E);
    case 'australia':
      return const Color(0xFF002868);
    case 'new zealand':
    case 'newzealand':
    case 'nz':
      return const Color(0xFFC0392B);
    case 'europe':
      return const Color(0xFFFFCC00);
    case 'india':
      return const Color(0xFFFF9933);
    default:
      return const Color(0xFF1B3F72);
  }
}

Color _accentBot(String country) {
  switch (country.toLowerCase()) {
    case 'usa':
      return const Color(0xFF1B3F72);
    case 'canada':
      return const Color(0xFF1A5C35);
    case 'uk':
      return const Color(0xFF0D0D2B);
    case 'australia':
      return const Color(0xFF7C2D12);
    case 'new zealand':
    case 'newzealand':
    case 'nz':
      return const Color(0xFF0D3B2E);
    case 'europe':
      return const Color(0xFF003399);
    case 'india':
      return const Color(0xFF138808);
    default:
      return const Color(0xFF0B1D3A);
  }
}

String _flagFor(String country) {
  switch (country.toLowerCase()) {
    case 'usa':
      return '🇺🇸';
    case 'canada':
      return '🇨🇦';
    case 'uk':
      return '🇬🇧';
    case 'australia':
      return '🇦🇺';
    case 'new zealand':
    case 'newzealand':
    case 'nz':
      return '🇳🇿';
    case 'europe':
      return '🇪🇺';
    case 'india':
      return '🇮🇳';
    default:
      return '🌐';
  }
}

String _routeFor(String country) {
  switch (country.toLowerCase()) {
    case 'usa':
      return '/usa';
    case 'canada':
      return '/canada';
    case 'uk':
      return '/uk';
    case 'australia':
      return '/australia';
    case 'new zealand':
    case 'newzealand':
    case 'nz':
      return '/newzealand';
    case 'europe':
      return '/europe';
    case 'india':
      return '/india';
    default:
      return '/';
  }
}

String _routeForCalc(SavedCalc calc) {
  final country = calc.country.toLowerCase();
  final type = calc.calcType.toLowerCase();

  String? toolId;
  if (country == 'uk') {
    if (type.contains('mortgage')) {
      toolId = 'mortgage';
    } else if (type.contains('stamp duty') || type == 'sdlt') {
      toolId = 'sdlt';
    } else if (type.contains('ltv')) {
      toolId = 'ltv';
    } else if (type.contains('remortgage')) {
      toolId = 'remortgage';
    } else if (type.contains('affordability')) {
      toolId = 'affordability';
    } else if (type.contains('help to buy')) {
      toolId = 'helptobuy';
    } else if (type.contains('amortization')) {
      toolId = 'amortization';
    } else if (type.contains('buy-to-let') || type.contains('btl')) {
      toolId = 'btl';
    } else if (type.contains('income multiple')) {
      toolId = 'incomemultiples';
    } else if (type.contains('sdlt calculator') || type.contains('sdltcalc')) {
      toolId = 'sdltcalc';
    }
  } else if (country == 'usa' || country == 'us') {
    if (type.contains('emergency fund') || type.contains('emergency fund plan'))
      return '/usa/emergency-fund';
    else if (type.contains('home maintenance') ||
        type.contains('maintenance budget'))
      return '/usa/home-maintenance-budget';
    else if (type.contains('fico better rate') ||
        type.contains('fico booster') ||
        type.contains('fico better rate plan'))
      return '/usa/fico-better-rate';
    else if (type.contains('hoa reserve') ||
        type.contains('reserve fund health') ||
        type.contains('reserve health'))
      return '/usa/hoa-reserve-fund-health';
    else if (type.contains('hoa fee increases') ||
        type.contains('hoa fee increase'))
      return '/usa/hoa-fee-increases';
    else if (type.contains('hoa lender dti') ||
        type.contains('lender treatment'))
      return '/usa/hoa-lender-treatment';
    else if (type.contains('arm vs fixed') ||
        type.contains('arm breakeven') ||
        type.contains('arm vs. fixed'))
      return '/usa/arm-vs-fixed-breakeven';
    else if (type.contains('sofr history') ||
        type.contains('sofr rate history'))
      return '/usa/sofr-history';
    else if (type.contains('refinance arm') ||
        type.contains('refinancing from arm') ||
        type.contains('refinancing arm'))
      return '/usa/refinance-arm';
    else if (type.contains('arm risk') || type.contains('arm risk factors'))
      return '/usa/arm-risk-factors';
    else if (type.contains('usda eligibility') ||
        type.contains('usda eligibility map'))
      return '/usa/usda-eligibility-map';
    else if (type.contains('usda 502 direct') ||
        type.contains('502 direct vs guaranteed') ||
        type.contains('502 direct vs. guaranteed') ||
        type.contains('direct vs. guaranteed'))
      return '/usa/usda-502-direct-vs-guaranteed';
    else if (type.contains('usda income limits') ||
        type.contains('usda 2025 income limits') ||
        type.contains('2025 income limits'))
      return '/usa/usda-2025-income-limits';
    else if (type.contains('usda streamline') ||
        type.contains('usda streamline refinance') ||
        type.contains('streamline refinance'))
      return '/usa/usda-streamline-refinance';
    else if (type.contains('203k alternative') || type.contains('alternative'))
      return '/usa/fha-203k-alternative';
    else if (type.contains('203k'))
      return '/usa/fha-203k';
    else if (type.contains('one-close') || type.contains('two-close'))
      return '/usa/one-close-vs-two-close';
    else if (type.contains('builder requirements'))
      return '/usa/builder-requirements';
    else if (type.contains('construction lenders') ||
        type.contains('lenders shortlist'))
      return '/usa/top-construction-lenders';
    else if (type.contains('limits'))
      return '/usa/fha-loan-limits';
    else if (type.contains('credit score') ||
        type.contains('score requirements'))
      return '/usa/fha-credit-score-requirements';
    else if (type.contains('mip cancellation') ||
        type.contains('cancellation rules'))
      return '/usa/fha-mip-cancellation-rules';
    else if (type.contains('property standards') || type.contains('standards'))
      return '/usa/fha-property-standards';
    else if (type.contains('fha'))
      toolId = 'fha';
    else if (type.contains('va coe') ||
        type.contains('va certificate') ||
        type.contains('coe check'))
      return '/usa/va-coe';
    else if (type.contains('va entitlement') ||
        type.contains('entitlement & limits') ||
        type.contains('zero-down ceiling'))
      return '/usa/va-entitlement-limits';
    else if (type.contains('va spouse') ||
        type.contains('surviving spouse') ||
        type.contains('spouse check'))
      return '/usa/va-surviving-spouse';
    else if (type.contains('va irrrl') ||
        type.contains('irrrl streamline') ||
        type.contains('irrrl'))
      return '/usa/va-irrrl';
    else if (type.contains('va'))
      toolId = 'va';
    else if (type.contains('usda'))
      toolId = 'usda';
    else if (type.contains('jumbo lenders') ||
        type.contains('jumbo top lenders'))
      return '/usa/jumbo-lenders';
    else if (type.contains('jumbo doc checklist') ||
        type.contains('jumbo documentation'))
      return '/usa/jumbo-documentation';
    else if (type.contains('jumbo arm') || type.contains('jumbo arm options'))
      return '/usa/jumbo-arm';
    else if (type.contains('jumbo vs conforming') ||
        type.contains('jumbo vs. conforming'))
      return '/usa/jumbo-vs-conforming';
    else if (type.contains('jumbo'))
      toolId = 'jumbo';
    else if (type.contains('construction'))
      toolId = 'construction';
    else if (type.contains('arm'))
      toolId = 'arm';
    else if (type.contains('piti'))
      toolId = 'piti';
    else if (type.contains('mortgage'))
      toolId = 'mortgage';
    else if (type.contains('dti'))
      toolId = 'dti';
    else if (type.contains('amortization'))
      toolId = 'amortization';
    else if (type.contains('affordability'))
      toolId = 'affordability';
    else if (type.contains('bpmi') || type.contains('borrower-paid'))
      return '/usa/pmi-bpmi';
    else if (type.contains('lpmi') || type.contains('lender-paid'))
      return '/usa/pmi-lpmi';
    else if (type.contains('spmi') || type.contains('single premium'))
      return '/usa/pmi-spmi';
    else if (type.contains('split premium') || type.contains('split pmi'))
      return '/usa/pmi-split';
    else if (type.contains('pmi'))
      toolId = 'pmi';
    else if (type.contains('homeinsurance') ||
        type.contains('homeowner') ||
        type.contains('ho3') ||
        type.contains('ho5') ||
        type.contains('ho1') ||
        type.contains('ho6') ||
        type.contains('wildfire') ||
        type.contains('hurricane')) {
      final tLower = type.toLowerCase();
      if (tLower.contains('ho3') || tLower.contains('ho-3')) {
        toolId = 'homeinsurance_ho3';
      } else if (tLower.contains('ho5') || tLower.contains('ho-5')) {
        toolId = 'homeinsurance_ho5';
      } else if (tLower.contains('ho1') || tLower.contains('ho-1')) {
        toolId = 'homeinsurance_ho1';
      } else if (tLower.contains('ho6') || tLower.contains('ho-6')) {
        toolId = 'homeinsurance_ho6';
      } else if (tLower.contains('wildfire')) {
        toolId = 'homeinsurance_wildfire';
      } else if (tLower.contains('hurricane')) {
        toolId = 'homeinsurance_hurricane';
      } else {
        toolId = 'homeinsurance';
      }
    } else if (type.contains('flood'))
      toolId = 'floodinsurance';
    else if (type.contains('property tax'))
      toolId = 'propertytax';
    else if (type.contains('closing'))
      toolId = 'closingcosts';
    else if (type.contains('hoa'))
      toolId = 'hoaimpact';
    else if (type.contains('rental yield'))
      toolId = 'rentalyield';
    else if (type.contains('cash') && type.contains('cash'))
      toolId = 'cashoncash';
    else if (type.contains('fix') && type.contains('flip'))
      toolId = 'fixflip';
    else if (type.contains('1031'))
      toolId = 'exchange1031';
    else if (type.contains('credit score'))
      toolId = 'creditscore';
    else if (type.contains('heloc'))
      toolId = 'heloc';
    else if (type.contains('home equity'))
      toolId = 'homeequity';
    else if (type.contains('debt payoff'))
      toolId = 'debtpayoff';
    else if (type.contains('student loan'))
      toolId = 'studentloandti';
    else if (type.contains('tax deduction'))
      toolId = 'taxdeduction';
    else if (type.contains('moving cost'))
      toolId = 'movingcost';
    else if (type.contains('rent vs buy'))
      toolId = 'rentvsbuy';
    else if (type.contains('hud dpa') || type.contains('huddpa'))
      toolId = 'huddpa';
    else if (type.contains('piggyback')) toolId = 'piggyback';
  } else if (country == 'canada' || country == 'ca') {
    if (type.contains('cmhc'))
      toolId = 'cmhc';
    else if (type.contains('gds'))
      toolId = 'gdstds';
    else if (type.contains('stress'))
      toolId = 'stresstest';
    else if (type.contains('affordability'))
      toolId = 'affordability';
    else if (type.contains('amortization'))
      toolId = 'amortization';
    else if (type.contains('renewal'))
      toolId = 'renewal';
    else if (type.contains('prepayment'))
      toolId = 'prepayment';
    else if (type.contains('transfer') || type.contains('ltt'))
      toolId = 'ltt';
    else if (type.contains('first'))
      toolId = 'firsthome';
    else if (type.contains('rate') || type.contains('boc'))
      toolId = 'bocrate';
    else if (type.contains('advisor'))
      toolId = 'aiadvisor';
    else if (type.contains('mortgage')) toolId = 'mortgage';
  } else if (country == 'australia' || country == 'au') {
    if (type.contains('lmi'))
      toolId = 'lmi';
    else if (type.contains('offset'))
      toolId = 'offset';
    else if (type.contains('dti'))
      toolId = 'dti';
    else if (type.contains('affordability'))
      toolId = 'affordability';
    else if (type.contains('amortization'))
      toolId = 'amortization';
    else if (type.contains('stamp duty by state'))
      toolId = 'stampdutybystate';
    else if (type.contains('stamp duty'))
      toolId = 'stampduty';
    else if (type.contains('refinance'))
      toolId = 'refinance';
    else if (type.contains('extra'))
      toolId = 'extrarepayments';
    else if (type.contains('construction'))
      toolId = 'construction';
    else if (type.contains('grant') || type.contains('fhog'))
      toolId = 'fhog';
    else if (type.contains('rba') || type.contains('rate'))
      toolId = 'rbahistory';
    else if (type.contains('mortgage')) toolId = 'mortgage';
  } else if (country == 'new zealand' ||
      country == 'nz' ||
      country == 'newzealand') {
    if (type.contains('repayment'))
      toolId = 'repayment';
    else if (type.contains('dti'))
      toolId = 'dti';
    else if (type.contains('amortization'))
      toolId = 'amortization';
    else if (type.contains('affordability'))
      toolId = 'affordability';
    else if (type.contains('refixing'))
      toolId = 'refixing';
    else if (type.contains('extra'))
      toolId = 'extrarepayments';
    else if (type.contains('car loan'))
      toolId = 'carloan';
    else if (type.contains('lvr band'))
      toolId = 'lvrband';
    else if (type.contains('lvr'))
      toolId = 'lvr';
    else if (type.contains('deposit builder'))
      toolId = 'depositbuilder';
    else if (type.contains('low equity'))
      toolId = 'lowequity';
    else if (type.contains('kiwisaver calc'))
      toolId = 'kiwisavercalc';
    else if (type.contains('grant') || type.contains('homestart'))
      toolId = 'homestartgrant';
    else if (type.contains('kiwisaver balance'))
      toolId = 'kiwisaverbalance';
    else if (type.contains('employer'))
      toolId = 'employercontrib';
    else if (type.contains('rental yield'))
      toolId = 'rentalyield';
    else if (type.contains('ring'))
      toolId = 'ringfencing';
    else if (type.contains('bright'))
      toolId = 'brightline';
    else if (type.contains('investment'))
      toolId = 'investmentproperty';
    else if (type.contains('interest'))
      toolId = 'interestdeductibility';
    else if (type.contains('nzx'))
      toolId = 'nzxinvestor';
    else if (type.contains('first home'))
      toolId = 'firsthomebuyer';
    else if (type.contains('deposit calc'))
      toolId = 'depositcalc';
    else if (type.contains('preapproval'))
      toolId = 'preapprovalguide';
    else if (type.contains('solicitor'))
      toolId = 'solicitorcosts';
    else if (type.contains('credit score'))
      toolId = 'creditscorenz';
    else if (type.contains('revolving'))
      toolId = 'revolvingcredit';
    else if (type.contains('debt'))
      toolId = 'debtconsolidation';
    else if (type.contains('income tax'))
      toolId = 'incometaxcalc';
    else if (type.contains('refinance'))
      toolId = 'refinancecalc';
    else if (type.contains('construction'))
      toolId = 'constructionloan';
    else if (type.contains('budget'))
      toolId = 'budgetplanner';
    else if (type.contains('ocr'))
      toolId = 'ocrhistory';
    else if (type.contains('compare'))
      toolId = 'comparelenders';
    else if (type.contains('withdrawal'))
      toolId = 'kiwisaverwithdrawal';
    else if (type.contains('house price') || type.contains('all regions'))
      toolId = 'allregions';
    else if (type.contains('kāinga') || type.contains('kainga'))
      toolId = 'kaingaora';
    else if (type.contains('reinz') || type.contains('hpi'))
      toolId = 'reinz_hpi';
    else if (type.contains('overseas') || type.contains('oia'))
      toolId = 'overseas_investment_act';
    else if (type.contains('healthy'))
      toolId = 'healthy_homes';
    else if (type.contains('moneyhub'))
      toolId = 'moneyhub_mortgage';
    else if (type.contains('property market') || type.contains('market report'))
      toolId = 'property_market_report';
    else if (type.contains('mortgage')) toolId = 'mortgage';
  } else if (country == 'europe') {
    if (type.contains('dti'))
      toolId = 'dti';
    else if (type.contains('tax'))
      toolId = 'propertytax';
    else if (type.contains('affordability'))
      toolId = 'affordability';
    else if (type.contains('amortization'))
      toolId = 'amortization';
    else if (type.contains('euribor'))
      toolId = 'euribor';
    else if (type.contains('comparison'))
      toolId = 'comparison';
    else if (type.contains('notary'))
      toolId = 'notaryfee';
    else if (type.contains('non-resident') || type.contains('nonresident'))
      toolId = 'nonresident';
    else if (type.contains('currency'))
      toolId = 'currency';
    else if (type.contains('mortgage')) toolId = 'mortgage';
  } else if (country == 'india' || country == 'in') {
    if (type.contains('emi') || type == 'in_emi')
      toolId = 'in_emi';
    else if (type.contains('amortization'))
      toolId = 'in_amortization';
    else if (type.contains('eligibility'))
      toolId = 'in_loan_eligibility';
    else if (type.contains('prepayment'))
      toolId = 'in_prepayment';
    else if (type.contains('transfer'))
      toolId = 'in_balance_transfer';
    else if (type.contains('foir'))
      toolId = 'in_foir';
    else if (type.contains('under construction'))
      toolId = 'in_under_construction';
    else if (type.contains('joint'))
      toolId = 'in_joint_loan';
    else if (type.contains('floating'))
      toolId = 'in_floating_vs_fixed';
    else if (type.contains('car loan'))
      toolId = 'in_car_loan';
    else if (type.contains('stamp'))
      toolId = 'in_stamp_duty';
    else if (type.contains('gst'))
      toolId = 'in_gst';
    else if (type.contains('pmay subsidy'))
      toolId = 'in_pmay';
    else if (type.contains('80c'))
      toolId = 'in_section_80c';
    else if (type.contains('24b'))
      toolId = 'in_section_24b';
    else if (type.contains('cibil'))
      toolId = 'in_cibil';
    else if (type.contains('first home'))
      toolId = 'in_first_home';
    else if (type.contains('tds'))
      toolId = 'in_tds';
    else if (type.contains('capital gains'))
      toolId = 'in_capital_gains';
    else if (type.contains('personal loan'))
      toolId = 'in_personal_loan_emi';
    else if (type.contains('education'))
      toolId = 'in_education_loan';
    else if (type.contains('ppf'))
      toolId = 'in_ppf_calculator';
    else if (type.contains('epf'))
      toolId = 'in_epf_calculator';
    else if (type.contains('sip'))
      toolId = 'in_sip_calculator';
    else if (type.contains('nps'))
      toolId = 'in_nps_calculator';
    else if (type.contains('income tax'))
      toolId = 'in_income_tax_calculator';
    else if (type.contains('gold'))
      toolId = 'in_gold_loan_calculator';
    else if (type.contains('lap'))
      toolId = 'in_lap_calculator';
    else if (type.contains('advisor'))
      toolId = 'in_india_ai_advisor';
    else if (type.contains('repo'))
      toolId = 'in_rbi_repo_rate_history';
    else if (type.contains('housing for all'))
      toolId = 'in_pmay_housing_for_all';
    else if (type.contains('residex'))
      toolId = 'in_nhb_residex';
    else if (type.contains('guide'))
      toolId = 'in_80c_24b_guide';
    else if (type.contains('nri'))
      toolId = 'in_nri_home_loan';
    else if (type.contains('nre'))
      toolId = 'in_nre_nro_account';
    else if (type.contains('fema'))
      toolId = 'in_fema_compliance';
    else if (type.contains('usd') && type.contains('inr'))
      toolId = 'in_usd_inr_converter';
    else if (type.contains('eligibility'))
      toolId = 'in_pmay_eligibility';
    else if (type.contains('gst property'))
      toolId = 'in_gst_property';
    else if (type.contains('monetary'))
      toolId = 'in_rbi_monetary_policy';
    else if (type.contains('compare banks'))
      toolId = 'in_compare_banks';
    else if (type.contains('city'))
      toolId = 'in_city_property_prices';
    else if (type.contains('all states'))
      toolId = 'in_stamp_duty_all_states';
    else if (type.contains('hfcs')) toolId = 'in_banks_hfcs_compare';
  }

  if (toolId != null) {
    return '/tool/$country/$toolId';
  }
  return _routeFor(country);
}

String _formatResultValue(String key, double value, String currencyCode) {
  final k = key.toLowerCase();
  if (k.contains('rate') ||
      k.contains('pct') ||
      k.contains('ltv') ||
      k.contains('ratio') ||
      k.contains('percent') ||
      k.contains('yield') ||
      k.contains('roi')) {
    if (value > 0.0 && value < 1.0) {
      return '${(value * 100).toStringAsFixed(2)}%';
    }
    return '${value.toStringAsFixed(2)}%';
  }
  if (k.contains('years') ||
      k.contains('term') ||
      k.contains('months') ||
      k.contains('multiple')) {
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
  return CurrencyFormatter.forCountry(value, currencyCode);
}

// ════════════════════════════════════════════════════════════════════════════
//  🔖  SAVED SCREEN
// ════════════════════════════════════════════════════════════════════════════
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedProvider);
    final savedTools = ref.watch(savedToolsProvider);

    // Filter calculations by search query
    final filtered = _searchQuery.isEmpty
        ? saved
        : saved
            .where((c) =>
                c.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.country.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.calcType.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Get and filter favorite tools
    final favToolsList =
        allToolsList.where((t) => savedTools.contains(t.id)).toList();
    final filteredFavTools = _searchQuery.isEmpty
        ? favToolsList
        : favToolsList
            .where((t) =>
                t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                t.countryName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Stats
    final countrySet = saved.map((c) => c.country).toSet();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    final navyCol = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final borderCol =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);

    final showEmptyState = saved.isEmpty && savedTools.isEmpty;
    final showNoResults =
        _searchQuery.isNotEmpty && filtered.isEmpty && filteredFavTools.isEmpty;

    return Scaffold(
      backgroundColor: bgCol,
      body: Column(
        children: [
          // ── Gradient Header ─────────────────────────────────────────
          _SavedHeader(
            savedCount: saved.length,
            countriesCount: countrySet.length,
            comparedCount:
                saved.length > 1 ? (saved.length ~/ 2).clamp(1, 9) : 0,
            showSearch: _showSearch,
            searchCtrl: _searchCtrl,
            onSearchToggle: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            onAdd: () => context.go('/'),
          ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: showEmptyState
                ? const _EmptyState()
                : showNoResults
                    ? _NoResults(query: _searchQuery)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(15, 16, 15, 110),
                        children: [
                          if (filtered.isNotEmpty) ...[
                            // Section header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                Text('Recently Saved',
                                    style: AppTextStyles.playfair(
                                        size: 15, color: navyCol)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _showSortSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: borderCol),
                                    ),
                                    child: Text('Sort ↓',
                                        style: AppTextStyles.dmSans(
                                            size: 11,
                                            color: const Color(0xFF0D9488),
                                            weight: FontWeight.w700)),
                                  ),
                                ),
                              ]),
                            ),

                            ...filtered.map(
                              (calc) => _SavedCard(
                                calc: calc,
                                ref: ref,
                                onViewDetails: () =>
                                    _showDetails(context, calc),
                                onRecalculate: () => context
                                    .push(_routeForCalc(calc), extra: calc),
                              ),
                            ),
                          ],
                          if (filteredFavTools.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                Text('Favorite Tools',
                                    style: AppTextStyles.playfair(
                                        size: 15, color: navyCol)),
                              ]),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.15,
                              ),
                              itemCount: filteredFavTools.length,
                              itemBuilder: (context, idx) {
                                final tool = filteredFavTools[idx];
                                return ToolCard(
                                  toolId: tool.id,
                                  flagIcon: _flagFor(tool.country),
                                  icon: tool.icon,
                                  name: tool.name,
                                  description: tool.description,
                                  variant: tool.variant,
                                  badgeText: tool.badgeText,
                                  badgeTextColor: tool.badgeTextColor,
                                  badgeBgColor: tool.badgeBgColor,
                                  onTap: () => context.push(tool.route),
                                  showFlag: true,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
          ),

          // ── Bottom Nav ───────────────────────────────────────────────
          BottomNav(
            activeIndex: 2,
            activeColor:
                isDark ? const Color(0xFFF97316) : const Color(0xFF7C2D12),
            countryIcon: '🌐',
            countryLabel: 'Tools',
            countryRoute: '/',
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navyColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final handleColor = isDark ? Colors.white24 : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Material(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: handleColor, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Sort By',
                style: AppTextStyles.playfair(size: 16, color: navyColor)),
            const SizedBox(height: 8),
            ...['Newest First', 'Oldest First', 'Country A–Z', 'Highest Value']
                .map((opt) => ListTile(
                      title: Text(opt,
                          style: AppTextStyles.dmSans(
                              size: 14,
                              color: navyColor,
                              weight: FontWeight.w600)),
                      onTap: () => Navigator.pop(context),
                    )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, SavedCalc calc) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navyColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF5B6E8F);
    final handleColor = isDark ? Colors.white24 : const Color(0xFFE2E8F0);
    final dateColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Text(_flagFor(calc.country),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(calc.label,
                            style: AppTextStyles.playfair(
                                size: 16, color: navyColor)),
                        Text('${calc.country} · ${calc.calcType}',
                            style: AppTextStyles.dmSans(
                                size: 11, color: mutedColor)),
                      ]),
                ),
              ]),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('Results',
                  style: AppTextStyles.dmSans(
                      size: 11, color: mutedColor, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...calc.results.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(
                        child: Text(e.key,
                            style: AppTextStyles.dmSans(
                                size: 13,
                                color: navyColor,
                                weight: FontWeight.w600)),
                      ),
                      Text(
                        _formatResultValue(e.key, e.value, calc.currencyCode),
                        style: AppTextStyles.dmSans(
                            size: 14,
                            color: navyColor,
                            weight: FontWeight.w800),
                      ),
                    ]),
                  )),
              const SizedBox(height: 16),
              Text('Saved on ${_fmtDate(calc.savedAt)}',
                  style: AppTextStyles.dmSans(size: 10, color: dateColor)),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  GRADIENT HEADER
// ════════════════════════════════════════════════════════════════════════════
class _SavedHeader extends StatelessWidget {
  final int savedCount, countriesCount, comparedCount;
  final bool showSearch;
  final TextEditingController searchCtrl;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  const _SavedHeader({
    required this.savedCount,
    required this.countriesCount,
    required this.comparedCount,
    required this.showSearch,
    required this.searchCtrl,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A00), Color(0xFF7C2D12), Color(0xFFD97706)],
          stops: [0.0, 0.60, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative gold circle
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x12FCD34D),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved Calculations',
                              style: AppTextStyles.playfair(
                                  size: 22, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Your mortgage history · 8 countries',
                              style: AppTextStyles.dmSans(
                                  size: 11, color: Colors.white54)),
                        ]),
                    const Spacer(),
                    // Search button
                    GestureDetector(
                      onTap: onSearchToggle,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: showSearch
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔍', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add button
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('+',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w300)),
                      ),
                    ),
                  ]),

                  // Search bar (animated)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: showSearch
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(height: 16),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 2),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: onSearchChanged,
                        autofocus: true,
                        style:
                            AppTextStyles.dmSans(size: 13, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search saved calculations…',
                          hintStyle: AppTextStyles.dmSans(
                              size: 13, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white54, size: 18),
                        ),
                      ),
                    ),
                  ),

                  // Stats row
                  Row(children: [
                    _StatBox(value: '$savedCount', label: 'Saved Calcs'),
                    const SizedBox(width: 10),
                    _StatBox(value: '$countriesCount', label: 'Countries'),
                    const SizedBox(width: 10),
                    _StatBox(value: '$comparedCount', label: 'Compared'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat box ─────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontFamily: 'DMSans')),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SAVED CARD  (matches HTML .saved-card design exactly)
// ════════════════════════════════════════════════════════════════════════════
class _SavedCard extends StatelessWidget {
  final SavedCalc calc;
  final WidgetRef ref;
  final VoidCallback onViewDetails;
  final VoidCallback onRecalculate;

  const _SavedCard({
    required this.calc,
    required this.ref,
    required this.onViewDetails,
    required this.onRecalculate,
  });

  String get _formattedDate {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return 'Saved ${months[calc.savedAt.month]} ${calc.savedAt.day}, ${calc.savedAt.year}';
  }

  bool get _isCmhcOrLmi =>
      calc.calcType.toLowerCase().contains('cmhc') ||
      calc.calcType.toLowerCase().contains('lmi');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topColor = _accentTop(calc.country);
    final botColor = _accentBot(calc.country);
    final flag = _flagFor(calc.country);
    final numEntries = calc.results.entries.take(3).toList();

    // Pick 3 display fields: try label1, monthly, rate
    final displayKeys = _pickDisplayKeys(numEntries);

    final cardBg = theme.cardColor;
    final cardBorder =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);
    final deleteBg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
    final deleteFg = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);

    final navyColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF5B6E8F);

    // Dynamic badge styles
    final badgeBg = _isCmhcOrLmi
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF));
    final badgeTextCol = _isCmhcOrLmi
        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8));

    // Dynamic grid item bg
    final gridBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F4FF);

    return Dismissible(
      key: Key(calc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(
          color: deleteBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🗑️', style: TextStyle(fontSize: 24)),
          Text('Delete',
              style: AppTextStyles.dmSans(
                  size: 10, color: deleteFg, weight: FontWeight.w700)),
        ]),
      ),
      onDismissed: (_) => ref.read(savedProvider.notifier).delete(calc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Country accent bar (4px left strip)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topColor, botColor],
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: flag + name/date + badge
                      Row(children: [
                        Text(flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${calc.country} · ${calc.label}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: navyColor,
                                        fontFamily: 'DMSans')),
                                const SizedBox(height: 1),
                                Text('$_formattedDate · ${calc.calcType}',
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        color: mutedColor,
                                        fontFamily: 'DMSans')),
                              ]),
                        ),
                        // Badge: blue = Mortgage, green = CMHC/LMI
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isCmhcOrLmi ? 'Incl.' : 'Mortgage',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeTextCol,
                                fontFamily: 'DMSans'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),

                      // 3-column number grid
                      Row(
                        children: displayKeys.map((entry) {
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: displayKeys.last == entry ? 0 : 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9, horizontal: 8),
                              decoration: BoxDecoration(
                                color: gridBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(children: [
                                Text(entry.key.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 8.5,
                                        color: mutedColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        fontFamily: 'DMSans')),
                                const SizedBox(height: 2),
                                Text(
                                  _formatResultValue(entry.key, entry.value,
                                      calc.currencyCode),
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: navyColor,
                                      fontFamily: 'DMSans'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 11),

                      // Action buttons row
                      Row(children: [
                        // View Details
                        Expanded(
                          flex: 4,
                          child: _ActionBtn(
                            label: 'View Details',
                            style: _BtnStyle.primary,
                            onTap: onViewDetails,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Recalculate
                        Expanded(
                          flex: 4,
                          child: _ActionBtn(
                            label: 'Recalculate',
                            style: _BtnStyle.secondary,
                            onTap: onRecalculate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete
                        _ActionBtn(
                          label: '🗑',
                          style: _BtnStyle.danger,
                          onTap: () =>
                              ref.read(savedProvider.notifier).delete(calc.id),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, double>> _pickDisplayKeys(
      List<MapEntry<String, double>> entries) {
    if (entries.length >= 3) return entries.take(3).toList();
    return entries;
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
enum _BtnStyle { primary, secondary, danger }

class _ActionBtn extends StatelessWidget {
  final String label;
  final _BtnStyle style;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg, fg;
    Border? border;

    switch (style) {
      case _BtnStyle.primary:
        bg = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1A3A8F);
        fg = isDark ? const Color(0xFF0A0F1E) : Colors.white;
      case _BtnStyle.secondary:
        bg = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF0F4FF);
        fg = isDark ? Colors.white70 : const Color(0xFF0B1D3A);
        border = Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0x171B3A8F));
      case _BtnStyle.danger:
        bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'DMSans')),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  EMPTY + NO-RESULTS STATES
// ════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navyCol = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF5B6E8F);
    final emptyBoxBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: emptyBoxBg,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text('🔖', style: TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 20),
            Text('No Saved Calculations',
                style: AppTextStyles.playfair(size: 20, color: navyCol)),
            const SizedBox(height: 8),
            Text(
              'Run a mortgage calculation and tap "Save" to store it here for future reference.',
              style: AppTextStyles.dmSans(size: 13, color: mutedCol),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C2D12), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C2D12).withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text('Start Calculating →',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navyCol = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF5B6E8F);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text('No results for "$query"',
              style: AppTextStyles.playfair(size: 18, color: navyCol)),
          const SizedBox(height: 8),
          Text('Try a different country or calculation name.',
              style: AppTextStyles.dmSans(size: 13, color: mutedCol)),
        ],
      ),
    );
  }
}
