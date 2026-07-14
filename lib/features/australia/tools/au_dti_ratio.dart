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
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  void _reset() {
    setState(() {
      _income = 120000;
      _partnerIncome = 0;
      _newLoan = 600000;
      _existingDebt = 20000;
      _rate = 6.09;
      _termYears = 30;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  double _calcMonthly(double loan, double r, int n) {
    if (r == 0) return loan / n;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  void _calculate() {
    final errors = <String, String>{};

    if (_income <= 0) {
      errors['income'] = 'Enter valid gross annual income';
    }
    if (_partnerIncome < 0) {
      errors['partnerIncome'] = 'Partner income cannot be negative';
    }
    if (_newLoan <= 0) {
      errors['newLoan'] = 'Enter valid proposed loan amount';
    }
    if (_existingDebt < 0) {
      errors['existingDebt'] = 'Existing debt cannot be negative';
    }
    if (_rate <= 0 || _rate > 25) {
      errors['rate'] = 'Enter rate (0.1% - 25%)';
    }
    if (_termYears <= 0 || _termYears > 50) {
      errors['termYears'] = 'Enter term (1-50)';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['income'] = _income;
      _calcSnapshot['partnerIncome'] = _partnerIncome;
      _calcSnapshot['newLoan'] = _newLoan;
      _calcSnapshot['existingDebt'] = _existingDebt;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['termYears'] = _termYears;
      _showResults = true;
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

  void _saveCalculation() async {
    final double snapIncome = _calcSnapshot['income'] ?? _income;
    final double snapPartnerIncome = _calcSnapshot['partnerIncome'] ?? _partnerIncome;
    final double snapNewLoan = _calcSnapshot['newLoan'] ?? _newLoan;
    final double snapExistingDebt = _calcSnapshot['existingDebt'] ?? _existingDebt;
    final double snapRate = _calcSnapshot['rate'] ?? _rate;
    final int snapTermYears = _calcSnapshot['termYears'] ?? _termYears;

    final totalIncome = snapIncome + snapPartnerIncome;
    final totalDebt = snapNewLoan + snapExistingDebt;
    final dti = totalIncome > 0 ? totalDebt / totalIncome : 0.0;
    final r = snapRate / 100 / 12;
    final br = (snapRate + 3.0) / 100 / 12;
    final n = snapTermYears * 12;
    final monthly = _calcMonthly(snapNewLoan, r, n);
    final bufferRepay = _calcMonthly(snapNewLoan, br, n);

    double maxBorrow = 0.0;
    if (totalIncome > 0) {
      final cap30 = totalIncome * 0.30 / 12; // 30% of gross income monthly limit
      final annuityFactor = br > 0 ? (1 - pow(1 + br, -n)) / br : n.toDouble();
      maxBorrow = min(totalIncome * 6.0, cap30 * annuityFactor);
    }

    final labelCtrl = TextEditingController(text: 'DTI Check');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_dti_ratio'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save DTI Check', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: DTI ${dti.toStringAsFixed(2)}x · Income \$${CurrencyFormatter.compact(totalIncome, symbol: 'AU\$')}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Pre-approval check)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002868),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'DTI Check';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'DTI Ratio',
        inputs: {
          'income': snapIncome,
          'partnerIncome': snapPartnerIncome,
          'newLoan': snapNewLoan,
          'existingDebt': snapExistingDebt,
          'rate': snapRate,
          'termYears': snapTermYears.toDouble(),
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
            content: Text('✅ Calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final double snapIncome = _showResults ? (_calcSnapshot['income'] ?? _income) : _income;
    final double snapPartnerIncome = _showResults ? (_calcSnapshot['partnerIncome'] ?? _partnerIncome) : _partnerIncome;
    final double snapNewLoan = _showResults ? (_calcSnapshot['newLoan'] ?? _newLoan) : _newLoan;
    final double snapExistingDebt = _showResults ? (_calcSnapshot['existingDebt'] ?? _existingDebt) : _existingDebt;
    final double snapRate = _showResults ? (_calcSnapshot['rate'] ?? _rate) : _rate;
    final int snapTermYears = _showResults ? (_calcSnapshot['termYears'] ?? _termYears) : _termYears;

    // Calculations
    final totalIncome = snapIncome + snapPartnerIncome;
    final totalDebt = snapNewLoan + snapExistingDebt;
    final dti = totalIncome > 0 ? totalDebt / totalIncome : 0.0;
    final r = snapRate / 100 / 12;
    final br = (snapRate + 3.0) / 100 / 12;
    final n = snapTermYears * 12;
    final monthly = _calcMonthly(snapNewLoan, r, n);
    final bufferRepay = _calcMonthly(snapNewLoan, br, n);

    double maxBorrow = 0.0;
    if (totalIncome > 0) {
      final cap30 = totalIncome * 0.30 / 12; // 30% of gross income monthly limit
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
      statusBg = isDark ? const Color(0xFF14532D).withValues(alpha: 0.4) : const Color(0xFFF0FDF4);
    } else if (dti <= 6) {
      statusText = '⚠️ Acceptable – Monitor closely';
      statusColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
      statusBg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFFFBEB);
    } else if (dti <= 7) {
      statusText = '🔶 High – Lender discretion';
      statusColor = isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412);
      statusBg = isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.4) : const Color(0xFFFFF7ED);
    } else {
      statusText = '🔴 Very High – Likely declined';
      statusColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
      statusBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEF2F2);
    }

    final isDirty = _showResults && (
      _income != (_calcSnapshot['income'] ?? 0.0) ||
      _partnerIncome != (_calcSnapshot['partnerIncome'] ?? 0.0) ||
      _newLoan != (_calcSnapshot['newLoan'] ?? 0.0) ||
      _existingDebt != (_calcSnapshot['existingDebt'] ?? 0.0) ||
      _rate != (_calcSnapshot['rate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['termYears'] ?? 0)
    );

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
                      errorText: _errors['income'],
                      onChanged: (val) => setState(() => _income = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Partner Income (opt.)',
                      prefix: 'AUD \$',
                      value: _partnerIncome,
                      errorText: _errors['partnerIncome'],
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
                      errorText: _errors['newLoan'],
                      onChanged: (val) => setState(() => _newLoan = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Existing Debt Total',
                      prefix: 'AUD \$',
                      value: _existingDebt,
                      errorText: _errors['existingDebt'],
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
                      errorText: _errors['rate'],
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
                      errorText: _errors['termYears'],
                      onChanged: (val) => setState(() => _termYears = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002868),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          if (isDirty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Check DTI Ratio to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DTI Result', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                          border: Border.all(color: theme.getBorderColor(context)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('💾 Save',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                color: isDark ? const Color(0xFFFFD700) : theme.primaryColor,
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
                              color: isDark ? Colors.white70 : const Color(0xFF92400E),
                              weight: FontWeight.w700,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 8),
                      Text('${dti.toStringAsFixed(2)}x',
                          style: AppTextStyles.playfair(size: 52, weight: FontWeight.w800, color: statusColor)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(statusText, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: statusColor)),
                      ),
                      const SizedBox(height: 16),

                      // Colored progress bar track for DTI levels
                      Column(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 50,
                                    child: Container(color: const Color(0xFF22C55E))), // green
                                Expanded(
                                    flex: 10,
                                    child: Container(color: const Color(0xFFEAB308))), // yellow
                                Expanded(
                                    flex: 10,
                                    child: Container(color: const Color(0xFFF97316))), // orange
                                Expanded(
                                    flex: 30,
                                    child: Container(color: const Color(0xFFEF4444))), // red
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStepMarker('0x'),
                              const Spacer(flex: 50),
                              _buildStepMarker('5x'),
                              const Spacer(flex: 10),
                              _buildStepMarker('6x'),
                              const Spacer(flex: 10),
                              _buildStepMarker('7x'),
                              const Spacer(flex: 30),
                              _buildStepMarker('10x+'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats Comparison & Buffers
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? theme.getCardColor(context) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Borrowing capacity analysis',
                          style: AppTextStyles.playfair(
                              size: 15,
                              color: theme.getTextColor(context),
                              weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1.3,
                        children: [
                          _buildSummaryBox(context, 'Combined Income', CurrencyFormatter.format(totalIncome, currencyCode: 'AUD')),
                          _buildSummaryBox(context, 'Total Debt Pool', CurrencyFormatter.format(totalDebt, currencyCode: 'AUD')),
                          _buildSummaryBox(context, 'Est. Max Borrow', CurrencyFormatter.format(maxBorrow, currencyCode: 'AUD')),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text('DEBT COMPOSITION',
                          style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: theme.getMutedColor(context),
                              weight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _buildDebtBar(context, 'Proposed Loan', snapNewLoan, totalDebt, const Color(0xFF002868)),
                      _buildDebtBar(context, 'Existing Debts', snapExistingDebt, totalDebt, const Color(0xFF7C2D12)),
                      const SizedBox(height: 18),

                      Text('ESTIMATED REPAYMENTS',
                          style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: theme.getMutedColor(context),
                              weight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _buildRepayRow(context, 'Monthly Payment (Actual)', monthly),
                      _buildRepayRow(context, 'Buffer Repayment (+3% buffer)', bufferRepay, isBuffer: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Help Card
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.15) : const Color(0xFFFFF7ED),
            border: Border.all(color: isDark ? const Color(0xFFEA580C) : const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why DTI Limits Matter in Australia',
                  style: AppTextStyles.playfair(
                      size: 13,
                      color: isDark ? const Color(0xFFFFD700) : const Color(0xFF7C2D12),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              _buildTipRow(context, '1', 'APRA Limits: The Australian Prudential Regulation Authority (APRA) categorises DTI ratios of 6x or higher as high risk. Lenders must report and limit loans above this limit.'),
              _buildTipRow(context, '2', 'Interest Rate Buffer: Lenders assess your capacity to pay at a rate 3.0% above current interest rate. This ensures you can afford repayments if rates rise.'),
              _buildTipRow(context, '3', 'How to Lower DTI: Reduce existing debt limits (like unused credit cards), increase your deposit to reduce loan size, or extend loan term to improve monthly buffers.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepMarker(String label) {
    return Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.grey, weight: FontWeight.w700));
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    bool isInteger = false,
    String? errorText,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (prefix.isNotEmpty)
                    Text('$prefix ', style: AppTextStyles.dmSans(size: 11, color: Colors.white54, weight: FontWeight.w700)),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(value),
                      initialValue: isInteger ? value.toInt().toString() : value.toString(),
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.playfair(size: 15, color: Colors.white, weight: FontWeight.w800),
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
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _buildSummaryBox(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
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

  Widget _buildDebtBar(BuildContext context, String label, double amount, double total, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF92400E)))),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 60,
              child: Text(CurrencyFormatter.format(amount, currencyCode: 'AUD'),
                  style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildRepayRow(BuildContext context, String label, double amount, {bool isBuffer = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : Colors.black87, weight: isBuffer ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${CurrencyFormatter.format(amount, currencyCode: 'AUD')}/mo',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.bold,
              color: isBuffer ? (isDark ? const Color(0xFFFFD700) : const Color(0xFF7C2D12)) : (isDark ? Colors.white : Colors.black),
            ),
          ),
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
            decoration: BoxDecoration(color: isDark ? const Color(0xFFC2410C) : const Color(0xFFEA580C), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(bullet, style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.dmSans(size: 10.5, color: isDark ? const Color(0xFFFFE3D3) : const Color(0xFF92400E), height: 1.4)),
          ),
        ],
      ),
    );
  }
}
