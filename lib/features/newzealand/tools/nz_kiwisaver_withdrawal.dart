// lib/features/newzealand/tools/nz_kiwisaver_withdrawal.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZKiwiSaverWithdrawal extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZKiwiSaverWithdrawal({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZKiwiSaverWithdrawal> createState() => _NZKiwiSaverWithdrawalState();
}

class _NZKiwiSaverWithdrawalState extends ConsumerState<NZKiwiSaverWithdrawal> {
  final _balanceController = TextEditingController(text: '48500');
  final _yearsController = TextEditingController(text: '7');
  final _incomeController = TextEditingController(text: '85000');

  String _propertyType = 'Existing home'; // 'Existing home', 'New build'
  String _region = 'Auckland'; // 'Auckland', 'Wellington', 'Christchurch', 'Hamilton', 'Tauranga', 'Dunedin'
  String _contribRate = '3%'; // '3%', '4%', '6%', '8%', '10%'

  void _saveCalc() async {
    final double balance = double.tryParse(_balanceController.text) ?? 48500;
    final double years = double.tryParse(_yearsController.text) ?? 7;
    final double income = double.tryParse(_incomeController.text) ?? 85000;

    final withdrawable = balance >= 1000 && years >= 3 ? balance - 1000 : 0.0;
    final grant = _calcGrant(years, income);
    final total = withdrawable + grant;

    final results = {
      'Withdrawable': withdrawable,
      'Grant Amount': grant,
      'Total Deposit': total,
    };
    final inputs = {
      'Balance': balance,
      'Years': years,
      'Income': income,
    };

    final labelCtrl = TextEditingController(text: 'KiwiSaver Withdrawal');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total available: ${CurrencyFormatter.compact(total, symbol: 'NZ\$')}',
              style: AppTextStyles.dmSans(
                  size: 11.5, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My KiwiSaver Deposit)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
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
                    size: 12,
                    weight: FontWeight.bold,
                    color: widget.theme.getMutedColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && labelCtrl.text.isNotEmpty) {
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'KiwiSaver Withdrawal',
        inputs: inputs,
        results: results,
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${labelCtrl.text}" successfully!'),
            backgroundColor: widget.theme.primaryColor,
          ),
        );
      }
    }
  }

  double _calcGrant(double years, double income) {
    if (years < 3 || income > 95000) return 0.0;
    final isNew = _propertyType == 'New build';
    final double multiplier = isNew ? 2000 : 1000;
    final double maxGrant = isNew ? 10000 : 5000;
    final double calculated = years * multiplier;
    return calculated.clamp(0.0, maxGrant);
  }

  double _priceCapFor(String reg, String propType) {
    final isNew = propType == 'New build';
    switch (reg) {
      case 'Auckland':
        return isNew ? 875000 : 650000;
      case 'Wellington':
        return isNew ? 790000 : 575000;
      case 'Christchurch':
        return isNew ? 675000 : 525000;
      default:
        return isNew ? 650000 : 500000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);
    final borderCol = theme.getBorderColor(context);

    final double balance = double.tryParse(_balanceController.text) ?? 48500;
    final double years = double.tryParse(_yearsController.text) ?? 7;
    final double income = double.tryParse(_incomeController.text) ?? 85000;

    final withdrawable = balance >= 1000 && years >= 3 ? balance - 1000 : 0.0;
    final grant = _calcGrant(years, income);
    final totalDeposit = withdrawable + grant;

    final hasThreeYears = years >= 3;
    final isIncomeEligible = income <= 95000;
    final priceCap = _priceCapFor(_region, _propertyType);

    // Breakdown parts
    final double memberContrib = withdrawable * 0.6;
    final double employerContrib = withdrawable * 0.3;
    final double govtContrib = withdrawable * 0.1;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input panel
          Text('YOUR DETAILS', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🥝 KIWISAVER FIRST-HOME WITHDRAWAL · TĀKE KĀINGA',
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: Colors.white70,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    text: 'Calculate your ',
                    style: AppTextStyles.playfair(size: 17, weight: FontWeight.bold, color: Colors.white),
                    children: const [
                      TextSpan(text: 'KiwiSaver', style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold)),
                      TextSpan(text: ' withdrawal amount'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KIWISAVER BALANCE', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _balanceController,
                              style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YEARS CONTRIBUTING', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _yearsController,
                              style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PROPERTY TYPE', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _propertyType,
                                isDense: true,
                                dropdownColor: const Color(0xFF0D3B2E),
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'Existing home', child: Text('Existing home')),
                                  DropdownMenuItem(value: 'New build', child: Text('New build')),
                                ],
                                onChanged: (val) => setState(() => _propertyType = val ?? 'Existing home'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('REGION', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _region,
                                isDense: true,
                                dropdownColor: const Color(0xFF0D3B2E),
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'Auckland', child: Text('Auckland')),
                                  DropdownMenuItem(value: 'Wellington', child: Text('Wellington')),
                                  DropdownMenuItem(value: 'Christchurch', child: Text('Christchurch')),
                                  DropdownMenuItem(value: 'Hamilton', child: Text('Hamilton')),
                                  DropdownMenuItem(value: 'Tauranga', child: Text('Tauranga')),
                                  DropdownMenuItem(value: 'Dunedin', child: Text('Dunedin')),
                                ],
                                onChanged: (val) => setState(() => _region = val ?? 'Auckland'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ANNUAL INCOME', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _incomeController,
                              style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CONTRIB RATE', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _contribRate,
                                isDense: true,
                                dropdownColor: const Color(0xFF0D3B2E),
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: '3%', child: Text('3%')),
                                  DropdownMenuItem(value: '4%', child: Text('4%')),
                                  DropdownMenuItem(value: '6%', child: Text('6%')),
                                  DropdownMenuItem(value: '8%', child: Text('8%')),
                                  DropdownMenuItem(value: '10%', child: Text('10%')),
                                ],
                                onChanged: (val) => setState(() => _contribRate = val ?? '3%'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: Text('🥝 Calculate My Withdrawal', style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Eligibility Status Badge row
          Text('ELIGIBILITY STATUS', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildEligBadge(hasThreeYears, '3-yr min met', 'Under 3 years'),
              _buildEligBadge(true, 'First-home buyer', 'Not FHB'),
              _buildEligBadge(true, 'NZ Citizen/Res.', 'Overseas buyer'),
              _buildEligBadge(isIncomeEligible, 'Income eligible', 'Income cap exceeded'),
              _buildEligBadge(true, 'Price cap check', 'Exceeds cap', isWarning: true),
            ],
          ),
          const SizedBox(height: 16),

          // Results Card
          Text('YOUR WITHDRAWAL ESTIMATE', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)]),
              border: Border.all(color: const Color(0xFF0D9488), width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🥝', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('KiwiSaver Withdrawal Breakdown', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: const Color(0xFF0F766E))),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildResultBox('Your Contributions', memberContrib, '${years.toInt()} yrs @ $_contribRate salary'),
                    _buildResultBox('Employer Contributions', employerContrib, '3% employer match'),
                    _buildResultBox('Govt Contribution', govtContrib, '\$521.43/yr max credits'),
                    _buildResultBox('Withdrawable Amount', withdrawable, 'Balance minus \$1,000'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0D3B2E), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Available for Deposit', style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                          Text('KiwiSaver + HomeStart Grant', style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.compact(totalDeposit, symbol: 'NZ\$'),
                        style: AppTextStyles.dmSans(size: 22, weight: FontWeight.w800, color: const Color(0xFFF5D060)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save calculation snapshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save This Calculation', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: Colors.white)),
                      Text('${CurrencyFormatter.compact(totalDeposit, symbol: 'NZ\$')} available · $_region', style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5D060),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Save', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Donut Composition Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Deposit Composition', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                    Text('${CurrencyFormatter.compact(totalDeposit, symbol: 'NZ\$')} total', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: theme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: DepositDonutPainter(
                          withdrawable: withdrawable,
                          grant: grant,
                          accentColor: theme.primaryColor,
                          secondaryColor: const Color(0xFFF5D060),
                          bgCol: theme.getBgColor(context),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(totalDeposit / 1000).toStringAsFixed(1)}K',
                                style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: textCol),
                              ),
                              Text('Deposit', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow('KiwiSaver', withdrawable, theme.primaryColor),
                          const SizedBox(height: 6),
                          _buildLegendRow('HomeStart Grant', grant, const Color(0xFFF5D060)),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Text('Property value cap:', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                          Text('Max \$${(priceCap / 1000).toInt()}K ($_region)', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: textCol)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // HomeStart Grant Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grant > 0 ? 'First Home Grant — You Qualify' : 'First Home Grant — Ineligible',
                          style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF92400E))),
                      Text(grant > 0
                          ? '$_propertyType · ${years.toInt()} yrs contributing · Income eligible'
                          : 'Exceeds \$95K single income limit or under 3 yrs contributions',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${(grant / 1000).toInt()}K', style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: const Color(0xFF78350F))),
                    Text('Eligible Grant', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF92400E))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Rules list
          Text('KEY RULES & STEPS', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _buildRuleStep(1, '3+ Year Contribution Minimum', 'Must have been a KiwiSaver member for at least 3 years to withdraw. You have contributed for ${years.toInt()} years.'),
          _buildRuleStep(2, '\$1,000 Must Stay in Account', 'IRD requires a minimum \$1,000 balance to remain in your KiwiSaver account after withdrawal. Withdrawable amount includes all tax credits.'),
          _buildRuleStep(3, 'House Price Cap — $_region', 'Max purchase price for existing homes in $_region: \$${(priceCap/1000).toInt()}K. Ensure your selected property falls below this cap.'),
          _buildRuleStep(4, 'Apply via IRD — My KiwiSaver', 'Submit withdrawal application through ird.govt.nz or myIR portal. Processing takes 10–15 working days before settlement.'),
        ],
      ),
    );
  }

  Widget _buildEligBadge(bool eligible, String passLabel, String failLabel, {bool isWarning = false}) {
    Color bg = eligible ? const Color(0xFFECFDF5) : isWarning ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2);
    Color textCol = eligible ? const Color(0xFF065F46) : isWarning ? const Color(0xFF92400E) : const Color(0xFFC0392B);
    Color border = eligible ? const Color(0xFFA7F3D0) : isWarning ? const Color(0xFFFDE68A) : const Color(0xFFFECACA);
    String icon = eligible ? '✅' : isWarning ? '⚠️' : '❌';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$icon ', style: const TextStyle(fontSize: 10)),
          Text(eligible ? passLabel : failLabel, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildResultBox(String label, double val, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF0D9488), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(CurrencyFormatter.compact(val, symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: const Color(0xFF0F766E))),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF0D9488)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String name, double val, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: theme.getTextColor(context)))),
        Text(CurrencyFormatter.compact(val, symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
      ],
    );
  }

  Widget _buildRuleStep(int num, String title, String desc) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: const Color(0xFF0D3B2E), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('$num', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DepositDonutPainter extends CustomPainter {
  final double withdrawable;
  final double grant;
  final Color accentColor;
  final Color secondaryColor;
  final Color bgCol;

  DepositDonutPainter({
    required this.withdrawable,
    required this.grant,
    required this.accentColor,
    required this.secondaryColor,
    required this.bgCol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = withdrawable + grant;
    final double sweep1 = total > 0 ? (withdrawable / total) * 2 * 3.1415926 : 2 * 3.1415926;
    final double sweep2 = total > 0 ? (grant / total) * 2 * 3.1415926 : 0.0;

    final Paint trackPaint = Paint()
      ..color = bgCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    final Paint slice1Paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;

    final Paint slice2Paint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - 16) / 2;

    // Draw track
    canvas.drawCircle(center, radius, trackPaint);

    const double startAngle = -3.1415926 / 2; // top

    // Draw first slice
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep1,
      false,
      slice1Paint,
    );

    // Draw second slice
    if (sweep2 > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweep1,
        sweep2,
        false,
        slice2Paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DepositDonutPainter oldDelegate) =>
      oldDelegate.withdrawable != withdrawable ||
      oldDelegate.grant != grant ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.bgCol != bgCol;
}
