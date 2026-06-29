// lib/features/india/india_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/country_header.dart';
import '../../shared/widgets/hero_calculator_card.dart';
import '../../shared/widgets/tool_card.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/alert_banner.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/section_label.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/mortgage_math.dart';
import '../../shared/widgets/result_panel.dart';
import '../../shared/widgets/deep_link_highlight_wrapper.dart';

class IndiaScreen extends StatefulWidget {
  final String? toolId;
  final bool fallback;

  const IndiaScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  State<IndiaScreen> createState() => _IndiaScreenState();
}

class _IndiaScreenState extends State<IndiaScreen> {
  final Map<String, GlobalKey> _cardKeys = {};

  GlobalKey _getKey(String id) {
    return _cardKeys.putIfAbsent(id, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    if (widget.toolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _cardKeys[widget.toolId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.15,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant IndiaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toolId != null && widget.toolId != oldWidget.toolId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _cardKeys[widget.toolId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.15,
          );
        }
      });
    }
  }

  static const _theme = CountryThemes.india;
  final double _loanAmount = 5000000;
  final double _ratePercent = 8.50;
  final int _termYears = 20;

  static const _rates = [
    RateItem(
        label: 'Repo Rate',
        value: '6.50%',
        note: 'RBI 2024',
        color: RateColor.gold),
    RateItem(label: 'Home Loan', value: '8.50%', note: 'SBI Avg'),
    RateItem(
        label: 'CPI Inflation',
        value: '5.10%',
        note: 'Apr 2024',
        color: RateColor.green),
    RateItem(label: 'Sensex', value: '74,683', note: 'BSE'),
  ];

  void _calculate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/india/emi/result'),
      builder: (_) => _IndiaCalcSheet(
          loanAmount: _loanAmount, rate: _ratePercent, termYears: _termYears),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CountryHeader(
                  theme: _theme,
                  rates: _rates,
                  onBack: () => context.go('/'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (widget.fallback) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text('⚠️', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tool not found. Showing available calculators.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SectionLabel(
                      text: 'Quick EMI Estimate',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    HeroCalculatorCard(
                      theme: _theme,
                      tag: 'भारत Home Loan EMI Calculator',
                      titleLine1: 'Calculate your',
                      accentWord: 'Home Loan EMI',
                      titleLine2: 'with processing fees',
                      buttonEmoji: '☸',
                      buttonText: 'Calculate Home Loan EMI',
                      inputs: [
                        HeroInputBox(
                            label: 'Loan Amount',
                            value: CurrencyFormatter.compact(_loanAmount,
                                symbol: '₹')),
                        HeroInputBox(
                            label: 'Interest Rate',
                            value: '${_ratePercent.toStringAsFixed(2)}%'),
                        HeroInputBox(label: 'Tenure', value: '$_termYears yr'),
                      ],
                      onCalculate: _calculate,
                      buttonGradient: LinearGradient(
                        colors: [
                          _theme.primaryColor,
                          _theme.primaryColor.withValues(alpha: 0.8)
                        ],
                      ),
                    ),

                    // RBI Banner
                    SectionLabel(
                      text: 'Reserve Bank of India',
                      moreText: 'RBI Policy →',
                      onMoreTap: () =>
                          context.push('/tool/india/in_rbi_monetary_policy'),
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _RBIBanner(),

                    // Indian Market Snapshot
                    SectionLabel(
                      text: 'Market Snapshot',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _IndiaMarketTicker(),

                    // Live Bank Home Loan Rates Scrollable
                    SectionLabel(
                      text: 'Live Bank Home Loan Rates',
                      moreText: 'Compare All →',
                      onMoreTap: () =>
                          context.push('/tool/india/in_compare_banks'),
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _BankRatesScroll(),

                    // Core Home Loan Tools Grid
                    SectionLabel(
                      text: 'Core Home Loan Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _coreToolsGrid(context),

                    // Govt Housing Schemes & GST Banners
                    SectionLabel(
                      text: 'Govt. Housing Schemes',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    AlertBanner(
                      icon: '🏡',
                      title: 'PMAY – Pradhan Mantri Awas Yojana',
                      subtitle:
                          'Interest subsidy up to ₹2.67 Lakh · EWS/LIG/MIG eligible',
                      buttonText: 'Check Eligibility',
                      bgColor1: const Color(0xFFECFDF5),
                      bgColor2: const Color(0xFFD1FAE5),
                      borderColor: const Color(0xFF6EE7B7),
                      buttonColor: const Color(0xFF046A38),
                      titleColor: const Color(0xFF07543A),
                      subtitleColor: const Color(0xFF046A38),
                      onTap: () =>
                          context.push('/tool/india/in_pmay_housing_for_all'),
                    ),
                    const SizedBox(height: 10),
                    AlertBanner(
                      icon: '📋',
                      title: 'GST on Property Purchase',
                      subtitle:
                          'Under-construction: 5% GST · Ready possession: Nil · RERA check',
                      buttonText: 'GST Calc',
                      bgColor1: const Color(0xFFFFF3E0),
                      bgColor2: const Color(0xFFFFEDD5),
                      borderColor: const Color(0xFFFDBA74),
                      buttonColor: const Color(0xFFFF6B00),
                      titleColor: const Color(0xFF9A3412),
                      subtitleColor: const Color(0xFFC2410C),
                      onTap: () => context.push('/tool/india/in_gst_property'),
                    ),

                    // Tax & Government Tools Grid
                    SectionLabel(
                      text: 'Tax & Government Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _taxGovToolsGrid(context),

                    // Personal Finance Grid
                    SectionLabel(
                      text: 'Personal Finance',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _personalFinanceGrid(context),

                    // City Property Prices
                    SectionLabel(
                      text: 'City Property Prices',
                      moreText: 'All Cities →',
                      onMoreTap: () =>
                          context.push('/tool/india/in_city_property_prices'),
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _CityPricesScroll(),

                    // State Stamp Duty
                    SectionLabel(
                      text: 'Stamp Duty by State',
                      moreText: 'All States →',
                      onMoreTap: () =>
                          context.push('/tool/india/in_stamp_duty_all_states'),
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _stateStampDutyGrid(context),

                    // NRI Home Loan Tools
                    SectionLabel(
                      text: 'NRI Home Loan Tools',
                      moreText: 'NRI Guide →',
                      onMoreTap: () =>
                          context.push('/tool/india/in_nri_home_loan'),
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _nriToolsGrid(context),

                    // Top Banks & HFCs Scroll
                    SectionLabel(
                      text: 'Top Banks & HFCs',
                      moreText: 'Compare →',
                      onMoreTap: () =>
                          context.push('/tool/india/in_banks_hfcs_compare'),
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _LendersScroll(),

                    // Resources & Government List
                    SectionLabel(
                      text: 'Resources & Government',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    ..._resources(context),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 1,
              activeColor: _theme.primaryColor,
              countryIcon: _theme.flag,
              countryLabel: 'India',
              countryRoute: '/india',
            ),
          ),
        ],
      ),
    );
  }

  Widget _coreToolsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'india_core_emi_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_emi_calculator'),
            toolId: 'india_core_emi_calculator',
            flagIcon: '🇮🇳',
            icon: '🏠',
            name: 'EMI Calculator',
            description: 'Monthly installment',
            variant: ToolCardVariant.dark,
            badgeText: '₹ INR',
            badgeTextColor: const Color(0xFFE05A00),
            badgeBgColor: const Color(0xFFFFF3E0),
            onTap: () => context.push('/tool/india/in_emi'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_amortization',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_amortization'),
            toolId: 'india_core_amortization',
            flagIcon: '🇮🇳',
            icon: '📊',
            name: 'Amortization',
            description: 'Full repayment schedule',
            onTap: () => context.push('/tool/india/in_amortization'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_loan_eligibility',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_loan_eligibility'),
            toolId: 'india_core_loan_eligibility',
            flagIcon: '🇮🇳',
            icon: '💰',
            name: 'Loan Eligibility',
            description: 'Max loan on salary',
            badgeText: 'FOIR Check',
            badgeTextColor: const Color(0xFF065F46),
            badgeBgColor: const Color(0xFFECFDF5),
            onTap: () => context.push('/tool/india/in_loan_eligibility'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_prepayment_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_prepayment_calc'),
            toolId: 'india_core_prepayment_calc',
            flagIcon: '🇮🇳',
            icon: '📅',
            name: 'Prepayment Calc',
            description: 'Part payment savings',
            variant: ToolCardVariant.red,
            onTap: () => context.push('/tool/india/in_prepayment'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_balance_transfer',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_balance_transfer'),
            toolId: 'india_core_balance_transfer',
            flagIcon: '🇮🇳',
            icon: '🔄',
            name: 'Balance Transfer',
            description: 'Switch bank savings',
            onTap: () => context.push('/tool/india/in_balance_transfer'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_foir_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_foir_calculator'),
            toolId: 'india_core_foir_calculator',
            flagIcon: '🇮🇳',
            icon: '📈',
            name: 'FOIR Calculator',
            description: 'Fixed obligation ratio',
            variant: ToolCardVariant.green,
            onTap: () => context.push('/tool/india/in_foir'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_under_construction',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_under_construction'),
            toolId: 'india_core_under_construction',
            flagIcon: '🇮🇳',
            icon: '🏗️',
            name: 'Under Construction',
            description: 'Pre-EMI vs full EMI',
            onTap: () => context.push('/tool/india/in_under_construction'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_joint_loan_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_joint_loan_calc'),
            toolId: 'india_core_joint_loan_calc',
            flagIcon: '🇮🇳',
            icon: '🤝',
            name: 'Joint Loan Calc',
            description: 'Co-applicant benefit',
            variant: ToolCardVariant.gold,
            onTap: () => context.push('/tool/india/in_joint_loan'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_floating_vs_fixed',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_floating_vs_fixed'),
            toolId: 'india_core_floating_vs_fixed',
            flagIcon: '🇮🇳',
            icon: '📉',
            name: 'Floating vs Fixed',
            description: 'Rate type comparison',
            onTap: () => context.push('/tool/india/in_floating_vs_fixed'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_core_car_loan_emi',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_core_car_loan_emi'),
            toolId: 'india_core_car_loan_emi',
            flagIcon: '🇮🇳',
            icon: '🏎️',
            name: 'Car Loan EMI',
            description: 'Vehicle financing',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/india/in_car_loan'),
          ),
        ),
      ],
    );
  }

  Widget _taxGovToolsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_stamp_duty_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_stamp_duty_calc'),
            toolId: 'india_govt_stamp_duty_calc',
            flagIcon: '🇮🇳',
            icon: '🏛️',
            name: 'Stamp Duty Calc',
            description: 'State-wise stamp duty',
            variant: ToolCardVariant.dark,
            badgeText: 'All States',
            badgeTextColor: const Color(0xFFE05A00),
            badgeBgColor: const Color(0xFFFFF3E0),
            onTap: () => context.push('/tool/india/in_stamp_duty_calc'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_gst_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_gst_calculator'),
            toolId: 'india_govt_gst_calculator',
            flagIcon: '🇮🇳',
            icon: '📋',
            name: 'GST Calculator',
            description: 'GST split & slabs',
            onTap: () => context.push('/tool/india/in_gst_calculator'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_pmay_subsidy',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_pmay_subsidy'),
            toolId: 'india_govt_pmay_subsidy',
            flagIcon: '🇮🇳',
            icon: '🏠',
            name: 'PMAY Subsidy',
            description: 'Interest subsidy calc',
            badgeText: '₹2.67L max',
            badgeTextColor: const Color(0xFF065F46),
            badgeBgColor: const Color(0xFFECFDF5),
            onTap: () => context.push('/tool/india/in_pmay_subsidy'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_section_80c',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_section_80c'),
            toolId: 'india_govt_section_80c',
            flagIcon: '🇮🇳',
            icon: '📘',
            name: 'Section 80C Calc',
            description: 'Principal deductions',
            onTap: () => context.push('/tool/india/in_section_80c'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_section_24b',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_section_24b'),
            toolId: 'india_govt_section_24b',
            flagIcon: '🇮🇳',
            icon: '💳',
            name: 'Section 24(b) Calc',
            description: 'Home loan interest',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/india/in_section_24b'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_80c_24b_guide',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_80c_24b_guide'),
            toolId: 'india_govt_80c_24b_guide',
            flagIcon: '🇮🇳',
            icon: '📋',
            name: 'Tax Guide 80C/24b',
            description: 'Combined savings',
            variant: ToolCardVariant.violet,
            onTap: () => context.push('/tool/india/in_80c_24b_guide'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_cibil_score_impact',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_cibil_score_impact'),
            toolId: 'india_govt_cibil_score_impact',
            flagIcon: '🇮🇳',
            icon: '💳',
            name: 'CIBIL Score Impact',
            description: 'Score → loan rate',
            badgeText: '750+ ideal',
            badgeTextColor: const Color(0xFF1D4ED8),
            badgeBgColor: const Color(0xFFEFF6FF),
            onTap: () => context.push('/tool/india/in_cibil'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_tds_on_property',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_tds_on_property'),
            toolId: 'india_govt_tds_on_property',
            flagIcon: '🇮🇳',
            icon: '📊',
            name: 'TDS on Property',
            description: '1% TDS >₹50L',
            variant: ToolCardVariant.slate,
            onTap: () => context.push('/tool/india/in_tds'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_govt_capital_gains_tax',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_govt_capital_gains_tax'),
            toolId: 'india_govt_capital_gains_tax',
            flagIcon: '🇮🇳',
            icon: '🔑',
            name: 'Capital Gains Tax',
            description: 'LTCG / STCG calc',
            variant: ToolCardVariant.violet,
            onTap: () => context.push('/tool/india/in_capital_gains'),
          ),
        ),
      ],
    );
  }

  Widget _personalFinanceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_personal_loan_emi',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_personal_loan_emi'),
            toolId: 'india_pf_personal_loan_emi',
            flagIcon: '🇮🇳',
            icon: '💼',
            name: 'Personal Loan EMI',
            description: 'Unsecured loan calc',
            variant: ToolCardVariant.dark,
            onTap: () => context.push('/tool/india/in_personal_loan_emi'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_education_loan',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_education_loan'),
            toolId: 'india_pf_education_loan',
            flagIcon: '🇮🇳',
            icon: '📚',
            name: 'Education Loan',
            description: '80E tax benefit',
            onTap: () => context.push('/tool/india/in_education_loan'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_ppf_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_ppf_calculator'),
            toolId: 'india_pf_ppf_calculator',
            flagIcon: '🇮🇳',
            icon: '💰',
            name: 'PPF Calculator',
            description: 'Public Provident Fund',
            badgeText: '7.1% PA',
            badgeTextColor: const Color(0xFF065F46),
            badgeBgColor: const Color(0xFFECFDF5),
            onTap: () => context.push('/tool/india/in_ppf_calculator'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_epf_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_epf_calculator'),
            toolId: 'india_pf_epf_calculator',
            flagIcon: '🇮🇳',
            icon: '🏆',
            name: 'EPF Calculator',
            description: 'Provident Fund returns',
            variant: ToolCardVariant.gold,
            onTap: () => context.push('/tool/india/in_epf_calculator'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_sip_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_sip_calculator'),
            toolId: 'india_pf_sip_calculator',
            flagIcon: '🇮🇳',
            icon: '📈',
            name: 'SIP Calculator',
            description: 'Mutual fund returns',
            onTap: () => context.push('/tool/india/in_sip_calculator'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_nps_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_nps_calculator'),
            toolId: 'india_pf_nps_calculator',
            flagIcon: '🇮🇳',
            icon: '🏖️',
            name: 'NPS Calculator',
            description: 'National Pension Scheme',
            variant: ToolCardVariant.green,
            onTap: () => context.push('/tool/india/in_nps_calculator'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_income_tax_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_income_tax_calc'),
            toolId: 'india_pf_income_tax_calc',
            flagIcon: '🇮🇳',
            icon: '🧾',
            name: 'Income Tax Calc',
            description: 'Old vs New regime',
            badgeText: 'FY 2025–26',
            badgeTextColor: const Color(0xFFC2410C),
            badgeBgColor: const Color(0xFFFFF7ED),
            onTap: () => context.push('/tool/india/in_income_tax_calculator'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_gold_loan_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_gold_loan_calc'),
            toolId: 'india_pf_gold_loan_calc',
            flagIcon: '🇮🇳',
            icon: '💎',
            name: 'Gold Loan Calc',
            description: 'LTV · EMI on gold',
            variant: ToolCardVariant.maple,
            onTap: () => context.push('/tool/india/in_gold_loan_calculator'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_lap_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_lap_calculator'),
            toolId: 'india_pf_lap_calculator',
            flagIcon: '🇮🇳',
            icon: '🏪',
            name: 'LAP Calculator',
            description: 'Loan Against Property',
            onTap: () => context.push('/tool/india/in_lap_calculator'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_pf_ai_advisor',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_pf_ai_advisor'),
            toolId: 'india_pf_ai_advisor',
            flagIcon: '🇮🇳',
            icon: '🤖',
            name: 'India AI Advisor',
            description: 'RBI · PMAY · tax guidance',
            variant: ToolCardVariant.violet,
            onTap: () => context.push('/tool/india/in_india_ai_advisor'),
          ),
        ),
      ],
    );
  }

  Widget _stateStampDutyGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.05,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'india_state_maharashtra',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('india_state_maharashtra'),
              toolId: 'india_state_maharashtra',
              flagIcon: '🇮🇳',
              icon: '🌆',
              name: 'Maharashtra',
              description: '5–6% + Metro',
              onTap: () => context.push('/tool/india/in_stamp_duty_all_states'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_state_delhi',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('india_state_delhi'),
              toolId: 'india_state_delhi',
              flagIcon: '🇮🇳',
              icon: '🏙️',
              name: 'Delhi',
              description: '4% Women · 6% Men',
              variant: ToolCardVariant.dark,
              onTap: () =>
                  context.push('/tool/india/in_stamp_duty_all_states')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_state_karnataka',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('india_state_karnataka'),
              toolId: 'india_state_karnataka',
              flagIcon: '🇮🇳',
              icon: '💻',
              name: 'Karnataka',
              description: '5% + Reg 1%',
              onTap: () => context.push('/tool/india/in_stamp_duty_all_states'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_state_tamil_nadu',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('india_state_tamil_nadu'),
              toolId: 'india_state_tamil_nadu',
              flagIcon: '🇮🇳',
              icon: '🌊',
              name: 'Tamil Nadu',
              description: '7% + Reg 4%',
              variant: ToolCardVariant.red,
              onTap: () =>
                  context.push('/tool/india/in_stamp_duty_all_states')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_state_telangana',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('india_state_telangana'),
              toolId: 'india_state_telangana',
              flagIcon: '🇮🇳',
              icon: '🏗️',
              name: 'Telangana',
              description: '4% + Reg 0.5%',
              onTap: () => context.push('/tool/india/in_stamp_duty_all_states'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_state_all_states',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('india_state_all_states'),
              toolId: 'india_state_all_states',
              flagIcon: '🇮🇳',
              icon: '🗺️',
              name: 'All 28 States',
              description: 'Complete state guide',
              variant: ToolCardVariant.green,
              onTap: () =>
                  context.push('/tool/india/in_stamp_duty_all_states')),
        ),
      ],
    );
  }

  Widget _nriToolsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'india_nri_home_loan',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_nri_home_loan'),
            toolId: 'india_nri_home_loan',
            flagIcon: '🇮🇳',
            icon: '✈️',
            name: 'NRI Home Loan',
            description: 'Eligibility & EMI calc',
            variant: ToolCardVariant.dark,
            badgeText: 'NRI/PIO/OCI',
            badgeTextColor: const Color(0xFF1D4ED8),
            badgeBgColor: const Color(0xFFEFF6FF),
            onTap: () => context.push('/tool/india/in_nri_home_loan'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_nri_account',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_nri_account'),
            toolId: 'india_nri_account',
            flagIcon: '🇮🇳',
            icon: '💱',
            name: 'NRE/NRO Account',
            description: 'Repatriation rules',
            onTap: () => context.push('/tool/india/in_nre_nro_account'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_nri_fema_compliance',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_nri_fema_compliance'),
            toolId: 'india_nri_fema_compliance',
            flagIcon: '🇮🇳',
            icon: '📋',
            name: 'FEMA Compliance',
            description: 'Foreign exchange rules',
            onTap: () => context.push('/tool/india/in_fema_compliance'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'india_nri_usd_inr_converter',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('india_nri_usd_inr_converter'),
            toolId: 'india_nri_usd_inr_converter',
            flagIcon: '🇮🇳',
            icon: '🌐',
            name: 'USD/INR Converter',
            description: 'Remittance to India',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/india/in_usd_inr_converter'),
          ),
        ),
      ],
    );
  }

  List<Widget> _resources(BuildContext context) {
    final items = [
      (
        '🏛️',
        'RBI Repo Rate History',
        'Monetary Policy Committee decisions since 2000',
        '/tool/india/in_rbi_repo_rate_history'
      ),
      (
        '🏠',
        'PMAY – Housing for All',
        'Urban & Rural · EWS/LIG/MIG subsidy guide',
        '/tool/india/in_pmay_housing_for_all'
      ),
      (
        '📊',
        'NHB Residex — Property Index',
        'National Housing Bank city-level HPI',
        '/tool/india/in_nhb_residex'
      ),
      (
        '💳',
        'CIBIL / Experian Score Check',
        'Free credit score · impact on rates',
        '/tool/india/in_cibil'
      ),
      (
        '📋',
        'Section 80C / 24(b) Guide',
        'Income tax deductions on home loan',
        '/tool/india/in_80c_24b_guide'
      ),
      (
        '🤖',
        'India AI Mortgage Advisor',
        'RBI · PMAY · RERA · tax guidance',
        '/tool/india/in_india_ai_advisor'
      ),
    ];
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InfoCard(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
                onTap: () => context.push(item.$4),
                iconBgColor: _theme.getBgColor(context),
                titleColor: _theme.getTextColor(context),
                subtitleColor: _theme.getMutedColor(context),
                borderColor: _theme.getBorderColor(context),
              ),
            ))
        .toList();
  }
}

// ─── RBI Repo Rate Banner ──────────────────────────────────────────
class _RBIBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(
        children: [
          const Text('🏛️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RBI REPO RATE · MONETARY POLICY',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.44),
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '6.50%',
                  style: AppTextStyles.dmSans(
                    size: 23,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFFDEA0),
                  ),
                ),
                Text(
                  'Next MPC Meeting: Jun 7 · Rate cut expected Q3 2024',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/tool/india/in_rbi_monetary_policy'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'RBI Live',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Indian Market Snapshot ──────────────────────────────────────
class _IndiaMarketTicker extends StatelessWidget {
  static const _items = [
    ('Sensex', '74,683', '+0.55%', true),
    ('Nifty 50', '22,643', '+0.48%', true),
    ('USD/INR', '83.52', '+0.12%', false),
    ('Nifty Realty', '897.4', '+1.20%', true),
    ('10-Yr G-Sec', '7.05%', '-0.02', false),
    ('Gold (10g)', '₹72,400', '+0.30%', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x1AFF6B00)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 16,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Indian Financial Markets',
                  style: AppTextStyles.infoTitle(const Color(0xFF0B1F48))),
              Text('● Live',
                  style: AppTextStyles.dmSans(
                      size: 10, color: const Color(0xFFFF6B00))),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: _items
                .map((item) => Column(
                      children: [
                        Text(item.$1,
                            style: AppTextStyles.rateLabel(
                                const Color(0xFF7A5C3A)),
                            textAlign: TextAlign.center),
                        Text(item.$2,
                            style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w700,
                                color: const Color(0xFF0B1F48)),
                            textAlign: TextAlign.center),
                        Text(item.$3,
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w700,
                                color: item.$4
                                    ? const Color(0xFF046A38)
                                    : const Color(0xFFE05A00)),
                            textAlign: TextAlign.center),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Live Bank Home Loan Rates Scroll ──────────────────────────────
class _BankRatesScroll extends StatelessWidget {
  static const _rates = [
    ('🏦', 'SBI', '8.50%', 'State Bank', '↓ Best', true),
    ('🏛️', 'HDFC Bank', '8.70%', 'Floating', '↑ +0.20', false),
    ('🏢', 'ICICI Bank', '8.75%', 'Floating', '↑ +0.25', false),
    ('🏦', 'Axis Bank', '8.75%', 'Floating', '↑ +0.25', false),
    ('🏗️', 'LIC HFL', '8.65%', 'HFC', '↓ -0.05', true),
    ('🌿', 'PNB HFL', '8.99%', 'HFC', 'Stable', true),
    ('🏦', 'Kotak', '8.85%', 'Private', '↑ +0.15', false),
  ];

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.india;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _rates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final r = _rates[i];
          return Container(
            width: 112,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.2
                            : 0.09),
                    blurRadius: 14,
                    offset: const Offset(0, 3))
              ],
            ),
            padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(r.$2,
                    style:
                        AppTextStyles.rateLabel(theme.getMutedColor(context))),
                Text(r.$3,
                    style: AppTextStyles.dmSans(
                        size: 16,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                Text(r.$4,
                    style:
                        AppTextStyles.rateNote(theme.getMutedColor(context))),
                Text(r.$5,
                    style: AppTextStyles.dmSans(
                        size: 9,
                        weight: FontWeight.w700,
                        color: r.$6
                            ? const Color(0xFF046A38)
                            : const Color(0xFFE05A00))),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── City Property Prices Scroll ───────────────────────────────────
class _CityPricesScroll extends StatelessWidget {
  static const _cities = [
    ('🌆', 'Mumbai', 'Maharashtra', '₹22,400/sqft', '↑ +3.2%', true),
    ('🏙️', 'Delhi NCR', 'Delhi/Noida/Gur.', '₹12,800/sqft', '↑ +4.1%', true),
    ('💻', 'Bengaluru', 'Karnataka', '₹11,500/sqft', '↑ +5.8%', true),
    ('🌊', 'Chennai', 'Tamil Nadu', '₹8,200/sqft', '↑ +2.4%', true),
    ('🏗️', 'Hyderabad', 'Telangana', '₹9,100/sqft', '↑ +6.2%', true),
    ('🌸', 'Pune', 'Maharashtra', '₹8,600/sqft', '↑ +4.5%', true),
    ('🎶', 'Kolkata', 'West Bengal', '₹6,400/sqft', '↑ +1.9%', true),
    ('🌴', 'Ahmedabad', 'Gujarat', '₹5,800/sqft', '↑ +3.6%', true),
  ];

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.india;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final c = _cities[i];
          return Container(
            width: 118,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.2
                            : 0.09),
                    blurRadius: 14,
                    offset: const Offset(0, 3))
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 2),
                Text(c.$2,
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                Text(c.$3,
                    style:
                        AppTextStyles.rateNote(theme.getMutedColor(context))),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.$4,
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: const Color(0xFFFF6B00))),
                    Text(c.$5,
                        style: AppTextStyles.dmSans(
                            size: 9,
                            weight: FontWeight.w700,
                            color: c.$6
                                ? const Color(0xFF046A38)
                                : const Color(0xFFE05A00))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Top Banks & HFCs Scroll ──────────────────────────────────────
class _LendersScroll extends StatelessWidget {
  static const _lenders = [
    ('🏦', 'SBI Home Loan', '8.50%', 'Floating · PSU Bank'),
    ('🏛️', 'HDFC Bank', '8.70%', 'Floating · Private'),
    ('💼', 'ICICI Bank', '8.75%', 'Floating · Private'),
    ('⚡', 'Axis Bank', '8.75%', 'Floating · Private'),
    ('🏗️', 'LIC HFL', '8.65%', 'Fixed/Float · HFC'),
    ('🌿', 'PNB Housing', '8.99%', 'Floating · HFC'),
    ('🔶', 'Bajaj HFL', '8.55%', 'Floating · NBFC'),
  ];

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.india;
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _lenders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final l = _lenders[i];
          return Container(
            width: 115,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.2
                            : 0.09),
                    blurRadius: 14,
                    offset: const Offset(0, 3))
              ],
            ),
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(l.$2,
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                Text(l.$3,
                    style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w800,
                        color: const Color(0xFFFF6B00))),
                const Spacer(),
                Text(l.$4,
                    style:
                        AppTextStyles.rateNote(theme.getMutedColor(context))),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Calculator Bottom Sheet ──────────────────────────────────────
class _IndiaCalcSheet extends StatefulWidget {
  final double loanAmount, rate;
  final int termYears;

  const _IndiaCalcSheet(
      {required this.loanAmount, required this.rate, required this.termYears});

  @override
  State<_IndiaCalcSheet> createState() => _IndiaCalcSheetState();
}

class _IndiaCalcSheetState extends State<_IndiaCalcSheet> {
  late double _loan, _rate;
  late int _term;
  static const _theme = CountryThemes.india;

  @override
  void initState() {
    super.initState();
    _loan = widget.loanAmount;
    _rate = widget.rate;
    _term = widget.termYears;
  }

  double get _emi => MortgageMath.monthlyPayment(
      principal: _loan, annualRatePercent: _rate, termYears: _term);
  double get _totalInterest => MortgageMath.totalInterest(
      principal: _loan, annualRatePercent: _rate, termYears: _term);
  double get _taxBenefit =>
      _totalInterest > 0 ? (_totalInterest / _term).clamp(0, 200000) * 0.30 : 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).scaffoldBackgroundColor
                : const Color(0xFFFFF7EE),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('🕌 India EMI Calculator',
                style: AppTextStyles.dmSans(
                    size: 18,
                    weight: FontWeight.w800,
                    color: _theme.textColor)),
            const SizedBox(height: 20),
            ResultPanel(
              primaryColor: _theme.primaryColor,
              rows: [
                ResultRow(
                    label: 'Monthly EMI',
                    value: _emi,
                    currencyCode: 'INR',
                    isHighlighted: true),
                ResultRow(
                    label: 'Total Interest',
                    value: _totalInterest,
                    currencyCode: 'INR'),
                ResultRow(
                    label: 'Total Payment',
                    value: _loan + _totalInterest,
                    currencyCode: 'INR'),
                ResultRow(
                    label: 'Tax Benefit Est. (30%)',
                    value: _taxBenefit,
                    currencyCode: 'INR'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
