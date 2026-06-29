// lib/features/usa/screens/usa_fico_better_rate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAFicoBetterRateScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFicoBetterRateScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFicoBetterRateScreen> createState() => _USAFicoBetterRateScreenState();
}

class _USAFicoBetterRateScreenState extends ConsumerState<USAFicoBetterRateScreen> {
  static const _theme = CountryThemes.usa;

  // Base Rates conventional
  static const double _baseRate30 = 6.82;
  static const double _baseRate20 = 6.38;
  static const double _baseRate15 = 6.10;

  static const List<_FicoTier> _tiers = [
    _FicoTier('580–619', 580, 619, 1.50, 'badge-r', 'High Risk', Color(0xFFB91C1C)),
    _FicoTier('620–639', 620, 639, 1.10, 'badge-r', 'Poor', Color(0xFFDC2626)),
    _FicoTier('640–659', 640, 659, 0.75, 'badge-o', 'Fair', Color(0xFFEA580C)),
    _FicoTier('660–679', 660, 679, 0.50, 'badge-o', 'Fair-Good', Color(0xFFD97706)),
    _FicoTier('680–699', 680, 699, 0.30, 'badge-o', 'Good', Color(0xFFCA8A04)),
    _FicoTier('700–719', 700, 719, 0.20, 'badge-b', 'Good', Color(0xFF2563EB)),
    _FicoTier('720–739', 720, 739, 0.10, 'badge-b', 'Very Good', Color(0xFF0EA5E9)),
    _FicoTier('740–759', 740, 759, 0.05, 'badge-g', 'Very Good', Color(0xFF16A34A)),
    _FicoTier('760–850', 760, 850, 0.00, 'badge-g', 'Excellent ✓', Color(0xFF15803D)),
  ];

  static const List<_BoostTip> _tips = [
    _BoostTip('💳', 'Pay Down Credit Card Balances', '+40–100 pts', 'High', 'badge-g', 'Keep utilization below 10%. This is the single fastest FICO booster — each billing cycle updates.'),
    _BoostTip('✅', 'Never Miss a Payment', '+20–50 pts', 'High', 'badge-g', 'Payment history = 35% of FICO. One 30-day late can drop 60–110 points. Set autopay now.'),
    _BoostTip('🚫', 'Don\'t Open New Credit Accounts', '+5–15 pts', 'Med', 'badge-o', 'Each hard inquiry drops ~5 pts for 12 months. Freeze new applications 12 months before applying.'),
    _BoostTip('📋', 'Dispute Credit Report Errors', '+20–100 pts', 'High', 'badge-g', '25% of reports have errors. Dispute with Equifax, Experian, TransUnion via AnnualCreditReport.com.'),
    _BoostTip('🕒', 'Become an Authorized User', '+10–30 pts', 'Med', 'badge-b', 'Ask a family member with excellent credit to add you to their old card. Age + limit transfers to you.'),
    _BoostTip('📂', 'Keep Old Accounts Open', '+5–15 pts', 'Low', 'badge-o', 'Credit age = 15% of FICO. Closing old cards shortens history and raises utilization ratio.'),
    _BoostTip('🔄', 'Mix of Credit Types', '+5–15 pts', 'Low', 'badge-b', 'Having a mix (card + auto + installment loan) = 10% of FICO. Don\'t open accounts just for this.'),
    _BoostTip('🔐', 'Credit Builder Loan', '+15–35 pts', 'Med', 'badge-b', 'Self.inc or local CU credit-builder loans add positive payment history. Best for thin files.'),
  ];

  // Inputs
  final _loanController = TextEditingController(text: '360000');
  double _currentFico = 700.0; // 580 to 850
  int _loanTerm = 30; // 30, 20, 15

  final FocusNode _loanFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loanFocus.addListener(() => setState(() {}));

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanController.text = (inputs['loanAmount'] ?? 360000.0).toStringAsFixed(0);
      _currentFico = inputs['currentFico'] ?? 700.0;
      _loanTerm = (inputs['loanTerm'] ?? 30.0).toInt();
    }
  }

  @override
  void dispose() {
    _loanController.dispose();
    _loanFocus.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  double _getBaseRate(int term) {
    if (term == 15) return _baseRate15;
    if (term == 20) return _baseRate20;
    return _baseRate30;
  }

  _FicoTier _getTierForFico(double score) {
    return _tiers.firstWhere((t) => score >= t.min && score <= t.max,
        orElse: () => _tiers.last);
  }

  double _getRateForFico(double score, int term) {
    final t = _getTierForFico(score);
    return _getBaseRate(term) + t.rateAdj;
  }

  double _monthlyPI(double principal, double annualRate, int years) {
    final r = annualRate / 100 / 12;
    final n = years * 12;
    if (r == 0) return principal / n;
    return principal * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  String _ficoCategory(double score) {
    if (score < 580) return 'Very Poor';
    if (score < 620) return 'Poor';
    if (score < 640) return 'Poor-Fair';
    if (score < 660) return 'Fair';
    if (score < 680) return 'Fair-Good';
    if (score < 700) return 'Good';
    if (score < 720) return 'Good';
    if (score < 740) return 'Very Good';
    if (score < 760) return 'Very Good';
    if (score < 800) return 'Excellent';
    return 'Exceptional';
  }

  Color _ficoCategoryColor(double score) {
    if (score < 580) return const Color(0xFF991B1B);
    if (score < 620) return const Color(0xFFB91C1C);
    if (score < 640) return const Color(0xFFDC2626);
    if (score < 660) return const Color(0xFFEA580C);
    if (score < 680) return const Color(0xFFD97706);
    if (score < 700) return const Color(0xFFCA8A04);
    if (score < 720) return const Color(0xFF2563EB);
    if (score < 740) return const Color(0xFF0EA5E9);
    if (score < 760) return const Color(0xFF059669);
    if (score < 800) return const Color(0xFF15803D);
    return const Color(0xFF14532D);
  }

  void _resetInputs() {
    setState(() {
      _loanController.text = '360000';
      _currentFico = 700.0;
      _loanTerm = 30;
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
    final loan = _val(_loanController);
    final rate = _getRateForFico(_currentFico, _loanTerm);
    final pi = _monthlyPI(loan, rate, _loanTerm);
    final bestRate = _getBaseRate(_loanTerm);
    final bestPI = _monthlyPI(loan, bestRate, _loanTerm);
    final diffMo = max(0.0, pi - bestPI);

    final labelCtrl = TextEditingController(text: 'FICO Better Rate Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_fico_better_rate_screen'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save FICO Scenario',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: FICO ${_currentFico.toInt()} · Loan: ${CurrencyFormatter.format(loan, symbol: '\$').split('.').first} · Monthly P&I: ${CurrencyFormatter.format(pi, symbol: '\$').split('.').first}',
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
                hintText: 'Label (e.g. My FICO booster)',
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
              backgroundColor: const Color(0xFF7C3AED),
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
          : 'FICO Better Rate Plan';

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'FICO Better Rate Plan',
        label: label,
        currencyCode: 'USD',
        inputs: {
          'loanAmount': loan,
          'currentFico': _currentFico,
          'loanTerm': _loanTerm.toDouble(),
        },
        results: {
          'rate': rate,
          'pi': pi,
          'diffMo': diffMo,
          'diffTotal': diffMo * _loanTerm * 12,
        },
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ FICO booster scenario saved successfully!'),
            backgroundColor: Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _loanController.text = (calc.inputs['loanAmount'] ?? 360000.0).toStringAsFixed(0);
      _currentFico = calc.inputs['currentFico'] ?? 700.0;
      _loanTerm = (calc.inputs['loanTerm'] ?? 30.0).toInt();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded saved scenario!'),
        backgroundColor: Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/usa/ficorate/info'),
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
                    'About FICO & Mortgage Rates',
                    style: AppTextStyles.playfair(size: 20, color: textCol, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your FICO score represents your credit risk and is the primary factor US lenders use to determine your mortgage interest rate. Higher credit scores indicate lower credit risk, unlocking lower adjustments (interest rates) which save you tens of thousands of dollars over the life of a loan.',
                    style: AppTextStyles.dmSans(size: 14, color: mutedCol, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PMI and Credit Scores:',
                    style: AppTextStyles.playfair(size: 14, color: textCol, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you purchase a home with less than 20% down, you will pay Private Mortgage Insurance (PMI). Just like interest rates, your monthly PMI cost scales significantly with FICO. Moving from a 620 to a 760 FICO can cut your annual PMI premium by more than half, saving you hundreds of dollars per month.',
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

    final loan = _val(_loanController);
    final activeRate = _getRateForFico(_currentFico, _loanTerm);
    final activePI = _monthlyPI(loan, activeRate, _loanTerm);

    final bestRate = _getBaseRate(_loanTerm);
    final bestPI = _monthlyPI(loan, bestRate, _loanTerm);

    final diffMo = max(0.0, activePI - bestPI);
    final diffTotal = diffMo * _loanTerm * 12;

    // FICO Score Gauge category and color
    final ficoCat = _ficoCategory(_currentFico);
    final ficoCatColor = _ficoCategoryColor(_currentFico);

    // Watch saved FICO calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'FICO Better Rate Plan').toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with custom gradient and card watermark
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
                        '💳',
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
                                    'Boost FICO',
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
                              '760+ unlocks the best mortgage rates in the US',
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
                  Expanded(child: _buildRsCell('Best FICO', '760+', 'Prime Rate', isGold: true)),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('FHA Min', '580', '3.5% Down')),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Conv. Min', '620', '3% Down')),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Rate Range', '~1.5%', '580→760')),
                ],
              ),
            ),
          ),

          // Main Screen Scroll Content
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FICO Impact'.toUpperCase(),
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

              // Result Hero Card (Purple/Violet gradient)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
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
                      'RATE AT YOUR FICO SCORE',
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
                          activeRate.toStringAsFixed(2),
                          style: AppTextStyles.dmSans(
                            size: 38,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ).copyWith(fontFamily: 'Georgia'),
                        ),
                        Text(
                          '%',
                          style: AppTextStyles.dmSans(
                            size: 18,
                            weight: FontWeight.w800,
                            color: const Color(0xFFFCD34D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FICO ${_currentFico.toInt()} · Conventional $_loanTerm-yr · ${CurrencyFormatter.format(loan, symbol: '\$').split('.').first} Loan · $ficoCat',
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
                          child: _buildHeroStat('Monthly P&I', CurrencyFormatter.format(activePI, symbol: '\$').split('.').first, '$_loanTerm-year fixed'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHeroStat(
                            'vs. Best Rate',
                            diffMo > 0 ? '-${CurrencyFormatter.format(diffMo, symbol: '\$').split('.').first}/mo' : '✓ Best Rate',
                            'vs. 760+ FICO',
                            textColor: const Color(0xFFFCD34D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHeroStat(
                            '$_loanTerm-yr Extra Cost',
                            diffMo > 0 ? CurrencyFormatter.compact(diffTotal, symbol: '\$') : '\$0',
                            'vs. best rate',
                            textColor: const Color(0xFFFCD34D),
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
                      'Your Scenario'.toUpperCase(),
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

              // Scenario Inputs Card
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
                          child: const Text('💳', style: TextStyle(fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mortgage & FICO Details',
                          style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Loan Amount
                    _buildInputField('Loan Amount', _loanController, _loanFocus),
                    const SizedBox(height: 12),

                    // FICO Score Slider & Pills
                    Text(
                      'YOUR CURRENT FICO SCORE',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('580', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
                        Text('${_currentFico.toInt()}', style: AppTextStyles.dmSans(size: 13, color: textCol, weight: FontWeight.w800)),
                        Text('850', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
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
                        value: _currentFico,
                        min: 580,
                        max: 850,
                        divisions: 270,
                        onChanged: (v) => setState(() => _currentFico = v),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [580.0, 620.0, 640.0, 700.0, 720.0, 760.0].map((fVal) {
                          return _buildFicoPill(fVal);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loan Term Pills
                    Text(
                      'LOAN TERM',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [30, 20, 15].map((t) {
                        final isActive = _loanTerm == t;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _loanTerm = t),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF0B1D3A) : bgCol,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isActive ? const Color(0xFF0B1D3A) : borderCol, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$t yr',
                                style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: isActive ? Colors.white : mutedCol,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Calculate Button
                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '📊 Calculate Rate Impact',
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
                              'Save This Scenario',
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

              // FICO Score Gauge Card
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'FICO Score Gauge'.toUpperCase(),
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
                      'Your Score Position',
                      style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),

                    // Semi-circular gauge custom paint
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 120,
                        child: CustomPaint(
                          painter: _FicoGaugePainter(
                            score: _currentFico,
                            label: ficoCat,
                            color: ficoCatColor,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Range labels
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Poor\n580', style: TextStyle(fontSize: 8.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        Text('Fair\n620', style: TextStyle(fontSize: 8.5, color: Color(0xFFEA580C), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        Text('Good\n670', style: TextStyle(fontSize: 8.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        Text('V.Good\n740', style: TextStyle(fontSize: 8.5, color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        Text('Excl.\n800+', style: TextStyle(fontSize: 8.5, color: Color(0xFF15803D), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                  ],
                ),
              ),

              // Rate Tiers Matrix
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FICO → Rate Tiers'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    Text(
                      '2025 Avg',
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
                      'Freddie Mac Rate by FICO — ${CurrencyFormatter.format(loan, symbol: '\$').split('.').first} Loan',
                      style: AppTextStyles.playfair(size: 11.5, color: const Color(0xFF1B3F72), weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: _tiers.map((t) {
                        final tRate = _getBaseRate(_loanTerm) + t.rateAdj;
                        final tPI = _monthlyPI(loan, tRate, _loanTerm);
                        final tDiff = tPI - bestPI;
                        final isActive = _currentFico >= t.min && _currentFico <= t.max;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? LinearGradient(
                                    colors: [const Color(0xFF7C3AED).withValues(alpha: 0.06), const Color(0xFF4C1D95).withValues(alpha: 0.04)],
                                  )
                                : null,
                            borderRadius: isActive ? BorderRadius.circular(10) : null,
                            border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF7C3AED) : bgCol,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  t.label,
                                  style: AppTextStyles.dmSans(
                                    size: isActive ? 11 : 9.5,
                                    weight: FontWeight.w800,
                                    color: isActive ? Colors.white : textCol,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${tRate.toStringAsFixed(2)}% Rate', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                                    Text('${CurrencyFormatter.format(tPI, symbol: '\$').split('.').first}/mo payment', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: t.badge == 'badge-r'
                                            ? const Color(0xFFFEF2F2)
                                            : (t.badge == 'badge-o' ? const Color(0xFFFFF7ED) : (t.badge == 'badge-b' ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4))),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        t.badgeText,
                                        style: AppTextStyles.badgeText(
                                          t.badge == 'badge-r'
                                              ? const Color(0xFFB91C1C)
                                              : (t.badge == 'badge-o' ? const Color(0xFFB45309) : (t.badge == 'badge-b' ? const Color(0xFF1D4ED8) : const Color(0xFF15803D))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tRate.toStringAsFixed(2)}%',
                                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  const SizedBox(height: 2),
                                  if (tDiff > 0.5)
                                    Text(
                                      '-${CurrencyFormatter.format(tDiff, symbol: '\$').split('.').first}/mo',
                                      style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF15803D), weight: FontWeight.w700),
                                    )
                                  else
                                    const Text(
                                      'Best Rate ✓',
                                      style: TextStyle(fontSize: 9.5, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
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

              // Lifetime Savings Card
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'Lifetime Savings if You Boost'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14532D), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Financial Impact of a Better FICO Score',
                      style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _buildSavingsGridItem('Monthly Savings', diffMo > 0 ? CurrencyFormatter.format(diffMo, symbol: '\$').split('.').first : '\$0', 'vs. 760+ score'),
                        _buildSavingsGridItem('Annual Savings', diffMo > 0 ? CurrencyFormatter.format(diffMo * 12, symbol: '\$').split('.').first : '\$0', 'every year'),
                        _buildSavingsGridItem('10-Year Savings', diffMo > 0 ? CurrencyFormatter.compact(diffMo * 120, symbol: '\$') : '\$0', 'if you boost now'),
                        _buildSavingsGridItem('30-Year Savings', diffMo > 0 ? CurrencyFormatter.compact(diffTotal, symbol: '\$') : '\$0', 'total extra paid'),
                      ],
                    ),
                  ],
                ),
              ),

              // Rate Comparison Bar Chart Card
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'Rate Comparison Visual'.toUpperCase(),
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
                      'Monthly Payment by FICO Score Tier',
                      style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Payment bars
                    SizedBox(
                      height: 100,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final selectedTiers = [580.0, 640.0, 680.0, 700.0, 720.0, 760.0];
                          final payments = selectedTiers.map((s) {
                            final rate = _getRateForFico(s, _loanTerm);
                            final pm = _monthlyPI(loan, rate, _loanTerm);
                            return _ChartBarData(s, pm, rate);
                          }).toList();
                          final maxPM = payments.map((p) => p.pi).fold(1.0, max);
                          final colors = [
                            const Color(0xFFB91C1C),
                            const Color(0xFFEA580C),
                            const Color(0xFFD97706),
                            const Color(0xFF2563EB),
                            const Color(0xFF0EA5E9),
                            const Color(0xFF15803D),
                          ];

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(payments.length, (idx) {
                              final p = payments[idx];
                              final h = (p.pi / maxPM * 82).clamp(4.0, 82.0);
                              final isActive = _currentFico >= p.fico && _currentFico < (idx + 1 < payments.length ? payments[idx+1].fico : 851.0);

                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.compact(p.pi, symbol: '\$'),
                                      style: TextStyle(fontSize: 7.5, color: colors[idx], fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      height: h,
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: colors[idx],
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                        border: isActive ? Border.all(color: Colors.white, width: 2) : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.fico >= 760 ? '760+' : p.fico.toInt().toString(),
                                      style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, weight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${p.rate.toStringAsFixed(2)}%',
                                      style: TextStyle(fontSize: 7.5, color: colors[idx], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on Freddie Mac PMMS + FICO adjustment factors · June 2025',
                      style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // PMI Cost Affect Card
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'PMI Bonus — Higher FICO = Lower PMI'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF3F0F0F), const Color(0xFF2E0A0A)]
                        : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                  ),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ FICO Also Affects PMI Cost (if <20% Down)',
                      style: AppTextStyles.playfair(size: 12, color: const Color(0xFFB91C1C), weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    _buildPmiRow('FICO 580–619 · PMI Rate', '~1.50%/yr'),
                    _buildPmiRow('FICO 620–659 · PMI Rate', '~1.10%/yr'),
                    _buildPmiRow('FICO 660–719 · PMI Rate', '~0.75%/yr'),
                    _buildPmiRow('FICO 720–759 · PMI Rate', '~0.55%/yr'),
                    _buildPmiRow('FICO 760+ · PMI Rate', '~0.36%/yr ✓ Best', isBest: true),
                  ],
                ),
              ),

              // FICO Boosting Tips
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'How to Boost Your FICO Score'.toUpperCase(),
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
                      'Proven Strategies — Ranked by Impact',
                      style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: _tips.map((t) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: bgCol,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(t.icon, style: const TextStyle(fontSize: 17)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.name, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(t.desc, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.4)),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: t.badge == 'badge-g'
                                            ? const Color(0xFFDCFCE7)
                                            : (t.badge == 'badge-o' ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${t.impact} Impact',
                                        style: AppTextStyles.badgeText(
                                          t.badge == 'badge-g'
                                              ? const Color(0xFF15803D)
                                              : (t.badge == 'badge-o' ? const Color(0xFFB45309) : const Color(0xFF1D4ED8)),
                                        ),
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
                                    t.pts,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontFamily: 'Georgia'),
                                  ),
                                  Text('pts boost', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
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

              // Saved calculations history panel
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text(
                  'Saved Scenarios'.toUpperCase(),
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
                            'No saved scenarios yet. Tap "Save This Scenario" above to bookmark a plan.',
                            style: AppTextStyles.dmSans(size: 11, color: mutedCol),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: savedCalcs.map((calc) {
                          final isLast = savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                          final lAmt = calc.inputs['loanAmount'] ?? 0.0;
                          final fScore = (calc.inputs['currentFico'] ?? 700.0).toInt();
                          final termYrs = (calc.inputs['loanTerm'] ?? 30.0).toInt();
                          final rVal = calc.results['rate'] ?? 0.0;
                          final piVal = calc.results['pi'] ?? 0.0;

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
                                          'FICO $fScore · Rate ${rVal.toStringAsFixed(2)}% · Loan ${CurrencyFormatter.compact(lAmt, symbol: '\$')} · $termYrs-yr · Monthly ${CurrencyFormatter.compact(piVal, symbol: '\$')}',
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
                                          content: Text('Removed saved scenario'),
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

  Widget _buildHeroStat(String label, String value, String sub, {Color? textColor}) {
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
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: textColor ?? Colors.white),
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
              color: isFocused ? const Color(0xFF7C3AED) : _theme.getBorderColor(context),
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

  Widget _buildFicoPill(double score) {
    final isActive = _currentFico == score;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFico = score;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B1D3A) : _theme.getBgColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF0B1D3A) : _theme.getBorderColor(context), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          score.toInt().toString(),
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: isActive ? Colors.white : _theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPmiRow(String label, String value, {bool isBest = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isBest ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGridItem(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.3),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 9, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _FicoGaugePainter extends CustomPainter {
  final double score;
  final String label;
  final Color color;
  final bool isDark;

  _FicoGaugePainter({
    required this.score,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 14;
    final r = min(size.width, size.height) - 10;
    final center = Offset(cx, cy);

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Colored segments (Poor -> Excellent)
    final segments = [
      _GaugeSeg(580, 620, const Color(0xFFB91C1C)),
      _GaugeSeg(620, 660, const Color(0xFFEA580C)),
      _GaugeSeg(660, 700, const Color(0xFFD97706)),
      _GaugeSeg(700, 740, const Color(0xFF0EA5E9)),
      _GaugeSeg(740, 800, const Color(0xFF22C55E)),
      _GaugeSeg(800, 850, const Color(0xFF15803D)),
    ];

    for (var seg in segments) {
      final startAngle = pi + ((seg.from - 580) / 270) * pi;
      final sweepAngle = ((seg.to - seg.from) / 270) * pi;
      final paint = Paint()
        ..color = seg.color
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Needle pointing
    final pct = ((score - 580) / 270).clamp(0.0, 1.0);
    final angle = pi + pct * pi;
    final nx = cx + (r - 18) * cos(angle);
    final ny = cy + (r - 18) * sin(angle);

    final needlePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0B1D3A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(nx, ny), needlePaint);

    // Pivot dot
    final pivotPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0B1D3A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, pivotPaint);

    // Center texts
    final textPainterNum = TextPainter(
      text: TextSpan(
        text: score.toInt().toString(),
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterNum.layout();
    textPainterNum.paint(
      canvas,
      Offset(cx - textPainterNum.width / 2, cy - 54),
    );

    final textPainterLbl = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterLbl.layout();
    textPainterLbl.paint(
      canvas,
      Offset(cx - textPainterLbl.width / 2, cy - 24),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FicoTier {
  final String label;
  final double min;
  final double max;
  final double rateAdj;
  final String badge;
  final String badgeText;
  final Color color;
  const _FicoTier(this.label, this.min, this.max, this.rateAdj, this.badge, this.badgeText, this.color);
}

class _BoostTip {
  final String icon;
  final String name;
  final String pts;
  final String impact;
  final String badge;
  final String desc;
  const _BoostTip(this.icon, this.name, this.pts, this.impact, this.badge, this.desc);
}

class _GaugeSeg {
  final double from;
  final double to;
  final Color color;
  _GaugeSeg(this.from, this.to, this.color);
}

class _ChartBarData {
  final double fico;
  final double pi;
  final double rate;
  _ChartBarData(this.fico, this.pi, this.rate);
}
