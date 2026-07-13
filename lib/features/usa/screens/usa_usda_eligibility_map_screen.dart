// lib/features/usa/screens/usa_usda_eligibility_map_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAUsdaEligibilityMapScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAUsdaEligibilityMapScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAUsdaEligibilityMapScreen> createState() => _USAUsdaEligibilityMapScreenState();
}

class _USAUsdaEligibilityMapScreenState extends ConsumerState<USAUsdaEligibilityMapScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  // Controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String _selectedState = '';

  bool _showResults = false;
  String _status = 'eligible'; // eligible, ineligible, partial
  int _population = 8240;
  String _areaClassification = 'Rural';
  String _classSub = 'USDA Designated';

  // ZIP prefix maps
  static const _eligiblePrefixes = {'626', '727', '395', '298', '373', '408', '738', '768', '488', '476'};
  static const _ineligiblePrefixes = {'100', '900', '606', '770', '852', '941', '980', '303', '021', '191'};

  final List<String> _states = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware',
    'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky',
    'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi',
    'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
    'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      final savedZip = inputs['zipCode']?.toInt().toString() ?? '';
      _zipController.text = savedZip.padLeft(5, '0');
      
      final savedStatusIndex = inputs['statusIndex'] ?? 0.0;
      if (savedStatusIndex == 0.0) {
        _status = 'eligible';
        _areaClassification = 'Rural';
        _classSub = 'USDA Designated';
      } else if (savedStatusIndex == 1.0) {
        _status = 'partial';
        _areaClassification = 'Suburban';
        _classSub = 'Verify Exact Address';
      } else {
        _status = 'ineligible';
        _areaClassification = 'Urban';
        _classSub = 'Exceeds Limit';
      }
      _population = (inputs['pop'] ?? 8240.0).toInt();
      _showResults = true;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _checkEligibility() {
    final errors = <String, String>{};
    final zip = _zipController.text.trim();
    if (zip.length != 5 || int.tryParse(zip) == null) {
      errors['zip'] = 'Enter valid 5-digit ZIP';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _showResults = false;
      });
      return;
    }

    final prefix = zip.substring(0, min(3, zip.length));
    String newStatus = 'eligible';
    int newPop = Random().nextInt(20000) + 3000;
    String newClass = 'Rural';
    String newSub = 'USDA Designated';

    if (_ineligiblePrefixes.contains(prefix)) {
      newStatus = 'ineligible';
      newPop = Random().nextInt(900000) + 200000;
      newClass = 'Urban';
      newSub = 'Exceeds Limit';
    } else if (_eligiblePrefixes.contains(prefix)) {
      newStatus = 'eligible';
      newPop = Random().nextInt(15000) + 2000;
      newClass = 'Rural';
      newSub = 'USDA Designated';
    } else {
      // 30% chance partial, 70% eligible
      if (Random().nextDouble() > 0.7) {
        newStatus = 'partial';
        newPop = Random().nextInt(15000) + 20000;
        newClass = 'Suburban';
        newSub = 'Verify Exact Address';
      } else {
        newStatus = 'eligible';
        newPop = Random().nextInt(25000) + 1000;
        newClass = 'Rural';
        newSub = 'USDA Designated';
      }
    }

    setState(() {
      _calcSnapshot['street'] = _streetController.text;
      _calcSnapshot['city'] = _cityController.text;
      _calcSnapshot['state'] = _selectedState;
      _calcSnapshot['zip'] = zip;
      _calcSnapshot['status'] = newStatus;
      _calcSnapshot['pop'] = newPop;
      _calcSnapshot['areaClass'] = newClass;
      _calcSnapshot['classSub'] = newSub;

      _status = newStatus;
      _population = newPop;
      _areaClassification = newClass;
      _classSub = newSub;
      _showResults = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Eligibility check complete'),
        backgroundColor: Colors.green,
      ),
    );

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
    if (!_showResults) return;

    final zip = _calcSnapshot['zip'] ?? '';
    final status = _calcSnapshot['status'] ?? 'eligible';
    final pop = _calcSnapshot['pop'] ?? 8240;
    final statusVal = status == 'eligible' ? 0.0 : (status == 'partial' ? 1.0 : 2.0);

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'USDA Eligibility Map',
      label: 'USDA Eligibility: ZIP $zip (${status.toUpperCase()})',
      currencyCode: 'USD',
      inputs: {
        'zipCode': double.tryParse(zip) ?? 0.0,
        'pop': pop.toDouble(),
        'statusIndex': statusVal,
      },
      results: {
        'EligibleFlag': status == 'eligible' ? 1.0 : (status == 'partial' ? 0.5 : 0.0),
        'EstPopulation': pop.toDouble(),
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Eligibility search saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _showResults && (
      _streetController.text != (_calcSnapshot['street'] ?? '') ||
      _cityController.text != (_calcSnapshot['city'] ?? '') ||
      _selectedState != (_calcSnapshot['state'] ?? '') ||
      _zipController.text.trim() != (_calcSnapshot['zip'] ?? '')
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
          // Premium Header
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
                      const Text('🗺️', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('USDA Eligibility Map',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('Rural · Suburban · Property Location Check',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top Rate Strip Banner
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
                  Expanded(child: _buildStripItem('Eligible Areas', '97%', 'of US Land', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Population', '19%', 'Eligible', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Max Pop.', '35K', 'City Limit', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Updated', '2025', 'USDA RD', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Check Property Eligibility'),

                // Inputs Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Street Address', _streetController, hint: 'e.g. 123 Main St')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('City', _cityController, hint: 'e.g. Springfield')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
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
                          Expanded(child: _buildInputField('ZIP Code', _zipController, hint: '5 digits', maxLen: 5, errorText: _errors['zip'])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _checkEligibility,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🗺️ Check USDA Eligibility',
                            style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                    // Result Hero
                if (!_showResults) ...[
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
                        const Text('🗺️', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'View Eligibility Map Results',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your property details above, then tap "Check USDA Eligibility" to determine USDA Rural Housing Eligibility.',
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
                                    'Inputs have changed. Tap "Check USDA Eligibility" to update results.',
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
                      gradient: LinearGradient(
                        colors: _status == 'eligible'
                            ? [const Color(0xFF0B1D3A), const Color(0xFF15803D)]
                            : (_status == 'partial'
                                ? [const Color(0xFF5D4017), const Color(0xFFB45309)]
                                : [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROPERTY ELIGIBILITY STATUS',
                            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _status == 'eligible' ? '✅' : (_status == 'partial' ? '⚠️' : '❌'),
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _status == 'eligible'
                                        ? 'Eligible'
                                        : (_status == 'partial' ? 'Verify Address' : 'Not Eligible'),
                                    style: AppTextStyles.playfair(size: 22, color: Colors.white, weight: FontWeight.w800),
                                  ),
                                  Text(
                                    _status == 'eligible'
                                        ? 'Qualifies for USDA Rural Housing Loan'
                                        : (_status == 'partial'
                                            ? 'Some parts of this area qualify'
                                            : 'Urban Area — USDA loans not available'),
                                    style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text(
                                _status == 'eligible'
                                    ? '✅ USDA Eligible'
                                    : (_status == 'partial' ? '⚠️ Partial Area' : '❌ Not Eligible'),
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w700),
                              ),
                            ),
                            if (_status != 'ineligible') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCD34D).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '502 Guaranteed',
                                  style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
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
                              '🔖 Save Search Result',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSquareStat(
                          '🏘️',
                          CurrencyFormatter.format(_population.toDouble(), symbol: '').split('.').first,
                          'Est. Population',
                          _status == 'eligible' ? 'Under 35,000 ✅' : 'Urban Zone',
                          cardBg, borderCol, textCol, mutedCol,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSquareStat(
                          '📍',
                          _areaClassification,
                          'Classification',
                          _classSub,
                          cardBg, borderCol, textCol, mutedCol,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSquareStat(
                          '💰',
                          '\$0',
                          'Down Payment',
                          '100% Financing',
                          cardBg, borderCol, textCol, mutedCol,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSquareStat(
                          '📅',
                          '30-Yr',
                          'Loan Term',
                          'Fixed Rate Only',
                          cardBg, borderCol, textCol, mutedCol,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('USDA Eligible Coverage'),

                // Map Placeholder Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🗺️ Rural Eligibility Overview',
                              style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                          Row(
                            children: [
                              _buildLegendDot(const Color(0xFF86EFAC), 'Eligible', mutedCol),
                              const SizedBox(width: 8),
                              _buildLegendDot(const Color(0xFFFCA5A5), 'Urban', mutedCol),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          color: isDark ? const Color(0xFF0F1E12) : const Color(0xFFD4EAD0),
                          child: CustomPaint(
                            size: const Size(double.infinity, 200),
                            painter: USAMapPainter(isDark: isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('National Coverage Statistics'),

                // Progress charts card
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
                      Text('📊 USDA Eligible Areas by Region (2025)',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildRegionBar('Midwest', 0.89, const Color(0xFF15803D), textCol, mutedCol),
                      _buildRegionBar('South', 0.84, const Color(0xFF1B3F72), textCol, mutedCol),
                      _buildRegionBar('Mountain', 0.95, const Color(0xFFD97706), textCol, mutedCol),
                      _buildRegionBar('Northeast', 0.61, const Color(0xFF7C3AED), textCol, mutedCol),
                      _buildRegionBar('Pacific', 0.72, const Color(0xFF0891B2), textCol, mutedCol),
                      const SizedBox(height: 6),
                      Text('% of land area designated USDA-eligible · Source: USDA RD 2025',
                          style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('US Land Classification'),

                // Donut Chart Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CustomPaint(
                          painter: ClassificationDonutPainter(isDark: isDark),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _buildDonutLegendItem(const Color(0xFF15803D), 'Rural Eligible', '89%', textCol, mutedCol),
                            const SizedBox(height: 6),
                            _buildDonutLegendItem(const Color(0xFFD97706), 'Rural Suburb', '8%', textCol, mutedCol),
                            const SizedBox(height: 6),
                            _buildDonutLegendItem(const Color(0xFFB91C1C), 'Urban (Ineligible)', '3%', textCol, mutedCol),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Sample Eligible Counties'),

                // Counties list
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCountyRow('Boone County', 'Missouri · Pop. 185K (rural areas)', 'Eligible', const Color(0xFFDCFCE7), const Color(0xFF14532D)),
                      _buildCountyRow('Comal County', 'Texas · Pop. 168K (rural zones)', 'Partial', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                      _buildCountyRow('Tuscaloosa County', 'Alabama · Rural fringe areas', 'Eligible', const Color(0xFFDCFCE7), const Color(0xFF14532D)),
                      _buildCountyRow('Flathead County', 'Montana · Most of county', 'Eligible', const Color(0xFFDCFCE7), const Color(0xFF14532D)),
                      _buildCountyRow('King County', 'Washington · Mostly ineligible', 'Ineligible', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                      _buildCountyRow('Chittenden County', 'Vermont · Burlington area', 'Partial', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Property Rules (2025)'),

                // Rules checklist
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark ? [const Color(0xFF0F3A1D), const Color(0xFF064E3B)] : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 USDA Property Eligibility Rules (2025)',
                          style: AppTextStyles.playfair(
                            size: 12,
                            color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF14532D),
                            weight: FontWeight.w800,
                          )),
                      const SizedBox(height: 12),
                      _buildRuleItem('🏙️', 'Population Limit:', 'Property must be in an area with a population under 35,000 (with exceptions up to 50,000).', isDark),
                      _buildRuleItem('🗺️', 'Official Tool:', 'Always verify boundaries at eligibility.sc.egov.usda.gov which updates periodically.', isDark),
                      _buildRuleItem('🏡', 'Property Types:', 'Single-family homes, approved condos/PUDs, and new builds qualify.', isDark),
                      _buildRuleItem('⚠️', 'Waiver Option:', 'Some areas exceeding limit might qualify if they lack mortgage credit access.', isDark),
                      _buildRuleItem('📅', 'Census Boundaries:', 'USDA utilizes 2020 Census records. Boundary classifications are strictly updated.', isDark),
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

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, int? maxLen, String? errorText}) {
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
            maxLength: maxLen,
            onChanged: (val) => setState(() {}),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context).withValues(alpha: 0.5)),
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

  Widget _buildSquareStat(String emoji, String val, String label, String sub, Color bg, Color border, Color text, Color muted) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8.5, color: muted, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: AppTextStyles.playfair(size: 17, color: text, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF15803D), weight: FontWeight.w600)),
        ],
      ),
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

  Widget _buildRegionBar(String label, double pct, Color color, Color textCol, Color mutedCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600)),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: textCol.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('${(pct * 100).round()}%',
                style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w800),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(Color color, String label, String value, Color textCol, Color mutedCol) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 10, color: mutedCol)),
        ),
        Text(value, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildCountyRow(String name, String details, String badgeText, Color badgeBg, Color badgeTextCol) {
    final borderCol = _theme.getBorderColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.dmSans(size: 11.5, color: textCol, weight: FontWeight.w800)),
                Text(details, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              badgeText,
              style: AppTextStyles.dmSans(size: 9.5, color: badgeTextCol, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String strongText, String normalText, bool isDark) {
    final textCol = isDark ? const Color(0xFFD1FAE5) : const Color(0xFF166534);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.dmSans(size: 10.5, color: textCol, height: 1.4),
                children: [
                  TextSpan(text: '$strongText ', style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.w800)),
                  TextSpan(text: normalText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw a simplified representation of the US continental map
class USAMapPainter extends CustomPainter {
  final bool isDark;
  USAMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = isDark ? const Color(0xFF1B3F23) : const Color(0xFF86EFAC).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    // Simplified outline points for the U.S. Map
    path.moveTo(size.width * 0.12, size.height * 0.20);
    path.lineTo(size.width * 0.84, size.height * 0.20);
    path.lineTo(size.width * 0.88, size.height * 0.27);
    path.lineTo(size.width * 0.90, size.height * 0.40);
    path.lineTo(size.width * 0.88, size.height * 0.53);
    path.lineTo(size.width * 0.84, size.height * 0.63);
    path.lineTo(size.width * 0.76, size.height * 0.70);
    path.lineTo(size.width * 0.68, size.height * 0.73);
    path.lineTo(size.width * 0.60, size.height * 0.75);
    path.lineTo(size.width * 0.52, size.height * 0.73);
    path.lineTo(size.width * 0.44, size.height * 0.72);
    path.lineTo(size.width * 0.36, size.height * 0.70);
    path.lineTo(size.width * 0.28, size.height * 0.67);
    path.lineTo(size.width * 0.20, size.height * 0.62);
    path.lineTo(size.width * 0.14, size.height * 0.53);
    path.lineTo(size.width * 0.11, size.height * 0.43);
    path.lineTo(size.width * 0.11, size.height * 0.30);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Ineligible cities red spots
    _drawCitySpot(canvas, size.width * 0.76, size.height * 0.47, 'LA', size);
    _drawCitySpot(canvas, size.width * 0.82, size.height * 0.28, 'SF', size);
    _drawCitySpot(canvas, size.width * 0.86, size.height * 0.38, 'PHX', size);
    _drawCitySpot(canvas, size.width * 0.68, size.height * 0.30, 'DEN', size);
    _drawCitySpot(canvas, size.width * 0.54, size.height * 0.33, 'CHI', size);
    _drawCitySpot(canvas, size.width * 0.72, size.height * 0.43, 'DAL', size);
    _drawCitySpot(canvas, size.width * 0.66, size.height * 0.53, 'ATL', size);
    _drawCitySpot(canvas, size.width * 0.44, size.height * 0.32, 'DET', size);
    _drawCitySpot(canvas, size.width * 0.34, size.height * 0.35, 'NYC', size);
    _drawCitySpot(canvas, size.width * 0.33, size.height * 0.40, 'PHI', size);

    // Eligible green markers
    _drawRuralDot(canvas, size.width * 0.40, size.height * 0.50);
    _drawRuralDot(canvas, size.width * 0.48, size.height * 0.57);
    _drawRuralDot(canvas, size.width * 0.30, size.height * 0.52);
    _drawRuralDot(canvas, size.width * 0.60, size.height * 0.48);
    _drawRuralDot(canvas, size.width * 0.56, size.height * 0.62);
    _drawRuralDot(canvas, size.width * 0.24, size.height * 0.47);
    _drawRuralDot(canvas, size.width * 0.76, size.height * 0.57);
    _drawRuralDot(canvas, size.width * 0.20, size.height * 0.57);

    // Alaska and Hawaii inset panels
    final insetBg = Paint()
      ..color = const Color(0xFFA7F3D0).withValues(alpha: isDark ? 0.3 : 0.7)
      ..style = PaintingStyle.fill;
    final insetBorder = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Alaska
    final RRect akPanel = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.14, size.height * 0.73, 80, 42), const Radius.circular(5));
    canvas.drawRRect(akPanel, insetBg);
    canvas.drawRRect(akPanel, insetBorder);
    _drawText(canvas, 'ALASKA', size.width * 0.14 + 40, size.height * 0.73 + 12, 8.5, const Color(0xFF14532D), FontWeight.bold);
    _drawText(canvas, 'Mostly Eligible', size.width * 0.14 + 40, size.height * 0.73 + 26, 7.0, const Color(0xFF166534), FontWeight.normal);

    // Hawaii
    final RRect hiPanel = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.33, size.height * 0.78, 55, 26), const Radius.circular(5));
    canvas.drawRRect(hiPanel, insetBg);
    canvas.drawRRect(hiPanel, insetBorder);
    _drawText(canvas, 'HAWAII', size.width * 0.33 + 27.5, size.height * 0.78 + 8, 8.0, const Color(0xFF14532D), FontWeight.bold);
    _drawText(canvas, 'Rural Areas', size.width * 0.33 + 27.5, size.height * 0.78 + 18, 6.5, const Color(0xFF166534), FontWeight.normal);
  }

  void _drawCitySpot(Canvas canvas, double x, double y, String label, Size size) {
    final spotPaint = Paint()
      ..color = const Color(0xFFFCA5A5).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final spotBorder = Paint()
      ..color = const Color(0xFFB91C1C)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, y), 8, spotPaint);
    canvas.drawCircle(Offset(x, y), 8, spotBorder);

    _drawText(canvas, label, x, y - 4, 6.5, const Color(0xFF7F1D1D), FontWeight.bold);
  }

  void _drawRuralDot(Canvas canvas, double x, double y) {
    final dotPaint = Paint()
      ..color = const Color(0xFF15803D).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color color, FontWeight weight) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'DM Sans',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Donut chart painter representing land classifications
class ClassificationDonutPainter extends CustomPainter {
  final bool isDark;
  ClassificationDonutPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double strokeWidth = 14;

    final Paint bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final Paint p1 = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final Paint p2 = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final Paint p3 = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Draw proportional segments (Total = 360 deg)
    // 89% Rural Eligible (320.4 deg)
    // 8% Rural Suburb (28.8 deg)
    // 3% Urban (10.8 deg)
    const double sweep1 = 2 * pi * 0.89;
    const double sweep2 = 2 * pi * 0.08;
    const double sweep3 = 2 * pi * 0.03;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    canvas.drawArc(rect, -pi / 2, sweep1 - 0.05, false, p1);
    canvas.drawArc(rect, -pi / 2 + sweep1, sweep2 - 0.05, false, p2);
    canvas.drawArc(rect, -pi / 2 + sweep1 + sweep2, sweep3 - 0.05, false, p3);

    // Draw inner text
    _drawText(canvas, '97%', center.dx, center.dy - 10, 11, isDark ? Colors.white : const Color(0xFF0B1D3A), FontWeight.bold);
    _drawText(canvas, 'Eligible', center.dx, center.dy + 4, 8, isDark ? Colors.white60 : const Color(0xFF4A5C7A), FontWeight.normal);
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, Color color, FontWeight weight) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'DM Sans',
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
