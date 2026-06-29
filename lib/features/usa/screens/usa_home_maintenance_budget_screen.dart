// lib/features/usa/screens/usa_home_maintenance_budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHomeMaintenanceBudgetScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAHomeMaintenanceBudgetScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAHomeMaintenanceBudgetScreen> createState() => _USAHomeMaintenanceBudgetScreenState();
}

class _USAHomeMaintenanceBudgetScreenState extends ConsumerState<USAHomeMaintenanceBudgetScreen> {
  static const _theme = CountryThemes.usa;

  // Inputs
  final _homeValueController = TextEditingController(text: '450000');
  final _reserveController = TextEditingController(text: '0');
  double _homeAge = 5.0; // 0 to 80
  double _maintenanceRate = 1.5; // 1.0, 1.5, 2.0

  final FocusNode _valueFocus = FocusNode();
  final FocusNode _reserveFocus = FocusNode();

  static const List<_MaintCategory> _categories = [
    _MaintCategory('HVAC Service & Repair', '❄️', 'Filter, tune-up, emergencies', 0.18, Color(0xFF1B3F72)),
    _MaintCategory('Roof & Gutters', '🏠', 'Inspection, cleaning, patching', 0.16, Color(0xFFD97706)),
    _MaintCategory('Plumbing', '🚿', 'Leaks, fixtures, water heater', 0.14, Color(0xFF15803D)),
    _MaintCategory('Electrical', '⚡', 'Outlets, panels, lighting', 0.11, Color(0xFF7C3AED)),
    _MaintCategory('Exterior & Paint', '🎨', 'Siding, deck, driveway', 0.13, Color(0xFFEA580C)),
    _MaintCategory('Lawn & Landscaping', '🌿', 'Mowing, irrigation, trees', 0.12, Color(0xFF0EA5E9)),
    _MaintCategory('Interior Repairs', '🔨', 'Drywall, flooring, doors', 0.09, Color(0xFFEC4899)),
    _MaintCategory('Appliance Maintenance', '🫙', 'Fridge, dishwasher, washer', 0.07, Color(0xFFF59E0B)),
  ];

  static const List<_SeasonData> _seasons = [
    _SeasonData('Spring', '🌸', Color(0xFFDCFCE7), [
      _TaskData('HVAC service (A/C tune-up)', '\$80–\$150'),
      _TaskData('Roof & gutter inspection', '\$100–\$300'),
      _TaskData('Exterior paint touch-up', '\$200–\$800'),
      _TaskData('Window & door sealing', '\$50–\$200'),
    ]),
    _SeasonData('Summer', '☀️', Color(0xFFFEF9C3), [
      _TaskData('Lawn irrigation service', '\$75–\$200'),
      _TaskData('Deck/patio cleaning & seal', '\$150–\$500'),
      _TaskData('Pest inspection', '\$100–\$300'),
      _TaskData('Exterior power wash', '\$150–\$400'),
    ]),
    _SeasonData('Fall', '🍂', Color(0xFFFEF3C7), [
      _TaskData('Heating system tune-up', '\$80–\$150'),
      _TaskData('Gutter cleaning', '\$100–\$225'),
      _TaskData('Chimney sweep/inspection', '\$150–\$350'),
      _TaskData('Weatherstripping doors', '\$50–\$150'),
    ]),
    _SeasonData('Winter', '❄️', Color(0xFFEFF6FF), [
      _TaskData('Pipe insulation check', '\$50–\$200'),
      _TaskData('Smoke/CO detector test', '\$20–\$50'),
      _TaskData('Water heater flush', '\$50–\$100'),
      _TaskData('Roof snow load check', '\$0–\$200'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _valueFocus.addListener(() => setState(() {}));
    _reserveFocus.addListener(() => setState(() {}));

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _homeValueController.text = (inputs['homeValue'] ?? 450000.0).toStringAsFixed(0);
      _reserveController.text = (inputs['currentReserve'] ?? 0.0).toStringAsFixed(0);
      _homeAge = inputs['homeAge'] ?? 5.0;
      _maintenanceRate = inputs['maintenanceRate'] ?? 1.5;
    }
  }

  @override
  void dispose() {
    _homeValueController.dispose();
    _reserveController.dispose();
    _valueFocus.dispose();
    _reserveFocus.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  double _getAgeMultiplier(double age) {
    if (age < 10) return 1.0;
    if (age < 25) return 1.3;
    if (age < 50) return 1.7;
    return 2.2;
  }

  String _getAgeRiskLabel(double age) {
    if (age < 10) return 'Low';
    if (age < 25) return 'Moderate';
    if (age < 50) return 'High';
    return 'Critical';
  }

  String _getAgeRiskSub(double age) {
    if (age < 10) return 'Under 10 yrs';
    if (age < 25) return '10–25 yrs';
    if (age < 50) return '25–50 yrs';
    return '50+ yrs';
  }

  void _resetInputs() {
    setState(() {
      _homeValueController.text = '450000';
      _reserveController.text = '0';
      _homeAge = 5.0;
      _maintenanceRate = 1.5;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Inputs reset to baseline values'),
        backgroundColor: Color(0xFF1B3F72),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveCalculation() async {
    final value = _val(_homeValueController);
    final reserve = _val(_reserveController);
    final mult = _getAgeMultiplier(_homeAge);
    final annual = value * (_maintenanceRate / 100) * mult;
    final monthly = annual / 12;

    final labelCtrl = TextEditingController(text: 'Home Maintenance Budget');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_home_maintenance_budget_screen'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Maintenance Budget',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Annual ${CurrencyFormatter.compact(annual, symbol: '\$')} · Home Value: ${CurrencyFormatter.compact(value, symbol: '\$')} · Reserve: ${CurrencyFormatter.compact(reserve, symbol: '\$')}',
              style: AppTextStyles.dmSans(
                  size: 11, color: _theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: _theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Home Maintenance)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: _theme.getBgColor(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'Home Maintenance Budget';

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Home Maintenance Budget',
        label: label,
        currencyCode: 'USD',
        inputs: {
          'homeValue': value,
          'currentReserve': reserve,
          'homeAge': _homeAge,
          'maintenanceRate': _maintenanceRate,
        },
        results: {
          'annualBudget': annual,
          'monthlyBudget': monthly,
          'reserveTarget': annual * 3,
        },
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Maintenance budget saved successfully!'),
            backgroundColor: Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _homeValueController.text = (calc.inputs['homeValue'] ?? 450000.0).toStringAsFixed(0);
      _reserveController.text = (calc.inputs['currentReserve'] ?? 0.0).toStringAsFixed(0);
      _homeAge = calc.inputs['homeAge'] ?? 5.0;
      _maintenanceRate = calc.inputs['maintenanceRate'] ?? 1.5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded saved budget!'),
        backgroundColor: Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/usa/maintenance/info'),
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
                    'About Home Maintenance',
                    style: AppTextStyles.playfair(size: 20, color: textCol, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The 1–2% Rule is a standard real estate formula suggesting that homeowners budget 1% to 2% of the home\'s value annually for maintenance and repairs. Older homes require a higher percentage due to systems reaching the end of their lifespans.',
                    style: AppTextStyles.dmSans(size: 14, color: mutedCol, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Risk and Multipliers:',
                    style: AppTextStyles.playfair(size: 14, color: textCol, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Under 10 Years (Low Risk): Multiplier 1.0. Brand new structures with builder warranties and new appliances.\n• 10–25 Years (Moderate Risk): Multiplier 1.3. Water heaters, HVAC systems, and appliances begin to fail.\n• 25–50 Years (High Risk): Multiplier 1.7. Major expenses like roofing, siding, and sewer lines may require replacement.\n• 50+ Years (Critical Risk): Multiplier 2.2. Electrical, plumbing, and structural components may be near failures.',
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

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final value = _val(_homeValueController);
    final reserve = _val(_reserveController);
    final ageMult = _getAgeMultiplier(_homeAge);

    final annualBudget = value * (_maintenanceRate / 100) * ageMult;
    final monthlyBudget = annualBudget / 12;
    final reserveTarget = annualBudget * 3;

    final reservePct = reserveTarget > 0 ? (reserve / reserveTarget * 100).clamp(0.0, 100.0) : 0.0;
    final monthlyContributionNeeded = reserve >= reserveTarget ? 0.0 : (reserveTarget - reserve) / 36;

    // Projection
    final yr1 = annualBudget;
    final yr2 = annualBudget * 1.035;
    final yr3 = annualBudget * 1.035 * 1.035;
    final maxProj = max(yr1, max(yr2, yr3));

    // Watch saved home maintenance calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Home Maintenance Budget').toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with custom gradient and wrench watermark
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFD97706)],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Watermark emoji
                  Positioned(
                    right: 10,
                    top: 50,
                    child: Opacity(
                      opacity: 0.07,
                      child: Text(
                        '🔧',
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  // Header content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('←', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'Home Maintenance',
                                    style: AppTextStyles.playfair(size: 19, color: Colors.white),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _showInfoSheet,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('ℹ️', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              '1–2% Rule · Seasonal Planner · Reserve Fund',
                              style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate Strip Block
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildRsCell('Rule of Thumb', '1–2%', 'Home Value/yr', isGold: true)),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Avg Spend', '\$6,413', 'Per year')),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Emergency', '3–6 mo', 'Reserves')),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Reserve Fund', '\$10K+', 'Recommended')),
                ],
              ),
            ),
          ),

          // Main contents
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maintenance Budget'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: Text(
                        'Recalculate',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1B3F72)),
                      ),
                    ),
                  ],
                ),
              ),

              // Result Hero Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF92400E), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED ANNUAL MAINTENANCE COST',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$',
                          style: AppTextStyles.dmSans(
                            size: 18,
                            weight: FontWeight.w800,
                            color: const Color(0xFFFCD34D),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(annualBudget, symbol: '').split('.').first,
                          style: AppTextStyles.dmSans(
                            size: 38,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ).copyWith(fontFamily: 'Georgia'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_maintenanceRate.toStringAsFixed(1)}% of ${CurrencyFormatter.format(value, symbol: '\$').split('.').first} · Budget ${CurrencyFormatter.format(monthlyBudget, symbol: '\$').split('.').first}/mo',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Grid stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeroStat('Monthly Budget', '${CurrencyFormatter.format(monthlyBudget, symbol: '\$').split('.').first}/mo', 'Set aside/mo'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHeroStat('Reserve Target', CurrencyFormatter.format(reserveTarget, symbol: '\$').split('.').first, '3× annual est.'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHeroStat(
                            'Home Age Risk',
                            _getAgeRiskLabel(_homeAge),
                            _getAgeRiskSub(_homeAge),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Inputs Section
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Home Details'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: _resetInputs,
                      child: Text(
                        'Reset',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1B3F72)),
                      ),
                    ),
                  ],
                ),
              ),

              // Home Details Inputs Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🏠', style: TextStyle(fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Home Information',
                          style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Home Value
                    _buildInputField('Home Value', _homeValueController, _valueFocus),
                    const SizedBox(height: 12),

                    // Home Age Slider & Pills
                    Text(
                      'HOME AGE (YEARS)',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('New', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
                        Text('${_homeAge.toInt()} yrs', style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                        Text('80 yrs', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFD97706),
                        thumbColor: const Color(0xFFD97706),
                        inactiveTrackColor: const Color(0xFFD97706).withValues(alpha: 0.15),
                        overlayColor: const Color(0xFFD97706).withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _homeAge,
                        min: 0,
                        max: 80,
                        divisions: 80,
                        onChanged: (v) => setState(() => _homeAge = v),
                      ),
                    ),
                    Row(
                      children: [
                        _buildAgePill('0–10 yrs', 5.0),
                        _buildAgePill('10–25 yrs', 20.0),
                        _buildAgePill('25–50 yrs', 35.0),
                        _buildAgePill('50+ yrs', 60.0),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Maintenance Rate Selector
                    Text(
                      'MAINTENANCE RATE',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildRatePill('1% Basic', 1.0),
                        _buildRatePill('1.5% Standard', 1.5),
                        _buildRatePill('2% Premium', 2.0),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Current Reserve
                    _buildInputField('Current Maintenance Reserve', _reserveController, _reserveFocus),
                    const SizedBox(height: 16),

                    // Calculate Button
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFF92400E)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🔧 Calculate Maintenance Budget',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Save Button
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💾', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(
                              'Save This Budget',
                              style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w800,
                                color: const Color(0xFFD97706),
                              ).copyWith(fontFamily: 'Georgia'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Breakdown Rows
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Annual Cost by Category'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    Text(
                      'US Avg',
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1B3F72)),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where Your Budget Goes — ${CurrencyFormatter.format(value, symbol: '\$').split('.').first} Home',
                      style: AppTextStyles.playfair(size: 11, color: const Color(0xFF1B3F72), weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: _categories.map((c) {
                        final catAnnual = annualBudget * c.pct;
                        final catMonthly = catAnnual / 12;
                        final barPct = c.pct;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: bgCol,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(c.icon, style: const TextStyle(fontSize: 17)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                                    Text(c.desc, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                                    const SizedBox(height: 5),
                                    // Custom bar fill
                                    Container(
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Container(
                                            width: constraints.maxWidth * barPct,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: c.color,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${CurrencyFormatter.format(catMonthly, symbol: '\$').split('.').first}/mo',
                                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  Text(
                                    '${CurrencyFormatter.format(catAnnual, symbol: '\$').split('.').first}/yr',
                                    style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Pie Donut Chart Card
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'Budget Breakdown'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance Category Distribution',
                      style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Circular Donut paint
                    Center(
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _HomeMaintenanceDonutPainter(
                          categories: _categories,
                          monthlyBudget: monthlyBudget,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Legend
                    Column(
                      children: _categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(c.name, style: AppTextStyles.dmSans(size: 10.5, color: mutedCol)),
                              ),
                              Text(
                                '${(c.pct * 100).toStringAsFixed(0)}%',
                                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 3-Year Projection Chart
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  '3-Year Cost Projection'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Annual Spend — Next 3 Years',
                      style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Proportional columns
                    SizedBox(
                      height: 100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildProjectionBar('Year 1', yr1, 'Baseline', const Color(0xFF1B3F72), maxProj),
                          _buildProjectionBar('Year 2', yr2, '+3.5%', const Color(0xFFD97706), maxProj),
                          _buildProjectionBar('Year 3', yr3, '+7.1%', const Color(0xFFB91C1C), maxProj),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Costs increase ~3.5%/yr (US inflation avg). Major systems replacement cycles accounted for.',
                      style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Seasonal Planner Grid
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'Seasonal Maintenance Planner'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _seasons.length,
                  itemBuilder: (context, index) {
                    final s = _seasons[index];
                    Color finalBg = s.bg;
                    if (isDark) {
                      if (s.bg == const Color(0xFFDCFCE7)) finalBg = const Color(0xFF0D2816);
                      if (s.bg == const Color(0xFFFEF9C3)) finalBg = const Color(0xFF2C2A0A);
                      if (s.bg == const Color(0xFFFEF3C7)) finalBg = const Color(0xFF2D1E0A);
                      if (s.bg == const Color(0xFFEFF6FF)) finalBg = const Color(0xFF0F1E2E);
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: finalBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(s.icon, style: const TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Text(s.name, style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: s.tasks.map((t) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.task,
                                          style: AppTextStyles.dmSans(size: 8, color: mutedCol),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        t.cost,
                                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: textCol),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Reserve Fund Health Status Card
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'Reserve Fund Health'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F263F), const Color(0xFF0F1E2E)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                  ),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏦 Maintenance Reserve Status',
                      style: AppTextStyles.playfair(size: 12, color: const Color(0xFF1D4ED8), weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    _buildReserveRow('Current Reserve', CurrencyFormatter.format(reserve, symbol: '\$').split('.').first),
                    _buildReserveRow('Recommended (3× Annual)', CurrencyFormatter.format(reserveTarget, symbol: '\$').split('.').first),
                    _buildReserveRow('Monthly Contribution Needed', monthlyContributionNeeded > 0 ? '${CurrencyFormatter.format(monthlyContributionNeeded, symbol: '\$').split('.').first}/mo (3yr plan)' : '✓ Fully Funded!'),
                    const SizedBox(height: 10),
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth * (reservePct / 100);
                            return Container(
                              height: 10,
                              width: w,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('\$0', style: TextStyle(fontSize: 9, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                        Text('${reservePct.toStringAsFixed(0)}% funded', style: const TextStyle(fontSize: 9, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                        Text('${CurrencyFormatter.format(reserveTarget, symbol: '\$').split('.').first} goal', style: const TextStyle(fontSize: 9, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              // Saved calculations history panel
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text(
                  'Saved Budgets'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: savedCalcs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'No saved budgets yet. Tap "Save This Budget" above to bookmark a plan.',
                            style: AppTextStyles.dmSans(size: 11, color: mutedCol),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: savedCalcs.map((calc) {
                          final isLast = savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                          final vVal = calc.inputs['homeValue'] ?? 0.0;
                          final rVal = calc.inputs['currentReserve'] ?? 0.0;
                          final ageVal = (calc.inputs['homeAge'] ?? 5.0).toInt();
                          final rateVal = calc.inputs['maintenanceRate'] ?? 1.5;
                          final annResult = calc.results['annualBudget'] ?? 0.0;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isLast ? Colors.transparent : borderCol.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _loadSavedCalculation(calc),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          calc.label,
                                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Annual ${CurrencyFormatter.compact(annResult, symbol: '\$')} · Home ${CurrencyFormatter.compact(vVal, symbol: '\$')} · Age $ageVal yrs · Reserve ${CurrencyFormatter.compact(rVal, symbol: '\$')} · Rate $rateVal%',
                                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await ref.read(savedProvider.notifier).delete(calc.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed saved budget'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Text('🗑️', style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRsCell(String label, String value, String note, {bool isGold = false}) {
    Color valColor = isGold ? const Color(0xFFFCD34D) : Colors.white;

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w700, letterSpacing: 0.4),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: valColor).copyWith(fontFamily: 'Georgia'),
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildRsDivider() {
    return Container(
      width: 1,
      height: 25,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }

  Widget _buildHeroStat(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.4),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, FocusNode focusNode) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: _theme.getMutedColor(context), letterSpacing: 0.5),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(
              color: isFocused ? const Color(0xFFD97706) : _theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13, right: 10),
                child: Text(
                  '\$',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w700, color: _theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgePill(String label, double val) {
    final isActive = _homeAge == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _homeAge = val;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0B1D3A) : _theme.getBgColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? const Color(0xFF0B1D3A) : _theme.getBorderColor(context)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w700,
              color: isActive ? Colors.white : _theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatePill(String label, double val) {
    final isActive = _maintenanceRate == val;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _maintenanceRate = val;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0B1D3A) : _theme.getBgColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? const Color(0xFF0B1D3A) : _theme.getBorderColor(context)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: isActive ? Colors.white : _theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReserveRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8), fontFamily: 'Georgia')),
        ],
      ),
    );
  }

  Widget _buildProjectionBar(String label, double val, String note, Color barColor, double maxVal) {
    final h = (val / maxVal * 82).clamp(4.0, 82.0);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.compact(val, symbol: '\$'),
            style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: _theme.getTextColor(context)),
          ),
          const SizedBox(height: 3),
          Container(
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context), weight: FontWeight.w600),
          ),
          Text(
            note,
            style: AppTextStyles.dmSans(size: 7.5, weight: FontWeight.w700, color: barColor),
          ),
        ],
      ),
    );
  }
}

class _HomeMaintenanceDonutPainter extends CustomPainter {
  final List<_MaintCategory> categories;
  final double monthlyBudget;
  final bool isDark;

  _HomeMaintenanceDonutPainter({
    required this.categories,
    required this.monthlyBudget,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 14.0;

    double startAngle = -pi / 2;

    for (var cat in categories) {
      final sweepAngle = cat.pct * 2 * pi;
      final paint = Paint()
        ..color = cat.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Donut hole text
    final textPainterVal = TextPainter(
      text: TextSpan(
        text: CurrencyFormatter.format(monthlyBudget, symbol: '\$').split('.').first,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterVal.layout();
    textPainterVal.paint(
      canvas,
      center - Offset(textPainterVal.width / 2, textPainterVal.height / 2 + 6),
    );

    final textPainterLbl = TextPainter(
      text: const TextSpan(
        text: 'per month',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterLbl.layout();
    textPainterLbl.paint(
      canvas,
      center - Offset(textPainterLbl.width / 2, -10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MaintCategory {
  final String name;
  final String icon;
  final String desc;
  final double pct;
  final Color color;
  const _MaintCategory(this.name, this.icon, this.desc, this.pct, this.color);
}

class _SeasonData {
  final String name;
  final String icon;
  final Color bg;
  final List<_TaskData> tasks;
  const _SeasonData(this.name, this.icon, this.bg, this.tasks);
}

class _TaskData {
  final String task;
  final String cost;
  const _TaskData(this.task, this.cost);
}
