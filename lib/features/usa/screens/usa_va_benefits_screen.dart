// lib/features/usa/screens/usa_va_benefits_screen.dart

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

class USAVaBenefitsScreen extends ConsumerStatefulWidget {
  const USAVaBenefitsScreen({super.key});

  @override
  ConsumerState<USAVaBenefitsScreen> createState() => _USAVaBenefitsScreenState();
}

class _USAVaBenefitsScreenState extends ConsumerState<USAVaBenefitsScreen> {
  static const _theme = CountryThemes.usa;

  final _homePriceController = TextEditingController(text: '425000');
  final _downPmtController = TextEditingController(text: '0');
  final _incomeController = TextEditingController(text: '90000');

  int _loanTerm = 30;
  String _serviceType = 'active';
  String _disability = 'none';

  bool _calculated = false;

  // Outputs
  double _loanAmt = 0;
  double _payment = 0;
  double _fundingFeeAmt = 0;
  double _feePct = 0;
  double _totalInterest = 0;
  double _dti = 0;
  double _pmiSaved = 0;
  double _totalSaved = 0;

  static const Map<String, Map<String, double>> _fundingFees = {
    'active': {'lt5': 0.0215, 'lt10': 0.0150, 'gte10': 0.0125},
    'reserve': {'lt5': 0.0230, 'lt10': 0.0165, 'gte10': 0.0140},
    'subsequent': {'lt5': 0.0330, 'lt10': 0.0150, 'gte10': 0.0125}
  };

  @override
  void dispose() {
    _homePriceController.dispose();
    _downPmtController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final price = double.tryParse(_homePriceController.text) ?? 425000;
    final term = _loanTerm;
    final downPmt = double.tryParse(_downPmtController.text) ?? 0;
    final income = double.tryParse(_incomeController.text) ?? 90000;

    final downPct = downPmt / price;
    final loanAmt = price - downPmt;
    const vaRate = 0.0625;
    const convRate = 0.0682;
    final n = term * 12;
    const mr = vaRate / 12;

    double payment = 0;
    if (mr > 0) {
      payment = loanAmt * (mr * math.pow(1 + mr, n)) / (math.pow(1 + mr, n) - 1);
    } else {
      payment = loanAmt / n;
    }

    // Funding Fee
    double feePct = 0;
    if (_disability == 'none') {
      final fees = _fundingFees[_serviceType] ?? {'lt5': 0.0215, 'lt10': 0.0150, 'gte10': 0.0125};
      if (downPct < 0.05) {
        feePct = fees['lt5']!;
      } else if (downPct < 0.10) {
        feePct = fees['lt10']!;
      } else {
        feePct = fees['gte10']!;
      }
    }
    final fundingFeeAmt = loanAmt * feePct;
    final totalInterest = (payment * n) - loanAmt;

    // PMI savings vs conventional
    final convPMIMonthly = (loanAmt * 0.008) / 12;
    final pmiMonths = ((1.0 - (0.80 - downPct)) * n).ceil();
    final pmiSaved = math.max(0.0, convPMIMonthly * math.min(pmiMonths.toDouble(), n.toDouble()));
    final rateSavings = (convRate - vaRate) / 12 * loanAmt * n * 0.45;
    final totalSaved = pmiSaved + rateSavings;

    final monthlyIncome = income / 12;
    final dti = monthlyIncome > 0 ? (payment / monthlyIncome * 100) : 0.0;

    setState(() {
      _loanAmt = loanAmt;
      _payment = payment;
      _fundingFeeAmt = fundingFeeAmt;
      _feePct = feePct;
      _totalInterest = totalInterest;
      _dti = dti;
      _pmiSaved = pmiSaved;
      _totalSaved = totalSaved;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;
    final price = double.tryParse(_homePriceController.text) ?? 425000;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'VA Benefits',
      label: 'VA Loan · ${CurrencyFormatter.compact(price)}',
      currencyCode: 'USD',
      inputs: {
        'price': price,
        'term': _loanTerm.toDouble(),
        'down': double.tryParse(_downPmtController.text) ?? 0,
      },
      results: {
        'Monthly Payment': _payment,
        'Funding Fee': _fundingFeeAmt,
        'Interest Paid': _totalInterest,
        'PMI Saved': _pmiSaved,
        'Total Saved': _totalSaved,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ VA Benefits calculation saved!'),
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
      (c) => c.country.toLowerCase() == 'usa' && c.calcType == 'VA Benefits'
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF7C2020)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪖', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('VA Benefits & Home Loans', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('Entitlement · COE · Funding Fee · 0% Down · 2025', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                    color: const Color(0xFF7C2020).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF7C2020).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRateItem('VA 30-Yr', '6.25%', 'Avg 2025', Colors.green),
                      _buildRateItem('Down Pmt', '0%', 'Eligible', Colors.orange),
                      _buildRateItem('Fund. Fee', '2.15%', '1st Use', textCol),
                      _buildRateItem('Loan Limit', 'No Limit', 'Full Entit.', textCol),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero View
                    _buildSectionHeader('VA Loan Overview', 'Veterans Only', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1D3A), Color(0xFF7C2020)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('U.S. Department of Veterans Affairs · 2025', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(r'$0 Down · No PMI · Competitive' '\n' 'Rates for Service Members', style: AppTextStyles.playfair(color: Colors.white, size: 16, weight: FontWeight.bold, height: 1.25)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSnapshotBox('Down Pmt', r'$0', const Color(0xFFFCD34D)),
                              const SizedBox(width: 6),
                              _buildSnapshotBox('PMI', 'None', Colors.greenAccent),
                              const SizedBox(width: 6),
                              _buildSnapshotBox('Min Score', '620', Colors.white),
                              const SizedBox(width: 6),
                              _buildSnapshotBox('VA Rate', '6.25%', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Benefits Grid
                    _buildSectionHeader('Key VA Benefits', 'Active 2025', mutedCol),
                    _buildBenefitsGrid(cardBg, textCol, mutedCol, borderCol),

                    // Calculator Card
                    _buildSectionHeader('VA Loan Calculator', 'Save Results', mutedCol),
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
                                child: const Text('🪖'),
                              ),
                              const SizedBox(width: 8),
                              Text('VA Mortgage & Savings Calculator', style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInputField('Home Price (\$)', _homePriceController)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField('Loan Term', _loanTerm, [
                                  const DropdownMenuItem(value: 30, child: Text('30 Years')),
                                  const DropdownMenuItem(value: 15, child: Text('15 Years')),
                                ], (val) => setState(() => _loanTerm = val!)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField('Service Type', _serviceType, [
                                  const DropdownMenuItem(value: 'active', child: Text('Active Duty / Veteran')),
                                  const DropdownMenuItem(value: 'reserve', child: Text('Reserves / Guard')),
                                  const DropdownMenuItem(value: 'subsequent', child: Text('Subsequent Use')),
                                ], (val) => setState(() => _serviceType = val!)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('Down Payment (\$)', _downPmtController)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField('Disability Rating', _disability, [
                                  const DropdownMenuItem(value: 'none', child: Text('None / Below 10%')),
                                  const DropdownMenuItem(value: 'waived', child: Text('10%+ (Waived)')),
                                ], (val) => setState(() => _disability = val!)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('Annual Income (\$)', _incomeController)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C2020),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Calculate VA Loan & Savings', style: AppTextStyles.dmSans(size: 14, weight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),

                          // Calculation results
                          if (_calculated) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF7C2020)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🇺🇸 VA Loan Results · 2025', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                                  const SizedBox(height: 10),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 2.2,
                                    children: [
                                      _buildResultBoxItem('Loan Amount', CurrencyFormatter.format(_loanAmt, symbol: r'$'), Colors.white),
                                      _buildResultBoxItem('Monthly Payment', '${CurrencyFormatter.format(_payment, symbol: r'$')}/mo', const Color(0xFFFCD34D)),
                                      _buildResultBoxItem('VA Funding Fee', _disability == 'waived' ? 'WAIVED ✅' : '${CurrencyFormatter.format(_fundingFeeAmt, symbol: r'$')} (${(_feePct * 100).toStringAsFixed(2)}%)', Colors.white),
                                      _buildResultBoxItem('Total Interest Paid', CurrencyFormatter.format(_totalInterest, symbol: r'$'), Colors.white),
                                      _buildResultBoxItem('DTI Ratio', '${_dti.toStringAsFixed(1)}%', Colors.white),
                                      _buildResultBoxItem('VA Rate Used', '6.25%', Colors.greenAccent),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('PMI Saved vs Conventional (Life of Loan)', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                                        Text(CurrencyFormatter.format(_pmiSaved, symbol: r'$'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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
                                        const Text('💡 Total Savings vs Conventional Loan', style: TextStyle(fontSize: 9, color: Colors.white60)),
                                        const SizedBox(height: 2),
                                        Text('${CurrencyFormatter.format(_totalSaved, symbol: r'$')} saved vs Conventional', style: AppTextStyles.dmSans(size: 15, weight: FontWeight.bold, color: Colors.greenAccent)),
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

                    // Donut payment breakdown chart
                    if (_calculated) ...[
                      _buildSectionHeader('Monthly Payment Breakdown', '', mutedCol),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120, height: 120,
                              child: CustomPaint(
                                painter: _DonutChartPainter(
                                  principal: _loanAmt / (_loanTerm * 12),
                                  interest: _payment - (_loanAmt / (_loanTerm * 12)) - (_fundingFeeAmt / (_loanTerm * 12)),
                                  fee: _fundingFeeAmt / (_loanTerm * 12),
                                  cardBg: cardBg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegendItem('Principal', _loanAmt / (_loanTerm * 12), const Color(0xFF1B3F72)),
                                  const SizedBox(height: 6),
                                  _buildLegendItem('Interest', _payment - (_loanAmt / (_loanTerm * 12)) - (_fundingFeeAmt / (_loanTerm * 12)), const Color(0xFFB91C1C)),
                                  const SizedBox(height: 6),
                                  _buildLegendItem('Monthly Fee', _fundingFeeAmt / (_loanTerm * 12), const Color(0xFFD97706)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Funding Fee Table
                    _buildSectionHeader('VA Funding Fee Table', '2025 Official', mutedCol),
                    _buildFundingFeeTable(cardBg, textCol, mutedCol, borderCol),

                    // Eligibility Info Checklist
                    _buildSectionHeader('VA Eligibility Requirements', 'Service Periods', mutedCol),
                    _buildInfoItem('🎖️', 'Active Duty Service', '90 days continuous active duty during wartime or 181 days during peacetime. Currently serving active duty members qualify after 90 days.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🏕️', 'National Guard / Reserves', '6 years of service OR 90 days of active duty under Title 10 orders. Must have been honorably discharged or be currently serving.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('💍', 'Surviving Spouses', 'Unremarried surviving spouse of veteran who died in service or from service-connected disability. Also eligible if veteran was POW/MIA.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('📋', 'Certificate of Eligibility (COE)', 'Obtain via VA.gov eBenefits portal, lender can pull automatically, or mail VA Form 26-1880. Most lenders obtain same day.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🏠', 'Occupancy Requirement', 'Must intend to occupy the home as primary residence within 60 days of closing. Spouses may satisfy occupancy for deployed veterans.', cardBg, textCol, mutedCol, borderCol),

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
                                    'Pmt: ${CurrencyFormatter.format(s.results['Monthly Payment'] ?? 0, symbol: r'$')}/mo · Saved: ${CurrencyFormatter.format(s.results['Total Saved'] ?? 0, symbol: r'$')}',
                                    style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(s.results['Total Saved'] ?? 0, symbol: r'$'),
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
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    final benefits = [
      {'ico': '💰', 'val': r'$0', 'lbl': 'Down Payment Required', 'tag': '0% Down', 'col': Colors.green},
      {'ico': '🚫', 'val': 'None', 'lbl': 'PMI (Private Mort. Ins.)', 'tag': 'Big Savings', 'col': Colors.green},
      {'ico': '📉', 'val': '6.25%', 'lbl': 'Average VA Rate 2025', 'tag': 'vs 6.82% Conv.', 'col': Colors.blue},
      {'ico': '🔄', 'val': 'Unlimited', 'lbl': 'Loan Assumption', 'tag': 'Transferable', 'col': Colors.blue},
      {'ico': '🏥', 'val': 'Waived', 'lbl': 'Funding Fee (Disabled)', 'tag': '10%+ Rating', 'col': Colors.green},
      {'ico': '♻️', 'val': 'Reusable', 'lbl': 'VA Entitlement Benefit', 'tag': 'Multiple Use', 'col': Colors.blue},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: 1.3,
      ),
      itemCount: benefits.length,
      itemBuilder: (_, i) {
        final b = benefits[i];
        final badgeColor = b['col'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(b['ico'] as String, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(b['val'] as String, style: AppTextStyles.playfair(size: 15, color: textCol, weight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(b['lbl'] as String, style: TextStyle(fontSize: 8, color: mutedCol), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(b['tag'] as String, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ],
          ),
        );
      },
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

  Widget _buildLegendItem(String label, double val, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.dmSans(size: 10, color: _theme.getTextColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFundingFeeTable(Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
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
              gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🏛️ VA Funding Fee · 2025', style: AppTextStyles.playfair(size: 11, color: Colors.white, weight: FontWeight.bold)),
                const Text('Per VA.gov official rates', style: TextStyle(fontSize: 9, color: Colors.white54)),
              ],
            ),
          ),
          _buildTableRow('Loan Type', 'Down Pmt', '1st Use', 'Sub. Use', isHeader: true),
          _buildTableRow('Purchase/Constr.', '<5%', '2.15%', '3.30%', isHighlight: true),
          _buildTableRow('Purchase/Constr.', '5–10%', '1.50%', '1.50%'),
          _buildTableRow('Purchase/Constr.', '10%+', '1.25%', '1.25%'),
          _buildTableRow('Cash-Out Refi', 'N/A', '2.15%', '3.30%', isHighlight: true),
          _buildTableRow('IRRRL', 'N/A', '0.50%', '0.50%'),
          _buildTableRow('Disabled Veteran', 'Any', 'Waived', 'Waived', valueColor: Colors.green),
        ],
      ),
    );
  }

  Widget _buildTableRow(String col1, String col2, String col3, String col4, {bool isHeader = false, bool isHighlight = false, Color? valueColor}) {
    final textStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.grey : _theme.getTextColor(context),
    );
    final valStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.bold,
      color: valueColor ?? (isHeader ? Colors.grey : (col3.contains('Waived') || col3.contains('2.15') ? Colors.green : Colors.orange)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isHeader ? _theme.backgroundColor.withValues(alpha: 0.3) : (isHighlight ? Colors.green.withValues(alpha: 0.03) : null),
        border: Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(col1, style: textStyle)),
          Expanded(child: Text(col2, style: textStyle, textAlign: TextAlign.center)),
          Expanded(child: Text(col3, style: valStyle, textAlign: TextAlign.center)),
          Expanded(child: Text(col4, style: valStyle, textAlign: TextAlign.center)),
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

class _DonutChartPainter extends CustomPainter {
  final double principal;
  final double interest;
  final double fee;
  final Color cardBg;

  _DonutChartPainter({required this.principal, required this.interest, required this.fee, required this.cardBg});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = principal + interest + fee;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 6);

    final paintPrincipal = Paint()..color = const Color(0xFF1B3F72)..style = PaintingStyle.fill;
    final paintInterest = Paint()..color = const Color(0xFFB91C1C)..style = PaintingStyle.fill;
    final paintFee = Paint()..color = const Color(0xFFD97706)..style = PaintingStyle.fill;
    final paintHole = Paint()..color = cardBg..style = PaintingStyle.fill;

    double startAngle = -math.pi / 2;

    // Principal
    final sweepPrincipal = (principal / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepPrincipal, true, paintPrincipal);
    startAngle += sweepPrincipal;

    // Interest
    final sweepInterest = (interest / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepInterest, true, paintInterest);
    startAngle += sweepInterest;

    // Fee
    final sweepFee = (fee / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepFee, true, paintFee);

    // Inner Hole (for donut look)
    canvas.drawCircle(center, radius - 26, paintHole);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
