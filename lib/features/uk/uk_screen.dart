// lib/features/uk/uk_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/country_themes.dart';
import '../../shared/widgets/country_header.dart';
import '../../shared/widgets/hero_calculator_card.dart';
import '../../shared/widgets/tool_card.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/alert_banner.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/section_label.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/uk_rates_provider.dart';
import 'tools/uk_sdlt_calc.dart';
import '../../shared/widgets/deep_link_highlight_wrapper.dart';

class UKScreen extends ConsumerStatefulWidget {
  final String? toolId;
  final bool fallback;

  const UKScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  ConsumerState<UKScreen> createState() => _UKScreenState();
}

class _UKScreenState extends ConsumerState<UKScreen> {
  static const _theme = CountryThemes.uk;

  final double _propValue = 380000;
  final double _depositPct = 15;
  final int _termYears = 25;

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
  void didUpdateWidget(covariant UKScreen oldWidget) {
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

  void _calculateMortgage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UKMortgageCalcSheet(
        propertyValue: _propValue,
        depositPercent: _depositPct,
        termYears: _termYears,
      ),
    );
  }

  void _calculateSDLT() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UKSDLTCalcSheet(
        propertyValue: _propValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = r?.boeBase.value  ?? 4.25;
    final fixed2yr = r?.fixed2yr.value ?? 4.75;
    final fixed5yr = r?.fixed5yr.value ?? 4.35;
    final isLive   = r?.isLive == true;

    final liveRates = [
      RateItem(
        label: '2-Yr Fixed',
        value: '${fixed2yr.toStringAsFixed(2)}%',
        note: isLive ? '🟢 Live' : 'BoE',
        color: RateColor.red,
      ),
      RateItem(
        label: '5-Yr Fixed',
        value: '${fixed5yr.toStringAsFixed(2)}%',
        note: 'BoE avg',
      ),
      RateItem(
        label: 'Tracker',
        value: '${(boeBase + 0.25).toStringAsFixed(2)}%',
        note: 'Base+0.25',
        color: RateColor.green,
      ),
      RateItem(
        label: 'BoE Base',
        value: '${boeBase.toStringAsFixed(2)}%',
        note: isLive ? '🟢 Live' : 'Est.',
        color: RateColor.gold,
      ),
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
                  rates: liveRates,
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
                      onMoreTap: () => context.push('/tool/uk/mortgage'),
                    ),
                    HeroCalculatorCard(
                      theme: _theme,
                      tag: 'UK Mortgage Calculator',
                      titleLine1: 'Calculate your',
                      accentWord: 'Stamp Duty',
                      titleLine2: '& monthly payment',
                      buttonEmoji: '👑',
                      buttonText: 'Calculate UK Mortgage',
                      inputs: [
                        HeroInputBox(
                          label: 'Property Value',
                          value: CurrencyFormatter.compact(_propValue,
                              symbol: '£'),
                        ),
                        HeroInputBox(
                          label: 'Deposit',
                          value: '${_depositPct.toInt()}%',
                        ),
                        HeroInputBox(
                          label: 'Term',
                          value: '$_termYears yr',
                        ),
                      ],
                      onCalculate: _calculateMortgage,
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                      ),
                    ),
                    SectionLabel(
                      text: 'Stamp Duty (SDLT)',
                      moreText: 'SDLT Guide →',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                      onMoreTap: () => context.push('/tool/uk/stampduty'),
                    ),
                    AlertBanner.sdlt(
                      onTap: _calculateSDLT,
                    ),
                    SectionLabel(
                      text: 'Core Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: [
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_mortgage_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_mortgage_calc'),
                            toolId: 'uk_mortgage_calc',
                            flagIcon: '🇬🇧',
                            icon: '🏠',
                            name: 'Mortgage Calc',
                            description: 'Monthly repayment',
                            variant: ToolCardVariant.dark,
                            badgeText: 'Repayment',
                            badgeTextColor: Colors.white,
                            badgeBgColor: Colors.white.withValues(alpha: 0.15),
                            onTap: () => context.push('/tool/uk/mortgage'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_stamp_duty_sdlt',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_stamp_duty_sdlt'),
                            toolId: 'uk_stamp_duty_sdlt',
                            flagIcon: '🇬🇧',
                            icon: '🏛️',
                            name: 'Stamp Duty (SDLT)',
                            description: 'Tax on purchase',
                            badgeText: 'FTB Relief',
                            badgeTextColor: const Color(0xFF991B1B),
                            badgeBgColor: const Color(0xFFFEF2F2),
                            onTap: () => context.push('/tool/uk/stampduty'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_ltv_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_ltv_calc'),
                            toolId: 'uk_ltv_calc',
                            flagIcon: '🇬🇧',
                            icon: '📊',
                            name: 'LTV Calculator',
                            description: 'Loan-to-value ratio',
                            variant: ToolCardVariant.royal,
                            onTap: () => context.push('/tool/uk/ltv'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_remortgage_tool',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_remortgage_tool'),
                            toolId: 'uk_remortgage_tool',
                            flagIcon: '🇬🇧',
                            icon: '🔁',
                            name: 'Remortgage Tool',
                            description: 'Switch & save calc',
                            onTap: () => context.push('/tool/uk/remortgage'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_affordability',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_affordability'),
                            toolId: 'uk_affordability',
                            flagIcon: '🇬🇧',
                            icon: '💷',
                            name: 'Affordability',
                            description: 'Max borrowing GBP',
                            onTap: () => context.push('/tool/uk/affordability'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_help_to_buy',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_help_to_buy'),
                            toolId: 'uk_help_to_buy',
                            flagIcon: '🇬🇧',
                            icon: '🏘️',
                            name: 'Help to Buy',
                            description: 'Equity loan scheme',
                            variant: ToolCardVariant.red,
                            onTap: () => context.push('/tool/uk/helptobuy'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_amortization',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_amortization'),
                            toolId: 'uk_amortization',
                            flagIcon: '🇬🇧',
                            icon: '📅',
                            name: 'Amortization',
                            description: 'Repayment schedule',
                            onTap: () => context.push('/tool/uk/amortization'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_buy_to_let',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_buy_to_let'),
                            toolId: 'uk_buy_to_let',
                            flagIcon: '🇬🇧',
                            icon: '🏢',
                            name: 'Buy-to-Let Calc',
                            description: 'Rental yield & BTL',
                            variant: ToolCardVariant.gold,
                            onTap: () => context.push('/tool/uk/btl'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_income_multiples',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_income_multiples'),
                            toolId: 'uk_income_multiples',
                            flagIcon: '🇬🇧',
                            icon: '📋',
                            name: 'Income Multiples',
                            description: '4x–4.5x salary check',
                            onTap: () => context.push('/tool/uk/incomemultiples'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'uk_sdlt_calculator',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('uk_sdlt_calculator'),
                            toolId: 'uk_sdlt_calculator',
                            flagIcon: '🇬🇧',
                            icon: '🧾',
                            name: 'SDLT Calculator',
                            description: '2nd home surcharge',
                            onTap: () => context.push('/tool/uk/sdlt'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                      ],
                    ),
                    SectionLabel(
                      text: 'UK Resources',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    ...[
                      (
                        '📉',
                        'BoE Base Rate Tracker',
                        'Live Bank of England rate history',
                        '/uk/boe-base-rate'
                      ),
                      (
                        '🏡',
                        'UK House Price Index',
                        'HM Land Registry · regional data',
                        '/uk/house-price-index'
                      ),
                      (
                        '🤝',
                        'Shared Ownership Calc',
                        'Part-buy part-rent scheme',
                        '/uk/shared-ownership'
                      ),
                      (
                        '🤖',
                        'UK AI Mortgage Advisor',
                        'FCA-aware guidance · SDLT help',
                        '/uk/ai-advisor'
                      ),
                    ].map((item) => Padding(
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
                        )),
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
              countryLabel: 'UK',
              countryRoute: '/uk',
            ),
          ),
        ],
      ),
    );
  }
}
