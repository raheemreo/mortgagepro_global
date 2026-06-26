// lib/features/usa/screens/usa_fha_loan_limits_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/currency_formatter.dart';

class USAFhaLoanLimitsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFhaLoanLimitsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFhaLoanLimitsScreen> createState() => _USAFhaLoanLimitsScreenState();
}

class _USAFhaLoanLimitsScreenState extends ConsumerState<USAFhaLoanLimitsScreen> {
  static const _theme = CountryThemes.usa;

  final _medianPriceController = TextEditingController(text: '450000');
  int _selectedUnits = 1;
  String _selectedAreaType = 'standard';
  bool _calculated = false;

  // Outputs
  double _pct115 = 0;
  double _floor = 0;
  double _ceiling = 0;
  double _estimatedLimit = 0;
  String _resultBasis = '';

  static const floors = {1: 541287.0, 2: 693050.0, 3: 837700.0, 4: 1041125.0};
  static const ceilings = {1: 1249125.0, 2: 1599375.0, 3: 1933200.0, 4: 2402625.0};

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _medianPriceController.text = (inputs['medianPrice'] ?? 450000.0).toStringAsFixed(0);
      _selectedUnits = (inputs['units'] ?? 1.0).toInt();
      final areaIdx = (inputs['areaTypeIndex'] ?? 0.0).toInt();
      _selectedAreaType = areaIdx == 0 ? 'standard' : areaIdx == 1 ? 'highcost' : 'special';
      _calculate();
    }
  }

  @override
  void dispose() {
    _medianPriceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final median = double.tryParse(_medianPriceController.text) ?? 0.0;
    final floor = floors[_selectedUnits] ?? 541287.0;
    final ceiling = ceilings[_selectedUnits] ?? 1249125.0;
    final pct115 = median * 1.15;

    double result = 0;
    String basis = '';

    if (_selectedAreaType == 'special') {
      result = (floor * 2.25 / 0.65) > (ceiling * 1.5)
          ? (ceiling * 1.5)
          : (pct115 * 1.95).clamp(0.0, ceiling * 1.5);
      result = result.clamp(floor * 2.25 / 0.65, double.infinity);
      basis = 'Special Exception (225%)';
    } else if (pct115 <= floor) {
      result = floor;
      basis = 'Floor Applied';
    } else if (pct115 >= ceiling) {
      result = ceiling;
      basis = 'Ceiling Applied (High-Cost)';
    } else {
      result = pct115;
      basis = '115% of Median Price';
    }

    setState(() {
      _pct115 = pct115;
      _floor = floor;
      _ceiling = ceiling;
      _estimatedLimit = result;
      _resultBasis = basis;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;
    final median = double.tryParse(_medianPriceController.text) ?? 0.0;
    final areaIdx = _selectedAreaType == 'standard' ? 0 : _selectedAreaType == 'highcost' ? 1 : 2;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FHA Loan Limits',
      label: 'FHA Limit: ${CurrencyFormatter.format(_estimatedLimit, symbol: '\$').split('.').first} ($_selectedUnits-Unit)',
      currencyCode: 'USD',
      inputs: {
        'medianPrice': median,
        'units': _selectedUnits.toDouble(),
        'areaTypeIndex': areaIdx.toDouble(),
      },
      results: {
        'EstimatedLimit': _estimatedLimit,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ FHA loan limits estimate saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: const Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF15803D), Color(0xFF166534)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('2026 FHA Loan Limits',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('National Floor · Ceiling · County Lookup',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rate Strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStripItem('1-Unit Floor', '\$541,287', 'Low-Cost', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('1-Unit Ceiling', '\$1,249,125', 'High-Cost', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Conforming', '\$832,750', 'FHFA 2026', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('FHA Loan Limits Overview', badgeText: 'Effective Jan 1, 2026'),
                
                // Hero Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HUD Mortgagee Letter 2025-23'.toUpperCase(),
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 5),
                      Text('2026 limits rose to \$541,287 floor nationwide',
                          style: AppTextStyles.dmSans(
                              size: 16,
                              color: Colors.white,
                              weight: FontWeight.w800,
                              height: 1.25)),
                      const SizedBox(height: 6),
                      Text(
                          'FHA loan limits increased for the third year in a row, reflecting a 3.26% rise in national home prices. The floor applies to ~85% of U.S. counties; high-cost areas can borrow up to the ceiling.',
                          style: AppTextStyles.dmSans(
                              size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroBox('2026 Floor', '\$541,287', '↑ +3.26% YoY'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroBox('2026 Ceiling', '\$1,249,125', '↑ +\$39,375 YoY', isGold: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                _buildSectionHeader('Estimate Your County Limit'),

                // Lookup Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔍 FHA Limit Estimator',
                          style: AppTextStyles.dmSans(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Median Home Price', _medianPriceController, prefix: '\$'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<int>(
                              label: 'Property Units',
                              value: _selectedUnits,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1-Unit')),
                                DropdownMenuItem(value: 2, child: Text('2-Unit')),
                                DropdownMenuItem(value: 3, child: Text('3-Unit')),
                                DropdownMenuItem(value: 4, child: Text('4-Unit')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUnits = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDropdownField<String>(
                        label: 'Area Type',
                        value: _selectedAreaType,
                        items: const [
                          DropdownMenuItem(value: 'standard', child: Text('Standard County')),
                          DropdownMenuItem(value: 'highcost', child: Text('Designated High-Cost Area')),
                          DropdownMenuItem(value: 'special', child: Text('AK / HI / Guam / USVI (Special)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAreaType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '📋 Estimate FHA Limit',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Calculation Results Card
                if (_calculated) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated FHA Loan Limit'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white54,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 5),
                        Text(CurrencyFormatter.format(_estimatedLimit, symbol: '\$').split('.').first,
                            style: AppTextStyles.dmSans(
                                size: 30, color: Colors.white, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('For a $_selectedUnits-unit property based on ${CurrencyFormatter.format(double.tryParse(_medianPriceController.text) ?? 0, symbol: '\$').split('.').first} median price',
                            style: AppTextStyles.dmSans(size: 10, color: Colors.white60)),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _buildResultItemCard('115% of Median Price', _pct115),
                            _buildResultItemCard('Applicable Floor', _floor),
                            _buildResultItemCard('Applicable Ceiling', _ceiling, isGold: true),
                            _buildResultItemCardStr('Result Basis', _resultBasis),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _saveCalc,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🔖 Save This Estimate',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Year-over-Year Growth'),

                // Historical Bar Chart Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📈 FHA 1-Unit Floor: 2023–2026',
                          style: AppTextStyles.dmSans(
                              size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildChartBar('2023', '\$472,030', 0.64, [Colors.grey.shade400, Colors.grey.shade600]),
                      const SizedBox(height: 10),
                      _buildChartBar('2024', '\$498,257', 0.68, [const Color(0xFF1B3F72), const Color(0xFF0B1D3A)]),
                      const SizedBox(height: 10),
                      _buildChartBar('2025', '\$524,225', 0.71, [const Color(0xFF15803D), const Color(0xFF166534)]),
                      const SizedBox(height: 10),
                      _buildChartBar('2026 (Current)', '\$541,287', 0.74, [const Color(0xFFD97706), const Color(0xFFB45309)]),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('2026 Limits by Property Size'),

                // Limits Table
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏘️ Forward Mortgage Limits — All Unit Types',
                          style: AppTextStyles.dmSans(
                              size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderCol)),
                            ),
                            children: [
                              _buildTableHeaderCell('Units'),
                              _buildTableHeaderCell('Floor', alignRight: true),
                              _buildTableHeaderCell('Ceiling', alignRight: true),
                            ],
                          ),
                          _buildTableRow('1-Unit', '\$541,287', '\$1,249,125', textCol, isGold: true),
                          _buildTableRow('2-Unit', '\$693,050', '\$1,599,375', textCol),
                          _buildTableRow('3-Unit', '\$837,700', '\$1,933,200', textCol),
                          _buildTableRow('4-Unit', '\$1,041,125', '\$2,402,625', textCol),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Source: HUD Mortgagee Letter 2025-23, effective for case numbers assigned on/after Jan 1, 2026.',
                          style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('High-Cost Area Examples'),

                // High-Cost Examples List
                Column(
                  children: [
                    _buildExampleCard('🌉', 'San Francisco County, CA', 'At national ceiling · median price >\$1.2M', '\$1,249,125', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildExampleCard('🗽', 'New York County, NY', 'Manhattan · high-cost designation', '\$1,249,125', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildExampleCard('🌴', 'Los Angeles County, CA', 'High-cost · near ceiling', '\$1,159,825', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildExampleCard('🏔️', 'Denver County, CO', 'Moderate high-cost area', '\$632,500', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildExampleCard('🌽', 'Most Rural Counties (US Avg.)', 'Standard floor applies', '\$541,287', cardBg, textCol, mutedCol, borderCol),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? badgeText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: _theme.getMutedColor(context),
              letterSpacing: 1.0,
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF134E5E) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String value, String sub, bool isDark, {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: isDark ? Colors.white54 : _theme.getMutedColor(context),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white)),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : Colors.white60)),
      ],
    );
  }

  Widget _buildHeroBox(String label, String value, String change, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8, color: Colors.white70, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 16,
                  color: isGold ? const Color(0xFFFCD34D) : Colors.white,
                  weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(change,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: const Color(0xFF86EFAC), weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {required String prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: _theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: _theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              prefixText: '$prefix ',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: _theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w800,
                color: _theme.getTextColor(context),
              ),
              dropdownColor: _theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: _theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItemCard(String label, double value, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(CurrencyFormatter.format(value, symbol: '\$').split('.').first,
              style: AppTextStyles.dmSans(
                  size: 12.5,
                  color: isGold ? const Color(0xFFFCD34D) : Colors.white,
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildResultItemCardStr(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: Colors.white,
                  weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildChartBar(String year, String limit, double fillFactor, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(year, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: _theme.getTextColor(context))),
            Text(limit, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: _theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fillFactor,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  limit.substring(0, 4),
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String value, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        value.toUpperCase(),
        style: AppTextStyles.dmSans(
          size: 8.5,
          weight: FontWeight.w700,
          color: _theme.getMutedColor(context),
          letterSpacing: 0.3,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  TableRow _buildTableRow(String units, String floor, String ceiling, Color textColor, {bool isGold = false}) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Text(units, style: AppTextStyles.dmSans(size: 10.5, color: textColor, weight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Text(floor,
              style: AppTextStyles.dmSans(
                  size: 10.5,
                  color: isGold ? const Color(0xFF15803D) : textColor,
                  weight: FontWeight.w800),
              textAlign: TextAlign.right),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Text(ceiling, style: AppTextStyles.dmSans(size: 10.5, color: textColor, weight: FontWeight.w700), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildExampleCard(
    String emoji,
    String title,
    String sub,
    String limit,
    Color bg,
    Color textCol,
    Color mutedCol,
    Color borderCol,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
              ],
            ),
          ),
          Text(limit, style: AppTextStyles.dmSans(size: 13, color: const Color(0xFF15803D), weight: FontWeight.w800)),
        ],
      ),
    );
  }
}
