// lib/features/australia/australia_screen.dart

import 'package:flutter/material.dart';
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
import 'tools/au_lmi_calc.dart';

import '../../shared/widgets/deep_link_highlight_wrapper.dart';

class AustraliaScreen extends StatefulWidget {
  final String? toolId;
  final bool fallback;

  const AustraliaScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  State<AustraliaScreen> createState() => _AustraliaScreenState();
}

class _AustraliaScreenState extends State<AustraliaScreen> {
  static const _theme = CountryThemes.australia;

  final double _propValue = 750000;
  final double _depositPct = 10;
  final int _termYears = 30;

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
  void didUpdateWidget(covariant AustraliaScreen oldWidget) {
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

  static const _rates = [
    RateItem(
        label: 'Variable',
        value: '6.09%',
        note: '↓ -0.25',
        color: RateColor.red),
    RateItem(label: '2-Yr Fixed', value: '6.29%', note: 'Avg'),
    RateItem(
        label: '3-Yr Fixed',
        value: '6.15%',
        note: 'Big 4',
        color: RateColor.green),
    RateItem(
        label: 'RBA Cash',
        value: '4.35%',
        note: 'Current',
        color: RateColor.gold),
  ];

  void _calculate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/australia/mortgage/result'),
      builder: (_) => AUMortgageCalcSheet(
        propertyValue: _propValue,
        depositPercent: _depositPct,
        termYears: _termYears,
        rate: 6.09,
      ),
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
                      tag: 'Australian Mortgage Calculator',
                      titleLine1: 'Calculate with',
                      accentWord: 'LMI',
                      titleLine2: '& offset account',
                      buttonEmoji: '🦘',
                      buttonText: 'Calculate Australian Mortgage',
                      inputs: [
                        HeroInputBox(
                            label: 'Property Value',
                            value: CurrencyFormatter.compact(_propValue,
                                symbol: 'AU\$')),
                        HeroInputBox(
                            label: 'Deposit', value: '${_depositPct.toInt()}%'),
                        HeroInputBox(label: 'Term', value: '$_termYears yr'),
                      ],
                      onCalculate: _calculate,
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFF001F5C), Color(0xFF1E3A8A)],
                      ),
                    ),
                    SectionLabel(
                        text: 'LMI Calculator',
                        labelColor: _theme.mutedColor,
                        moreColor: _theme.primaryColor),
                    AlertBanner.lmi(
                        onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              routeSettings: const RouteSettings(name: '/tool/australia/lmi/result'),
                              builder: (_) => AULMICalcSheet(
                                  propertyValue: _propValue,
                                  depositPercent: _depositPct),
                            )),
                    const SizedBox(height: 10),
                    SectionLabel(
                        text: 'Core Tools',
                        labelColor: _theme.mutedColor,
                        moreColor: _theme.primaryColor),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: [
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_mortgage_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_mortgage_calc'),
                              toolId: 'australia_mortgage_calc',
                              flagIcon: '🇦🇺',
                              icon: '🏠',
                              name: 'Mortgage Calc',
                              description: 'Variable & fixed rates',
                              variant: ToolCardVariant.dark,
                              badgeText: 'LMI Incl.',
                              badgeTextColor: const Color(0xFFFCA5A5),
                              badgeBgColor: Colors.white.withValues(alpha: 0.15),
                              onTap: () =>
                                  context.push('/tool/australia/mortgage')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_lmi',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_lmi'),
                              toolId: 'australia_lmi',
                              flagIcon: '🇦🇺',
                              icon: '🛡️',
                              name: 'LMI Calculator',
                              description: 'Insurance premium',
                              badgeText: '<20% dep.',
                              badgeTextColor: const Color(0xFF1D4ED8),
                              badgeBgColor: const Color(0xFFEFF6FF),
                              onTap: () => context.push('/tool/australia/lmi'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_offset',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_offset'),
                              toolId: 'australia_offset',
                              flagIcon: '🇦🇺',
                              icon: '🏦',
                              name: 'Offset Account',
                              description: 'Interest savings calc',
                              variant: ToolCardVariant.teal,
                              onTap: () =>
                                  context.push('/tool/australia/offset')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_dti',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_dti'),
                              toolId: 'australia_dti',
                              flagIcon: '🇦🇺',
                              icon: '📊',
                              name: 'DTI Ratio',
                              description: 'Debt-to-income AUS',
                              onTap: () => context.push('/tool/australia/dti'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_affordability',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_affordability'),
                              toolId: 'australia_affordability',
                              flagIcon: '🇦🇺',
                              icon: '💰',
                              name: 'Affordability',
                              description: 'Borrowing capacity AUD',
                              onTap: () =>
                                  context.push('/tool/australia/affordability'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_amortization',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_amortization'),
                              toolId: 'australia_amortization',
                              flagIcon: '🇦🇺',
                              icon: '📅',
                              name: 'Amortization',
                              description: 'Fortnightly schedule',
                              variant: ToolCardVariant.blue,
                              onTap: () =>
                                  context.push('/tool/australia/amortization')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_stamp_duty',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_stamp_duty'),
                              toolId: 'australia_stamp_duty',
                              flagIcon: '🇦🇺',
                              icon: '🏘️',
                              name: 'Stamp Duty (AUS)',
                              description: 'State-by-state calc',
                              variant: ToolCardVariant.gold,
                              onTap: () =>
                                  context.push('/tool/australia/stampduty')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_refinance_tool',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_refinance_tool'),
                              toolId: 'australia_refinance_tool',
                              flagIcon: '🇦🇺',
                              icon: '🔄',
                              name: 'Refinance Tool',
                              description: 'Switch lender savings',
                              onTap: () =>
                                  context.push('/tool/australia/refinance'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_extra_repayments',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_extra_repayments'),
                              toolId: 'australia_extra_repayments',
                              flagIcon: '🇦🇺',
                              icon: '📈',
                              name: 'Extra Repayments',
                              description: 'Save on interest',
                              onTap: () =>
                                  context.push('/tool/australia/extrarepayments'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'australia_construction_loan',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('australia_construction_loan'),
                              toolId: 'australia_construction_loan',
                              flagIcon: '🇦🇺',
                              icon: '🏗️',
                              name: 'Construction Loan',
                              description: 'Progressive drawdown',
                              onTap: () =>
                                  context.push('/tool/australia/construction'),
                              lightBorderColor: _theme.borderColor),
                        ),
                      ],
                    ),
                    SectionLabel(
                        text: 'State & Resources',
                        labelColor: _theme.mutedColor,
                        moreColor: _theme.primaryColor),
                    ...[
                      (
                        '📋',
                        'Stamp Duty by State',
                        'NSW, VIC, QLD, WA, SA, TAS…',
                        '/tool/australia/stampdutybystate'
                      ),
                      (
                        '🏡',
                        'First Home Owner Grant',
                        'FHOG · First Home Guarantee',
                        '/tool/australia/fhog'
                      ),
                      (
                        '📉',
                        'RBA Rate History',
                        'Reserve Bank of Australia tracker',
                        '/tool/australia/rbahistory'
                      ),
                      (
                        '🤖',
                        'Australia AI Advisor',
                        'RBA rules · LMI · offset guidance',
                        '/ai/au'
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
              countryLabel: 'Australia',
              countryRoute: '/australia',
            ),
          ),
        ],
      ),
    );
  }
}
