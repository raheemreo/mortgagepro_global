// lib/features/usa/screens/usa_first_time_homebuyer_screen.dart

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

class USAFirstTimeHomebuyerScreen extends ConsumerStatefulWidget {
  const USAFirstTimeHomebuyerScreen({super.key});

  @override
  ConsumerState<USAFirstTimeHomebuyerScreen> createState() => _USAFirstTimeHomebuyerScreenState();
}

class _USAFirstTimeHomebuyerScreenState extends ConsumerState<USAFirstTimeHomebuyerScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  final _homePriceController = TextEditingController(text: '350000');
  final _incomeController = TextEditingController(text: '75000');

  String _creditScore = '680';
  String _state = 'GA';
  String _loanType = 'fha';
  int _householdSize = 2;

  bool _calculated = false;

  // Outputs
  double _downReq = 0;
  double _totalDPA = 0;
  double _oop = 0;
  double _totalMonthly = 0;
  double _loanAmt = 0;
  String _progName = '';
  String _amiStatus = '';

  static const Map<String, double> _stateAMI = {
    'CA': 106800, 'TX': 73400, 'FL': 68800, 'NY': 93400, 'IL': 82200,
    'WA': 99600, 'CO': 96000, 'GA': 71200, 'OH': 70000, 'AZ': 78000
  };

  static const Map<String, Map<String, dynamic>> _stateDPA = {
    'CA': {'name': 'CA MyHome', 'amt': 0.035, 'max': 15000.0},
    'TX': {'name': 'TX TDHCA My First Texas', 'amt': 0.05, 'max': 15000.0},
    'FL': {'name': 'FL Assist', 'amt': 10000.0, 'max': 10000.0},
    'NY': {'name': 'NY SONYMA', 'amt': 3000.0, 'max': 3000.0},
    'IL': {'name': 'IL IHDA Access', 'amt': 6000.0, 'max': 6000.0},
    'WA': {'name': 'WA WSHFC Home Advantage', 'amt': 0.04, 'max': 10000.0},
    'CO': {'name': 'CO CHFA', 'amt': 0.03, 'max': 8000.0},
    'GA': {'name': 'GA Dream', 'amt': 7500.0, 'max': 7500.0},
    'OH': {'name': 'OH OHFA', 'amt': 2500.0, 'max': 2500.0},
    'AZ': {'name': 'AZ AZHFC HOME+', 'amt': 0.03, 'max': 9000.0}
  };

  static const _loanDownPct = {'fha': 0.035, 'conv3': 0.03, 'conv5': 0.05};
  static const _loanRates = {'fha': 0.0652, 'conv3': 0.0682, 'conv5': 0.0672};
  static const _mipFactor = {'fha': 0.0085 / 12, 'conv3': 0.007 / 12, 'conv5': 0.005 / 12};

  @override
  void dispose() {
    _homePriceController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final price = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (price <= 0) {
      errors['price'] = 'Enter positive home price';
    }
    if (income <= 0) {
      errors['income'] = 'Enter positive income';
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

    final downPct = _loanDownPct[_loanType] ?? 0.035;
    final rate = _loanRates[_loanType] ?? 0.0652;
    final mip = _mipFactor[_loanType] ?? (0.0085 / 12);

    final downReq = price * downPct;
    final loanAmt = price - downReq;
    final monthlyRate = rate / 12;
    const n = 360;

    double basePayment = 0;
    if (monthlyRate > 0) {
      basePayment = loanAmt * (monthlyRate * math.pow(1 + monthlyRate, n)) / (math.pow(1 + monthlyRate, n) - 1);
    } else {
      basePayment = loanAmt / n;
    }
    final monthlyMIP = loanAmt * mip;
    final totalMonthly = basePayment + monthlyMIP;

    // DPA Calculations
    final dpaInfo = _stateDPA[_state] ?? {'name': 'GA Dream', 'amt': 7500.0, 'max': 7500.0};
    double dpaAmt = 0;
    final dpaVal = dpaInfo['amt'] as double;
    final dpaMax = dpaInfo['max'] as double;

    if (dpaVal < 1.0) {
      dpaAmt = math.min(price * dpaVal, dpaMax);
    } else {
      dpaAmt = dpaMax;
    }

    // Federal DPA Bonus
    final baseAMI = _stateAMI[_state] ?? 71200.0;
    final ami80 = baseAMI * (_householdSize / 4 * 0.5 + 0.75);
    final ami120 = ami80 * 1.5;

    double federalBonus = 0;
    if (income <= ami120) {
      federalBonus = math.min(15000.0, price * 0.05);
    }

    final totalDPA = math.min(dpaAmt + federalBonus, downReq);
    final oop = math.max(0.0, downReq - totalDPA);

    String amiStatus = '';
    if (income <= ami80) {
      amiStatus = '✅ Qualifies for 80% AMI programs';
    } else if (income <= ami120) {
      amiStatus = '⚠️ 80%–120% AMI bracket';
    } else {
      amiStatus = '❌ Above 120% AMI limit';
    }

    setState(() {
      _calcSnapshot['price'] = price;
      _calcSnapshot['income'] = income;
      _calcSnapshot['_creditScore'] = _creditScore;
      _calcSnapshot['_state'] = _state;
      _calcSnapshot['_loanType'] = _loanType;
      _calcSnapshot['_householdSize'] = _householdSize;

      _downReq = downReq;
      _totalDPA = totalDPA;
      _oop = oop;
      _totalMonthly = totalMonthly;
      _loanAmt = loanAmt;
      _progName = dpaInfo['name'] as String;
      _amiStatus = amiStatus;
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
    final income = _calcSnapshot['income'] ?? 75000.0;
    final state = _calcSnapshot['_state'] ?? 'GA';
    final hhsize = (_calcSnapshot['_householdSize'] ?? 2).toDouble();

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'First-Time Homebuyer',
      label: '$state FTB · ${CurrencyFormatter.compact(price)}',
      currencyCode: 'USD',
      inputs: {
        'price': price,
        'income': income,
        'hhsize': hhsize,
      },
      results: {
        'DPA Grant': _totalDPA,
        'Out-of-Pocket': _oop,
        'Monthly Payment': _totalMonthly,
        'Loan Amount': _loanAmt,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ First-Time Homebuyer calculation saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['price'] ?? 0.0) ||
      (double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['income'] ?? 0.0) ||
      _creditScore != (_calcSnapshot['_creditScore'] ?? '680') ||
      _state != (_calcSnapshot['_state'] ?? 'GA') ||
      _loanType != (_calcSnapshot['_loanType'] ?? 'fha') ||
      _householdSize != (_calcSnapshot['_householdSize'] ?? 2)
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    final saves = ref.watch(savedProvider).where(
      (c) => c.country.toLowerCase() == 'usa' && c.calcType == 'First-Time Homebuyer'
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
                    decoration: BoxDecoration(gradient: _theme.headerGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏠', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('First-Time Homebuyer', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('HUD · State DPA · FHA · Grant Programs 2025', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                      _buildRateItem('FHA Rate', '6.52%', 'Avg 2025', Colors.green),
                      _buildRateItem('Min Down', '3.5%', 'FHA 580+', textCol),
                      _buildRateItem('Max DPA', r'$25K', 'Biden Grant', Colors.green),
                      _buildRateItem('Income Lim.', '120% AMI', 'Most States', textCol),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Grant Snapshot Card
                    _buildSectionHeader('Grant Snapshot', '2025 Programs', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('USA First-Time Homebuyer Assistance', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text('Up to \$25,000 in Down\nPayment Assistance Available', style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: Colors.white, height: 1.2)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSnapshotBox('Max Grant', r'$25K', const Color(0xFFFCD34D)),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('Min Credit', '580', Colors.white),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('States w/ DPA', '50', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
 
                     // Eligibility Checklist
                     _buildSectionHeader('Quick Eligibility Check', '', mutedCol),
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         gradient: const LinearGradient(
                           colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                         ),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: const Color(0xFFF59E0B)),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               const Text('✅', style: TextStyle(fontSize: 14)),
                               const SizedBox(width: 6),
                               Text('Common Requirements', style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                             ],
                           ),
                           const SizedBox(height: 10),
                           _buildEligibilityGrid(),
                         ],
                       ),
                     ),
 
                     // Estimator Calculator
                     _buildSectionHeader('Assistance Calculator', 'Estimate', mutedCol),
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
                                 child: const Text('🧮'),
                               ),
                               const SizedBox(width: 8),
                               Text('Down Payment Assistance Estimator', style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold)),
                             ],
                           ),
                           const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildInputField('Home Price (\$)', _homePriceController, errorText: _errors['price'])),
                                const SizedBox(width: 10),
                                Expanded(child: _buildInputField('Annual Income (\$)', _incomeController, errorText: _errors['income'])),
                              ],
                            ),
                           const SizedBox(height: 10),
                           Row(
                             children: [
                               Expanded(
                                 child: _buildDropdownField('Credit Score', _creditScore, [
                                   const DropdownMenuItem(value: '760', child: Text('760+ Excellent')),
                                   const DropdownMenuItem(value: '720', child: Text('720–759 V.Good')),
                                   const DropdownMenuItem(value: '680', child: Text('680–719 Good')),
                                   const DropdownMenuItem(value: '640', child: Text('640–679 Fair')),
                                   const DropdownMenuItem(value: '580', child: Text('580–639 FHA Min')),
                                 ], (val) => setState(() => _creditScore = val!)),
                               ),
                               const SizedBox(width: 10),
                               Expanded(
                                 child: _buildDropdownField('State', _state, [
                                   const DropdownMenuItem(value: 'CA', child: Text('California')),
                                   const DropdownMenuItem(value: 'TX', child: Text('Texas')),
                                   const DropdownMenuItem(value: 'FL', child: Text('Florida')),
                                   const DropdownMenuItem(value: 'NY', child: Text('New York')),
                                   const DropdownMenuItem(value: 'IL', child: Text('Illinois')),
                                   const DropdownMenuItem(value: 'WA', child: Text('Washington')),
                                   const DropdownMenuItem(value: 'CO', child: Text('Colorado')),
                                   const DropdownMenuItem(value: 'GA', child: Text('Georgia')),
                                   const DropdownMenuItem(value: 'OH', child: Text('Ohio')),
                                   const DropdownMenuItem(value: 'AZ', child: Text('Arizona')),
                                 ], (val) => setState(() => _state = val!)),
                               ),
                             ],
                           ),
                           const SizedBox(height: 10),
                           Row(
                             children: [
                               Expanded(
                                 child: _buildDropdownField('Loan Type', _loanType, [
                                   const DropdownMenuItem(value: 'fha', child: Text('FHA (3.5% down)')),
                                   const DropdownMenuItem(value: 'conv3', child: Text('Conv. (3% down)')),
                                   const DropdownMenuItem(value: 'conv5', child: Text('Conv. (5% down)')),
                                 ], (val) => setState(() => _loanType = val!)),
                               ),
                               const SizedBox(width: 10),
                               Expanded(
                                 child: _buildDropdownField('Household Size', _householdSize, [
                                   const DropdownMenuItem(value: 1, child: Text('1 Person')),
                                   const DropdownMenuItem(value: 2, child: Text('2 People')),
                                   const DropdownMenuItem(value: 3, child: Text('3 People')),
                                   const DropdownMenuItem(value: 4, child: Text('4 People')),
                                   const DropdownMenuItem(value: 5, child: Text('5+ People')),
                                 ], (val) => setState(() => _householdSize = val!)),
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
                               child: Text('Calculate My Assistance', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: Colors.white)),
                             ),
                           ),
 
                           // Calculation results
                           if (_calculated) ...[
                             const SizedBox(height: 16),
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
                                               'Inputs have changed. Tap "Calculate My Assistance" to update results.',
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
                               padding: const EdgeInsets.all(14),
                               decoration: BoxDecoration(
                                 gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   const Text('📊 Your Estimated Assistance · 2025', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                                   const SizedBox(height: 10),
                                   GridView.count(
                                     shrinkWrap: true,
                                     physics: const NeverScrollableScrollPhysics(),
                                     crossAxisCount: 2,
                                     mainAxisSpacing: 8,
                                     crossAxisSpacing: 8,
                                     childAspectRatio: 2.2,
                                     children: [
                                       _buildResultBoxItem('Required Down Payment', CurrencyFormatter.format(_downReq, symbol: r'$'), const Color(0xFFFCD34D)),
                                       _buildResultBoxItem('DPA Grant Available', CurrencyFormatter.format(_totalDPA, symbol: r'$'), const Color(0xFF6EE7B7)),
                                       _buildResultBoxItem('Out-of-Pocket Down', CurrencyFormatter.format(_oop, symbol: r'$'), Colors.white),
                                       _buildResultBoxItem('Est. Monthly Payment', '${CurrencyFormatter.format(_totalMonthly, symbol: r'$')}/mo', Colors.white),
                                       _buildResultBoxItem('Loan Amount', CurrencyFormatter.format(_loanAmt, symbol: r'$'), Colors.white),
                                       _buildResultBoxItem('Best Program Match', _progName, const Color(0xFFFCD34D)),
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
                                         const Text('AMI Check (80% Limit)', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                                         Text(_amiStatus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7))),
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
                                   foregroundColor: const Color(0xFF1B3F72),
                                   side: const BorderSide(color: Color(0xFF1B3F72), width: 1.5),
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
 
                     // Custom bar breakdown comparison chart
                     if (_calculated) ...[
                       _buildSectionHeader('Cost Breakdown Comparison', '', mutedCol),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: cardBg,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: borderCol),
                         ),
                         child: Column(
                           children: [
                             _buildChartBarRow('Home Price', _homePriceController.text, double.tryParse(_homePriceController.text) ?? 350000, double.tryParse(_homePriceController.text) ?? 350000, const Color(0xFF1B3F72)),
                             _buildChartBarRow('Down Payment', CurrencyFormatter.format(_downReq, symbol: r'$'), _downReq, double.tryParse(_homePriceController.text) ?? 350000, const Color(0xFFB91C1C)),
                             _buildChartBarRow('DPA Grant', CurrencyFormatter.format(_totalDPA, symbol: r'$'), _totalDPA, double.tryParse(_homePriceController.text) ?? 350000, const Color(0xFF15803D)),
                             _buildChartBarRow('Your Out-of-Pocket', CurrencyFormatter.format(_oop, symbol: r'$'), _oop, _downReq, const Color(0xFFD97706)),
                             _buildChartBarRow('Est. Monthly Pmt', '${CurrencyFormatter.format(_totalMonthly, symbol: r'$')}/mo', _totalMonthly, _totalMonthly, const Color(0xFF6D28D9)),
                           ],
                         ),
                       ),
                     ],
 
                     // Program Details
                     _buildSectionHeader('Federal & State Programs', '2025 Active', mutedCol),
                     _buildProgramCard('🏛️', 'HUD Homebuyer Assistance', 'U.S. Dept. of Housing & Urban Development', 'Up to \$25,000 Grant', 'Income Limit: 120% AMI', 'First-Time Only', 'The Downpayment Toward Equity Act proposes \$25,000 for first-generation buyers. Current state HUD programs provide \$5,000–\$15,000 in DPA. Must complete HUD-approved counseling (hud.gov). Income limits vary: 80%–120% AMI by metro area.'),
                     _buildProgramCard('🌿', 'State DPA Programs', 'All 50 States + DC · Local HFAs', r'$2,500–$65,000', 'Forgivable or Deferred', '620+ Credit Score', 'CA MyHome: deferred 3.5% DPA · TX TDHCA: up to 5% grant · FL Assist: \$10,000 0% loan · NY SONYMA: \$3,000 grant + low rate · GA Dream: \$7,500 forgivable loan. Combined with FHA for lowest out-of-pocket.'),
                     _buildProgramCard('⭐', 'Fannie Mae HomeReady®', '3% Down · No PMI at 80% LTV · 2025', '3% Down Payment', 'Reduced PMI', '620+ Score', 'Income limit 80% AMI. Allows non-occupant co-borrowers. Gift funds accepted for full down payment. Reduced MI (0.25% less than standard). Online homebuyer education required (\$75 fee). Available for 1–4 unit primary residences.'),
                     _buildProgramCard('🏠', 'Freddie Mac Home Possible®', '3% Down · Low-to-Moderate Income · 2025', '3% Down', 'No Income Limit (Underserved)', '660+ Score', 'Income ≤ 80% AMI (standard), or no limit in underserved areas. Sweat equity counts toward down payment. Multiple co-borrowers allowed. MI cancels at 20% equity automatically. Comparable to HomeReady with slightly different qualifying criteria.'),
                     _buildProgramCard('🏦', 'Good Neighbor Next Door', 'HUD · 50% Discount for Public Service Workers', '50% Off List Price', 'Teachers · Police · Firefighters', '3-Year Residency Required', 'HUD sells foreclosed homes at 50% discount to eligible law enforcement, teachers (K-12), firefighters, and EMTs. Must live in the home for 36 months. Properties in HUD-designated revitalization areas. Listings rotate weekly on HUDhomestore.gov.'),
 
                     // Saved calculations list
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
                                     'DPA: ${CurrencyFormatter.format(s.results['DPA Grant'] ?? 0, symbol: r'$')} · OOP: ${CurrencyFormatter.format(s.results['Out-of-Pocket'] ?? 0, symbol: r'$')}',
                                     style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                                   ),
                                   trailing: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Text(
                                         CurrencyFormatter.format(s.results['DPA Grant'] ?? 0, symbol: r'$'),
                                         style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: Colors.green),
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
             Text(value, style: AppTextStyles.dmSans(size: 14, weight: FontWeight.bold, color: valColor)),
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
               decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
               child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.green)),
             ),
         ],
       ),
     );
   }
 
   Widget _buildEligibilityGrid() {
     final items = [
       {'icon': '🏠', 'text': 'No home ownership in last 3 years'},
       {'icon': '💳', 'text': 'Credit score ≥ 580 (FHA) or 620 (Conv.)'},
       {'icon': '💵', 'text': 'Income ≤ 80–120% Area Median Income'},
       {'icon': '🏫', 'text': 'Complete HUD-approved counseling'},
       {'icon': '🏡', 'text': 'Owner-occupied primary residence'},
       {'icon': '📋', 'text': 'Property price within program limits'},
     ];
 
     return GridView.builder(
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
         mainAxisSpacing: 8,
         crossAxisSpacing: 8,
         childAspectRatio: 2.3,
       ),
       itemCount: items.length,
       itemBuilder: (_, i) {
         final it = items[i];
         return Container(
           padding: const EdgeInsets.all(6),
           decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
           child: Row(
             children: [
               Text(it['icon']!, style: const TextStyle(fontSize: 14)),
               const SizedBox(width: 6),
               Expanded(child: Text(it['text']!, style: const TextStyle(fontSize: 8.5, color: Color(0xFF92400E), fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
             ],
           ),
         );
       },
     );
   }
 
   Widget _buildInputField(String label, TextEditingController controller, {String? errorText}) {
     final hasError = errorText != null;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: hasError ? Colors.red : Colors.grey, letterSpacing: 0.4)),
         const SizedBox(height: 4),
         TextField(
           controller: controller,
           keyboardType: TextInputType.number,
           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
           decoration: InputDecoration(
             fillColor: _theme.backgroundColor.withValues(alpha: 0.3),
             filled: true,
             contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(10),
               borderSide: hasError ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
             ),
             enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(10),
               borderSide: hasError ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
             ),
             focusedBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(10),
               borderSide: hasError ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
             ),
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

  Widget _buildChartBarRow(String label, String valStr, double value, double maxValue, Color color) {
    final pct = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 20,
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
          SizedBox(width: 70, child: Text(valStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildProgramCard(String emoji, String title, String subtitle, String tag1, String tag2, String tag3, String detail) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                    Text(subtitle, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _buildProgramTag(tag1, Colors.green),
              _buildProgramTag(tag2, Colors.blue),
              _buildProgramTag(tag3, Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: Text(detail, style: TextStyle(fontSize: 9.5, color: mutedCol, height: 1.45)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
