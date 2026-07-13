// lib/features/usa/screens/usa_fha_credit_score_requirements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/currency_formatter.dart';

class USAFhaCreditScoreRequirementsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFhaCreditScoreRequirementsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFhaCreditScoreRequirementsScreen> createState() => _USAFhaCreditScoreRequirementsScreenState();
}

class _USAFhaCreditScoreRequirementsScreenState extends ConsumerState<USAFhaCreditScoreRequirementsScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  double _score = 620;
  final _homePriceController = TextEditingController(text: '350000');
  String _bankruptcy = 'no';
  bool _calculated = false;

  // Outputs
  double _downPct = 0;
  double _downAmt = 0;
  double _loanAmt = 0;
  String _overlayRisk = '';
  String _resultText = '';
  bool _isEligible = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _score = inputs['score'] ?? 620.0;
      _homePriceController.text = (inputs['homePrice'] ?? 350000.0).toStringAsFixed(0);
      final bkIdx = (inputs['bankruptcyIndex'] ?? 0.0).toInt();
      _bankruptcy = bkIdx == 0 ? 'no' : bkIdx == 1 ? 'ch7' : 'ch13';
      _calculate();
    }
  }

  @override
  void dispose() {
    _homePriceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final price = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (price <= 0) {
      errors['price'] = 'Enter positive home price';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _calculated = false;
      });
      return;
    }

    if (_score < 500) {
      setState(() {
        _calcSnapshot['price'] = price;
        _calcSnapshot['score'] = _score;
        _calcSnapshot['bankruptcy'] = _bankruptcy;

        _isEligible = false;
        _downPct = 0;
        _downAmt = 0;
        _loanAmt = 0;
        _overlayRisk = 'High';
        _resultText = 'FHA requires a minimum 500 FICO score to insure any loan';
        _calculated = true;
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
      return;
    }

    final downPct = _score >= 580 ? 0.035 : 0.10;
    final downAmt = price * downPct;
    final loanAmt = price - downAmt;
    final risk = _score >= 660 ? 'Low' : _score >= 620 ? 'Moderate' : 'Higher (shop lenders)';

    String bkNote = '';
    if (_bankruptcy == 'ch7') {
      bkNote = ' Chapter 7 needs 2+ yrs since discharge with re-established credit.';
    } else if (_bankruptcy == 'ch13') {
      bkNote = ' Chapter 13 may qualify after 1 yr of on-time plan payments + trustee approval.';
    }

    setState(() {
      _calcSnapshot['price'] = price;
      _calcSnapshot['score'] = _score;
      _calcSnapshot['bankruptcy'] = _bankruptcy;

      _isEligible = true;
      _downPct = downPct;
      _downAmt = downAmt;
      _loanAmt = loanAmt;
      _overlayRisk = risk;
      _resultText = '${_score.toInt()} FICO qualifies for ${(downPct * 100).toStringAsFixed(1)}% down.$bkNote';
      _calculated = true;
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
    if (!_calculated) return;
    final price = _calcSnapshot['price'] ?? 350000.0;
    final score = _calcSnapshot['score'] ?? 620.0;
    final bk = _calcSnapshot['bankruptcy'] ?? 'no';
    final bkIdx = bk == 'no' ? 0 : bk == 'ch7' ? 1 : 2;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FHA Credit Score Requirements',
      label: 'FHA Credit Check: ${score.toInt()} FICO',
      currencyCode: 'USD',
      inputs: {
        'score': score,
        'homePrice': price,
        'bankruptcyIndex': bkIdx.toDouble(),
      },
      results: {
        'DownPaymentAmt': _downAmt,
        'LoanAmountNeeded': _loanAmt,
        'Eligible': _isEligible ? 1.0 : 0.0,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Credit score eligibility check saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['price'] ?? 0.0) ||
      _score != (_calcSnapshot['score'] ?? 620.0) ||
      _bankruptcy != (_calcSnapshot['bankruptcy'] ?? 'no')
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scoreVal = _calculated ? (_calcSnapshot['score'] ?? 620.0) : _score;

    // Slide tag styling
    String tagLabel;
    Color tagBg;
    Color tagText;
    if (scoreVal < 500) {
      tagLabel = 'Not Eligible';
      tagBg = isDark ? const Color(0xFF5A1D1D) : const Color(0xFFFCA5A5);
      tagText = isDark ? Colors.white : const Color(0xFF7F1D1D);
    } else if (scoreVal < 580) {
      tagLabel = 'Fair';
      tagBg = isDark ? const Color(0xFF5D4017) : const Color(0xFFFEF3C7);
      tagText = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
    } else if (scoreVal < 670) {
      tagLabel = 'Fair/Good';
      tagBg = isDark ? const Color(0xFF134E5E) : const Color(0xFFBBF7D0);
      tagText = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF166534);
    } else {
      tagLabel = 'Good/Excellent';
      tagBg = isDark ? const Color(0xFF14532D) : const Color(0xFF86EFAC);
      tagText = isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
    }

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
                      const Text('💳', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Credit Score Requirements',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('FHA Minimum FICO · Down Payment Tiers',
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
                    child: _buildStripItem('Absolute Min', '500', '10% down', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Standard Min', '580', '3.5% down', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Lender Min (Most)', '620', 'Common floor', isDark),
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
                _buildSectionHeader('FHA Credit Tiers', badgeText: 'HUD Handbook 4000.1'),

                // Hero Box
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
                      Text('FHA Single Family Housing Policy Handbook'.toUpperCase(),
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 5),
                      Text('Two FICO tiers decide your minimum down payment',
                          style: AppTextStyles.dmSans(
                              size: 16,
                              color: Colors.white,
                              weight: FontWeight.w800,
                              height: 1.25)),
                      const SizedBox(height: 6),
                      Text(
                          'FHA itself only requires 500+ to insure a loan, but most lenders set their own higher overlay — commonly 620 — due to risk tolerance and investor requirements.',
                          style: AppTextStyles.dmSans(
                              size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTierBox('580+ FICO', '3.5% Down', isGold: true),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTierBox('500–579 FICO', '10% Down'),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTierBox('Below 500', 'Not Eligible', isRed: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Credit Score Scale'),

                // Visual Scale Card
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
                      Text('📊 Where You Stand',
                          style: AppTextStyles.dmSans(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      
                      // Scale indicator
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final pct = ((_score - 300) / 550).clamp(0.0, 1.0);
                          final markerLeft = pct * (constraints.maxWidth - 5);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFCA5A5),
                                      Color(0xFFFCA5A5),
                                      Color(0xFFFDE68A),
                                      Color(0xFFFDE68A),
                                      Color(0xFFBBF7D0),
                                      Color(0xFFBBF7D0),
                                      Color(0xFF86EFAC),
                                      Color(0xFF86EFAC),
                                    ],
                                    stops: [0.0, 0.19, 0.19, 0.36, 0.36, 0.64, 0.64, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: markerLeft,
                                top: -6,
                                child: Container(
                                  width: 4,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: textCol,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('300', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('500', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('580', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('670', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('740', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('850', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Legend
                      _buildLegendRow(const Color(0xFFFCA5A5), 'Below 500 — Not Eligible', 'FHA will not insure the loan at any down payment', null),
                      const SizedBox(height: 8),
                      _buildLegendRow(const Color(0xFFFDE68A), '500–579 — Fair', 'Eligible with 10% minimum down payment', '10%'),
                      const SizedBox(height: 8),
                      _buildLegendRow(const Color(0xFFBBF7D0), '580–669 — Fair/Good', 'Eligible with 3.5% minimum down payment', '3.5%'),
                      const SizedBox(height: 8),
                      _buildLegendRow(const Color(0xFF86EFAC), '670+ — Good/Excellent', 'Best rates, easiest approval, 3.5% down', '3.5%'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Check Your Eligibility'),

                // Eligibility Inputs Card
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
                      Text('🔍 Credit Score Eligibility Checker',
                          style: AppTextStyles.dmSans(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      
                      // Score Display & Slider
                      Center(
                        child: Column(
                          children: [
                            Text('${_score.toInt()}',
                                style: AppTextStyles.dmSans(size: 34, weight: FontWeight.w800, color: textCol)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: tagBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tagLabel,
                                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: tagText),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _score,
                        min: 300,
                        max: 850,
                        activeColor: const Color(0xFF15803D),
                        inactiveColor: borderCol,
                        onChanged: (val) {
                          setState(() => _score = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Home Price (\$)', _homePriceController, errorText: _errors['price']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Bankruptcy?',
                              value: _bankruptcy,
                              items: const [
                                DropdownMenuItem(value: 'no', child: Text('No')),
                                DropdownMenuItem(value: 'ch7', child: Text('Ch. 7 (2+ yrs ago)')),
                                DropdownMenuItem(value: 'ch13', child: Text('Ch. 13 (1+ yr, on-time)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _bankruptcy = val);
                                }
                              },
                            ),
                          ),
                        ],
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
                            '💳 Check My Eligibility',
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
                                    'Inputs have changed. Tap "Check My Eligibility" to update results.',
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isEligible
                            ? [const Color(0xFF0B1D3A), const Color(0xFF15803D)]
                            : [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEligible ? '✅ You\'re Eligible!' : '❌ Not Currently Eligible',
                            style: AppTextStyles.dmSans(
                                size: 17, color: Colors.white, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(_resultText,
                            style: AppTextStyles.dmSans(
                                size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _buildResultItemCardStr('Min. Down Payment', _isEligible ? '${(_downPct * 100).toStringAsFixed(1)}%' : 'N/A'),
                            _buildResultItemCardStr('Down Payment \$', _isEligible ? CurrencyFormatter.format(_downAmt, symbol: '\$').split('.').first : 'N/A'),
                            _buildResultItemCardStr('Loan Amount Needed', _isEligible ? CurrencyFormatter.format(_loanAmt, symbol: '\$').split('.').first : 'N/A'),
                            _buildResultItemCardStr('Lender Overlay Risk', _overlayRisk),
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
                              '🔖 Save This Check',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Why Lenders Set Higher Minimums'),

                // Distribution Chart Card
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
                      Text('📈 Where Most Approved Lenders Set Their Floor',
                          style: AppTextStyles.dmSans(
                              size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildChartBar('FHA Statutory Minimum', '500 (10% down)', 0.59, [Colors.grey.shade400, Colors.grey.shade600]),
                      const SizedBox(height: 10),
                      _buildChartBar('FHA Standard Minimum', '580 (3.5% down)', 0.68, [const Color(0xFFD97706), const Color(0xFFB45309)]),
                      const SizedBox(height: 10),
                      _buildChartBar('Most Common Lender Overlay', '620', 0.73, [const Color(0xFF1B3F72), const Color(0xFF0B1D3A)]),
                      const SizedBox(height: 10),
                      _buildChartBar('Best Rate Tier', '680+', 0.80, [const Color(0xFF15803D), const Color(0xFF166534)]),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Improve Your Approval Odds'),

                // Improvement Tips List
                Column(
                  children: [
                    _buildTipCard('📉', 'Lower Credit Utilization', 'Keep balances under 30% of credit limits', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildTipCard('⏱️', 'Wait Out Recent Late Payments', 'Late payments hurt score most in last 12 months', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildTipCard('🤝', 'Add a Co-Borrower', 'Combine credit profiles for stronger approval', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildTipCard('🏦', 'Shop Multiple FHA Lenders', 'Overlays vary — some accept 580, others need 620+', cardBg, textCol, mutedCol, borderCol),
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
                color: isDark ? const Color(0xFF5D4017) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF166534),
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

  Widget _buildTierBox(String label, String value, {bool isGold = false, bool isRed = false}) {
    Color valColor = Colors.white;
    if (isGold) valColor = const Color(0xFFFCD34D);
    if (isRed) valColor = const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: valColor,
                  weight: FontWeight.w800),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color dotColor, String range, String detail, String? downText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(range, style: AppTextStyles.dmSans(size: 11, color: _theme.getTextColor(context), weight: FontWeight.w700)),
                Text(detail, style: AppTextStyles.dmSans(size: 9, color: _theme.getMutedColor(context))),
              ],
            ),
          ),
          if (downText != null)
            Text(downText, style: AppTextStyles.dmSans(size: 11, color: const Color(0xFF15803D), weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? errorText}) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: hasError ? Colors.red : _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : _theme.getBorderColor(context),
              width: 1.5,
            ),
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
                size: 12,
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
                  size: 11.5,
                  color: Colors.white,
                  weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, String limit, double fillFactor, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: _theme.getTextColor(context))),
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
                  limit.substring(0, 3),
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(
    String emoji,
    String title,
    String sub,
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
        ],
      ),
    );
  }
}
