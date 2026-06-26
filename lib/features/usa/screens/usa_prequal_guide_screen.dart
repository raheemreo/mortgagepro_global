// lib/features/usa/screens/usa_prequal_guide_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../core/utils/currency_formatter.dart';

class USAMortgagePrequalGuideScreen extends ConsumerStatefulWidget {
  const USAMortgagePrequalGuideScreen({super.key});

  @override
  ConsumerState<USAMortgagePrequalGuideScreen> createState() => _USAMortgagePrequalGuideScreenState();
}

class _USAMortgagePrequalGuideScreenState extends ConsumerState<USAMortgagePrequalGuideScreen> {
  static const _theme = CountryThemes.usa;

  final _incomeCtrl = TextEditingController(text: '85000');
  final _debtsCtrl = TextEditingController(text: '500');
  final _downCtrl = TextEditingController(text: '60000');

  String _creditScore = '740';

  bool _calculated = false;

  // Outputs
  double _maxPrice = 0;
  double _monthlyPmt = 0;
  double _dti = 0;

  // Checklist items
  final List<String> _checklistKeys = [
    'doc_w2', 'doc_paystubs', 'doc_taxreturns', 'doc_1099',
    'doc_bankstatements', 'doc_investments', 'doc_giftletter',
    'doc_photoid', 'doc_ssn', 'doc_purchaseagreement'
  ];

  final Map<String, bool> _checklistState = {};

  @override
  void initState() {
    super.initState();
    for (var key in _checklistKeys) {
      _checklistState[key] = false;
    }
    _loadChecklistProgress();
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _debtsCtrl.dispose();
    _downCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChecklistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        for (var key in _checklistKeys) {
          _checklistState[key] = prefs.getBool(key) ?? false;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveChecklistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var key in _checklistKeys) {
        await prefs.setBool(key, _checklistState[key] ?? false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Checklist progress saved locally!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  void _calculate() {
    final income = double.tryParse(_incomeCtrl.text) ?? 85000;
    final debts = double.tryParse(_debtsCtrl.text) ?? 500;
    final down = double.tryParse(_downCtrl.text) ?? 60000;
    final credit = double.tryParse(_creditScore) ?? 740;

    final monthlyIncome = income / 12;
    
    final m30Val = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    // Rate mapping
    final Map<double, double> rateMap = {
      760: m30Val,
      740: m30Val + 0.23,
      720: m30Val + 0.53,
      700: m30Val + 0.53,
      680: m30Val + 0.78,
      660: m30Val + 0.98,
      640: m30Val + 1.28,
      620: m30Val + 1.58,
    };
    final ratePercent = rateMap[credit] ?? 7.5;
    final monthlyRate = ratePercent / 100 / 12;

    final maxHousingDTI = monthlyIncome * 0.28;
    final maxBackDTI = monthlyIncome * 0.43;

    final availableForHousing = math.min(maxHousingDTI, maxBackDTI - debts);
    const n = 360;

    double maxLoan = 0;
    if (monthlyRate > 0) {
      maxLoan = availableForHousing * (math.pow(1 + monthlyRate, n) - 1) / (monthlyRate * math.pow(1 + monthlyRate, n));
    } else {
      maxLoan = availableForHousing * n;
    }

    final maxPrice = maxLoan + down;
    final actualLoan = maxLoan;

    double monthlyPmt = 0;
    if (monthlyRate > 0) {
      monthlyPmt = actualLoan * monthlyRate * math.pow(1 + monthlyRate, n) / (math.pow(1 + monthlyRate, n) - 1);
    } else {
      monthlyPmt = actualLoan / n;
    }

    final totalMonthlyDebt = monthlyPmt + debts;
    final dti = (totalMonthlyDebt / monthlyIncome) * 100;

    setState(() {
      _maxPrice = maxPrice;
      _monthlyPmt = monthlyPmt;
      _dti = dti;
      _calculated = true;
    });
  }

  void _saveCalculation() {
    if (!_calculated) return;
    final income = double.tryParse(_incomeCtrl.text) ?? 85000;
    final debts = double.tryParse(_debtsCtrl.text) ?? 500;
    final down = double.tryParse(_downCtrl.text) ?? 60000;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Prequalification',
      label: 'Pre-Qual · ${CurrencyFormatter.compact(_maxPrice)}',
      currencyCode: 'USD',
      inputs: {
        'income': income,
        'debts': debts,
        'down': down,
        'credit': double.tryParse(_creditScore) ?? 740.0,
      },
      results: {
        'Max Home Price': _maxPrice,
        'Monthly Payment': _monthlyPmt,
        'DTI Ratio': _dti,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Pre-Qualification results saved to bookmarks!'),
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

    final mortgage30Async = ref.watch(fredMortgage30Provider);
    final mortgage15Async = ref.watch(fredMortgage15Provider);
    final sofrAsync = ref.watch(fredSofrProvider);
    final fedFundsAsync = ref.watch(fredFedFundsProvider);

    final m30Val = mortgage30Async.valueOrNull?.value ?? 6.82;
    final m15Val = mortgage15Async.valueOrNull?.value ?? 6.11;
    final sofrVal = sofrAsync.valueOrNull?.value ?? 5.33;
    final fedFundsVal = fedFundsAsync.valueOrNull?.value ?? 5.33;

    final checkedCount = _checklistState.values.where((v) => v).length;
    final totalDocs = _checklistKeys.length;
    final progressPct = checkedCount / totalDocs;

    // Gauge marker coordinate calculation
    final gaugePos = (_dti / 50.0).clamp(0.05, 0.95);

    return Scaffold(
      backgroundColor: bgCol,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(gradient: _theme.headerGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🦅', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('Prequalification Guide', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('Pre-Qual · Pre-Approval · Documents · DTI', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _theme.primaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStripItem('30-Yr Fixed', '${m30Val.toStringAsFixed(2)}%', mortgage30Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Freddie Mac', textCol),
                      _buildStripItem('15-Yr Fixed', '${m15Val.toStringAsFixed(2)}%', mortgage15Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Avg', textCol),
                      _buildStripItem('5/1 ARM', '${(sofrVal + 0.72).toStringAsFixed(2)}%', sofrAsync.valueOrNull?.isLive == true ? 'FRED SOFR' : 'Avg', textCol),
                      _buildStripItem('Fed Rate', '${fedFundsVal.toStringAsFixed(2)}%', fedFundsAsync.valueOrNull?.isLive == true ? 'FRED Live' : 'FOMC', Colors.amber),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Instant Eligibility Calculator Card
                    _buildSectionHeader('Quick Eligibility Check', 'Buying Power', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MORTGAGE PRE-QUALIFICATION · 2025', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text('Estimate Your Buying Power in 60 Seconds', style: AppTextStyles.playfair(color: Colors.white, size: 15, weight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildHeroField('Annual Income (\$)', _incomeCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildHeroField('Monthly Debts (\$)', _debtsCtrl)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CREDIT SCORE', style: TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _creditScore,
                                          dropdownColor: const Color(0xFF0B1D3A),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          items: const [
                                            DropdownMenuItem(value: '760', child: Text('760+ Excellent')),
                                            DropdownMenuItem(value: '740', child: Text('740–759 V.Good')),
                                            DropdownMenuItem(value: '720', child: Text('720–739 Good')),
                                            DropdownMenuItem(value: '700', child: Text('700–719 Fair-Good')),
                                            DropdownMenuItem(value: '680', child: Text('680–699 Fair')),
                                            DropdownMenuItem(value: '660', child: Text('660–679 Below Avg')),
                                            DropdownMenuItem(value: '640', child: Text('640–659 Poor')),
                                            DropdownMenuItem(value: '620', child: Text('620–639 Minimum')),
                                          ],
                                          onChanged: (val) => setState(() => _creditScore = val ?? '740'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: _buildHeroField('Down Payment (\$)', _downCtrl)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB91C1C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: Text('🦅 Check My Eligibility →', style: AppTextStyles.dmSans(weight: FontWeight.bold, size: 13, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Result Card
                    if (_calculated) ...[
                      const SizedBox(height: 12),
                      Container(
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
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: _dti > 45 ? Colors.red.withValues(alpha: 0.1) : _dti > 36 ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(_dti > 45 ? '❌' : _dti > 36 ? '⚠️' : '✅', style: const TextStyle(fontSize: 22)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dti > 45 ? 'High Debt Risk' : _dti > 36 ? 'Caution Eligible' : 'Likely Eligible',
                                        style: TextStyle(
                                          color: _dti > 45 ? Colors.red : _dti > 36 ? Colors.orange : Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('You may qualify for a mortgage!', style: AppTextStyles.playfair(size: 14, weight: FontWeight.bold, color: textCol)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.5,
                              children: [
                                _buildResultBox('Max Home Price', CurrencyFormatter.format(_maxPrice, decimalDigits: 0)),
                                _buildResultBox('Est. Monthly Pmt', '${CurrencyFormatter.format(_monthlyPmt, decimalDigits: 0)}/mo'),
                                _buildResultBox('Your DTI Ratio', '${_dti.toStringAsFixed(0)}%'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // DTI risk gauge indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('High Risk', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                                    Text('Good DTI', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                    Text('Excellent', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.red, Colors.orange, Colors.green]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final offset = constraints.maxWidth * gaugePos;
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Positioned(
                                                  left: offset - 9,
                                                  top: -4,
                                                  child: Container(
                                                    width: 18, height: 18,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: const Color(0xFF0B1D3A), width: 3),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveCalculation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                                child: Text('💾 Save My Pre-Qual Result', style: AppTextStyles.dmSans(weight: FontWeight.bold, size: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Pre-Qual vs Pre-Approval comparison
                    _buildSectionHeader('Pre-Qual vs Pre-Approval', 'Key Diff', mutedCol),
                    Row(
                      children: [
                        _buildCmpCard(
                          '🔍', 'Step 1', 'Pre-Qualification',
                          ['Self-reported income', 'Soft credit pull only', 'No documents needed', 'Estimate only', 'Free & instant'],
                          '⏱ 5–15 Minutes',
                          const Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 10),
                        _buildCmpCard(
                          '✅', 'Step 2 — Stronger', 'Pre-Approval',
                          ['Verified income & assets', 'Hard credit pull (−5 pts)', 'Full docs required', 'Conditional commitment', 'Preferred by sellers'],
                          '⏱ 1–3 Business Days',
                          const Color(0xFF1B3F72),
                        ),
                      ],
                    ),

                    // Pre-Approval steps process stepper
                    _buildSectionHeader('Pre-Approval Steps', 'Full Process', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          _buildStepItem(
                            1, 'Check Your Credit Score',
                            'Pull your free credit report from AnnualCreditReport.com. Dispute any errors — they can take 30 days to resolve and impact your rate significantly.',
                            ['FICO Score', 'Credit Report', 'Dispute Letters'],
                            '⏱ Do this 3–6 months before buying',
                            isDone: true,
                          ),
                          _buildStepItem(
                            2, 'Calculate Your DTI Ratio',
                            'Add up all monthly debt payments (car, student loans, credit cards). Divide by gross monthly income. Lenders want front-end ≤28% and back-end ≤36–43%.',
                            ['Pay Stubs', 'Loan Statements'],
                            '⏱ Calculate before applying',
                            isActive: true,
                          ),
                          _buildStepItem(
                            3, 'Gather Required Documents',
                            'Collect W-2s (2 years), pay stubs (30 days), bank statements (2–3 months), tax returns, and government-issued ID. Self-employed need 2 years of tax returns + P&L statements.',
                            ['W-2 (2 yrs)', 'Pay Stubs', 'Bank Stmts', 'Tax Returns'],
                            '⏱ Takes 1–2 weeks to gather',
                          ),
                          _buildStepItem(
                            4, 'Submit Application to Lender',
                            'Apply to 3–5 lenders within a 14-day window — multiple hard inquiries in this period count as just ONE on your credit score (FICO rate-shopping window).',
                            ['Uniform Residential Loan App', '1003 Form'],
                            '⏱ 14-day rate shopping window',
                          ),
                          _buildStepItem(
                            5, 'Receive Pre-Approval Letter',
                            'Valid typically 60–90 days. Shows sellers you\'re a serious buyer. Maximum loan amount, rate estimate, and conditions will be listed. Don\'t make large purchases now!',
                            ['Pre-Approval Letter', 'Loan Estimate (LE)'],
                            '⏱ Valid 60–90 days',
                          ),
                        ],
                      ),
                    ),

                    // Credit Score Rates impact guide
                    _buildSectionHeader('Credit Score → Rate Impact', 'FICO Guide', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          _buildCreditRow('760–850 · Exceptional', 1.0, Colors.green, 'Excellent', '${m30Val.toStringAsFixed(2)}%'),
                          _buildCreditRow('720–759 · Very Good', 0.85, Colors.teal, 'Very Good', '${(m30Val + 0.23).toStringAsFixed(2)}%'),
                          _buildCreditRow('680–719 · Good', 0.68, Colors.blue, 'Good', '${(m30Val + 0.53).toStringAsFixed(2)}%'),
                          _buildCreditRow('640–679 · Fair', 0.48, Colors.orange, 'Fair', '${(m30Val + 0.98).toStringAsFixed(2)}%'),
                          _buildCreditRow('620–639 · Poor (Min)', 0.28, Colors.red, 'Min. FHA', '${(m30Val + 1.58).toStringAsFixed(2)}%'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '📌 760 vs 620 score difference = ~\$${(((400000 * (m30Val + 1.58) / 100 / 12) / (1 - math.pow(1 + (m30Val + 1.58) / 100 / 12, -360))) - ((400000 * m30Val / 100 / 12) / (1 - math.pow(1 + m30Val / 100 / 12, -360)))).toStringAsFixed(0)}/mo more on a \$400K loan (30-yr fixed)',
                              style: const TextStyle(fontSize: 9.5, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // DTI guide card
                    _buildSectionHeader('DTI Ratio Guide', '28/36 Rule', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Debt-to-Income Ratio Zones', style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          // Custom DTI range bar
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.green, Colors.orange, Colors.red, Color(0xFF7F1D1D)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Excellent <28%', style: TextStyle(fontSize: 8.5, color: Colors.green, fontWeight: FontWeight.bold)),
                              Text('Caution 36–43%', style: TextStyle(fontSize: 8.5, color: Colors.orange, fontWeight: FontWeight.bold)),
                              Text('Risky >50%', style: TextStyle(fontSize: 8.5, color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildDtiRuleBox('28%', 'Front-End Max\n(Housing only)', const Color(0xFFEFF6FF)),
                              const SizedBox(width: 7),
                              _buildDtiRuleBox('36%', 'Back-End Ideal\n(All debts)', const Color(0xFFFEF3C7)),
                              const SizedBox(width: 7),
                              _buildDtiRuleBox('43%', 'Max Conventional\n(QM Rule)', const Color(0xFFF0FDF4)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Document checklist
                    _buildSectionHeader('Document Checklist', 'Interactive', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Documents Ready', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('$checkedCount / $totalDocs', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(20)),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progressPct.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreenAccent]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('📋 INCOME VERIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          _buildDocCheckItem('W-2 Forms (last 2 years)', 'doc_w2', isRequired: true),
                          _buildDocCheckItem('Recent Pay Stubs (30 days)', 'doc_paystubs', isRequired: true),
                          _buildDocCheckItem('Federal Tax Returns (2 yrs)', 'doc_taxreturns', isRequired: true),
                          _buildDocCheckItem('1099 / Self-Employment P&L', 'doc_1099'),

                          const SizedBox(height: 12),
                          const Text('🏦 ASSETS & ACCOUNTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          _buildDocCheckItem('Bank Statements (2–3 months)', 'doc_bankstatements', isRequired: true),
                          _buildDocCheckItem('Investment / Retirement Accounts', 'doc_investments'),
                          _buildDocCheckItem('Gift Letter (if down pmt gifted)', 'doc_giftletter'),

                          const SizedBox(height: 12),
                          const Text('🪪 IDENTITY & PROPERTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          _buildDocCheckItem('Government-Issued Photo ID', 'doc_photoid', isRequired: true),
                          _buildDocCheckItem('Social Security Number', 'doc_ssn', isRequired: true),
                          _buildDocCheckItem('Purchase Agreement (if available)', 'doc_purchaseagreement'),

                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveChecklistProgress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              child: Text('💾 Save My Checklist Progress', style: AppTextStyles.dmSans(weight: FontWeight.bold, size: 12, color: Colors.white)),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 1,
              activeColor: _theme.primaryColor,
              countryIcon: _theme.flag,
              countryLabel: 'USA',
              countryRoute: '/usa',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String val, String note, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.white54, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: color)),
        Text(note, style: const TextStyle(fontSize: 7.5, color: Colors.white38)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String tagText, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: labelColor, letterSpacing: 0.8)),
          if (tagText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCmpCard(String emoji, String stepTag, String title, List<String> bulletPoints, String duration, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bg, bg.withValues(alpha: 0.85)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(stepTag, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(title, style: AppTextStyles.playfair(color: Colors.white, size: 12.5, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bulletPoints.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.amber, fontSize: 10)),
                      Expanded(child: Text(b, style: const TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.3))),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(duration, style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int num, String title, String desc, List<String> docs, String timeLabel, {bool isDone = false, bool isActive = false}) {
    final numGrad = isDone
        ? const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)])
        : isActive
            ? const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)])
            : const LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)]);

    final themeTxtCol = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1D3A);
    final themeMuted = Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF4A5C7A);
    final borderCol = _theme.getBorderColor(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(gradient: numGrad, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text('$num', style: AppTextStyles.dmSans(color: Colors.white, size: 13, weight: FontWeight.bold)),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFF1B3F72), const Color(0xFF1B3F72).withValues(alpha: 0.1)],
                    ),
                  ),
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
                  Text(title, style: AppTextStyles.playfair(size: 12.5, color: themeTxtCol, weight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(desc, style: TextStyle(fontSize: 9.5, color: themeMuted, height: 1.5)),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: docs.map((d) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _theme.getBgColor(context),
                          border: Border.all(color: borderCol),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(d, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: themeTxtCol)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 5),
                  Text(timeLabel, style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditRow(String range, double pct, Color color, String lbl, String rate) {
    final themeTxtCol = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1D3A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(range, style: AppTextStyles.playfair(size: 10, color: themeTxtCol, weight: FontWeight.bold)),
                const SizedBox(height: 3),
                Container(
                  height: 7,
                  width: double.infinity,
                  decoration: BoxDecoration(color: _theme.getBgColor(context), borderRadius: BorderRadius.circular(20)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(lbl, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          const SizedBox(width: 8),
          SizedBox(width: 42, child: Text(rate, style: AppTextStyles.playfair(size: 11, color: themeTxtCol, weight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildDtiRuleBox(String val, String lbl, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Column(
          children: [
            Text(val, style: AppTextStyles.dmSans(size: 18, weight: FontWeight.bold, color: const Color(0xFF0B1D3A))),
            const SizedBox(height: 2),
            Text(lbl, style: const TextStyle(fontSize: 8.5, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCheckItem(String label, String key, {bool isRequired = false}) {
    final active = _checklistState[key] ?? false;
    final themeTxtCol = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1D3A);
    final borderCol = _theme.getBorderColor(context);

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _checklistState[key] = !active;
              });
            },
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]) : null,
                color: active ? null : _theme.getBgColor(context),
                border: Border.all(color: active ? Colors.green : borderCol, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: active ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: AppTextStyles.dmSans(size: 11, color: themeTxtCol, weight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isRequired ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isRequired ? 'Required' : 'If Applicable',
              style: TextStyle(color: isRequired ? Colors.red : Colors.orange, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
