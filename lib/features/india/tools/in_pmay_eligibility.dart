// lib/features/india/tools/in_pmay_eligibility.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INPMAYEligibility extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INPMAYEligibility({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INPMAYEligibility> createState() => _INPMAYEligibilityState();
}

class _INPMAYEligibilityState extends ConsumerState<INPMAYEligibility> {
  // Input states
  String _selectedCat = 'ews'; // default EWS
  double _income = 250000; // default ₹2.5L
  double _loanAmt = 1500000; // default ₹15L
  String _selectedState = 'Maharashtra';
  String _gender = 'male'; // male, female, joint

  // Eligibility Checklist
  bool _noHouse = true;
  bool _noPMAY = true;
  bool _aadhaar = true;
  bool _firstHome = true;

  // Controllers
  late TextEditingController _incomeCtrl;
  late TextEditingController _loanAmtCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultPanelKey = GlobalKey();

  bool _calculated = false;

  final Map<String, _PmayCatData> _catData = {
    'ews': _PmayCatData(
      name: 'EWS',
      icon: '🏠',
      desc: 'Annual Income ≤ ₹3 Lakh',
      subsidy: 267280,
      clss: 6.5,
      maxLoan: 600000,
      maxArea: 30,
      incomeMax: 300000,
      themeColor: const Color(0xFF046A38),
    ),
    'lig': _PmayCatData(
      name: 'LIG',
      icon: '🏘️',
      desc: 'Annual Income ₹3L – ₹6L',
      subsidy: 267280,
      clss: 6.5,
      maxLoan: 600000,
      maxArea: 60,
      incomeMax: 600000,
      themeColor: const Color(0xFF1D4ED8),
    ),
    'mig1': _PmayCatData(
      name: 'MIG-I',
      icon: '🏗️',
      desc: 'Annual Income ₹6L – ₹12L',
      subsidy: 235068,
      clss: 4.0,
      maxLoan: 900000,
      maxArea: 160,
      incomeMax: 1200000,
      themeColor: const Color(0xFFFF6B00),
    ),
    'mig2': _PmayCatData(
      name: 'MIG-II',
      icon: '🏢',
      desc: 'Annual Income ₹12L – ₹18L',
      subsidy: 230156,
      clss: 3.0,
      maxLoan: 1200000,
      maxArea: 200,
      incomeMax: 1800000,
      themeColor: const Color(0xFF7C3AED),
    ),
  };

  static final List<String> _indianStates = [
    'Andhra Pradesh', 'Assam', 'Bihar', 'Delhi', 'Gujarat', 'Haryana',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Punjab',
    'Rajasthan', 'Tamil Nadu', 'Telangana', 'Uttar Pradesh', 'West Bengal', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _incomeCtrl = TextEditingController(text: _income.toStringAsFixed(0));
    _loanAmtCtrl = TextEditingController(text: _loanAmt.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _loanAmtCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveEligibilityReport() async {
    final d = _catData[_selectedCat]!;
    final List<String> issues = _checkIssues(d);
    final bool eligible = issues.isEmpty;
    final double subsidyAmt = eligible ? d.subsidy : 0.0;
    final double effectiveLoan = eligible ? ((_loanAmt - subsidyAmt) > 0 ? _loanAmt - subsidyAmt : 0.0) : _loanAmt;

    final labelCtrl = TextEditingController(text: 'PMAY Eligibility Report - ${d.name}');

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_pmay_eligibility'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Eligibility Report', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving PMAY Report: Status: ${eligible ? "Eligible" : "Ineligible"}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My PMAY Eligibility)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'PMAY Report';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'PMAY Eligibility',
        inputs: {
          'householdIncome': _income,
          'loanNeeded': _loanAmt,
          'categoryIndex': ['ews', 'lig', 'mig1', 'mig2'].indexOf(_selectedCat).toDouble(),
          'genderIndex': _gender == 'male' ? 0.0 : (_gender == 'female' ? 1.0 : 2.0),
          'ownsPuccaHouse': _noHouse ? 0.0 : 1.0,
          'hasPriorBenefits': _noPMAY ? 0.0 : 1.0,
          'aadhaarLinked': _aadhaar ? 1.0 : 0.0,
          'firstHomeBuyer': _firstHome ? 1.0 : 0.0,
        },
        results: {
          'isEligible': eligible ? 1.0 : 0.0,
          'subsidyAmount': subsidyAmt,
          'effectiveLoan': effectiveLoan,
          'clssRate': d.clss,
          'maxCarpetArea': d.maxArea,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eligibility report saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<String> _checkIssues(_PmayCatData d) {
    final List<String> issues = [];
    if (_income <= 0) issues.add('Enter your annual household income');
    if (_loanAmt <= 0) issues.add('Enter your loan amount');
    if (!_noHouse) issues.add('You must confirm no pucca house ownership');
    if (!_noPMAY) issues.add('You must confirm no prior central housing benefits');
    if (!_aadhaar) issues.add('Aadhaar bank link is mandatory');
    if (_income > 0 && _income > d.incomeMax) {
      issues.add('Income of ${_fmt(_income)} exceeds ${d.name} limit of ${_fmt(d.incomeMax)}');
    }
    return issues;
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _calculateEligibility() {
    setState(() {
      _calculated = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultPanelKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final d = _catData[_selectedCat]!;
    final List<String> issues = _checkIssues(d);
    final bool eligible = issues.isEmpty;
    final double subsidyAmt = eligible ? d.subsidy : 0.0;
    final double effectiveLoan = eligible ? ((_loanAmt - subsidyAmt) > 0 ? _loanAmt - subsidyAmt : 0.0) : _loanAmt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF046A38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('Max Subsidy', '₹2.67L', 'EWS/LIG', isSaffron: true),
              _infoCell('CLSS Rate', '6.50%', 'EWS subsidy', isSaffron: true),
              _infoCell('Max Loan', '₹6L', 'EWS eligible'),
              _infoCell('Scheme', 'Active', 'Urban 2.0'),
            ],
          ),
        ),

        // Title Section
        Text('Select Your Income Category', style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        // 2x2 Category Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.15,
          children: _catData.entries.map((e) {
            final isSelected = _selectedCat == e.key;
            final cat = e.value;
            final cardColor = isSelected 
                ? cat.themeColor.withValues(alpha: 0.12)
                : theme.getCardColor(context);
            final borderColor = isSelected 
                ? cat.themeColor 
                : theme.getBorderColor(context);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCat = e.key;
                  _income = cat.incomeMax * 0.75;
                  _incomeCtrl.text = _income.toStringAsFixed(0);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: borderColor, width: isSelected ? 2.2 : 1.0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 5),
                        Text(cat.name, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        const SizedBox(height: 2),
                        Text(cat.desc, style: AppTextStyles.dmSans(size: 7.5, color: theme.getMutedColor(context)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Subsidy: ${_fmtShort(cat.subsidy)}', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: cat.themeColor)),
                      ],
                    ),
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(color: cat.themeColor, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Eligibility Form
        Text('Enter Your Details', style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: Color(0xFF046A38)),
                  const SizedBox(width: 8),
                  Text('📋 Eligibility Details', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                ],
              ),
              const SizedBox(height: 16),

              // Annual Household Income
              _buildSyncedInputRow(
                label: 'ANNUAL HOUSEHOLD INCOME (₹)',
                controller: _incomeCtrl,
                value: _income,
                min: 50000,
                max: 3000000, // up to 30 Lakhs
                prefix: '₹ ',
                onChangedText: (v) {
                  setState(() {
                    _income = v;
                  });
                },
                onChangedSlider: (v) {
                  setState(() {
                    _income = v;
                    _incomeCtrl.text = v.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Loan Amount Needed
              _buildSyncedInputRow(
                label: 'LOAN AMOUNT NEEDED (₹)',
                controller: _loanAmtCtrl,
                value: _loanAmt,
                min: 100000,
                max: 15000000, // up to 1.5 Cr
                prefix: '₹ ',
                onChangedText: (v) {
                  setState(() {
                    _loanAmt = v;
                  });
                },
                onChangedSlider: (v) {
                  setState(() {
                    _loanAmt = v;
                    _loanAmtCtrl.text = v.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // State & Gender rows
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STATE', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            border: Border.all(color: theme.getBorderColor(context)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedState,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w700, color: theme.getTextColor(context)),
                              items: _indianStates.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedState = v;
                                  });
                                }
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
                        Text('APPLICANT GENDER', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            border: Border.all(color: theme.getBorderColor(context)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w700, color: theme.getTextColor(context)),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'joint', child: Text('Joint (Male+Female)')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _gender = v;
                                  });
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

              // Checklist Cards
              Text('CONFIRM ELIGIBILITY CRITERIA', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),

              _buildChecklistCard('No pucca house in India', 'Applicant/family must not own a brick-and-mortar house anywhere in India', _noHouse, (v) => setState(() => _noHouse = v)),
              _buildChecklistCard('No prior PMAY benefit', 'Should not have availed any central/state housing scheme subsidy previously', _noPMAY, (v) => setState(() => _noPMAY = v)),
              _buildChecklistCard('Aadhaar linked to bank account', 'Mandatory condition for subsidy direct credit via NHB / HUDCO', _aadhaar, (v) => setState(() => _aadhaar = v)),
              _buildChecklistCard('First-time home buyer', 'For MIG categories, first-time registration rules apply', _firstHome, (v) => setState(() => _firstHome = v)),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _calculateEligibility,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('🏡 Check PMAY Eligibility', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Result Status Panel
        if (_calculated)
          Container(
            key: _resultPanelKey,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: eligible
                  ? const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    eligible ? '✅ Eligible' : '⚠️ Not Eligible',
                    style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  eligible ? 'You qualify for PMAY ${d.name}!' : 'Eligibility Issues Found',
                  style: AppTextStyles.playfair(size: 20, color: Colors.white, weight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  eligible
                      ? 'CLSS @ ${d.clss}% interest subsidy up to ${d.maxArea} sqm carpet area. Subsidy credited directly.'
                      : issues.join(' · '),
                  style: AppTextStyles.dmSans(size: 10.5, color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 16),

                if (eligible) ...[
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 1.6,
                    children: [
                      _resultStatBox('Your Subsidy', _fmt(d.subsidy), 'NPV subsidy'),
                      _resultStatBox('Effective Loan', _fmt(effectiveLoan), 'After subsidy credit'),
                      _resultStatBox('CLSS Rate', '${d.clss}%', 'Interest subsidy'),
                      _resultStatBox('Max Carpet Area', '${d.maxArea} sqm', '${d.name} limit'),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _saveEligibilityReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white, size: 16),
                    label: Text('Save Eligibility Report', style: AppTextStyles.dmSans(size: 11.5, color: Colors.white, weight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Subsidy Limit Slabs Bar Chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 PMAY Subsidy by Category — 2025', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 14),
              _subsidyBar('EWS (≤₹3L/yr)', 267280, 267280, '6.5% CLSS on ₹6L loan over 20 yrs'),
              _subsidyBar('LIG (₹3L–₹6L/yr)', 267280, 267280, '6.5% CLSS on ₹6L loan over 20 yrs'),
              _subsidyBar('MIG-I (₹6L–₹12L/yr)', 235068, 267280, '4.0% CLSS on ₹9L loan over 20 yrs', gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF10B981)])),
              _subsidyBar('MIG-II (₹12L–₹18L/yr)', 230156, 267280, '3.0% CLSS on ₹12L loan over 20 yrs', gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)])),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stepper Application steps
        Text('How to Apply — PMAY Urban 2.0', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _applyStep('1', 'Check Eligibility', 'Visit pmaymis.gov.in · Enter Aadhaar number · Verify beneficiary records'),
              _applyStep('2', 'Apply Through Bank or ULB', 'Apply via Primary Lending Institution (PLI listing) or local Urban Local Body (ULB) office'),
              _applyStep('3', 'Submit Documents', 'Aadhaar, income proof certificate, property registry papers, bank accounts'),
              _applyStep('4', 'Subsidy Credited to Loan', 'HUDCO/NHB audits status and credits CLSS NPV directly to outstanding principal loan account'),
              _applyStep('5', 'Track Application Status', 'Monitor milestones on PMAY portal using Aadhaar registry and tracking indices'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
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

  Widget _buildChecklistCard(String title, String desc, bool isChecked, ValueChanged<bool> onChanged) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.getBgColor(context),
          border: Border.all(color: theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              activeColor: const Color(0xFF046A38),
              onChanged: (v) => onChanged(v ?? false),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                  const SizedBox(height: 1),
                  Text(desc, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.dmSans(size: 8, color: theme.getTextColor(context), weight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Text('$prefix${_fmtShort(value)}$suffix',
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF046A38))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.w800),
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
            activeTrackColor: const Color(0xFF046A38),
            inactiveTrackColor: theme.getBorderColor(context),
            thumbColor: const Color(0xFF046A38),
            overlayColor: const Color(0xFF046A38).withValues(alpha: 0.24),
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

  Widget _resultStatBox(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _subsidyBar(String label, double val, double maxVal, String note, {Gradient? gradient}) {
    final double pct = maxVal > 0 ? val / maxVal : 0.0;
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text(_fmt(val), style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: const Color(0xFF046A38))),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: theme.getBorderColor(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient ?? const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(note, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _applyStep(String num, String title, String desc) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(num, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PmayCatData {
  final String name;
  final String icon;
  final String desc;
  final double subsidy;
  final double clss;
  final double maxLoan;
  final double maxArea;
  final double incomeMax;
  final Color themeColor;

  _PmayCatData({
    required this.name,
    required this.icon,
    required this.desc,
    required this.subsidy,
    required this.clss,
    required this.maxLoan,
    required this.maxArea,
    required this.incomeMax,
    required this.themeColor,
  });
}
