// lib/features/india/tools/in_first_home_buyer.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INFirstHomeBuyer extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INFirstHomeBuyer({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INFirstHomeBuyer> createState() => _INFirstHomeBuyerState();
}

class _INFirstHomeBuyerState extends ConsumerState<INFirstHomeBuyer> {
  // State variables for inputs
  double _income = 1200000;
  double _propVal = 4500000;
  double _loanAmt = 3500000;
  double _intPaid = 280000;
  String _regime = 'old';

  // Text controllers
  late TextEditingController _incomeCtrl;
  late TextEditingController _propValCtrl;
  late TextEditingController _loanAmtCtrl;
  late TextEditingController _intPaidCtrl;

  // Scroll controller to scroll to results
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  // Checklist state
  final List<Map<String, dynamic>> _checklistItems = [
    {'title': 'PAN Card', 'sub': 'Mandatory for loan & registration above ₹50L', 'checked': false},
    {'title': 'Aadhaar Card', 'sub': 'KYC & PMAY application', 'checked': false},
    {'title': 'Last 3 Months Salary Slips', 'sub': 'Income proof for loan eligibility', 'checked': false},
    {'title': 'ITR for Last 2 Years', 'sub': 'Income Tax Returns – Form 16 or ITR-1/2', 'checked': false},
    {'title': 'Bank Statements (6 Months)', 'sub': 'Savings / current account statements', 'checked': false},
    {'title': 'Sale Agreement / Allotment Letter', 'sub': 'Property purchase documents from builder/seller', 'checked': false},
    {'title': 'RERA Registration Certificate', 'sub': 'Verify builder at rera.gov.in / state RERA site', 'checked': false},
    {'title': 'Self-Declaration (First-Time Buyer)', 'sub': 'For 80EE/80EEA – no other residential property owned', 'checked': false},
  ];

  @override
  void initState() {
    super.initState();
    _incomeCtrl = TextEditingController(text: _income.toStringAsFixed(0));
    _propValCtrl = TextEditingController(text: _propVal.toStringAsFixed(0));
    _loanAmtCtrl = TextEditingController(text: _loanAmt.toStringAsFixed(0));
    _intPaidCtrl = TextEditingController(text: _intPaid.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _propValCtrl.dispose();
    _loanAmtCtrl.dispose();
    _intPaidCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _income = 1200000;
      _propVal = 4500000;
      _loanAmt = 3500000;
      _intPaid = 280000;
      _incomeCtrl.text = '1200000';
      _propValCtrl.text = '4500000';
      _loanAmtCtrl.text = '3500000';
      _intPaidCtrl.text = '280000';
      _regime = 'old';
      for (var item in _checklistItems) {
        item['checked'] = false;
      }
    });
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    // Perform calculation
    double d80c = 0;
    double d24b = 0;
    double d80eeApplied = 0;
    double totalDedn = 0;
    double taxSaved = 0;

    if (_regime == 'old') {
      d80c = min(150000.0, _loanAmt * 0.10);
      d24b = min(200000.0, _intPaid);
      if (_propVal <= 4500000) {
        final remainingInterest = max(0.0, _intPaid - 200000.0);
        d80eeApplied = min(150000.0, remainingInterest);
      } else if (_propVal <= 5000000 && _loanAmt <= 3500000) {
        final remainingInterest = max(0.0, _intPaid - 200000.0);
        d80eeApplied = min(50000.0, remainingInterest);
      }
      totalDedn = d80c + d24b + d80eeApplied;
      final rate = _income > 1500000 ? 0.30 : _income > 1000000 ? 0.20 : 0.10;
      taxSaved = Compat.round(totalDedn * rate).toDouble();
    }

    final labelCtrl = TextEditingController(text: 'First-Home Benefits');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save First-Home Report', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Deductions ${_fmt(totalDedn)} · Tax Saved ${_fmt(taxSaved)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My First Flat Plan)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'First-Home Benefits';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'First-Home Buyer',
        inputs: {
          'income': _income,
          'propVal': _propVal,
          'loanAmt': _loanAmt,
          'intPaid': _intPaid,
          'regime': _regime == 'old' ? 1.0 : 0.0,
        },
        results: {
          'd80c': d80c,
          'd24b': d24b,
          'd80ee': d80eeApplied,
          'totalDeduction': totalDedn,
          'taxSaved': taxSaved,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Report saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reactively clamp loan amount to property value
    if (_loanAmt > _propVal) {
      _loanAmt = _propVal;
      _loanAmtCtrl.text = _loanAmt.toStringAsFixed(0);
    }

    // Calculations
    double d80c = 0;
    double d24b = 0;
    double d80eeApplied = 0;
    double totalDedn = 0;
    double taxSaved = 0;
    double taxRatePercent = 0.0;

    if (_regime == 'old') {
      d80c = min(150000.0, _loanAmt * 0.10);
      d24b = min(200000.0, _intPaid);
      if (_propVal <= 4500000) {
        final remainingInterest = max(0.0, _intPaid - 200000.0);
        d80eeApplied = min(150000.0, remainingInterest);
      } else if (_propVal <= 5000000 && _loanAmt <= 3500000) {
        final remainingInterest = max(0.0, _intPaid - 200000.0);
        d80eeApplied = min(50000.0, remainingInterest);
      }
      totalDedn = d80c + d24b + d80eeApplied;
      final rate = _income > 1500000 ? 0.30 : _income > 1000000 ? 0.20 : 0.10;
      taxRatePercent = rate * 100;
      taxSaved = Compat.round(totalDedn * rate).toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF046A38), Color(0xFF07543A)],
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
                  Text('FIRST-HOME BUYER BENEFIT CALCULATOR',
                      style: AppTextStyles.dmSans(
                          size: 9, color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w800, letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFFDEA0), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Maximise your tax savings as a first-time buyer',
                style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              // Synced Slider 1: Annual Income
              _buildSyncedInputRow(
                label: 'ANNUAL INCOME',
                controller: _incomeCtrl,
                value: _income,
                min: 100000,
                max: 10000000,
                onChangedText: (val) {
                  setState(() {
                    _income = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _income = val;
                    _incomeCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced Slider 2: Property Value
              _buildSyncedInputRow(
                label: 'PROPERTY VALUE',
                controller: _propValCtrl,
                value: _propVal,
                min: 500000,
                max: 20000000,
                onChangedText: (val) {
                  setState(() {
                    _propVal = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _propVal = val;
                    _propValCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced Slider 3: Loan Amount (Capped dynamically at _propVal)
              _buildSyncedInputRow(
                label: 'LOAN AMOUNT (₹)',
                controller: _loanAmtCtrl,
                value: _loanAmt,
                min: 0,
                max: _propVal,
                onChangedText: (val) {
                  setState(() {
                    _loanAmt = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _loanAmt = val;
                    _loanAmtCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced Slider 4: Annual Interest Paid
              _buildSyncedInputRow(
                label: 'ANNUAL INTEREST PAID',
                controller: _intPaidCtrl,
                value: _intPaid,
                min: 0,
                max: 1500000,
                onChangedText: (val) {
                  setState(() {
                    _intPaid = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _intPaid = val;
                    _intPaidCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 14),

              // Tax Regime Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TAX REGIME', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _regime,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF046A38),
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                        iconEnabledColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'old', child: Text('Old Regime (Deductions Allowed)')),
                          DropdownMenuItem(value: 'new', child: Text('New Regime (No Deductions)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _regime = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _scrollToResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE05F00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text('🏠 Calculate My First-Home Benefits', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PMAY Banner - Clickable, navigates to PMAY Subsidy
        GestureDetector(
          onTap: () => context.push('/tool/india/in_pmay'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF6EE7B7)),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏡', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PMAY-U 2.0 – Pradhan Mantri Awas Yojana',
                          style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF07543A))),
                      const SizedBox(height: 2),
                      Text(
                        'Interest subsidy up to ₹2.67 Lakh · EWS/LIG/MIG-I/MIG-II · Annual income ≤₹18L',
                        style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF046A38), height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF046A38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Check', style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.w800)),
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Results Card (Always visible with real-time updates)
        Container(
          key: _resultsKey,
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
              Text('YOUR FIRST-HOME TAX BENEFIT SUMMARY',
                  style: AppTextStyles.dmSans(
                      size: 9, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _resBox('Section 80C (Principal)', _fmt(d80c), 'Max ₹1.5L p.a.'),
                  const SizedBox(width: 8),
                  _resBox('Section 24(b) (Interest)', _fmt(d24b), 'Max ₹2L p.a.'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _resBox('Section 80EE / 80EEA', _fmt(d80eeApplied), 'First-time only'),
                  const SizedBox(width: 8),
                  _resBox('Total Deduction', _fmt(totalDedn), 'This FY'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text('Total Tax Saved This Year', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(taxSaved),
                      style: AppTextStyles.playfair(size: 28, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _regime == 'old'
                          ? 'At ${taxRatePercent.round()}% effective rate (Old Regime)'
                          : 'New Regime: No deductions on home loan',
                      style: AppTextStyles.dmSans(size: 9, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Donut chart card (Only for Old Regime when deductions apply)
        if (_regime == 'old' && totalDedn > 0) ...[
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
                Text('📊 Benefit Breakdown',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          v1: d80c,
                          v2: d24b,
                          v3: d80eeApplied,
                          c1: const Color(0xFF046A38),
                          c2: const Color(0xFFFF6B00),
                          c3: const Color(0xFF1A3A8F),
                          centerLabel: _fmtCenter(totalDedn),
                          textColor: theme.getTextColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _donutLegendRow(const Color(0xFF046A38), 'Sec 80C: ${_fmt(d80c)}', 'Principal repayment'),
                          const SizedBox(height: 8),
                          _donutLegendRow(const Color(0xFFFF6B00), 'Sec 24(b): ${_fmt(d24b)}', 'Interest deduction'),
                          const SizedBox(height: 8),
                          _donutLegendRow(const Color(0xFF1A3A8F), '80EE/A: ${_fmt(d80eeApplied)}', 'First-home bonus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Benefit details list
        Text('All First-Home Buyer Benefits', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: [
            _benefitCard(
                '📜',
                'Section 80C – Principal Repayment',
                'Deduction of up to ₹1.5 Lakh per year on home loan principal. Applicable under Old Tax Regime. Includes stamp duty & registration in year of purchase.',
                '₹1.5L/yr',
                _regime == 'old',
                context),
            _benefitCard(
                '📝',
                'Section 24(b) – Interest on Home Loan',
                'Up to ₹2 Lakh/year on interest paid for self-occupied property. For let-out property, no upper limit. Old Regime only. 5-year construction wait applies.',
                '₹2L/yr',
                _regime == 'old',
                context),
            _benefitCard(
                '🎁',
                'Section 80EEA – Affordable Housing Bonus',
                'Additional ₹1.5L deduction for first-time buyers. Property stamp value ≤₹45L. Loan sanctioned between Apr 2019 – Mar 2022. Loan outstanding during FY.',
                '₹1.5L/yr',
                _regime == 'old' && _propVal <= 4500000,
                context),
            _benefitCard(
                '🏠',
                'Section 80EE – Additional Interest Deduction',
                '₹50,000 extra for loans sanctioned Apr 2016 – Mar 2017. Loan value ≤₹35L. Property value ≤₹50L. Cannot claim with 80EEA. First-time buyer only.',
                '₹50K/yr',
                _regime == 'old' && _propVal <= 5000000 && _loanAmt <= 3500000 && _propVal > 4500000,
                context),
            _benefitCard(
                '🏡',
                'PMAY – Credit Linked Subsidy Scheme',
                'EWS/LIG: ₹2.67L subsidy. MIG-I (₹6–12L income): ₹2.35L. MIG-II (₹12–18L income): ₹2.30L. One-time benefit credited to loan account at disbursement.',
                '₹2.67L',
                _income <= 1800000,
                context),
            _benefitCard(
                '🏦',
                'Special Women Borrower Concession',
                'If property is in woman\'s name (sole or co-owner), banks offer 0.05% rate concession. State stamp duty is often 1-2% lower for women co-owners.',
                '0.05% off',
                false,
                context),
          ],
        ),

        const SizedBox(height: 20),

        // Document checklist
        Text('First-Home Buyer Document Checklist', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: List.generate(_checklistItems.length, (idx) {
            final item = _checklistItems[idx];
            final checked = item['checked'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: checked ? const Color(0xFF6EE7B7) : theme.getBorderColor(context)),
              ),
              child: ListTile(
                dense: true,
                onTap: () {
                  setState(() {
                    _checklistItems[idx]['checked'] = !checked;
                  });
                },
                leading: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked ? const Color(0xFF046A38) : const Color(0xFFFF6B00).withValues(alpha: 0.04),
                    border: Border.all(color: checked ? const Color(0xFF046A38) : theme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: checked ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
                ),
                title: Text(
                  item['title'] as String,
                  style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.w700,
                    color: checked ? const Color(0xFF046A38) : theme.getTextColor(context),
                  ).copyWith(
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  item['sub'] as String,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: theme.getMutedColor(context),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Save Calculation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save This Calculation',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
                    Text('Keep a record of your benefits report',
                        style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save', style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncedInputRow({
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
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
            Text(_fmt(value), style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFFDEA0), weight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
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
            inactiveTrackColor: Colors.white.withValues(alpha: 0.24),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.24),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
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

  Widget _resBox(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
            const SizedBox(height: 3),
            Text(value, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white)),
            Text(sub, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _benefitCard(String icon, String title, String desc, String maxLabel, bool isActive, BuildContext context) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF042F1A) : const Color(0xFFECFDF5))
            : theme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isActive ? const Color(0xFF6EE7B7) : theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF046A38).withValues(alpha: 0.12) : const Color(0xFFFF6B00).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        maxLabel,
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: isActive ? const Color(0xFF047857) : const Color(0xFF065F46)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCenter(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(v);
  }

  Widget _donutLegendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
              Text(value, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double v1;
  final double v2;
  final double v3;
  final Color c1;
  final Color c2;
  final Color c3;
  final String centerLabel;
  final Color textColor;

  _DonutChartPainter({
    required this.v1,
    required this.v2,
    required this.v3,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.centerLabel,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeW = 14.0;

    final total = v1 + v2 + v3;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      return;
    }

    final p1 = v1 / total;
    final p2 = v2 / total;
    final p3 = v3 / total;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // Start from top

    // Section 1
    if (p1 > 0) {
      final sweep1 = p1 * 2 * pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweep1,
        false,
        Paint()
          ..color = c1
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      startAngle += sweep1;
    }

    // Section 2
    if (p2 > 0) {
      final sweep2 = p2 * 2 * pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweep2,
        false,
        Paint()
          ..color = c2
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      startAngle += sweep2;
    }

    // Section 3
    if (p3 > 0) {
      final sweep3 = p3 * 2 * pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweep3,
        false,
        Paint()
          ..color = c3
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
    }

    // Draw center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
          fontFamily: 'Book Antiqua',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 + 5),
    );

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'Total',
        style: TextStyle(
          fontFamily: 'Trebuchet MS',
          fontSize: 8,
          color: Colors.grey,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
      canvas,
      center - Offset(subPainter.width / 2, subPainter.height / 2 - 10),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.v1 != v1 || oldDelegate.v2 != v2 || oldDelegate.v3 != v3 || oldDelegate.textColor != textColor;
  }
}
