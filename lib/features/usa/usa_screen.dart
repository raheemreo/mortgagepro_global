// lib/features/usa/usa_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/country_header.dart';
import '../../shared/widgets/hero_calculator_card.dart';
import '../../shared/widgets/tool_card.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/alert_banner.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/section_label.dart';

import '../../core/utils/mortgage_math.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/usa_rates_provider.dart';
import 'tools/usa_mortgage_calc.dart';

import '../../shared/widgets/deep_link_highlight_wrapper.dart';

class USAScreen extends ConsumerStatefulWidget {
  final String? toolId;
  final bool fallback;

  const USAScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  ConsumerState<USAScreen> createState() => _USAScreenState();
}

class _USAScreenState extends ConsumerState<USAScreen> {
  static const _theme = CountryThemes.usa;

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
  void didUpdateWidget(covariant USAScreen oldWidget) {
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

  final double _homePrice = 450000;
  final double _downPct = 20;
  final int _termYears = 30;
  String? _resultText;

  void _calculate() {
    final loan = _homePrice * (1 - _downPct / 100);
    final rate30 = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    final monthly = MortgageMath.monthlyPayment(
      principal: loan,
      annualRatePercent: rate30,
      termYears: _termYears,
    );
    setState(() {
      _resultText =
          '${CurrencyFormatter.format(monthly, symbol: '\$')}/mo · Loan: ${CurrencyFormatter.compact(loan)}';
    });
    _showResultSheet(monthly, loan, rate30);
  }

  void _showResultSheet(double monthly, double loan, double rate30) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => USAMortgageCalcSheet(
        homePrice: _homePrice,
        downPercent: _downPct,
        termYears: _termYears,
        rate: rate30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rate30 =
        ref.watch(fredMortgage30Provider).valueOrNull?.formatted ?? '6.82%';
    final rate15 =
        ref.watch(fredMortgage15Provider).valueOrNull?.formatted ?? '6.11%';
    final rateSofr =
        ref.watch(fredSofrProvider).valueOrNull?.formatted ?? '6.05%';
    final rateFed =
        ref.watch(fredFedFundsProvider).valueOrNull?.formatted ?? '5.33%';

    final ratesList = [
      RateItem(
          label: '30-Yr Fixed',
          value: rate30,
          note: ref.watch(fredMortgage30Provider).valueOrNull?.isLive == true
              ? 'FRED Live'
              : 'Freddie Mac',
          color: RateColor.red),
      RateItem(
          label: '15-Yr Fixed',
          value: rate15,
          note: ref.watch(fredMortgage15Provider).valueOrNull?.isLive == true
              ? 'FRED Live'
              : 'Avg'),
      RateItem(
          label: '5/1 ARM',
          value: rateSofr,
          note: ref.watch(fredSofrProvider).valueOrNull?.isLive == true
              ? 'SOFR Live'
              : 'Avg'),
      RateItem(
          label: 'Fed Funds',
          value: rateFed,
          note: ref.watch(fredFedFundsProvider).valueOrNull?.isLive == true
              ? 'FRED Live'
              : 'FOMC',
          color: RateColor.gold),
    ];

    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CountryHeader(
                  theme: _theme,
                  rates: ratesList,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const SizedBox(height: 10),
                    ],
                    SectionLabel(
                      text: 'Quick Estimate',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    HeroCalculatorCard(
                      theme: _theme,
                      tag: 'USA Mortgage Calculator',
                      titleLine1: 'PITI · DTI ·',
                      accentWord: 'Amortization',
                      titleLine2: 'All-in-one payment',
                      buttonEmoji: '🦅',
                      buttonText: 'Calculate USA Mortgage (PITI)',
                      inputs: [
                        HeroInputBox(
                            label: 'Home Price',
                            value: CurrencyFormatter.compact(_homePrice)),
                        HeroInputBox(
                            label: 'Down Pmt.', value: '${_downPct.toInt()}%'),
                        HeroInputBox(label: 'Term', value: '$_termYears yr'),
                      ],
                      onCalculate: _calculate,
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    if (_resultText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _theme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('📊', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(
                              _resultText!,
                              style: AppTextStyles.dmSans(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Federal Reserve Banner
                    SectionLabel(
                      text: 'Federal Reserve',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _FedBanner(),

                    // Market Snapshot
                    SectionLabel(
                      text: 'Market Snapshot',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _MarketTicker(),


                    // Mortgage Rates H-scroll
                    SectionLabel(
                      text: 'Live Mortgage Rates',
                      moreText: 'Rate Trends →',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                      onMoreTap: () => context.push('/usa/rate-trends'),
                    ),
                    _MortgageRatesScroll(),

                    // Core Mortgage Tools
                    SectionLabel(
                      text: 'Core Mortgage Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _coreToolsGrid(context),

                    // Loan Programs
                    SectionLabel(
                      text: 'Loan Programs',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _loanProgramsGrid(context),

                    // Insurance & Tax
                    SectionLabel(
                      text: 'Insurance, Tax & Closing',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _insuranceTaxGrid(context),

                    // State Banner
                    SectionLabel(
                      text: 'State-by-State Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    AlertBanner(
                      icon: '🗺️',
                      title: 'Property Tax by State',
                      subtitle:
                          'NJ 2.23% · IL 2.08% · TX 1.60% · CA 0.76% · HI 0.29%',
                      buttonText: 'All States',
                      bgColor1: const Color(0xFFFEF3C7),
                      bgColor2: const Color(0xFFFDE68A),
                      borderColor: const Color(0xFFF59E0B),
                      buttonColor: const Color(0xFFD97706),
                      titleColor: const Color(0xFF92400E),
                      subtitleColor: const Color(0xFFB45309),
                      onTap: () => context.push('/usa/property-tax-by-state'),
                    ),
                    const SizedBox(height: 10),
                    _stateGrid(context),

                    // Personal Finance
                    SectionLabel(
                      text: 'Personal Finance',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _personalFinanceGrid(context),

                    // Real Estate Investment
                    SectionLabel(
                      text: 'Real Estate Investment',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _realEstateInvestmentGrid(context),

                    // Gov Programs / Resources
                    SectionLabel(
                      text: 'Gov. Programs & Retirement',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    ..._resources(context),

                    // Housing Market Data
                    SectionLabel(
                      text: 'Housing Market Data',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    ..._housingMarketData(context),

                    // Federal Reserve
                    SectionLabel(
                      text: 'Federal Reserve',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    AlertBanner(
                      icon: '🏛️',
                      title: 'Fed Funds Rate · FOMC',
                      subtitle:
                          '4.25–4.50% · Hold · Next FOMC: Jun 17–18 · ~22% cut prob.',
                      buttonText: 'FRED Live',
                      bgColor1: const Color(0xFFEFF6FF),
                      bgColor2: const Color(0xFFDBEAFE),
                      borderColor: const Color(0xFF1D4ED8),
                      buttonColor: const Color(0xFF1D4ED8),
                      titleColor: const Color(0xFF1E3A8A),
                      subtitleColor: const Color(0xFF1D4ED8),
                      onTap: () => context.push('/usa/fed-funds-rate'),
                    ),
                    const SizedBox(height: 10),
                    _fedReserveGrid(context),
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
              countryLabel: 'USA',
              countryRoute: '/usa',
            ),
          ),
        ],
      ),
    );
  }

  Widget _fedReserveGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        ToolCard(
          flagIcon: '🇺🇸',
          icon: '🏛️',
          name: 'Fed Funds Rate',
          description: 'FOMC target · FRED Live · 2025',
          variant: ToolCardVariant.dark,
          badgeText: 'FEDFUNDS',
          badgeTextColor: const Color(0xFF60A5FA),
          badgeBgColor: Colors.white.withValues(alpha: 0.15),
          onTap: () => context.push('/usa/fed-funds-rate'),
        ),
        ToolCard(
          flagIcon: '🇺🇸',
          icon: '🎯',
          name: 'FedWatch Tool',
          description: 'CME probabilities per meeting',
          onTap: () => context.push('/usa/fedwatch'),
          lightBorderColor: _theme.borderColor,
        ),
        ToolCard(
          flagIcon: '🇺🇸',
          icon: '📊',
          name: 'Yield Curve',
          description: '2s10s spread · inversion tracker',
          variant: ToolCardVariant.red,
          onTap: () => context.push('/usa/yield-curve'),
        ),
        ToolCard(
          flagIcon: '🇺🇸',
          icon: '💵',
          name: 'CPI vs Fed Rate',
          description: 'Inflation vs policy rate gap',
          variant: ToolCardVariant.gold,
          onTap: () => context.push('/usa/cpi-vs-fed-rate'),
        ),
      ],
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
          toolId: 'usa_core_piti_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_piti_calculator'),
            toolId: 'usa_core_piti_calculator',
            flagIcon: '🇺🇸',
            icon: '📊',
            name: 'PITI Calculator',
            description: 'Principal+Interest+Tax+Ins',
            variant: ToolCardVariant.dark,
            badgeText: 'Full Breakdown',
            badgeTextColor: const Color(0xFF60A5FA),
            badgeBgColor: Colors.white.withValues(alpha: 0.15),
            onTap: () => context.push('/tool/usa/piti'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_mortgage_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_mortgage_calc'),
            toolId: 'usa_core_mortgage_calc',
            flagIcon: '🇺🇸',
            icon: '🧮',
            name: 'Mortgage Calc',
            description: 'Monthly payment estimate',
            onTap: () => context.push('/tool/usa/mortgage'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_amortization',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_amortization'),
            toolId: 'usa_core_amortization',
            flagIcon: '🇺🇸',
            icon: '📅',
            name: 'Amortization',
            description: 'Full payment schedule',
            variant: ToolCardVariant.red,
            onTap: () => context.push('/tool/usa/amortization'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_affordability',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_affordability'),
            toolId: 'usa_core_affordability',
            flagIcon: '🇺🇸',
            icon: '💰',
            name: 'Affordability',
            description: 'How much house?',
            onTap: () => context.push('/tool/usa/affordability'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_down_payment',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_down_payment'),
            toolId: 'usa_core_down_payment',
            flagIcon: '🇺🇸',
            icon: '🔑',
            name: 'Down Payment',
            description: '3% · 5% · 10% · 20%',
            variant: ToolCardVariant.gold,
            onTap: () => context.push('/tool/usa/downpayment'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_refinance_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_refinance_calc'),
            toolId: 'usa_core_refinance_calc',
            flagIcon: '🇺🇸',
            icon: '🔄',
            name: 'Refinance Calc',
            description: 'Break-even & savings',
            onTap: () => context.push('/tool/usa/refinance'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_auto_loan',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_auto_loan'),
            toolId: 'usa_core_auto_loan',
            flagIcon: '🇺🇸',
            icon: '🏎️',
            name: 'Auto Loan',
            description: 'Vehicle financing',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/usa/autoloan'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_core_dti_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_core_dti_calculator'),
            toolId: 'usa_core_dti_calculator',
            flagIcon: '🇺🇸',
            icon: '📊',
            name: 'DTI Calculator',
            description: 'Debt-to-income ratio limits',
            onTap: () => context.push('/tool/usa/dti'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _loanProgramsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'usa_loan_fha',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_loan_fha'),
            toolId: 'usa_loan_fha',
            flagIcon: '🇺🇸',
            icon: '🏦',
            name: 'FHA Loan Calc',
            description: '3.5% down · MIP included',
            badgeText: '580+ Score',
            badgeTextColor: const Color(0xFF15803D),
            badgeBgColor: const Color(0xFFF0FDF4),
            onTap: () => context.push('/tool/usa/fha'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_loan_usda',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_loan_usda'),
            toolId: 'usa_loan_usda',
            flagIcon: '🇺🇸',
            icon: '🌾',
            name: 'USDA Loan',
            description: 'Rural 0% down payment',
            variant: ToolCardVariant.green,
            onTap: () => context.push('/tool/usa/usda'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_loan_jumbo',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_loan_jumbo'),
            toolId: 'usa_loan_jumbo',
            flagIcon: '🇺🇸',
            icon: '🏢',
            name: 'Jumbo Loan',
            description: r'>$766,550 conforming',
            onTap: () => context.push('/tool/usa/jumbo'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_loan_construction',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_loan_construction'),
            toolId: 'usa_loan_construction',
            flagIcon: '🇺🇸',
            icon: '🏗️',
            name: 'Construction Loan',
            description: 'Build new home',
            variant: ToolCardVariant.red,
            onTap: () => context.push('/tool/usa/construction'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_loan_va',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_loan_va'),
            toolId: 'usa_loan_va',
            flagIcon: '🇺🇸',
            icon: '🎖️',
            name: 'VA Loan Calc',
            description: '0% down payment for veterans',
            variant: ToolCardVariant.dark,
            badgeText: 'No PMI',
            badgeTextColor: const Color(0xFFFCD34D),
            badgeBgColor: Colors.white.withValues(alpha: 0.15),
            onTap: () => context.push('/tool/usa/va'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_loan_arm',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_loan_arm'),
            toolId: 'usa_loan_arm',
            flagIcon: '🇺🇸',
            icon: '📈',
            name: 'ARM Calculator',
            description: 'Adjustable rate mortgage',
            onTap: () => context.push('/tool/usa/arm'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _insuranceTaxGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'usa_insctax_closing_costs',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_insctax_closing_costs'),
            toolId: 'usa_insctax_closing_costs',
            flagIcon: '🇺🇸',
            icon: '📝',
            name: 'Closing Costs',
            description: 'Estimate escrow, tax & fees',
            variant: ToolCardVariant.dark,
            badgeText: 'State Fees',
            badgeTextColor: const Color(0xFF60A5FA),
            badgeBgColor: Colors.white.withValues(alpha: 0.15),
            onTap: () => context.push('/tool/usa/closingcosts'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_insctax_homeowner_ins',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_insctax_homeowner_ins'),
            toolId: 'usa_insctax_homeowner_ins',
            flagIcon: '🇺🇸',
            icon: '🛡️',
            name: 'Homeowner Ins.',
            description: 'Estimate annual policy cost',
            onTap: () => context.push('/tool/usa/homeinsurance'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_insctax_flood_ins',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_insctax_flood_ins'),
            toolId: 'usa_insctax_flood_ins',
            flagIcon: '🇺🇸',
            icon: '🌊',
            name: 'Flood Insurance',
            description: 'FEMA Risk 2.0 zone pricing',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/usa/floodinsurance'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_insctax_pmi',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_insctax_pmi'),
            toolId: 'usa_insctax_pmi',
            flagIcon: '🇺🇸',
            icon: '💸',
            name: 'PMI Calculator',
            description: 'Private mortgage insurance',
            onTap: () => context.push('/tool/usa/pmi'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_insctax_property_tax',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_insctax_property_tax'),
            toolId: 'usa_insctax_property_tax',
            flagIcon: '🇺🇸',
            icon: '🏛️',
            name: 'Property Tax Calc',
            description: 'Exemptions & state averages',
            variant: ToolCardVariant.red,
            onTap: () => context.push('/tool/usa/propertytax'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_insctax_hoa_fee_impact',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_insctax_hoa_fee_impact'),
            toolId: 'usa_insctax_hoa_fee_impact',
            flagIcon: '🇺🇸',
            icon: '🏘️',
            name: 'HOA Fee Impact',
            description: 'HOA cost on buying power',
            onTap: () => context.push('/tool/usa/hoaimpact'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _stateGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.05,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'usa_state_california',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('usa_state_california'),
              toolId: 'usa_state_california',
              flagIcon: '🇺🇸',
              icon: '🌴',
              name: 'California',
              description: 'Prop 13 · 0.76%',
              onTap: () => context.push('/usa/property-tax-by-state'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_state_texas',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('usa_state_texas'),
              toolId: 'usa_state_texas',
              flagIcon: '🇺🇸',
              icon: '🤠',
              name: 'Texas',
              description: 'No income tax · 1.60%',
              variant: ToolCardVariant.dark,
              onTap: () => context.push('/usa/property-tax-by-state')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_state_new_york',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('usa_state_new_york'),
              toolId: 'usa_state_new_york',
              flagIcon: '🇺🇸',
              icon: '🌇',
              name: 'New York',
              description: 'STAR program · 1.72%',
              onTap: () => context.push('/usa/property-tax-by-state'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_state_florida',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('usa_state_florida'),
              toolId: 'usa_state_florida',
              flagIcon: '🇺🇸',
              icon: '🌞',
              name: 'Florida',
              description: 'Homestead · 0.83%',
              variant: ToolCardVariant.red,
              onTap: () => context.push('/usa/property-tax-by-state')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_state_illinois',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('usa_state_illinois'),
              toolId: 'usa_state_illinois',
              flagIcon: '🇺🇸',
              icon: '🌆',
              name: 'Illinois',
              description: 'High rate · 2.08%',
              onTap: () => context.push('/usa/property-tax-by-state'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_state_all_states',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('usa_state_all_states'),
              toolId: 'usa_state_all_states',
              flagIcon: '🇺🇸',
              icon: '🍊',
              name: 'All States',
              description: '50 state calculator',
              variant: ToolCardVariant.gold,
              onTap: () => context.push('/usa/property-tax-by-state')),
        ),
      ],
    );
  }

  List<Widget> _resources(BuildContext context) {
    final items = [
      (
        '🏠',
        'First-Time Homebuyer Programs',
        'HUD · State DPA · \$25K grant programs',
        '/usa/first-time-homebuyer'
      ),
      (
        '🪖',
        'VA Benefits & Home Loans',
        'Entitlement · COE · funding fee waiver',
        '/usa/va-benefits'
      ),
      (
        '📈',
        '401(k) / IRA Home Withdrawal',
        '10% penalty exemptions · first-time buyer',
        '/usa/retirement-withdrawal'
      ),
      (
        '🌾',
        'USDA Rural Development',
        '502 Direct · 502 Guaranteed loan',
        '/usa/usda-rural'
      ),
      (
        '🏛️',
        'FHA 203(k) Rehab Loan',
        'Purchase + renovation in one loan',
        '/usa/fha-203k'
      ),
      (
        '🤖',
        'USA AI Mortgage Advisor',
        'FRED rates · FHA/VA/USDA guidance',
        '/usa/ai-advisor'
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

  List<Widget> _housingMarketData(BuildContext context) {
    final items = [
      (
        '📉',
        'FRED Rate History',
        'Federal Reserve Economic Data live',
        '/usa/fred-rate-history'
      ),
      (
        '🏡',
        'US Home Price Index (HPI)',
        'S&P/Case-Shiller · FHFA index',
        '/usa/home-price-index'
      ),
      (
        '📊',
        'Median Home Prices by State',
        'NAR · Zillow · Redfin data',
        '/usa/median-home-prices'
      ),
      (
        '🏦',
        'Top US Mortgage Lenders',
        'Rocket · UWM · Chase · Wells Fargo',
        '/usa/top-lenders'
      ),
      (
        '📋',
        'Mortgage Prequalification Guide',
        'Pre-qual vs Pre-approval steps',
        '/usa/prequal-guide'
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
          toolId: 'usa_pf_credit_score_impact',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_credit_score_impact'),
            toolId: 'usa_pf_credit_score_impact',
            flagIcon: '🇺🇸',
            icon: '💳',
            name: 'Credit Score Impact',
            description: 'FICO · score to rate',
            variant: ToolCardVariant.dark,
            badgeText: '620–850',
            badgeTextColor: const Color(0xFF60A5FA),
            badgeBgColor: Colors.white.withValues(alpha: 0.15),
            onTap: () => context.push('/tool/usa/creditscore'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_heloc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_heloc'),
            toolId: 'usa_pf_heloc',
            flagIcon: '🇺🇸',
            icon: '🏦',
            name: 'HELOC Calculator',
            description: 'Home equity line',
            lightBorderColor: _theme.borderColor,
            onTap: () => context.push('/tool/usa/heloc'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_home_equity_loan',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_home_equity_loan'),
            toolId: 'usa_pf_home_equity_loan',
            flagIcon: '🇺🇸',
            icon: '💵',
            name: 'Home Equity Loan',
            description: 'Lump sum borrowing',
            lightBorderColor: _theme.borderColor,
            onTap: () => context.push('/tool/usa/homeequity'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_debt_payoff_planner',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_debt_payoff_planner'),
            toolId: 'usa_pf_debt_payoff_planner',
            flagIcon: '🇺🇸',
            icon: '📉',
            name: 'Debt Payoff Planner',
            description: 'Avalanche vs Snowball',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/usa/debtpayoff'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_student_loan_dti',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_student_loan_dti'),
            toolId: 'usa_pf_student_loan_dti',
            flagIcon: '🇺🇸',
            icon: '🎓',
            name: 'Student Loan DTI',
            description: 'Impact on mortgage',
            lightBorderColor: _theme.borderColor,
            onTap: () => context.push('/tool/usa/studentloandti'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_tax_deduction_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_tax_deduction_calc'),
            toolId: 'usa_pf_tax_deduction_calc',
            flagIcon: '🇺🇸',
            icon: '🧾',
            name: 'Tax Deduction Calc',
            description: 'Mortgage interest deduction',
            variant: ToolCardVariant.red,
            onTap: () => context.push('/tool/usa/taxdeduction'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_moving_cost_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_moving_cost_calc'),
            toolId: 'usa_pf_moving_cost_calc',
            flagIcon: '🇺🇸',
            icon: '📦',
            name: 'Moving Cost Calc',
            description: 'Relocation budget',
            lightBorderColor: _theme.borderColor,
            onTap: () => context.push('/tool/usa/movingcost'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_pf_rent_vs_buy',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_pf_rent_vs_buy'),
            toolId: 'usa_pf_rent_vs_buy',
            flagIcon: '🇺🇸',
            icon: '🤝',
            name: 'Rent vs Buy',
            description: 'True cost comparison',
            variant: ToolCardVariant.violet,
            onTap: () => context.push('/tool/usa/rentvsbuy'),
          ),
        ),
      ],
    );
  }

  Widget _realEstateInvestmentGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'usa_invest_rental_yield_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_invest_rental_yield_calc'),
            toolId: 'usa_invest_rental_yield_calc',
            flagIcon: '🇺🇸',
            icon: '🏘️',
            name: 'Rental Yield Calc',
            description: 'Cap rate & cash flow',
            variant: ToolCardVariant.green,
            onTap: () => context.push('/tool/usa/rentalyield'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_invest_cash_on_cash',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_invest_cash_on_cash'),
            toolId: 'usa_invest_cash_on_cash',
            flagIcon: '🇺🇸',
            icon: '📊',
            name: 'Cash-on-Cash Return',
            description: 'Investment analysis',
            lightBorderColor: _theme.borderColor,
            onTap: () => context.push('/tool/usa/cashoncash'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_invest_fix_and_flip',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_invest_fix_and_flip'),
            toolId: 'usa_invest_fix_and_flip',
            flagIcon: '🇺🇸',
            icon: '🔨',
            name: 'Fix & Flip Calc',
            description: 'ARV · rehab · profit',
            variant: ToolCardVariant.slate,
            onTap: () => context.push('/tool/usa/fixflip'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'usa_invest_1031_exchange',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('usa_invest_1031_exchange'),
            toolId: 'usa_invest_1031_exchange',
            flagIcon: '🇺🇸',
            icon: '🏙️',
            name: '1031 Exchange',
            description: 'Tax-deferred swap',
            lightBorderColor: _theme.borderColor,
            onTap: () => context.push('/tool/usa/exchange1031'),
          ),
        ),
      ],
    );
  }
}

// ─── Fed Banner ───────────────────────────────────────────────────
class _FedBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fedRate =
        ref.watch(fredFedFundsProvider).valueOrNull?.formatted ?? '5.33%';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF061528), Color(0xFF0F2D6B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      child: Row(
        children: [
          const Text('🏛️', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FED FUNDS RATE · FOMC',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  fedRate,
                  style: AppTextStyles.dmSans(
                    size: 22,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFCD34D),
                  ),
                ),
                Text(
                  'FOMC Target Midpoint · FRED Live',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/usa/fed-funds-rate'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'FRED Live',
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

// ─── Market Ticker ────────────────────────────────────────────────
class _MarketTicker extends StatelessWidget {
  static const _items = [
    ('S&P 500', '5,304', '+0.74%', true),
    ('Dow Jones', '38,886', '+0.51%', true),
    ('NASDAQ', '16,742', '-0.21%', false),
    ('10-Yr T-Bill', '4.47%', '-0.03', false),
    ('30-Yr T-Bond', '4.61%', '+0.02', true),
    ('VIX', '13.4', '-0.80', false),
  ];

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.usa;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.07),
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
              Text('US Financial Indices',
                  style: AppTextStyles.infoTitle(theme.getTextColor(context))),
              Text('Live',
                  style: AppTextStyles.dmSans(
                      size: 10, color: const Color(0xFF0D9488))),
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
                                theme.getMutedColor(context)),
                            textAlign: TextAlign.center),
                        Text(item.$2,
                            style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w700,
                                color: theme.getTextColor(context)),
                            textAlign: TextAlign.center),
                        Text(item.$3,
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w700,
                                color: item.$4
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C)),
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

// ─── Mortgage Rates H-scroll ──────────────────────────────────────
class _MortgageRatesScroll extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const theme = CountryThemes.usa;
    final rate30 = ref.watch(fredMortgage30Provider).valueOrNull;
    final rate15 = ref.watch(fredMortgage15Provider).valueOrNull;
    final sofr = ref.watch(fredSofrProvider).valueOrNull;

    final val30 = rate30?.value ?? 6.82;
    final val15 = rate15?.value ?? 6.11;
    final valSofr = sofr?.value ?? 5.33;

    final list = [
      (
        '🏠',
        '30-Yr Fixed',
        '${val30.toStringAsFixed(2)}%',
        'Freddie Mac',
        rate30?.isLive == true ? 'Live FRED' : 'est.',
        rate30?.isLive == true
      ),
      (
        '🏡',
        '15-Yr Fixed',
        '${val15.toStringAsFixed(2)}%',
        'National Avg',
        rate15?.isLive == true ? 'Live FRED' : 'est.',
        rate15?.isLive == true
      ),
      (
        '📊',
        '5/1 ARM',
        '${(valSofr + 0.72).toStringAsFixed(2)}%',
        'SOFR Index',
        sofr?.isLive == true ? 'Live SOFR' : 'est.',
        sofr?.isLive == true
      ),
      (
        '🏢',
        'Jumbo 30yr',
        '${(val30 + 0.22).toStringAsFixed(2)}%',
        'Conforming',
        rate30?.isLive == true ? 'Live spread' : 'est.',
        rate30?.isLive == true
      ),
      (
        '🎖️',
        'VA Loan',
        '${(val30 - 0.57).toStringAsFixed(2)}%',
        'No PMI Veterans',
        rate30?.isLive == true ? 'Live spread' : 'est.',
        rate30?.isLive == true
      ),
      (
        '🌾',
        'USDA Rural',
        '${(val30 - 0.47).toStringAsFixed(2)}%',
        'Rural Areas',
        rate30?.isLive == true ? 'Live spread' : 'est.',
        rate30?.isLive == true
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final r = list[i];
          return Container(
            width: 110,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.2
                            : 0.07),
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
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB91C1C))),
              ],
            ),
          );
        },
      ),
    );
  }
}
