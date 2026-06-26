// lib/features/usa/screens/usa_va_entitlement_limits_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAVaEntitlementLimitsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAVaEntitlementLimitsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAVaEntitlementLimitsScreen> createState() => _USAVaEntitlementLimitsScreenState();
}

class _USAVaEntitlementLimitsScreenState extends ConsumerState<USAVaEntitlementLimitsScreen> {
  static const _theme = CountryThemes.usa;

  // Inputs
  String _selectedEntStatus = 'full'; // full, partial
  final _homePriceController = TextEditingController(text: '500000');
  String _selectedCountyType = 'standard'; // standard, highcost, special
  final _entUsedController = TextEditingController(text: '50000');

  // Outputs
  bool _calculated = false;
  double _zeroDownCeiling = 0.0;
  bool _isNoLimit = true;
  String _resultSub = 'Borrowing power depends on income & lender approval, not a VA cap';
  double _maxGuaranty = 208188.0;
  String _bonusEntText = '25% — no ceiling';
  double _downIfNeeded = 0.0;
  double _usedPct = 0.0;

  static const Map<String, double> _countyLimits = {
    'standard': 832750.0,
    'highcost': 1249125.0,
    'special': 1249125.0,
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _selectedEntStatus = (inputs['entStatus'] ?? 0.0) == 0.0 ? 'full' : 'partial';
      _homePriceController.text = (inputs['homePrice'] ?? 500000.0).toStringAsFixed(0);
      final countyIdx = (inputs['countyType'] ?? 0.0).toInt();
      _selectedCountyType = countyIdx == 0 ? 'standard' : (countyIdx == 1 ? 'highcost' : 'special');
      _entUsedController.text = (inputs['entUsed'] ?? 50000.0).toStringAsFixed(0);
      _calculate();
    } else {
      _calculate();
    }
  }

  @override
  void dispose() {
    _homePriceController.dispose();
    _entUsedController.dispose();
    super.dispose();
  }

  void _calculate() {
    final price = double.tryParse(_homePriceController.text) ?? 0.0;
    final limit = _countyLimits[_selectedCountyType] ?? 832750.0;
    final maxGuar = limit * 0.25;

    if (_selectedEntStatus == 'full') {
      setState(() {
        _isNoLimit = true;
        _zeroDownCeiling = 0.0;
        _resultSub = 'Borrowing power depends on income & lender approval, not a VA cap';
        _maxGuaranty = maxGuar;
        _bonusEntText = '25% — no ceiling';
        _downIfNeeded = 0.0;
        _usedPct = 0.0;
        _calculated = true;
      });
    } else {
      final used = double.tryParse(_entUsedController.text) ?? 0.0;
      final remainingGuar = (maxGuar - used).clamp(0.0, maxGuar);
      final zeroDownMax = remainingGuar * 4.0;
      final downNeeded = (price - zeroDownMax).clamp(0.0, price);

      setState(() {
        _isNoLimit = false;
        _zeroDownCeiling = zeroDownMax;
        _resultSub = downNeeded > 0
            ? 'Home price exceeds ceiling — est. down payment needed: ${CurrencyFormatter.format(downNeeded, symbol: '\$').split('.').first}'
            : 'Your remaining entitlement fully covers this home price with \$0 down';
        _maxGuaranty = maxGuar;
        _bonusEntText = 'Remaining: ${CurrencyFormatter.format(remainingGuar, symbol: '\$').split('.').first}';
        _downIfNeeded = downNeeded;
        _usedPct = maxGuar > 0 ? (used / maxGuar).clamp(0.0, 1.0) : 0.0;
        _calculated = true;
      });
    }
  }

  void _saveCalc() {
    if (!_calculated) return;

    final price = double.tryParse(_homePriceController.text) ?? 0.0;
    final used = double.tryParse(_entUsedController.text) ?? 0.0;
    final statusIdx = _selectedEntStatus == 'full' ? 0.0 : 1.0;
    final countyIdx = _selectedCountyType == 'standard' ? 0.0 : (_selectedCountyType == 'highcost' ? 1.0 : 2.0);

    final statusLabel = _selectedEntStatus == 'full' ? 'Full' : 'Partial';
    final ceilingStr = _isNoLimit ? 'No Limit' : CurrencyFormatter.compact(_zeroDownCeiling, symbol: '\$');

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'VA Entitlement & Limits',
      label: 'VA Entitlement: $statusLabel · Ceiling: $ceilingStr',
      currencyCode: 'USD',
      inputs: {
        'entStatus': statusIdx,
        'homePrice': price,
        'countyType': countyIdx,
        'entUsed': used,
      },
      results: {
        'ZeroDownCeiling': _zeroDownCeiling,
        'DownNeeded': _downIfNeeded,
        'MaxGuaranty': _maxGuaranty,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Entitlement scenario saved!'),
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

    final used = double.tryParse(_entUsedController.text) ?? 0.0;

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar
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
                    colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF4C1D95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏠', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Entitlement & Loan Limits',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('2026 county limits · Full vs. partial',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Summary Strip
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
                  Expanded(child: _buildStripItem('Baseline 2026', '\$832,750', 'Most Counties', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('High-Cost Cap', '\$1.25M', '~155 Counties', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Full Entitlement', 'No Limit', 'Since 2020', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Note strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📌 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF92400E), height: 1.4),
                            children: const [
                              TextSpan(text: 'Since the Blue Water Navy Vietnam Veterans Act of 2019, veterans with '),
                              TextSpan(text: 'full entitlement', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' face no VA loan limit at all — county limits only apply if you have '),
                              TextSpan(text: 'partial', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' entitlement.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Your Entitlement Scenario'),

                // Input Card
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
                      _buildDropdownField<String>(
                        label: 'Entitlement Status',
                        value: _selectedEntStatus,
                        items: const [
                          DropdownMenuItem(value: 'full', child: Text('Full Entitlement (1st use / restored)')),
                          DropdownMenuItem(value: 'partial', child: Text('Partial Entitlement (active prior loan)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedEntStatus = val);
                            _calculate();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Home Price (\$)', _homePriceController),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'County Type',
                              value: _selectedCountyType,
                              items: const [
                                DropdownMenuItem(value: 'standard', child: Text('Standard (\$832,750)')),
                                DropdownMenuItem(value: 'highcost', child: Text('High-Cost (up to \$1.25M)')),
                                DropdownMenuItem(value: 'special', child: Text('AK / HI / Territories')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCountyType = val);
                                  _calculate();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_selectedEntStatus == 'partial') ...[
                        const SizedBox(height: 12),
                        _buildInputField('Entitlement Already Used (\$)', _entUsedController, hint: 'From your COE — "Entitlement Charged" line'),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Result Hero Card
                if (_calculated) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESTIMATED \$0-DOWN PURCHASE CEILING',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(
                              _isNoLimit ? 'No Limit' : CurrencyFormatter.format(_zeroDownCeiling, symbol: '\$').split('.').first,
                              style: AppTextStyles.playfair(size: 32, color: Colors.white, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(_isNoLimit ? 'full entitlement' : 'remaining entitlement ceiling',
                                style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            Text(_resultSub,
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _saveCalc,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark_border, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Save', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Entitlement Usage Breakdown'),

                // Horizontal stack bar chart card
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
                      Text('📊 Entitlement Usage Breakdown',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 22,
                          color: const Color(0xFFEEF2F8),
                          child: CustomPaint(
                            size: const Size(double.infinity, 22),
                            painter: EntitlementUsagePainter(ratio: _usedPct, isDark: isDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLegendDot(const Color(0xFFB91C1C), 'Used: \$${CurrencyFormatter.format(used, symbol: "").split(".").first}', mutedCol),
                          _buildLegendDot(const Color(0xFF1B3F72), _isNoLimit ? 'Remaining: Full' : 'Available remaining', mutedCol),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Breakdown Grid cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                  children: [
                    _buildBreakdownCard('🛡️', 'Basic Entitlement', '\$36,000', 'Standard VA guaranty base', textCol, mutedCol),
                    _buildBreakdownCard('⭐', 'Bonus Entitlement', _bonusEntText, 'Covers above \$144K loans', textCol, mutedCol),
                    _buildBreakdownCard('📐', 'Max VA Guaranty', CurrencyFormatter.format(_maxGuaranty, symbol: '\$').split('.').first, '25% of county limit', textCol, mutedCol),
                    _buildBreakdownCard('💰', 'Down Pmt If Needed', CurrencyFormatter.format(_downIfNeeded, symbol: '\$').split('.').first, 'On amount above ceiling', textCol, mutedCol, isWarning: _downIfNeeded > 0),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('2026 County Loan Limits'),

                // Limits description card
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
                      Text('🗺️ Conforming Loan Limits by Area Type',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildLimitRow('Standard Counties (~95% of U.S.)', '\$832,750', textCol),
                      _buildLimitRow('High-Cost Counties (e.g. SF, DC, Honolulu)', 'up to \$1,249,125', textCol),
                      _buildLimitRow('Alaska, Hawaii, Guam, USVI', '\$1,249,125+', textCol),
                      _buildLimitRow('2-Unit Property Baseline', '\$1,066,250', textCol),
                      _buildLimitRow('2025 → 2026 Baseline Change', '+3.3% (\$806,500 → \$832,750)', textCol, isGreen: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Entitlement Rules That Matter'),

                // Rules card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCompareRow('Full Entitlement', '✅ No VA loan limit', textCol),
                      _buildCompareRow('Partial Entitlement', '⚡ County limit applies', textCol, isGold: true),
                      _buildCompareRow('Restore After Sale', '✅ Pay loan in full → restore', textCol),
                      _buildCompareRow('One-Time Restoration', '✅ Keep home, restore once', textCol),
                      _buildCompareRow('Multiple VA Loans', '⚡ Possible with remaining entitlement', textCol, isGold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer helper note strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3F72).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1B3F72).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Loan limits aren\'t a cap on what you can borrow — they only define how much the VA guarantees without a down payment. With full entitlement, the real ceiling is what a lender approves based on your income, credit, and DTI.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF1B3F72), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
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
                color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.playfair(
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.sectionLabel(_theme.getMutedColor(context)),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint}) {
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => _calculate(),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context).withValues(alpha: 0.4)),
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
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ).copyWith(fontFamily: 'Georgia'),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text, Color labelColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.dmSans(size: 9, color: labelColor)),
      ],
    );
  }

  Widget _buildBreakdownCard(String emoji, String label, String value, String sub, Color textCol, Color mutedCol, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: _theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15.5, color: isWarning ? const Color(0xFFB91C1C) : textCol, weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String key, String val, Color textCol, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context), width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: textCol)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: isGreen ? const Color(0xFF15803D) : textCol)),
        ],
      ),
    );
  }

  Widget _buildCompareRow(String label, String value, Color textCol, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700).copyWith(fontFamily: 'Georgia')),
          Text(value, style: AppTextStyles.dmSans(size: 10.5, color: isGold ? const Color(0xFFD97706) : const Color(0xFF15803D), weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// Painter for horizontal entitlement bar
class EntitlementUsagePainter extends CustomPainter {
  final double ratio; // 0.0 to 1.0 (used amount)
  final bool isDark;

  EntitlementUsagePainter({required this.ratio, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(5),
    );

    // If ratio is 0.0 (full entitlement), draw whole bar in navy blue/purple gradient
    if (ratio <= 0.0) {
      final Paint remainPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF4C1D95)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRRect(rect, remainPaint);

      // Draw centered text
      _drawText(canvas, 'Guaranty fully available', size.width / 2, size.height / 2, Colors.white);
      return;
    }

    // Otherwise, draw partial segments
    final double usedWidth = size.width * ratio;
    final double remainWidth = size.width - usedWidth;

    // Draw used segment (Red)
    if (usedWidth > 0) {
      final Paint usedPaint = Paint()..color = const Color(0xFFB91C1C);
      final RRect usedRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, usedWidth, size.height),
        topLeft: const Radius.circular(5),
        bottomLeft: const Radius.circular(5),
        topRight: remainWidth <= 0 ? const Radius.circular(5) : Radius.zero,
        bottomRight: remainWidth <= 0 ? const Radius.circular(5) : Radius.zero,
      );
      canvas.drawRRect(usedRect, usedPaint);
    }

    // Draw remain segment (Blue)
    if (remainWidth > 0) {
      final Paint remainPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1B3F72), Color(0xFF4C1D95)],
        ).createShader(Rect.fromLTWH(usedWidth, 0, remainWidth, size.height));

      final RRect remainRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(usedWidth, 0, remainWidth, size.height),
        topRight: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
        topLeft: usedWidth <= 0 ? const Radius.circular(5) : Radius.zero,
        bottomLeft: usedWidth <= 0 ? const Radius.circular(5) : Radius.zero,
      );
      canvas.drawRRect(remainRect, remainPaint);
    }

    // Draw text values
    if (ratio > 0.15) {
      _drawText(canvas, '${(ratio * 100).round()}% Used', usedWidth / 2, size.height / 2, Colors.white);
    }
    if ((1.0 - ratio) > 0.25) {
      _drawText(canvas, 'Available', usedWidth + remainWidth / 2, size.height / 2, Colors.white);
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'DM Sans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
