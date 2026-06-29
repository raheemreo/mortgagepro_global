// lib/features/india/tools/in_rbi_monetary_policy.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INRBIMonetaryPolicy extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INRBIMonetaryPolicy({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INRBIMonetaryPolicy> createState() => _INRBIMonetaryPolicyState();
}

class _INRBIMonetaryPolicyState extends ConsumerState<INRBIMonetaryPolicy> {
  late Timer _timer;
  Duration _countdown = const Duration(days: 57, hours: 14, minutes: 25, seconds: 10);

  // Database of timeline decisions
  static final List<Map<String, dynamic>> _decisions = [
    {
      'mon': 'Jun',
      'yr': '2026',
      'action': 'hold',
      'actionLabel': '⏸ Hold',
      'rate': '5.25%',
      'change': 'Unchanged',
      'detail': 'Third consecutive hold. Neutral stance maintained. Iran war impact on inflation monitored. GDP forecast raised to 7.3%. Rupee weakness (~₹95.4) a concern.'
    },
    {
      'mon': 'Feb',
      'yr': '2026',
      'action': 'hold',
      'actionLabel': '⏸ Hold',
      'rate': '5.25%',
      'change': 'Unchanged',
      'detail': 'Stable prices and strong economy. Many expected 25 bps cut but RBI held rates. SDF at 5.00%, MSF at 5.50%. Neutral stance maintained.'
    },
    {
      'mon': 'Dec',
      'yr': '2025',
      'action': 'cut',
      'actionLabel': '▼ Rate Cut',
      'rate': '5.25%',
      'change': '-25 bps',
      'detail': 'Unanimous 6-0 cut. CPI at 2%, GDP forecast raised to 7.3%. ₹1 lakh cr govt bond purchases & \$5B USD/INR swap announced. SDF to 5.00%.'
    },
    {
      'mon': 'Jun',
      'yr': '2025',
      'action': 'cut',
      'actionLabel': '▼ Rate Cut',
      'rate': '5.50%',
      'change': '-50 bps',
      'detail': 'Largest single cut — 50 bps. Third consecutive cut since Feb. Stance changed from accommodative → neutral. CRR cut by 100 bps. CPI projected at 3.7% for FY26.'
    },
    {
      'mon': 'Apr',
      'yr': '2025',
      'action': 'cut',
      'actionLabel': '▼ Rate Cut',
      'rate': '6.00%',
      'change': '-25 bps',
      'detail': 'Second cut of easing cycle. Inflation softening below 4% target. Growth supported by private consumption and fixed capital formation.'
    },
    {
      'mon': 'Feb',
      'yr': '2025',
      'action': 'cut',
      'actionLabel': '▼ Rate Cut',
      'rate': '6.25%',
      'change': '-25 bps',
      'detail': 'First cut since May 2020. Easing cycle begins under Gov. Sanjay Malhotra. Accommodative stance adopted. Previous rate 6.50% held for 8 consecutive meetings.'
    }
  ];

  @override
  void initState() {
    super.initState();
    // Calculate live countdown to Aug 5, 2026
    final target = DateTime(2026, 8, 5, 10, 0, 0);
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.inSeconds > 0) {
      _countdown = diff;
    } else {
      _countdown = const Duration(days: 57, hours: 14, minutes: 25, seconds: 10);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown.inSeconds > 0) {
            _countdown = _countdown - const Duration(seconds: 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _savePolicySnapshot() async {
    final labelCtrl = TextEditingController(text: 'RBI Monetary Policy Snapshot');

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_rbi_monetary_policy'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Policy Snapshot', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving RBI corridor parameters: Repo 5.25%, SDF 5.00%, MSF 5.50%',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Jun 2026 Policy Corridor)',
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
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'RBI Monetary Policy';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'RBI Monetary Policy Info',
        inputs: {},
        results: {
          'repoRate': 5.25,
          'sdfRate': 5.00,
          'msfRate': 5.50,
          'crrRate': 3.00,
          'slrRate': 18.00,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Policy snapshot saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
    // Time calculations
    final dDays = _countdown.inDays;
    final dHours = _countdown.inHours % 24;
    final dMins = _countdown.inMinutes % 60;
    final dSecs = _countdown.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('Repo Rate', '5.25%', 'Jun 2026', isSaffron: true),
              _infoCell('CPI Inflation', '2.00%', 'FY26 Est.', isGreen: true),
              _infoCell('GDP FY26', '7.30%', 'RBI Est.', isGreen: true),
              _infoCell('Stance', 'Neutral', 'MPC Stance'),
            ],
          ),
        ),

        // Reserve Bank of India Hero Card
        Text('Reserve Bank of India', style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF046A38).withValues(alpha: 0.25),
                      border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text('Live · Jun 9, 2026', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF86EFAC), weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Text('RBI.ORG.IN ➔', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFFDEA0), weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Text('MONETARY POLICY COMMITTEE (MPC) · CURRENT RATE',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('5.25', style: AppTextStyles.playfair(size: 48, color: Colors.white, weight: FontWeight.w800)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 2),
                    child: Text('%', style: AppTextStyles.dmSans(size: 16, color: const Color(0xFFFFDEA0), weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5).withValues(alpha: 0.18),
                      border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('▼ -100 bps since Feb 2025', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF86EFAC), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _rbiBox('SDF Rate', '5.00%'),
                  const SizedBox(width: 8),
                  _rbiBox('MSF/Bank Rate', '5.50%'),
                  const SizedBox(width: 8),
                  _rbiBox('CRR', '3.00%', isGreen: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Policy Rate Corridor Block Visualizer
        Text('RBI Policy Rate Corridor', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interest Rate Corridor – Jun 2026', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _corridorBlock('SDF (Floor)', '5.00%', 'Standing Deposit Facility', const Color(0xFF046A38)),
                  const SizedBox(width: 8),
                  _corridorBlock('Repo Rate', '5.25%', 'Policy Rate · Unchanged', const Color(0xFFFF6B00), isHighlight: true),
                  const SizedBox(width: 8),
                  _corridorBlock('MSF (Ceiling)', '5.50%', 'Marginal Standing Facility', const Color(0xFF0B1F48)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Next Meeting Countdown Timer Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)]),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT MPC MEETING',
                        style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w800, letterSpacing: 0.5)),
                    Text('Aug 5–7, 2026', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                    Text('Bi-monthly policy review · 6 MPC members', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${dDays}d ${dHours}h ${dMins}m ${dSecs}s',
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('until announcement', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white70, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // MPC Rate Decisions History Chart Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MPC Rate Decisions — 2025–26', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
            Text('Repo Rate Trend', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Policy Rates Trend Over Last 6 Meetings', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('6 MPC Meetings · FY2025–26 · % per annum', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 16),

              // Custom paint line chart for the repo rates
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RepoRateChartPainter(
                    meetings: const ['Feb\'25', 'Apr\'25', 'Jun\'25', 'Aug\'25', 'Dec\'25', 'Jun\'26'],
                    rates: const [6.50, 6.25, 6.00, 5.50, 5.25, 5.25],
                    actions: const ['hold', 'cut', 'cut', 'cut', 'cut', 'hold'], // hold is orange, cut is green
                    lineColor: const Color(0xFFFF6B00),
                    gridColor: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                    textColor: theme.getTextColor(context),
                    mutedColor: theme.getMutedColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(const Color(0xFFD97706), 'Hold'),
                  const SizedBox(width: 14),
                  _legendDot(const Color(0xFF046A38), 'Cut'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Timeline of recent Decisions
        Text('MPC Decision History', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: _decisions.asMap().entries.map((entry) {
              final idx = entry.key;
              final d = entry.value;
              final isLast = idx == _decisions.length - 1;
              final isCut = d['action'] == 'cut';

              Color badgeBg = isCut ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED);
              Color badgeFg = isCut ? const Color(0xFF065F46) : const Color(0xFF92400E);
              Color lineCol = isCut ? const Color(0xFF046A38) : const Color(0xFFD97706);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 44,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        decoration: BoxDecoration(color: const Color(0xFF0B1F48), borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                             Text(d['mon'], style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
                            Text(d['yr'], style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 48,
                          color: lineCol,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Right detail body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(d['actionLabel'], style: AppTextStyles.dmSans(size: 8.5, color: badgeFg, weight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(d['rate'], style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: theme.getTextColor(context))),
                            const SizedBox(width: 6),
                            Text(
                              d['change'],
                              style: AppTextStyles.dmSans(
                                size: 9.5,
                                weight: FontWeight.w700,
                                color: isCut ? const Color(0xFF046A38) : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        Text(d['detail'], style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.45)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Projections FY 2025-26 Grid Card
        Text('RBI Projections FY 2025–26', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📈 GDP Growth', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                    const SizedBox(height: 8),
                    _projRow('Q1 FY26', '7.1%', isGreen: true),
                    _projRow('Q2 FY26', '7.3%', isGreen: true),
                    _projRow('Q3 FY26', '7.5%', isGreen: true),
                    _projRow('FY26 Est.', '7.30%', isGreen: true),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎈 CPI Inflation', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                    const SizedBox(height: 8),
                    _projRow('Q1 FY26', '2.9%', isSaffron: true),
                    _projRow('Q2 FY26', '3.4%', isSaffron: true),
                    _projRow('Q3 FY26', '3.9%', isSaffron: true),
                    _projRow('FY26 Est.', '3.70%', isSaffron: true),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Impact on Home Loans card
        Text('Rate Cut Impact on Home Loans', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How -100 bps Cut Affects You', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              _impactRow('🏠', 'Home Loan EMI (₹50L, 20yr)', 'Savings: ~₹3,200/month vs Feb 2025 rates', '▼ Lower', isGood: true),
              _impactRow('📊', 'RLLR (Repo Linked Lending)', 'Now linked to 5.25% repo; bank spread 2–3%', '7.25–8.25%', isGood: true),
              _impactRow('💰', 'Fixed Deposit Returns', 'FD rates lowered; short tenures still attractive', '▼ Falling', isWarn: true),
              _impactRow('🏗️', 'Real Estate Demand', 'Cheaper loans boosting housing demand; Nifty Realty up', '▲ Positive', isGood: true),
              _impactRow('💱', 'Rupee Pressure', 'Rate cuts widen rate differential; INR at ₹95.4/USD', '▲ Weak', isBad: true),
            ],
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _savePolicySnapshot,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bookmark, color: Colors.white, size: 14),
            label: Text('Save Policy Corridor Snapshot', style: AppTextStyles.dmSans(size: 11.5, color: Colors.white, weight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note, {bool isGreen = false, bool isSaffron = false}) {
    Color valColor = Colors.white;
    if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    } else if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    }
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _rbiBox(String label, String value, {bool isGreen = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: isGreen ? const Color(0xFF86EFAC) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corridorBlock(String title, String val, String subtitle, Color color, {bool isHighlight = false}) {
    final theme = widget.theme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlight ? color : theme.getBorderColor(context).withValues(alpha: 0.05),
          border: Border.all(color: isHighlight ? color : theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 8, color: isHighlight ? Colors.white70 : theme.getMutedColor(context), weight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(val, style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: isHighlight ? Colors.white : theme.getTextColor(context))),
            const SizedBox(height: 1),
            Text(
              subtitle,
               style: AppTextStyles.dmSans(size: 8, color: isHighlight ? Colors.white.withValues(alpha: 0.55) : theme.getMutedColor(context)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _projRow(String q, String val, {bool isGreen = false, bool isSaffron = false}) {
    Color col = widget.theme.getTextColor(context);
    if (isGreen) {
      col = const Color(0xFF046A38);
    } else if (isSaffron) {
      col = const Color(0xFFFF6B00);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.theme.getBorderColor(context).withValues(alpha: 0.07))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(q, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
          Text(val, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: col)),
        ],
      ),
    );
  }

  Widget _impactRow(String icon, String title, String sub, String badge, {bool isGood = false, bool isWarn = false, bool isBad = false}) {
    final theme = widget.theme;
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);
    if (isGood) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF065F46);
    } else if (isWarn) {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFC2410C);
    } else if (isBad) {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.getBorderColor(context).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                Text(sub, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: AppTextStyles.dmSans(size: 8.5, color: fg, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _RepoRateChartPainter extends CustomPainter {
  final List<String> meetings;
  final List<double> rates;
  final List<String> actions;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final Color mutedColor;

  _RepoRateChartPainter({
    required this.meetings,
    required this.rates,
    required this.actions,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rates.length < 2) return;

    final double width = size.width;
    final double height = size.height - 20;

    // Rates map between 5.00% (bottom) and 7.00% (top)
    const double minVal = 5.00;
    const double maxVal = 7.00;
    const double valRange = maxVal - minVal;

    // Grid lines for 5%, 6%, 7%
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final y5 = height;
    final y6 = height / 2;
    const y7 = 0.0;

    canvas.drawLine(Offset(0, y5), Offset(width, y5), gridPaint);
    canvas.drawLine(Offset(0, y6), Offset(width, y6), gridPaint);
    canvas.drawLine(const Offset(0, y7), Offset(width, y7), gridPaint);

    // Points coordinates
    final List<Offset> points = [];
    final double stepX = width / (rates.length - 1);

    for (int i = 0; i < rates.length; i++) {
      final double x = stepX * i;
      final double ratio = (rates[i] - minVal) / valRange;
      final double y = height - (ratio * height);
      points.add(Offset(x, y));
    }

    // Path area fill gradient underneath the line
    final Path areaPath = Path()..moveTo(points.first.dx, height);
    for (var pt in points) {
      areaPath.lineTo(pt.dx, pt.dy);
    }
    areaPath.lineTo(points.last.dx, height);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withValues(alpha: 0.25), lineColor.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, width, height));
    canvas.drawPath(areaPath, areaPaint);

    // Line Path
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Nodes and labels
    for (int i = 0; i < points.length; i++) {
      final isCut = actions[i] == 'cut';
      final Color nodeColor = isCut ? const Color(0xFF046A38) : const Color(0xFFD97706);

      canvas.drawCircle(points[i], 4.0, Paint()..color = nodeColor);
      canvas.drawCircle(
        points[i],
        4.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Rate value text label above point
      final ratePainter = TextPainter(
        text: TextSpan(
          text: rates[i].toStringAsFixed(2),
          style: TextStyle(fontFamily: 'Trebuchet MS', fontSize: 8, color: nodeColor, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ratePainter.paint(
        canvas,
        Offset(points[i].dx - ratePainter.width / 2, points[i].dy - ratePainter.height - 4),
      );

      // Meeting label text below chart
      final meetingPainter = TextPainter(
        text: TextSpan(
          text: meetings[i],
          style: TextStyle(fontFamily: 'Trebuchet MS', fontSize: 8, color: mutedColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      meetingPainter.paint(
        canvas,
        Offset(points[i].dx - meetingPainter.width / 2, height + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RepoRateChartPainter oldDelegate) {
    return oldDelegate.rates != rates || oldDelegate.textColor != textColor;
  }
}
