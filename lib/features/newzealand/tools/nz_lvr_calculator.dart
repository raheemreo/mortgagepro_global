// lib/features/newzealand/tools/nz_lvr_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZLvrCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZLvrCalculator({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZLvrCalculator> createState() => _NZLvrCalculatorState();
}

class _NZLvrCalculatorState extends ConsumerState<NZLvrCalculator> {
  String _borrowerType = 'owner'; // 'owner' or 'investor'
  double _propValue = 750000;
  double _deposit = 150000;
  double _loanAmount = 600000;
  String _region = 'auckland';

  bool _showResults = false;

  void _reset() {
    setState(() {
      _borrowerType = 'owner';
      _propValue = 750000;
      _deposit = 150000;
      _loanAmount = 600000;
      _region = 'auckland';
      _showResults = false;
    });
  }

  void _saveCalculation(double lvr, double depPct, double limit,
      double shortfall, double maxLoan) async {
    final labelCtrl = TextEditingController(text: 'NZ LVR Calculation');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.getCardColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('💾 Save LVR Scenario',
              style: AppTextStyles.playfair(
                  size: 16, color: widget.theme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saving: LVR of ${lvr.toStringAsFixed(1)}% on ${CurrencyFormatter.compact(_propValue, symbol: 'NZ\$')} property.',
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
                  hintText: 'Label (e.g. Auckland House)',
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
                backgroundColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save',
                  style: AppTextStyles.dmSans(
                      size: 12, color: Colors.white, weight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text;
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'LVR Calculator',
        inputs: {
          'propertyValue': _propValue,
          'deposit': _deposit,
          'loanAmount': _loanAmount,
          'borrowerType': _borrowerType == 'owner' ? 0.0 : 1.0,
        },
        results: {
          'lvr': lvr,
          'depositPct': depPct,
          'limit': limit,
          'shortfall': shortfall,
          'maxLoan': maxLoan,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
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

    // Rate strip values
    const ruleOwnerMaxLvr = 80.0;
    const ruleInvestorMaxLvr = 65.0;
    const ruleFlowAllowance = 10.0;
    const rateOCR = 5.50;

    // Calculations
    final lvr = _propValue > 0 ? (_loanAmount / _propValue) * 100 : 0.0;
    final depPct = _propValue > 0 ? (_deposit / _propValue) * 100 : 0.0;
    final limit =
        _borrowerType == 'owner' ? ruleOwnerMaxLvr : ruleInvestorMaxLvr;
    final maxLoan = _propValue * limit / 100;
    final shortfall = max(0.0, _loanAmount - maxLoan);
    final gap = lvr - limit;

    // Determine status
    String statusType; // 'pass', 'warn', 'fail'
    String statusTitle;
    String statusSub;
    String statusIcon;
    Color statusColor;

    if (lvr <= limit) {
      statusType = 'pass';
      statusIcon = '✅';
      statusTitle = 'Compliant with RBNZ Rules';
      statusSub =
          'Your ${depPct.toStringAsFixed(1)}% deposit meets the ${_borrowerType == 'owner' ? 'owner-occupier' : 'investor'} ${100 - limit.toInt()}% minimum.';
      statusColor = const Color(0xFF1A6B4A);
    } else if (lvr <= limit + 10) {
      statusType = 'warn';
      statusIcon = '⚠️';
      statusTitle = 'Borderline (bank discretion)';
      statusSub =
          'Exceeds standard RBNZ limit. Requires bank High-LVR flow allocation (10% limit).';
      statusColor = const Color(0xFFD97706);
    } else {
      statusType = 'fail';
      statusIcon = '❌';
      statusTitle = 'Exceeds RBNZ Limit';
      statusSub =
          'You need ${CurrencyFormatter.format(shortfall, currencyCode: 'NZD')} more deposit to meet the ${100 - limit.toInt()}% requirement.';
      statusColor = const Color(0xFFC0392B);
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Rate Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _buildRateStripCell('Owner-Occ',
                        '≤${ruleOwnerMaxLvr.toInt()}%', 'Max LVR')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('Investor',
                        '≤${ruleInvestorMaxLvr.toInt()}%', 'Max LVR')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('Excep.',
                        '${ruleFlowAllowance.toInt()}%', 'Flow allowance')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('OCR', '$rateOCR%', 'RBNZ',
                        isGold: true)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // RBNZ Warning Banner
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF78350F).withValues(alpha: 0.3),
                        const Color(0xFF78350F).withValues(alpha: 0.15)
                      ]
                    : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
              ),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFFB45309)
                      : const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RBNZ Loan-to-Value Restrictions',
                          style: AppTextStyles.dmSans(
                              size: 12.5,
                              color: isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF92400E),
                              weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Owner-occupiers: 20% min deposit (80% max LVR) · Investors: 35% min deposit (65% max LVR) · As at Jan 2024',
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Borrower Type Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _borrowerType = 'owner'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: _borrowerType == 'owner'
                          ? (isDark
                              ? const Color(0xFF14532D)
                              : const Color(0xFFECFDF5))
                          : theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _borrowerType == 'owner'
                              ? (isDark
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF1A6B4A))
                              : theme.getBorderColor(context),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏠', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text('Owner-Occupier',
                            style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 4),
                        Text('≤ 80% LVR',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF1A6B4A))),
                        const SizedBox(height: 2),
                        Text('20% min deposit required',
                            style: AppTextStyles.dmSans(
                                size: 9, color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _borrowerType = 'investor'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: _borrowerType == 'investor'
                          ? (isDark
                              ? const Color(0xFF7F1D1D)
                              : const Color(0xFFFEF2F2))
                          : theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _borrowerType == 'investor'
                              ? (isDark
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFC0392B))
                              : theme.getBorderColor(context),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏘️', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text('Investor',
                            style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 4),
                        Text('≤ 65% LVR',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFC0392B))),
                        const SizedBox(height: 2),
                        Text('35% min deposit required',
                            style: AppTextStyles.dmSans(
                                size: 9, color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Property Details Input Card
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
                    Text('🏠 Property Details',
                        style: AppTextStyles.playfair(
                            size: 15,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800)),
                    GestureDetector(
                      onTap: _reset,
                      child: Text('Reset ↺',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: const Color(0xFFD97706),
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Property Value (NZD)',
                        value: _propValue,
                        onChanged: (val) {
                          setState(() {
                            _propValue = val;
                            _loanAmount = max(0.0, _propValue - _deposit);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildNumericField(
                        label: 'Your Deposit (NZD)',
                        value: _deposit,
                        onChanged: (val) {
                          setState(() {
                            _deposit = val;
                            _loanAmount = max(0.0, _propValue - _deposit);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Loan Amount (NZD)',
                        value: _loanAmount,
                        onChanged: (val) {
                          setState(() {
                            _loanAmount = val;
                            _deposit = max(0.0, _propValue - _loanAmount);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REGION',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: theme.getMutedColor(context),
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: theme.getBgColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.getBorderColor(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _region,
                                dropdownColor: theme.getCardColor(context),
                                isExpanded: true,
                                style: AppTextStyles.dmSans(
                                    size: 12,
                                    color: theme.getTextColor(context),
                                    weight: FontWeight.w700),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'auckland',
                                      child: Text('Auckland (NZ\$950K med.)')),
                                  DropdownMenuItem(
                                      value: 'wellington',
                                      child:
                                          Text('Wellington (NZ\$780K med.)')),
                                  DropdownMenuItem(
                                      value: 'christchurch',
                                      child:
                                          Text('Christchurch (NZ\$610K med.)')),
                                  DropdownMenuItem(
                                      value: 'hamilton',
                                      child: Text('Hamilton (NZ\$650K med.)')),
                                  DropdownMenuItem(
                                      value: 'tauranga',
                                      child: Text('Tauranga (NZ\$810K med.)')),
                                  DropdownMenuItem(
                                      value: 'other',
                                      child: Text('Other Region')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _region = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_propValue <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Property value must be greater than 0',
                                style: AppTextStyles.dmSans())),
                      );
                      return;
                    }
                    setState(() => _showResults = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text('🛡️ Calculate LVR Status',
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          if (_showResults) ...[
            const SizedBox(height: 16),

            // LVR Gauge Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.getBorderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LVR Gauge',
                          style: AppTextStyles.playfair(
                              size: 13,
                              color: theme.getTextColor(context),
                              weight: FontWeight.w800)),
                      Text(
                        '${lvr.toStringAsFixed(1)}% LVR · ${lvr <= limit ? "Compliant ✅" : "Non-Compliant ❌"}',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 110,
                      child: CustomPaint(
                        painter: _NZLvrGaugePainter(
                          lvr: lvr,
                          limit: limit,
                          statusColor: statusColor,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusType == 'pass'
                    ? (isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                        : const Color(0xFFECFDF5))
                    : statusType == 'warn'
                        ? (isDark
                            ? const Color(0xFF78350F).withValues(alpha: 0.4)
                            : const Color(0xFFFEF3C7))
                        : (isDark
                            ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
                            : const Color(0xFFFEF2F2)),
                border: Border.all(
                  color: statusType == 'pass'
                      ? (isDark
                          ? const Color(0xFF065F46)
                          : const Color(0xFF6EE7B7))
                      : statusType == 'warn'
                          ? (isDark
                              ? const Color(0xFFB45309)
                              : const Color(0xFFFCD34D))
                          : (isDark
                              ? const Color(0xFF991B1B)
                              : const Color(0xFFFCA5A5)),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(statusIcon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: statusType == 'pass'
                                ? (isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF065F46))
                                : statusType == 'warn'
                                    ? (isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFF92400E))
                                    : (isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFC0392B)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusSub,
                          style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: statusType == 'pass'
                                ? (isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF047857))
                                : statusType == 'warn'
                                    ? (isDark
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFB45309))
                                    : (isDark
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFC0392B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats Grid (6 boxes)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatBox(
                    'Your LVR',
                    '${lvr.toStringAsFixed(1)}%',
                    'Loan ÷ Property value',
                    lvr <= limit
                        ? const Color(0xFF1A6B4A)
                        : const Color(0xFFC0392B)),
                _buildStatBox('Deposit %', '${depPct.toStringAsFixed(1)}%',
                    'Of property value', const Color(0xFF1A6B4A)),
                _buildStatBox(
                    'Additional Needed',
                    shortfall > 0
                        ? CurrencyFormatter.compact(shortfall, symbol: 'NZ\$')
                        : 'None needed',
                    'To meet LVR limit',
                    shortfall > 0
                        ? const Color(0xFFC0392B)
                        : const Color(0xFF1A6B4A)),
                _buildStatBox(
                    'Max Loan',
                    CurrencyFormatter.compact(maxLoan, symbol: 'NZ\$'),
                    'At this property value',
                    const Color(0xFF0D9488)),
                _buildStatBox('LVR Limit', '${limit.toInt()}%', 'RBNZ maximum',
                    const Color(0xFFD97706)),
                _buildStatBox(
                    'LVR Gap',
                    '${(gap > 0 ? "+" : "")}${gap.toStringAsFixed(1)}%',
                    'vs RBNZ limit',
                    gap > 0
                        ? const Color(0xFFC0392B)
                        : const Color(0xFF1A6B4A)),
              ],
            ),
            const SizedBox(height: 12),

            // LVR Band Visualiser Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📐 LVR Band Visualiser',
                      style: AppTextStyles.playfair(
                          size: 13,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w800)),
                  const SizedBox(height: 14),

                  // Horizontal track builder
                  SizedBox(
                    height: 36,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 65,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color(0xFF1A6B4A),
                                      Color(0xFF0D9488)
                                    ]),
                                  ),
                                  child: const Text('0–65%',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color(0xFFD97706),
                                      Color(0xFFB45309)
                                    ]),
                                  ),
                                  child: const Text('65–80%',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                flex: 20,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color(0xFFC0392B),
                                      Color(0xFF922B21)
                                    ]),
                                  ),
                                  child: const Text('80–100%',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Current position tick
                        Positioned(
                          left: (lvr.clamp(0.0, 100.0) / 100) *
                              180, // rough adjustment to handle padding/width
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0% LVR',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context))),
                      Text('Investor limit ↑',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context))),
                      Text('Owner limit',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context))),
                      Text('100%',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your position',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 4),
                        Text(
                          lvr <= 65
                              ? '✅ Safe zone (under 65%) — eligible for both owner-occupier and investor lending.'
                              : lvr <= 80
                                  ? '⚠️ Amber zone (65–80%) — eligible for owner-occupier only; investor LVR exceeded by ${(lvr - 65).toStringAsFixed(1)}%.'
                                  : '❌ Red zone (above 80%) — exceeds both owner-occupier and investor LVR limits.',
                          style: AppTextStyles.dmSans(
                              size: 10, color: theme.getMutedColor(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Save Calculation Banner
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💾 Save This Scenario',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 2),
                        Text('Store to your LVR limits comparison',
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveCalculation(
                        lvr, depPct, limit, shortfall, maxLoan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text('Save ›',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: Colors.white,
                            weight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // RBNZ Exceptions
          Text('RBNZ LVR Exceptions',
              style: AppTextStyles.playfair(
                  size: 14,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 10),
          _buildExceptionItem(
              'New Build Exemption',
              'New builds are fully exempt from LVR restrictions — no deposit floor applies for owner-occupiers or investors.',
              'Exempt',
              isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46)),
          const SizedBox(height: 8),
          _buildExceptionItem(
              '10% High-LVR Flow',
              'Banks may lend up to 10% of new owner-occupier loans at >80% LVR per quarter (RBNZ allowance).',
              'Limited',
              isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
              isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
          const SizedBox(height: 8),
          _buildExceptionItem(
              'Kāinga Ora Lending',
              'Government housing loans via Kāinga Ora are exempt from standard LVR restrictions.',
              'Exempt',
              isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46)),
          const SizedBox(height: 8),
          _buildExceptionItem(
              'Bridging Finance',
              'Short-term bridging loans (under 12 months) are excluded from LVR calculations.',
              'Short-term',
              isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
              isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)),
        ],
      ),
    );
  }

  Widget _buildRateStripCell(String label, String value, String subtitle,
      {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white54,
                weight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFF5D060) : Colors.white)),
        const SizedBox(height: 1),
        Text(subtitle,
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 25,
      width: 1,
      color: Colors.white12,
    );
  }

  Widget _buildNumericField({
    required String label,
    required double value,
    bool isPercent = false,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (!isPercent)
                Text('\$ ',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: value.toStringAsFixed(0),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.playfair(
                      size: 14,
                      color: theme.getTextColor(context),
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
              if (isPercent)
                Text('%',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, String sub, Color color) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 16, color: color, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.dmSans(
                  size: 8, color: theme.getMutedColor(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildExceptionItem(String title, String desc, String badgeText,
      Color badgeBg, Color badgeFg) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: theme.getBgColor(context),
                borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: const Text('🛡️', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badgeText,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: badgeFg, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _NZLvrGaugePainter extends CustomPainter {
  final double lvr;
  final double limit;
  final Color statusColor;
  final bool isDark;

  _NZLvrGaugePainter({
    required this.lvr,
    required this.limit,
    required this.statusColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    const radius = 80.0;
    const strokeWidth = 16.0;

    final paintBg = Paint()
      ..color =
          isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintGreen = Paint()
      ..color = const Color(0xFF1A6B4A).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintAmber = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final paintRed = Paint()
      ..color = const Color(0xFFC0392B).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background half circle (from pi to 2*pi)
    canvas.drawArc(rect, pi, pi, false, paintBg);

    // Draw Safe Zone (0 to 65% LVR)
    canvas.drawArc(rect, pi, pi * 0.65, false, paintGreen);

    // Draw Amber Zone (65% to 80% LVR)
    canvas.drawArc(rect, pi + pi * 0.65, pi * 0.15, false, paintAmber);

    // Draw Red Zone (80% to 100% LVR)
    canvas.drawArc(rect, pi + pi * 0.80, pi * 0.20, false, paintRed);

    // Draw active needle track
    final fraction = (lvr / 100.0).clamp(0.0, 1.0);
    final paintNeedle = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi * fraction, false, paintNeedle);

    // Draw static texts
    _drawText(canvas, center - const Offset(60, -10), 'Safe',
        const Color(0xFF1A6B4A), 8);
    _drawText(canvas, center - const Offset(0, 85), '65%',
        const Color(0xFFD97706), 8);
    _drawText(canvas, center - const Offset(-45, 45), '80%',
        const Color(0xFFD97706), 8);
    _drawText(canvas, center - const Offset(-55, -10), 'High',
        const Color(0xFFC0392B), 8);

    // Draw central LVR value
    _drawText(
        canvas,
        center - const Offset(0, 32),
        '${lvr.toStringAsFixed(1)}%',
        isDark ? Colors.white : const Color(0xFF0A0F0D),
        24,
        isBold: true);
    _drawText(canvas, center - const Offset(0, 10), 'Loan-to-Value Ratio',
        isDark ? Colors.white70 : const Color(0xFF4A6358), 9);
  }

  void _drawText(
      Canvas canvas, Offset position, String text, Color color, double fontSize,
      {bool isBold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Helvetica Neue',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position - Offset(textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _NZLvrGaugePainter oldDelegate) =>
      oldDelegate.lvr != lvr ||
      oldDelegate.limit != limit ||
      oldDelegate.statusColor != statusColor ||
      oldDelegate.isDark != isDark;
}
