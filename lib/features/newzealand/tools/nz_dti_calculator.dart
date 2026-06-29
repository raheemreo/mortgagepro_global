// lib/features/newzealand/tools/nz_dti_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZDtiCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZDtiCalculator({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZDtiCalculator> createState() => _NZDtiCalculatorState();
}

class _NZDtiCalculatorState extends ConsumerState<NZDtiCalculator> {
  double _borrower1Income = 95000;
  double _borrower2Income = 70000;
  double _otherIncome = 0;
  String _borrowerType = 'owner'; // 'owner' or 'investor'
  double _newLoanAmt = 680000;

  double _existingMortgage = 0;
  double _carLoan = 18000;
  double _creditCardLimits = 12000;
  double _studentLoan = 0;
  double _otherDebts = 0;

  bool _showResults = false;

  void _reset() {
    setState(() {
      _borrower1Income = 95000;
      _borrower2Income = 70000;
      _otherIncome = 0;
      _borrowerType = 'owner';
      _newLoanAmt = 680000;
      _existingMortgage = 0;
      _carLoan = 18000;
      _creditCardLimits = 12000;
      _studentLoan = 0;
      _otherDebts = 0;
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final totalIncome = _borrower1Income + _borrower2Income + _otherIncome;
    final totalDebt = _existingMortgage +
        _carLoan +
        _creditCardLimits +
        _studentLoan +
        _otherDebts +
        _newLoanAmt;
    final dti = totalIncome > 0 ? totalDebt / totalIncome : 0.0;

    final labelCtrl = TextEditingController(text: 'NZ DTI Snapshot');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_dti_calculator/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save DTI Assessment',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: DTI Ratio ${dti.toStringAsFixed(1)}x for ${CurrencyFormatter.compact(totalIncome, symbol: "NZ\$")} income',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Joint Application)',
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
          : 'DTI Calculator';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'DTI Calculator',
        inputs: {
          'borrower1Income': _borrower1Income,
          'borrower2Income': _borrower2Income,
          'otherIncome': _otherIncome,
          'newLoan': _newLoanAmt,
          'existingMortgage': _existingMortgage,
          'carLoan': _carLoan,
          'creditCards': _creditCardLimits,
          'studentLoan': _studentLoan,
          'otherDebts': _otherDebts,
          'borrowerType': _borrowerType == 'owner' ? 0.0 : 1.0,
        },
        results: {
          'dti': dti,
          'totalIncome': totalIncome,
          'totalDebt': totalDebt,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ DTI assessment saved!',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculations
    final totalIncome = _borrower1Income + _borrower2Income + _otherIncome;
    final existingDebt = _existingMortgage +
        _carLoan +
        _creditCardLimits +
        _studentLoan +
        _otherDebts;
    final totalDebt = existingDebt + _newLoanAmt;
    final dti = totalIncome > 0 ? totalDebt / totalIncome : 0.0;
    final cap = _borrowerType == 'owner' ? 6 : 7;

    final maxBorrow6 = (totalIncome * 6) - existingDebt;
    final maxBorrow7 = (totalIncome * 7) - existingDebt;
    final maxBorrow5 = (totalIncome * 5) - existingDebt;
    final remaining = (totalIncome * cap) - totalDebt;

    String statusText;
    Color statusColor;
    if (dti < 4) {
      statusText = '✅ Excellent — Strong approval';
      statusColor = const Color(0xFF6EE7B7);
    } else if (dti < 5) {
      statusText = '✅ Good — Standard approval';
      statusColor = const Color(0xFF6EE7B7);
    } else if (dti < cap) {
      statusText = '⚠️ Caution — Near RBNZ limit';
      statusColor = const Color(0xFFFDE68A);
    } else if (dti < 7) {
      statusText = '❌ Over owner-occ limit (6×)';
      statusColor = const Color(0xFFFCA5A5);
    } else {
      statusText = '❌ Exceeds all NZ DTI caps';
      statusColor = const Color(0xFFFCA5A5);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // RBNZ Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF78350F).withValues(alpha: 0.3)
                : const Color(0xFFFEF3C7),
            border: Border.all(
                color:
                    isDark ? const Color(0xFFB45309) : const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚠️ RBNZ DTI Limits (from 1 Jul 2024)',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF92400E))),
              const SizedBox(height: 4),
              Text(
                'Owner-occupiers: max 6× gross income (80% of new lending)\n'
                'Investors: max 7× gross income (90% of new lending)\n'
                'Some banks use stricter internal limits (5.0–5.5×)',
                style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFB45309),
                    height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DTI Income & Debt Setup',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFC0392B),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('DTI Assessment Details',
                  style: AppTextStyles.playfair(
                      size: 18,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Incomes
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Borrower 1 Income (Yr)',
                      prefix: 'NZD \$',
                      value: _borrower1Income,
                      onChanged: (val) =>
                          setState(() => _borrower1Income = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Borrower 2 Income (Yr)',
                      prefix: 'NZD \$',
                      value: _borrower2Income,
                      onChanged: (val) =>
                          setState(() => _borrower2Income = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Other Annual Income',
                      prefix: 'NZD \$',
                      value: _otherIncome,
                      onChanged: (val) => setState(() => _otherIncome = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFEDF5F2),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : const Color(0x150D3B2E)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Borrower Type',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF4A6358),
                                  weight: FontWeight.w600)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _borrowerType,
                              isDense: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0A0F0D),
                                  weight: FontWeight.w700),
                              items: const [
                                DropdownMenuItem(
                                    value: 'owner',
                                    child: Text('Owner-Occupier (6x)')),
                                DropdownMenuItem(
                                    value: 'investor',
                                    child: Text('Investor (7x)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _borrowerType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Text('Existing Debt Balances',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: theme.getMutedColor(context))),
              const SizedBox(height: 8),

              _buildDebtItem('🏠', 'Existing Mortgage', _existingMortgage,
                  (v) => setState(() => _existingMortgage = v)),
              const SizedBox(height: 6),
              _buildDebtItem('🚗', 'Car Loan Balance', _carLoan,
                  (v) => setState(() => _carLoan = v)),
              const SizedBox(height: 6),
              _buildDebtItem('💳', 'Credit Card Limits', _creditCardLimits,
                  (v) => setState(() => _creditCardLimits = v)),
              const SizedBox(height: 6),
              _buildDebtItem('📚', 'Student Loan (NZ)', _studentLoan,
                  (v) => setState(() => _studentLoan = v)),
              const SizedBox(height: 6),
              _buildDebtItem('💰', 'Other Debts', _otherDebts,
                  (v) => setState(() => _otherDebts = v)),

              const SizedBox(height: 12),
              _buildInputBox(
                label: 'New Proposed Loan Amount',
                prefix: 'NZD \$',
                value: _newLoanAmt,
                onChanged: (val) => setState(() => _newLoanAmt = val),
              ),

              const SizedBox(height: 14),
              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (totalIncome <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Please enter valid income details',
                              style: AppTextStyles.dmSans())),
                    );
                    return;
                  }
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('📈 Calculate DTI Ratio',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results
        if (_showResults) ...[
          const SizedBox(height: 20),
          Text('Your DTI Result',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

          // Needle gauge card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('Debt-to-Income Ratio',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white60,
                        weight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  height: 110,
                  child: CustomPaint(
                    painter: _NZDtiGaugePainter(dti: dti),
                  ),
                ),
                const SizedBox(height: 10),
                Text('${dti.toStringAsFixed(1)}×',
                    style: AppTextStyles.playfair(
                        size: 30,
                        color: const Color(0xFFF5D060),
                        weight: FontWeight.w800)),
                Text(statusText,
                    style: AppTextStyles.dmSans(
                        size: 12, weight: FontWeight.w800, color: statusColor)),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.compact(totalDebt, symbol: "NZ\$")} debt / ${CurrencyFormatter.compact(totalIncome, symbol: "NZ\$")} income',
                  style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGaugeSummary('Total Debt',
                        CurrencyFormatter.compact(totalDebt, symbol: 'NZ\$')),
                    _buildGaugeSummary('Gross Income',
                        CurrencyFormatter.compact(totalIncome, symbol: 'NZ\$')),
                    _buildGaugeSummary(
                        'Max Borrow',
                        CurrencyFormatter.compact(totalIncome * cap,
                            symbol: 'NZ\$')),
                  ],
                ),
              ],
            ),
          ),

          // Max borrowing card
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF115E59).withValues(alpha: 0.3)
                  : const Color(0xFFF0FDFA),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF5EEAD4)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏠 Maximum Borrowing Capacity (NZD)',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFF0F766E))),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildMaxBorrowBox('At 6x (Owner-Occ)', maxBorrow6),
                    _buildMaxBorrowBox('At 7x (Investor)', maxBorrow7),
                    _buildMaxBorrowBox('At 5x (Bank Strict)', maxBorrow5),
                    _buildMaxBorrowBox('Remaining at ${cap}x', remaining,
                        isSpecial: true),
                  ],
                ),
              ],
            ),
          ),

          // DTI Bands list
          const SizedBox(height: 20),
          Text('DTI Bands Guide',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildBandRow('0–4×', 'Excellent', 'Easy approval, best rates',
                    '✅ Strong', const Color(0xFF1A6B4A), dti < 4, theme),
                _buildBandRow(
                    '4–5×',
                    'Good',
                    'Standard NZ bank approval',
                    '✅ OK',
                    const Color(0xFF65A30D),
                    dti >= 4 && dti < 5,
                    theme),
                _buildBandRow(
                    '5–6×',
                    'Caution',
                    'Near RBNZ owner-occ cap',
                    '⚠️ Border',
                    const Color(0xFFD97706),
                    dti >= 5 && dti < 6,
                    theme),
                _buildBandRow(
                    '6–7×',
                    'Over Limit',
                    'Exceeds owner-occ cap (6×)',
                    '❌ Limit',
                    const Color(0xFFC0392B),
                    dti >= 6 && dti < 7,
                    theme),
                _buildBandRow('7×+', 'Declined', 'Exceeds all NZ DTI caps',
                    '❌ Declined', const Color(0xFF0A0F0D), dti >= 7, theme),
              ],
            ),
          ),

          // Save Calculation Card
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💾 Save DTI assessment',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    Text('Income & debt snapshot saved',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFEDF5F2),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0x150D3B2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: isDark ? Colors.white70 : const Color(0xFF4A6358),
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF4A6358),
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  initialValue: value.toInt().toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15,
                      color: isDark ? Colors.white : const Color(0xFF0A0F0D),
                      weight: FontWeight.w800),
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

  Widget _buildDebtItem(
      String icon, String label, double value, ValueChanged<double> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFEDF5F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0A0F0D))),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toInt().toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: isDark
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFC0392B),
                  weight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFC0392B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              onChanged: (val) {
                final d = double.tryParse(val) ?? 0.0;
                onChanged(d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeSummary(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 12, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMaxBorrowBox(String label, double val,
      {bool isSpecial = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: isDark ? Colors.white70 : const Color(0xFF0D9488),
                  weight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            isSpecial && val < 0
                ? 'Over limit'
                : CurrencyFormatter.compact(val, symbol: 'NZ\$'),
            style: AppTextStyles.dmSans(
                size: 14,
                color: isSpecial && val < 0
                    ? const Color(0xFFC0392B)
                    : (isDark
                        ? const Color(0xFF2DD4BF)
                        : const Color(0xFF0F766E)),
                weight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBandRow(String range, String label, String desc,
      String badgeText, Color color, bool isActive, CountryTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF14532D) : const Color(0xFFF0FDF4))
            : Colors.transparent,
        border: Border.all(
            color: isActive
                ? (isDark ? const Color(0xFF15803D) : const Color(0xFF86EFAC))
                : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(
              width: 50,
              child: Text(range,
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeText.contains('Strong') || badgeText.contains('OK')
                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                  : badgeText.contains('Border')
                      ? (isDark
                          ? const Color(0xFF78350F)
                          : const Color(0xFFFFFBEB))
                      : (isDark
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFFFEF2F2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.dmSans(
                size: 8.5,
                weight: FontWeight.w800,
                color: badgeText.contains('Strong') || badgeText.contains('OK')
                    ? (isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF065F46))
                    : badgeText.contains('Border')
                        ? (isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF92400E))
                        : (isDark
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFC0392B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NZDtiGaugePainter extends CustomPainter {
  final double dti;
  _NZDtiGaugePainter({required this.dti});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = min(size.width, size.height - 10) - 10;
    const strokeWidth = 16.0;

    final paintBg = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track arc (180 deg)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi,
      false,
      paintBg,
    );

    // Green zone 0 to 5 DTI (out of 8 max, so 5/8 * 180 deg = 112.5 deg)
    final paintGreen = Paint()
      ..color = const Color(0xFF1A6B4A).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi,
        pi * (5 / 8), false, paintGreen);

    // Yellow zone 5 to 6 DTI (1/8 * 180 deg = 22.5 deg)
    final paintYellow = Paint()
      ..color = const Color(0xFFD4A017).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi + pi * (5 / 8), pi * (1 / 8), false, paintYellow);

    // Red zone 6 to 7 DTI (1/8 * 180 deg = 22.5 deg)
    final paintRed = Paint()
      ..color = const Color(0xFFC0392B).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi + pi * (6 / 8), pi * (1 / 8), false, paintRed);

    // Dark zone 7 to 8+ DTI (1/8 * 180 deg = 22.5 deg)
    final paintDark = Paint()
      ..color = const Color(0xFF0A0F0D).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -pi + pi * (7 / 8), pi * (1 / 8), false, paintDark);

    // Needle rotation (0 to 8 dti maps to -pi to 0 rad)
    final ratio = (dti / 8.0).clamp(0.0, 1.0);
    final angle = -pi + (ratio * pi);

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final needleLength = radius - 10;
    final needleEnd =
        center + Offset(cos(angle) * needleLength, sin(angle) * needleLength);
    canvas.drawLine(center, needleEnd, needlePaint);

    final centerCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, centerCirclePaint);

    // Draw simple labels
    _drawLabel(canvas, '0',
        center + Offset(cos(-pi) * (radius + 14), sin(-pi) * (radius + 14)));
    _drawLabel(
        canvas,
        '5×',
        center +
            Offset(cos(-pi + pi * (5 / 8)) * (radius + 14),
                sin(-pi + pi * (5 / 8)) * (radius + 14)));
    _drawLabel(
        canvas,
        '6×',
        center +
            Offset(cos(-pi + pi * (6 / 8)) * (radius + 14),
                sin(-pi + pi * (6 / 8)) * (radius + 14)));
    _drawLabel(
        canvas,
        '7×',
        center +
            Offset(cos(-pi + pi * (7 / 8)) * (radius + 14),
                sin(-pi + pi * (7 / 8)) * (radius + 14)));
    _drawLabel(canvas, '8+',
        center + Offset(cos(0) * (radius + 14), sin(0) * (radius + 14)));
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Colors.white54, fontSize: 8, fontFamily: 'Arial')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NZDtiGaugePainter oldDelegate) =>
      oldDelegate.dti != dti;
}
