// lib/features/canada/canada_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/country_themes.dart';
import '../../shared/widgets/country_header.dart';
import '../../shared/widgets/hero_calculator_card.dart';
import '../../shared/widgets/hero_input_editor_sheet.dart';
import '../../shared/widgets/tool_card.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/alert_banner.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/section_label.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/canada_rates_provider.dart';
import 'tools/ca_stress_test.dart';
import 'tools/ca_mortgage_calc.dart';

import '../../shared/widgets/deep_link_highlight_wrapper.dart';

class CanadaScreen extends ConsumerStatefulWidget {
  final String? toolId;
  final bool fallback;

  const CanadaScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  ConsumerState<CanadaScreen> createState() => _CanadaScreenState();
}

class _CanadaScreenState extends ConsumerState<CanadaScreen> {
  static const _theme = CountryThemes.canada;
  double _homePrice = 650000;
  double _downPct = 10;
  int _termYears = 25;

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
  void didUpdateWidget(covariant CanadaScreen oldWidget) {
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

  void _calculate() {
    final r5yrFixed = ref.read(canadaCalculatedRatesProvider).valueOrNull?.rate5yrFixed ?? 4.99;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/canada/mortgage/result'),
      builder: (_) => CAMortgageCalcSheet(
        homePrice: _homePrice,
        downPercent: _downPct,
        defaultContractRate: r5yrFixed,
      ),
    );
  }

  void _showInputEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/canada/mortgage/inputs'),
      builder: (_) => HeroInputEditorSheet(
        title: '\uD83C\uDDE8\uD83C\uDDE6 Adjust Mortgage Inputs',
        primaryColor: _theme.primaryColor,
        configs: [
          HeroInputConfig(
            label: 'HOME PRICE',
            value: _homePrice,
            min: 100000, max: 3000000, divisions: 58,
            format: (v) => CurrencyFormatter.compact(v, symbol: 'CA\$'),
          ),
          HeroInputConfig(
            label: 'DOWN PAYMENT',
            value: _downPct,
            min: 5, max: 50, divisions: 45,
            format: (v) => '${v.toInt()}%',
          ),
          HeroInputConfig(
            label: 'AMORTIZATION',
            value: _termYears.toDouble(),
            min: 5, max: 30, divisions: 25,
            format: (v) => '${v.toInt()} Years',
          ),
        ],
        onApply: (values) {
          setState(() {
            _homePrice = values[0];
            _downPct = values[1];
            _termYears = values[2].toInt();
          });
          _calculate();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final r5yrFixed = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final r3yrFixed = ratesAsync.valueOrNull?.rate3yrFixed ?? 5.14;
    final rVariable = ratesAsync.valueOrNull?.rateVariable ?? 5.95;
    final rStress = ratesAsync.valueOrNull?.stressTestRate ?? 7.00;
    final rOvernight = ratesAsync.valueOrNull?.overnight.value ?? 2.25;
    final rPrime = ratesAsync.valueOrNull?.prime.value ?? 4.45;
    final usdCad = ratesAsync.valueOrNull?.usdCad.value ?? 1.3977;
    final bond5yr = ratesAsync.valueOrNull?.bond5yr.value ?? 3.75;
    final bond10yr = ratesAsync.valueOrNull?.bond10yr.value ?? 3.95;
    final isLive = ratesAsync.valueOrNull?.isLive == true;

    final rates = [
      RateItem(
          label: '5-Yr Fixed',
          value: '${r5yrFixed.toStringAsFixed(2)}%',
          note: isLive ? '🟢 Live' : 'BoC',
          color: RateColor.red),
      RateItem(
          label: '3-Yr Fixed',
          value: '${r3yrFixed.toStringAsFixed(2)}%',
          note: isLive ? 'BoC Live' : 'BoC'),
      RateItem(
          label: 'Variable',
          value: '${rVariable.toStringAsFixed(2)}%',
          note: 'Prime−0.5',
          color: RateColor.green),
      RateItem(
          label: 'Stress Test',
          value: '${rStress.toStringAsFixed(2)}%',
          note: isLive ? 'OSFI Min' : 'Min rate',
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
                    theme: _theme, rates: rates, onBack: () => context.go('/')),
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
                        moreColor: _theme.primaryColor),
                    HeroCalculatorCard(
                      theme: _theme,
                      tag: 'Canadian Mortgage Calculator',
                      titleLine1: 'Calculate your',
                      accentWord: 'CMHC',
                      titleLine2: 'insured payment',
                      buttonEmoji: '🍁',
                      buttonText: 'Calculate Canadian Mortgage',
                      inputs: [
                        HeroInputBox(
                            label: 'Home Price',
                            value: CurrencyFormatter.compact(_homePrice,
                                symbol: 'CA\$')),
                        HeroInputBox(
                            label: 'Down Payment',
                            value: '${_downPct.toInt()}%'),
                        HeroInputBox(label: 'Amort.', value: '$_termYears yr'),
                      ],
                      onCalculate: _calculate,
                      onInputTap: _showInputEditor,
                      buttonGradient: const LinearGradient(
                          colors: [Color(0xFFB20D28), Color(0xFF8B0A1E)]),
                    ),
                    SectionLabel(
                        text: 'Stress Test',
                        labelColor: _theme.mutedColor,
                        moreColor: _theme.primaryColor),
                    AlertBanner(
                      icon: '⚠️',
                      title: 'Mortgage Stress Test',
                      subtitle:
                          'Qualify at 7.00% or contract+2% — whichever is higher',
                      buttonText: 'Test Now',
                      bgColor1: const Color(0xFFFEF2F2),
                      bgColor2: const Color(0xFFFCA5A5),
                      borderColor: const Color(0xFFEF4444),
                      buttonColor: const Color(0xFFDC2626),
                      titleColor: const Color(0xFF7F1D1D),
                      subtitleColor: const Color(0xFF991B1B),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        routeSettings: const RouteSettings(name: '/tool/canada/stresstest/result'),
                        builder: (_) => CAStressTestSheet(
                            homePrice: _homePrice,
                            downPercent: _downPct,
                            defaultContractRate: r5yrFixed),
                      ),
                    ),
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
                          toolId: 'canada_mortgage_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_mortgage_calc'),
                              toolId: 'canada_mortgage_calc',
                              flagIcon: '🇨🇦',
                              icon: '🏠',
                              name: 'Mortgage Calc',
                              description: 'Monthly payment + CMHC',
                              variant: ToolCardVariant.dark,
                              badgeText: '25yr Max',
                              badgeTextColor: const Color(0xFF86EFAC),
                              badgeBgColor: Colors.white.withValues(alpha: 0.15),
                              onTap: () => context.push('/tool/canada/mortgage')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_cmhc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_cmhc'),
                              toolId: 'canada_cmhc',
                              flagIcon: '🇨🇦',
                              icon: '🛡️',
                              name: 'CMHC Insurance',
                              description: 'Premium calculator',
                              badgeText: '<20% down',
                              badgeTextColor: const Color(0xFF92400E),
                              badgeBgColor: const Color(0xFFFEF3C7),
                              onTap: () => context.push('/tool/canada/cmhc'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_gds_tds',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_gds_tds'),
                              toolId: 'canada_gds_tds',
                              flagIcon: '🇨🇦',
                              icon: '📊',
                              name: 'GDS / TDS Ratio',
                              description: 'Gross debt service',
                              onTap: () => context.push('/tool/canada/gdstds'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_stress_test',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_stress_test'),
                              toolId: 'canada_stress_test',
                              flagIcon: '🇨🇦',
                              icon: '🧪',
                              name: 'Stress Test Calc',
                              description: 'Can you qualify?',
                              variant: ToolCardVariant.red,
                              onTap: () =>
                                  context.push('/tool/canada/stresstest')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_affordability',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_affordability'),
                              toolId: 'canada_affordability',
                              flagIcon: '🇨🇦',
                              icon: '💰',
                              name: 'Affordability',
                              description: 'Max home price, CAD',
                              onTap: () =>
                                  context.push('/tool/canada/affordability'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_amortization',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_amortization'),
                              toolId: 'canada_amortization',
                              flagIcon: '🇨🇦',
                              icon: '📅',
                              name: 'Amortization',
                              description: 'Bi-weekly schedule',
                              variant: ToolCardVariant.maple,
                              onTap: () =>
                                  context.push('/tool/canada/amortization')),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_renewal_planner',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_renewal_planner'),
                              toolId: 'canada_renewal_planner',
                              flagIcon: '🇨🇦',
                              icon: '🔄',
                              name: 'Renewal Planner',
                              description: 'Term renewal analysis',
                              onTap: () => context.push('/tool/canada/renewal'),
                              lightBorderColor: _theme.borderColor),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'canada_prepayment_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                              key: _getKey('canada_prepayment_calc'),
                              toolId: 'canada_prepayment_calc',
                              flagIcon: '🇨🇦',
                              icon: '📈',
                              name: 'Prepayment Calc',
                              description: 'Lump sum savings',
                              onTap: () =>
                                  context.push('/tool/canada/prepayment'),
                              lightBorderColor: _theme.borderColor),
                        ),
                      ],
                    ),
                    SectionLabel(
                        text: 'Province & Resources',
                        labelColor: _theme.mutedColor,
                        moreColor: _theme.primaryColor),
                    ...[
                      (
                        '🏛️',
                        'Land Transfer Tax',
                        'By Province: ON, BC, AB, QC, MB…',
                        '/tool/canada/ltt'
                      ),
                      (
                        '🏡',
                        'First-Home Buyer Incentive',
                        'FHBI · RRSP Home Buyers\' Plan',
                        '/tool/canada/firsthome'
                      ),
                      (
                        '📉',
                        'BoC Rate History',
                        'Live Bank of Canada rate tracker',
                        '/tool/canada/bocrate'
                      ),
                      (
                        '🤖',
                        'Canada AI Advisor',
                        'CMHC rules · stress test guidance',
                        '/tool/canada/aiadvisor'
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
                              borderColor: _theme.getBorderColor(context)),
                        )),
                    // ── Market Indicators (Live BoC API) ─────────────────────────────
                    SectionLabel(
                        text: 'Market Indicators',
                        labelColor: _theme.mutedColor,
                        moreColor: _theme.primaryColor),
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _theme.getCardColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _theme.getBorderColor(context)),
                      ),
                      child: Column(
                        children: [
                          _MarketIndicatorRow(
                            label: 'BoC Overnight Rate',
                            value: '${rOvernight.toStringAsFixed(2)}%',
                            note: isLive ? '🟢 Live · V39079' : 'est.',
                            theme: _theme,
                          ),
                          const Divider(height: 14, thickness: 0.4),
                          _MarketIndicatorRow(
                            label: 'Prime Rate',
                            value: '${rPrime.toStringAsFixed(2)}%',
                            note: isLive ? '🟢 Live · V80691311' : 'est.',
                            theme: _theme,
                          ),
                          const Divider(height: 14, thickness: 0.4),
                          _MarketIndicatorRow(
                            label: '5-Yr Govt Bond Yield',
                            value: '${bond5yr.toStringAsFixed(2)}%',
                            note: isLive ? '🟢 Live · V39051' : 'est.',
                            theme: _theme,
                            isGold: true,
                          ),
                          const Divider(height: 14, thickness: 0.4),
                          _MarketIndicatorRow(
                            label: '10-Yr Govt Bond Yield',
                            value: '${bond10yr.toStringAsFixed(2)}%',
                            note: isLive ? '🟢 Live · V39052' : 'est.',
                            theme: _theme,
                            isGold: true,
                          ),
                          const Divider(height: 14, thickness: 0.4),
                          _MarketIndicatorRow(
                            label: 'USD / CAD',
                            value: usdCad.toStringAsFixed(4),
                            note: isLive ? '🟢 Live · FXUSDCAD' : 'est.',
                            theme: _theme,
                          ),
                          if (!isLive) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🔌', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 6),
                                Text(
                                  'Showing estimated data — connect for live BoC rates',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _theme.getMutedColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
                countryLabel: 'Canada',
                countryRoute: '/canada'),
          ),
        ],
      ),
    );
  }
}

// ─── Market Indicator Row ─────────────────────────────────────────────────────
class _MarketIndicatorRow extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final CountryTheme theme;
  final bool isGold;

  const _MarketIndicatorRow({
    required this.label,
    required this.value,
    required this.note,
    required this.theme,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isGold
        ? const Color(0xFFD97706)
        : theme.getTextColor(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.getTextColor(context),
                  fontFamily: 'DMSans',
                ),
              ),
              Text(
                note,
                style: TextStyle(
                  fontSize: 9.5,
                  color: theme.getMutedColor(context),
                  fontFamily: 'DMSans',
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}
