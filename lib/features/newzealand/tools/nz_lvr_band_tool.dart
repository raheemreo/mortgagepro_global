// lib/features/newzealand/tools/nz_lvr_band_tool.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZLvrBandTool extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZLvrBandTool({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZLvrBandTool> createState() => _NZLvrBandToolState();
}

class _NZLvrBandToolState extends ConsumerState<NZLvrBandTool> {
  double _propVal = 850000;
  double _deposit = 170000;
  String _buyerType = 'owner'; // 'owner', 'investor', 'newbuild'

  bool _showResults = false;

  void _reset() {
    setState(() {
      _propVal = 850000;
      _deposit = 170000;
      _buyerType = 'owner';
      _showResults = false;
    });
  }

  void _saveCalculation(
      double loan, double lvr, double depPct, double gap, String status) async {
    final labelCtrl = TextEditingController(text: 'NZ LVR Band Analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.getCardColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('💾 Save LVR Band',
              style: AppTextStyles.playfair(
                  size: 16, color: widget.theme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saving: LVR of ${lvr.toStringAsFixed(1)}% ($status) for a ${CurrencyFormatter.compact(_propVal, symbol: 'NZ\$')} property.',
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
                  hintText: 'Label (e.g. Wellington Property)',
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
        calcType: 'LVR Band Tool',
        inputs: {
          'propertyValue': _propVal,
          'deposit': _deposit,
          'buyerType': _buyerType == 'owner'
              ? 0.0
              : _buyerType == 'investor'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'loan': loan,
          'lvr': lvr,
          'depositPct': depPct,
          'gap': gap,
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

    // Calculations
    final loan = _propVal - _deposit;
    final lvr = _propVal > 0 ? (loan / _propVal) * 100 : 0.0;
    final depPct = _propVal > 0 ? (_deposit / _propVal) * 100 : 0.0;

    double limit = _buyerType == 'investor'
        ? 65.0
        : _buyerType == 'newbuild'
            ? 90.0
            : 80.0;
    double gap = limit - lvr;

    // Determine status
    String status = '';
    Color statusColor;
    Color pillBg;
    Color pillFg;
    String subText = '';

    if (_buyerType == 'investor') {
      if (lvr <= 65) {
        status = 'WITHIN LIMIT';
        statusColor = const Color(0xFF1A6B4A);
        pillBg = const Color(0xFFECFDF5);
        pillFg = const Color(0xFF065F46);
        subText = '✅ Your LVR is within RBNZ investor limit of 65%';
      } else {
        status = 'EXCEEDS LIMIT';
        statusColor = const Color(0xFFC0392B);
        pillBg = const Color(0xFFFEF2F2);
        pillFg = const Color(0xFFC0392B);
        subText = '🚫 Exceeds RBNZ investor LVR limit of 65%';
      }
    } else if (_buyerType == 'newbuild') {
      if (lvr <= 90) {
        status = 'WITHIN LIMIT';
        statusColor = const Color(0xFF1A6B4A);
        pillBg = const Color(0xFFECFDF5);
        pillFg = const Color(0xFF065F46);
        subText = '✅ Within new build exemption limit of 90% LVR';
      } else {
        status = 'EXCEEDS LIMIT';
        statusColor = const Color(0xFFC0392B);
        pillBg = const Color(0xFFFEF2F2);
        pillFg = const Color(0xFFC0392B);
        subText = '🚫 Exceeds 90% LVR even for new build';
      }
    } else {
      if (lvr <= 80) {
        status = 'STANDARD BAND';
        statusColor = const Color(0xFF1A6B4A);
        pillBg = const Color(0xFFECFDF5);
        pillFg = const Color(0xFF065F46);
        subText = '✅ Within standard owner-occupier LVR of 80%';
      } else if (lvr <= 90) {
        status = 'LOW-EQUITY BAND';
        statusColor = const Color(0xFFD97706);
        pillBg = const Color(0xFFFFF7ED);
        pillFg = const Color(0xFFC2410C);
        subText = '⚠️ Low Equity Margin (LEM) fee likely applies';
      } else {
        status = 'EXCEEDS LIMIT';
        statusColor = const Color(0xFFC0392B);
        pillBg = const Color(0xFFFEF2F2);
        pillFg = const Color(0xFFC0392B);
        subText = '🚫 Exceeds RBNZ owner-occupier high-LVR speed limit';
      }
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
                    child: _buildRateStripCell('Owner-Occ', '80%', 'Max LVR')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('Investor', '65%', 'Max LVR')),
                _buildDivider(),
                Expanded(
                    child:
                        _buildRateStripCell('Min Deposit', '20%', 'Owner-Occ')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('Min Deposit', '35%', 'Investor',
                        isGold: true)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Input Card (Hero Gradient Styling)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
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
                    Text('NZ Loan-to-Value Band · Te Tatau LVR',
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: Colors.white54,
                            weight: FontWeight.w600)),
                    GestureDetector(
                      onTap: _reset,
                      child: Text('Reset ↺',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: const Color(0xFFF5D060),
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Find your LVR Band',
                    style: AppTextStyles.playfair(
                        size: 17,
                        color: Colors.white,
                        weight: FontWeight.w800)),
                const SizedBox(height: 14),

                // Property Value and Deposit Input
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Property Value',
                        value: _propVal,
                        onChanged: (val) => setState(() => _propVal = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Deposit / Equity',
                        value: _deposit,
                        onChanged: (val) => setState(() => _deposit = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Buyer Type and Loan Amount
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BUYER TYPE',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: Colors.white54,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _buyerType,
                                dropdownColor: const Color(0xFF0D3B2E),
                                isExpanded: true,
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    color: Colors.white,
                                    weight: FontWeight.w700),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'owner',
                                      child: Text('Owner-Occupier')),
                                  DropdownMenuItem(
                                      value: 'investor',
                                      child: Text('Investor')),
                                  DropdownMenuItem(
                                      value: 'newbuild',
                                      child: Text('New Build')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _buyerType = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOAN AMOUNT (AUTO)',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: Colors.white54,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              CurrencyFormatter.compact(loan, symbol: 'NZ\$'),
                              style: AppTextStyles.playfair(
                                  size: 14,
                                  color: Colors.white70,
                                  weight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed: () {
                    if (_propVal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please enter valid property value',
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
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text('📐 Calculate LVR Band',
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

            // LVR Result Band Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(18),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_buyerType == 'investor' ? 'Investor' : 'Owner-Occ'} LVR Analysis',
                        style: AppTextStyles.playfair(
                            size: 14,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          status,
                          style: AppTextStyles.dmSans(
                              size: 11, weight: FontWeight.w800, color: pillFg),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal gauge bar
                  Text('Loan-to-Value Ratio',
                      style: AppTextStyles.dmSans(
                          size: 11, color: theme.getMutedColor(context)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    '${lvr.toStringAsFixed(1)}%',
                    style: AppTextStyles.playfair(
                        size: 32,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Stacked track
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              width: constraints.maxWidth *
                                  (lvr.clamp(0.0, 100.0) / 100),
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: statusColor == const Color(0xFF1A6B4A)
                                      ? [
                                          const Color(0xFF059669),
                                          const Color(0xFF34D399)
                                        ]
                                      : statusColor == const Color(0xFFD97706)
                                          ? [
                                              const Color(0xFFD97706),
                                              const Color(0xFFFBBF24)
                                            ]
                                          : [
                                              const Color(0xFFC0392B),
                                              const Color(0xFFF87171)
                                            ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0%',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
                      Text('65% (Investor)',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
                      Text('80% (Owner)',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
                      Text('100%',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subText,
                      style: AppTextStyles.dmSans(
                          size: 10, color: theme.getMutedColor(context)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),

                  // Stats row (3 metric columns)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox('Loan Amount',
                            CurrencyFormatter.compact(loan, symbol: 'NZ\$')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatBox(
                            'Deposit %', '${depPct.toStringAsFixed(1)}%',
                            isGreen: depPct >= 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatBox('Gap to Limit',
                            '${gap >= 0 ? "+" : ""}${gap.toStringAsFixed(1)}%',
                            isGreen: gap >= 0, isRed: gap < 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Band explanations highlight list
                  _buildBandRow(
                    title: '✅ Standard Band',
                    desc: 'Owner-Occ ≤80% LVR · Full lender access',
                    tag: '≤80%',
                    isActive: lvr <= 80,
                    colorType: 'green',
                  ),
                  const SizedBox(height: 7),
                  _buildBandRow(
                    title: '⚠️ Low-Equity Band',
                    desc: '80–90% LVR · Low Equity Margin applies',
                    tag: '80–90%',
                    isActive: lvr > 80 && lvr <= 90,
                    colorType: 'amber',
                  ),
                  const SizedBox(height: 7),
                  _buildBandRow(
                    title: '🚫 Above Limit',
                    desc: 'Owner-Occ >90% · Investor >65% — RBNZ restricted',
                    tag: '>90%',
                    isActive: lvr > 90,
                    colorType: 'red',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Save Calculation Button
            ElevatedButton.icon(
              onPressed: () => _saveCalculation(loan, lvr, depPct, gap, status),
              icon: const Text('💾', style: TextStyle(fontSize: 14)),
              label: Text('Save This Calculation',
                  style: AppTextStyles.dmSans(
                      size: 13, weight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // RBNZ Rules card
          Text('RBNZ LVR Rules 2025',
              style: AppTextStyles.playfair(
                  size: 14,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              ),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ Current RBNZ LVR Restrictions',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: const Color(0xFF92400E))),
                const SizedBox(height: 10),
                _buildRuleRow(
                    'Owner-Occupier Max LVR', '80%', '20% min deposit'),
                _buildRuleRow('Investor Max LVR', '65%', '35% min deposit'),
                _buildRuleRow('New Build Exemption', '90%', 'Special rules'),
                _buildRuleDetailRow(
                    'High-LVR Speed Limit (Owner)', '15% of lending'),
                _buildRuleDetailRow(
                    'High-LVR Speed Limit (Investor)', '5% of lending'),
                _buildRuleDetailRow('Last RBNZ Review', 'Feb 2025'),
              ],
            ),
          ),
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

  Widget _buildHeroInputBox({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8, color: Colors.white54, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          TextFormField(
            key: ValueKey(value),
            initialValue: value.toStringAsFixed(0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.playfair(
                size: 14, color: Colors.white, weight: FontWeight.w800),
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
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value,
      {bool isGreen = false, bool isRed = false}) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: isGreen
                  ? const Color(0xFF059669)
                  : isRed
                      ? const Color(0xFFC0392B)
                      : theme.getTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBandRow({
    required String title,
    required String desc,
    required String tag,
    required bool isActive,
    required String colorType,
  }) {
    Color bg;
    Color fg;
    Color border;
    Color tagBg;
    Color tagFg;

    if (colorType == 'green') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF065F46);
      border = isActive ? const Color(0xFF059669) : Colors.transparent;
      tagBg = const Color(0xFFD1FAE5);
      tagFg = const Color(0xFF065F46);
    } else if (colorType == 'amber') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFC2410C);
      border = isActive ? const Color(0xFFD97706) : Colors.transparent;
      tagBg = const Color(0xFFFDE68A);
      tagFg = const Color(0xFF92400E);
    } else {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFC0392B);
      border = isActive ? const Color(0xFFC0392B) : Colors.transparent;
      tagBg = const Color(0xFFFEE2E2);
      tagFg = const Color(0xFFC0392B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorType == 'green'
                  ? const Color(0xFF059669)
                  : colorType == 'amber'
                      ? const Color(0xFFD97706)
                      : const Color(0xFFC0392B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11.5, weight: FontWeight.w800, color: fg)),
                const SizedBox(height: 1),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9, color: const Color(0xFF4A6358))),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: tagBg, borderRadius: BorderRadius.circular(20)),
            child: Text(tag,
                style: AppTextStyles.dmSans(
                    size: 9.5, weight: FontWeight.w800, color: tagFg)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value, String pill) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1E92400E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 11, color: const Color(0xFF92400E))),
          Row(
            children: [
              Text(value,
                  style: AppTextStyles.dmSans(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFF92400E))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(pill,
                    style: AppTextStyles.dmSans(
                        size: 9, weight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1E92400E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 11, color: const Color(0xFF92400E))),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: const Color(0xFF92400E))),
        ],
      ),
    );
  }
}
