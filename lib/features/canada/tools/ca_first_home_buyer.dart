// lib/features/canada/tools/ca_first_home_buyer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CAFirstHomeBuyer extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAFirstHomeBuyer({super.key, required this.theme});

  @override
  ConsumerState<CAFirstHomeBuyer> createState() => _CAFirstHomeBuyerState();
}

class _CAFirstHomeBuyerState extends ConsumerState<CAFirstHomeBuyer> {
  final _fhsaController = TextEditingController(text: '32000');
  final _hbpController = TextEditingController(text: '40000');
  final _savingsController = TextEditingController(text: '25000');
  final _cobuyController = TextEditingController(text: '0');

  bool _showFhsaDetails = false;
  bool _showHbpDetails = false;
  bool _showRebateDetails = false;
  bool _hasCalculated = true; // Show results initially with default values

  @override
  void dispose() {
    _fhsaController.dispose();
    _hbpController.dispose();
    _savingsController.dispose();
    _cobuyController.dispose();
    super.dispose();
  }

  void _saveScenario(double total, double maxHomePrice, bool isCmhc, double pctOf700k) async {
    final labelCtrl = TextEditingController(text: 'First-Home Savings');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Down Payment',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving Scenario: Total Down Payment ${CurrencyFormatter.compact(total, symbol: 'CA\$')}',
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Down Payment Plan)',
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
                    size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
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
          : 'First-Home Savings';

      final fhsa = double.tryParse(_fhsaController.text) ?? 0;
      final hbp = double.tryParse(_hbpController.text) ?? 0;
      final sav = double.tryParse(_savingsController.text) ?? 0;
      final co = double.tryParse(_cobuyController.text) ?? 0;

      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'First-Home Buyer Incentive',
        inputs: {
          'FHSA Balance': fhsa,
          'HBP Withdrawal': hbp,
          'Personal Savings': sav,
          'Co-buyer Amount': co,
        },
        results: {
          'Total Down Pymt': total,
          'Max Home Price': maxHomePrice,
          'CMHC Required': isCmhc ? 1.0 : 0.0,
          'Percent of 700K': pctOf700k,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Down payment scenario saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Read input values
    final double fhsa = double.tryParse(_fhsaController.text) ?? 0;
    final double hbp = double.tryParse(_hbpController.text) ?? 0;
    final double sav = double.tryParse(_savingsController.text) ?? 0;
    final double co = double.tryParse(_cobuyController.text) ?? 0;

    // Max HBP is officially $60,000 per person
    final double cappedHbp = hbp.clamp(0, 60000);

    final double totalDown = fhsa + cappedHbp + sav + co;
    final double maxHomePrice = totalDown / 0.05; // 5% minimum down payment standard
    const double baselineHome = 700000;
    final double pctOf700k = (totalDown / baselineHome) * 100;
    final bool isCmhcRequired = pctOf700k < 20.0;

    // Live BoC rates — for payment estimate
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final live5yr = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final isLive = ratesAsync.valueOrNull?.isLive == true;


    final double loanAmt = (maxHomePrice - totalDown).clamp(0, double.infinity);
    final double biweeklyPmt = loanAmt > 0 && live5yr > 0
        ? () {
            final double r = (((1 + live5yr / 200) * (1 + live5yr / 200)) - 1) / 26;
            const int n = 25 * 26;
            return loanAmt * r / (1 - (1 / ((1 + r) * n)));
          }()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Savings Programs Section
        Text(
          'SAVINGS PROGRAMS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        // FHSA Card
        _buildProgramCard(
          icon: '🏦',
          title: 'First Home Savings Account (FHSA)',
          subtitle: 'Tax-deductible contributions + tax-free withdrawals. Best first-time buyer tool in Canada.',
          badge: 'Launched 2023 · Active 2026',
          badgeBg: const Color(0xFFF0FDF4),
          badgeTextCol: const Color(0xFF166534),
          stats: [
            {'val': '\$8K', 'lbl': 'Annual limit', 'grn': 'true'},
            {'val': '\$40K', 'lbl': 'Lifetime max', 'grn': 'true'},
            {'val': '15 yr', 'lbl': 'Account life', 'grn': 'false'},
          ],
          showDetails: _showFhsaDetails,
          onToggleDetails: () => setState(() => _showFhsaDetails = !_showFhsaDetails),
          detailsRows: [
            {'lbl': 'Eligibility', 'val': 'Canadian resident, 18–71, never owned', 'grn': 'false'},
            {'lbl': 'Annual contribution', 'val': 'CA\$8,000/year', 'grn': 'true'},
            {'lbl': 'Lifetime limit', 'val': 'CA\$40,000', 'grn': 'true'},
            {'lbl': 'Carry-forward', 'val': 'Up to \$8K unused room (1 yr)', 'grn': 'false'},
            {'lbl': 'Tax deduction going in', 'val': '✓ Yes (like RRSP)', 'grn': 'true'},
            {'lbl': 'Tax-free withdrawal', 'val': '✓ Yes (like TFSA)', 'grn': 'true'},
            {'lbl': 'Repayment required?', 'val': 'No repayment needed', 'grn': 'true'},
            {'lbl': 'If you don\'t buy', 'val': 'Transfer to RRSP tax-free', 'grn': 'false'},
            {'lbl': 'Tax saving (30% bracket)', 'val': '~CA\$2,400/yr on \$8K', 'grn': 'true'},
          ],
        ),
        const SizedBox(height: 10),

        // HBP Card
        _buildProgramCard(
          icon: '📋',
          title: 'RRSP Home Buyers\' Plan (HBP)',
          subtitle: 'Withdraw from your RRSP for a first home. Limit raised to \$60K in April 2024.',
          badge: 'Limit raised Apr 2024',
          badgeBg: const Color(0xFFEFF6FF),
          badgeTextCol: const Color(0xFF1D4ED8),
          stats: [
            {'val': '\$60K', 'lbl': 'Per person', 'grn': 'false'},
            {'val': '\$120K', 'lbl': 'Couple max', 'grn': 'true'},
            {'val': '15 yr', 'lbl': 'Repay period', 'grn': 'false'},
          ],
          showDetails: _showHbpDetails,
          onToggleDetails: () => setState(() => _showHbpDetails = !_showHbpDetails),
          detailsRows: [
            {'lbl': 'Withdrawal limit (2026)', 'val': 'CA\$60,000 per person', 'grn': 'false'},
            {'lbl': 'Couple combined', 'val': 'CA\$120,000 total', 'grn': 'true'},
            {'lbl': 'Repayment period', 'val': '15 years', 'grn': 'false'},
            {'lbl': 'Repayment start', 'val': '2 years after withdrawal', 'grn': 'false'},
            {'lbl': 'Grace period (2022–2025)', 'val': '5-yr grace for HBPs made Jan 2022–Dec 2025', 'grn': 'false'},
            {'lbl': 'Annual repayment', 'val': '1/15th of withdrawn amount', 'grn': 'false'},
            {'lbl': 'If not repaid', 'val': 'Added to taxable income', 'grn': 'false'},
            {'lbl': 'Can combine with FHSA?', 'val': '✓ Yes — use both!', 'grn': 'true'},
          ],
        ),
        const SizedBox(height: 10),

        // LTT Rebates Card
        _buildProgramCard(
          icon: '🏛️',
          title: 'Land Transfer Tax Rebates',
          subtitle: 'Provincial rebates for first-time buyers at closing. Ontario & BC most impactful.',
          badge: 'Applied at closing',
          badgeBg: const Color(0xFFFFFBEB),
          badgeTextCol: const Color(0xFF92400E),
          stats: [
            {'val': '\$4K', 'lbl': 'Ontario max', 'grn': 'false'},
            {'val': '\$4,475', 'lbl': 'Toronto +', 'grn': 'false'},
            {'val': 'Full', 'lbl': 'BC ≤\$500K', 'grn': 'true'},
          ],
          showDetails: _showRebateDetails,
          onToggleDetails: () => setState(() => _showRebateDetails = !_showRebateDetails),
          detailsRows: [
            {'lbl': 'Ontario provincial rebate', 'val': 'Up to CA\$4,000', 'grn': 'true'},
            {'lbl': 'Toronto municipal rebate', 'val': 'Up to CA\$4,475', 'grn': 'true'},
            {'lbl': 'Toronto combined max', 'val': 'CA\$8,475', 'grn': 'true'},
            {'lbl': 'BC (homes ≤\$500K)', 'val': 'Full PTT exemption', 'grn': 'true'},
            {'lbl': 'BC (homes \$500K–\$525K)', 'val': 'Partial rebate (pro-rated)', 'grn': 'false'},
            {'lbl': 'PEI', 'val': 'Exempt on homes <\$200K', 'grn': 'true'},
            {'lbl': 'Alberta / Saskatchewan', 'val': 'No LTT — small reg fee only', 'grn': 'false'},
            {'lbl': 'Quebec, MB, NS, NB', 'val': 'No FTHB rebate', 'grn': 'false'},
          ],
        ),
        const SizedBox(height: 20),

        // Down Payment Calculator Section
        Text(
          'MAX DOWN PAYMENT CALCULATOR',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildCalcField('FHSA balance', 'Contributions + growth', _fhsaController),
              const Divider(height: 20, thickness: 0.5),
              _buildCalcField('RRSP HBP withdrawal', 'Up to \$60K per person', _hbpController),
              const Divider(height: 20, thickness: 0.5),
              _buildCalcField('Personal savings', 'Non-registered savings', _savingsController),
              const Divider(height: 20, thickness: 0.5),
              _buildCalcField('Co-buyer FHSA/HBP', 'Spouse/partner (optional)', _cobuyController),
            ],
          ),
        ),
        const SizedBox(height: 12),

        ElevatedButton(
          onPressed: () {
            setState(() {
              _hasCalculated = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size.fromHeight(48),
            elevation: 2,
          ),
          child: Text(
            '🏡 Calculate My Down Payment',
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),

        if (_hasCalculated) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR CALCULATOR RESULT',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.bold,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.6,
                ),
              ),
              GestureDetector(
                onTap: () => _saveScenario(totalDown, maxHomePrice, isCmhcRequired, pctOf700k),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('💾', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL AVAILABLE DOWN PAYMENT',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: Colors.white60,
                    weight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'CA\$',
                      style: AppTextStyles.dmSans(
                        size: 18,
                        weight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(totalDown, symbol: ''),
                      style: AppTextStyles.playfair(
                        size: 36,
                        weight: FontWeight.w800,
                        color: const Color(0xFF6EDFA0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _resultMiniBox('Affordable Home (5% down)', maxHomePrice),
                    const SizedBox(width: 8),
                    _resultMiniBox('CMHC Needed? (700K baseline)', null, customString: isCmhcRequired ? '✓ Yes' : '✗ No (≥20%)'),
                    const SizedBox(width: 8),
                    _resultMiniBox('Down Pymt % (on 700K)', null, customString: '${pctOf700k.toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Live rate payment context card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '📊 Est. Payment at Live Rate',
                      style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.bold,
                        color: theme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFFDCF4E8)
                            : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLive ? '🟢 Live BoC' : 'Estimated',
                        style: AppTextStyles.dmSans(
                          size: 8.5,
                          weight: FontWeight.bold,
                          color: isLive
                              ? const Color(0xFF1A5C35)
                              : theme.getMutedColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5-Yr Fixed Rate',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                      ),
                    ),
                    Text(
                      '${live5yr.toStringAsFixed(2)}%',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Loan Amount',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                      ),
                    ),
                    Text(
                      loanAmt > 0
                          ? 'CA\$${(loanAmt / 1000).toStringAsFixed(0)}K'
                          : 'CA\$0',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.bold,
                        color: theme.getTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, thickness: 0.4),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Est. Bi-Weekly Payment',
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.bold,
                        color: theme.getTextColor(context),
                      ),
                    ),
                    Text(
                      biweeklyPmt > 0
                          ? 'CA\$${biweeklyPmt.toStringAsFixed(0)}/bi-wk'
                          : '—',
                      style: AppTextStyles.playfair(
                        size: 16,
                        weight: FontWeight.w800,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Optimal Strategy Timeline
        Text(
          'OPTIMAL 2026 STRATEGY',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildStrategyRow(1, 'Max FHSA First (\$8K/yr)', 'Double tax benefit — deduction in, tax-free out. Outperforms HBP for new savings.'),
              const Divider(height: 20, thickness: 0.5),
              _buildStrategyRow(2, 'Add RRSP HBP (\$60K per person)', 'Combine with FHSA for \$100K combined buying power per person. Repay over 15 years.'),
              const Divider(height: 20, thickness: 0.5),
              _buildStrategyRow(3, 'Claim LTT Rebate at Closing', 'Your lawyer handles it — up to \$8,475 back in Toronto; \$4,000 in Ontario.'),
              const Divider(height: 20, thickness: 0.5),
              _buildStrategyRow(4, 'Defer FHSA Deduction if Income Rises', 'Contribute now for tax-free growth; claim deduction in a higher-income year.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalcField(String label, String sub, TextEditingController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.bold,
                color: widget.theme.getTextColor(context),
              ),
            ),
            Text(
              sub,
              style: AppTextStyles.dmSans(
                size: 10,
                color: widget.theme.getMutedColor(context),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'CA\$',
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.bold,
                color: widget.theme.getMutedColor(context),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 100,
              height: 38,
              decoration: BoxDecoration(
                color: widget.theme.getBgColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.theme.getBorderColor(context)),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.bold,
                  color: widget.theme.getTextColor(context),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultMiniBox(String label, double? val, {String? customString}) {
    final displayVal = customString ?? CurrencyFormatter.format(val ?? 0, symbol: 'CA\$');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white60),
            ),
            const SizedBox(height: 2),
            Text(
              displayVal,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard({
    required String icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeBg,
    required Color badgeTextCol,
    required List<Map<String, String>> stats,
    required bool showDetails,
    required VoidCallback onToggleDetails,
    required List<Map<String, String>> detailsRows,
  }) {
    final theme = widget.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.playfair(
                          size: 14,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: AppTextStyles.dmSans(
                            size: 9,
                            weight: FontWeight.bold,
                            color: badgeTextCol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats boxes row
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.getBorderColor(context)),
                bottom: BorderSide(color: theme.getBorderColor(context)),
              ),
            ),
            child: Row(
              children: stats.map((s) {
                final isGreen = s['grn'] == 'true';
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        right: stats.last == s
                            ? BorderSide.none
                            : BorderSide(color: theme.getBorderColor(context)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          s['val']!,
                          style: AppTextStyles.playfair(
                            size: 15,
                            weight: FontWeight.w800,
                            color: isGreen ? const Color(0xFF1A5C35) : theme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['lbl']!.toUpperCase(),
                          style: AppTextStyles.dmSans(
                            size: 8,
                            color: theme.getMutedColor(context),
                            weight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Accordion details panel
          if (showDetails)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.getBgColor(context).withValues(alpha: 0.5),
              child: Column(
                children: detailsRows.map((dr) {
                  final isGreen = dr['grn'] == 'true';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 3,
                          child: Text(
                            dr['lbl']!,
                            style: AppTextStyles.dmSans(
                              size: 11,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 2,
                          child: Text(
                            dr['val']!,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.bold,
                              color: isGreen ? const Color(0xFF1A5C35) : theme.getTextColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          // Toggle button
          GestureDetector(
            onTap: onToggleDetails,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: theme.getBgColor(context).withValues(alpha: 0.2),
              alignment: Alignment.center,
              child: Text(
                showDetails ? '▲ Hide Details' : '▼ Show Details',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: const Color(0xFF1A5C35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyRow(int step, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF1A5C35),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.bold,
                    color: widget.theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: widget.theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
