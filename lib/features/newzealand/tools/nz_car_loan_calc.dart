// lib/features/newzealand/tools/nz_car_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../services/remote_config_service.dart';

class NZCarLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZCarLoanCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZCarLoanCalc> createState() => _NZCarLoanCalcState();
}

class _NZCarLoanCalcState extends ConsumerState<NZCarLoanCalc> {
  double _vehiclePrice = 35000;
  double _deposit = 5000;
  double _rate = 7.95;
  int _termYears = 5;
  double _estFee = 250;
  String _freq = 'monthly'; // 'weekly', 'fortnightly', 'monthly'

  bool _showResults = false;
  String _selectedVehicleName = 'New Car';
  String _selectedVehicleIcon = '🚗';

  final List<Map<String, dynamic>> _vehicles = [
    {'icon': '🚗', 'name': 'New Car', 'rate': 7.95},
    {'icon': '🚙', 'name': 'Used Car', 'rate': 9.95},
    {'icon': '⚡', 'name': 'EV/Hybrid', 'rate': 6.99},
    {'icon': '🚐', 'name': 'Ute/Van', 'rate': 9.50},
    {'icon': '🏍️', 'name': 'Motorcycle', 'rate': 12.90},
  ];

  final List<Map<String, dynamic>> _lenders = [
    {
      'name': 'ANZ Car Loan',
      'icon': '🏦',
      'rate': 7.95,
      'detail': 'Secured · New & used vehicles'
    },
    {
      'name': 'ASB Personal Loan',
      'icon': '🏦',
      'rate': 8.99,
      'detail': 'Secured vehicle loan'
    },
    {
      'name': 'Kiwibank Car Loan',
      'icon': '🥝',
      'rate': 6.99,
      'detail': 'Secured · Best for EV'
    },
    {
      'name': 'UDC Finance',
      'icon': '🏦',
      'rate': 9.95,
      'detail': "NZ's largest auto financier"
    },
    {
      'name': 'MTF Finance',
      'icon': '🏦',
      'rate': 11.95,
      'detail': 'Dealer-based · Nationwide NZ'
    },
  ];

  void _reset() {
    setState(() {
      _vehiclePrice = 35000;
      _deposit = 5000;
      _rate = 7.95;
      _termYears = 5;
      _estFee = 250;
      _freq = 'monthly';
      _selectedVehicleName = 'New Car';
      _selectedVehicleIcon = '🚗';
      _showResults = false;
    });
  }

  void _saveCalculation(double repayment, double totalInterest,
      double totalCost, double loanAmt) async {
    final labelCtrl = TextEditingController(
        text: 'NZ $_selectedVehicleIcon $_selectedVehicleName Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.getCardColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('💾 Save Calculation',
              style: AppTextStyles.playfair(
                  size: 16, color: widget.theme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saving: ${CurrencyFormatter.compact(loanAmt, symbol: 'NZ\$')} loan @ $_rate% → ${CurrencyFormatter.compact(repayment, symbol: 'NZ\$')}/${_freq == 'weekly' ? 'wk' : _freq == 'fortnightly' ? 'fn' : 'mo'}',
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
                  hintText: 'Label (e.g. Mazda CX-5)',
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
                backgroundColor: const Color(0xFFC0392B),
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
        calcType: 'Car Loan Calc',
        inputs: {
          'vehiclePrice': _vehiclePrice,
          'deposit': _deposit,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
          'estFee': _estFee,
          'freq': _freq == 'weekly'
              ? 0.0
              : _freq == 'fortnightly'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'repayment': repayment,
          'totalInterest': totalInterest,
          'totalCost': totalCost,
          'loanAmount': loanAmt,
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

  double _calculateMonthlyRepayment(double P, double rateVal, int years) {
    final r = rateVal / 100 / 12;
    final n = years * 12;
    if (r == 0) return P / n;
    return P * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Rates strip values
    const rateCarLoan = 9.95;
    const ratePersonal = 12.9;
    const rateSecured = 7.95;
    final rateOCR = double.tryParse(RemoteConfigService.instance.nzOcrRate) ?? 2.25;

    // Calculation logic
    final P = max(0.0, _vehiclePrice - _deposit);
    final months = _termYears * 12;
    final monthlyRepay = _calculateMonthlyRepayment(P, _rate, _termYears);
    final totalPay = monthlyRepay * months;
    final totalInterest = max(0.0, totalPay - P);
    final totalCost = totalPay + _estFee;
    final effRate = P > 0 ? (totalInterest / P / _termYears * 100) : 0.0;

    // Repayments based on frequency
    double displayRepayment;
    String freqLabel;
    if (_freq == 'weekly') {
      displayRepayment = monthlyRepay * 12 / 52;
      freqLabel = 'Weekly';
    } else if (_freq == 'fortnightly') {
      displayRepayment = monthlyRepay * 12 / 26;
      freqLabel = 'Fortnightly';
    } else {
      displayRepayment = monthlyRepay;
      freqLabel = 'Monthly';
    }

    final totalBreakdown = P + totalInterest + _estFee;
    final principalPct = totalBreakdown > 0 ? P / totalBreakdown : 0.0;
    final interestPct =
        totalBreakdown > 0 ? totalInterest / totalBreakdown : 0.0;
    final feePct = totalBreakdown > 0 ? _estFee / totalBreakdown : 0.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Rate Strip (integrated in header visually)
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
                    child: _buildRateStripCell(
                        'Car Loan', '$rateCarLoan%', 'UDC Finance')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell(
                        'Personal', '$ratePersonal%', 'Major banks')),
                _buildDivider(),
                Expanded(
                    child:
                        _buildRateStripCell('Secured', '$rateSecured%', 'ANZ')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('OCR', '$rateOCR%', 'RBNZ',
                        isGold: true)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Vehicle Type Selector
          Text('Vehicle Type',
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _vehicles.map((v) {
                final isSelected = _selectedVehicleName == v['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVehicleName = v['name'];
                      _selectedVehicleIcon = v['icon'];
                      _rate = v['rate'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF7F1D1D)
                              : const Color(0xFFFEF2F2))
                          : theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: isSelected
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
                      children: [
                        Text(v['icon'], style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          v['name'],
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFC0392B))
                                : theme.getTextColor(context),
                          ),
                        ),
                        Text(
                          '${v['rate']}%+',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Input Details Card
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
                    Text('🏎️ Loan Details',
                        style: AppTextStyles.playfair(
                            size: 14,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800)),
                    GestureDetector(
                      onTap: _reset,
                      child: Text('Reset ↺',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: const Color(0xFFC0392B),
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle Price & Deposit Row
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Vehicle Price (NZD)',
                        value: _vehiclePrice,
                        onChanged: (val) => setState(() => _vehiclePrice = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildNumericField(
                        label: 'Deposit (NZD)',
                        value: _deposit,
                        onChanged: (val) => setState(() => _deposit = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Term Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LOAN TERM',
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                    Text('$_termYears years',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFFC0392B),
                    inactiveTrackColor: theme.getBgColor(context),
                    thumbColor: const Color(0xFFC0392B),
                    overlayColor:
                        const Color(0xFFC0392B).withValues(alpha: 0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    min: 1,
                    max: 7,
                    divisions: 6,
                    value: _termYears.toDouble(),
                    onChanged: (val) =>
                        setState(() => _termYears = val.round()),
                  ),
                ),
                const SizedBox(height: 10),

                // Rate and Establishment Fee Row
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Interest Rate %',
                        value: _rate,
                        isPercent: true,
                        onChanged: (val) => setState(() => _rate = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildNumericField(
                        label: 'Establishment Fee',
                        value: _estFee,
                        onChanged: (val) => setState(() => _estFee = val),
                        subtitle: 'Typical: \$150–\$350',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Repayment Frequency
                Text('REPAYMENT FREQUENCY',
                    style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _freq,
                      dropdownColor: theme.getCardColor(context),
                      isExpanded: true,
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w700),
                      items: const [
                        DropdownMenuItem(
                            value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(
                            value: 'fortnightly', child: Text('Fortnightly')),
                        DropdownMenuItem(
                            value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _freq = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Calculate Button
                ElevatedButton(
                  onPressed: () {
                    if (P <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Deposit must be less than vehicle price',
                                style: AppTextStyles.dmSans())),
                      );
                      return;
                    }
                    setState(() => _showResults = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 44),
                    elevation: 2,
                  ),
                  child: Text('🏎️ Calculate Car Loan',
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          // Results Block
          if (_showResults) ...[
            const SizedBox(height: 18),

            // Hero Repayment Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0F0D), Color(0xFF922B21)],
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
                  Text('$freqLabel Repayment · NZD',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: Colors.white54,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(displayRepayment,
                        currencyCode: 'NZD'),
                    style: AppTextStyles.playfair(
                        size: 36,
                        color: const Color(0xFFF5D060),
                        weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$freqLabel repayment · $_termYears year term · $_rate% p.a.',
                    style:
                        AppTextStyles.dmSans(size: 10, color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),

                  // 3-Box Results Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroBox(
                            'Total Cost',
                            CurrencyFormatter.compact(totalCost,
                                symbol: 'NZ\$'),
                            const Color(0xFFF5D060)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeroBox(
                            'Interest Paid',
                            CurrencyFormatter.compact(totalInterest,
                                symbol: 'NZ\$'),
                            const Color(0xFFFCA5A5)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeroBox(
                            'Effective Rate',
                            '${effRate.toStringAsFixed(2)}%',
                            const Color(0xFF6EE7B7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Save Calculation Card
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
                        Text('Compare different terms and rates easily',
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveCalculation(
                        displayRepayment, totalInterest, totalCost, P),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
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
            const SizedBox(height: 12),

            // Cost Breakdown Donut
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
                  Text('💰 Total Cost Breakdown',
                      style: AppTextStyles.playfair(
                          size: 13,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CustomPaint(
                          painter: _NZCarDonutPainter(
                            principalPct: principalPct,
                            interestPct: interestPct,
                            feePct: feePct,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _buildLegendRow(
                                'Principal', P, const Color(0xFF1A6B4A)),
                            const SizedBox(height: 8),
                            _buildLegendRow('Interest', totalInterest,
                                const Color(0xFFC0392B)),
                            const SizedBox(height: 8),
                            _buildLegendRow(
                                'Fees', _estFee, const Color(0xFFD4A017)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Cost Composition Stacked Bar & Freq Compare
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
                  Text('📊 Cost Composition',
                      style: AppTextStyles.playfair(
                          size: 13,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  // Stacked Bar
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        if (principalPct > 0)
                          Expanded(
                            flex: (principalPct * 100).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xFF0D3B2E),
                                  Color(0xFF1A6B4A)
                                ]),
                              ),
                            ),
                          ),
                        if (interestPct > 0)
                          Expanded(
                            flex: (interestPct * 100).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xFFC0392B),
                                  Color(0xFF922B21)
                                ]),
                              ),
                            ),
                          ),
                        if (feePct > 0)
                          Expanded(
                            flex: (feePct * 100).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xFFD4A017),
                                  Color(0xFFA07810)
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stacked Bar Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Principal ${(principalPct * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: theme.getMutedColor(context))),
                      Text(
                          'Interest ${(interestPct * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: theme.getMutedColor(context))),
                      Text('Fees ${(feePct * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 12),

                  Text('Weekly vs Monthly Comparison',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  const SizedBox(height: 8),

                  _buildFreqCompareRow(
                      'Weekly', monthlyRepay * 12 / 52, '52 × year', theme),
                  const SizedBox(height: 6),
                  _buildFreqCompareRow('Fortnightly', monthlyRepay * 12 / 26,
                      '26 × year', theme),
                  const SizedBox(height: 6),
                  _buildFreqCompareRow(
                      'Monthly', monthlyRepay, '12 × year', theme),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // NZ Lender Rates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NZ Car Finance Rates',
                  style: AppTextStyles.playfair(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF78350F)
                        : const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Jun 2025',
                    style: AppTextStyles.dmSans(
                        size: 9,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF92400E),
                        weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._lenders.map((l) {
            final rateVal = l['rate'] as double;
            final isEV = l['name'].toString().contains('Kiwibank');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.getBorderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child:
                        Text(l['icon'], style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['name'],
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(l['detail'],
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: theme.getMutedColor(context))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${rateVal.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(
                              size: 14,
                              weight: FontWeight.w800,
                              color: const Color(0xFF1A6B4A))),
                      Text(isEV ? 'EV rate' : 'p.a.',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                ],
              ),
            );
          }),
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
    String? subtitle,
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
                  initialValue: value.toString(),
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.dmSans(
                    size: 8, color: theme.getMutedColor(context))),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white54,
                  weight: FontWeight.w600,
                  letterSpacing: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 12.5, color: color, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, double val, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 10, color: theme.getMutedColor(context))),
        const Spacer(),
        Text(
          CurrencyFormatter.compact(val, symbol: 'NZ\$'),
          style: AppTextStyles.dmSans(
              size: 12,
              color: theme.getTextColor(context),
              weight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildFreqCompareRow(
      String name, double val, String note, CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: theme.getTextColor(context))),
          Text(note,
              style: AppTextStyles.dmSans(
                  size: 9, color: theme.getMutedColor(context))),
          Text(
            CurrencyFormatter.format(val, currencyCode: 'NZD'),
            style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: const Color(0xFF1A6B4A)),
          ),
        ],
      ),
    );
  }
}

class _NZCarDonutPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final double feePct;
  final bool isDark;

  _NZCarDonutPainter({
    required this.principalPct,
    required this.interestPct,
    required this.feePct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final paintBg = Paint()
      ..color =
          isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    double startAngle = -pi / 2;

    // Draw Principal Segment
    if (principalPct > 0) {
      final sweepAngle = principalPct * 2 * pi;
      final paintP = Paint()
        ..color = const Color(0xFF1A6B4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintP);
      startAngle += sweepAngle;
    }

    // Draw Interest Segment
    if (interestPct > 0) {
      final sweepAngle = interestPct * 2 * pi;
      final paintI = Paint()
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintI);
      startAngle += sweepAngle;
    }

    // Draw Fees Segment
    if (feePct > 0) {
      final sweepAngle = feePct * 2 * pi;
      final paintF = Paint()
        ..color = const Color(0xFFD4A017)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintF);
    }

    // Draw central text
    final textPainterLabel = TextPainter(
      text: TextSpan(
          text: 'LOAN',
          style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF4A6358),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'Helvetica Neue')),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterLabel.paint(
        canvas, center - Offset(textPainterLabel.width / 2, 10));

    final textPainterSub = TextPainter(
      text: TextSpan(
          text: 'COST',
          style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF4A6358),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'Helvetica Neue')),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterSub.paint(canvas, center - Offset(textPainterSub.width / 2, -2));
  }

  @override
  bool shouldRepaint(covariant _NZCarDonutPainter oldDelegate) =>
      oldDelegate.principalPct != principalPct ||
      oldDelegate.interestPct != interestPct ||
      oldDelegate.feePct != feePct ||
      oldDelegate.isDark != isDark;
}
