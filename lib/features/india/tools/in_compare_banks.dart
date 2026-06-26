// lib/features/india/tools/in_compare_banks.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' show min, pi, pow;
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INCompareBanks extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INCompareBanks({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INCompareBanks> createState() => _INCompareBanksState();
}

class _INCompareBanksState extends ConsumerState<INCompareBanks> {
  // Input states
  double _loanAmount = 5000000; // 50 Lakhs
  double _tenureYears = 20;
  String _cibilRange = '800+'; // 800+, 750-799, 700-749, 650-699
  String _borrowerType = 'Salaried'; // Salaried, Self-Employed, NRI
  String _activeFilter = 'all'; // all, psu, private, hfc, nbfc, nri

  // Controllers
  late TextEditingController _loanAmtCtrl;
  late TextEditingController _tenureCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _comparisonTableKey = GlobalKey();

  // Banking Rates database
  static final List<Map<String, dynamic>> _banksDb = [
    {
      'name': 'Bank of Maharashtra',
      'shortName': 'Bank of Mah.',
      'type': 'psu',
      'typeLabel': 'PSU · Floating',
      'rate': 7.10,
      'ltv': '90%',
      'fee': 'Nil',
      'icon': '🏛️'
    },
    {
      'name': 'Bank of India',
      'shortName': 'Bank of India',
      'type': 'psu',
      'typeLabel': 'PSU · Floating',
      'rate': 7.10,
      'ltv': '90%',
      'fee': 'Nil',
      'icon': '🏦'
    },
    {
      'name': 'Union Bank',
      'shortName': 'Union Bank',
      'type': 'psu',
      'typeLabel': 'PSU · Floating',
      'rate': 7.15,
      'ltv': '80%',
      'fee': 'Nil',
      'icon': '🏦'
    },
    {
      'name': 'PNB',
      'shortName': 'PNB',
      'type': 'psu',
      'typeLabel': 'PSU · RLLR',
      'rate': 7.20,
      'ltv': '90%',
      'fee': '0.35%',
      'icon': '🏛️'
    },
    {
      'name': 'SBI',
      'shortName': 'SBI',
      'type': 'psu',
      'typeLabel': 'PSU · RLLR',
      'rate': 7.25,
      'ltv': '90%',
      'fee': '0.35%',
      'icon': '🏦'
    },
    {
      'name': 'Bajaj HFL',
      'shortName': 'Bajaj HFL',
      'type': 'nbfc',
      'typeLabel': 'NBFC · Floating',
      'rate': 7.35,
      'ltv': '75%',
      'fee': '0.5%',
      'icon': '🔶'
    },
    {
      'name': 'LIC HFL',
      'shortName': 'LIC HFL',
      'type': 'hfc',
      'typeLabel': 'HFC · Float/Fix',
      'rate': 7.40,
      'ltv': '80%',
      'fee': '₹10,000',
      'icon': '🏗️'
    },
    {
      'name': 'ICICI Bank',
      'shortName': 'ICICI Bank',
      'type': 'private',
      'typeLabel': 'Pvt · RLLR',
      'rate': 7.45,
      'ltv': '80%',
      'fee': '₹10,000',
      'icon': '🏢'
    },
    {
      'name': 'HDFC Bank',
      'shortName': 'HDFC Bank',
      'type': 'private',
      'typeLabel': 'Pvt · RLLR',
      'rate': 7.90,
      'ltv': '80%',
      'fee': '₹10,000',
      'icon': '🏛️'
    },
    {
      'name': 'Axis Bank',
      'shortName': 'Axis Bank',
      'type': 'private',
      'typeLabel': 'Pvt · RLLR',
      'rate': 7.90,
      'ltv': '80%',
      'fee': '₹10,000',
      'icon': '⚡'
    },
    {
      'name': 'Kotak',
      'shortName': 'Kotak',
      'type': 'private',
      'typeLabel': 'Pvt · Float',
      'rate': 7.99,
      'ltv': '80%',
      'fee': '0.5%',
      'icon': '🏦'
    },
    {
      'name': 'PNB Housing',
      'shortName': 'PNB Housing',
      'type': 'hfc',
      'typeLabel': 'HFC · Float',
      'rate': 8.50,
      'ltv': '75%',
      'fee': '1.0%',
      'icon': '🌿'
    }
  ];

  static const List<Map<String, dynamic>> _nriRates = [
    {'bank': '🏦 SBI NRI Home Loan', 'rate': 7.65},
    {'bank': '🏢 ICICI NRI Home Loan', 'rate': 7.90},
    {'bank': '🏛️ HDFC NRI Home Loan', 'rate': 8.05},
    {'bank': '⚡ Axis NRI Home Loan', 'rate': 8.10},
    {'bank': '🏗️ LIC HFL NRI Loan', 'rate': 7.85},
    {'bank': '🔶 Bajaj HFL NRI Loan', 'rate': 8.00},
  ];

  @override
  void initState() {
    super.initState();
    _loanAmtCtrl = TextEditingController(text: _loanAmount.toStringAsFixed(0));
    _tenureCtrl = TextEditingController(text: _tenureYears.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _loanAmtCtrl.dispose();
    _tenureCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _calcEMI(double principal, double annualRate, double tenureY) {
    final double monthlyRate = annualRate / 12 / 100;
    final int months = (tenureY * 12).toInt();
    if (monthlyRate == 0) return principal / months;
    return principal * monthlyRate * pow(1 + monthlyRate, months) / (pow(1 + monthlyRate, months) - 1);
  }

  double _getAdjustedRate(double baseRate) {
    double adj = 0.0;
    // CIBIL adjustment
    if (_cibilRange == '750-799') adj += 0.10;
    if (_cibilRange == '700-749') adj += 0.25;
    if (_cibilRange == '650-699') adj += 0.55;

    // Profile type adjustment
    if (_borrowerType == 'Self-Employed') adj += 0.15;
    if (_borrowerType == 'NRI') adj += 0.40;

    return baseRate + adj;
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }



  String _fmtK(double n) {
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)}K';
    return '₹${n.toStringAsFixed(0)}';
  }

  void _saveComparisonReport() async {
    final labelCtrl = TextEditingController(text: 'Multi-Bank Rate Comparison');
    final activeLenders = _getActiveLenders();
    if (activeLenders.isEmpty) return;

    final best = activeLenders.first;
    final worst = activeLenders.last;
    final bestEmi = _calcEMI(_loanAmount, best['adjRate'], _tenureYears);
    final worstEmi = _calcEMI(_loanAmount, worst['adjRate'], _tenureYears);
    final double totalInterestBest = (bestEmi * _tenureYears * 12) - _loanAmount;
    final double totalInterestWorst = (worstEmi * _tenureYears * 12) - _loanAmount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparison Snapshot', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving report: ${_fmt(_loanAmount)} home loan over ${_tenureYears.toInt()} years',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. June 2026 Home Loan)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Rate Comparison';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Bank Compare List',
        inputs: {
          'loanAmount': _loanAmount,
          'tenureYears': _tenureYears,
          'cibilIndex': _cibilRange == '800+' ? 0.0 : (_cibilRange == '750-799' ? 1.0 : (_cibilRange == '700-749' ? 2.0 : 3.0)),
          'borrowerTypeIndex': _borrowerType == 'Salaried' ? 0.0 : (_borrowerType == 'Self-Employed' ? 1.0 : 2.0),
        },
        results: {
          'bestRate': best['adjRate'],
          'bestEMI': bestEmi,
          'worstRate': worst['adjRate'],
          'worstEMI': worstEmi,
          'tenureSavings': totalInterestWorst - totalInterestBest,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Comparison saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getActiveLenders() {
    final filtered = _banksDb.where((b) {
      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'nri') return b['type'] == 'private' || b['type'] == 'hfc';
      return b['type'] == _activeFilter;
    }).toList();

    final result = filtered.map((b) {
      final double baseRate = b['rate'];
      final double adjusted = _getAdjustedRate(baseRate);
      return {
        ...b,
        'adjRate': adjusted,
      };
    }).toList();

    // Sort by rate ascending
    result.sort((a, b) => (a['adjRate'] as double).compareTo(b['adjRate'] as double));
    return result;
  }

  void _scrollToComparisonTable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _comparisonTableKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeLenders = _getActiveLenders();
    final hasLenders = activeLenders.isNotEmpty;

    final bestLender = hasLenders ? activeLenders.first : null;
    final worstLender = hasLenders ? activeLenders.last : null;

    final double bestRate = bestLender != null ? bestLender['adjRate'] : 7.10;
    final double worstRate = worstLender != null ? worstLender['adjRate'] : 8.50;

    // EMIs
    final double emiBest = _calcEMI(_loanAmount, bestRate, _tenureYears);
    final double emiWorst = _calcEMI(_loanAmount, worstRate, _tenureYears);

    final double totalIntBest = (emiBest * _tenureYears * 12) - _loanAmount;
    final double totalIntWorst = (emiWorst * _tenureYears * 12) - _loanAmount;
    final double totalTenureSaving = totalIntWorst - totalIntBest;

    // Donut split values for the best lender
    final double totalRepayment = emiBest * _tenureYears * 12;
    final double principalShare = totalRepayment > 0 ? (_loanAmount / totalRepayment) : 0.5;

    // Top 10 horizontal bar chart data
    final top10Chart = activeLenders.take(10).toList();
    final double maxRateVal = top10Chart.isNotEmpty ? top10Chart.last['adjRate'] : 1.0;

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
              _infoCell('Lowest Rate', '7.10%', 'BoM / BoI', isGreen: true),
              _infoCell('SBI Rate', '7.25%', 'Floating', isSaffron: true),
              _infoCell('Avg Private', '7.90%', 'Banks'),
              _infoCell('Repo Rate', '5.25%', 'RBI Jun\'26'),
            ],
          ),
        ),

        // Customise Search Hero
        Text('Customise Your Search', style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
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
              Text('🇮🇳 INDIA HOME LOAN RATE COMPARISON · JUN 9, 2026',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.45), weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Find the Lowest Rate for your Profile',
                  style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 14),

              // Synced input-slider: Loan Amount
              _buildSyncedInputRow(
                label: 'LOAN AMOUNT',
                controller: _loanAmtCtrl,
                value: _loanAmount,
                min: 100000,
                max: 100000000, // 10 Cr max
                prefix: '₹ ',
                onChangedText: (val) => setState(() => _loanAmount = val),
                onChangedSlider: (val) => setState(() {
                  _loanAmount = val;
                  _loanAmtCtrl.text = val.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 12),

              // Synced input-slider: Tenure (Years)
              _buildSyncedInputRow(
                label: 'TENURE (YEARS)',
                controller: _tenureCtrl,
                value: _tenureYears,
                min: 1,
                max: 30,
                suffix: ' Yrs',
                onChangedText: (val) => setState(() => _tenureYears = val),
                onChangedSlider: (val) => setState(() {
                  _tenureYears = val;
                  _tenureCtrl.text = val.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 12),

              // Dropdown selectors row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CIBIL SCORE', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cibilRange,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1F48),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: '800+', child: Text('800+ (Best)')),
                                DropdownMenuItem(value: '750-799', child: Text('750–799')),
                                DropdownMenuItem(value: '700-749', child: Text('700–749')),
                                DropdownMenuItem(value: '650-699', child: Text('650–699')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _cibilRange = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BORROWER TYPE', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _borrowerType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1F48),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'Salaried', child: Text('Salaried')),
                                DropdownMenuItem(value: 'Self-Employed', child: Text('Self-Employed')),
                                DropdownMenuItem(value: 'NRI', child: Text('NRI')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _borrowerType = v);
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

              // Filter chip scrollable row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Banks', 'all'),
                    const SizedBox(width: 6),
                    _buildFilterChip('PSU Banks', 'psu'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Private', 'private'),
                    const SizedBox(width: 6),
                    _buildFilterChip('HFC', 'hfc'),
                    const SizedBox(width: 6),
                    _buildFilterChip('NBFC', 'nbfc'),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _scrollToComparisonTable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('☸ Compare All Banks Now', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Best Rate Banner
        if (bestLender != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7), width: 1.5),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Best Rate: ${bestLender['name']}',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A))),
                      const SizedBox(height: 2),
                      Text('${bestLender['typeLabel']} · ${bestLender['ltv']} LTV · CIBIL $_cibilRange',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                    ],
                  ),
                ),
                Text('${bestRate.toStringAsFixed(2)}%',
                    style: AppTextStyles.dmSans(
                        size: 22,
                        weight: FontWeight.w800,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A))),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Rate Comparison Chart card
        Text('Rate Comparison Chart', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 12,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Home Loan Rates — Top Lenders (Jun 2026)', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              Column(
                children: top10Chart.map((b) {
                  final double val = b['adjRate'];
                  final pct = maxRateVal > 0 ? val / maxRateVal : 0.0;

                  // Color categories based on adjusted rates
                  LinearGradient color = const LinearGradient(colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)]);
                  String tag = 'Mid';
                  Color tagBg = const Color(0xFFEFF6FF);
                  Color tagFg = const Color(0xFF1D4ED8);

                  if (val <= 7.25) {
                    color = const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF10B981)]);
                    tag = 'Best';
                    tagBg = const Color(0xFFECFDF5);
                    tagFg = const Color(0xFF065F46);
                  } else if (val <= 7.60) {
                    color = const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFE05A00)]);
                    tag = 'Good';
                    tagBg = const Color(0xFFFFF3E0);
                    tagFg = const Color(0xFFE05A00);
                  } else if (val >= 8.20) {
                    color = const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]);
                    tag = 'High';
                    tagBg = const Color(0xFFFEF2F2);
                    tagFg = const Color(0xFFB91C1C);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 84,
                          child: Text(b['shortName'], style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        ),
                        Expanded(
                          child: Container(
                            height: 22,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: LayoutBuilder(builder: (ctx, constraints) {
                              return Container(
                                width: constraints.maxWidth * pct,
                                height: double.infinity,
                                padding: const EdgeInsets.only(right: 7),
                                alignment: Alignment.centerRight,
                                decoration: BoxDecoration(
                                  gradient: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${val.toStringAsFixed(2)}%',
                                    style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w800)),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 42,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(tag, style: AppTextStyles.dmSans(size: 8, color: tagFg, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Full Comparison Table Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Full Rate Table', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
            GestureDetector(
              onTap: _saveComparisonReport,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('💾 Save Snapshot', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          key: _comparisonTableKey,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Major Banks — Jun 2026', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 12),

              // Table header
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: const Color(0xFFFF6B00).withValues(alpha: 0.12), width: 1.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 16,
                        child: Text('BANK', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context), letterSpacing: 0.4))),
                    Expanded(
                        flex: 10,
                        child: Text('RATE', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context), letterSpacing: 0.4), textAlign: TextAlign.right)),
                    Expanded(
                        flex: 10,
                        child: Text('MAX LTV', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context), letterSpacing: 0.4), textAlign: TextAlign.right)),
                    Expanded(
                        flex: 10,
                        child: Text('FEE', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context), letterSpacing: 0.4), textAlign: TextAlign.right)),
                  ],
                ),
              ),

              // Table rows
              Column(
                children: activeLenders.map((b) {
                  final double val = b['adjRate'];
                  final isBest = val <= 7.15;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.07))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 16,
                          child: Row(
                            children: [
                              Text(b['icon'], style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(b['name'].toString().split(' ').first,
                                            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                                        if (isBest) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('★ Best', style: TextStyle(fontSize: 7, color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(b['typeLabel'], style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            '${val.toStringAsFixed(2)}%',
                            style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w800,
                              color: isBest ? const Color(0xFF046A38) : (val >= 8.20 ? const Color(0xFFDC2626) : theme.getTextColor(context)),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            b['ltv'],
                            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            b['fee'],
                            style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // EMI Comparison Ranked List Card
        Text('EMI Comparison', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly EMI — ₹${(_loanAmount / 100000).toStringAsFixed(0)}L for ${_tenureYears.toInt()} Years', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('Based on current floating rates · Jun 2026', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 12),

              Column(
                children: activeLenders.toList().take(5).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final b = entry.value;
                  final double rate = b['adjRate'];
                  final emi = _calcEMI(_loanAmount, rate, _tenureYears);
                  final isFirst = idx == 0;

                  Color rankBg = const Color(0xFF0B1F48).withValues(alpha: 0.08);
                  Color rankFg = theme.getTextColor(context);
                  if (idx == 0) {
                    rankBg = const Color(0xFF046A38);
                    rankFg = Colors.white;
                  } else if (idx == 1) {
                    rankBg = const Color(0xFFFF6B00);
                    rankFg = Colors.white;
                  } else if (idx == 2) {
                    rankBg = const Color(0xFF1A3A8F);
                    rankFg = Colors.white;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.07))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
                          child: Text('${idx + 1}', style: AppTextStyles.dmSans(size: 10, color: rankFg, weight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['name'], style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                              Text('${rate.toStringAsFixed(2)}% Floating', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_fmtK(emi), style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                            Text(
                              isFirst ? 'Best deal' : '+${_fmtK(emi - emiBest)}/mo',
                              style: AppTextStyles.dmSans(
                                size: 8.5,
                                weight: FontWeight.w700,
                                color: isFirst ? const Color(0xFF046A38) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              // Tip interest savings banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                  border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Over ${_tenureYears.toInt()} yrs: Choose ${bestLender != null ? bestLender['shortName'] : 'BoM'} over ${worstLender != null ? worstLender['shortName'] : 'HDFC'} ➔ Save ${_fmt(totalTenureSaving)}',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                    const SizedBox(height: 2),
                    Text('Total interest difference across full tenure', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interest vs Principal Split Donut Card
        Text('Interest vs Principal Split', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
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
              Text('₹${(_loanAmount / 100000).toStringAsFixed(0)}L Loan · ${bestRate.toStringAsFixed(2)}% · ${_tenureYears.toInt()} Years (SBI/BoM)', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('Total repayment breakdown', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _SimpleDonutPainter(
                        principalRatio: principalShare,
                        cPrincipal: const Color(0xFF046A38),
                        cInterest: const Color(0xFFFF6B00),
                        centerText: _fmtK(totalRepayment),
                        textColor: theme.getTextColor(context),
                        mutedColor: theme.getMutedColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _donutLegendRow(const Color(0xFF046A38), 'Principal', '${_fmt(_loanAmount)} (${(principalShare * 100).toStringAsFixed(0)}%)', context),
                        const SizedBox(height: 8),
                        _donutLegendRow(const Color(0xFFFF6B00), 'Total Interest', '${_fmt(totalRepayment - _loanAmount)} (${((1 - principalShare) * 100).toStringAsFixed(0)}%)', context),
                        const SizedBox(height: 8),
                        _donutLegendRow(const Color(0xFF1A3A8F), 'Monthly EMI', '${_fmtK(emiBest)}/month', context),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // NRI Rates Panel
        Text('NRI Home Loan Rates', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NRI / PIO / OCI — Jun 2026', style: AppTextStyles.dmSans(size: 12.5, color: Colors.white, weight: FontWeight.w800)),
              Text('Rates slightly higher; CIBIL/overseas income assessed · RLLR-linked', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.55))),
              const SizedBox(height: 12),
              Column(
                children: _nriRates.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['bank'], style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
                        Text('${(item['rate'] as double).toStringAsFixed(2)}%',
                            style: AppTextStyles.dmSans(size: 12, color: const Color(0xFFFFDEA0), weight: FontWeight.w800)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
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

  Widget _buildSyncedInputRow({
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
    String prefix = '',
    String suffix = '',
    required ValueChanged<double> onChangedText,
    required ValueChanged<double> onChangedSlider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w800)),
            Text('$prefix${value.toInt()}$suffix',
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFFFFDEA0))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 12.5, color: Colors.white, weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed >= min && parsed <= max) {
                onChangedText(parsed);
              }
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF6B00),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.24),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChangedSlider,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _activeFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : Colors.white.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _donutLegendRow(Color color, String label, String value, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
              Text(value, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleDonutPainter extends CustomPainter {
  final double principalRatio;
  final Color cPrincipal;
  final Color cInterest;
  final String centerText;
  final Color textColor;
  final Color mutedColor;

  _SimpleDonutPainter({
    required this.principalRatio,
    required this.cPrincipal,
    required this.cInterest,
    required this.centerText,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..color = cInterest.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = strokeW);

    // segments
    final sweep1 = principalRatio * 2 * pi;
    final sweep2 = (1 - principalRatio) * 2 * pi;

    canvas.drawArc(rect, -pi / 2, sweep1, false, Paint()..color = cPrincipal..style = PaintingStyle.stroke..strokeWidth = strokeW);
    canvas.drawArc(rect, -pi / 2 + sweep1, sweep2, false, Paint()..color = cInterest..style = PaintingStyle.stroke..strokeWidth = strokeW);

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(fontFamily: 'Book Antiqua', fontSize: 11.5, fontWeight: FontWeight.w800, color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2 + 5));

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'Total Pay',
        style: TextStyle(fontFamily: 'Trebuchet MS', fontSize: 8, color: mutedColor, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas, center - Offset(subPainter.width / 2, subPainter.height / 2 - 9));
  }

  @override
  bool shouldRepaint(covariant _SimpleDonutPainter oldDelegate) {
    return oldDelegate.principalRatio != principalRatio || oldDelegate.textColor != textColor;
  }
}
