// lib/features/usa/screens/usa_usda_2025_income_limits_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAUsda2025IncomeLimitsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAUsda2025IncomeLimitsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAUsda2025IncomeLimitsScreen> createState() => _USAUsda2025IncomeLimitsScreenState();
}

class _USAUsda2025IncomeLimitsScreenState extends ConsumerState<USAUsda2025IncomeLimitsScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  // Controllers
  String _selectedState = '';
  String _selectedCountyType = 'standard'; // standard, high_cost
  int _selectedHhSize = 4;
  final _incomeController = TextEditingController(text: '85000');

  bool _showResult = false;
  double _limit = 140550.0;
  double _ratio = 60.5;
  double _room = 55550.0;
  bool _eligible = true;

  // Income Limits Data matching HTML
  static const _limitsData = {
    'standard': [103500.0, 112450.0, 126500.0, 140550.0, 151800.0, 163050.0, 174300.0, 185550.0],
    'high_cost': [135600.0, 154900.0, 174250.0, 193550.0, 208900.0, 224300.0, 239650.0, 255050.0]
  };

  final List<String> _states = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware',
    'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
    'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi',
    'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
    'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming'
  ];

  final List<String> _hhIcons = ['🧍', '👫', '👨‍👩‍👦', '👨‍👩‍Target', '👨‍👩‍👦‍👦', '👨‍👩‍👧‍👧', '👨‍👩‍👧‍👦', '👨‍👩‍👧‍👦'];


  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _incomeController.text = (inputs['income'] ?? 85000.0).toStringAsFixed(0);
      _selectedHhSize = (inputs['hhSize'] ?? 4.0).toInt();
      _selectedCountyType = (inputs['countyType'] ?? 0.0) == 0.0 ? 'standard' : 'high_cost';
      _calculate();
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (income <= 0) {
      errors['income'] = 'Enter positive annual income';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _showResult = false;
      });
      return;
    }

    final idx = (_selectedHhSize - 1).clamp(0, 7);
    final limit = _limitsData[_selectedCountyType]![idx];

    final eligible = income <= limit;
    final ratio = limit > 0 ? (income / limit * 100) : 0.0;
    final room = limit - income;

    setState(() {
      _calcSnapshot['income'] = income;
      _calcSnapshot['hhSize'] = _selectedHhSize;
      _calcSnapshot['countyType'] = _selectedCountyType;
      _calcSnapshot['state'] = _selectedState;

      _limit = limit;
      _ratio = ratio;
      _room = room;
      _eligible = eligible;
      _showResult = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _saveCalc() {
    if (!_showResult) return;

    final income = _calcSnapshot['income'] ?? 85000.0;
    final hhSize = _calcSnapshot['hhSize'] ?? 4;
    final countyType = _calcSnapshot['countyType'] ?? 'standard';

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'USDA 2025 Income Limits',
      label: 'USDA Income Limit: $hhSize Person (${_eligible ? "Eligible" : "Over limit"})',
      currencyCode: 'USD',
      inputs: {
        'income': income,
        'hhSize': hhSize.toDouble(),
        'countyType': countyType == 'standard' ? 0.0 : 1.0,
      },
      results: {
        'Limit': _limit,
        'Ratio': _ratio,
        'Eligible': _eligible ? 1.0 : 0.0,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Income limit lookup saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectHhSize(int size) {
    setState(() {
      _selectedHhSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _showResult && (
      (double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['income'] ?? 0.0) ||
      _selectedHhSize != (_calcSnapshot['hhSize'] ?? 4) ||
      _selectedCountyType != (_calcSnapshot['countyType'] ?? 'standard') ||
      _selectedState != (_calcSnapshot['state'] ?? '')
    );

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
                    colors: [Color(0xFF0B1D3A), Color(0xFF15803D), Color(0xFF78350F)],
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
                      Text('2025 Income Limits',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('USDA 502 Guaranteed · By County / Area',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
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
                  Expanded(child: _buildStripItem('1-Person', '\$103.5K', 'Standard', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('4-Person', '\$140.6K', 'Standard', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('8-Person', '\$185.6K', 'Standard', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Updated', 'Oct 2024', 'FY 2025', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Lookup Your Limit'),

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
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'State',
                              value: _selectedState.isEmpty ? null : _selectedState,
                              items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedState = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'County / Area',
                              value: _selectedCountyType,
                              items: const [
                                DropdownMenuItem(value: 'standard', child: Text('Standard County')),
                                DropdownMenuItem(value: 'high_cost', child: Text('High-Cost County')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCountyType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<int>(
                              label: 'Household Size',
                              value: _selectedHhSize,
                              items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} Person'))),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedHhSize = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Your Annual Income (\$)', _incomeController, errorText: _errors['income']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            '📋 Look Up My Income Limit',
                            style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Result Card
                if (!_showResult) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'View Income Limit Results',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your household size and county details, then tap "Look Up My Income Limit" to evaluate.',
                          style: AppTextStyles.dmSans(size: 10.5, color: mutedCol),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    key: _resultsKey,
                    child: Column(
                      children: [
                        if (isDirty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Inputs have changed. Tap "Look Up My Income Limit" to update results.',
                                    style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
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
                            Text('INCOME LIMIT FOR ${_calcSnapshot['hhSize'] ?? 4}-PERSON HOUSEHOLD',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(CurrencyFormatter.format(_limit, symbol: '\$').split('.').first,
                                style: AppTextStyles.playfair(size: 30, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${(_calcSnapshot['countyType'] ?? "standard") == "high_cost" ? "High-Cost" : "Standard"} County · 502 Guaranteed · FY 2025',
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _eligible ? const Color(0xFF15803D).withValues(alpha: 0.3) : const Color(0xFFB91C1C).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _eligible ? const Color(0xFF86EFAC).withValues(alpha: 0.3) : const Color(0xFFFCA5A5).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _eligible ? '✅ Eligible' : '❌ Over Limit',
                                    style: AppTextStyles.dmSans(size: 9.5, color: _eligible ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5), weight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCD34D).withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '${_ratio.toStringAsFixed(1)}% of limit',
                                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _saveCalc,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bookmark_border, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('All Household Sizes — Current Lookup'),

                // HH Size selector grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, idx) {
                    final isAct = _selectedHhSize == (idx + 1);
                    final val = _limitsData[_selectedCountyType]![idx];
                    return GestureDetector(
                      onTap: () => _selectHhSize(idx + 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isAct ? const Color(0xFFF0FDF4) : cardBg,
                          border: Border.all(color: isAct ? const Color(0xFF15803D) : borderCol, width: isAct ? 1.5 : 1.0),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_hhIcons[idx], style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 3),
                            Text('${idx + 1}${idx == 7 ? "+" : ""} Per',
                                style: AppTextStyles.dmSans(size: 8.5, color: isAct ? const Color(0xFF14532D) : mutedCol, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('\$${(val / 1000).round()}K',
                                style: AppTextStyles.playfair(size: 11, color: textCol, weight: FontWeight.w800)),
                            const SizedBox(height: 1),
                            Text('Guar.', style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFF15803D), weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Income vs. Limit Gauge'),

                // Custom Painter Gauge Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('🎯 Your Income vs. Limit', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 160,
                        height: 90,
                        child: CustomPaint(
                          painter: IncomeLimitNeedleGaugePainter(ratio: _ratio, isDark: isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_ratio.toStringAsFixed(1)}% of limit',
                        style: AppTextStyles.playfair(size: 14, color: _eligible ? const Color(0xFF15803D) : const Color(0xFFB91C1C), weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _eligible ? 'Within USDA income limit' : 'Exceeds USDA income limit',
                        style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Limit Analysis'),

                // Income Card Detail
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark ? [const Color(0xFF0F3A1D), const Color(0xFF0F3B3F)] : [const Color(0xFFF0FDF4), const Color(0xFFE0F2FE)],
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF15803D).withValues(alpha: 0.4) : const Color(0xFF86EFAC)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🌾 USDA 2025 Income Eligibility (502 Guaranteed)',
                          style: AppTextStyles.playfair(
                            size: 12,
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D),
                            weight: FontWeight.w800,
                          )),
                      const SizedBox(height: 10),
                      _buildIncomeRow('Your Household Income', '\$${(double.tryParse(_incomeController.text) ?? 0.0).toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')} / yr', isDark),
                      _buildIncomeRow('Income Limit for HH Size', '\$${_limit.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')} ($_selectedHhSize-person)', isDark),
                      _buildIncomeRow(
                        'Eligibility Status',
                        _eligible ? '✅ Within limit' : '❌ Exceeds limit',
                        isDark,
                        valColor: _eligible ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                      _buildIncomeRow('Income to Limit Ratio', '${_ratio.toStringAsFixed(1)}% – ${_eligible ? "Eligible" : "Over cap"}', isDark),
                      _buildIncomeRow(
                        _eligible ? 'Room Under Limit' : 'Amount OVER Limit',
                        '\$${_room.abs().toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                        isDark,
                        valColor: _eligible ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Full limits Table'),

                // Table
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF15803D)]),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('502 Guaranteed — Standard Areas', style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: isDark ? const Color(0xFF141C33) : const Color(0xFFF0F4FF),
                        child: Row(
                          children: [
                            Expanded(flex: 8, child: Text('HH Size', style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700))),
                            Expanded(flex: 6, child: Text('1–4', style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700), textAlign: TextAlign.center)),
                            Expanded(flex: 6, child: Text('5', style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700), textAlign: TextAlign.center)),
                            Expanded(flex: 6, child: Text('6', style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700), textAlign: TextAlign.center)),
                            Expanded(flex: 6, child: Text('8+', style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      _buildTableSummaryRow('Standard', '\$103.5K', '\$151.8K', '\$163.1K', '\$185.6K'),
                      _buildTableSummaryRow('High Cost', '\$135.6K', '\$208.9K', '\$224.3K', '\$255.1K'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Limits Progression'),

                // Progress bars
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
                      Text('📊 Income Limits by Household Size (2025)',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildProgressionRow('1 Person', 0.56, '\$103.5K', const Color(0xFF15803D), textCol, mutedCol),
                      _buildProgressionRow('2 Person', 0.61, '\$112.5K', const Color(0xFF15803D), textCol, mutedCol),
                      _buildProgressionRow('3 Person', 0.68, '\$126.5K', const Color(0xFF15803D), textCol, mutedCol),
                      _buildProgressionRow('4 Person', 0.76, '\$140.6K', const Color(0xFF15803D), textCol, mutedCol),
                      _buildProgressionRow('5 Person', 0.82, '\$151.8K', const Color(0xFF1B3F72), textCol, mutedCol),
                      _buildProgressionRow('6 Person', 0.88, '\$163.1K', const Color(0xFF1B3F72), textCol, mutedCol),
                      _buildProgressionRow('7 Person', 0.94, '\$174.3K', const Color(0xFF1B3F72), textCol, mutedCol),
                      _buildProgressionRow('8+ Person', 1.0, '\$185.6K', const Color(0xFF1B3F72), textCol, mutedCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Notable High-Cost Counties'),

                // High cost list
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        color: const Color(0xFF0B1D3A),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('High-Cost Area Limits (4-Person HH)', style: AppTextStyles.playfair(size: 11.5, color: Colors.white, weight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      _buildHighCostRow('San Diego Co., CA', 'High Cost · California', '\$193,550'),
                      _buildHighCostRow('King County, WA', 'High Cost · Washington', '\$193,550'),
                      _buildHighCostRow('Maui County, HI', 'High Cost · Hawaii', '\$193,550'),
                      _buildHighCostRow('Loudoun County, VA', 'High Cost · Virginia', '\$193,550'),
                      _buildHighCostRow('Douglas County, CO', 'High Cost · Colorado', '\$193,550'),
                      _buildHighCostRow('Travis County, TX', 'Standard · Texas (rural)', '\$140,550', isStd: true),
                      _buildHighCostRow('Shelby County, TN', 'Standard · Tennessee', '\$140,550', isStd: true),
                      _buildHighCostRow('Wake County, NC', 'Standard · North Carolina', '\$140,550', isStd: true),
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
        style: AppTextStyles.dmSans(
          size: 10,
          weight: FontWeight.w800,
          color: _theme.getMutedColor(context),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? errorText}) {
    const theme = _theme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: hasError ? Colors.red : theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
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
              ),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeRow(String key, String val, bool isDark, {Color? valColor}) {
    final kColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
    final vColor = valColor ?? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D));
    final bColor = isDark ? const Color(0xFF15803D).withValues(alpha: 0.3) : const Color(0xFFDCFCE7);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bColor, width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: kColor)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: vColor)),
        ],
      ),
    );
  }

  Widget _buildTableSummaryRow(String area, String v1, String v5, String v6, String v8) {
    final borderCol = _theme.getBorderColor(context);
    final textCol = _theme.getTextColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
      child: Row(
        children: [
          Expanded(flex: 8, child: Text(area, style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.w700))),
          Expanded(flex: 6, child: Container(padding: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)), child: Text(v1, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF14532D), weight: FontWeight.w700), textAlign: TextAlign.center))),
          Expanded(flex: 6, child: Text(v5, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600), textAlign: TextAlign.center)),
          Expanded(flex: 6, child: Text(v6, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600), textAlign: TextAlign.center)),
          Expanded(flex: 6, child: Text(v8, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildProgressionRow(String label, double pct, String val, Color color, Color textCol, Color mutedCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600)),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: textCol.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(val,
                style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w800),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildHighCostRow(String county, String desc, String limitStr, {bool isStd = false}) {
    final borderCol = _theme.getBorderColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(county, style: AppTextStyles.dmSans(size: 11.5, color: textCol, weight: FontWeight.w800)),
              Text(desc, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(limitStr,
                  style: AppTextStyles.playfair(
                      size: 12.5, color: isStd ? const Color(0xFF15803D) : const Color(0xFFD97706), weight: FontWeight.w800)),
              Text('4-person limit', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a needle gauge for Income limits
class IncomeLimitNeedleGaugePainter extends CustomPainter {
  final double ratio;
  final bool isDark;

  IncomeLimitNeedleGaugePainter({required this.ratio, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height);
    const double strokeWidth = 14;

    // Draw scale bands: Green, Orange, Red
    // Total arc is 180 degrees (from 180 to 360 deg)
    // 0% to 80% limit -> Green (0 to 96 deg)
    // 80% to 100% limit -> Orange (96 to 120 deg)
    // 100% to 150%+ limit -> Red (120 to 180 deg)
    final Paint p1 = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint p2 = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint p3 = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    canvas.drawArc(rect, pi, pi * 0.53, false, p1); // up to ~80%
    canvas.drawArc(rect, pi + (pi * 0.53), pi * 0.14, false, p2); // ~80% to 100%
    canvas.drawArc(rect, pi + (pi * 0.67), pi * 0.33, false, p3); // ~100% to 150%

    // Draw center hub
    final Paint hubPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0B1D3A)
      ..style = PaintingStyle.fill;
    final Paint hubBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw needle
    // Map ratio to angle. Angle starts from -180 deg (Left) to 0 deg (Right).
    // ratio = 0% -> -pi rad
    // ratio = 100% -> -pi * 0.33 rad
    // ratio = 150% -> 0 rad
    final double pct = ratio.clamp(0, 150);
    final double needleAngle = pi + (pct / 150.0) * pi;

    final Paint needlePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0B1D3A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double needleLength = radius - 18;
    final Offset needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 9, hubPaint);
    canvas.drawCircle(center, 9, hubBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
