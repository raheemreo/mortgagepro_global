// lib/features/newzealand/tools/nz_kiwisaver_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZKiwiSaverCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZKiwiSaverCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZKiwiSaverCalc> createState() => _NZKiwiSaverCalcState();
}

class _NZKiwiSaverCalcState extends ConsumerState<NZKiwiSaverCalc> {
  final _balanceController = TextEditingController(text: '45000');
  final _yearsController = TextEditingController(text: '5');
  final _priceController = TextEditingController(text: '700000');
  final _savingsController = TextEditingController(text: '30000');

  String _propType = 'existing'; // 'existing' | 'newbuild'
  String _prevWithdraw = 'no'; // 'no' | 'yes'

  bool _showResults = false;

  @override
  void dispose() {
    _balanceController.dispose();
    _yearsController.dispose();
    _priceController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  void _saveCalculation() async {
    final double bal = double.tryParse(_balanceController.text) ?? 0;
    final double yrs = double.tryParse(_yearsController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0;
    final double own = double.tryParse(_savingsController.text) ?? 0;

    final yrOk = yrs >= 3;
    final prevOk = _prevWithdraw == 'no';
    final balOk = bal > 1000;
    final isEligible = yrOk && prevOk && balOk;

    final double withdrawal = isEligible ? max(0.0, bal - 1000.0) : 0.0;
    final double grant = isEligible ? (_propType == 'newbuild' ? 10000.0 : 5000.0) : 0.0;
    final double totalDeposit = withdrawal + grant + own;

    final labelCtrl = TextEditingController(text: 'NZ KiwiSaver Deposit');
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
              'Saving: KiwiSaver ${CurrencyFormatter.compact(bal, symbol: 'NZ\$')} · Deposit: ${CurrencyFormatter.compact(totalDeposit, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Auckland First Home)',
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
              backgroundColor: const Color(0xFF1A6B4A),
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
          : 'KiwiSaver Calc';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'KiwiSaver Calc',
        inputs: {
          'ksBalance': bal,
          'ksYears': yrs,
          'propPrice': price,
          'ownSavings': own,
          'propType': _propType == 'newbuild' ? 1.0 : 0.0,
          'prevWithdraw': _prevWithdraw == 'yes' ? 1.0 : 0.0,
        },
        results: {
          'withdrawal': withdrawal,
          'grant': grant,
          'totalDeposit': totalDeposit,
          'eligible': isEligible ? 1.0 : 0.0,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ KiwiSaver calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final double bal = double.tryParse(_balanceController.text) ?? 0;
    final double yrs = double.tryParse(_yearsController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0;
    final double own = double.tryParse(_savingsController.text) ?? 0;

    final yrOk = yrs >= 3;
    final prevOk = _prevWithdraw == 'no';
    final balOk = bal > 1000;
    final isEligible = yrOk && prevOk && balOk;

    final double withdrawal = isEligible ? max(0.0, bal - 1000.0) : 0.0;
    final double grant = isEligible ? (_propType == 'newbuild' ? 10000.0 : 5000.0) : 0.0;
    final double totalDeposit = withdrawal + grant + own;
    final double depositPct = price > 0 ? (totalDeposit / price) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'First Home Withdrawal',
              style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                border: Border.all(color: const Color(0xFF5EEAD4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '3yr min',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFF0F766E), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D3B2E), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KIWISAVER FIRST HOME · TE KĀINGA TUATAHI',
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white70,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 16, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'Calculate your '),
                    TextSpan(text: 'KiwiSaver', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: '\nFirst Home amount'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inputs Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'KiwiSaver Balance (NZD)',
                      controller: _balanceController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Years in KiwiSaver',
                      controller: _yearsController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Inputs Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Property Type',
                      value: _propType,
                      items: const [
                        DropdownMenuItem(value: 'existing', child: Text('Existing Home')),
                        DropdownMenuItem(value: 'newbuild', child: Text('New Build')),
                      ],
                      onChanged: (val) => setState(() => _propType = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroDropdown(
                      label: 'Prior Withdrawal?',
                      value: _prevWithdraw,
                      items: const [
                        DropdownMenuItem(value: 'no', child: Text('No')),
                        DropdownMenuItem(value: 'yes', child: Text('Yes')),
                      ],
                      onChanged: (val) => setState(() => _prevWithdraw = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Inputs Row 3
              Row(
                children: [
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Property Price (NZD)',
                      controller: _priceController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroInputBox(
                      label: 'Own Savings (NZD)',
                      controller: _savingsController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calculate Button
              ElevatedButton(
                onPressed: () => setState(() => _showResults = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0F0D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🥝 Calculate Withdrawal',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Eligibility Check card
        Text(
          'Eligibility Check',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 KiwiSaver First Home Criteria',
                style: AppTextStyles.dmSans(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildEligRow(
                icon: yrOk ? '✅' : '❌',
                isOk: yrOk,
                title: '3-Year Minimum Membership',
                sub: 'Must be a KiwiSaver member for 3+ years',
                valueText: yrOk ? '✓ ${yrs.toInt()} years' : '✗ ${yrs.toInt()} yrs (need 3+)',
              ),
              const Divider(height: 16),
              _buildEligRow(
                icon: prevOk ? '✅' : '❌',
                isOk: prevOk,
                title: 'First Home Buyer',
                sub: 'Never owned property in NZ before',
                valueText: prevOk ? '✓ First home' : '✗ Previous use',
              ),
              const Divider(height: 16),
              _buildEligRow(
                icon: balOk ? '✅' : '❌',
                isOk: balOk,
                title: 'Minimum \$1,000 Remains',
                sub: '\$1,000 must stay in KiwiSaver account',
                valueText: balOk ? '✓ Sufficient' : '✗ Low balance',
              ),
              const Divider(height: 16),
              _buildEligRow(
                icon: '✅',
                isOk: true,
                title: 'NZ Property for Living In',
                sub: 'Must intend to live in the property',
                valueText: '✓ Required',
              ),
            ],
          ),
        ),

        // Results Box
        if (_showResults) ...[
          const SizedBox(height: 20),
          Text(
            'Your Withdrawal Result',
            style: AppTextStyles.playfair(
                size: 12,
                weight: FontWeight.w800,
                color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KiwiSaver Withdrawal',
                      style: AppTextStyles.dmSans(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isEligible ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEligible ? 'Eligible' : 'Not Eligible',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          weight: FontWeight.w800,
                          color: isEligible ? const Color(0xFF065F46) : const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Estimated Withdrawal Amount',
                        style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(withdrawal, currencyCode: 'NZD'),
                        style: AppTextStyles.playfair(
                          size: 28,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEligible
                            ? 'Total deposit with HomeStart & savings: ${CurrencyFormatter.compact(totalDeposit, symbol: 'NZ\$')} (${depositPct.toStringAsFixed(1)}% of property)'
                            : 'Check eligibility criteria above.',
                        style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        label: 'KiwiSaver',
                        val: isEligible ? CurrencyFormatter.compact(withdrawal, symbol: 'NZ\$') : '—',
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        label: 'HomeStart',
                        val: isEligible ? CurrencyFormatter.compact(grant, symbol: 'NZ\$') : '—',
                        color: const Color(0xFFD4A017),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        label: 'Total Deposit',
                        val: isEligible ? CurrencyFormatter.compact(totalDeposit, symbol: 'NZ\$') : '—',
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                if (isEligible) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Your Deposit Breakdown',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.bold,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Bar Breakdown
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        if (withdrawal > 0)
                          Expanded(
                            flex: (withdrawal / totalDeposit * 1000).toInt(),
                            child: Container(
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        if (grant > 0)
                          Expanded(
                            flex: (grant / totalDeposit * 1000).toInt(),
                            child: Container(
                              color: const Color(0xFFD4A017),
                            ),
                          ),
                        if (own > 0)
                          Expanded(
                            flex: (own / totalDeposit * 1000).toInt(),
                            child: Container(
                              color: const Color(0xFF1A6B4A),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildLegendDot(
                          label: 'KiwiSaver: ${CurrencyFormatter.compact(withdrawal, symbol: 'NZ\$')}',
                          color: const Color(0xFF0D9488)),
                      _buildLegendDot(
                          label: 'HomeStart: ${CurrencyFormatter.compact(grant, symbol: 'NZ\$')}',
                          color: const Color(0xFFD4A017)),
                      _buildLegendDot(
                          label: 'Own Savings: ${CurrencyFormatter.compact(own, symbol: 'NZ\$')}',
                          color: const Color(0xFF1A6B4A)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Save Button
          ElevatedButton.icon(
            onPressed: _saveCalculation,
            icon: const Text('💾', style: TextStyle(fontSize: 14)),
            label: Text(
              'Save This Calculation',
              style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Rules and Limits card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rules & Limits 2025',
              style: AppTextStyles.playfair(
                  size: 12,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Current',
                style: AppTextStyles.dmSans(
                    size: 8, color: const Color(0xFF991B1B), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF5EEAD4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🥝 KiwiSaver First Home Rules',
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 8),
              _buildRuleRow('Minimum KiwiSaver term', '3 years'),
              _buildRuleRow('Amount you can withdraw', 'All except \$1,000'),
              _buildRuleRow('Previous withdrawals', 'Disqualifies (FHW)'),
              _buildRuleRow('HomeStart grant (new build)', 'Up to \$10,000'),
              _buildRuleRow('HomeStart grant (existing)', 'Up to \$5,000'),
              _buildRuleRow('Income cap (single)', 'NZ\$95,000 p.a.'),
              _buildRuleRow('Income cap (couple)', 'NZ\$150,000 p.a.'),
              _buildRuleRow('Price cap (Auckland)', 'NZ\$875,000 (new) / \$650,000 (exist)'),
              _buildRuleRow('Administered by', 'Kāinga Ora'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroInputBox({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF0D3B2E),
              style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEligRow({
    required String icon,
    required bool isOk,
    required String title,
    required String sub,
    required String valueText,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.bold,
                    color: widget.theme.getTextColor(context)),
              ),
              Text(
                sub,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        Text(
          valueText,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w800,
            color: isOk ? const Color(0xFF059669) : const Color(0xFFC0392B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({required String label, required String val, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _buildRuleRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF0D9488)),
          ),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: const Color(0xFF0F766E)),
          ),
        ],
      ),
    );
  }
}
