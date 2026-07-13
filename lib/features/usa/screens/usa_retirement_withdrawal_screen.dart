// lib/features/usa/screens/usa_retirement_withdrawal_screen.dart

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

class USARetirementWithdrawalScreen extends ConsumerStatefulWidget {
  const USARetirementWithdrawalScreen({super.key});

  @override
  ConsumerState<USARetirementWithdrawalScreen> createState() => _USARetirementWithdrawalScreenState();
}

class _USARetirementWithdrawalScreenState extends ConsumerState<USARetirementWithdrawalScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  final _withdrawController = TextEditingController(text: '15000');
  final _ageController = TextEditingController(text: '42');
  final _stateTaxController = TextEditingController(text: '5.0');
  final _balanceController = TextEditingController(text: '120000');
  final _growthController = TextEditingController(text: '7');
  final _yearsController = TextEditingController(text: '25');

  String _currentAcct = 'tira';
  double _taxBracket = 0.22;
  String _firstTime = 'yes';

  bool _calculated = false;

  // Outputs
  double _gross = 0;
  double _penalty = 0;
  double _fedTax = 0;
  double _stateTax = 0;
  double _net = 0;
  double _effRate = 0;
  double _lostGrowth = 0;
  double _trueCost = 0;

  @override
  void dispose() {
    _withdrawController.dispose();
    _ageController.dispose();
    _stateTaxController.dispose();
    _balanceController.dispose();
    _growthController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final withdraw = double.tryParse(_withdrawController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final age = double.tryParse(_ageController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final stateTaxRateVal = double.tryParse(_stateTaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    final growthVal = double.tryParse(_growthController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    final years = double.tryParse(_yearsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final balance = double.tryParse(_balanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (withdraw <= 0) {
      errors['withdraw'] = 'Enter positive withdrawal';
    }
    if (age <= 0) {
      errors['age'] = 'Enter positive age';
    }
    if (stateTaxRateVal < 0) {
      errors['stateTax'] = 'Enter valid tax rate';
    }
    if (growthVal < 0) {
      errors['growth'] = 'Enter valid growth rate';
    }
    if (years <= 0) {
      errors['years'] = 'Enter positive years';
    }
    if (balance <= 0) {
      errors['balance'] = 'Enter positive balance';
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

    final stateTaxRate = stateTaxRateVal / 100;
    final growth = growthVal / 100;

    double penalty = 0;
    double fedTax = 0;
    double stateTax = 0;
    final isEarly = age < 59.5;

    if (_currentAcct == 'tira') {
      final penaltyFree = (_firstTime == 'yes') ? math.min(10000.0, withdraw) : 0.0;
      final penaltySubject = math.max(0.0, withdraw - penaltyFree);
      penalty = isEarly ? penaltySubject * 0.10 : 0.0;
      fedTax = withdraw * _taxBracket;
      stateTax = withdraw * stateTaxRate;
    } else if (_currentAcct == 'rira') {
      const contribPct = 0.60;
      final earningAmt = withdraw * (1.0 - contribPct);
      final penaltyFreeEarnings = (_firstTime == 'yes') ? math.min(10000.0, earningAmt) : 0.0;
      final penaltySubjectEarnings = math.max(0.0, earningAmt - penaltyFreeEarnings);
      penalty = isEarly ? penaltySubjectEarnings * 0.10 : 0.0;
      fedTax = earningAmt * _taxBracket;
      stateTax = earningAmt * stateTaxRate;
    } else {
      // 401(k) / 403(b) / TSP
      penalty = isEarly ? withdraw * 0.10 : 0.0;
      fedTax = withdraw * _taxBracket;
      stateTax = withdraw * stateTaxRate;
    }

    final net = withdraw - penalty - fedTax - stateTax;
    final effRate = withdraw > 0 ? ((withdraw - net) / withdraw * 100) : 0.0;
    final lostGrowth = withdraw * math.pow(1.0 + growth, years) - withdraw;
    final trueCost = penalty + fedTax + stateTax + lostGrowth;

    setState(() {
      _calcSnapshot['withdraw'] = withdraw;
      _calcSnapshot['age'] = age;
      _calcSnapshot['stateTax'] = stateTaxRateVal;
      _calcSnapshot['growth'] = growthVal;
      _calcSnapshot['years'] = years;
      _calcSnapshot['balance'] = balance;
      _calcSnapshot['_currentAcct'] = _currentAcct;
      _calcSnapshot['_taxBracket'] = _taxBracket;
      _calcSnapshot['_firstTime'] = _firstTime;

      _gross = withdraw;
      _penalty = penalty;
      _fedTax = fedTax;
      _stateTax = stateTax;
      _net = net;
      _effRate = effRate;
      _lostGrowth = lostGrowth;
      _trueCost = trueCost;
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
    final withdraw = _calcSnapshot['withdraw'] ?? 15000.0;
    final age = _calcSnapshot['age'] ?? 42.0;
    final currentAcct = _calcSnapshot['_currentAcct'] ?? 'tira';

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Retirement Withdrawal',
      label: '${currentAcct.toUpperCase()} · ${CurrencyFormatter.compact(withdraw)} withdrawal',
      currencyCode: 'USD',
      inputs: {
        'withdraw': withdraw,
        'age': age,
      },
      results: {
        'Net Received': _net,
        'Penalty': _penalty,
        'Tax Cost': _fedTax + _stateTax,
        'Lost Growth': _lostGrowth,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Withdrawal calculation saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_withdrawController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['withdraw'] ?? 0.0) ||
      (double.tryParse(_ageController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['age'] ?? 0.0) ||
      (double.tryParse(_stateTaxController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['stateTax'] ?? 0.0) ||
      (double.tryParse(_growthController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['growth'] ?? 0.0) ||
      (double.tryParse(_yearsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['years'] ?? 0.0) ||
      (double.tryParse(_balanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['balance'] ?? 0.0) ||
      _currentAcct != (_calcSnapshot['_currentAcct'] ?? 'tira') ||
      _taxBracket != (_calcSnapshot['_taxBracket'] ?? 0.22) ||
      _firstTime != (_calcSnapshot['_firstTime'] ?? 'yes')
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    final saves = ref.watch(savedProvider).where(
      (c) => c.country.toLowerCase() == 'usa' && c.calcType == 'Retirement Withdrawal'
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📈', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('Retirement Withdrawal', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('Penalty Exemptions · Tax Impact · First-Time Buyer', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRateItem('Penalty', '10%', 'Under 59½', Colors.redAccent),
                      _buildRateItem('IRA Limit', r'$10K', 'Lifetime', Colors.orange),
                      _buildRateItem('Roth Limit', 'No Limit', 'Contrib. Only', Colors.green),
                      _buildRateItem('401k Loan', '50% / \$50K', 'Max Limit', textCol),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero
                    _buildSectionHeader('Retirement Withdrawal Overview', 'IRS 2025', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1D3A), Color(0xFFB45309)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('IRS Rules · Retirement Account · Home Purchase 2025', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text('Smart Withdrawal:\nMinimize Penalties & Taxes', style: AppTextStyles.playfair(color: Colors.white, size: 16, weight: FontWeight.bold, height: 1.25)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSnapshotBox('IRA Exempt', r'$10K', const Color(0xFFFCD34D)),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('Penalty', '10%', Colors.redAccent),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('Tax Rate', 'Ordinary', Colors.white),
                              const SizedBox(width: 8),
                              _buildSnapshotBox('401k Loan', r'$50K Max', const Color(0xFFFCD34D)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // IRS Warning
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Important IRS Warning · 2025', style: AppTextStyles.playfair(size: 10.5, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                                const SizedBox(height: 3),
                                const Text(
                                  'Early withdrawals from retirement accounts are generally subject to 10% penalty + ordinary income tax. The IRA first-time homebuyer exception is limited to \$10,000 lifetime. Always consult a tax professional before withdrawing.',
                                  style: TextStyle(fontSize: 9, color: Color(0xFFB45309), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Account Selector Toggle
                    _buildSectionHeader('Account Type', 'Select Below', mutedCol),
                    _buildAccountSelector(),

                    // Calculator Card
                    _buildSectionHeader('Withdrawal Impact Calculator', '', mutedCol),
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
                              Text('Withdrawal Impact Calculator', style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInputField('Withdrawal Amount (\$)', _withdrawController, errorText: _errors['withdraw'])),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('Your Age', _ageController, errorText: _errors['age'])),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField('Federal Tax Bracket', _taxBracket, [
                                  const DropdownMenuItem(value: 0.10, child: Text('10% · <\$11.6K')),
                                  const DropdownMenuItem(value: 0.12, child: Text('12% · \$11.6–47.1K')),
                                  const DropdownMenuItem(value: 0.22, child: Text('22% · \$47.1–100.5K')),
                                  const DropdownMenuItem(value: 0.24, child: Text('24% · \$100.5–191.9K')),
                                  const DropdownMenuItem(value: 0.32, child: Text('32% · \$191.9–243.7K')),
                                  const DropdownMenuItem(value: 0.35, child: Text('35% · \$243.7–609.3K')),
                                  const DropdownMenuItem(value: 0.37, child: Text('37% · >\$609.3K')),
                                ], (val) => setState(() => _taxBracket = val!)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('State Tax Rate (%)', _stateTaxController, errorText: _errors['stateTax'])),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField('First-Time Buyer?', _firstTime, [
                                  const DropdownMenuItem(value: 'yes', child: Text('Yes (no home in 3 yrs)')),
                                  const DropdownMenuItem(value: 'no', child: Text('No')),
                                ], (val) => setState(() => _firstTime = val!)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('Account Balance (\$)', _balanceController, errorText: _errors['balance'])),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildInputField('Expected Return (%/yr)', _growthController, errorText: _errors['growth'])),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInputField('Years to Retirement', _yearsController, errorText: _errors['years'])),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Calculate Withdrawal Impact', style: AppTextStyles.dmSans(size: 14, weight: FontWeight.bold, color: Colors.white)),
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
                                              'Inputs have changed. Tap "Calculate Withdrawal Impact" to update results.',
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
                                gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFFB45309)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('📊 Withdrawal Analysis · 2025', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                                  const SizedBox(height: 10),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 2.2,
                                    children: [
                                      _buildResultBoxItem('Gross Withdrawal', CurrencyFormatter.format(_gross, symbol: r'$'), const Color(0xFFFCD34D)),
                                      _buildResultBoxItem('Early Penalty (10%)', _penalty == 0 ? 'None (waived)' : CurrencyFormatter.format(_penalty, symbol: r'$'), Colors.redAccent),
                                      _buildResultBoxItem('Federal Tax Cost', CurrencyFormatter.format(_fedTax, symbol: r'$'), Colors.redAccent),
                                      _buildResultBoxItem('State Tax Cost', CurrencyFormatter.format(_stateTax, symbol: r'$'), Colors.redAccent),
                                      _buildResultBoxItem('Net Amount Received', CurrencyFormatter.format(_net, symbol: r'$'), Colors.greenAccent),
                                      _buildResultBoxItem('Effective Cost Rate', '${_effRate.toStringAsFixed(1)}% goes to gov.', Colors.redAccent),
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
                                        const Text('Lost Compound Growth (at retirement)', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                                        Text('${CurrencyFormatter.format(_lostGrowth, symbol: r'$')} in ${_yearsController.text} years', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), border: Border.all(color: Colors.red.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('⚠️ Total True Cost of Withdrawal', style: TextStyle(fontSize: 9, color: Colors.white60)),
                                        const SizedBox(height: 2),
                                        Text('True cost: ${CurrencyFormatter.format(_trueCost, symbol: r'$')} (penalties + taxes + growth)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
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

                    // Segmented Bar Chart
                    if (_calculated) ...[
                      _buildSectionHeader('Where Your Withdrawal Goes', '', mutedCol),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          children: [
                            _buildStackedBar(),
                            const SizedBox(height: 12),
                            _buildStackedLegend(),
                          ],
                        ),
                      ),
                    ],

                    // Comparison Table
                    _buildSectionHeader('Account Type Comparison', 'All 4 Types', mutedCol),
                    _buildComparisonTable(cardBg, textCol, mutedCol, borderCol),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text('*Traditional IRA penalty waived for first-time homebuyer up to \$10,000 lifetime limit per IRS § 72(t)(2)(F).', style: TextStyle(fontSize: 8, color: mutedCol)),
                    ),

                    // Rules List
                    _buildSectionHeader('Key IRS Rules to Know', '2025', mutedCol),
                    _buildInfoItem('📋', 'IRA First-Time Homebuyer Exception', 'IRS allows penalty-free withdrawal of up to \$10,000 lifetime from Traditional IRA for first-time home purchase. "First-time" = no ownership in last 24 months. Taxes still apply.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🔄', 'IRA 60-Day Rollover Bridge', 'Withdraw IRA funds as a bridge loan; must be used within 120 days for home purchase. If sale falls through, redeposit within 60 days to avoid tax/penalty. One rollover per 12-month period.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🏦', '401(k) Loan – Best Option', 'Borrow up to 50% of vested balance or \$50,000 (whichever is less). No taxes or penalties. Must repay within 5 years. If you leave your employer, the full balance typically due in 60–90 days.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('🌱', 'Roth IRA – Most Flexible', 'Contributions (not earnings) can be withdrawn anytime tax-free and penalty-free. After age 59½ with 5-year rule met, earnings also tax-free. First-time buyer: earnings also exempt up to \$10K.', cardBg, textCol, mutedCol, borderCol),
                    _buildInfoItem('⏰', 'Hardship Withdrawal – Last Resort', 'Some 401(k) plans allow hardship withdrawals for home purchase. Subject to 10% penalty + full income tax. Cannot repay after taking. Permanently reduces retirement savings.', cardBg, textCol, mutedCol, borderCol),

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
                                    'Net: ${CurrencyFormatter.format(s.results['Net Received'] ?? 0, symbol: r'$')} · Penalty: ${CurrencyFormatter.format(s.results['Penalty'] ?? 0, symbol: r'$')}',
                                    style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(s.results['Net Received'] ?? 0, symbol: r'$'),
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
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector() {
    final accounts = [
      {'id': 'tira', 'label': 'Traditional IRA'},
      {'id': 'rira', 'label': 'Roth IRA'},
      {'id': '401k', 'label': '401(k)'},
      {'id': '403b', 'label': '403(b) / TSP'},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.2,
      children: accounts.map((act) {
        final active = _currentAcct == act['id'];
        return GestureDetector(
          onTap: () => setState(() => _currentAcct = act['id']!),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? _theme.primaryColor : _theme.backgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? _theme.primaryColor : _theme.getBorderColor(context)),
            ),
            child: Text(
              act['label']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : _theme.getTextColor(context),
              ),
            ),
          ),
        );
      }).toList(),
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

  Widget _buildStackedBar() {
    final total = _net + _fedTax + _stateTax + _penalty;
    if (total == 0) return const SizedBox.shrink();

    final netPct = _net / total;
    final fedPct = _fedTax / total;
    final statePct = _stateTax / total;
    final penaltyPct = _penalty / total;

    return Container(
      height: 36,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (netPct > 0)
            Expanded(
              flex: (netPct * 1000).toInt(),
              child: Container(
                color: const Color(0xFF15803D),
                alignment: Alignment.center,
                child: Text('${(netPct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          if (fedPct > 0)
            Expanded(
              flex: (fedPct * 1000).toInt(),
              child: Container(
                color: const Color(0xFFB91C1C),
                alignment: Alignment.center,
                child: Text('${(fedPct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          if (statePct > 0)
            Expanded(
              flex: (statePct * 1000).toInt(),
              child: Container(
                color: const Color(0xFFD97706),
                alignment: Alignment.center,
                child: Text('${(statePct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          if (penaltyPct > 0)
            Expanded(
              flex: (penaltyPct * 1000).toInt(),
              child: Container(
                color: const Color(0xFF0B1D3A),
                alignment: Alignment.center,
                child: Text('${(penaltyPct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStackedLegend() {
    final list = [
      {'label': 'Net Received', 'val': _net, 'color': const Color(0xFF15803D)},
      {'label': 'Federal Tax', 'val': _fedTax, 'color': const Color(0xFFB91C1C)},
      {'label': 'State Tax', 'val': _stateTax, 'color': const Color(0xFFD97706)},
      {'label': 'Penalty', 'val': _penalty, 'color': const Color(0xFF0B1D3A)},
    ].where((e) => (e['val'] as double) > 0).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: list.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: item['color'] as Color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Text('${item['label']}: ${CurrencyFormatter.format(item['val'] as double, symbol: r'$')}', style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildComparisonTable(Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
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
                Text('📋 Account Withdrawal Rules · IRS 2025', style: AppTextStyles.playfair(size: 11, color: Colors.white, weight: FontWeight.bold)),
              ],
            ),
          ),
          _buildTableRow('Account', 'Penalty', 'FTB Exemption', 'Tax', isHeader: true),
          _buildTableRow('Traditional IRA', 'Waived*', 'Up to \$10K', 'Yes', isHighlight: true),
          _buildTableRow('Roth IRA', 'None', 'Contrib. Free', 'None (contrib.)'),
          _buildTableRow('401(k) / 403(b)', '10%', 'No exemption', 'Yes', isHighlight: true),
          _buildTableRow('401(k) Loan', 'None', 'Up to \$50K', 'Repay only'),
        ],
      ),
    );
  }

  Widget _buildTableRow(String col1, String col2, String col3, String col4, {bool isHeader = false, bool isHighlight = false}) {
    final textStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.grey : _theme.getTextColor(context),
    );
    final valStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.bold,
      color: isHeader
          ? Colors.grey
          : (col2.contains('None') || col2.contains('Waived') || col3.contains('Free') ? Colors.green : Colors.red),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isHeader ? _theme.backgroundColor.withValues(alpha: 0.3) : (isHighlight ? const Color(0xFFFFF7ED) : null),
        border: Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(col1, style: textStyle)),
          Expanded(child: Text(col2, style: valStyle, textAlign: TextAlign.center)),
          Expanded(child: Text(col3, style: textStyle, textAlign: TextAlign.center)),
          Expanded(child: Text(col4, style: textStyle, textAlign: TextAlign.center)),
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
