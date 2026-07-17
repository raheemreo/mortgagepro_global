// lib/features/india/tools/in_pmay_housing_for_all.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INPMAYHousingForAll extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INPMAYHousingForAll({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INPMAYHousingForAll> createState() => _INPMAYHousingForAllState();
}

class _INPMAYHousingForAllState extends ConsumerState<INPMAYHousingForAll> {
  String _selCat = 'ews';
  double _loanAmountLakhs = 20; // In lakhs
  int _tenureYears = 20;
  double _bankRate = 8.50;

  bool _calculated = false;
  String _calcSelCat = 'ews';
  double _calcLoanAmountLakhs = 20;
  int _calcTenureYears = 20;
  double _calcBankRate = 8.50;

  bool _loanHasError = false;
  bool _rateHasError = false;

  final GlobalKey _resultsKey = GlobalKey();

  final Map<String, _PmayCatData> _catData = {
    'ews': _PmayCatData(name: 'EWS', subRate: 6.5, maxLoan: 600000, subsidy: 267000, incomeLimit: '≤ ₹3 Lakh/yr'),
    'lig': _PmayCatData(name: 'LIG', subRate: 6.5, maxLoan: 600000, subsidy: 267000, incomeLimit: '₹3L – ₹6L/yr'),
    'mig1': _PmayCatData(name: 'MIG-I', subRate: 4.0, maxLoan: 900000, subsidy: 235000, incomeLimit: '₹6L – ₹12L/yr'),
    'mig2': _PmayCatData(name: 'MIG-II', subRate: 3.0, maxLoan: 1200000, subsidy: 230000, incomeLimit: '₹12L – ₹18L/yr'),
  };

  double _emi(double p, double r, int nMonths) {
    if (r <= 0) return p / nMonths;
    final mr = r / 12 / 100;
    return p * mr * pow(1 + mr, nMonths) / (pow(1 + mr, nMonths) - 1);
  }

  void _calculate() {
    setState(() {
      _loanHasError = _loanAmountLakhs <= 0;
      _rateHasError = _bankRate <= 0 || _bankRate > 30;
    });

    if (_loanHasError || _rateHasError) return;

    setState(() {
      _calculated = true;
      _calcSelCat = _selCat;
      _calcLoanAmountLakhs = _loanAmountLakhs;
      _calcTenureYears = _tenureYears;
      _calcBankRate = _bankRate;
    });

    _scrollToResults();
  }

  bool _areInputsChanged() {
    return _selCat != _calcSelCat ||
        _loanAmountLakhs != _calcLoanAmountLakhs ||
        _tenureYears != _calcTenureYears ||
        _bankRate != _calcBankRate;
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  void _reset() {
    setState(() {
      _selCat = 'ews';
      _loanAmountLakhs = 20;
      _tenureYears = 20;
      _bankRate = 8.50;

      _calculated = false;
      _calcSelCat = 'ews';
      _calcLoanAmountLakhs = 20;
      _calcTenureYears = 20;
      _calcBankRate = 8.50;

      _loanHasError = false;
      _rateHasError = false;
    });
  }

  void _saveCalculation() async {
    final d = _catData[_calcSelCat]!;
    final loan = _calcLoanAmountLakhs * 100000;
    final subLoan = min(loan, d.maxLoan.toDouble());
    final effRate = max(_calcBankRate - d.subRate, 1.0);
    final normalEmi = _emi(loan, _calcBankRate, _calcTenureYears * 12);
    final subEmi = _emi(subLoan, effRate, _calcTenureYears * 12) + _emi(max(loan - subLoan, 0.0), _calcBankRate, _calcTenureYears * 12);
    final saving = normalEmi - subEmi;

    final labelCtrl = TextEditingController(text: 'PMAY Housing for All (${d.name})');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_pmay_housing_for_all/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save PMAY Calculation', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving PMAY Subsidy details: ₹${(d.subsidy / 100000).toStringAsFixed(2)}L NPV Benefit',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My PMAY Subsidy)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'PMAY Housing for All';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'PMAY - Housing for All',
        inputs: {
          'loanAmount': loan,
          'tenureYears': _calcTenureYears.toDouble(),
          'bankRate': _calcBankRate,
          'catIndex': _catData.keys.toList().indexOf(_calcSelCat).toDouble(),
        },
        results: {
          'subsidyNPV': d.subsidy.toDouble(),
          'monthlySaving': saving,
          'subsidisedEmi': subEmi,
          'normalEmi': normalEmi,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PMAY calculation saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    // Calculations using frozen _calc* values
    final d = _catData[_calcSelCat]!;
    final loan = _calcLoanAmountLakhs * 100000;
    final subLoan = min(loan, d.maxLoan.toDouble());
    final effRate = max(_calcBankRate - d.subRate, 1.0);
    final normalEmi = _emi(loan, _calcBankRate, _calcTenureYears * 12);
    final subEmi = _emi(subLoan, effRate, _calcTenureYears * 12) + _emi(max(loan - subLoan, 0.0), _calcBankRate, _calcTenureYears * 12);
    final saving = normalEmi - subEmi;
    final interestTotal = max(normalEmi * _calcTenureYears * 12 - loan, 1.0);
    final double subPct = (min((d.subsidy / interestTotal) * 100, 80.0)).clamp(1.0, 99.0);

    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
              _infoCell('Interest', '6.50%', 'Subsidy Rate', isGreen: true),
              _infoCell('Benefited', '1.22Cr+', 'Households'),
              _infoCell('Deadline', 'Mar 31', '2026', isSaffron: true),
            ],
          ),
        ),

        // Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF07543A), Color(0xFF046A38)],
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
              Text('प्रधानमंत्री आवास योजना · Ministry of Housing',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Housing for All — Interest Subsidy',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Credit Linked Subsidy Scheme (CLSS) for EWS / LIG / MIG categories',
                  style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 14),
              Row(
                children: [
                  _hBox('Scheme', 'PMAY-U 2.0'),
                  const SizedBox(width: 8),
                  _hBox('Subsidy NPV', '₹2.67L'),
                  const SizedBox(width: 8),
                  _hBox('Max Loan', '₹6L (EWS)'),
                ],
              )
            ],
          ),
        ),

        // Category scroll selector
        Text('Category Eligibility slabs', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _catData.entries.map((e) {
              final isSelected = _selCat == e.key;
              Color bg = isDark ? const Color(0xFF141C33) : Colors.white;
              Color borderCol = isSelected ? const Color(0xFF046A38) : theme.getBorderColor(context);
              if (isSelected) {
                bg = const Color(0xFFECFDF5);
              }
              return GestureDetector(
                onTap: () => setState(() => _selCat = e.key),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 9, bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: borderCol, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(e.value.name,
                          style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.w800,
                              color: isSelected ? const Color(0xFF07543A) : theme.getTextColor(context))),
                      Text(e.value.incomeLimit,
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: isSelected ? const Color(0xFF046A38) : theme.getMutedColor(context))),
                      const SizedBox(height: 4),
                      Text('₹${(e.value.subsidy / 100000).toStringAsFixed(2)}L',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFFFF6B00))),
                      Text('Max NPV Subsidy',
                          style: AppTextStyles.dmSans(
                              size: 8,
                              color: isSelected ? const Color(0xFF046A38) : theme.getMutedColor(context))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PMAY Subsidy Parameters', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              _buildSliderRow('LOAN AMOUNT (₹ LAKH)', _loanAmountLakhs, 5.0, 100.0, 95,
                  (v) => setState(() => _loanAmountLakhs = v),
                  hasError: _loanHasError),
              const SizedBox(height: 12),
              _buildSliderRow('LOAN TENURE (YEARS)', _tenureYears.toDouble(), 5.0, 30.0, 25,
                  (v) => setState(() => _tenureYears = v.toInt())),
              const SizedBox(height: 12),
              _buildSliderRow('BANK INTEREST RATE (%)', _bankRate, 6.00, 15.00, 180,
                  (v) => setState(() => _bankRate = v),
                  hasError: _rateHasError),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.calculate, size: 16),
                      label: Text('🏠 Calculate PMAY Subsidy',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _reset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFF0FDF4),
                        foregroundColor: theme.getTextColor(context),
                        side: BorderSide(color: theme.getBorderColor(context)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.refresh, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Result Panel — only shown after Calculate is tapped
        if (_calculated) ...[
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
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: isDark ? Colors.amber[200]! : Colors.amber[900]!,
                          weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultsKey, height: 0),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PMAY SUBSIDY BENEFIT',
                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF07543A), weight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('₹${(d.subsidy / 100000).toStringAsFixed(2)}L (NPV)',
                    style: AppTextStyles.playfair(size: 30, color: const Color(0xFF07543A), weight: FontWeight.w800)),
                Text('On ₹${(subLoan / 100000).toStringAsFixed(0)}L at ${d.subRate}% subsidy rate',
                    style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF046A38))),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _resBox('Effective Rate', '${effRate.toStringAsFixed(2)}%'),
                    _resBox('Normal EMI', numFormat.format(normalEmi)),
                    _resBox('Subsidised EMI', numFormat.format(subEmi)),
                    _resBox('Monthly Saving', numFormat.format(saving)),
                  ],
                ),
                const SizedBox(height: 16),

                // Donut Visual
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CustomPaint(
                        painter: _PmayDonutPainter(subPct: subPct),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(const Color(0xFF046A38), 'Subsidised Interest', '${subPct.toStringAsFixed(0)}%'),
                          const SizedBox(height: 4),
                          _legendItem(const Color(0xFFD1FAE5), 'Remaining Interest', '${(100 - subPct).toStringAsFixed(0)}%'),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _saveCalculation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white, size: 16),
                    label: Text('Save Calculation', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Documents Required
        Text('Documents Required', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: [
            _docItem('📄', 'Identity & Address Proof', 'Aadhaar Card (mandatory), PAN Card, Voter ID or Passport. Address proof must match Aadhaar.'),
            _docItem('💰', 'Income Certificate', 'Salary slips (3 months), Form 16, or ITR for salaried. For self-employed: CA-certified income declaration.'),
            _docItem('🏠', 'Property Documents', 'Sale agreement, allotment letter, NOC from builder. Property must be in applicant\'s name (women preferred for EWS/LIG).'),
            _docItem('🏦', 'Bank Statements', 'Last 6 months bank statement. No existing housing property owned by any family member in India.'),
          ],
        ),

        const SizedBox(height: 20),

        // Quick Links
        Text('Quick Links', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: [
            _linkItem('🌐', 'PMAY Official Portal', 'pmaymis.gov.in · Apply online'),
            _linkItem('🔍', 'Check Beneficiary Status', 'Track your PMAY application status'),
            _linkItem('🏦', 'Nodal Banks List', 'SBI, HDFC, LIC HFL, NHB PLIs'),
            _linkItem('📞', 'Helpline', '1800-11-6446 · Toll Free · 9am–5pm'),
          ],
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
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _hBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(val, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String title, double val, double min, double max, int div, ValueChanged<double> onChanged, {bool hasError = false}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 8.5, color: hasError ? Colors.red : theme.getMutedColor(context), weight: FontWeight.w800)),
            Text(
              title.contains('RATE')
                  ? '${val.toStringAsFixed(2)}%'
                  : title.contains('TENURE')
                      ? '${val.toInt()} Yrs'
                      : '₹${val.toStringAsFixed(1)} Lakh',
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: hasError ? Colors.red : theme.getTextColor(context)),
            ),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          divisions: div,
          activeColor: hasError ? Colors.red : const Color(0xFF046A38),
          inactiveColor: (hasError ? Colors.red : const Color(0xFF046A38)).withValues(alpha: 0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _resBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF046A38).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF046A38))),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF07543A))),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String pct) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF07543A), weight: FontWeight.w600)),
        const Spacer(),
        Text(pct, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF07543A), weight: FontWeight.w800)),
      ],
    );
  }

  Widget _docItem(String emoji, String title, String desc) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.45)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _linkItem(String emoji, String title, String desc) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Text('›', style: TextStyle(fontSize: 18, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }
}

class _PmayCatData {
  final String name;
  final double subRate;
  final double maxLoan;
  final double subsidy;
  final String incomeLimit;

  _PmayCatData({
    required this.name,
    required this.subRate,
    required this.maxLoan,
    required this.subsidy,
    required this.incomeLimit,
  });
}

class _PmayDonutPainter extends CustomPainter {
  final double subPct;
  _PmayDonutPainter({required this.subPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 4;

    final basePaint = Paint()
      ..color = const Color(0xFFD1FAE5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = const Color(0xFF046A38)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, basePaint);

    final sweepAngle = 2 * pi * (subPct / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );

    // Text in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${subPct.toStringAsFixed(0)}%',
        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF07543A)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PmayDonutPainter oldDelegate) => oldDelegate.subPct != subPct;
}
