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
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  void _reset() {
    setState(() {
      _propVal = 850000;
      _deposit = 170000;
      _buyerType = 'owner';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};

    if (_propVal <= 0) {
      errors['propVal'] = 'Enter valid property value';
    }
    if (_deposit < 0) {
      errors['deposit'] = 'Deposit cannot be negative';
    } else if (_deposit >= _propVal && _propVal > 0) {
      errors['deposit'] = 'Deposit must be less than property value';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['deposit'] = _deposit;
      _calcSnapshot['buyerType'] = _buyerType;
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

  void _saveCalculation(
      double loan, double lvr, double depPct, double gap, String status) async {
    final snapPropVal = _calcSnapshot['propVal'] ?? _propVal;
    final snapDeposit = _calcSnapshot['deposit'] ?? _deposit;
    final snapBuyerType = _calcSnapshot['buyerType'] ?? _buyerType;

    final labelCtrl = TextEditingController(text: 'NZ LVR Band Analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_lvr_band_tool/save'),
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
                'Saving: LVR of ${lvr.toStringAsFixed(1)}% ($status) for a ${CurrencyFormatter.compact(snapPropVal, symbol: 'NZ\$')} property.',
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
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'LVR Band Analysis';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'LVR Band Tool',
        inputs: <String, double>{
          'propertyValue': snapPropVal,
          'deposit': snapDeposit,
          'buyerType': snapBuyerType == 'owner'
              ? 0.0
              : snapBuyerType == 'investor'
                  ? 1.0
                  : 2.0,
        },
        results: <String, double>{
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

    final double rawPropVal = _propVal;
    final double rawDeposit = _deposit;
    final String rawBuyerType = _buyerType;

    final double propVal = _showResults ? (_calcSnapshot['propVal'] ?? rawPropVal) : rawPropVal;
    final double deposit = _showResults ? (_calcSnapshot['deposit'] ?? rawDeposit) : rawDeposit;
    final String buyerType = _showResults ? (_calcSnapshot['buyerType'] ?? rawBuyerType) : rawBuyerType;

    // Calculations
    final loan = propVal - deposit;
    final lvr = propVal > 0 ? (loan / propVal) * 100 : 0.0;
    final depPct = propVal > 0 ? (deposit / propVal) * 100 : 0.0;

    double limit = buyerType == 'investor'
        ? 65.0
        : buyerType == 'newbuild'
            ? 90.0
            : 80.0;
    double gap = limit - lvr;

    // Determine status
    String status = '';
    Color statusColor;
    Color pillBg;
    Color pillFg;
    String subText = '';

    if (buyerType == 'investor') {
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
    } else if (buyerType == 'newbuild') {
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

    final isDirty = _showResults && (
      _propVal != (_calcSnapshot['propVal'] ?? 0.0) ||
      _deposit != (_calcSnapshot['deposit'] ?? 0.0) ||
      _buyerType != (_calcSnapshot['buyerType'] ?? '')
    );

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
                        errorText: _errors['propVal'],
                        onChanged: (val) => setState(() => _propVal = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Deposit / Equity',
                        value: _deposit,
                        errorText: _errors['deposit'],
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
                              CurrencyFormatter.compact(propVal - deposit, symbol: 'NZ\$'),
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
                  onPressed: _calculate,
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
                        'Inputs have changed. Tap Calculate LVR Band to refresh results.',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                              '${buyerType == 'investor' ? 'Investor' : 'Owner-Occ'} LVR Analysis',
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
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (lvr / 100).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('LVR standard limit: ${limit.toInt()}%',
                                style: AppTextStyles.dmSans(
                                    size: 10,
                                    color: theme.getMutedColor(context),
                                    weight: FontWeight.bold)),
                            Text(
                              gap >= 0
                                  ? '${gap.toStringAsFixed(1)}% Headroom'
                                  : '${(-gap).toStringAsFixed(1)}% Exceeded',
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  color: gap >= 0
                                      ? const Color(0xFF1A6B4A)
                                      : const Color(0xFFC0392B),
                                  weight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Breakdown lists
                        _buildRow('Total Loan Needed',
                            CurrencyFormatter.format(loan, currencyCode: 'NZD'), theme),
                        const SizedBox(height: 8),
                        _buildRow('Required Deposit ($depPct%)',
                            CurrencyFormatter.format(deposit, currencyCode: 'NZD'), theme),
                        const SizedBox(height: 8),
                        _buildRow('Status Details', subText, theme, isBold: true),
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
                              loan, lvr, depPct, gap, status),
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
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Informational Content on NZ LVR Bands
          Text('Understanding LVR Bands in NZ',
              style: AppTextStyles.playfair(
                  size: 14,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 10),
          _buildInfoPill('🟢 Under 65% LVR (Safe Zone)',
              'Standard pricing applies. Banks highly welcome these low-risk loans. Standard investor limit met.', theme),
          const SizedBox(height: 8),
          _buildInfoPill('🟡 65% to 80% LVR (Standard Band)',
              'Standard owner-occupier pricing. Investors require special exemptions (like a new build) to borrow in this band.', theme),
          const SizedBox(height: 8),
          _buildInfoPill('🟠 80% to 90% LVR (Low Equity Band)',
              'Low Equity Margin (LEM) or Low Equity Premium (LEP) applies. This adds +0.25% to +1.50% to your interest rate or a 1% upfront fee.', theme),
          const SizedBox(height: 8),
          _buildInfoPill('🔴 Above 90% LVR (Exceeds Limit)',
              'Extremely rare. Typically restricted to Kāinga Ora First Home Loans or specialist non-bank lenders.', theme),
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
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
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
    String? errorText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.2)),
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
            initialValue: value.toInt().toString(),
            keyboardType: TextInputType.number,
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
          if (errorText != null) ...[
            const SizedBox(height: 2),
            Text(errorText, style: AppTextStyles.dmSans(size: 8, color: Colors.red, weight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, CountryTheme theme, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getMutedColor(context),
                weight: FontWeight.w600)),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getTextColor(context),
                weight: isBold ? FontWeight.w800 : FontWeight.w700)),
      ],
    );
  }

  Widget _buildInfoPill(String title, String desc, CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context))),
          const SizedBox(height: 2),
          Text(desc,
              style: AppTextStyles.dmSans(
                  size: 9.5, color: theme.getMutedColor(context), height: 1.35)),
        ],
      ),
    );
  }
}
