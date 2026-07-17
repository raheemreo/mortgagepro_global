// lib/features/india/tools/in_tds_on_property.dart

import 'package:flutter/material.dart';
import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INTDSOnProperty extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INTDSOnProperty({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INTDSOnProperty> createState() => _INTDSOnPropertyState();
}

class _INTDSOnPropertyState extends ConsumerState<INTDSOnProperty> {
  // State variables for inputs
  double _saleAmt = 7500000;
  double _stampVal = 8000000;
  String _payMode = 'lump';
  String _panAvail = 'yes';
  int _numSellers = 1;

  bool _calculated = false;
  double _calcSaleAmt = 7500000;
  double _calcStampVal = 8000000;
  String _calcPayMode = 'lump';
  String _calcPanAvail = 'yes';
  int _calcNumSellers = 1;

  bool _saleAmtHasError = false;
  bool _stampValHasError = false;

  // Text controllers
  late TextEditingController _saleAmtCtrl;
  late TextEditingController _stampValCtrl;

  // Scroll controller and key to scroll to results
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _saleAmtCtrl = TextEditingController(text: _saleAmt.toStringAsFixed(0));
    _stampValCtrl = TextEditingController(text: _stampVal.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _saleAmtCtrl.dispose();
    _stampValCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _saleAmt = 7500000;
      _stampVal = 8000000;
      _saleAmtCtrl.text = '7500000';
      _stampValCtrl.text = '8000000';
      _payMode = 'lump';
      _panAvail = 'yes';
      _numSellers = 1;
      _calculated = false;

      _calcSaleAmt = 7500000;
      _calcStampVal = 8000000;
      _calcPayMode = 'lump';
      _calcPanAvail = 'yes';
      _calcNumSellers = 1;

      _saleAmtHasError = false;
      _stampValHasError = false;
    });
  }

  void _calculate() {
    final saleVal = double.tryParse(_saleAmtCtrl.text) ?? 0.0;
    final stampVal = double.tryParse(_stampValCtrl.text) ?? 0.0;

    setState(() {
      _saleAmtHasError = saleVal <= 0;
      _stampValHasError = stampVal <= 0;
    });

    if (_saleAmtHasError || _stampValHasError) {
      return;
    }

    setState(() {
      _calculated = true;
      _calcSaleAmt = _saleAmt;
      _calcStampVal = _stampVal;
      _calcPayMode = _payMode;
      _calcPanAvail = _panAvail;
      _calcNumSellers = _numSellers;
    });

    _scrollToResults();
  }

  bool _areInputsChanged() {
    return _saleAmt != _calcSaleAmt ||
        _stampVal != _calcStampVal ||
        _payMode != _calcPayMode ||
        _panAvail != _calcPanAvail ||
        _numSellers != _calcNumSellers;
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  void _saveCalculation() async {
    final isExempt = _calcSaleAmt < 5000000 && _calcStampVal < 5000000;
    double base = 0;
    double rate = 0;
    double totalTDS = 0;
    double perSeller = 0;

    if (!isExempt) {
      base = max(_calcSaleAmt, _calcStampVal);
      rate = _calcPanAvail == 'yes' ? 1.0 : 20.0;
      totalTDS = Compat.round(base * rate / 100).toDouble();
      perSeller = Compat.round(totalTDS / _calcNumSellers).toDouble();
    }

    final labelCtrl = TextEditingController(text: 'TDS on Property');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_tds_on_property/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save TDS Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Total TDS ${_fmt(totalTDS)} · Rate ${rate.toInt()}%',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Flat TDS deposit)',
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
              backgroundColor: const Color(0xFF046A38),
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
          : 'TDS on Property';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'TDS on Property',
        inputs: {
          'saleAmt': _calcSaleAmt,
          'stampVal': _calcStampVal,
          'panAvail': _calcPanAvail == 'yes' ? 1.0 : 0.0,
          'numSellers': _calcNumSellers.toDouble(),
        },
        results: {
          'base': base,
          'rate': rate,
          'totalTds': totalTDS,
          'perSeller': perSeller,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ TDS Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
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
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real-time calculation
    double base = 0;
    double rate = 0;
    double totalTDS = 0;
    double perSeller = 0;
    bool isExempt = true;

    if (_calcSaleAmt >= 5000000 || _calcStampVal >= 5000000) {
      isExempt = false;
      base = max(_calcSaleAmt, _calcStampVal);
      rate = _calcPanAvail == 'yes' ? 1.0 : 20.0;
      totalTDS = Compat.round(base * rate / 100).toDouble();
      perSeller = Compat.round(totalTDS / _calcNumSellers).toDouble();
    } else {
      base = _calcSaleAmt;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget banner alert
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget 2024: TDS on Rent Increased',
                      style: AppTextStyles.dmSans(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0B1F48),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Section 194-IB TDS on rent raised from 5% to 10% w.e.f. Oct 1, 2024. Property purchase TDS (Sec 194-IA) remains 1% for transactions above ₹50 Lakh.',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF334155), Color(0xFF1E293B)],
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
                  Text('TDS CALCULATOR – SEC 194-IA',
                      style: AppTextStyles.dmSans(
                          size: 9,
                          color: Colors.white.withValues(alpha: 0.7),
                          weight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFFDEA0),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Calculate TDS to be deducted & deposited',
                style: AppTextStyles.playfair(
                    size: 17, color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              // Synced input-slider 1: Sale Consideration
              _buildSyncedInputRow(
                label: 'SALE CONSIDERATION',
                controller: _saleAmtCtrl,
                value: _saleAmt,
                min: 500000,
                max: 50000000,
                hasError: _saleAmtHasError,
                onChangedText: (val) {
                  setState(() {
                    _saleAmt = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _saleAmt = val;
                    _saleAmtCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 2: Stamp Duty Value
              _buildSyncedInputRow(
                label: 'STAMP DUTY VALUE',
                controller: _stampValCtrl,
                value: _stampVal,
                min: 500000,
                max: 50000000,
                hasError: _stampValHasError,
                onChangedText: (val) {
                  setState(() {
                    _stampVal = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _stampVal = val;
                    _stampValCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PAYMENT MODE',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white70,
                                weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _payMode,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF334155),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  color: Colors.white,
                                  weight: FontWeight.w800),
                              iconEnabledColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                    value: 'lump', child: Text('Lump Sum')),
                                DropdownMenuItem(
                                    value: 'installment',
                                    child: Text('Installments')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _payMode = val);
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
                        Text('SELLER PAN AVAILABLE?',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white70,
                                weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _panAvail,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF334155),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  color: Colors.white,
                                  weight: FontWeight.w800),
                              iconEnabledColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                    value: 'yes', child: Text('Yes – 1% TDS')),
                                DropdownMenuItem(
                                    value: 'no', child: Text('No – 20% TDS')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _panAvail = val);
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
              const SizedBox(height: 12),

              // Joint sellers
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NUMBER OF SELLERS (JOINT SALE)',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: Colors.white70,
                          weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _numSellers,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF334155),
                        style: AppTextStyles.dmSans(
                            size: 13,
                            color: Colors.white,
                            weight: FontWeight.w800),
                        iconEnabledColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 Seller')),
                          DropdownMenuItem(value: 2, child: Text('2 Sellers')),
                          DropdownMenuItem(value: 3, child: Text('3 Sellers')),
                          DropdownMenuItem(value: 4, child: Text('4 Sellers')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _numSellers = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('📊 Calculate TDS Liability',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        if (_calculated) ...[
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
                      'Inputs changed. Tap Calculate TDS Liability to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultsKey, height: 0),

          // Results Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF334155), Color(0xFF1E293B)],
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
                Text('☸ TDS CALCULATION RESULT – SECTION 194-IA',
                    style: AppTextStyles.dmSans(
                        size: 8.5,
                        color: Colors.white.withValues(alpha: 0.6),
                        weight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _resBox(
                        'TDS Base Amount', _fmt(base), 'Higher of sale/stamp'),
                    const SizedBox(width: 8),
                    _resBox('TDS Rate', isExempt ? 'Nil' : '${rate.toInt()}%',
                        'Section 194-IA'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _resBox('TDS Per Seller', isExempt ? '₹0' : _fmt(perSeller),
                        'Divided equally'),
                    const SizedBox(width: 8),
                    _resBox('Deposit Deadline', isExempt ? 'N/A' : '30 Days',
                        'Via Form 26QB'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.18),
                    border: Border.all(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.40)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text('Total TDS to Deduct & Deposit',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(
                        isExempt ? '₹0 (No TDS)' : _fmt(totalTDS),
                        style: AppTextStyles.playfair(
                            size: 28,
                            color: const Color(0xFFFFDEA0),
                            weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isExempt
                            ? 'Property value below ₹50L threshold – TDS not applicable'
                            : _calcPanAvail == 'no'
                                ? '⚠️ Higher TDS @ 20% due to missing PAN (Sec 206AA)'
                                : 'Deposit on NSDL via Form 26QB within 30 days of payment',
                        style: AppTextStyles.dmSans(
                            size: 9, color: Colors.white70, height: 1.3),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Rate Reference Table
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
                Text('TDS Rate Reference 2025',
                    style: AppTextStyles.playfair(
                        size: 14,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800)),
                const SizedBox(height: 12),
                _rateRow('Property Purchase (Sec 194-IA)', 'Above ₹50 Lakh', '1%',
                    const Color(0xFFFF6B00)),
                _rateRow('Property Purchase (No PAN)', 'Above ₹50 Lakh', '20%',
                    Colors.red),
                _rateRow('Rent Paid to Owner (Sec 194-IB)', 'Above ₹50k/mo',
                    '10%', const Color(0xFFFF6B00)),
                _rateRow('NRI Property Sale (LTCG)', 'Any amount', '12.5%',
                    const Color(0xFFFF6B00)),
                _rateRow('NRI STCG (Sec 195)', 'Any amount', '30%',
                    const Color(0xFFFF6B00)),
                _rateRow('Agricultural Land (Rural)', 'Any amount', 'Exempt',
                    isDark ? const Color(0xFF86EFAC) : const Color(0xFF046A38)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Timeline: Step-by-Step Deposit
          Text('How to Deposit TDS – Step by Step',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 12),
          _timelineItem(
              1,
              'Deduct TDS at the time of payment',
              'Buyer deducts 1% of the sale consideration (or stamp duty value, whichever is higher) before paying the seller. Applicable only if total consideration exceeds ₹50 Lakh.',
              'Required by Law'),
          _timelineItem(
              2,
              'File Form 26QB online on NSDL',
              'Go to tin.tin.nsdl.com → TDS on Property → Form 26QB. Enter buyer PAN, seller PAN, property details, and TDS amount. One Form 26QB per buyer-seller combination.',
              'Within 30 Days of Payment'),
          _timelineItem(
              3,
              'Pay TDS via challan 26QB',
              'Pay online via Net Banking / debit card through NSDL. Authorised bank challan generated. Keep acknowledgement number.',
              'Online Net Banking'),
          _timelineItem(
              4,
              'Download Form 16B (TDS Certificate)',
              'After 10–15 days of TDS deposit, download Form 16B from TRACES portal (tdscpc.gov.in) and issue it to the seller.',
              'TRACES Portal'),
          _timelineItem(
              5,
              'Seller claims TDS credit in ITR',
              'Seller views TDS credit in Form 26AS / AIS and claims TDS refund or reduces tax payable in their Income Tax Return.',
              'Seller Benefit'),

          const SizedBox(height: 20),

          // Penalty Warnings
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D1212) : const Color(0xFFFEF2F2),
              border: Border.all(
                  color:
                      isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interest for Late TDS Deposit – Sec 201(1A)',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1% per month from date TDS was deductible to actual deduction date, PLUS 1.5% per month from deduction to deposit date. Penalty under Sec 271C can be equal to TDS amount.',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: isDark
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFF7F1D1D),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save Calculation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              border: Border.all(
                  color:
                      isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
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
                          style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF07543A))),
                      Text('Keep a record of your TDS liability details',
                          style: AppTextStyles.dmSans(
                              size: 10,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF046A38))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
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
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white70, weight: FontWeight.w800)),
            Text(_fmt(value),
                style: AppTextStyles.dmSans(
                    size: 11,
                    color: const Color(0xFFFFDEA0),
                    weight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
                color: hasError
                    ? Colors.red
                    : Colors.white.withValues(alpha: 0.20),
                width: hasError ? 1.5 : 1.0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 13, color: Colors.white, weight: FontWeight.w800),
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
            Text(label,
                style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTextStyles.dmSans(
                    size: 13, weight: FontWeight.w800, color: Colors.white)),
            Text(sub,
                style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _rateRow(String label, String value, String rate, Color rateColor) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: theme.getBorderColor(context).withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context))),
          ),
          Expanded(
            flex: 2,
            child: Text(value,
                style: AppTextStyles.dmSans(
                    size: 10, color: theme.getMutedColor(context))),
          ),
          Expanded(
            flex: 1,
            child: Text(
              rate,
              style: AppTextStyles.dmSans(
                  size: 12.5, weight: FontWeight.w800, color: rateColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
      int number, String title, String description, String badgeText) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTextStyles.dmSans(
                  size: 15, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: theme.getMutedColor(context),
                      height: 1.45),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyles.dmSans(
                        size: 8,
                        weight: FontWeight.w700,
                        color: Colors.blue[800]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
