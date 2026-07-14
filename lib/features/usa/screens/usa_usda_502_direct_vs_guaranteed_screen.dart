// lib/features/usa/screens/usa_usda_502_direct_vs_guaranteed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAUsda502DirectVsGuaranteedScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAUsda502DirectVsGuaranteedScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAUsda502DirectVsGuaranteedScreen> createState() => _USAUsda502DirectVsGuaranteedScreenState();
}

class _USAUsda502DirectVsGuaranteedScreenState extends ConsumerState<USAUsda502DirectVsGuaranteedScreen> {
  static const _theme = CountryThemes.usa;

  // Toggle state
  String _selectedProgramTab = 'direct'; // direct, guaranteed
  String _selectedTimelineTab = 'direct'; // direct, guaranteed

  // Controllers & Form Inputs
  final _incomeController = TextEditingController(text: '65000');
  int _selectedHhSize = 4;
  String _selectedRegion = 'standard'; // standard, high

  bool _showRecommenderResult = false;
  String _recommendedProgram = '';
  double _recDirectLimit = 0;
  double _recGuarLimit = 0;
  int _recIndex = 0; // 0 = Direct, 1 = Guar, 2 = Over limit

  // Focus node to monitor focus status and update border color dynamically
  final FocusNode _incomeFocusNode = FocusNode();

  // 2025 USDA Income Limits (115% AMI for Guaranteed, 80% AMI for Direct)
  static const _limitsData = {
    'standard': {
      'guaranteed': [103500.0, 112450.0, 126500.0, 140550.0, 151800.0, 163050.0, 174300.0, 185550.0],
      'direct': [50200.0, 57350.0, 64500.0, 71600.0, 77350.0, 83100.0, 88800.0, 94550.0]
    },
    'high': {
      'guaranteed': [135600.0, 154900.0, 174250.0, 193550.0, 208900.0, 224300.0, 239650.0, 255050.0],
      'direct': [65500.0, 74800.0, 84200.0, 93500.0, 101000.0, 108500.0, 115950.0, 123450.0]
    }
  };

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  @override
  void initState() {
    super.initState();
    _incomeFocusNode.addListener(() {
      setState(() {});
    });

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _incomeController.text = (inputs['income'] ?? 65000.0).toStringAsFixed(0);
      _selectedHhSize = (inputs['hhSize'] ?? 4.0).toInt();
      _selectedRegion = (inputs['region'] ?? 0.0) == 0.0 ? 'standard' : 'high';

      final results = widget.savedCalc!.results;
      _recDirectLimit = results['DirectLimit'] ?? 0.0;
      _recGuarLimit = results['GuarLimit'] ?? 0.0;
      _recIndex = (results['RecIndex'] ?? 0.0).toInt();

      if (_recIndex == 0) {
        _recommendedProgram = '🏛️ You Qualify for 502 Direct';
        _selectedProgramTab = 'direct';
      } else if (_recIndex == 1) {
        _recommendedProgram = '🏦 You Qualify for 502 Guaranteed';
        _selectedProgramTab = 'guaranteed';
      } else {
        _recommendedProgram = '❌ Over Limits for Both Programs';
      }
      _calcSnapshot['income'] = double.tryParse(_incomeController.text) ?? 0.0;
      _calcSnapshot['hhSize'] = _selectedHhSize;
      _calcSnapshot['region'] = _selectedRegion;
      _showRecommenderResult = true;
    }
  }

  void _resetInputs() {
    setState(() {
      _incomeController.text = '65000';
      _selectedHhSize = 4;
      _selectedRegion = 'standard';
      _showRecommenderResult = false;
      _calcSnapshot.clear();
    });
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _incomeFocusNode.dispose();
    super.dispose();
  }

  void _recommendProgram({bool showFeedback = true}) {
    final income = double.tryParse(_incomeController.text) ?? 0.0;
    final idx = (_selectedHhSize - 1).clamp(0, 7);
    final lims = _limitsData[_selectedRegion]!;
    final directLimit = lims['direct']![idx];
    final guarLimit = lims['guaranteed']![idx];

    String recommendation = '';
    int recommendedIndex = 0;

    if (income <= directLimit) {
      recommendation = '🏛️ You Qualify for 502 Direct';
      recommendedIndex = 0;
    } else if (income <= guarLimit) {
      recommendation = '🏦 You Qualify for 502 Guaranteed';
      recommendedIndex = 1;
    } else {
      recommendation = '❌ Over Limits for Both Programs';
      recommendedIndex = 2;
    }

    setState(() {
      _recommendedProgram = recommendation;
      _recDirectLimit = directLimit;
      _recGuarLimit = guarLimit;
      _recIndex = recommendedIndex;
      _calcSnapshot['income'] = income;
      _calcSnapshot['hhSize'] = _selectedHhSize;
      _calcSnapshot['region'] = _selectedRegion;
      _showRecommenderResult = true;
    });

    if (showFeedback) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Program recommendation updated'),
          backgroundColor: Color(0xFF15803D),
          duration: Duration(seconds: 2),
        ),
      );
    }

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
    final income = _calcSnapshot['income'] ?? (double.tryParse(_incomeController.text) ?? 0.0);
    final hhSize = _calcSnapshot['hhSize'] ?? _selectedHhSize;
    final region = _calcSnapshot['region'] ?? _selectedRegion;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'USDA 502 Direct vs Guaranteed',
      label: 'USDA Rec: ${_recIndex == 0 ? "Direct" : (_recIndex == 1 ? "Guar" : "Over limit")} · Income: ${CurrencyFormatter.compact(income, symbol: '\$')}',
      currencyCode: 'USD',
      inputs: {
        'income': income,
        'hhSize': hhSize.toDouble(),
        'region': region == 'standard' ? 0.0 : 1.0,
      },
      results: {
        'DirectLimit': _recDirectLimit,
        'GuarLimit': _recGuarLimit,
        'RecIndex': _recIndex.toDouble(),
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔖 Program comparison saved successfully!'),
        backgroundColor: Color(0xFF15803D),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/usa/usda/info'),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF141C33) : Colors.white;
        final textCol = isDark ? Colors.white : const Color(0xFF0B1D3A);
        final mutedCol = isDark ? Colors.white70 : const Color(0xFF4A5C7A);

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'About USDA 502 Loans',
                    style: AppTextStyles.playfair(size: 20, color: textCol, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The Section 502 Rural Housing Loan Programs assist low- and moderate-income households in purchasing safe, clean, and sanitary housing in eligible rural areas.',
                    style: AppTextStyles.dmSans(size: 14, color: mutedCol, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _buildBulletPoint('🏛️ Section 502 Direct', 'Funded directly by the government. Focuses on very low- to low-income borrowers (under 80% AMI) and provides payment assistance/subsidies to lower the interest rate down to 1%.', textCol, mutedCol),
                  const SizedBox(height: 12),
                  _buildBulletPoint('🏦 Section 502 Guaranteed', 'Funded by approved private lenders (banks, credit unions) and backed 90% by the USDA. Ideal for moderate-income families (up to 115% AMI). There is no USDA loan limit, and the process is faster.', textCol, mutedCol),
                  const SizedBox(height: 16),
                  Text(
                    'Key Eligibility Criteria:',
                    style: AppTextStyles.playfair(size: 14, color: textCol, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Must occupy the property as your primary residence.\n• The property must be located in an eligible rural area as defined by the USDA.\n• You must meet household income caps which scale by household size and cost-of-living metrics.',
                    style: AppTextStyles.dmSans(size: 13.5, color: mutedCol, height: 1.6),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBulletPoint(String title, String desc, Color titleCol, Color descCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.dmSans(size: 14, color: titleCol, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(desc, style: AppTextStyles.dmSans(size: 13, color: descCol, height: 1.4)),
      ],
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

    // Check if the current inputs are already saved
    final savedList = ref.watch(savedProvider);
    final snapIncome = _calcSnapshot['income'] ?? 0.0;
    final snapHhSize = _calcSnapshot['hhSize'] ?? 0;
    final snapRegion = _calcSnapshot['region'] ?? '';

    final isCurrentCalcSaved = savedList.any((calc) =>
        calc.calcType == 'USDA 502 Direct vs Guaranteed' &&
        calc.inputs['income'] == snapIncome &&
        calc.inputs['hhSize'] == snapHhSize.toDouble() &&
        (calc.inputs['region'] == 0.0 ? 'standard' : 'high') == snapRegion);

    final currentIncome = double.tryParse(_incomeController.text) ?? 0.0;
    final isDirty = _showRecommenderResult && (
      currentIncome != snapIncome ||
      _selectedHhSize != snapHhSize ||
      _selectedRegion != snapRegion
    );

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Premium Header with custom gradient and wheat watermark
          SliverAppBar(
            expandedHeight: 155,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF15803D), Color(0xFF78350F)],
                        stops: [0.0, 0.45, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Watermark emoji
                  Positioned(
                    right: 8,
                    top: 46,
                    child: Opacity(
                      opacity: 0.06,
                      child: Text(
                        '🌾',
                        style: TextStyle(
                          fontSize: 82,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  // App Bar Contents
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('←', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('🌾', style: TextStyle(fontSize: 24)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '502 Direct vs. Guaranteed',
                                    style: AppTextStyles.playfair(
                                      size: 18,
                                      color: Colors.white,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'USDA Rural Housing Loan Programs · 2025',
                                    style: AppTextStyles.dmSans(
                                      size: 10,
                                      color: Colors.white.withValues(alpha: 0.50),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _showInfoSheet,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('ℹ️', style: TextStyle(fontSize: 14, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate Strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildStripItem('Direct Rate', '4.75%', 'Subsidized', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
                  Expanded(child: _buildStripItem('Guar. Rate', '6.35%', 'Market rate', isDark)),
                  Container(width: 1, height: 26, color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
                  Expanded(child: _buildStripItem('Direct Max', '\$377K', 'Most states', isDark)),
                  Container(width: 1, height: 26, color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08)),
                  Expanded(child: _buildStripItem('Loan Limit', 'None', 'Guaranteed', isDark, isGold: true)),
                ],
              ),
            ),
          ),

          // Main Contents
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Program toggle
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedProgramTab = 'direct'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _selectedProgramTab == 'direct'
                                  ? const LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: _selectedProgramTab == 'direct'
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🏛️ 502 Direct',
                              style: AppTextStyles.dmSans(
                                size: 12,
                                color: _selectedProgramTab == 'direct' ? Colors.white : mutedCol,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedProgramTab = 'guaranteed'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _selectedProgramTab == 'guaranteed'
                                  ? const LinearGradient(
                                      colors: [Color(0xFF15803D), Color(0xFF166534)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: _selectedProgramTab == 'guaranteed'
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF15803D).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🏦 502 Guaranteed',
                              style: AppTextStyles.dmSans(
                                size: 12,
                                color: _selectedProgramTab == 'guaranteed' ? Colors.white : mutedCol,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Direct or Guaranteed Hero Card
                _buildHeroCard(isDark, isCurrentCalcSaved),

                const SizedBox(height: 20),
                _buildSectionHeader('Find Your Program'),

                // Recommender Input Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎯 Which Program Fits You?',
                        style: AppTextStyles.playfair(size: 13.5, color: textCol, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Annual Income (\$)', _incomeController, isDark, borderCol),
                          ),
                          const SizedBox(width: 10),
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
                              isDark: isDark,
                              borderCol: borderCol,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDropdownField<String>(
                        label: 'State / Region Type',
                        value: _selectedRegion,
                        items: const [
                          DropdownMenuItem(value: 'standard', child: Text('Standard Cost Area')),
                          DropdownMenuItem(value: 'high', child: Text('High Cost Area (CA, HI, AK, etc.)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRegion = val);
                          }
                        },
                        isDark: isDark,
                        borderCol: borderCol,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _recommendProgram(showFeedback: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF15803D), Color(0xFF166534)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '🌾 Find My USDA Program',
                                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _resetInputs,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                              decoration: BoxDecoration(
                                color: cardBg,
                                border: Border.all(color: borderCol),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'Reset',
                                style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Recommender Result Display inside the card
                      if (_showRecommenderResult) ...[
                        if (isDirty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Inputs have changed. Find program again to update.',
                                    style: AppTextStyles.dmSans(
                                      size: 11,
                                      color: const Color(0xFFB45309),
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildRecommenderResultCard(isDark, isCurrentCalcSaved),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Side-by-Side Comparison'),

                // Comparison Table Matrix
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        color: isDark ? const Color(0xFF111729) : const Color(0xFFF8FAFF),
                        child: Row(
                          children: [
                            Expanded(flex: 13, child: Text('FEATURE', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, weight: FontWeight.w700, letterSpacing: 0.5))),
                            Expanded(flex: 10, child: Text('🏛️ 502 DIRECT', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF7C3AED), weight: FontWeight.w800), textAlign: TextAlign.center)),
                            Expanded(flex: 10, child: Text('🏦 502 GUAR.', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF15803D), weight: FontWeight.w800), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      _buildCompareRow('Lender', 'USDA/Gov\'t', 'Private Bank', isDark, borderCol, textCol),
                      _buildCompareRow('Income Target', 'Very Low–Low\n(≤50–80% AMI)', 'Moderate\n(≤115% AMI)', isDark, borderCol, textCol, isDirectBadge: true, isGuarBadge: true, labelDirect: '≤50–80% AMI', labelGuar: '≤115% AMI'),
                      _buildCompareRow('Interest Rate', '4.75%\n(Subsidized)', '6.35%\n(Market)', isDark, borderCol, textCol, isDirectBadge: true, labelDirect: 'Subsidized'),
                      _buildCompareRow('Payment Subsidy', '✅ Yes\n(As low as 1%)', '❌ None', isDark, borderCol, textCol, isDirectBadge: true, labelDirect: 'As low as 1%'),
                      _buildCompareRow('Down Payment', '\$0', '\$0', isDark, borderCol, textCol),
                      _buildCompareRow('Upfront Fee', 'None\n(No fee)', '1.00%\n(Financed)', isDark, borderCol, textCol, isDirectBadge: true, labelDirect: 'No fee'),
                      _buildCompareRow('Annual Fee', 'None', '0.35%/yr', isDark, borderCol, textCol),
                      _buildCompareRow('Loan Limit', '~\$377K\n(Varies by area)', 'No limit\n(Income cap only)', isDark, borderCol, textCol, isGuarBadge: true, labelGuar: 'Income cap only'),
                      _buildCompareRow('Loan Term', '33–38 yrs', '30 yrs', isDark, borderCol, textCol),
                      _buildCompareRow('Credit Score', 'None\n(Manual UW)', '640+\n(Lender req.)', isDark, borderCol, textCol),
                      _buildCompareRow('Processing Time', '60–90 days', '30–45 days\n(Faster)', isDark, borderCol, textCol, isGuarBadge: true, labelGuar: 'Faster'),
                      _buildCompareRow('Market Share', '~10%', '~90%\n(Most popular)', isDark, borderCol, textCol, isGuarBadge: true, labelGuar: 'Most popular'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Rate & Cost Comparison'),

                // Comparison Bar Chart Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Effective Rate vs. Monthly Payment (\$250K Home)',
                        style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      // Height-aligned bar wrapper container
                      SizedBox(
                        height: 130,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCostBarColumn('🏛️ 502 Direct', '4.75%', 80, '\$1,304', const Color(0xFF7C3AED), textCol, mutedCol),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildCostBarColumn('🏦 502 Guaranteed', '6.35%', 115, '\$1,562', const Color(0xFF15803D), textCol, mutedCol),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 Direct saves ~\$258/mo vs Guaranteed',
                              style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF166534), weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Over 30 yrs = ~\$92,880 in savings — but Direct has stricter income/area limits',
                              style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Application Process'),

                // Process timeline
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔄 Step-by-Step Process',
                        style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      // Timeline program selector tabs
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111729) : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            Expanded(child: _buildTimelineToggleTab('Direct', 'direct', mutedCol)),
                            Expanded(child: _buildTimelineToggleTab('Guaranteed', 'guaranteed', mutedCol)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Dynamic Timeline lists
                      if (_selectedTimelineTab == 'direct') ...[
                        _buildTimelineStep(1, 'Contact Local USDA RD Office', 'Find your state\'s Rural Development office at rd.usda.gov · Schedule an appointment', 'Day 1', const Color(0xFF7C3AED), textCol, mutedCol, false),
                        _buildTimelineStep(2, 'Submit Form RD 410-4', 'Application for Rural Assistance with income documentation, tax returns (2 yrs), bank statements', 'Week 1–2', const Color(0xFF7C3AED), textCol, mutedCol, false),
                        _buildTimelineStep(3, 'USDA Underwrites Directly', 'USDA reviews income eligibility, credit, and property. No private lender involved.', 'Week 3–6', const Color(0xFF7C3AED), textCol, mutedCol, false),
                        _buildTimelineStep(4, 'Subsidy Determination', 'USDA calculates your payment subsidy to reduce effective rate — as low as 1%', 'Week 6–8', const Color(0xFF7C3AED), textCol, mutedCol, false),
                        _buildTimelineStep(5, 'Closing with USDA', 'USDA funds the loan directly. No private lender closing fees typical with banks.', 'Week 10–12', const Color(0xFF7C3AED), textCol, mutedCol, true),
                      ] else ...[
                        _buildTimelineStep(1, 'Choose USDA-Approved Lender', 'Banks, credit unions, mortgage companies — over 1,800 approved lenders nationwide', 'Day 1', const Color(0xFF15803D), textCol, mutedCol, false),
                        _buildTimelineStep(2, 'Pre-Qualification & Application', 'Lender pulls credit (640+ preferred), verifies income, submits GUS (Guaranteed Underwriting System)', 'Week 1–2', const Color(0xFF15803D), textCol, mutedCol, false),
                        _buildTimelineStep(3, 'Lender Underwrites Loan', 'Private lender completes underwriting; GUS provides Accept/Refer/Caution determination', 'Week 2–4', const Color(0xFF15803D), textCol, mutedCol, false),
                        _buildTimelineStep(4, 'USDA Issues Conditional Commitment', 'Lender submits to USDA for guarantee approval — typically 2–5 business days', 'Week 4–5', const Color(0xFF15803D), textCol, mutedCol, false),
                        _buildTimelineStep(5, 'Closing with Private Lender', 'Standard closing process. USDA guarantees 90% of loan to lender. 1% upfront fee financed.', 'Week 5–7', const Color(0xFF15803D), textCol, mutedCol, true),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Key Insights'),

                // Key insights styled cards
                _buildInsightCard('🏛️', '502 Direct: Deepest Subsidy', 'For households at 50–80% of Area Median Income (AMI). Payment subsidy can reduce your effective rate to as low as 1%. Must apply directly through USDA Rural Development office — not through a bank.', const Color(0xFFC4B5FD), const Color(0xFF7C3AED), isDark),
                const SizedBox(height: 8),
                _buildInsightCard('🏦', '502 Guaranteed: More Accessible', 'For households up to 115% AMI. Apply through any of 1,800+ approved lenders nationwide. Faster processing (30–45 days) and no loan limit makes it the choice for 90% of USDA borrowers.', const Color(0xFF86EFAC), const Color(0xFF15803D), isDark),
                const SizedBox(height: 8),
                _buildInsightCard('⚠️', 'Recapture Rule — Direct Only', 'If you sell or refinance a 502 Direct loan within 9 years, USDA may "recapture" some of the subsidy received. Plan to stay or ask USDA about the recapture calculation before selling.', const Color(0xFFFCD34D), const Color(0xFFB45309), isDark),
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
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8,
            weight: FontWeight.w700,
            color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.playfair(
            size: 13.5,
            weight: FontWeight.w800,
            color: isGold ? const Color(0xFFFCD34D) : Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          sub,
          style: AppTextStyles.dmSans(
            size: 7.5,
            color: isDark ? Colors.white30 : Colors.white60,
          ),
        ),
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

  // Active Program Hero Card
  Widget _buildHeroCard(bool isDark, bool isSaved) {
    if (_selectedProgramTab == 'direct') {
      return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D1B69), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D1B69).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'USDA 502 DIRECT LOAN',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.50),
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                _buildSaveButton(isSaved),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '4.75%',
              style: AppTextStyles.playfair(
                size: 30,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gov\'t subsidized · Applied directly through USDA Rural Development',
              style: AppTextStyles.dmSans(
                size: 9.5,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC4B5FD).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC4B5FD).withValues(alpha: 0.30)),
              ),
              child: Text(
                '🏛️ Very Low to Low Income · USDA Administers Directly',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: const Color(0xFFC4B5FD),
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1D3A).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'USDA 502 GUARANTEED LOAN',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.50),
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                _buildSaveButton(isSaved),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '6.35%',
              style: AppTextStyles.playfair(
                size: 30,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Market rate · Applied through USDA-approved private lenders',
              style: AppTextStyles.dmSans(
                size: 9.5,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF86EFAC).withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.30)),
              ),
              child: Text(
                '🏦 Moderate Income · Lender Administered · 90% of USDA Loans',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: const Color(0xFF86EFAC),
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSaveButton(bool isSaved) {
    return GestureDetector(
      onTap: isSaved ? null : _saveCalc,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSaved ? const Color(0xFF15803D).withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: isSaved ? Colors.transparent : Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 4),
            Text(
              isSaved ? 'Saved' : 'Save',
              style: AppTextStyles.dmSans(
                size: 10.5,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isDark, Color borderCol) {
    final hasFocus = _incomeFocusNode.hasFocus;
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
            color: isDark ? const Color(0xFF111729) : const Color(0xFFF8FAFF),
            border: Border.all(color: hasFocus ? const Color(0xFF15803D) : borderCol, width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            focusNode: _incomeFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 13.5,
              weight: FontWeight.w700,
              color: _theme.getTextColor(context),
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
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    required Color borderCol,
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
            color: isDark ? const Color(0xFF111729) : const Color(0xFFF8FAFF),
            border: Border.all(color: borderCol, width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w700,
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

  // Recommender Output box with dynamic background color styling
  Widget _buildRecommenderResultCard(bool isDark, bool isSaved) {
    final income = _calcSnapshot['income'] ?? 0.0;
    final hhSize = _calcSnapshot['hhSize'] ?? _selectedHhSize;

    // Gradients, borders, and text colors based on eligibility status index
    Gradient cardGrad;
    Color border;
    Color recTextCol;
    Color subTextCol;
    List<Widget> rows = [];

    if (_recIndex == 0) {
      // 🏛️ Direct
      cardGrad = LinearGradient(
        colors: isDark ? [const Color(0xFF1A1138), const Color(0xFF2C1C52)] : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      border = const Color(0xFFC4B5FD);
      recTextCol = const Color(0xFF7C3AED);
      subTextCol = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);

      rows = [
        _buildRecResultRow('Your Income', '\$${CurrencyFormatter.format(income)}', subTextCol, border),
        _buildRecResultRow('Direct Limit ($hhSize-person)', '\$${CurrencyFormatter.format(_recDirectLimit)}', subTextCol, border),
        _buildRecResultRow('Also Qualifies for Guaranteed', '✅ Yes', subTextCol, border),
        _buildRecResultRow('Recommended Rate', 'As low as 1% (subsidized)', subTextCol, border),
      ];
    } else if (_recIndex == 1) {
      // 🏦 Guaranteed
      cardGrad = LinearGradient(
        colors: isDark ? [const Color(0xFF0C1D13), const Color(0xFF14301D)] : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      border = const Color(0xFF86EFAC);
      recTextCol = const Color(0xFF15803D);
      subTextCol = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);

      rows = [
        _buildRecResultRow('Your Income', '\$${CurrencyFormatter.format(income)}', subTextCol, border),
        _buildRecResultRow('Guaranteed Limit ($hhSize-person)', '\$${CurrencyFormatter.format(_recGuarLimit)}', subTextCol, border),
        _buildRecResultRow('Direct Program', '❌ Over income cap', subTextCol, border),
        _buildRecResultRow('Typical Rate', '~6.35% (market)', subTextCol, border),
      ];
    } else {
      // ❌ Over limits
      cardGrad = LinearGradient(
        colors: isDark ? [const Color(0xFF2A1C0F), const Color(0xFF382312)] : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      border = const Color(0xFFFCD34D);
      recTextCol = const Color(0xFFD97706);
      subTextCol = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);

      rows = [
        _buildRecResultRow('Your Income', '\$${CurrencyFormatter.format(income)}', subTextCol, border),
        _buildRecResultRow('Guaranteed Limit ($hhSize-person)', '\$${CurrencyFormatter.format(_recGuarLimit)}', subTextCol, border),
        _buildRecResultRow('Income Over Limit', '\$${CurrencyFormatter.format(income - _recGuarLimit)}', subTextCol, border),
      ];
    }

    return Container(
      key: _resultsKey,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: cardGrad,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recommendedProgram,
            style: AppTextStyles.playfair(
              size: 14,
              color: recTextCol,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
          const SizedBox(height: 8),
          Text(
            _recIndex == 0
                ? 'Contact your local USDA Rural Development office to apply. The 502 Direct subsidy can reduce your payment significantly. You may also choose Guaranteed for faster processing.'
                : (_recIndex == 1
                    ? 'Apply through any USDA-approved lender. No down payment required. 1% upfront guarantee fee is financed into your loan. Faster 30–45 day close.'
                    : 'Consider FHA (3.5% down) or conventional loans. Fannie/Freddie HomeReady or Home Possible programs may also help with low down payments.'),
            style: AppTextStyles.dmSans(
              size: 9.5,
              color: subTextCol,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isSaved ? null : _saveCalc,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSaved ? Colors.grey.withValues(alpha: 0.15) : recTextCol.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                isSaved ? '🔖 Saved to Portfolio' : '🔖 Save Recommendation',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: isSaved ? subTextCol.withValues(alpha: 0.5) : recTextCol,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecResultRow(String label, String value, Color color, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border.withValues(alpha: 0.3), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 10, color: color, weight: FontWeight.w600)),
          Text(value, style: AppTextStyles.dmSans(size: 10, color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  // Side-by-Side Comparison Row
  Widget _buildCompareRow(
    String label,
    String valDirect,
    String valGuar,
    bool isDark,
    Color borderCol,
    Color textCol, {
    bool isDirectBadge = false,
    bool isGuarBadge = false,
    String? labelDirect,
    String? labelGuar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderCol)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isDirectBadge && labelDirect != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF241A42) : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labelDirect,
                      style: AppTextStyles.dmSans(
                        size: 8,
                        color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
                        weight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  valDirect.contains('\n') ? valDirect.split('\n')[0] : valDirect,
                  style: AppTextStyles.dmSans(size: 10, color: isDirectBadge ? const Color(0xFF7C3AED) : textCol, weight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isGuarBadge && labelGuar != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF142F1B) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labelGuar,
                      style: AppTextStyles.dmSans(
                        size: 8,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                        weight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  valGuar.contains('\n') ? valGuar.split('\n')[0] : valGuar,
                  style: AppTextStyles.dmSans(size: 10, color: isGuarBadge ? const Color(0xFF15803D) : textCol, weight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cost Comparison bar chart widget matching bc-bar-wrap (bottom alignment inside 130px container)
  Widget _buildCostBarColumn(String label, String rateStr, double height, String cost, Color color, Color textCol, Color mutedCol) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8.5, color: color, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          rateStr,
          style: AppTextStyles.dmSans(size: 9, color: mutedCol),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 44,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.75)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                label.contains('Direct') ? 'Direct' : 'Guar.',
                style: AppTextStyles.dmSans(size: 8, color: Colors.white, weight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          cost,
          style: AppTextStyles.playfair(size: 13, color: color, weight: FontWeight.w800),
        ),
        Text(
          '/mo P&I',
          style: AppTextStyles.dmSans(size: 8, color: mutedCol),
        ),
      ],
    );
  }

  // Timeline program selector tab
  Widget _buildTimelineToggleTab(String label, String tabKey, Color muted) {
    final active = _selectedTimelineTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimelineTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? _theme.getCardColor(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _theme.getBorderColor(context) : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            color: active ? (tabKey == 'direct' ? const Color(0xFF7C3AED) : const Color(0xFF15803D)) : muted,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Vertical timeline step drawing (using IntrinsicHeight and Expanded line to prevent gaps)
  Widget _buildTimelineStep(int index, String title, String desc, String time, Color color, Color textCol, Color mutedCol, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: AppTextStyles.dmSans(size: 11, color: color, weight: FontWeight.w800),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _theme.getBorderColor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.45),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      time,
                      style: AppTextStyles.dmSans(size: 8, color: color, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Key Insights colored card
  Widget _buildInsightCard(String emoji, String title, String desc, Color fillBg, Color highlightColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fillBg.withValues(alpha: isDark ? 0.12 : 0.45),
        border: Border.all(color: fillBg.withValues(alpha: isDark ? 0.3 : 0.8)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.playfair(size: 11.5, color: highlightColor, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF4A5C7A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
