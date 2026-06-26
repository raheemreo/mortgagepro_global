// lib/features/usa/screens/usa_hoa_lender_treatment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHoaLenderTreatmentScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAHoaLenderTreatmentScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAHoaLenderTreatmentScreen> createState() => _USAHoaLenderTreatmentScreenState();
}

class _USAHoaLenderTreatmentScreenState extends ConsumerState<USAHoaLenderTreatmentScreen> {
  static const _theme = CountryThemes.usa;

  final _piPaymentController = TextEditingController(text: '2480');
  final _hoaFeeController = TextEditingController(text: '350');
  final _taxMoController = TextEditingController(text: '412');
  final _insMoController = TextEditingController(text: '150');
  final _otherDebtsController = TextEditingController(text: '500');
  final _grossIncomeController = TextEditingController(text: '8500');

  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    final list = [
      _piPaymentController,
      _hoaFeeController,
      _taxMoController,
      _insMoController,
      _otherDebtsController,
      _grossIncomeController,
    ];
    for (final controller in list) {
      controller.addListener(_markDirty);
    }

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _piPaymentController.text = (inputs['PiPayment'] ?? 2480.0).toStringAsFixed(0);
      _hoaFeeController.text = (inputs['HoaFee'] ?? 350.0).toStringAsFixed(0);
      _taxMoController.text = (inputs['TaxMo'] ?? 412.0).toStringAsFixed(0);
      _insMoController.text = (inputs['InsMo'] ?? 150.0).toStringAsFixed(0);
      _otherDebtsController.text = (inputs['OtherDebts'] ?? 500.0).toStringAsFixed(0);
      _grossIncomeController.text = (inputs['GrossIncome'] ?? 8500.0).toStringAsFixed(0);
      _showResults = true;
      _isCalcDirty = false;
    }
  }

  @override
  void dispose() {
    final list = [
      _piPaymentController,
      _hoaFeeController,
      _taxMoController,
      _insMoController,
      _otherDebtsController,
      _grossIncomeController,
    ];
    for (final controller in list) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _resetInputs() {
    setState(() {
      _piPaymentController.text = '2480';
      _hoaFeeController.text = '350';
      _taxMoController.text = '412';
      _insMoController.text = '150';
      _otherDebtsController.text = '500';
      _grossIncomeController.text = '8500';
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _calculate() {
    setState(() {
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final pi = _val(_piPaymentController);
    final hoa = _val(_hoaFeeController);
    final tax = _val(_taxMoController);
    final ins = _val(_insMoController);
    final debts = _val(_otherDebtsController);
    final income = _val(_grossIncomeController);

    final housing = pi + hoa + tax + ins;
    final total = housing + debts;
    final frontEnd = income > 0 ? (housing / income * 100) : 0.0;
    final backEnd = income > 0 ? (total / income * 100) : 0.0;
    final hoaImpact = income > 0 ? (hoa / income * 100) : 0.0;

    final labelCtrl = TextEditingController(text: 'HOA Lender DTI');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Back-End DTI: ${backEnd.toStringAsFixed(1)}% · HOA Impact: +${hoaImpact.toStringAsFixed(1)}%',
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
                hintText: 'Label (e.g. My Lender Eligibility)',
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
              backgroundColor: const Color(0xFF6D28D9),
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
          : 'HOA Lender DTI';

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HOA Lender DTI',
        inputs: {
          'PiPayment': pi,
          'HoaFee': hoa,
          'TaxMo': tax,
          'InsMo': ins,
          'OtherDebts': debts,
          'GrossIncome': income,
        },
        results: {
          'BackEndDTI': backEnd,
          'FrontEndDTI': frontEnd,
          'HoaImpact': hoaImpact,
          'TotalHousing': housing,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF6D28D9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    // Compute active calculation
    final pi = _val(_piPaymentController);
    final hoa = _val(_hoaFeeController);
    final tax = _val(_taxMoController);
    final ins = _val(_insMoController);
    final debts = _val(_otherDebtsController);
    final income = _val(_grossIncomeController);

    final housing = pi + hoa + tax + ins;
    final total = housing + debts;
    final frontEnd = income > 0 ? (housing / income * 100) : 0.0;
    final backEnd = income > 0 ? (total / income * 100) : 0.0;
    final hoaImpact = income > 0 ? (hoa / income * 100) : 0.0;

    // Status colors & texts
    String heroSub = '';
    String dtiStatus = '';
    String dtiNote = '';
    Color dtiBarColor = const Color(0xFF15803D);
    List<Color> heroColors = const [Color(0xFF15803D), Color(0xFF166534)];

    if (backEnd <= 36) {
      heroSub = '✅ Excellent — qualifies for all major loan programs';
      dtiStatus = '✅ Excellent DTI — strong approval across Conventional, FHA, VA, and USDA';
      dtiBarColor = const Color(0xFF15803D);
      heroColors = const [Color(0xFF15803D), Color(0xFF166534)];
    } else if (backEnd <= 43) {
      heroSub = '⚠️ Acceptable — may require compensating factors for some programs';
      dtiStatus = '⚠️ Acceptable range — qualifies for FHA & most Conventional; VA requires residual income check';
      dtiBarColor = const Color(0xFFD97706);
      heroColors = const [Color(0xFFD97706), Color(0xFF92400E)];
    } else if (backEnd <= 50) {
      heroSub = '⚠️ High — FHA with AUS approval possible; Conventional needs compensating factors';
      dtiStatus = '⚠️ High DTI — FHA with AUS approval possible up to 57%; Conventional needs strong reserves or high credit score';
      dtiBarColor = const Color(0xFFEA580C);
      heroColors = const [Color(0xFFEA580C), Color(0xFF9A3412)];
    } else {
      heroSub = '🚨 Exceeds most guidelines — approval unlikely without co-borrower or HOA reduction';
      dtiStatus = '🚨 Very High DTI — exceeds Fannie Mae/Freddie Mac limits. FHA AUS may allow up to 57% with exceptional credit & reserves.';
      dtiBarColor = const Color(0xFFB91C1C);
      heroColors = const [Color(0xFFB91C1C), Color(0xFF7F1D1D)];
    }

    final withoutHoaDti = income > 0 ? ((total - hoa) / income * 100) : 0.0;
    dtiNote = 'HOA of ${CurrencyFormatter.format(hoa, symbol: r'$')}/mo adds ${hoaImpact.toStringAsFixed(1)} percentage points to your DTI. Without HOA, your back-end DTI would be ${withoutHoaDti.toStringAsFixed(1)}%.';

    // Rate strip values
    const rateStats = [
      {'label': 'Back-End Max', 'value': '43%', 'note': 'Most Lenders'},
      {'label': 'FHA Max DTI', 'value': '57%', 'note': 'w/ Exceptions'},
      {'label': 'VA Max DTI', 'value': '41%', 'note': 'Guideline'},
      {'label': 'Conv. Ideal', 'value': '36%', 'note': 'Back-End'},
    ];

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with gradient
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF4C1D95), Color(0xFF6D28D9)],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 50,
                    child: Opacity(
                      opacity: 0.07,
                      child: Text(
                        '🏦',
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
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
                                  const Text('🏦', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'Lender Treatment',
                                    style: AppTextStyles.playfair(size: 17, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 36),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              'HOA in DTI · FHA · VA · Conventional',
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
                children: rateStats.map((stat) {
                  final idx = rateStats.indexOf(stat);
                  final isLast = idx == rateStats.length - 1;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                right: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1),
                              ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stat['label']!,
                            style: AppTextStyles.dmSans(
                                size: 8.5, weight: FontWeight.w700, color: Colors.white54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat['value']!,
                            style: AppTextStyles.playfair(
                              size: 15,
                              weight: FontWeight.w800,
                              color: stat['label'] == 'Back-End Max' || stat['label'] == 'Conv. Ideal' ? const Color(0xFFFCD34D) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            stat['note']!,
                            style: AppTextStyles.dmSans(
                                size: 7.5, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main scroll area
          SliverList(
            delegate: SliverChildListDelegate([
              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DTI QUALIFIER',
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

              // Inputs Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🏦', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lender DTI Checker',
                                style: AppTextStyles.playfair(
                                    size: 14.5, weight: FontWeight.w800, color: textCol),
                              ),
                              Text(
                                'Check approval likelihood across all loan types',
                                style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildTextInputRow('Monthly P&I Payment', _piPaymentController, prefix: r'$')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Monthly HOA Fee', _hoaFeeController, prefix: r'$')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildTextInputRow('Property Tax /Mo', _taxMoController, prefix: r'$')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Insurance /Mo', _insMoController, prefix: r'$')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildTextInputRow('Other Monthly Debts', _otherDebtsController, prefix: r'$')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Gross Income /Mo', _grossIncomeController, prefix: r'$')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                              elevation: 2,
                            ),
                            child: Text(
                              '🏦 Check Lender Eligibility',
                              style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800),
                            ),
                          ),
                        ),
                        if (_showResults && !_isCalcDirty) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _saveCalculation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardBg,
                              foregroundColor: const Color(0xFF6D28D9),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                                side: const BorderSide(color: Color(0xFF6D28D9), width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              '🔖 Save',
                              style: AppTextStyles.dmSans(
                                  size: 12, weight: FontWeight.w700, color: const Color(0xFF6D28D9)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Results View
              if (_showResults && !_isCalcDirty) ...[
                const SizedBox(height: 16),

                // Hero Result Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: heroColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: heroColors.first.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BACK-END DTI (WITH HOA)',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${backEnd.toStringAsFixed(1)}%',
                        style: AppTextStyles.playfair(
                            size: 36, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        heroSub,
                        style: AppTextStyles.dmSans(
                            size: 10, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildHeroBottomBox('Front-End', '${frontEnd.toStringAsFixed(1)}%'),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('HOA Impact', '+${hoaImpact.toStringAsFixed(1)}%'),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Total Housing', '${CurrencyFormatter.format(housing, symbol: r'$')}/mo'),
                        ],
                      )
                    ],
                  ),
                ),

                // DTI Progress Bar Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Back-End DTI: ',
                              style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol)),
                          Text('${backEnd.toStringAsFixed(1)}%',
                              style: AppTextStyles.playfair(size: 12, weight: FontWeight.w900, color: const Color(0xFF6D28D9))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (backEnd / 57.0).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: dtiBarColor,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0%', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('28%', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('36%', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('43%', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('57%+', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildDtiZoneBox('Excellent', '≤36%', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
                          const SizedBox(width: 8),
                          _buildDtiZoneBox('Acceptable', '37–43%', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          _buildDtiZoneBox('High Risk', '>43%', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dtiStatus,
                                style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: textCol)),
                            const SizedBox(height: 2),
                            Text(
                              dtiNote,
                              style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Approval Chart
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval Likelihood by Loan Type',
                        style: AppTextStyles.playfair(
                            size: 12.5, weight: FontWeight.w700, color: textCol),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _DtiApprovalChartPainter(
                            dti: backEnd,
                            textColor: textCol,
                            mutedColor: mutedCol,
                            gridColor: borderCol,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Loan Type Rules
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Text(
                  'LOAN TYPE HOA RULES',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    _buildLoanRuleCard('FHA', 'FHA Loan', '43–57%', '31–40%', '10%+ needed', '<15%', cardBg, textCol, mutedCol, borderCol, isDark),
                    _buildLoanRuleCard('Conv', 'Conventional', '45–50%', '28–36%', '10%+ reserve', '<15%', cardBg, textCol, mutedCol, borderCol, isDark),
                    _buildLoanRuleCard('VA', 'VA Loan', '41%+', 'N/A', 'Required', 'Flexible', cardBg, textCol, mutedCol, borderCol, isDark, label3: 'Residual Inc.', val3: 'Required', label5: 'Delinquency', val5: 'Reviewed'),
                    _buildLoanRuleCard('USDA', 'USDA Loan', '41%', '29%', 'Rural only', 'Rare', cardBg, textCol, mutedCol, borderCol, isDark, label4: 'Eligible Areas', val4: 'Rural only', label5: 'HOA Common', val5: 'Rare'),
                  ],
                ),
              ),

              // Condo Project Approval Factors
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Text(
                  'CONDO PROJECT APPROVAL',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏢 What Lenders Check About the HOA',
                      style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem('📊', 'Owner-Occupancy Ratio', 'Fannie Mae & FHA require ≥50% owner-occupied units. Buildings with too many rentals may be ineligible for conventional financing.', const Color(0xFFDCFCE7), const Color(0xFF15803D), textCol, mutedCol),
                    _buildChecklistItem('💸', 'HOA Delinquency Rate', 'Max 15% of units can be 30+ days delinquent on HOA dues. Higher delinquency = HOA cash-flow risk = lender rejection.', const Color(0xFFFEE2E2), const Color(0xFFB91C1C), textCol, mutedCol),
                    _buildChecklistItem('🔍', 'Single-Entity Ownership', 'No single entity can own more than 10% (Fannie) or 25% (FHA) of units. Over-concentrated ownership is a red flag.', const Color(0xFFFEF9C3), const Color(0xFFD97706), textCol, mutedCol),
                    _buildChecklistItem('⚖️', 'Active Litigation', 'Any active lawsuit against the HOA (construction defects, insurance disputes) can make the building ineligible for Fannie Mae/FHA financing.', const Color(0xFFF3E8FF), const Color(0xFF6D28D9), textCol, mutedCol),
                    _buildChecklistItem('🏦', 'Reserve Fund Adequacy', 'Post-Surfside, FHA requires HOAs to maintain 10%+ of annual budget in reserves. Fannie Mae conducts project reviews on high-rise condos.', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), textCol, mutedCol),
                    _buildChecklistItem('🏗️', 'Building Condition', 'Lenders (especially post-2021) increasingly scrutinize structural integrity reports, especially for buildings 20+ years old or 3+ stories.', const Color(0xFFDCFCE7), const Color(0xFF15803D), textCol, mutedCol),
                  ],
                ),
              ),

              // Red Flags
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF3F1B1B), const Color(0xFF2E1414)]
                        : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                  ),
                  border: Border.all(color: const Color(0x38B91C1C)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚩 Red Flags That Kill Financing',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: const Color(0xFFB91C1C))),
                    const SizedBox(height: 10),
                    _buildRedFlagItem('🚨', 'HOA Delinquency >15%', 'Triggers automatic disqualification for Fannie Mae & FHA condo approval'),
                    _buildRedFlagItem('⚖️', 'Active HOA Litigation', 'Even small lawsuits can cause "spot approval" refusals — affecting your specific unit'),
                    _buildRedFlagItem('📉', 'Pending Large Special Assessment', 'Must be disclosed; may need to be paid in full at closing or reduce loan eligibility'),
                    _buildRedFlagItem('🏗️', 'Structural Safety Concerns', 'Post-Surfside Florida law now requires milestone inspections; non-compliance = unlendable'),
                    _buildRedFlagItem('🔢', 'Single Owner >10% of Units', 'Investor concentration violates Fannie Mae project eligibility requirements'),
                  ],
                ),
              ),

              // Key Numbers
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Text(
                  'KEY NUMBERS',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat('🏦', 'Fannie DTI', '45%', 'Back-end max', cardBg, textCol, mutedCol, borderCol, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMiniStat('🏠', 'FHA DTI', '57%', 'w/ AUS approve', cardBg, textCol, mutedCol, borderCol, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMiniStat('🇺🇸', 'VA DTI', '41%', '+ residual rule', cardBg, textCol, mutedCol, borderCol, isDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMiniStat('📊', 'Owner-Occ.', '50%', 'FHA min', cardBg, textCol, mutedCol, borderCol, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMiniStat('💰', 'Reserves', '10%', 'Of annual budget', cardBg, textCol, mutedCol, borderCol, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMiniStat('⚠️', 'Deliq. Max', '15%', 'HOA units', cardBg, textCol, mutedCol, borderCol, isDark)),
                      ],
                    ),
                  ],
                ),
              ),

              // Pro Tip
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2E1A47), const Color(0xFF1E1030)]
                        : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
                  ),
                  border: Border.all(color: const Color(0x2E6D28D9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Pro Tip: HOA Questionnaire',
                        style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: const Color(0xFF4C1D95))),
                    const SizedBox(height: 5),
                    Text(
                      'Your lender will send an HOA Questionnaire to the association before closing. This captures: budget health, delinquency rate, pending litigation, owner-occupancy ratio, and reserve fund balance. Delays in HOA response are a common cause of closing delays — notify the HOA early in the process.',
                      style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF6D28D9), height: 1.55),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputRow(String label, TextEditingController controller,
      {String? prefix, String? suffix}) {
    final textColor = _theme.getTextColor(context);
    final mutedColor = _theme.getMutedColor(context);
    final borderColor = _theme.getBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8.5, weight: FontWeight.w700, color: mutedColor, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (prefix != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    border: Border(right: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Text(prefix,
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: mutedColor)),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.playfair(
                        size: 14, weight: FontWeight.w800, color: textColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Text(suffix,
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedColor)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBottomBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildDtiZoneBox(String label, String val, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context), weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanRuleCard(
    String badge,
    String name,
    String backMax,
    String frontMax,
    String reserve,
    String delinq,
    Color cardBg,
    Color textCol,
    Color mutedCol,
    Color borderCol,
    bool isDark, {
    String label3 = 'Reserve Check',
    String val3 = '10%+',
    String label4 = 'Delinquency',
    String val4 = '<15%',
    String? label5,
    String? val5,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge, style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Text(name, style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                _buildRuleRow('HOA in DTI', 'Yes ✓', mutedCol, const Color(0xFF15803D)),
                _buildRuleRow('Back-End Max', backMax, mutedCol, textCol),
                if (frontMax != 'N/A') _buildRuleRow('Front-End Max', frontMax, mutedCol, textCol),
                _buildRuleRow(label3, val3, mutedCol, textCol),
                _buildRuleRow(label4, val4, mutedCol, textCol),
                if (label5 != null && val5 != null) _buildRuleRow(label5, val5, mutedCol, textCol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String key, String val, Color keyCol, Color valCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 9.5, color: keyCol, weight: FontWeight.w700)),
          Text(val, style: AppTextStyles.dmSans(size: 10, color: valCol, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String icon, String title, String sub, Color iconBg,
      Color iconText, Color textCol, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x120B1D3A), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: iconText),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11, weight: FontWeight.w700, color: textCol)),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedFlagItem(String icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x18B91C1C), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 10.5, weight: FontWeight.w700, color: const Color(0xFF7F1D1D))),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFB91C1C))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, String label, String value, String sub,
      Color cardBg, Color textCol, Color mutedCol, Color borderCol, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 3),
            Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.playfair(size: 14.5, weight: FontWeight.w800, color: textCol)),
            Text(sub, style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Approval Chart vs User DTI
class _DtiApprovalChartPainter extends CustomPainter {
  final double dti;
  final Color textColor;
  final Color mutedColor;
  final Color gridColor;
  final bool isDark;

  const _DtiApprovalChartPainter({
    required this.dti,
    required this.textColor,
    required this.mutedColor,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;

    final programs = [
      {'name': 'Conv. (Ideal)', 'max': 36.0, 'color': const Color(0xFF1B3F72)},
      {'name': 'Conv. (Max)', 'max': 50.0, 'color': const Color(0xFF6D28D9)},
      {'name': 'FHA (Std)', 'max': 43.0, 'color': const Color(0xFFD97706)},
      {'name': 'FHA (AUS)', 'max': 57.0, 'color': const Color(0xFF15803D)},
      {'name': 'VA Loan', 'max': 41.0, 'color': const Color(0xFFB91C1C)},
    ];

    const barH = 14.0;
    const gap = 6.0;
    const startY = 6.0;
    final maxX = W - 110.0; // Allocating space for labels & markers

    for (int i = 0; i < programs.length; i++) {
      final p = programs[i];
      final y = startY + i * (barH + gap);
      final maxP = p['max'] as double;
      final color = p['color'] as Color;

      final bw = (maxP / 60.0) * maxX;

      // Draw background bar
      final bgPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(80.0, y, maxX, barH), const Radius.circular(4.0)),
        bgPaint,
      );

      // Draw program bar
      final progPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(80.0, y, bw, barH), const Radius.circular(4.0)),
        progPaint,
      );

      // Program label (Left side)
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: p['name'] as String,
        style: AppTextStyles.dmSans(size: 8.5, color: textColor, weight: FontWeight.w700),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(74.0 - textPainter.width, y + barH / 2 - textPainter.height / 2));

      // Limit label (Inside bar)
      textPainter.text = TextSpan(
        text: '${maxP.toStringAsFixed(0)}%',
        style: AppTextStyles.playfair(size: 8.5, weight: FontWeight.w800, color: Colors.white),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(85.0, y + barH / 2 - textPainter.height / 2));

      // Draw User DTI line marker
      final dx = 80.0 + (dti / 60.0) * maxX;
      if (dx <= 80.0 + maxX) {
        final linePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = dti <= maxP ? Colors.white : const Color(0xFFFF0000);
        canvas.drawLine(Offset(dx, y - 2.0), Offset(dx, y + barH + 2.0), linePaint);
      }

      // Draw pass/fail dot at end
      final pass = dti <= maxP;
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = pass ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
      canvas.drawCircle(Offset(80.0 + maxX + 12.0, y + barH / 2), 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DtiApprovalChartPainter oldDelegate) {
    return oldDelegate.dti != dti || oldDelegate.isDark != isDark || oldDelegate.textColor != textColor;
  }
}
