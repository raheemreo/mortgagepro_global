// lib/features/australia/tools/au_dti_ratio.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUDtiRatio extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUDtiRatio({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUDtiRatio> createState() => _AUDtiRatioState();
}

class _AUDtiRatioState extends ConsumerState<AUDtiRatio> {
  double _income = 120000;
  double _partnerIncome = 0;
  double _newLoan = 600000;
  double _existingDebt = 20000;
  double _rate = 6.09;
  int _termYears = 30;

  bool _showResults = false;

  void _reset() {
    setState(() {
      _income = 120000;
      _partnerIncome = 0;
      _newLoan = 600000;
      _existingDebt = 20000;
      _rate = 6.09;
      _termYears = 30;
      _showResults = false;
    });
  }

  double _calcMonthly(double loan, double r, int n) {
    if (r == 0) return loan / n;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  void _saveCalculation() async {
    final totalIncome = _income + _partnerIncome;
    final totalDebt = _newLoan + _existingDebt;
    final dti = totalIncome > 0 ? totalDebt / totalIncome : 0.0;
    final r = _rate / 100 / 12;
    final br = (_rate + 3.0) / 100 / 12;
    final n = _termYears * 12;
    final monthly = _calcMonthly(_newLoan, r, n);
    final bufferRepay = _calcMonthly(_newLoan, br, n);

    double maxBorrow = 0.0;
    if (totalIncome > 0) {
      final cap30 =
          totalIncome * 0.30 / 12; // 30% of gross income monthly limit
      final annuityFactor = br > 0 ? (1 - pow(1 + br, -n)) / br : n.toDouble();
      maxBorrow = min(totalIncome * 6.0, cap30 * annuityFactor);
    }

    final labelCtrl = TextEditingController(text: 'DTI Check');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save DTI Check',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: DTI ${dti.toStringAsFixed(2)}x · Income \$${CurrencyFormatter.compact(totalIncome, symbol: 'AU\$')}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Pre-approval check)',
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
              backgroundColor: const Color(0xFF002868),
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
          : 'DTI Check';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'DTI Ratio',
        inputs: {
          'income': _income,
          'partnerIncome': _partnerIncome,
          'newLoan': _newLoan,
          'existingDebt': _existingDebt,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
        },
        results: {
          'dti': dti,
          'totalIncome': totalIncome,
          'totalDebt': totalDebt,
          'monthly': monthly,
          'bufferRepay': bufferRepay,
          'maxBorrow': maxBorrow,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF002868),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Calculations
    final totalIncome = _income + _partnerIncome;
    final totalDebt = _newLoan + _existingDebt;
    final dti = totalIncome > 0 ? totalDebt / totalIncome : 0.0;
    final r = _rate / 100 / 12;
    final br = (_rate + 3.0) / 100 / 12;
    final n = _termYears * 12;
    final monthly = _calcMonthly(_newLoan, r, n);
    final bufferRepay = _calcMonthly(_newLoan, br, n);

    double maxBorrow = 0.0;
    if (totalIncome > 0) {
      final cap30 =
          totalIncome * 0.30 / 12; // 30% of gross income monthly limit
      final annuityFactor = br > 0 ? (1 - pow(1 + br, -n)) / br : n.toDouble();
      maxBorrow = min(totalIncome * 6.0, cap30 * annuityFactor);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    String statusText;
    Color statusColor;
    Color statusBg;

    if (dti <= 5) {
      statusText = '✅ Excellent – Well within limits';
      statusColor = isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534);
      statusBg = isDark
          ? const Color(0xFF14532D).withValues(alpha: 0.4)
          : const Color(0xFFF0FDF4);
    } else if (dti <= 6) {
      statusText = '⚠️ Acceptable – Monitor closely';
      statusColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
      statusBg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.4)
          : const Color(0xFFFFFBEB);
    } else if (dti <= 7) {
      statusText = '🔶 High – Lender discretion';
      statusColor = isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412);
      statusBg = isDark
          ? const Color(0xFF7C2D12).withValues(alpha: 0.4)
          : const Color(0xFFFFF7ED);
    } else {
      statusText = '🔴 Very High – Likely declined';
      statusColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
      statusBg = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
          : const Color(0xFFFEF2F2);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A00), Color(0xFF7C2D12)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Debt-to-Income Ratio Calculator',
                      style: AppTextStyles.dmSans(
                          size: 9,
                          color: Colors.white60,
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFFD700),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('APRA Serviceability Check',
                  style: AppTextStyles.playfair(
                      size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Gross Annual Income',
                      prefix: 'AUD \$',
                      value: _income,
                      onChanged: (val) => setState(() => _income = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Partner Income (opt.)',
                      prefix: 'AUD \$',
                      value: _partnerIncome,
                      onChanged: (val) => setState(() => _partnerIncome = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Proposed Loan Amount',
                      prefix: 'AUD \$',
                      value: _newLoan,
                      onChanged: (val) => setState(() => _newLoan = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Existing Debt Total',
                      prefix: 'AUD \$',
                      value: _existingDebt,
                      onChanged: (val) => setState(() => _existingDebt = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Interest Rate %',
                      prefix: '',
                      value: _rate,
                      onChanged: (val) => setState(() => _rate = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Term (yrs)',
                      prefix: '',
                      value: _termYears.toDouble(),
                      isInteger: true,
                      onChanged: (val) =>
                          setState(() => _termYears = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002868),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 4,
                ),
                child: Text('📊 Check DTI Ratio',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DTI Result',
                  style: AppTextStyles.playfair(
                      size: 15, color: theme.getTextColor(context))),
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    border: Border.all(color: theme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('💾 Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : theme.primaryColor,
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Gauge Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Text('YOUR DEBT-TO-INCOME RATIO',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF92400E),
                        weight: FontWeight.w700,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                Text('${dti.toStringAsFixed(2)}x',
                    style: AppTextStyles.playfair(
                        size: 52, weight: FontWeight.w800, color: statusColor)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText,
                      style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w700,
                          color: statusColor)),
                ),
                const SizedBox(height: 16),

                // Colored progress bar track for DTI levels
                Column(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey[200],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(
                              flex: 50,
                              child: Container(
                                  color: const Color(0xFF16A34A))), // <= 5x
                          Expanded(
                              flex: 10,
                              child: Container(
                                  color: const Color(0xFFD97706))), // 5x - 6x
                          Expanded(
                              flex: 10,
                              child: Container(
                                  color: const Color(0xFFEA580C))), // 6x - 7x
                          Expanded(
                              flex: 30,
                              child: Container(
                                  color: const Color(0xFFDC2626))), // 7x+
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0x',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF92400E))),
                        Text('5x ✅',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF92400E))),
                        Text('6x ⚠️',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF92400E))),
                        Text('7x+',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF92400E))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Grid stats
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildSummaryBox(
                        context,
                        'Total Income',
                        CurrencyFormatter.format(totalIncome,
                            currencyCode: 'AUD')),
                    _buildSummaryBox(
                        context,
                        'Total Debt',
                        CurrencyFormatter.format(totalDebt,
                            currencyCode: 'AUD')),
                    _buildSummaryBox(context, 'Monthly Repay',
                        '${CurrencyFormatter.format(monthly, currencyCode: 'AUD')}/mo'),
                    _buildSummaryBox(context, 'Buffer Test Rate',
                        '${(_rate + 3.0).toStringAsFixed(2)}%'),
                    _buildSummaryBox(context, 'Buffer Repay',
                        '${CurrencyFormatter.format(bufferRepay, currencyCode: 'AUD')}/mo'),
                    _buildSummaryBox(
                        context,
                        'Max Borrowing',
                        CurrencyFormatter.format(maxBorrow,
                            currencyCode: 'AUD')),
                  ],
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Debt Breakdown',
                      style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF92400E))),
                ),
                const SizedBox(height: 10),
                _buildDebtBar(context, 'New Mortgage', _newLoan, totalDebt,
                    const Color(0xFF002868)),
                _buildDebtBar(context, 'Existing Debt', _existingDebt,
                    totalDebt, const Color(0xFFEA580C)),
              ],
            ),
          ),
        ],

        // Guide Cards
        const SizedBox(height: 20),
        Text('About DTI in Australia',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A150D), Color(0xFF140702)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                  ),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF7C2D12) : const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 APRA DTI & Serviceability Rules',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFFF9D7E)
                          : const Color(0xFF7C2D12))),
              const SizedBox(height: 12),
              _buildTipRow(context, '1',
                  'APRA\'s macroprudential guidance targets DTI ratios above 6x as "high" — most major lenders use 6–7x as a hard cap.'),
              _buildTipRow(context, '2',
                  'All lenders must apply a 3% serviceability buffer above the actual rate. At 6.09% that means testing at 9.09%.'),
              _buildTipRow(context, '3',
                  'Credit cards are assessed at 3.8% of limit per month regardless of actual usage — cancel unused cards before applying.'),
              _buildTipRow(context, '4',
                  'From June 2026, APRA proposed lowering the buffer to 2.5% for some borrowers switching lenders — refinancers may benefit.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    bool isInteger = false,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white54,
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15, color: Colors.white, weight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: isDark ? Colors.white70 : const Color(0xFF92400E),
                  weight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 13,
                  color: isDark ? Colors.white : Colors.black,
                  weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDebtBar(BuildContext context, String label, double amount,
      double total, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: AppTextStyles.dmSans(
                      size: 10,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF92400E)))),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(4))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 60,
              child: Text(CurrencyFormatter.format(amount, currencyCode: 'AUD'),
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTipRow(BuildContext context, String bullet, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFFC2410C) : const Color(0xFFEA580C),
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(bullet,
                style: AppTextStyles.dmSans(
                    size: 9, color: Colors.white, weight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    color: isDark
                        ? const Color(0xFFFFE3D3)
                        : const Color(0xFF92400E),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
