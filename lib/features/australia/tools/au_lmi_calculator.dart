// lib/features/australia/tools/au_lmi_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AULmiCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AULmiCalc({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AULmiCalc> createState() => _AULmiCalcState();
}

class _AULmiCalcState extends ConsumerState<AULmiCalc> {
  double _propVal = 750000;
  double _deposit = 75000;
  int _termYears = 30;
  String _stateCode = 'NSW';
  String _ownerType = 'owner'; // 'owner' or 'invest'

  bool _showResults = false;

  final List<Map<String, dynamic>> _lmiTiers = [
    {
      'lvr': '≤ 80%',
      'label': 'No LMI',
      'rate': 0.0,
      'color': Colors.green,
      'bg': const Color(0xFFF0FDF4),
      'text': const Color(0xFF166534)
    },
    {
      'lvr': '80.01–85%',
      'label': 'Low LMI',
      'rate': 0.0077,
      'color': Colors.amber,
      'bg': const Color(0xFFFFFBEB),
      'text': const Color(0xFF92400E)
    },
    {
      'lvr': '85.01–90%',
      'label': 'Medium',
      'rate': 0.0196,
      'color': Colors.orange,
      'bg': const Color(0xFFFFF7ED),
      'text': const Color(0xFF9A3412)
    },
    {
      'lvr': '90.01–95%',
      'label': 'High',
      'rate': 0.0384,
      'color': Colors.red,
      'bg': const Color(0xFFFEF2F2),
      'text': const Color(0xFF991B1B)
    },
    {
      'lvr': '95.01%+',
      'label': 'Very High',
      'rate': 0.0486,
      'color': const Color(0xFF7F1D1D),
      'bg': const Color(0xFFFEE2E2),
      'text': const Color(0xFF7F1D1D)
    },
  ];

  void _reset() {
    setState(() {
      _propVal = 750000;
      _deposit = 75000;
      _termYears = 30;
      _stateCode = 'NSW';
      _ownerType = 'owner';
      _showResults = false;
    });
  }

  Map<String, double> _calcLMI(double loanAmt, double lvr, String ownerType) {
    double rate = 0;
    if (lvr <= 80) {
      rate = 0;
    } else if (lvr <= 85) {
      rate = 0.0077;
    } else if (lvr <= 90) {
      rate = 0.0196;
    } else if (lvr <= 95) {
      rate = 0.0384;
    } else {
      rate = 0.0486;
    }

    if (ownerType == 'invest') rate *= 1.15; // investment surcharge

    final lmi = loanAmt * rate;
    final gst = lmi * 0.10;
    final stamp = lmi * 0.09; // ~9% stamp duty on LMI varies by state
    final total = lmi + gst + stamp;

    return {
      'lmi': lmi,
      'gst': gst,
      'stamp': stamp,
      'total': total,
      'rate': rate,
    };
  }

  void _saveCalculation() async {
    final loanAmt = _propVal - _deposit;
    if (loanAmt <= 0) return;

    final lvr = (loanAmt / _propVal) * 100;
    final lmiData = _calcLMI(loanAmt, lvr, _ownerType);
    final totalLmi = lmiData['total']!;

    // Prompt user for label
    final labelCtrl = TextEditingController(text: 'Bondi LMI Estimate');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_lmi_calculator'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save LMI Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: LMI for \$${(_propVal / 1000).toStringAsFixed(0)}K property · LVR ${lvr.toStringAsFixed(1)}%',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Dream Home - LMI)',
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
          : 'LMI Calculation';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'LMI Calculator',
        inputs: {
          'propertyValue': _propVal,
          'deposit': _deposit,
          'termYears': _termYears.toDouble(),
          'ownerType': _ownerType == 'owner' ? 0.0 : 1.0,
        },
        results: {
          'lvr': lvr,
          'depositPct': (_deposit / _propVal) * 100,
          'lmiPremium': lmiData['lmi']!,
          'gst': lmiData['gst']!,
          'stamp': lmiData['stamp']!,
          'total': totalLmi,
          'rate': lmiData['rate']!,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculations
    final loanAmt = _propVal - _deposit;
    final lvr = _propVal > 0 ? (loanAmt / _propVal) * 100 : 0.0;
    final depPct = _propVal > 0 ? (_deposit / _propVal) * 100 : 0.0;

    final lmiData = _calcLMI(loanAmt, lvr, _ownerType);
    final lmi = lmiData['lmi']!;
    final gst = lmiData['gst']!;
    final stamp = lmiData['stamp']!;
    final total = lmiData['total']!;
    final rate = lmiData['rate']!;

    // Repayments
    const monthlyRate = 0.0609 / 12;
    final n = _termYears * 12;
    double calcRepay(double loan) {
      if (monthlyRate == 0) return loan / n;
      return loan *
          (monthlyRate * pow(1 + monthlyRate, n)) /
          (pow(1 + monthlyRate, n) - 1);
    }

    final baseRepay = calcRepay(loanAmt);
    final capRepay = calcRepay(loanAmt + total);
    final extraMonthly = capRepay - baseRepay;

    // Active tier
    int activeTierIdx = 0;
    if (lvr <= 80) {
      activeTierIdx = 0;
    } else if (lvr <= 85) {
      activeTierIdx = 1;
    } else if (lvr <= 90) {
      activeTierIdx = 2;
    } else if (lvr <= 95) {
      activeTierIdx = 3;
    } else {
      activeTierIdx = 4;
    }

    // Cost comparison samples
    final samples = [600000.0, 750000.0, 900000.0, 1000000.0];
    final maxLMIValue = samples
        .map((p) => _calcLMI(p * (lvr / 100), lvr, _ownerType)['total']!)
        .reduce(max);

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
              colors: [Color(0xFF140800), Color(0xFF7C2D12)],
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
                  Text('Lenders Mortgage Insurance Calculator',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white54,
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
              Text('Calculate your LMI Premium',
                  style: AppTextStyles.playfair(
                      size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Property Value',
                      prefix: 'AUD \$',
                      value: _propVal,
                      onChanged: (val) => setState(() => _propVal = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Deposit / Savings',
                      prefix: 'AUD \$',
                      value: _deposit,
                      onChanged: (val) => setState(() => _deposit = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STATE',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: Colors.white54,
                                  weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _stateCode,
                              dropdownColor: const Color(0xFF140800),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              isDense: true,
                              style: AppTextStyles.playfair(
                                  size: 15,
                                  color: Colors.white,
                                  weight: FontWeight.w800),
                              items: [
                                'NSW',
                                'VIC',
                                'QLD',
                                'WA',
                                'SA',
                                'TAS',
                                'ACT',
                                'NT'
                              ].map((st) {
                                return DropdownMenuItem(
                                    value: st,
                                    child: Text(st,
                                        style: AppTextStyles.playfair(
                                            size: 15,
                                            color: Colors.white,
                                            weight: FontWeight.w800)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _stateCode = val);
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

              // Toggle Row
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                          'Owner Occupied', _ownerType == 'owner', () {
                        setState(() => _ownerType = 'owner');
                      }),
                    ),
                    Expanded(
                      child: _buildToggleButton(
                          'Investment', _ownerType == 'invest', () {
                        setState(() => _ownerType = 'invest');
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (_deposit >= _propVal) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Deposit must be less than property value',
                              style: AppTextStyles.dmSans())),
                    );
                    return;
                  }
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
                child: Text('🛡️ Calculate LMI',
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

          // LVR Needle Gauge Card
          Text('LVR Gauge',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Text('Loan-to-Value Ratio (LVR)',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 14),
                // Needle Gauge Track
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // LVR starts visually from 60% to 100%
                    final gaugePos = ((lvr - 60) / 40).clamp(0.0, 1.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFF3F4F6),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 80,
                                      child: Container(
                                          color: const Color(
                                              0xFF86EFAC))), // 60-80% safe
                                  Expanded(
                                      flex: 10,
                                      child: Container(
                                          color: const Color(
                                              0xFFFBBF24))), // 80-85% warn
                                  Expanded(
                                      flex: 5,
                                      child: Container(
                                          color: const Color(
                                              0xFFF97316))), // 85-90% med
                                  Expanded(
                                      flex: 5,
                                      child: Container(
                                          color: const Color(
                                              0xFFEF4444))), // 90-100% high
                                ],
                              ),
                            ),
                            Positioned(
                              left: gaugePos * (width - 4),
                              top: -4,
                              child: Container(
                                width: 4,
                                height: 26,
                                decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A0A00),
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('60%',
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    color: theme.getMutedColor(context))),
                            Text('80%',
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    color: theme.getMutedColor(context))),
                            Text('85%',
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    color: theme.getMutedColor(context))),
                            Text('90%',
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    color: theme.getMutedColor(context))),
                            Text('95%+',
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    color: theme.getMutedColor(context))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValBox(
                        'Your LVR',
                        '${lvr.toStringAsFixed(1)}%',
                        lvr <= 80
                            ? Colors.green
                            : lvr <= 90
                                ? Colors.orange
                                : Colors.red),
                    _buildValBox('Deposit %', '${depPct.toStringAsFixed(1)}%',
                        Colors.blue),
                    _buildValBox(
                        'Loan Amount',
                        CurrencyFormatter.format(loanAmt, currencyCode: 'AUD'),
                        Colors.black),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LMI Result',
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

          // LMI Result Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Text('Estimated LMI Premium',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                    lvr <= 80
                        ? '\$0'
                        : CurrencyFormatter.format(total, currencyCode: 'AUD'),
                    style: AppTextStyles.playfair(
                        size: 40,
                        color: lvr <= 80
                            ? Colors.green
                            : (isDark ? const Color(0xFFFCA5A5) : Colors.red),
                        weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  lvr <= 80
                      ? '✅ No LMI required — LVR ≤ 80%'
                      : 'LMI (${(rate * 100).toStringAsFixed(2)}%) + GST + Stamp Duty',
                  style: AppTextStyles.dmSans(
                      size: 11, color: theme.getMutedColor(context)),
                ),
                if (lvr > 80) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Base: ${CurrencyFormatter.format(lmi, currencyCode: 'AUD')} · GST: ${CurrencyFormatter.format(gst, currencyCode: 'AUD')} · Stamp: ${CurrencyFormatter.format(stamp, currencyCode: 'AUD')}',
                    style: AppTextStyles.dmSans(
                        size: 10, color: isDark ? Colors.white60 : Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Info Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildSummaryBox('LMI Capitalised',
                        CurrencyFormatter.format(total, currencyCode: 'AUD')),
                    _buildSummaryBox(
                        'Total Loan (incl. LMI)',
                        CurrencyFormatter.format(loanAmt + total,
                            currencyCode: 'AUD')),
                    _buildSummaryBox('Monthly Repayment',
                        '${CurrencyFormatter.format(capRepay, currencyCode: 'AUD')}/mo'),
                    _buildSummaryBox('Extra Monthly (LMI)',
                        '${CurrencyFormatter.format(extraMonthly, currencyCode: 'AUD')}/mo'),
                  ],
                ),
              ],
            ),
          ),

          // Tiers Table Card
          const SizedBox(height: 20),
          Text('LMI Rate Tiers (Genworth 2026)',
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
                ..._lmiTiers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value;
                  final isActive = idx == activeTierIdx;
                  final itemRate = t['rate'] as double;
                  final double displayRate = itemRate == 0
                      ? 0
                      : itemRate * (_ownerType == 'invest' ? 1.15 : 1.0);

                  Color rateColor = t['color'] as Color;
                  Color badgeBg = t['bg'] as Color;
                  Color badgeText = t['text'] as Color;

                  if (isDark) {
                    if (rateColor == Colors.green) {
                      rateColor = const Color(0xFF34D399);
                    } else if (rateColor == Colors.amber) {
                      rateColor = const Color(0xFFFCD34D);
                    } else if (rateColor == Colors.orange) {
                      rateColor = const Color(0xFFF59E0B);
                    } else if (rateColor == Colors.red) {
                      rateColor = const Color(0xFFFCA5A5);
                    } else if (rateColor == const Color(0xFF7F1D1D)) {
                      rateColor = const Color(0xFFEF4444);
                    }

                    final baseColor = t['color'] as Color;
                    badgeBg = baseColor.withValues(alpha: 0.15);
                    badgeText = baseColor == const Color(0xFF7F1D1D)
                        ? const Color(0xFFEF4444)
                        : baseColor;
                  }

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark
                              ? const Color(0xFF7C2D12)
                              : const Color(0xFFFFF8F0))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 65,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: Text(t['label'],
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: badgeText)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LVR ${t['lvr']}',
                                style: AppTextStyles.dmSans(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: theme.getTextColor(context))),
                            Text(
                                idx == 0
                                    ? 'Standard requirement'
                                    : 'Premium of loan amount',
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: theme.getMutedColor(context))),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              displayRate == 0
                                  ? '—'
                                  : '${(displayRate * 100).toStringAsFixed(2)}%',
                              style: AppTextStyles.dmSans(
                                  size: 12.5,
                                  weight: FontWeight.w800,
                                  color: rateColor),
                            ),
                            if (isActive)
                              Text('◀ Your LVR',
                                  style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      weight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFFFFD700)
                                          : theme.primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('LMI Cost Comparison',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: theme.getMutedColor(context))),
                ),
                const SizedBox(height: 10),
                // Simple bar comparison
                ...samples.map((p) {
                  final lmiVal =
                      _calcLMI(p * (lvr / 100), lvr, _ownerType)['total']!;
                  final barPct = maxLMIValue > 0 ? lmiVal / maxLMIValue : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 85,
                          child: Text(
                              '\$${(p / 1000).toStringAsFixed(0)}K property',
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  color: theme.getMutedColor(context))),
                        ),
                        Expanded(
                          child: Container(
                            height: 10,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFFFF8F0),
                                borderRadius: BorderRadius.circular(5)),
                            child: FractionallySizedBox(
                              widthFactor: barPct.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF002868),
                                    Color(0xFFEA580C)
                                  ]),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 55,
                          child: Text(
                            lmiVal > 0
                                ? CurrencyFormatter.compact(lmiVal,
                                    symbol: '\$')
                                : '—',
                            style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.w700,
                                color: theme.getTextColor(context)),
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
        ],

        // About LMI Guide
        const SizedBox(height: 20),
        Text('About LMI',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF7C2D12).withValues(alpha: 0.2),
                      const Color(0xFF7C2D12).withValues(alpha: 0.1)
                    ]
                  : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
            ),
            border: Border.all(
                color:
                    isDark ? const Color(0xFFEA580C) : const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🛡️ LMI Facts (Australia 2026)',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF7C2D12))),
              const SizedBox(height: 12),
              _buildTipRow('1',
                  'LMI protects the lender (not you) if you default. It\'s required by most lenders when LVR exceeds 80%.'),
              _buildTipRow('2',
                  'Rates are based on Genworth & QBE sliding scale tables — the larger and higher the LVR, the higher the premium.'),
              _buildTipRow('3',
                  'You can capitalise LMI (add to loan) but this means paying interest on the insurance premium over your whole loan term.'),
              _buildTipRow('4',
                  'First Home Guarantee (FHBG) lets eligible first-home buyers purchase with 5% deposit without paying LMI.'),
              _buildTipRow('5',
                  'Some professions (doctors, lawyers, accountants) get LMI waivers from certain lenders with up to 90% LVR.'),
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
    bool isPercent = false,
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
              if (isPercent)
                Text('%',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white54,
                        weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD700) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: active ? const Color(0xFF1A0A00) : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildValBox(String label, String val, Color valCol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color displayColor = valCol;
    if (isDark) {
      if (valCol == Colors.black) {
        displayColor = Colors.white;
      } else if (valCol == Colors.blue) {
        displayColor = const Color(0xFF60A5FA);
      } else if (valCol == Colors.green) {
        displayColor = const Color(0xFF34D399);
      } else if (valCol == Colors.orange) {
        displayColor = const Color(0xFFFBBF24);
      } else if (valCol == Colors.red) {
        displayColor = const Color(0xFFFCA5A5);
      }
    }
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9.5,
                color: isDark ? Colors.white70 : const Color(0xFF92400E))),
        const SizedBox(height: 2),
        Text(val,
            style: AppTextStyles.playfair(
                size: 16, weight: FontWeight.w800, color: displayColor)),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildTipRow(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
                color: Color(0xFFEA580C), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(bullet,
                style: AppTextStyles.dmSans(
                    size: 9, color: Colors.white, weight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.dmSans(
                    size: 10.5, color: const Color(0xFF92400E), height: 1.4)),
          ),
        ],
      ),
    );
  }
}
