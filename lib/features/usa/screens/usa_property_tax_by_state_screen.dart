// lib/features/usa/screens/usa_property_tax_by_state_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';

// ─── Data Model ────────────────────────────────────────────────────────────
class _StateData {
  final int rank;
  final String name;
  final String abbr;
  final String note;
  final double rate;
  final double medianBill;
  final String region; // all | northeast | south | midwest | west
  const _StateData({
    required this.rank,
    required this.name,
    required this.abbr,
    required this.note,
    required this.rate,
    required this.medianBill,
    required this.region,
  });
}

const List<_StateData> _allStates = [
  _StateData(rank: 1,  name: 'New Jersey',        abbr: 'NJ', note: 'No homestead limit',              rate: 2.33, medianBill: 8602,  region: 'northeast'),
  _StateData(rank: 2,  name: 'Illinois',           abbr: 'IL', note: 'Senior freeze available',          rate: 2.08, medianBill: 4877,  region: 'midwest'),
  _StateData(rank: 3,  name: 'Connecticut',        abbr: 'CT', note: 'Mill rate system',                 rate: 2.02, medianBill: 6484,  region: 'northeast'),
  _StateData(rank: 4,  name: 'New Hampshire',      abbr: 'NH', note: 'No income or sales tax',          rate: 1.89, medianBill: 6196,  region: 'northeast'),
  _StateData(rank: 5,  name: 'Vermont',            abbr: 'VT', note: 'Education fund tax',               rate: 1.84, medianBill: 4329,  region: 'northeast'),
  _StateData(rank: 6,  name: 'New York',           abbr: 'NY', note: 'STAR exemption program',           rate: 1.72, medianBill: 5732,  region: 'northeast'),
  _StateData(rank: 7,  name: 'Wisconsin',          abbr: 'WI', note: 'Lottery credit available',         rate: 1.67, medianBill: 3472,  region: 'midwest'),
  _StateData(rank: 8,  name: 'Texas',              abbr: 'TX', note: 'No income tax · Homestead',        rate: 1.66, medianBill: 3797,  region: 'south'),
  _StateData(rank: 9,  name: 'Nebraska',           abbr: 'NE', note: 'Homestead exemption',              rate: 1.63, medianBill: 3013,  region: 'midwest'),
  _StateData(rank: 10, name: 'Michigan',           abbr: 'MI', note: 'Principal residence exempt.',      rate: 1.60, medianBill: 2817,  region: 'midwest'),
  _StateData(rank: 11, name: 'Ohio',               abbr: 'OH', note: '2.5% rollback credit',             rate: 1.55, medianBill: 2456,  region: 'midwest'),
  _StateData(rank: 12, name: 'Pennsylvania',       abbr: 'PA', note: 'Homestead exclusion',              rate: 1.53, medianBill: 3072,  region: 'northeast'),
  _StateData(rank: 13, name: 'Iowa',               abbr: 'IA', note: 'Rollback adjustment',              rate: 1.50, medianBill: 2635,  region: 'midwest'),
  _StateData(rank: 14, name: 'Kansas',             abbr: 'KS', note: 'Homestead refund credit',          rate: 1.47, medianBill: 2445,  region: 'midwest'),
  _StateData(rank: 15, name: 'Rhode Island',       abbr: 'RI', note: 'Homestead exemption',              rate: 1.43, medianBill: 4483,  region: 'northeast'),
  _StateData(rank: 16, name: 'South Dakota',       abbr: 'SD', note: 'No income tax',                    rate: 1.39, medianBill: 2447,  region: 'midwest'),
  _StateData(rank: 17, name: 'Maine',              abbr: 'ME', note: 'Circuit breaker rebate',            rate: 1.36, medianBill: 3003,  region: 'northeast'),
  _StateData(rank: 18, name: 'Minnesota',          abbr: 'MN', note: 'Homestead market val. exclusion',  rate: 1.32, medianBill: 3141,  region: 'midwest'),
  _StateData(rank: 19, name: 'Massachusetts',      abbr: 'MA', note: '\$1,000 residential exemption',    rate: 1.28, medianBill: 5314,  region: 'northeast'),
  _StateData(rank: 20, name: 'Maryland',           abbr: 'MD', note: 'Homestead tax credit',             rate: 1.25, medianBill: 3573,  region: 'south'),
  _StateData(rank: 21, name: 'Oregon',             abbr: 'OR', note: 'Assessed val. cap 3%/yr',          rate: 1.22, medianBill: 3294,  region: 'west'),
  _StateData(rank: 22, name: 'North Dakota',       abbr: 'ND', note: 'Property tax relief program',      rate: 1.20, medianBill: 2056,  region: 'midwest'),
  _StateData(rank: 23, name: 'Missouri',           abbr: 'MO', note: 'Senior property tax credit',       rate: 1.14, medianBill: 1847,  region: 'midwest'),
  _StateData(rank: 24, name: 'Washington',         abbr: 'WA', note: 'No income tax',                    rate: 1.12, medianBill: 4003,  region: 'west'),
  _StateData(rank: 25, name: 'Montana',            abbr: 'MT', note: 'Residential market value',         rate: 1.09, medianBill: 2119,  region: 'west'),
  _StateData(rank: 26, name: 'North Carolina',     abbr: 'NC', note: 'Elderly/disabled exclusion',       rate: 1.07, medianBill: 1833,  region: 'south'),
  _StateData(rank: 27, name: 'Indiana',            abbr: 'IN', note: '1% gross assessed deduction',      rate: 1.04, medianBill: 1594,  region: 'midwest'),
  _StateData(rank: 28, name: 'Virginia',           abbr: 'VA', note: 'Land Use val. program',            rate: 0.99, medianBill: 2985,  region: 'south'),
  _StateData(rank: 29, name: 'Florida',            abbr: 'FL', note: '\$50K homestead exemption',        rate: 0.98, medianBill: 2143,  region: 'south'),
  _StateData(rank: 30, name: 'Georgia',            abbr: 'GA', note: 'Homestead standard deduction',     rate: 0.93, medianBill: 1850,  region: 'south'),
  _StateData(rank: 31, name: 'Colorado',           abbr: 'CO', note: 'Gallagher Amendment',              rate: 0.91, medianBill: 2017,  region: 'west'),
  _StateData(rank: 32, name: 'Alaska',             abbr: 'AK', note: 'No state income or sales tax',     rate: 0.90, medianBill: 3771,  region: 'west'),
  _StateData(rank: 33, name: 'Mississippi',        abbr: 'MS', note: 'Homestead exemption \$7.5K',       rate: 0.89, medianBill: 929,   region: 'south'),
  _StateData(rank: 34, name: 'Kentucky',           abbr: 'KY', note: 'Homestead exemption eligible',     rate: 0.88, medianBill: 1257,  region: 'south'),
  _StateData(rank: 35, name: 'Tennessee',          abbr: 'TN', note: 'No income tax (wages)',            rate: 0.87, medianBill: 1459,  region: 'south'),
  _StateData(rank: 36, name: 'Idaho',              abbr: 'ID', note: 'Circuit breaker program',          rate: 0.86, medianBill: 1893,  region: 'west'),
  _StateData(rank: 37, name: 'Nevada',             abbr: 'NV', note: 'No state income tax · 3% cap',    rate: 0.85, medianBill: 2107,  region: 'west'),
  _StateData(rank: 38, name: 'Oklahoma',           abbr: 'OK', note: 'Homestead exemption \$1K off',     rate: 0.84, medianBill: 1261,  region: 'south'),
  _StateData(rank: 39, name: 'Arizona',            abbr: 'AZ', note: 'Owner-occ. primary prop. ratio',   rate: 0.81, medianBill: 1648,  region: 'west'),
  _StateData(rank: 40, name: 'New Mexico',         abbr: 'NM', note: 'Valuation cap program',            rate: 0.80, medianBill: 1406,  region: 'west'),
  _StateData(rank: 41, name: 'West Virginia',      abbr: 'WV', note: 'Homestead exemption 60+',          rate: 0.78, medianBill: 719,   region: 'south'),
  _StateData(rank: 42, name: 'South Carolina',     abbr: 'SC', note: '4% primary res. assessment',       rate: 0.77, medianBill: 1024,  region: 'south'),
  _StateData(rank: 43, name: 'California',         abbr: 'CA', note: 'Prop 13 · 1% + bonds limit',      rate: 0.76, medianBill: 4279,  region: 'west'),
  _StateData(rank: 44, name: 'Delaware',           abbr: 'DE', note: 'Senior school property rebate',    rate: 0.75, medianBill: 1603,  region: 'south'),
  _StateData(rank: 45, name: 'Arkansas',           abbr: 'AR', note: 'Homestead credit \$425/yr',        rate: 0.63, medianBill: 802,   region: 'south'),
  _StateData(rank: 46, name: 'Utah',               abbr: 'UT', note: 'Primary res. partial exemption',   rate: 0.60, medianBill: 1837,  region: 'west'),
  _StateData(rank: 47, name: 'Wyoming',            abbr: 'WY', note: 'No income tax · 9.5% res. ratio', rate: 0.57, medianBill: 1380,  region: 'west'),
  _StateData(rank: 48, name: 'Louisiana',          abbr: 'LA', note: '\$75K homestead exemption',        rate: 0.54, medianBill: 832,   region: 'south'),
  _StateData(rank: 49, name: 'DC',                 abbr: 'DC', note: 'Homestead deduction \$84,850',     rate: 0.46, medianBill: 3641,  region: 'south'),
  _StateData(rank: 50, name: 'Hawaii',             abbr: 'HI', note: 'Home exemption \$140K+',           rate: 0.27, medianBill: 1971,  region: 'west'),
];

const _noIncomeTaxStates = [
  ('🤠', 'Texas'),
  ('🌞', 'Florida'),
  ('🏔️', 'Nevada'),
  ('🌧️', 'Washington'),
  ('🏔️', 'Wyoming'),
  ('🌲', 'Alaska'),
  ('🏜️', 'South Dakota'),
  ('🌿', 'New Hampshire'),
  ('🎰', 'Tennessee'),
];

// ─── Screen ────────────────────────────────────────────────────────────────
class USAPropertyTaxByStateScreen extends StatefulWidget {
  const USAPropertyTaxByStateScreen({super.key});

  @override
  State<USAPropertyTaxByStateScreen> createState() =>
      _USAPropertyTaxByStateScreenState();
}

class _USAPropertyTaxByStateScreenState
    extends State<USAPropertyTaxByStateScreen> {
  static const _theme = CountryThemes.usa;

  // Calculator state
  double _homeValue = 450000;
  String _selectedStateAbbr = 'US'; // 'US' = US Average
  bool _calcDone = false;

  // Filter state
  String _searchQuery = '';
  String _selectedRegion = 'all';

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lookup rate for selected state or US avg
  double get _selectedRate {
    if (_selectedStateAbbr == 'US') return 1.08;
    return _allStates.firstWhere((s) => s.abbr == _selectedStateAbbr,
        orElse: () => _allStates.first).rate;
  }

  double get _annualTax => _homeValue * (_selectedRate / 100);
  double get _monthlyTax => _annualTax / 12;
  double get _dailyTax => _annualTax / 365;

  List<_StateData> get _filteredStates {
    return _allStates.where((s) {
      final matchRegion =
          _selectedRegion == 'all' || s.region == _selectedRegion;
      final matchSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchRegion && matchSearch;
    }).toList();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _rateColor(double rate) {
    if (rate >= 1.80) return const Color(0xFFB91C1C);
    if (rate >= 1.20) return const Color(0xFFD97706);
    if (rate >= 0.80) return const Color(0xFF1B3F72);
    if (rate >= 0.60) return const Color(0xFF15803D);
    return const Color(0xFF0D9488);
  }

  Color _barColor(double rate) {
    if (rate >= 1.80) return const Color(0xFFB91C1C);
    if (rate >= 1.20) return const Color(0xFFD97706);
    if (rate >= 0.80) return const Color(0xFF1B3F72);
    if (rate >= 0.60) return const Color(0xFF0F766E);
    return const Color(0xFF0D9488);
  }

  String _tierNote() {
    if (_selectedRate >= 1.80) {
      return '🔴 High tax state. Consider neighboring states or homestead exemptions.';
    } else if (_selectedRate >= 1.20) {
      return '🟡 Above-average rate. Verify homestead and senior exemptions available.';
    } else if (_selectedRate >= 0.80) {
      return '🟢 Average tax state. Check local exemptions for additional savings.';
    } else {
      return '✅ Low tax state. Note: check total tax burden including income & sales tax.';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: CustomScrollView(
        slivers: [
          _buildHeader(isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section: Calculator
                _sectionLabel('Property Tax Calculator', moreText: '2024 Data →'),
                const SizedBox(height: 8),
                _buildHeroCalculator(isDark),
                const SizedBox(height: 20),

                // Section: Extremes
                _sectionLabel('Highest & Lowest Rates', moreText: 'Rank All →'),
                const SizedBox(height: 8),
                _buildExtremesRow(),
                const SizedBox(height: 20),

                // Section: State Table
                _sectionLabel('All 50 States + DC', moreText: 'Sort by Rate →'),
                const SizedBox(height: 8),
                _buildSearchBar(isDark),
                const SizedBox(height: 8),
                _buildRegionTabs(isDark),
                const SizedBox(height: 8),
                _buildStateTable(isDark),
                const SizedBox(height: 20),

                // Section: No Income Tax States
                _sectionLabel('No State Income Tax', moreText: 'Tax Comparison →'),
                const SizedBox(height: 8),
                _buildNoIncomeTaxCard(isDark),
                const SizedBox(height: 20),

                // Section: Resources
                _sectionLabel('Homeowner Resources', moreText: 'All →'),
                const SizedBox(height: 8),
                _buildResourcesList(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header SliverAppBar ──────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 176,
      pinned: true,
      backgroundColor: const Color(0xFF0B1D3A),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          alignment: Alignment.center,
          child: Text('←',
              style: AppTextStyles.dmSans(size: 18, color: Colors.white)),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(10),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          alignment: Alignment.center,
          child: const Text('🔔', style: TextStyle(fontSize: 16)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFD97706)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 50,
                child: Text('🗺️',
                    style: TextStyle(
                        fontSize: 72,
                        color: Colors.white.withValues(alpha: 0.07))),
              ),
              // Title block
              Positioned(
                bottom: 54,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text('🗺️', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      'Property Tax by State',
                      style: AppTextStyles.playfair(
                        size: 19,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All 50 States · Effective Rates · 2024–2025 Data',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.52),
                      ),
                    ),
                  ],
                ),
              ),
              // Rate strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _rateStripCell(
                            'US Average', '1.08%', 'Eff. Rate', null),
                      ),
                      _vDivider(),
                      Expanded(
                        child: _rateStripCell(
                            'Highest', '2.33%', 'New Jersey',
                            const Color(0xFFFCA5A5)),
                      ),
                      _vDivider(),
                      Expanded(
                        child: _rateStripCell(
                            'Lowest', '0.27%', 'Hawaii',
                            const Color(0xFF6EE7B7)),
                      ),
                      _vDivider(),
                      Expanded(
                        child: _rateStripCell('No Tax', '0', 'States', null),
                      ),
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

  Widget _vDivider() => Container(
        width: 1,
        height: 30,
        color: Colors.white.withValues(alpha: 0.14),
      );

  Widget _rateStripCell(
      String label, String value, String note, Color? valColor) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8.5,
                color: Colors.white.withValues(alpha: 0.48),
                weight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 15,
            weight: FontWeight.w800,
            color: valColor ?? const Color(0xFFFCD34D),
          ),
        ),
        Text(note,
            style: AppTextStyles.dmSans(
                size: 8, color: Colors.white.withValues(alpha: 0.38))),
      ],
    );
  }

  // ─── Section Label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {String? moreText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w800,
            color: _theme.getMutedColor(context),
            letterSpacing: 1,
          ),
        ),
        if (moreText != null)
          Text(
            moreText,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w600,
              color: _theme.primaryColor,
            ),
          ),
      ],
    );
  }

  // ─── Hero Calculator ──────────────────────────────────────────────────────
  Widget _buildHeroCalculator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative orb
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMATE ANNUAL PROPERTY TAX · BY STATE',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: Colors.white.withValues(alpha: 0.48),
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: 'Your Property Tax ',
                  style: AppTextStyles.playfair(
                    size: 18,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: 'Estimate',
                      style: AppTextStyles.playfair(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // Row: Home Value + State Select
              Row(
                children: [
                  Expanded(child: _buildCalcInputField()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStateDropdown()),
                ],
              ),
              const SizedBox(height: 8),

              // Home value slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFD97706),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
                  thumbColor: const Color(0xFFFCD34D),
                  overlayColor:
                      const Color(0xFFD97706).withValues(alpha: 0.20),
                  trackHeight: 4,
                ),
                child: Slider(
                  min: 100000,
                  max: 2000000,
                  divisions: 190,
                  value: _homeValue.clamp(100000, 2000000),
                  onChanged: (v) => setState(() => _homeValue = v),
                ),
              ),

              // Calculate button
              GestureDetector(
                onTap: () => setState(() => _calcDone = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFB45309)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🗺️  Calculate Property Tax',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Result box
              if (_calcDone) ...[
                const SizedBox(height: 10),
                _buildCalcResultBox(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalcInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOME VALUE',
            style: AppTextStyles.dmSans(
                size: 8.5,
                color: Colors.white.withValues(alpha: 0.55),
                weight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '\$${_homeValue.round().toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
            style: AppTextStyles.dmSans(
                size: 13, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'US',
        child: Text('US Average (1.08%)',
            style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w700,
                color: Colors.white),
            overflow: TextOverflow.ellipsis),
      ),
      ..._allStates.map((s) => DropdownMenuItem(
            value: s.abbr,
            child: Text('${s.name} (${s.rate.toStringAsFixed(2)}%)',
                style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white),
                overflow: TextOverflow.ellipsis),
          )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT STATE',
            style: AppTextStyles.dmSans(
                size: 8.5,
                color: Colors.white.withValues(alpha: 0.55),
                weight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStateAbbr,
              items: items,
              onChanged: (v) {
                if (v != null) setState(() => _selectedStateAbbr = v);
              },
              dropdownColor: const Color(0xFF0B1D3A),
              icon: Icon(Icons.arrow_drop_down,
                  color: Colors.white.withValues(alpha: 0.7)),
              isExpanded: true,
              style: AppTextStyles.dmSans(
                  size: 12, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcResultBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 PROPERTY TAX ESTIMATE',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _resultItem('Annual Tax', '\$${_annualTax.round().toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}', const Color(0xFFFCD34D))),
              Expanded(child: _resultItem('Monthly', '\$${_monthlyTax.round().toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}', Colors.white)),
              Expanded(child: _resultItem('Daily Cost', '\$${_dailyTax.toStringAsFixed(2)}', Colors.white)),
              Expanded(child: _resultItem('Eff. Rate', '${_selectedRate.toStringAsFixed(2)}%', const Color(0xFF6EE7B7))),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          Text(
            _tierNote(),
            style: AppTextStyles.dmSans(
              size: 9,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _resultItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9, color: Colors.white.withValues(alpha: 0.50))),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 15,
            weight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ─── Extremes Cards ───────────────────────────────────────────────────────
  Widget _buildExtremesRow() {
    return Row(
      children: [
        Expanded(child: _extremeCard(
          isHigh: true,
          label: '🔴 Highest Tax States',
          rate: '2.33',
          title: 'New Jersey',
          note: 'Avg. bill ~\$9,000/yr on median home',
          states: 'NJ · IL · CT · NH · VT',
        )),
        const SizedBox(width: 10),
        Expanded(child: _extremeCard(
          isHigh: false,
          label: '🟢 Lowest Tax States',
          rate: '0.27',
          title: 'Hawaii',
          note: 'But high home values offset low rates',
          states: 'HI · LA · WY · UT · DC',
        )),
      ],
    );
  }

  Widget _extremeCard({
    required bool isHigh,
    required String label,
    required String rate,
    required String title,
    required String note,
    required String states,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHigh
              ? [const Color(0xFFB91C1C), const Color(0xFF991B1B)]
              : [const Color(0xFF15803D), const Color(0xFF166534)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 9,
                  color: Colors.white.withValues(alpha: 0.55),
                  weight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              text: rate,
              style: AppTextStyles.dmSans(
                size: 26,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: '%',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(title,
              style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.w800,
                color: Colors.white,
              )),
          const SizedBox(height: 4),
          Text(note,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white.withValues(alpha: 0.55))),
          const SizedBox(height: 5),
          Text(states,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('🔍',
              style: TextStyle(
                  fontSize: 16,
                  color: _theme.getMutedColor(context))),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.dmSans(
                  size: 13, color: _theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Search state name…',
                hintStyle: AppTextStyles.dmSans(
                    size: 13, color: _theme.getMutedColor(context)),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.close,
                  size: 18, color: _theme.getMutedColor(context)),
            ),
        ],
      ),
    );
  }

  // ─── Region Tabs ──────────────────────────────────────────────────────────
  Widget _buildRegionTabs(bool isDark) {
    const tabs = [
      ('all', 'All States'),
      ('northeast', 'Northeast'),
      ('south', 'South'),
      ('midwest', 'Midwest'),
      ('west', 'West'),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final isActive = _selectedRegion == tabs[i].$1;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedRegion = tabs[i].$1;
              _searchQuery = '';
              _searchController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0B1D3A)
                    : _theme.getCardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF0B1D3A)
                      : _theme.getBorderColor(context),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i].$2,
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : _theme.getMutedColor(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── State Table ──────────────────────────────────────────────────────────
  Widget _buildStateTable(bool isDark) {
    final states = _filteredStates;
    const maxRate = 2.33;

    return Container(
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 28,
                    child: _tableHeader('#', alignLeft: true)),
                Expanded(flex: 3, child: _tableHeader('State', alignLeft: true)),
                SizedBox(width: 52, child: _tableHeader('Rate')),
                SizedBox(width: 64, child: _tableHeader('Med. Bill')),
                SizedBox(width: 60, child: _tableHeader('Bar')),
              ],
            ),
          ),
          // State rows
          if (states.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No states match your search.',
                style: AppTextStyles.dmSans(
                    size: 13, color: _theme.getMutedColor(context)),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...states.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == states.length - 1;
              final barWidth = s.rate / maxRate;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedStateAbbr = s.abbr;
                  _calcDone = true;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                                color: _theme.getBorderColor(context),
                                width: 0.8)),
                    borderRadius: isLast
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(17))
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${s.rank}',
                          style: AppTextStyles.dmSans(
                              size: 10,
                              weight: FontWeight.w700,
                              color: _theme.getMutedColor(context)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: AppTextStyles.playfair(
                                size: 12,
                                weight: FontWeight.w800,
                                color: _theme.getTextColor(context),
                              ),
                            ),
                            Text(
                              s.note,
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: _theme.getMutedColor(context)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: _ratePill(s.rate),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '\$${s.medianBill.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                          style: AppTextStyles.dmSans(
                              size: 10,
                              weight: FontWeight.w700,
                              color: _theme.getMutedColor(context)),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 6,
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFF1F5F9),
                                child: FractionallySizedBox(
                                  widthFactor: barWidth,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    color: _barColor(s.rate),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {bool alignLeft = false}) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.dmSans(
        size: 9,
        weight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.55),
        letterSpacing: 0.4,
      ),
      textAlign: alignLeft ? TextAlign.left : TextAlign.right,
    );
  }

  Widget _ratePill(double rate) {
    final color = _rateColor(rate);
    final bg = color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${rate.toStringAsFixed(2)}%',
        style: AppTextStyles.dmSans(
          size: 9.5,
          weight: FontWeight.w800,
          color: color,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  // ─── No Income Tax States Card ────────────────────────────────────────────
  Widget _buildNoIncomeTaxCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
        color: isDark ? const Color(0xFF1A1500) : null,
        border: Border.all(
          color: isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 9 States with Zero Income Tax',
            style: AppTextStyles.playfair(
              size: 12.5,
              weight: FontWeight.w800,
              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Higher property taxes may offset income tax savings — compare total tax burden',
            style: AppTextStyles.dmSans(
              size: 9.5,
              color: isDark ? const Color(0xFFD97706) : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _noIncomeTaxStates.map((s) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  '${s.$1} ${s.$2}',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFF92400E),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Resources List ───────────────────────────────────────────────────────
  Widget _buildResourcesList(bool isDark) {
    const resources = [
      ('📋', 'How to Appeal Property Tax',
          'Assessment appeal process · Comparable sales argument'),
      ('🏠', 'Homestead Exemptions',
          'State-by-state savings for primary residence owners'),
      ('👴', 'Senior & Veteran Exemptions',
          'Age 65+ freeze · disabled veteran 100% exemption'),
      ('📊', 'Effective vs Nominal Rate',
          'Why Prop 13 CA is low despite high home values'),
      ('🧾', 'Mortgage Tax Deduction',
          'Deduct up to \$10K SALT on federal return (post-TCJA)'),
    ];
    return Column(
      children: resources.asMap().entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _theme.getCardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(entry.value.$1,
                    style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value.$2,
                      style: AppTextStyles.playfair(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: _theme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.value.$3,
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: _theme.getMutedColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Text('›',
                  style: AppTextStyles.dmSans(
                      size: 20,
                      color: _theme.getMutedColor(context)
                          .withValues(alpha: 0.4))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
