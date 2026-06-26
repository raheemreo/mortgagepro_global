// lib/features/usa/screens/usa_usda_rural_development_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/bottom_nav.dart';

class USAUsdaRuralDevelopmentScreen extends ConsumerStatefulWidget {
  const USAUsdaRuralDevelopmentScreen({super.key});

  @override
  ConsumerState<USAUsdaRuralDevelopmentScreen> createState() => _USAUsdaRuralDevelopmentScreenState();
}

class _USAUsdaRuralDevelopmentScreenState extends ConsumerState<USAUsdaRuralDevelopmentScreen> {
  static const _theme = CountryThemes.usa;

  final _homePriceController = TextEditingController(text: '280000');
  final _incomeController = TextEditingController(text: '72000');
  final _debtsController = TextEditingController(text: '500');

  String _currentProg = 'guar';
  int _householdSize = 4;
  String _state = 'GA';
  String _creditScore = '680';

  bool _calculated = false;

  // Outputs
  double _loanAmt = 0;
  double _totalMonthly = 0;
  double _upfrontFee = 0;
  double _annualFeeMonthly = 0;
  double _frontDTI = 0;
  double _backDTI = 0;
  double _incomeLimit = 0;
  bool _incomeEligible = false;
  String _eligibilityResult = '';

  // Comparisons for chart
  double _fhaMonthly = 0;
  double _convMonthly = 0;

  static const Map<String, double> _progRates = {'direct': 0.04875, 'guar': 0.0635};
  static const Map<String, Map<String, double>> _progFees = {
    'direct': {'upfront': 0.0, 'annual': 0.0},
    'guar': {'upfront': 0.01, 'annual': 0.0035}
  };

  // 2025 USDA 115% typical income limits by HH size
  static const Map<int, double> _amiLimits = {
    1: 92200, 2: 105400, 3: 118550, 4: 131700, 5: 142250, 6: 152800
  };

  @override
  void dispose() {
    _homePriceController.dispose();
    _incomeController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final price = double.tryParse(_homePriceController.text) ?? 280000;
    final income = double.tryParse(_incomeController.text) ?? 72000;
    final debts = double.tryParse(_debtsController.text) ?? 500;

    final rate = _progRates[_currentProg] ?? 0.0635;
    final fees = _progFees[_currentProg] ?? {'upfront': 0.01, 'annual': 0.0035};
    const n = 360;
    final mr = rate / 12;

    final upfrontFee = price * fees['upfront']!;
    final loanAmt = price + upfrontFee;

    double basePayment = 0;
    if (mr > 0) {
      basePayment = loanAmt * (mr * math.pow(1 + mr, n)) / (math.pow(1 + mr, n) - 1);
    } else {
      basePayment = loanAmt / n;
    }
    final annualFeeMonthly = (price * fees['annual']!) / 12;
    final totalMonthly = basePayment + annualFeeMonthly;

    final monthlyIncome = income / 12;
    final frontDTI = monthlyIncome > 0 ? (totalMonthly / monthlyIncome * 100) : 0.0;
    final backDTI = monthlyIncome > 0 ? ((totalMonthly + debts) / monthlyIncome * 100) : 0.0;

    // Income limit check
    double limit = 0;
    if (_currentProg == 'direct') {
      limit = _householdSize <= 4 ? 90300.0 : 119200.0;
    } else {
      limit = _amiLimits[_householdSize] ?? 131700.0;
    }
    final incomeEligible = income <= limit;

    // Eligibility check
    String eligibilityResult = '';
    final frontOK = frontDTI <= 29;
    final backOK = backDTI <= 41;

    if (incomeEligible && frontOK && backOK) {
      eligibilityResult = '✅ Likely Eligible — meets income, front & back DTI limits';
    } else if (!incomeEligible) {
      eligibilityResult = '❌ Income exceeds the USDA program limit for household size';
    } else if (!frontOK) {
      eligibilityResult = '⚠️ Front-end DTI exceeds 29% USDA guideline';
    } else {
      eligibilityResult = '⚠️ Back-end DTI exceeds 41% USDA guideline';
    }

    // Chart Comparison Calcs
    // FHA monthly: 3.5% down, 6.52% rate + MIP (0.85%)
    final fhaDown = price * 0.035;
    final fhaLoan = price - fhaDown;
    const fhaMr = 0.0652 / 12;
    final fhaBase = fhaLoan * (fhaMr * math.pow(1 + fhaMr, n)) / (math.pow(1 + fhaMr, n) - 1);
    final fhaMIP = fhaLoan * 0.0085 / 12;
    final fhaMonthly = fhaBase + fhaMIP;

    // Conv monthly: 5% down, 6.82% rate + PMI (0.8%)
    final convDown = price * 0.05;
    final convLoan = price - convDown;
    const convMr = 0.0682 / 12;
    final convBase = convLoan * (convMr * math.pow(1 + convMr, n)) / (math.pow(1 + convMr, n) - 1);
    final convPMI = convLoan * 0.008 / 12;
    final convMonthly = convBase + convPMI;

    setState(() {
      _loanAmt = loanAmt;
      _totalMonthly = totalMonthly;
      _upfrontFee = upfrontFee;
      _annualFeeMonthly = annualFeeMonthly;
      _frontDTI = frontDTI;
      _backDTI = backDTI;
      _incomeLimit = limit;
      _incomeEligible = incomeEligible;
      _eligibilityResult = eligibilityResult;
      _fhaMonthly = fhaMonthly;
      _convMonthly = convMonthly;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;
    final price = double.tryParse(_homePriceController.text) ?? 280000;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'USDA Rural Development',
      label: 'USDA ${_currentProg == 'direct' ? 'Direct' : 'Guaranteed'} · ${CurrencyFormatter.compact(price)}',
      currencyCode: 'USD',
      inputs: {
        'price': price,
        'income': double.tryParse(_incomeController.text) ?? 72000,
        'hhsize': _householdSize.toDouble(),
      },
      results: {
        'Loan Amount': _loanAmt,
        'Monthly Payment': _totalMonthly,
        'Front DTI': _frontDTI,
        'Back DTI': _backDTI,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ USDA Rural Development calculation saved!'),
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

    final saves = ref.watch(savedProvider).where(
      (c) => c.country.toLowerCase() == 'usa' && c.calcType == 'USDA Rural Development'
    ).toList();

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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF166534), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌾', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('USDA Rural Development', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('502 Direct · 502 Guaranteed · 0% Down · 2025', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRateItem('Direct Rate', '4.875%', '502 Direct', Colors.green),
                      _buildRateItem('Guar. Rate', '6.35%', 'Avg 2025', textCol),
                      _buildRateItem('Down Pmt', '0%', 'Both Prog.', Colors.orange),
                      _buildRateItem('Guar. Fee', '1.0%', 'Upfront', textCol),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero
                    _buildSectionHeader('USDA Programs', '0% Down', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1D3A), Color(0xFF166534)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('U.S. Dept. of Agriculture · Rural Housing · 2025', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text('Zero Down Payment\nfor Rural & Suburban Buyers', style: AppTextStyles.playfair(color: Colors.white, size: 16, weight: FontWeight.bold, height: 1.25)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSnapshotBox('Down Pmt', r'$0', const Color(0xFFFCD34D)),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('Max Area', '35K Pop', Colors.white),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('Income Lim.', '115% AMI', Colors.white),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('Fees', '1% + 0.35%', const Color(0xFFFCD34D)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Program selector toggle
                    _buildSectionHeader('Select Program', 'Compare Both', mutedCol),
                    _buildProgramSelector(cardBg, textCol, mutedCol, borderCol),

                    // Calculator Card
                    _buildSectionHeader('USDA Loan & Eligibility Calculator', '', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderCol),
                        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(9)),
                                alignment: Alignment.center,
                                child: const Text('🌾'),
                              ),
                              const SizedBox(width: 8),
                              Text('USDA Loan & Eligibility Calculator', style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInputField('Home Price (\$)', _homePriceController)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('Annual Income (\$)', _incomeController)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField('Household Size', _householdSize, [
                                  const DropdownMenuItem(value: 1, child: Text('1 Person')),
                                  const DropdownMenuItem(value: 2, child: Text('2 People')),
                                  const DropdownMenuItem(value: 3, child: Text('3 People')),
                                  const DropdownMenuItem(value: 4, child: Text('4 People')),
                                  const DropdownMenuItem(value: 5, child: Text('5 People')),
                                  const DropdownMenuItem(value: 6, child: Text('6+ People')),
                                ], (val) => setState(() => _householdSize = val!)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField('State / Region', _state, [
                                  const DropdownMenuItem(value: 'AL', child: Text('Alabama')),
                                  const DropdownMenuItem(value: 'AR', child: Text('Arkansas')),
                                  const DropdownMenuItem(value: 'GA', child: Text('Georgia')),
                                  const DropdownMenuItem(value: 'IA', child: Text('Iowa')),
                                  const DropdownMenuItem(value: 'KS', child: Text('Kansas')),
                                  const DropdownMenuItem(value: 'KY', child: Text('Kentucky')),
                                  const DropdownMenuItem(value: 'MI', child: Text('Michigan')),
                                  const DropdownMenuItem(value: 'MN', child: Text('Minnesota')),
                                  const DropdownMenuItem(value: 'MO', child: Text('Missouri')),
                                  const DropdownMenuItem(value: 'MS', child: Text('Mississippi')),
                                  const DropdownMenuItem(value: 'NC', child: Text('North Carolina')),
                                  const DropdownMenuItem(value: 'ND', child: Text('North Dakota')),
                                  const DropdownMenuItem(value: 'NE', child: Text('Nebraska')),
                                  const DropdownMenuItem(value: 'OH', child: Text('Ohio')),
                                  const DropdownMenuItem(value: 'OK', child: Text('Oklahoma')),
                                  const DropdownMenuItem(value: 'SD', child: Text('South Dakota')),
                                  const DropdownMenuItem(value: 'TN', child: Text('Tennessee')),
                                  const DropdownMenuItem(value: 'TX', child: Text('Texas')),
                                  const DropdownMenuItem(value: 'WI', child: Text('Wisconsin')),
                                  const DropdownMenuItem(value: 'WV', child: Text('West Virginia')),
                                ], (val) => setState(() => _state = val!)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildInputField('Monthly Debts (\$)', _debtsController)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField('Credit Score', _creditScore, [
                                  const DropdownMenuItem(value: '760', child: Text('760+ Excellent')),
                                  const DropdownMenuItem(value: '720', child: Text('720–759 V.Good')),
                                  const DropdownMenuItem(value: '680', child: Text('680–719 Good')),
                                  const DropdownMenuItem(value: '640', child: Text('640–679 Fair')),
                                ], (val) => setState(() => _creditScore = val!)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Calculate USDA Loan', style: AppTextStyles.dmSans(size: 14, weight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),

                          // Calculation results
                          if (_calculated) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF166534)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentProg == 'direct' ? '🏛️ USDA 502 Direct · 2025' : '🌾 USDA 502 Guaranteed · 2025',
                                    style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 2.2,
                                    children: [
                                      _buildResultBoxItem('Loan Amount', CurrencyFormatter.format(_loanAmt, symbol: r'$'), const Color(0xFFFCD34D)),
                                      _buildResultBoxItem('Monthly Payment', '${CurrencyFormatter.format(_totalMonthly, symbol: r'$')}/mo', Colors.white),
                                      _buildResultBoxItem('Guarantee Fee (1%)', _currentProg == 'direct' ? 'None' : '${CurrencyFormatter.format(_upfrontFee, symbol: r'$')} (rolled in)', Colors.white),
                                      _buildResultBoxItem('Annual Fee (0.35%)', _currentProg == 'direct' ? 'None' : '${CurrencyFormatter.format(_annualFeeMonthly, symbol: r'$')}/mo', Colors.white),
                                      _buildResultBoxItem('Front DTI', '${_frontDTI.toStringAsFixed(1)}% (limit 29%)', Colors.white),
                                      _buildResultBoxItem('Back-End DTI', '${_backDTI.toStringAsFixed(1)}% (limit 41%)', Colors.white),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Income Limit Check (115% AMI)', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                                        Text(
                                          _incomeEligible
                                              ? '✅ \$${(double.tryParse(_incomeController.text) ?? 72000).toStringAsFixed(0)} ≤ \$${_incomeLimit.toStringAsFixed(0)} limit'
                                              : '❌ \$${(double.tryParse(_incomeController.text) ?? 72000).toStringAsFixed(0)} > \$${_incomeLimit.toStringAsFixed(0)} limit',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), border: Border.all(color: Colors.green.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('✅ Program Eligibility Assessment', style: TextStyle(fontSize: 9, color: Colors.white60)),
                                        const SizedBox(height: 2),
                                        Text(_eligibilityResult, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: const Color(0xFF6EE7B7))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _saveCalc,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF15803D),
                                  side: const BorderSide(color: Color(0xFF15803D), width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Save This Calculation', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bar Chart: USDA vs FHA vs Conventional monthly cost
                    if (_calculated) ...[
                      _buildSectionHeader('USDA vs FHA vs Conventional · Monthly Cost', '', mutedCol),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          children: [
                            _buildChartBarRow('USDA (0% down)', _totalMonthly, _fhaMonthly, _convMonthly),
                            _buildChartBarRow('FHA (3.5% down)', _fhaMonthly, _fhaMonthly, _convMonthly),
                            _buildChartBarRow('Conv. (5% down)', _convMonthly, _fhaMonthly, _convMonthly),
                          ],
                        ),
                      ),
                    ],

                    // Income Limits Table
                    _buildSectionHeader('2025 USDA Income Limits', 'By Household Size', mutedCol),
                    _buildIncomeLimitsTable(cardBg, textCol, mutedCol, borderCol),

                    // Program Details
                    _buildSectionHeader('Program Details', '2025 Active', mutedCol),
                    _buildInfoItem('🏛️', '502 Direct Loan – USDA as Lender', 'USDA directly lends at 4.875% (2025 rate). Income must be low or very low (50–80% AMI). Payment assistance can reduce rate to as low as 1%. No down payment, no PMI. Max loan based on repayment ability.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🏦', '502 Guaranteed Loan – Private Lender', 'USDA guarantees 90% of loan from approved private lenders. Income ≤ 115% AMI. Rate is market-based (~6.35% in 2025). Upfront fee: 1.0% of loan. Annual fee: 0.35% of outstanding balance.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🗺️', 'Rural Area Definition', 'Property must be in USDA-designated rural area. Generally communities of <35,000 population. Check eligibility at eligibility.sc.egov.usda.gov. Many suburban areas surprisingly qualify.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🔧', '504 Repair Loan & Grant Program', 'For very-low-income homeowners to repair/improve homes. Loan: up to \$40,000 at 1%. Grant: up to \$10,000 for age 62+. Combined max: \$50,000. Must be primary residence, owner-occupied.', cardBg, textCol, mutedCol, borderCol),

                    // Saved list
                    _buildSectionHeader('Saved Calculations', '${saves.length} Saved', mutedCol),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: saves.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(child: Text('No saved calculations yet.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: saves.length,
                              separatorBuilder: (_, __) => Divider(color: borderCol),
                              itemBuilder: (context, idx) {
                                final s = saves[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(s.label, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                                  subtitle: Text(
                                    'Pmt: ${CurrencyFormatter.format(s.results['Monthly Payment'] ?? 0, symbol: r'$')}/mo · DTI: ${(s.results['Front DTI'] ?? 0).toStringAsFixed(1)}%/${(s.results['Back DTI'] ?? 0).toStringAsFixed(1)}%',
                                    style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(s.results['Monthly Payment'] ?? 0, symbol: r'$'),
                                        style: AppTextStyles.dmSans(color: Colors.green, weight: FontWeight.bold, size: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                        onPressed: () => ref.read(savedProvider.notifier).delete(s.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
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

  Widget _buildRateItem(String label, String value, String note, Color valColor) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.white54, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.dmSans(size: 14, weight: FontWeight.bold, color: valColor)),
        Text(note, style: const TextStyle(fontSize: 7.5, color: Colors.white38)),
      ],
    );
  }

  Widget _buildSnapshotBox(String label, String value, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: valColor)),
          ],
        ),
      ),
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
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(20)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
            ),
        ],
      ),
    );
  }

  Widget _buildProgramSelector(Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _currentProg = 'direct'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentProg == 'direct' ? const Color(0xFFF0FDF4) : cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _currentProg == 'direct' ? Colors.green : borderCol, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏛️', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('502 Direct', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                  Text('USDA as lender · Low income', style: TextStyle(fontSize: 9, color: mutedCol)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: const Text('4.875% rate', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _currentProg = 'guar'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentProg == 'guar' ? const Color(0xFFF0FDF4) : cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _currentProg == 'guar' ? Colors.green : borderCol, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏦', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('502 Guaranteed', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                  Text('Private lender · Mod. income', style: TextStyle(fontSize: 9, color: mutedCol)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                    child: const Text('~6.35% rate', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            fillColor: _theme.backgroundColor.withValues(alpha: 0.3),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _theme.getTextColor(context)),
          decoration: InputDecoration(
            fillColor: _theme.backgroundColor.withValues(alpha: 0.3),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBoxItem(String label, String value, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: valColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildChartBarRow(String label, double val, double usda, double conv) {
    final maxVal = math.max(_totalMonthly, math.max(_fhaMonthly, _convMonthly));
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;
    final color = label.contains('USDA') ? Colors.green : (label.contains('FHA') ? Colors.blue : Colors.red);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.only(left: 6),
                    alignment: Alignment.centerLeft,
                    child: pct > 0.15 ? const Text('▐', style: TextStyle(color: Colors.white, fontSize: 8)) : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 65, child: Text('${CurrencyFormatter.format(val, symbol: r'$')}/mo', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildIncomeLimitsTable(Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF166534)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌾 USDA 502 Guaranteed Income Limits · 2025', style: AppTextStyles.playfair(size: 11, color: Colors.white, weight: FontWeight.bold)),
                const Text('Typical rural / low-cost county (115% AMI)', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
              ],
            ),
          ),
          _buildTableLimitsRow('Household Size', 'Income Limit', 'Status', isHeader: true),
          _buildTableLimitsRow('1–4 People', r'$110,650', 'Most counties', isHighlight: true),
          _buildTableLimitsRow('5–8 People', r'$146,050', 'Most counties'),
          _buildTableLimitsRow('High-cost areas', 'Up to \$180K+', 'Some metros', isHighlight: true),
          _buildTableLimitsRow('502 Direct (1–4)', r'$90,300', 'Low Income'),
          _buildTableLimitsRow('502 Direct (5–8)', r'$119,200', 'Low Income', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildTableLimitsRow(String col1, String col2, String col3, {bool isHeader = false, bool isHighlight = false}) {
    final textStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.grey : _theme.getTextColor(context),
    );
    final valStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.bold,
      color: isHeader ? Colors.grey : Colors.green,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isHeader ? _theme.backgroundColor.withValues(alpha: 0.3) : (isHighlight ? const Color(0xFFF0FDF4) : null),
        border: Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(col1, style: textStyle)),
          Expanded(child: Text(col2, style: valStyle, textAlign: TextAlign.center)),
          Expanded(child: Text(col3, style: textStyle, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String title, String desc, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _theme.backgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 9.5, color: mutedCol, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
