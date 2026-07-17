// lib/features/europe/europe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/country_header.dart';
import '../../shared/widgets/hero_calculator_card.dart';
import '../../shared/widgets/hero_input_editor_sheet.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/alert_banner.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/tool_card.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/mortgage_math.dart';
import '../../shared/widgets/result_panel.dart';
import '../../shared/widgets/deep_link_highlight_wrapper.dart';
import '../../providers/europe_rates_provider.dart';

class EuropeScreen extends ConsumerStatefulWidget {
  final String? toolId;
  final bool fallback;

  const EuropeScreen({
    super.key,
    this.toolId,
    this.fallback = false,
  });

  @override
  ConsumerState<EuropeScreen> createState() => _EuropeScreenState();
}

class _EuropeScreenState extends ConsumerState<EuropeScreen> {
  static const _theme = CountryThemes.europe;
  double _propValue = 420000;
  double _depositPct = 20;
  int _termYears = 20;
  String _selectedCountry = 'DE';

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
  void didUpdateWidget(covariant EuropeScreen oldWidget) {
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

  // Static rate items are dynamically built from live provider in build()
  List<RateItem> _buildRateItems(EuropeCalculatedRates? r) {
    final ecb = r?.ecbRate.value ?? 4.00;
    final eu6m = r?.euribor6m.value ?? 3.42;
    final isLive = r?.isLive == true;
    return [
      RateItem(
          label: '🇩🇪 Germany',
          value: '${(ecb + 0.85).toStringAsFixed(2)}%',
          note: 'Fixed 10yr${isLive ? " 🟢" : ""}',
          color: RateColor.green),
      RateItem(label: '🇫🇷 France', value: '${(ecb + 0.60).toStringAsFixed(2)}%', note: 'Fixed 20yr'),
      RateItem(
          label: '🇪🇸 Spain',
          value: '${(eu6m + 1.10).toStringAsFixed(2)}%',
          note: 'Variable',
          color: RateColor.red),
      RateItem(
          label: 'ECB Rate',
          value: '${ecb.toStringAsFixed(2)}%',
          note: 'Current',
          color: RateColor.gold),
    ];
  }

  static const _euCountries = [
    ('🇩🇪', 'DE', 'Germany', 3.85),
    ('🇫🇷', 'FR', 'France', 3.60),
    ('🇪🇸', 'ES', 'Spain', 4.10),
    ('🇮🇹', 'IT', 'Italy', 4.20),
    ('🇳🇱', 'NL', 'Netherlands', 3.95),
    ('🇵🇹', 'PT', 'Portugal', 4.30),
  ];

  double get _selectedRate =>
      _euCountries.firstWhere((c) => c.$2 == _selectedCountry).$4;

  void _calculate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/europe/mortgage/result'),
      builder: (_) => _EUCalcSheet(
        propValue: _propValue,
        depositPct: _depositPct,
        termYears: _termYears,
        rate: _selectedRate,
        country: _selectedCountry,
      ),
    );
  }

  void _showInputEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/europe/mortgage/inputs'),
      builder: (_) => HeroInputEditorSheet(
        title: '\uD83C\uDDEA\uD83C\uDDFA Adjust Mortgage Inputs',
        primaryColor: _theme.primaryColor,
        configs: [
          HeroInputConfig(
            label: 'PROPERTY VALUE',
            value: _propValue,
            min: 50000, max: 3000000, divisions: 59,
            format: (v) => CurrencyFormatter.compact(v, symbol: '\u20AC'),
          ),
          HeroInputConfig(
            label: 'DEPOSIT',
            value: _depositPct,
            min: 5, max: 50, divisions: 45,
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
    final ratesAsync = ref.watch(europeRatesProvider);
    final r = ratesAsync.valueOrNull;
    final ecb = r?.ecbRate.value ?? 4.00;
    final eu3m = r?.euribor3m.value ?? 3.65;
    final eu6m = r?.euribor6m.value ?? 3.42;
    final eu12m = r?.euribor12m.value ?? 3.17;
    final eurUsd = r?.eurUsd.value ?? 1.0875;
    final eurGbp = r?.eurGbp.value ?? 0.8420;
    final cpi = r?.cpiInflation.value ?? 2.20;
    final isLive = r?.isLive == true;

    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CountryHeader(
                  theme: _theme,
                  rates: _buildRateItems(r),
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
                    // Select Country Row
                    SectionLabel(
                      text: 'Select Country',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _euCountries.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = _euCountries[i];
                          final active = c.$2 == _selectedCountry;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCountry = c.$2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color:
                                    active ? _theme.primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: active
                                      ? _theme.primaryColor
                                      : _theme.primaryColor
                                          .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                '${c.$1} ${c.$3}',
                                style: AppTextStyles.dmSans(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: active
                                        ? const Color(0xFFFFCC00)
                                        : _theme.primaryColor),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    HeroCalculatorCard(
                      theme: _theme,
                      tag: 'European Mortgage Calculator',
                      titleLine1: 'Calculate your',
                      accentWord: 'Baufinanzierung',
                      titleLine2: 'payment in EUR',
                      buttonEmoji: '⭐',
                      buttonText: 'Calculate European Mortgage',
                      inputs: [
                        HeroInputBox(
                            label: 'Property Value',
                            value: CurrencyFormatter.compact(_propValue,
                                symbol: '€')),
                        HeroInputBox(
                            label: 'Deposit', value: '${_depositPct.toInt()}%'),
                        HeroInputBox(label: 'Term', value: '$_termYears yr'),
                      ],
                      onCalculate: _calculate,
                      onInputTap: _showInputEditor,
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFF003399), Color(0xFF1A0040)],
                      ),
                    ),

                    // ECB Rate Monitor Banner
                    SectionLabel(
                      text: 'ECB Rate Monitor',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    AlertBanner(
                      icon: '🏛️',
                      title: 'ECB Rate: ${ecb.toStringAsFixed(2)}%${isLive ? '  🟢 Live' : ''}',
                      subtitle:
                          'European Central Bank — affects all Eurozone mortgages',
                      buttonText: 'View ECB',
                      bgColor1: const Color(0xFFEEF2FF),
                      bgColor2: const Color(0xFFE0E7FF),
                      borderColor: const Color(0xFF818CF8),
                      buttonColor: const Color(0xFF4F46E5),
                      titleColor: const Color(0xFF1E1B4B),
                      subtitleColor: const Color(0xFF4338CA),
                      onTap: () => context.push('/tool/europe/euribor'),
                    ),
                    const SizedBox(height: 12),

                    SectionLabel(
                      text: 'Core Tools',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: [
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_mortgage_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_mortgage_calc'),
                            toolId: 'europe_mortgage_calc',
                            flagIcon: '🇪🇺',
                            icon: '🏠',
                            name: 'Mortgage Calc',
                            description: 'EUR monthly payment',
                            variant: ToolCardVariant.dark,
                            badgeText: 'Multi-country',
                            badgeTextColor: Colors.white,
                            badgeBgColor: Colors.white.withValues(alpha: 0.15),
                            onTap: () => context.push('/tool/europe/mortgage'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_dti',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_dti'),
                            toolId: 'europe_dti',
                            flagIcon: '🇪🇺',
                            icon: '📊',
                            name: 'DTI Ratio EUR',
                            description: 'Debt-to-income Europe',
                            onTap: () => context.push('/tool/europe/dti'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_property_tax_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_property_tax_calc'),
                            toolId: 'europe_property_tax_calc',
                            flagIcon: '🇪🇺',
                            icon: '🏛️',
                            name: 'Property Tax Calc',
                            description: 'Country-specific taxes',
                            variant: ToolCardVariant.violet,
                            onTap: () => context.push('/tool/europe/propertytax'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_affordability',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_affordability'),
                            toolId: 'europe_affordability',
                            flagIcon: '🇪🇺',
                            icon: '💶',
                            name: 'Affordability EUR',
                            description: 'Borrowing capacity',
                            badgeText: 'Per country',
                            badgeTextColor: const Color(0xFF166534),
                            badgeBgColor: const Color(0xFFF0FDF4),
                            onTap: () => context.push('/tool/europe/affordability'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_amortization',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_amortization'),
                            toolId: 'europe_amortization',
                            flagIcon: '🇪🇺',
                            icon: '📅',
                            name: 'Amortization',
                            description: 'European schedule',
                            onTap: () => context.push('/tool/europe/amortization'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_euribor_tracker',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_euribor_tracker'),
                            toolId: 'europe_euribor_tracker',
                            flagIcon: '🇪🇺',
                            icon: '🔄',
                            name: 'Euribor Tracker',
                            description: 'Variable rate index',
                            variant: ToolCardVariant.gold,
                            onTap: () => context.push('/tool/europe/euribor'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_country_comparison',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_country_comparison'),
                            toolId: 'europe_country_comparison',
                            flagIcon: '🇪🇺',
                            icon: '🌍',
                            name: 'Country Comparison',
                            description: 'Compare EU rates',
                            variant: ToolCardVariant.teal,
                            onTap: () => context.push('/tool/europe/comparison'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_notary_fee_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_notary_fee_calc'),
                            toolId: 'europe_notary_fee_calc',
                            flagIcon: '🇪🇺',
                            icon: '📜',
                            name: 'Notary Fee Calc',
                            description: 'DE/FR/ES closing costs',
                            onTap: () => context.push('/tool/europe/notaryfee'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_non_resident_calc',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_non_resident_calc'),
                            toolId: 'europe_non_resident_calc',
                            flagIcon: '🇪🇺',
                            icon: '🏘️',
                            name: 'Non-Resident Calc',
                            description: 'Foreign buyer guide',
                            variant: ToolCardVariant.slate,
                            onTap: () => context.push('/tool/europe/nonresident'),
                          ),
                        ),
                        DeepLinkHighlightWrapper(
                          toolId: 'europe_currency_converter',
                          activeToolId: widget.toolId,
                          highlightColor: _theme.primaryColor,
                          child: ToolCard(
                            key: _getKey('europe_currency_converter'),
                            toolId: 'europe_currency_converter',
                            flagIcon: '🇪🇺',
                            icon: '💱',
                            name: 'Currency Converter',
                            description: 'EUR · GBP · USD · CHF',
                            onTap: () => context.push('/tool/europe/currency'),
                            lightBorderColor: _theme.borderColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Countries & Resources List
                    SectionLabel(
                      text: 'Countries & Resources',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    ..._resources(context),

                    // ── Market Indicators Section ──────────────────────
                    const SizedBox(height: 8),
                    SectionLabel(
                      text: 'ECB Market Indicators',
                      labelColor: _theme.mutedColor,
                      moreColor: _theme.primaryColor,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _theme.getCardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _theme.getBorderColor(context)),
                      ),
                      child: Column(
                        children: [
                          _MarketIndicatorRow(
                            label: 'ECB Main Rate',
                            value: '${ecb.toStringAsFixed(2)}%',
                            series: 'FM/BB.1000.M',
                            theme: _theme,
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          _MarketIndicatorRow(
                            label: 'Euribor 3M',
                            value: '${eu3m.toStringAsFixed(2)}%',
                            series: 'FM/EURIBOR3MD',
                            theme: _theme,
                            isAccent: true,
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          _MarketIndicatorRow(
                            label: 'Euribor 6M',
                            value: '${eu6m.toStringAsFixed(2)}%',
                            series: 'FM/EURIBOR6MD',
                            theme: _theme,
                            isAccent: true,
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          _MarketIndicatorRow(
                            label: 'Euribor 12M',
                            value: '${eu12m.toStringAsFixed(2)}%',
                            series: 'FM/EURIBOR1YD',
                            theme: _theme,
                            isAccent: true,
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          _MarketIndicatorRow(
                            label: 'EUR / USD',
                            value: eurUsd.toStringAsFixed(4),
                            series: 'EXR/D.USD',
                            theme: _theme,
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          _MarketIndicatorRow(
                            label: 'EUR / GBP',
                            value: eurGbp.toStringAsFixed(4),
                            series: 'EXR/D.GBP',
                            theme: _theme,
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          _MarketIndicatorRow(
                            label: 'Eurozone CPI',
                            value: '${cpi.toStringAsFixed(1)}%',
                            series: 'ICP/HICP',
                            theme: _theme,
                          ),
                          if (!isLive) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Text('⚠️', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Estimated values — ECB API unreachable. Values shown are 2025 Q2 benchmarks.',
                                      style: AppTextStyles.dmSans(
                                        size: 9.5,
                                        color: _theme.getMutedColor(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCF4E8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '🟢 Live · ECB Data Portal',
                                    style: AppTextStyles.dmSans(
                                      size: 8.5,
                                      weight: FontWeight.bold,
                                      color: const Color(0xFF1A5C35),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
              countryLabel: 'Europe',
              countryRoute: '/europe',
            ),
          ),
        ],
      ),
    );
  }



  List<Widget> _resources(BuildContext context) {
    final items = [
      ('🇩🇪', 'Germany – Baufinanzierung', '10yr fixed · Grunderwerbsteuer'),
      ('🇫🇷', 'France – Prêt Immobilier', '20yr fixed · Frais de notaire'),
      ('🇪🇸', 'Spain – Hipoteca', 'Euribor variable · ITP/AJD tax'),
      ('🤖', 'Europe AI Advisor', 'ECB rules · multi-country guidance'),
    ];
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InfoCard(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
                onTap: () => context.push('/ai/eu'),
                iconBgColor: _theme.getBgColor(context),
                titleColor: _theme.getTextColor(context),
                subtitleColor: _theme.getMutedColor(context),
                borderColor: _theme.getBorderColor(context),
              ),
            ))
        .toList();
  }
}

// ─── Market Indicator Row ──────────────────────────────────────────
class _MarketIndicatorRow extends StatelessWidget {
  final String label;
  final String value;
  final String series;
  final CountryTheme theme;
  final bool isAccent;

  const _MarketIndicatorRow({
    required this.label,
    required this.value,
    required this.series,
    required this.theme,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isAccent
        ? const Color(0xFFFFCC00)
        : theme.getTextColor(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w600,
                color: theme.getTextColor(context),
              ),
            ),
            Text(
              series,
              style: AppTextStyles.dmSans(
                size: 9,
                color: theme.getMutedColor(context),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.playfair(
            size: 16,
            weight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─── Calculator Bottom Sheet ──────────────────────────────────────
class _EUCalcSheet extends StatelessWidget {
  final double propValue, depositPct, rate;
  final int termYears;
  final String country;

  const _EUCalcSheet(
      {required this.propValue,
      required this.depositPct,
      required this.termYears,
      required this.rate,
      required this.country});

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.europe;
    final loan = propValue * (1 - depositPct / 100);
    final monthly = MortgageMath.monthlyPayment(
        principal: loan, annualRatePercent: rate, termYears: termYears);
    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
            color: theme.getBgColor(context),
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
            Text('🏛️ European Mortgage Result',
                style: AppTextStyles.dmSans(
                    size: 18,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context))),
            const SizedBox(height: 16),
            ResultPanel(
              primaryColor: const Color(0xFF00236B),
              rows: [
                ResultRow(
                    label: 'Monthly Payment',
                    value: monthly,
                    currencyCode: 'EUR',
                    isHighlighted: true),
                ResultRow(
                    label: 'Loan Amount', value: loan, currencyCode: 'EUR'),
                ResultRow(label: 'Interest Rate', value: rate, isPercent: true),
                ResultRow(
                    label: 'Total Interest',
                    value: MortgageMath.totalInterest(
                        principal: loan,
                        annualRatePercent: rate,
                        termYears: termYears),
                    currencyCode: 'EUR'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
