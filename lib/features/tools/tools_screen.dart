// lib/features/tools/tools_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/tool_card.dart';
import '../../services/analytics_service.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
class _DT {
  static Color navy = const Color(0xFF0B1D3A);
  static Color royal = const Color(0xFF1A3A8F);
  static Color bg = const Color(0xFFF0F4FF);
  static Color muted = const Color(0xFF5B6E8F);
  static Color border = const Color(0x171B3A8F);
  static Color gold = const Color(0xFFD97706);

  static void update(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    navy = isDark ? Colors.white : const Color(0xFF0B1D3A);
    royal = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1A3A8F);
    bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    muted = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    border =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);
  }
}

// ── Tool definition model ───────────────────────────────────────────────────
class _ToolDef {
  final String id;
  final String icon;
  final String name;
  final String description;
  final String country; // 'usa', 'canada', 'uk', 'australia', 'newzealand', 'europe', 'india'
  final String countryName;
  final String category;
  final ToolCardVariant variant;
  final String? badgeText;
  final Color? badgeTextColor;
  final Color? badgeBgColor;
  final String route;
  final List<String> keywords;

  const _ToolDef({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.country,
    required this.countryName,
    required this.category,
    this.variant = ToolCardVariant.light,
    this.badgeText,
    this.badgeTextColor,
    this.badgeBgColor,
    required this.route,
    required this.keywords,
  });
}

// ── Complete tools list ─────────────────────────────────────────────────────
const List<_ToolDef> _allTools = [
  // ── USA (10) ──────────────────────────────────────────────────────────────
  _ToolDef(
    id: 'usa_core_mortgage_calc',
    icon: '🧮',
    name: 'Mortgage Calc',
    description: 'Monthly payment estimate',
    country: 'usa',
    countryName: 'United States',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.dark,
    route: '/tool/usa/mortgage',
    keywords: ['mortgage', 'calc', 'usa', 'monthly', 'payment', 'estimate'],
  ),
  _ToolDef(
    id: 'usa_core_piti_calculator',
    icon: '📊',
    name: 'PITI Calculator',
    description: 'Full payment breakdown',
    country: 'usa',
    countryName: 'United States',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.light,
    badgeText: 'Popular',
    badgeTextColor: Color(0xFF1D4ED8),
    badgeBgColor: Color(0xFFEFF6FF),
    route: '/tool/usa/piti',
    keywords: ['piti', 'calculator', 'usa', 'payment', 'breakdown', 'taxes', 'insurance'],
  ),
  _ToolDef(
    id: 'usa_core_dti_calculator',
    icon: '📈',
    name: 'DTI Calculator',
    description: '28/36 rule check',
    country: 'usa',
    countryName: 'United States',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/usa/dti',
    keywords: ['dti', 'calculator', 'usa', 'debt', 'income', 'ratio', '28/36'],
  ),
  _ToolDef(
    id: 'usa_core_amortization',
    icon: '📅',
    name: 'Amortization',
    description: 'Full payment schedule',
    country: 'usa',
    countryName: 'United States',
    category: 'Amortization',
    variant: ToolCardVariant.red,
    route: '/tool/usa/amortization',
    keywords: ['amortization', 'usa', 'schedule', 'table', 'interest', 'principal'],
  ),
  _ToolDef(
    id: 'usa_core_affordability',
    icon: '💰',
    name: 'Affordability',
    description: 'How much house?',
    country: 'usa',
    countryName: 'United States',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/usa/affordability',
    keywords: ['affordability', 'usa', 'how much', 'house', 'budget'],
  ),
  _ToolDef(
    id: 'usa_core_down_payment',
    icon: '🔑',
    name: 'Down Payment',
    description: '3% · 5% · 10% · 20%',
    country: 'usa',
    countryName: 'United States',
    category: 'Down Payment Tools',
    variant: ToolCardVariant.gold,
    route: '/tool/usa/downpayment',
    keywords: ['down', 'payment', 'usa', 'savings', 'percentage', 'pmi'],
  ),
  _ToolDef(
    id: 'usa_loan_fha',
    icon: '🏦',
    name: 'FHA Loan Calc',
    description: '3.5% down · MIP incl.',
    country: 'usa',
    countryName: 'United States',
    category: 'Government Programs',
    variant: ToolCardVariant.light,
    badgeText: '580+ Score',
    badgeTextColor: Color(0xFF15803D),
    badgeBgColor: Color(0xFFF0FDF4),
    route: '/tool/usa/fha',
    keywords: ['fha', 'loan', 'usa', 'mip', 'government', 'bad credit', 'downpayment'],
  ),
  _ToolDef(
    id: 'usa_loan_va',
    icon: '🎖️',
    name: 'VA Loan Calc',
    description: '0% down · Veterans',
    country: 'usa',
    countryName: 'United States',
    category: 'Government Programs',
    variant: ToolCardVariant.dark,
    route: '/tool/usa/va',
    keywords: ['va', 'loan', 'usa', 'veterans', 'military', 'zero down'],
  ),
  _ToolDef(
    id: 'usa_insctax_pmi',
    icon: '🛡️',
    name: 'PMI Calculator',
    description: 'Private mortgage insurance',
    country: 'usa',
    countryName: 'United States',
    category: 'Insurance Tools',
    variant: ToolCardVariant.light,
    route: '/tool/usa/pmi',
    keywords: ['pmi', 'calculator', 'usa', 'private', 'mortgage', 'insurance'],
  ),
  _ToolDef(
    id: 'usa_insctax_property_tax',
    icon: '🏛️',
    name: 'Property Tax',
    description: 'By state & county',
    country: 'usa',
    countryName: 'United States',
    category: 'Tax Tools',
    variant: ToolCardVariant.slate,
    route: '/tool/usa/propertytax',
    keywords: ['property', 'tax', 'usa', 'state', 'county', 'taxes'],
  ),

  // ── CANADA (8) ────────────────────────────────────────────────────────────
  _ToolDef(
    id: 'canada_mortgage_calc',
    icon: '🏠',
    name: 'Mortgage Calc',
    description: 'Monthly payment + CMHC',
    country: 'canada',
    countryName: 'Canada',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.green,
    route: '/tool/canada/mortgage',
    keywords: ['mortgage', 'calc', 'canada', 'ca', 'monthly', 'payment', 'cmhc'],
  ),
  _ToolDef(
    id: 'canada_cmhc',
    icon: '🛡️',
    name: 'CMHC Insurance',
    description: 'Premium calculator',
    country: 'canada',
    countryName: 'Canada',
    category: 'Insurance Tools',
    variant: ToolCardVariant.light,
    badgeText: '<20% down',
    badgeTextColor: Color(0xFFB91C1C),
    badgeBgColor: Color(0xFFFEF2F2),
    route: '/tool/canada/cmhc',
    keywords: ['cmhc', 'insurance', 'canada', 'premium', 'default', 'deposit'],
  ),
  _ToolDef(
    id: 'canada_gds_tds',
    icon: '📊',
    name: 'GDS / TDS Ratio',
    description: 'Gross debt service',
    country: 'canada',
    countryName: 'Canada',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/canada/gdstds',
    keywords: ['gds', 'tds', 'ratio', 'canada', 'debt', 'service', 'qualification'],
  ),
  _ToolDef(
    id: 'canada_stress_test',
    icon: '🧪',
    name: 'Stress Test Calc',
    description: 'Can you qualify?',
    country: 'canada',
    countryName: 'Canada',
    category: 'Affordability Tools',
    variant: ToolCardVariant.red,
    route: '/tool/canada/stresstest',
    keywords: ['stress', 'test', 'canada', 'qualify', 'bank of canada', 'mqr'],
  ),
  _ToolDef(
    id: 'canada_affordability',
    icon: '💰',
    name: 'Affordability',
    description: 'Max home price, CAD',
    country: 'canada',
    countryName: 'Canada',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/canada/affordability',
    keywords: ['affordability', 'canada', 'max', 'price', 'cad', 'budget'],
  ),
  _ToolDef(
    id: 'canada_amortization',
    icon: '📅',
    name: 'Amortization',
    description: 'Bi-weekly schedule',
    country: 'canada',
    countryName: 'Canada',
    category: 'Amortization',
    variant: ToolCardVariant.gold,
    route: '/tool/canada/amortization',
    keywords: ['amortization', 'canada', 'bi-weekly', 'schedule', 'table'],
  ),
  _ToolDef(
    id: 'canada_renewal_planner',
    icon: '🔄',
    name: 'Renewal Planner',
    description: 'Term renewal analysis',
    country: 'canada',
    countryName: 'Canada',
    category: 'Refinancing Tools',
    variant: ToolCardVariant.light,
    route: '/tool/canada/renewal',
    keywords: ['renewal', 'planner', 'canada', 'term', 'rates', 'analysis'],
  ),
  _ToolDef(
    id: 'canada_prepayment_calc',
    icon: '📈',
    name: 'Prepayment Calc',
    description: 'Lump sum savings',
    country: 'canada',
    countryName: 'Canada',
    category: 'Payment Tools',
    variant: ToolCardVariant.light,
    route: '/tool/canada/prepayment',
    keywords: ['prepayment', 'canada', 'lump sum', 'savings', 'interest', 'accelerated'],
  ),

  // ── UK (8) ────────────────────────────────────────────────────────────────
  _ToolDef(
    id: 'uk_mortgage_calc',
    icon: '🏠',
    name: 'Mortgage Calc',
    description: 'Monthly repayment',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.dark,
    route: '/tool/uk/mortgage',
    keywords: ['mortgage', 'calc', 'uk', 'repayment', 'monthly', 'gbp'],
  ),
  _ToolDef(
    id: 'uk_stamp_duty_sdlt',
    icon: '🏛️',
    name: 'Stamp Duty (SDLT)',
    description: 'Tax on purchase',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Tax Tools',
    variant: ToolCardVariant.light,
    badgeText: 'FTB Relief',
    badgeTextColor: Color(0xFFB91C1C),
    badgeBgColor: Color(0xFFFEF2F2),
    route: '/tool/uk/stampduty',
    keywords: ['stamp', 'duty', 'sdlt', 'uk', 'tax', 'purchase', 'land'],
  ),
  _ToolDef(
    id: 'uk_ltv_calc',
    icon: '📊',
    name: 'LTV Calculator',
    description: 'Loan-to-value ratio',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Affordability Tools',
    variant: ToolCardVariant.royal,
    route: '/tool/uk/ltv',
    keywords: ['ltv', 'calculator', 'uk', 'loan to value', 'ratio', 'equity'],
  ),
  _ToolDef(
    id: 'uk_remortgage_tool',
    icon: '🔁',
    name: 'Remortgage Tool',
    description: 'Switch & save calc',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Refinancing Tools',
    variant: ToolCardVariant.light,
    route: '/tool/uk/remortgage',
    keywords: ['remortgage', 'uk', 'switch', 'save', 'refinance', 'equity'],
  ),
  _ToolDef(
    id: 'uk_affordability',
    icon: '💷',
    name: 'Affordability',
    description: 'Max borrowing GBP',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/uk/affordability',
    keywords: ['affordability', 'uk', 'max', 'borrowing', 'gbp', 'income'],
  ),
  _ToolDef(
    id: 'uk_help_to_buy',
    icon: '🏘️',
    name: 'Help to Buy',
    description: 'Equity loan scheme',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Government Programs',
    variant: ToolCardVariant.red,
    route: '/tool/uk/helptobuy',
    keywords: ['help to buy', 'uk', 'equity', 'loan', 'scheme', 'government'],
  ),
  _ToolDef(
    id: 'uk_amortization',
    icon: '📅',
    name: 'Amortization',
    description: 'Repayment schedule',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Amortization',
    variant: ToolCardVariant.light,
    route: '/tool/uk/amortization',
    keywords: ['amortization', 'uk', 'repayment', 'schedule', 'table'],
  ),
  _ToolDef(
    id: 'uk_buy_to_let',
    icon: '🏢',
    name: 'Buy-to-Let Calc',
    description: 'Rental yield & BTL',
    country: 'uk',
    countryName: 'United Kingdom',
    category: 'Investment Tools',
    variant: ToolCardVariant.gold,
    route: '/tool/uk/btl',
    keywords: ['buy to let', 'btl', 'uk', 'rental', 'yield', 'investment', 'landlord'],
  ),

  // ── AUSTRALIA (8) ─────────────────────────────────────────────────────────
  _ToolDef(
    id: 'australia_mortgage_calc',
    icon: '🏠',
    name: 'Mortgage Calc',
    description: 'Variable & fixed rates',
    country: 'australia',
    countryName: 'Australia',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.dark,
    badgeText: 'LMI Incl.',
    badgeTextColor: Color(0xFF1D4ED8),
    badgeBgColor: Color(0xFFEFF6FF),
    route: '/tool/australia/mortgage',
    keywords: ['mortgage', 'calc', 'australia', 'au', 'variable', 'fixed', 'lmi'],
  ),
  _ToolDef(
    id: 'australia_lmi',
    icon: '🛡️',
    name: 'LMI Calculator',
    description: 'Insurance premium',
    country: 'australia',
    countryName: 'Australia',
    category: 'Insurance Tools',
    variant: ToolCardVariant.light,
    route: '/tool/australia/lmi',
    keywords: ['lmi', 'calculator', 'australia', 'lenders', 'mortgage', 'insurance'],
  ),
  _ToolDef(
    id: 'australia_offset',
    icon: '🏦',
    name: 'Offset Account',
    description: 'Interest savings calc',
    country: 'australia',
    countryName: 'Australia',
    category: 'Payment Tools',
    variant: ToolCardVariant.teal,
    route: '/tool/australia/offset',
    keywords: ['offset', 'account', 'australia', 'interest', 'savings', 'balance'],
  ),
  _ToolDef(
    id: 'australia_dti',
    icon: '📊',
    name: 'DTI Ratio',
    description: 'Debt-to-income AUS',
    country: 'australia',
    countryName: 'Australia',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/australia/dti',
    keywords: ['dti', 'ratio', 'australia', 'debt', 'income', 'aus'],
  ),
  _ToolDef(
    id: 'australia_affordability',
    icon: '💰',
    name: 'Affordability',
    description: 'Borrowing capacity AUD',
    country: 'australia',
    countryName: 'Australia',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/australia/affordability',
    keywords: ['affordability', 'australia', 'borrowing', 'capacity', 'aud'],
  ),
  _ToolDef(
    id: 'australia_amortization',
    icon: '📅',
    name: 'Amortization',
    description: 'Fortnightly schedule',
    country: 'australia',
    countryName: 'Australia',
    category: 'Amortization',
    variant: ToolCardVariant.blue,
    route: '/tool/australia/amortization',
    keywords: ['amortization', 'australia', 'fortnightly', 'schedule', 'table'],
  ),
  _ToolDef(
    id: 'australia_stamp_duty',
    icon: '🏘️',
    name: 'Stamp Duty (AUS)',
    description: 'State-by-state calc',
    country: 'australia',
    countryName: 'Australia',
    category: 'Tax Tools',
    variant: ToolCardVariant.gold,
    route: '/tool/australia/stampduty',
    keywords: ['stamp', 'duty', 'australia', 'state', 'tax', 'purchase', 'aus'],
  ),
  _ToolDef(
    id: 'australia_refinance_tool',
    icon: '🔄',
    name: 'Refinance Tool',
    description: 'Switch lender savings',
    country: 'australia',
    countryName: 'Australia',
    category: 'Refinancing Tools',
    variant: ToolCardVariant.light,
    route: '/tool/australia/refinance',
    keywords: ['refinance', 'australia', 'switch', 'lender', 'savings', 'fees'],
  ),

  // ── NEW ZEALAND (8) ───────────────────────────────────────────────────────
  _ToolDef(
    id: 'nz_core_mortgage_calc',
    icon: '🏠',
    name: 'Mortgage Calc',
    description: 'NZD monthly payment',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.teal,
    badgeText: 'Fixed & Float',
    badgeTextColor: Color(0xFF15803D),
    badgeBgColor: Color(0xFFF0FDF4),
    route: '/tool/newzealand/mortgage',
    keywords: ['mortgage', 'calc', 'new zealand', 'nz', 'monthly', 'fixed', 'floating'],
  ),
  _ToolDef(
    id: 'nz_core_repayment_calc',
    icon: '📊',
    name: 'Repayment Calc',
    description: 'P&I vs interest only',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Payment Tools',
    variant: ToolCardVariant.light,
    route: '/tool/newzealand/repayment',
    keywords: ['repayment', 'new zealand', 'nz', 'interest only', 'principal'],
  ),
  _ToolDef(
    id: 'nz_core_dti_calculator',
    icon: '📈',
    name: 'DTI Calculator',
    description: 'Debt-to-income NZ',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    badgeText: '6x Cap',
    badgeTextColor: Color(0xFFB91C1C),
    badgeBgColor: Color(0xFFFEF2F2),
    route: '/tool/newzealand/dti',
    keywords: ['dti', 'calculator', 'new zealand', 'nz', 'debt', 'income', '6x'],
  ),
  _ToolDef(
    id: 'nz_core_car_loan_calc',
    icon: '🏎️',
    name: 'Car Loan Calc',
    description: 'Vehicle financing NZD',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Investment Tools',
    variant: ToolCardVariant.red,
    route: '/tool/newzealand/carloan',
    keywords: ['car', 'loan', 'new zealand', 'nz', 'vehicle', 'financing'],
  ),
  _ToolDef(
    id: 'nz_lvr_calculator',
    icon: '🛡️',
    name: 'LVR Calculator',
    description: 'Loan-to-value ratio',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    badgeText: '20% / 35%',
    badgeTextColor: Color(0xFFB91C1C),
    badgeBgColor: Color(0xFFFEF2F2),
    route: '/tool/newzealand/lvr',
    keywords: ['lvr', 'calculator', 'new zealand', 'nz', 'loan to value', 'deposit'],
  ),
  _ToolDef(
    id: 'nz_kiwisaver_calc',
    icon: '🥝',
    name: 'KiwiSaver Calc',
    description: 'First-home withdrawal',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Government Programs',
    variant: ToolCardVariant.dark,
    badgeText: '3yr min',
    badgeTextColor: Color(0xFF0D9488),
    badgeBgColor: Color(0xFFEFF6FF),
    route: '/tool/newzealand/kiwisavercalc',
    keywords: ['kiwisaver', 'new zealand', 'nz', 'withdrawal', 'first home'],
  ),
  _ToolDef(
    id: 'nz_fhb_first_home_buyer',
    icon: '🏡',
    name: 'First Home Buyer',
    description: 'Full eligibility check',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Government Programs',
    variant: ToolCardVariant.teal,
    route: '/tool/newzealand/firsthomebuyer',
    keywords: ['first', 'home', 'buyer', 'new zealand', 'nz', 'eligibility', 'grant'],
  ),
  _ToolDef(
    id: 'nz_tax_rental_yield_calc',
    icon: '🏘️',
    name: 'Rental Yield Calc',
    description: 'Gross & net yield NZD',
    country: 'newzealand',
    countryName: 'New Zealand',
    category: 'Investment Tools',
    variant: ToolCardVariant.light,
    route: '/tool/newzealand/rentalyield',
    keywords: ['rental', 'yield', 'new zealand', 'nz', 'investment', 'tax'],
  ),

  // ── EUROPE (8) ────────────────────────────────────────────────────────────
  _ToolDef(
    id: 'europe_mortgage_calc',
    icon: '🏠',
    name: 'Mortgage Calc',
    description: 'EUR monthly payment',
    country: 'europe',
    countryName: 'Europe',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.dark,
    badgeText: '6 countries',
    badgeTextColor: Color(0xFF1D4ED8),
    badgeBgColor: Color(0xFFEFF6FF),
    route: '/tool/europe/mortgage',
    keywords: ['mortgage', 'calc', 'europe', 'eu', 'eur', 'germany', 'france'],
  ),
  _ToolDef(
    id: 'europe_dti',
    icon: '📊',
    name: 'DTI Ratio EUR',
    description: 'Debt-to-income Europe',
    country: 'europe',
    countryName: 'Europe',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/europe/dti',
    keywords: ['dti', 'ratio', 'europe', 'debt', 'income', 'eur'],
  ),
  _ToolDef(
    id: 'europe_property_tax_calc',
    icon: '🏛️',
    name: 'Property Tax Calc',
    description: 'Country-specific taxes',
    country: 'europe',
    countryName: 'Europe',
    category: 'Tax Tools',
    variant: ToolCardVariant.violet,
    route: '/tool/europe/propertytax',
    keywords: ['property', 'tax', 'europe', 'taxes', 'germany', 'france', 'spain'],
  ),
  _ToolDef(
    id: 'europe_affordability',
    icon: '💶',
    name: 'Affordability EUR',
    description: 'Borrowing capacity',
    country: 'europe',
    countryName: 'Europe',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/europe/affordability',
    keywords: ['affordability', 'europe', 'borrowing', 'capacity', 'eur'],
  ),
  _ToolDef(
    id: 'europe_euribor_tracker',
    icon: '🔄',
    name: 'Euribor Tracker',
    description: 'Variable rate index',
    country: 'europe',
    countryName: 'Europe',
    category: 'Market Tools',
    variant: ToolCardVariant.gold,
    route: '/tool/europe/euribor',
    keywords: ['euribor', 'tracker', 'europe', 'variable', 'rate', 'index'],
  ),
  _ToolDef(
    id: 'europe_country_comparison',
    icon: '🌍',
    name: 'Country Comparison',
    description: 'Compare EU rates',
    country: 'europe',
    countryName: 'Europe',
    category: 'Market Tools',
    variant: ToolCardVariant.teal,
    route: '/tool/europe/comparison',
    keywords: ['country', 'comparison', 'europe', 'rates', 'germany', 'france', 'italy'],
  ),
  _ToolDef(
    id: 'europe_notary_fee_calc',
    icon: '📜',
    name: 'Notary Fee Calc',
    description: 'DE/FR/ES closing costs',
    country: 'europe',
    countryName: 'Europe',
    category: 'Tax Tools',
    variant: ToolCardVariant.light,
    route: '/tool/europe/notaryfee',
    keywords: ['notary', 'fee', 'europe', 'closing', 'costs', 'germany', 'france', 'spain'],
  ),
  _ToolDef(
    id: 'europe_currency_converter',
    icon: '💱',
    name: 'Currency Converter',
    description: 'EUR · GBP · USD · CHF',
    country: 'europe',
    countryName: 'Europe',
    category: 'Payment Tools',
    variant: ToolCardVariant.light,
    route: '/tool/europe/currency',
    keywords: ['currency', 'converter', 'europe', 'forex', 'eur', 'gbp', 'usd'],
  ),

  // ── INDIA (8) ─────────────────────────────────────────────────────────────
  _ToolDef(
    id: 'india_core_emi_calculator',
    icon: '🏠',
    name: 'EMI Calculator',
    description: 'Monthly installment',
    country: 'india',
    countryName: 'India',
    category: 'Mortgage Calculators',
    variant: ToolCardVariant.blue,
    route: '/tool/india/in_emi',
    keywords: ['emi', 'calculator', 'india', 'in', 'monthly', 'installment', 'home loan'],
  ),
  _ToolDef(
    id: 'india_core_amortization',
    icon: '📊',
    name: 'Amortization',
    description: 'Full repayment schedule',
    country: 'india',
    countryName: 'India',
    category: 'Amortization',
    variant: ToolCardVariant.light,
    route: '/tool/india/in_amortization',
    keywords: ['amortization', 'india', 'schedule', 'table', 'repayment'],
  ),
  _ToolDef(
    id: 'india_core_loan_eligibility',
    icon: '💰',
    name: 'Loan Eligibility',
    description: 'Max loan on salary',
    country: 'india',
    countryName: 'India',
    category: 'Affordability Tools',
    variant: ToolCardVariant.light,
    route: '/tool/india/in_loan_eligibility',
    keywords: ['loan', 'eligibility', 'india', 'salary', 'max', 'borrowing'],
  ),
  _ToolDef(
    id: 'india_core_prepayment_calc',
    icon: '📅',
    name: 'Prepayment Calc',
    description: 'Part payment savings',
    country: 'india',
    countryName: 'India',
    category: 'Payment Tools',
    variant: ToolCardVariant.gold,
    route: '/tool/india/in_prepayment',
    keywords: ['prepayment', 'india', 'part payment', 'savings', 'interest'],
  ),
  _ToolDef(
    id: 'india_govt_stamp_duty_calc',
    icon: '🏛️',
    name: 'Stamp Duty Calc',
    description: 'State-wise rates',
    country: 'india',
    countryName: 'India',
    category: 'Tax Tools',
    variant: ToolCardVariant.light,
    route: '/tool/india/in_stamp_duty',
    keywords: ['stamp', 'duty', 'india', 'state', 'tax', 'registration'],
  ),
  _ToolDef(
    id: 'india_govt_pmay_subsidy',
    icon: '🎁',
    name: 'PMAY Subsidy',
    description: 'Govt. interest subsidy',
    country: 'india',
    countryName: 'India',
    category: 'Government Programs',
    variant: ToolCardVariant.green,
    route: '/tool/india/in_pmay',
    keywords: ['pmay', 'subsidy', 'india', 'pradhan mantri', 'government', 'interest'],
  ),
  _ToolDef(
    id: 'india_govt_cibil_score_impact',
    icon: '💳',
    name: 'CIBIL Score Impact',
    description: 'Score-to-rate effect',
    country: 'india',
    countryName: 'India',
    category: 'Market Tools',
    variant: ToolCardVariant.light,
    route: '/tool/india/in_cibil',
    keywords: ['cibil', 'score', 'india', 'credit score', 'rate impact'],
  ),
  _ToolDef(
    id: 'india_nri_home_loan',
    icon: '🌐',
    name: 'NRI Home Loan',
    description: 'Full eligibility guide',
    country: 'india',
    countryName: 'India',
    category: 'Government Programs',
    variant: ToolCardVariant.light,
    route: '/tool/india/in_nri_home_loan',
    keywords: ['nri', 'home loan', 'india', 'non resident', 'eligibility'],
  ),
  _ToolDef(
    id: 'global_top_lenders',
    icon: '🏛️',
    name: 'Top Lenders',
    description: 'Top lenders across 5 countries',
    country: 'global',
    countryName: 'Global',
    category: 'Market Tools',
    variant: ToolCardVariant.gold,
    route: '/global/top-lenders',
    keywords: ['lenders', 'top lenders', 'global', 'banks', 'rates'],
  ),
];

// ── Country Meta details (flag, rate, label) matching HTML ─────────────────
class _CountryGroupMeta {
  final String key;
  final String name;
  final String flag;
  final String meta;
  final String rateValue;
  final String rateLabel;
  final Color rateColor;
  final String seeAllText;
  final String countryCode;

  const _CountryGroupMeta({
    required this.key,
    required this.name,
    required this.flag,
    required this.meta,
    required this.rateValue,
    required this.rateLabel,
    required this.rateColor,
    required this.seeAllText,
    required this.countryCode,
  });
}

const List<_CountryGroupMeta> _countryGroups = [
  _CountryGroupMeta(
    key: 'usa',
    name: 'United States',
    flag: '🇺🇸',
    meta: 'USD · Freddie Mac PMMS',
    rateValue: '6.47%',
    rateLabel: '30-Yr Fixed',
    rateColor: Color(0xFF1A3A8F),
    seeAllText: 'See all 19 USA tools →',
    countryCode: 'usa',
  ),
  _CountryGroupMeta(
    key: 'canada',
    name: 'Canada',
    flag: '🇨🇦',
    meta: 'CAD · Bank of Canada',
    rateValue: '3.99%',
    rateLabel: '5-Yr Fixed',
    rateColor: Color(0xFF15803D),
    seeAllText: 'See all 8 Canada tools →',
    countryCode: 'canada',
  ),
  _CountryGroupMeta(
    key: 'uk',
    name: 'United Kingdom',
    flag: '🇬🇧',
    meta: 'GBP · Bank of England',
    rateValue: '4.48%',
    rateLabel: '5-Yr Fixed',
    rateColor: Color(0xFFB45309),
    seeAllText: 'See all 10 UK tools →',
    countryCode: 'uk',
  ),
  _CountryGroupMeta(
    key: 'australia',
    name: 'Australia',
    flag: '🇦🇺',
    meta: 'AUD · Reserve Bank of Australia',
    rateValue: '4.35%',
    rateLabel: 'RBA Cash Rate',
    rateColor: Color(0xFFD97706),
    seeAllText: 'See all 10 Australia tools →',
    countryCode: 'australia',
  ),
  _CountryGroupMeta(
    key: 'newzealand',
    name: 'New Zealand',
    flag: '🇳🇿',
    meta: 'NZD · Reserve Bank of NZ',
    rateValue: '2.25%',
    rateLabel: 'OCR',
    rateColor: Color(0xFF0D9488),
    seeAllText: 'See all 20 New Zealand tools →',
    countryCode: 'newzealand',
  ),
  _CountryGroupMeta(
    key: 'europe',
    name: 'Europe',
    flag: '🇪🇺',
    meta: 'EUR · 6 countries · ECB',
    rateValue: '2.40%',
    rateLabel: 'ECB Refi Rate',
    rateColor: Color(0xFF6D28D9),
    seeAllText: 'See all 10 Europe tools →',
    countryCode: 'europe',
  ),
  _CountryGroupMeta(
    key: 'india',
    name: 'India',
    flag: '🇮🇳',
    meta: 'INR · Reserve Bank of India',
    rateValue: '5.25%',
    rateLabel: 'RBI Repo Rate',
    rateColor: Color(0xFFFF6B00),
    seeAllText: 'See all 19 India tools →',
    countryCode: 'india',
  ),
];

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  String _searchQuery = '';
  String _selectedCountryFilter = 'All'; // 'All', 'usa', 'canada', etc.
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _DT.update(context);

    // Filter tools list based on search and country filter
    List<_ToolDef> filteredToolsList;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filteredToolsList = _allTools.where((t) {
        final matchesQuery = t.name.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query) ||
            t.countryName.toLowerCase().contains(query) ||
            t.keywords.any((kw) => kw.contains(query));

        if (_selectedCountryFilter == 'All') {
          return matchesQuery;
        } else {
          return matchesQuery && t.country == _selectedCountryFilter;
        }
      }).toList();
    } else {
      if (_selectedCountryFilter == 'All') {
        filteredToolsList = _allTools;
      } else {
        filteredToolsList =
            _allTools.where((t) => t.country == _selectedCountryFilter).toList();
      }
    }

    return Scaffold(
      backgroundColor: _DT.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Gradient Header with Search and Filter pills ───────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B1D3A),
                        Color(0xFF1B3F72),
                        Color(0xFF0D9488),
                      ],
                      stops: [0.0, 0.50, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        // Decorative Wrench emoji watermark (🔧)
                        Positioned(
                          right: 16,
                          top: 40,
                          child: Text(
                            '🔧',
                            style: TextStyle(
                              fontSize: 80,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Screen Title & Notification Icon
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Tools ',
                                                style: AppTextStyles.playfair(
                                                    size: 20,
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Find calculators, resources and mortgage planning tools.',
                                          style: AppTextStyles.dmSans(
                                            size: 10.5,
                                            weight: FontWeight.w500,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.20)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('🔔',
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.20)),
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      AnalyticsService.instance.logSearchPerformed(filteredToolsList.length);
                                    }
                                  },
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    hintText:
                                        'Search EMI, stamp duty, refinance…',
                                    hintStyle: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.55),
                                      fontSize: 12.5,
                                      fontFamily: 'DMSans',
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.white70,
                                                size: 16),
                                            onPressed: () {
                                              setState(() {
                                                _searchQuery = '';
                                                _searchCtrl.clear();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Horizontal Country Pill selector
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterPill('All', '🌐 All'),
                                    ..._countryGroups.map((g) =>
                                        _buildFilterPill(
                                            g.key, '${g.flag} ${g.name}')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Search Results Grid (when searching) ───────────────────────
              if (_searchQuery.isNotEmpty) ...[
                if (filteredToolsList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 12),
                            Text(
                              'No tools found',
                              style: AppTextStyles.playfair(
                                  size: 16, color: _DT.navy),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for another keyword or term.',
                              style: AppTextStyles.dmSans(
                                  size: 12, color: _DT.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(15, 16, 15, 110),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tool = filteredToolsList[index];
                          return _buildToolCardWithFavorite(tool, searchIndex: index);
                        },
                        childCount: filteredToolsList.length,
                      ),
                    ),
                  ),
              ]

              // ── Grouped Country View (when not searching) ──────────────────
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final group = _countryGroups[index];
                      // Skip if country filter is active and doesn't match
                      if (_selectedCountryFilter != 'All' &&
                          _selectedCountryFilter != group.key) {
                        return const SizedBox.shrink();
                      }

                      final countryTools = _allTools
                          .where((t) => t.country == group.key)
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // Country Group Header
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _DT.border,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(group.flag,
                                      style: const TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: AppTextStyles.dmSans(
                                          size: 14,
                                          weight: FontWeight.w800,
                                          color: _DT.navy,
                                        ),
                                      ),
                                      Text(
                                        group.meta,
                                        style: AppTextStyles.dmSans(
                                          size: 9.5,
                                          weight: FontWeight.w400,
                                          color: _DT.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      group.rateValue,
                                      style: AppTextStyles.dmSans(
                                        size: 14,
                                        weight: FontWeight.w800,
                                        color: group.rateColor,
                                      ),
                                    ),
                                    Text(
                                      group.rateLabel,
                                      style: AppTextStyles.dmSans(
                                        size: 8,
                                        weight: FontWeight.w600,
                                        color: _DT.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(height: 1, color: _DT.border),
                            const SizedBox(height: 10),

                            // 2-Column Grid of Tools
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
                              itemCount: countryTools.length,
                              itemBuilder: (context, i) {
                                final tool = countryTools[i];
                                return _buildToolCardWithFavorite(tool);
                              },
                            ),
                            const SizedBox(height: 10),

                            // See all Tools link footer
                            GestureDetector(
                              onTap: () {
                                // Navigate to the country's full screen
                                context.push('/${group.countryCode}');
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  group.seeAllText,
                                  style: AppTextStyles.dmSans(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: _DT.royal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                    childCount: _countryGroups.length,
                  ),
                ),
                // Padding at bottom for navigation bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 110),
                ),
              ],
            ],
          ),

          // ── Bottom Nav ─────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 2,
              activeColor: _DT.royal,
              countryIcon: '🛠️',
              countryLabel: 'Tools',
              countryRoute: '/tools',
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal country pill builder
  Widget _buildFilterPill(String filterKey, String displayLabel) {
    final isActive = _selectedCountryFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCountryFilter = filterKey;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? _DT.gold
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive
                ? _DT.gold
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isActive ? _DT.navy : Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
          ),
        ),
      ),
    );
  }

  // Builder for ToolCard wrapped with a dynamic Favorite toggle button
  Widget _buildToolCardWithFavorite(_ToolDef tool, {int? searchIndex}) {
    final flag = _countryGroups.firstWhere(
      (g) => g.key == tool.country,
      orElse: () => const _CountryGroupMeta(
        key: '',
        name: '',
        flag: '🌐',
        meta: '',
        rateValue: '',
        rateLabel: '',
        rateColor: Colors.transparent,
        seeAllText: '',
        countryCode: '',
      ),
    ).flag;

    return ToolCard(
      toolId: tool.id,
      flagIcon: flag,
      icon: tool.icon,
      name: tool.name,
      description: tool.description,
      variant: tool.variant,
      badgeText: tool.badgeText,
      badgeTextColor: tool.badgeTextColor,
      badgeBgColor: tool.badgeBgColor,
      onTap: () {
        if (searchIndex != null) {
          AnalyticsService.instance.logSearchResultOpened(
            resultIndex: searchIndex,
            searchTerm: _searchQuery,
            toolId: tool.id,
          );
        }
        context.push(tool.route);
      },
    );
  }
}

typedef ToolDef = _ToolDef;
const allToolsList = _allTools;

