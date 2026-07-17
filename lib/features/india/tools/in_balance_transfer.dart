// lib/features/india/tools/in_balance_transfer.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INBalanceTransfer extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INBalanceTransfer({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INBalanceTransfer> createState() => _INBalanceTransferState();
}

class _INBalanceTransferState extends ConsumerState<INBalanceTransfer> {
  double _balance = 4000000;
  double _cRate = 9.50;
  int _tenure = 15;
  double _nRate = 8.50;
  double _feePercent = 0.50;

  bool _hasCalculated = false;
  double _calcBalance = 4000000;
  double _calcCRate = 9.50;
  int _calcTenure = 15;
  double _calcNRate = 8.50;
  double _calcFeePercent = 0.50;
  final GlobalKey _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _banks = const [
    {'icon': '🏦', 'name': 'SBI Home Loan', 'rate': 8.50, 'fee': 0.35},
    {'icon': '🔶', 'name': 'Bajaj HFL', 'rate': 8.55, 'fee': 0.50},
    {'icon': '🏗️', 'name': 'LIC HFL', 'rate': 8.65, 'fee': 0.25},
    {'icon': '🏛️', 'name': 'HDFC Bank', 'rate': 8.70, 'fee': 0.50},
    {'icon': '💼', 'name': 'ICICI Bank', 'rate': 8.75, 'fee': 0.50},
    {'icon': '⚡', 'name': 'Axis Bank', 'rate': 8.75, 'fee': 0.50},
  ];

  bool _areInputsChanged() {
    return _balance != _calcBalance ||
        _cRate != _calcCRate ||
        _tenure != _calcTenure ||
        _nRate != _calcNRate ||
        _feePercent != _calcFeePercent;
  }

  void _reset() {
    setState(() {
      _balance = 4000000;
      _cRate = 9.50;
      _tenure = 15;
      _nRate = 8.50;
      _feePercent = 0.50;
      _hasCalculated = false;
      _calcBalance = 4000000;
      _calcCRate = 9.50;
      _calcTenure = 15;
      _calcNRate = 8.50;
      _calcFeePercent = 0.50;
    });
  }

  double _calcEMI(double p, double r, int n) {
    final mr = r / 1200;
    return p * mr * pow(1 + mr, n) / (pow(1 + mr, n) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final oldEmi = _calcEMI(_calcBalance, _calcCRate, _calcTenure * 12);
    final newEmi = _calcEMI(_calcBalance, _calcNRate, _calcTenure * 12);
    final oldTotal = oldEmi * _calcTenure * 12;
    final newTotal = newEmi * _calcTenure * 12;
    final grossSaved = oldTotal - newTotal;
    final procFee = _calcBalance * (_calcFeePercent / 100);
    const otherCost = 15500.0;
    final totalCost = procFee + otherCost;
    final netSaved = grossSaved - totalCost;

    final labelCtrl = TextEditingController(text: 'Balance Transfer');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_balance_transfer'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Transfer Plan', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Net Saved ${_fmt(netSaved)} · Old $_calcCRate% · New $_calcNRate%',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Switch to SBI)',
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
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Balance Transfer';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Balance Transfer',
        inputs: {
          'balance': _calcBalance,
          'cRate': _calcCRate,
          'tenure': _calcTenure.toDouble(),
          'nRate': _calcNRate,
          'feePercent': _calcFeePercent,
        },
        results: {
          'netSaved': netSaved,
          'grossSaved': grossSaved,
          'totalCost': totalCost,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Balance transfer saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
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

    final calcBalance = _calcBalance;
    final calcCRate = _calcCRate;
    final calcTenure = _calcTenure;
    final calcNRate = _calcNRate;
    final calcFeePercent = _calcFeePercent;

    final n = calcTenure * 12;
    final oldEmi = _calcEMI(calcBalance, calcCRate, n);
    final newEmi = _calcEMI(calcBalance, calcNRate, n);
    final oldTotal = oldEmi * n;
    final newTotal = newEmi * n;
    final grossSaved = oldTotal - newTotal;
    final procFee = calcBalance * (calcFeePercent / 100);
    const otherCost = 15500.0;
    final totalCost = procFee + otherCost;
    final netSaved = grossSaved - totalCost;
    final emiSave = oldEmi - newEmi;
    final breakeven = emiSave > 0 ? (totalCost / emiSave).ceil() : 999;
    final rateDrop = calcCRate - calcNRate;

    final LinearGradient verdictGradient;
    final String verdictMessage;
    final String verdictBadgeText;
    final Color verdictBadgeBg;
    final Color verdictBadgeTextCol;
    final Color savingColor;

    if (netSaved > 200000 && rateDrop >= 0.50) {
      verdictGradient = const LinearGradient(
        colors: [Color(0xFF046A38), Color(0xFF07543A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      verdictMessage = '✅ Balance transfer is highly recommended';
      verdictBadgeText = '✅ Transfer Recommended';
      verdictBadgeBg = const Color(0xFF86EFAC).withValues(alpha: 0.2);
      verdictBadgeTextCol = const Color(0xFF86EFAC);
      savingColor = const Color(0xFF86EFAC);
    } else if (netSaved > 0) {
      verdictGradient = const LinearGradient(
        colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      verdictMessage = '⚠️ Marginal benefit – evaluate carefully';
      verdictBadgeText = '⚠️ Consider Transfer';
      verdictBadgeBg = const Color(0xFFFFDEA0).withValues(alpha: 0.2);
      verdictBadgeTextCol = const Color(0xFFFFDEA0);
      savingColor = const Color(0xFFFFDEA0);
    } else {
      verdictGradient = const LinearGradient(
        colors: [Color(0xFF9A3412), Color(0xFF7C2D12)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      verdictMessage = '❌ Transfer not beneficial – stay with current bank';
      verdictBadgeText = '❌ Not Recommended';
      verdictBadgeBg = const Color(0xFFFCA5A5).withValues(alpha: 0.2);
      verdictBadgeTextCol = const Color(0xFFFCA5A5);
      savingColor = const Color(0xFFFCA5A5);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('SBI', '8.50%', 'Lowest', isFirst: true),
              _buildRateStripItem('HDFC', '8.70%', 'Private'),
              _buildRateStripItem('Bajaj', '8.55%', 'NBFC'),
              _buildRateStripItem('LIC HFL', '8.65%', 'HFC'),
            ],
          ),
        ),

        // Section label & Reset button
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Loan (Existing Bank)',
                style: AppTextStyles.sectionLabel(theme.getMutedColor(context)),
              ),
              GestureDetector(
                onTap: _reset,
                child: Text(
                  'Reset ↺',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    color: const Color(0xFFE05F00),
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Balance Slider
              _buildSliderRow(
                title: 'Outstanding Balance',
                value: _balance,
                min: 500000,
                max: 10000000,
                divisions: 95,
                displayValue: _fmt(_balance),
                onChanged: (val) => setState(() => _balance = val),
              ),
              const SizedBox(height: 16),

              // Current Rate Slider
              _buildSliderRow(
                title: 'Current Interest Rate',
                value: _cRate,
                min: 8.00,
                max: 14.00,
                divisions: 120,
                displayValue: '${_cRate.toStringAsFixed(2)}%',
                onChanged: (val) => setState(() => _cRate = val),
              ),
              const SizedBox(height: 16),

              // Tenure Slider
              _buildSliderRow(
                title: 'Remaining Tenure',
                value: _tenure.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                displayValue: "$_tenure Year${_tenure > 1 ? 's' : ''}",
                onChanged: (val) => setState(() => _tenure = val.toInt()),
              ),
              const SizedBox(height: 16),

              // Divider Line
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.getBorderColor(context),
                      thickness: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'NEW BANK OFFER',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: theme.getBorderColor(context),
                      thickness: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // New Offered Rate Slider
              _buildSliderRow(
                title: 'New Interest Rate',
                value: _nRate,
                min: 7.00,
                max: 13.00,
                divisions: 120,
                displayValue: '${_nRate.toStringAsFixed(2)}%',
                onChanged: (val) => setState(() => _nRate = val),
              ),
              const SizedBox(height: 16),

              // Processing Fee Slider
              _buildSliderRow(
                title: 'Processing Fee (%)',
                value: _feePercent,
                min: 0.00,
                max: 1.50,
                divisions: 15,
                displayValue: '${_feePercent.toStringAsFixed(2)}%',
                onChanged: (val) => setState(() => _feePercent = val),
              ),
              const SizedBox(height: 20),

              // Analyse button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasCalculated = true;
                    _calcBalance = _balance;
                    _calcCRate = _cRate;
                    _calcTenure = _tenure;
                    _calcNRate = _nRate;
                    _calcFeePercent = _feePercent;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Balance transfer analysis updated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF1A3A8F),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_resultsKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        _resultsKey.currentContext!,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '☸ Analyse Balance Transfer',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_hasCalculated) ...[
          const SizedBox(height: 20),
          // Warning banner if inputs changed
          if (_areInputsChanged())
            Container(
              key: _resultsKey,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs changed. Tap Calculate to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultsKey, height: 0),

          // Redesigned Verdict Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: verdictGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Savings After Transfer Costs',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: Colors.white.withValues(alpha: 0.55),
                    weight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(netSaved > 0 ? netSaved : 0),
                  style: AppTextStyles.dmSans(
                    size: 34,
                    weight: FontWeight.w800,
                    color: savingColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  verdictMessage,
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildVerdictBox("EMI Saving", "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(emiSave > 0 ? emiSave : 0)}/mo"),
                    const SizedBox(width: 8),
                    _buildVerdictBox("Breakeven", breakeven < 120 ? "$breakeven mo" : "N/A"),
                    const SizedBox(width: 8),
                    _buildVerdictBox("Rate Drop", "${rateDrop.toStringAsFixed(2)}%"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: verdictBadgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        verdictBadgeText,
                        style: AppTextStyles.dmSans(
                          size: 9,
                          weight: FontWeight.w700,
                          color: verdictBadgeTextCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Cost Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💼 Transfer Cost Breakdown',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),

                _buildCostItem("Processing Fee (new bank)", "−₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(procFee)}", isNegative: true),
                _buildCostItem("Legal / Technical Charges", "−₹8,500", isNegative: true),
                _buildCostItem("Stamp Duty (if any)", "−₹3,000", isNegative: true),
                _buildCostItem("MOD Charges (approx.)", "−₹4,000", isNegative: true),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1),
                ),

                _buildCostItem(
                  "Total Transfer Cost",
                  "−₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(totalCost)}",
                  isNegative: true,
                  isBold: true,
                ),
                _buildCostItem(
                  "Gross Interest Saved",
                  "+${_fmt(grossSaved)}",
                  isNegative: false,
                  isBold: true,
                  customColor: const Color(0xFF046A38),
                ),
                _buildCostItem(
                  "Net Benefit",
                  netSaved > 0 ? _fmt(netSaved) : "−${_fmt(netSaved.abs())}",
                  isNegative: netSaved <= 0,
                  isBold: true,
                  fontSize: 14,
                  customColor: netSaved > 0 ? const Color(0xFF046A38) : Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Best Transfer Options', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Bank',
                          style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rate',
                          style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'New EMI',
                          style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Savings',
                          style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                ..._banks.map((b) {
                  final bRate = b['rate'] as double;
                  final bFee = b['fee'] as double;
                  final bEmi = _calcEMI(calcBalance, bRate, n);
                  final bTotal = bEmi * n;
                  final feeCost = calcBalance * (bFee / 100);
                  final totalBTransferCost = feeCost + otherCost;
                  final compareSaved = oldTotal - bTotal - totalBTransferCost;

                  final bestRate = _banks.map((e) => e['rate'] as double).reduce((curr, next) => curr < next ? curr : next);
                  final isBest = bRate == bestRate;

                  final rowBgColor = isBest
                      ? const Color(0xFF046A38).withValues(alpha: 0.05)
                      : Colors.transparent;

                  final isLast = b == _banks.last;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    decoration: BoxDecoration(
                      color: rowBgColor,
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: theme.getBorderColor(context),
                                width: 1.0,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        // Bank Column
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                b['icon'] as String,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        b['name'] as String,
                                        style: AppTextStyles.dmSans(
                                          size: 10.5,
                                          weight: FontWeight.w700,
                                          color: theme.getTextColor(context),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isBest) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF046A38),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'BEST',
                                          style: AppTextStyles.dmSans(
                                            size: 7,
                                            weight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rate Column
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${bRate.toStringAsFixed(2)}%",
                            style: AppTextStyles.dmSans(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFFFF6B00),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),

                        // New EMI Column
                        Expanded(
                          flex: 3,
                          child: Text(
                            "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(bEmi)}",
                            style: AppTextStyles.dmSans(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: theme.getTextColor(context),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),

                        // Savings Column
                        Expanded(
                          flex: 3,
                          child: Text(
                            "${compareSaved > 0 ? '+' : ''}${_fmt(compareSaved)}",
                            style: AppTextStyles.dmSans(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: compareSaved > 0 ? const Color(0xFF046A38) : Colors.red,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Save bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save Transfer Analysis',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF07543A),
                        ),
                      ),
                      Text(
                        'Save for bank negotiation reference',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: isDark ? Colors.white70 : const Color(0xFF046A38),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text('Save', style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5E6D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.dmSans(
                size: 10.5,
                color: theme.getMutedColor(context),
                weight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: const Color(0xFFFF6B00),
            inactiveTrackColor: inactiveColor,
            thumbColor: const Color(0xFFFF6B00),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10.0,
              elevation: 4.0,
            ),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(
                  left: BorderSide(color: Colors.white12, width: 1.0),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white60,
                weight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 14,
                color: const Color(0xFFFFDEA0),
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white.withValues(alpha: 0.5),
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem(
    String label,
    String value, {
    required bool isNegative,
    bool isBold = false,
    double fontSize = 11,
    Color? customColor,
  }) {
    final theme = widget.theme;
    final defaultColor = theme.getTextColor(context);
    final valColor = customColor ?? (isNegative ? Colors.red : const Color(0xFF046A38));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: fontSize,
              weight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? defaultColor : theme.getMutedColor(context),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: fontSize,
              weight: FontWeight.w800,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }
}
