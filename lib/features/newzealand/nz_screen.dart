// lib/features/newzealand/nz_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/country_header.dart';
import '../../shared/widgets/hero_calculator_card.dart';
import '../../shared/widgets/hero_input_editor_sheet.dart';
import '../../shared/widgets/tool_card.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/alert_banner.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/section_label.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/mortgage_math.dart';
import '../../shared/widgets/result_panel.dart';

import '../../shared/widgets/deep_link_highlight_wrapper.dart';
import '../../providers/nz_rates_provider.dart';
import '../../services/remote_config_service.dart';

class NZScreen extends ConsumerStatefulWidget {
  final String? toolId;
  final bool fallback;

  const NZScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  ConsumerState<NZScreen> createState() => _NZScreenState();
}

class _NZScreenState extends ConsumerState<NZScreen> {
  static const _theme = CountryThemes.newZealand;
  double _propValue = 850000;
  double _depositPct = 20;
  int _termYears = 30;

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
  void didUpdateWidget(covariant NZScreen oldWidget) {
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

  List<RateItem> _buildRates(NZRatesModel? r) {
    final rc = RemoteConfigService.instance;
    return [
      RateItem(
          label: '1-Yr Fixed',
          value: '${(r?.fixed1yr.value ?? 5.59).toStringAsFixed(2)}%',
          note: r?.isLive == true ? '🟢 Live' : 'Avg Lenders',
          color: RateColor.red),
      RateItem(
          label: '2-Yr Fixed',
          value: '${(r?.fixed2yr.value ?? 5.29).toStringAsFixed(2)}%',
          note: 'Avg'),
      RateItem(
          label: 'Floating',
          value: '${(r?.floating.value ?? 7.24).toStringAsFixed(2)}%',
          note: 'Avg'),
      RateItem(
          label: 'OCR Rate',
          value: '${rc.nzOcrRate}%',
          note: 'RBNZ',
          color: RateColor.gold),
    ];
  }

  void _calculate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings:
          const RouteSettings(name: '/tool/newzealand/mortgage/result'),
      builder: (_) => _NZCalcSheet(
          propValue: _propValue,
          depositPct: _depositPct,
          termYears: _termYears),
    );
  }

  void _showInputEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/newzealand/mortgage/inputs'),
      builder: (_) => HeroInputEditorSheet(
        title: '\uD83C\uDDF3\uD83C\uDDFF Adjust Home Loan Inputs',
        primaryColor: _theme.primaryColor,
        configs: [
          HeroInputConfig(
            label: 'PROPERTY VALUE',
            value: _propValue,
            min: 100000, max: 5000000, divisions: 98,
            format: (v) => CurrencyFormatter.compact(v, symbol: 'NZ\$'),
          ),
          HeroInputConfig(
            label: 'DEPOSIT',
            value: _depositPct,
            min: 10, max: 50, divisions: 40,
            format: (v) => '${v.toInt()}%',
          ),
          HeroInputConfig(
            label: 'TERM',
            value: _termYears.toDouble(),
            min: 5, max: 30, divisions: 25,
            format: (v) => '${v.toInt()} Years',
          ),
        ],
        onApply: (values) {
          setState(() {
            _propValue = values[0];
            _depositPct = values[1];
            _termYears = values[2].toInt();
          });
          _calculate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nzRates = ref.watch(nzRatesProvider).valueOrNull;
    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CountryHeader(
                  theme: _theme,
                  rates: _buildRates(nzRates),
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
                      const SizedBox(height: 10),
                    ],
                    SectionLabel(
                      text: 'Quick Estimate',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    HeroCalculatorCard(
                      theme: _theme,
                      tag: 'NZ Mortgage Calculator · Te Tatau Hea Hua',
                      titleLine1: 'Calculate your',
                      accentWord: 'NZ Home Loan',
                      titleLine2: 'with LVR & fees',
                      buttonEmoji: '🌿',
                      buttonText: 'Calculate NZ Home Loan',
                      inputs: [
                        HeroInputBox(
                            label: 'Property Value',
                            value: CurrencyFormatter.compact(_propValue,
                                symbol: 'NZ\$')),
                        HeroInputBox(
                            label: 'Deposit', value: '${_depositPct.toInt()}%'),
                        HeroInputBox(label: 'Term', value: '$_termYears yr'),
                      ],
                      onCalculate: _calculate,
                      onInputTap: _showInputEditor,
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFF1A6B4A), Color(0xFF0D3B2E)],
                      ),
                    ),

                    // Core Home Loan Tools Grid
                    SectionLabel(
                      text: 'Core Home Loan Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _coreToolsGrid(context),

                    // LVR Restrictions Banner
                    SectionLabel(
                      text: 'LVR Restrictions',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    AlertBanner(
                      icon: '⚠️',
                      title: 'Loan-to-Value Restrictions (LVR)',
                      subtitle:
                          'Owner-occ: 20% min deposit · Investor: 35% min deposit (RBNZ 2024)',
                      buttonText: 'Check LVR',
                      bgColor1: const Color(0xFFFEF3C7),
                      bgColor2: const Color(0xFFFDE68A),
                      borderColor: const Color(0xFFF59E0B),
                      buttonColor: const Color(0xFFD97706),
                      titleColor: const Color(0xFF92400E),
                      subtitleColor: const Color(0xFFB45309),
                      onTap: () => context.push('/tool/newzealand/lvr'),
                    ),
                    const SizedBox(height: 10),
                    _lvrDepositGrid(context),

                    // KiwiSaver Banner & Grid
                    SectionLabel(
                      text: 'KiwiSaver',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    AlertBanner(
                      icon: '🥝',
                      title: 'KiwiSaver First-Home Withdrawal',
                      subtitle:
                          'Use KiwiSaver savings as deposit · \$10K HomeStart Grant eligible',
                      buttonText: 'Calculate',
                      bgColor1: const Color(0xFFF0FDFA),
                      bgColor2: const Color(0xFFCCFBF1),
                      borderColor: const Color(0xFF5EEAD4),
                      buttonColor: const Color(0xFF0D9488),
                      titleColor: const Color(0xFF0F766E),
                      subtitleColor: const Color(0xFF0D9488),
                      onTap: () =>
                          context.push('/tool/newzealand/kiwisaverwithdrawal'),
                    ),
                    const SizedBox(height: 10),
                    _kiwiSaverGrid(context),

                    // First Home Buyer Tools
                    SectionLabel(
                      text: 'First Home Buyer Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _firstHomeGrid(context),

                    // Tax & Investment Tools
                    SectionLabel(
                      text: 'Tax & Investment Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _taxInvestmentGrid(context),

                    // Personal Finance Grid
                    SectionLabel(
                      text: 'Personal Finance',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    _personalFinanceGrid(context),

                    // NZ Regional House Prices
                    SectionLabel(
                      text: 'Region House Prices',
                      moreText: 'All Regions →',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                      onMoreTap: () =>
                          context.push('/tool/newzealand/allregions'),
                    ),
                    _RegionPricesScroll(),

                    // Government & Resources List
                    SectionLabel(
                      text: 'Government & Resources',
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
              countryLabel: 'NZ',
              countryRoute: '/newzealand',
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
          toolId: 'nz_core_mortgage_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_mortgage_calc'),
            toolId: 'nz_core_mortgage_calc',
            flagIcon: '🇳🇿',
            icon: '🏠',
            name: 'Mortgage Calc',
            description: 'NZD monthly payment',
            variant: ToolCardVariant.dark,
            badgeText: 'Fixed & Float',
            badgeTextColor: const Color(0xFF10B981),
            badgeBgColor: Colors.white.withValues(alpha: 0.15),
            onTap: () => context.push('/tool/newzealand/mortgage'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_repayment_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_repayment_calc'),
            toolId: 'nz_core_repayment_calc',
            flagIcon: '🇳🇿',
            icon: '📊',
            name: 'Repayment Calc',
            description: 'P&I vs interest only',
            onTap: () => context.push('/tool/newzealand/repayment'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_dti_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_dti_calculator'),
            toolId: 'nz_core_dti_calculator',
            flagIcon: '🇳🇿',
            icon: '📈',
            name: 'DTI Calculator',
            description: 'Debt-to-income NZ',
            badgeText: '6x Cap',
            badgeTextColor: const Color(0xFFEF4444),
            badgeBgColor: const Color(0xFFFEF2F2),
            onTap: () => context.push('/tool/newzealand/dti'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_amortization',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_amortization'),
            toolId: 'nz_core_amortization',
            flagIcon: '🇳🇿',
            icon: '📅',
            name: 'Amortization',
            description: 'Full repayment schedule',
            variant: ToolCardVariant.green,
            onTap: () => context.push('/tool/newzealand/amortization'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_affordability_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_affordability_calc'),
            toolId: 'nz_core_affordability_calc',
            flagIcon: '🇳🇿',
            icon: '💰',
            name: 'Affordability Calc',
            description: 'Max borrowing NZD',
            onTap: () => context.push('/tool/newzealand/affordability'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_refixing_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_refixing_calc'),
            toolId: 'nz_core_refixing_calc',
            flagIcon: '🇳🇿',
            icon: '🔄',
            name: 'Refixing Calc',
            description: 'Best term to refix',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/newzealand/refixing'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_extra_repayments',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_extra_repayments'),
            toolId: 'nz_core_extra_repayments',
            flagIcon: '🇳🇿',
            icon: '📉',
            name: 'Extra Repayments',
            description: 'Interest savings calc',
            onTap: () => context.push('/tool/newzealand/extrarepayments'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_core_car_loan_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_core_car_loan_calc'),
            toolId: 'nz_core_car_loan_calc',
            flagIcon: '🇳🇿',
            icon: '🏎️',
            name: 'Car Loan Calc',
            description: 'Vehicle financing NZD',
            variant: ToolCardVariant.red,
            onTap: () => context.push('/tool/newzealand/carloan'),
          ),
        ),
      ],
    );
  }

  Widget _lvrDepositGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'nz_lvr_calculator',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_lvr_calculator'),
            toolId: 'nz_lvr_calculator',
            flagIcon: '🇳🇿',
            icon: '🛡️',
            name: 'LVR Calculator',
            description: 'Loan-to-value ratio',
            badgeText: '20% / 35%',
            badgeTextColor: const Color(0xFFEF4444),
            badgeBgColor: const Color(0xFFFEF2F2),
            onTap: () => context.push('/tool/newzealand/lvr'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_lvr_deposit_builder',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_lvr_deposit_builder'),
            toolId: 'nz_lvr_deposit_builder',
            flagIcon: '🇳🇿',
            icon: '🏦',
            name: 'Deposit Builder',
            description: 'Savings goal tracker',
            variant: ToolCardVariant.dark,
            onTap: () => context.push('/tool/newzealand/depositbuilder'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_lvr_band_tool',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_lvr_band_tool'),
            toolId: 'nz_lvr_band_tool',
            flagIcon: '🇳🇿',
            icon: '📐',
            name: 'LVR Band Tool',
            description: 'Owner-occ vs investor',
            variant: ToolCardVariant.blue,
            onTap: () => context.push('/tool/newzealand/lvrband'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_lvr_low_equity_margin',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_lvr_low_equity_margin'),
            toolId: 'nz_lvr_low_equity_margin',
            flagIcon: '🇳🇿',
            icon: '🔍',
            name: 'Low Equity Margin',
            description: 'LEM fee calculator',
            badgeText: 'LEM',
            badgeTextColor: const Color(0xFFEA580C),
            badgeBgColor: const Color(0xFFFFF7ED),
            onTap: () => context.push('/tool/newzealand/lowequity'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _kiwiSaverGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'nz_kiwisaver_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_kiwisaver_calc'),
            toolId: 'nz_kiwisaver_calc',
            flagIcon: '🇳🇿',
            icon: '🥝',
            name: 'KiwiSaver Calc',
            description: 'First-home withdrawal',
            variant: ToolCardVariant.green,
            badgeText: '3yr min',
            badgeTextColor: const Color(0xFF0F766E),
            badgeBgColor: const Color(0xFFF0FDFA),
            onTap: () => context.push('/tool/newzealand/kiwisavercalc'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_kiwisaver_homestart_grant',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_kiwisaver_homestart_grant'),
            toolId: 'nz_kiwisaver_homestart_grant',
            flagIcon: '🇳🇿',
            icon: '🎁',
            name: 'HomeStart Grant',
            description: '\$10K new / \$5K existing',
            onTap: () => context.push('/tool/newzealand/homestartgrant'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_kiwisaver_balance',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_kiwisaver_balance'),
            toolId: 'nz_kiwisaver_balance',
            flagIcon: '🇳🇿',
            icon: '📦',
            name: 'KiwiSaver Balance',
            description: 'Projection calculator',
            onTap: () => context.push('/tool/newzealand/kiwisaverbalance'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_kiwisaver_employer_contrib',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_kiwisaver_employer_contrib'),
            toolId: 'nz_kiwisaver_employer_contrib',
            flagIcon: '🇳🇿',
            icon: '👥',
            name: 'Employer Contrib.',
            description: '3% match tracker',
            variant: ToolCardVariant.teal,
            onTap: () => context.push('/tool/newzealand/employercontrib'),
          ),
        ),
      ],
    );
  }

  Widget _firstHomeGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'nz_fhb_first_home_buyer',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_fhb_first_home_buyer'),
            toolId: 'nz_fhb_first_home_buyer',
            flagIcon: '🇳🇿',
            icon: '🏡',
            name: 'First Home Buyer',
            description: 'Full eligibility check',
            variant: ToolCardVariant.red,
            badgeText: 'FHB',
            badgeTextColor: const Color(0xFF15803D),
            badgeBgColor: const Color(0xFFECFDF5),
            onTap: () => context.push('/tool/newzealand/firsthomebuyer'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_fhb_deposit_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_fhb_deposit_calc'),
            toolId: 'nz_fhb_deposit_calc',
            flagIcon: '🇳🇿',
            icon: '🔑',
            name: 'Deposit Calc',
            description: 'How long to save 20%',
            onTap: () => context.push('/tool/newzealand/depositcalc'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_fhb_preapproval_guide',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_fhb_preapproval_guide'),
            toolId: 'nz_fhb_preapproval_guide',
            flagIcon: '🇳🇿',
            icon: '💳',
            name: 'Pre-approval Guide',
            description: 'Conditional approval',
            onTap: () => context.push('/tool/newzealand/preapprovalguide'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_fhb_solicitor_costs',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_fhb_solicitor_costs'),
            toolId: 'nz_fhb_solicitor_costs',
            flagIcon: '🇳🇿',
            icon: '📋',
            name: 'Solicitor Costs',
            description: 'Legal & conveyancing',
            variant: ToolCardVariant.gold,
            onTap: () => context.push('/tool/newzealand/solicitorcosts'),
          ),
        ),
      ],
    );
  }

  Widget _taxInvestmentGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        DeepLinkHighlightWrapper(
          toolId: 'nz_tax_rental_yield_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_tax_rental_yield_calc'),
            toolId: 'nz_tax_rental_yield_calc',
            flagIcon: '🇳🇿',
            icon: '🏘️',
            name: 'Rental Yield Calc',
            description: 'Gross & net yield NZD',
            variant: ToolCardVariant.slate,
            onTap: () => context.push('/tool/newzealand/rentalyield'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_tax_ring_fencing_rules',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_tax_ring_fencing_rules'),
            toolId: 'nz_tax_ring_fencing_rules',
            flagIcon: '🇳🇿',
            icon: '💼',
            name: 'Ring-Fencing Rules',
            description: 'Rental loss tax rules',
            badgeText: '2019 law',
            badgeTextColor: const Color(0xFFEF4444),
            badgeBgColor: const Color(0xFFFEF2F2),
            onTap: () => context.push('/tool/newzealand/ringfencing'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_tax_investment_property',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_tax_investment_property'),
            toolId: 'nz_tax_investment_property',
            flagIcon: '🇳🇿',
            icon: '🏢',
            name: 'Investment Property',
            description: 'Cash flow & return',
            variant: ToolCardVariant.green,
            onTap: () => context.push('/tool/newzealand/investmentproperty'),
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_tax_interest_deductibility',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_tax_interest_deductibility'),
            toolId: 'nz_tax_interest_deductibility',
            flagIcon: '🇳🇿',
            icon: '📝',
            name: 'Interest Deductibility',
            description: 'Phased-in rules tracker',
            onTap: () => context.push('/tool/newzealand/interestdeductibility'),
            lightBorderColor: _theme.borderColor,
          ),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_tax_nzx_investor_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
            key: _getKey('nz_tax_nzx_investor_calc'),
            toolId: 'nz_tax_nzx_investor_calc',
            flagIcon: '🇳🇿',
            icon: '💹',
            name: 'NZX Investor Calc',
            description: 'FIF · PIE tax rates',
            variant: ToolCardVariant.blue,
            onTap: () => context.push('/tool/newzealand/nzxinvestor'),
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
          toolId: 'nz_pf_credit_score',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_credit_score'),
              toolId: 'nz_pf_credit_score',
              flagIcon: '🇳🇿',
              icon: '💳',
              name: 'Credit Score NZ',
              description: 'Equifax · Centrix score',
              variant: ToolCardVariant.dark,
              onTap: () => context.push('/tool/newzealand/creditscorenz')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_revolving_credit',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_revolving_credit'),
              toolId: 'nz_pf_revolving_credit',
              flagIcon: '🇳🇿',
              icon: '🏦',
              name: 'Revolving Credit',
              description: 'Home equity access',
              onTap: () => context.push('/tool/newzealand/revolvingcredit'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_debt_consolidation',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_debt_consolidation'),
              toolId: 'nz_pf_debt_consolidation',
              flagIcon: '🇳🇿',
              icon: '📉',
              name: 'Debt Consolidation',
              description: 'Roll debts into mortgage',
              variant: ToolCardVariant.red,
              onTap: () => context.push('/tool/newzealand/debtconsolidation')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_income_tax_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_income_tax_calc'),
              toolId: 'nz_pf_income_tax_calc',
              flagIcon: '🇳🇿',
              icon: '🧾',
              name: 'Income Tax Calc',
              description: 'PAYE · ACC levy',
              onTap: () => context.push('/tool/newzealand/incometaxcalc'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_refinance_calc',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_refinance_calc'),
              toolId: 'nz_pf_refinance_calc',
              flagIcon: '🇳🇿',
              icon: '🔁',
              name: 'Refinance Calc',
              description: 'Break fee & savings',
              variant: ToolCardVariant.teal,
              onTap: () => context.push('/tool/newzealand/refinancecalc')),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_construction_loan',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_construction_loan'),
              toolId: 'nz_pf_construction_loan',
              flagIcon: '🇳🇿',
              icon: '🏗️',
              name: 'Construction Loan',
              description: 'Progressive drawdown',
              onTap: () => context.push('/tool/newzealand/constructionloan'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_budget_planner',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              key: _getKey('nz_pf_budget_planner'),
              toolId: 'nz_pf_budget_planner',
              flagIcon: '🇳🇿',
              icon: '💵',
              name: 'Budget Planner',
              description: 'Housing cost vs income',
              onTap: () => context.push('/tool/newzealand/budgetplanner'),
              lightBorderColor: _theme.borderColor),
        ),
        DeepLinkHighlightWrapper(
          toolId: 'nz_pf_ai_advisor',
          activeToolId: widget.toolId,
          highlightColor: _theme.primaryColor,
          child: ToolCard(
              toolId: 'nz_pf_ai_advisor',
              flagIcon: '🇳🇿',
              icon: '🤖',
              name: 'NZ AI Advisor',
              description: 'RBNZ · LVR · KiwiSaver',
              variant: ToolCardVariant.violet,
              onTap: () => context.push('/ai/nz')),
        ),
      ],
    );
  }

  List<Widget> _resources(BuildContext context) {
    final items = [
      (
        '🏡',
        'Kāinga Ora (Housing NZ)',
        'Public housing · First Home Partner scheme',
        '/tool/newzealand/kaingaora'
      ),
      (
        '🏛️',
        'RBNZ OCR Rate History',
        'Official Cash Rate decisions since 1999',
        '/tool/newzealand/ocrhistory'
      ),
      (
        '📊',
        'REINZ House Price Index',
        'Real Estate Institute NZ · monthly HPI',
        '/tool/newzealand/reinz_hpi'
      ),
      (
        '🚫',
        'Overseas Investment Act',
        'Foreign buyer restrictions · OIO rules',
        '/tool/newzealand/overseas_investment_act'
      ),
      (
        '📋',
        'Healthy Homes Standards',
        'Rental compliance · insulation rules',
        '/tool/newzealand/healthy_homes'
      ),
      (
        '🤝',
        'MoneyHub NZ Mortgage Guide',
        'Independent NZ mortgage comparison',
        '/tool/newzealand/moneyhub_mortgage'
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

// ─── Region House Prices Scroll ──────────────────────────────────
class _RegionPricesScroll extends StatelessWidget {
  static const _regions = [
    ('🏙️', 'Auckland', 'Metro', r'NZ$950K', '↓ -1.2%', false),
    ('🌊', 'Wellington', 'Capital', r'NZ$780K', '↓ -2.4%', false),
    ('🏔️', 'Christchurch', 'South Island', r'NZ$610K', '↑ +1.8%', true),
    ('🌺', 'Hamilton', 'Waikato', r'NZ$650K', '↑ +0.5%', true),
    ('🌿', 'Tauranga', 'Bay of Plenty', r'NZ$810K', '↓ -0.8%', false),
    ('🍇', 'Dunedin', 'Otago', r'NZ$520K', '↑ +2.1%', true),
  ];

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.newZealand;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _regions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final rg = _regions[i];
          return Container(
            width: 120,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rg.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 2),
                Text(rg.$2,
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                Text(rg.$3,
                    style:
                        AppTextStyles.rateNote(theme.getMutedColor(context))),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rg.$4,
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: const Color(0xFF1A6B4A))),
                    Text(rg.$5,
                        style: AppTextStyles.dmSans(
                            size: 9,
                            weight: FontWeight.w700,
                            color: rg.$6
                                ? const Color(0xFF15803D)
                                : const Color(0xFFC0392B))),
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

// ─── Calculator Bottom Sheet ──────────────────────────────────────
class _NZCalcSheet extends StatefulWidget {
  final double propValue, depositPct;
  final int termYears;

  const _NZCalcSheet(
      {required this.propValue,
      required this.depositPct,
      required this.termYears});

  @override
  State<_NZCalcSheet> createState() => _NZCalcSheetState();
}

class _NZCalcSheetState extends State<_NZCalcSheet> {
  late double _val, _dep, _rate;
  late int _term;
  static const _theme = CountryThemes.newZealand;

  @override
  void initState() {
    super.initState();
    _val = widget.propValue;
    _dep = widget.depositPct;
    _term = widget.termYears;
    _rate = 6.35;
  }

  double get _loan => _val * (1 - _dep / 100);
  double get _monthly => MortgageMath.monthlyPayment(
      principal: _loan, annualRatePercent: _rate, termYears: _term);
  double get _fortnightly => MortgageMath.fortnightlyPayment(
      principal: _loan, annualRatePercent: _rate, termYears: _term);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).scaffoldBackgroundColor
                : const Color(0xFFF4F4F8),
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
            Text('🌿 NZ Mortgage Calculator',
                style: AppTextStyles.dmSans(
                    size: 18,
                    weight: FontWeight.w800,
                    color: _theme.textColor)),
            const SizedBox(height: 16),
            ResultPanel(
              primaryColor: _theme.primaryColor,
              rows: [
                ResultRow(
                    label: 'Monthly Payment',
                    value: _monthly,
                    currencyCode: 'NZD',
                    isHighlighted: true),
                ResultRow(
                    label: 'Fortnightly Payment',
                    value: _fortnightly,
                    currencyCode: 'NZD'),
                ResultRow(
                    label: 'Loan Amount', value: _loan, currencyCode: 'NZD'),
                ResultRow(
                    label: 'LVR',
                    value: MortgageMath.ltv(_loan, _val),
                    isPercent: true),
                ResultRow(
                    label: 'Total Interest',
                    value: MortgageMath.totalInterest(
                        principal: _loan,
                        annualRatePercent: _rate,
                        termYears: _term),
                    currencyCode: 'NZD'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
