// lib/features/india/tools/in_car_loan_emi.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INCarLoanEMI extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INCarLoanEMI({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INCarLoanEMI> createState() => _INCarLoanEMIState();
}

class _INCarLoanEMIState extends ConsumerState<INCarLoanEMI> {
  late TextEditingController _priceController;
  late TextEditingController _downController;
  late TextEditingController _rateController;
  late TextEditingController _tenureController;
  String _carType = 'new'; // 'new', 'used', 'ev'

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '1500000');
    _downController = TextEditingController(text: '20');
    _rateController = TextEditingController(text: '8.75');
    _tenureController = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _downController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _priceController.text = '1500000';
      _downController.text = '20';
      _rateController.text = '8.75';
      _tenureController.text = '5';
      _carType = 'new';
    });
  }

  double get _price => double.tryParse(_priceController.text) ?? 1500000.0;
  double get _downPct => double.tryParse(_downController.text) ?? 20.0;
  double get _rate => double.tryParse(_rateController.text) ?? 8.75;
  int get _tenure => int.tryParse(_tenureController.text) ?? 5;

  void _selectCarType(String type) {
    setState(() {
      _carType = type;
      if (type == 'used') {
        _rateController.text = '10.50';
      } else {
        _rateController.text = '8.75';
      }
    });
  }

  double _calcEMI(double p, double r, int n) {
    final mr = r / 12 / 100;
    if (mr <= 0) return p / n;
    return p * mr * pow(1 + mr, n) / (pow(1 + mr, n) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final priceVal = _price;
    final dpVal = _downPct;
    final rateVal = _rate;
    final tenureVal = _tenure;

    final loan = priceVal * (1 - dpVal / 100);
    final n = tenureVal * 12;
    final emi = _calcEMI(loan, rateVal, n);
    final total = emi * n;
    final interest = total - loan;

    final labelCtrl = TextEditingController(text: 'Car Loan EMI');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Car EMI', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: EMI ${_fmt(emi)}/mo · Car Price ${_fmt(priceVal)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My New SUV Loan)',
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
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Car Loan EMI';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Car Loan EMI',
        inputs: {
          'price': priceVal,
          'downPct': dpVal,
          'rate': rateVal,
          'tenure': tenureVal.toDouble(),
          'carType': _carType == 'new' ? 0.0 : _carType == 'used' ? 1.0 : 2.0,
        },
        results: {
          'emi': emi,
          'loan': loan,
          'interest': interest,
          'total': total,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Car loan EMI saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final priceVal = _price;
    final dpVal = _downPct;
    final rateVal = _rate;
    final tenureVal = _tenure;

    final loan = priceVal * (1 - dpVal / 100);
    final down = priceVal * (dpVal / 100);
    final n = tenureVal * 12;
    final emi = _calcEMI(loan, rateVal, n);
    final total = emi * n;
    final interest = total - loan;
    final fee = loan * 0.005; // 0.5% standard fee

    final totalOutgo = total + down;
    final double pctLoan = totalOutgo > 0 ? (loan / totalOutgo) : 0.0;
    final double pctInt = totalOutgo > 0 ? (interest / totalOutgo) : 0.0;
    final double pctDown = totalOutgo > 0 ? (down / totalOutgo) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('SBI Car Loan', '8.75%', 'Jun 2025', isFirst: true),
              _buildRateStripItem('HDFC New', '9.25%', 'Car Loan'),
              _buildRateStripItem('ICICI New', '9.00%', 'Car Loan'),
              _buildRateStripItem('Used Car', '10.5%', 'Avg Rate'),
            ],
          ),
        ),

        // Popular Models Scroll
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular Models', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)),
                child: Text('Ex-Showroom 2025', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: const Color(0xFFFF6B00))),
              ),
            ],
          ),
        ),
        _buildPopularModels(),
        const SizedBox(height: 16),

        // Inputs Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Details', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
              GestureDetector(
                onTap: _reset,
                child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car type toggles
              Text('VEHICLE TYPE', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildToggleBtn('New Car', _carType == 'new', () => _selectCarType('new'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildToggleBtn('Used Car', _carType == 'used', () => _selectCarType('used'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildToggleBtn('EV', _carType == 'ev', () => _selectCarType('ev'))),
                ],
              ),
              const SizedBox(height: 16),

              // Price
              _buildSyncSliderRow(
                title: 'Car Price / On-Road (₹)',
                controller: _priceController,
                min: 100000,
                max: 10000000,
                divisions: 198,
                displayValue: _fmt(priceVal),
              ),
              const SizedBox(height: 16),

              // Down Payment %
              _buildSyncSliderRow(
                title: 'Down Payment (%)',
                controller: _downController,
                min: 10,
                max: 50,
                divisions: 40,
                displayValue: '${dpVal.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 16),

              // Rate
              _buildSyncSliderRow(
                title: 'Interest Rate (% p.a.)',
                controller: _rateController,
                min: 7,
                max: 18,
                divisions: 220,
                displayValue: '${rateVal.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 16),

              // Tenure
              _buildSyncSliderRow(
                title: 'Loan Tenure (Years)',
                controller: _tenureController,
                min: 1,
                max: 7,
                divisions: 6,
                displayValue: '$tenureVal yr',
              ),
              const SizedBox(height: 20),

              // Calculate EMI Button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ EMI calculation updated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF046A38),
                      duration: const Duration(milliseconds: 600),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '☸ Calculate Car Loan EMI',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Results Card Grid (6 items)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
              Text('Car Loan Results', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, weight: FontWeight.w800)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildResultBox('Loan Amount', _fmt(loan), sub: '${(100 - dpVal).toStringAsFixed(0)}% financing'),
                  _buildResultBox('Monthly EMI', _fmt(emi), sub: '$tenureVal-year tenure', highlight: true),
                  _buildResultBox('Total Interest', _fmt(interest), sub: 'Cumulative cost'),
                  _buildResultBox('Total Payable', _fmt(total), sub: 'Loan + interest', highlight: true),
                  _buildResultBox('Down Payment', _fmt(down), sub: '${dpVal.toStringAsFixed(0)}% upfront'),
                  _buildResultBox('Processing Fee', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(fee)}", sub: '~0.5% of loan'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Cost Breakup Donut Chart
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 Cost Breakup', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _CarDonutPainter(
                        pctPrincipal: pctLoan,
                        pctInterest: pctInt,
                        pctDown: pctDown,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('EMI', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF0B1F48))),
                            Text(_fmtShort(emi), style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF7A5C3A), weight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendRow('Principal', _fmtShort(loan), const Color(0xFF1A3A8F)),
                        const SizedBox(height: 8),
                        _buildLegendRow('Total Interest', _fmtShort(interest), const Color(0xFFFF6B00)),
                        const SizedBox(height: 8),
                        _buildLegendRow('Down Payment', _fmtShort(down), const Color(0xFF0D9488)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Bank Rate comparison
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Banks – Car Loan Rates 2025', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              _buildBankBar('SBI', 8.75, [const Color(0xFF0B1F48), const Color(0xFF1A3A8F)]),
              _buildBankBar('HDFC', 9.25, [const Color(0xFFFF6B00), const Color(0xFFFF9933)]),
              _buildBankBar('ICICI', 9.00, [const Color(0xFF0D9488), const Color(0xFF0F766E)]),
              _buildBankBar('Axis', 9.50, [const Color(0xFFF5A623), const Color(0xFFB45309)]),
              _buildBankBar('Kotak', 9.25, [const Color(0xFF046A38), const Color(0xFF07543A)]),
              _buildBankBar('Used Car Avg', 10.50, [const Color(0xFF9333EA), const Color(0xFF6D28D9)]),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tips Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'India Car Loan Tips: New cars: 85–90% financing available. Used cars (under 5 years): up to 80% LTV. EV loans — SBI Green Car Loan at 8.75%, HDFC at 8.50% for electric vehicles. CIBIL 750+ gets best rates. Processing fee: 0.5–1% of loan.',
                  style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF07543A), weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Save Button
        ElevatedButton.icon(
          onPressed: _saveCalculation,
          icon: const Icon(Icons.save, size: 16, color: Colors.white),
          label: Text('Save This Calculation', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF046A38),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // --- Widget Builders ---

  Widget _buildPopularModels() {
    final theme = widget.theme;
    final models = [
      {'icon': '🚗', 'name': 'Maruti Swift', 'price': 1500000.0, 'dispPrice': '₹15.0L', 'emi': '~₹30,000/mo'},
      {'icon': '🚙', 'name': 'Hyundai Creta', 'price': 1800000.0, 'dispPrice': '₹18.0L', 'emi': '~₹36,000/mo'},
      {'icon': '🛻', 'name': 'Tata Nexon EV', 'price': 3000000.0, 'dispPrice': '₹30.0L', 'emi': '~₹60,000/mo'},
      {'icon': '🚗', 'name': 'Tata Punch', 'price': 1200000.0, 'dispPrice': '₹12.0L', 'emi': '~₹24,000/mo'},
      {'icon': '🚐', 'name': 'Innova HyCross', 'price': 5000000.0, 'dispPrice': '₹50.0L', 'emi': '~₹1.0L/mo'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: models.map((m) {
          final price = m['price'] as double;
          final isSelected = (_price - price).abs() < 1000;
          return GestureDetector(
            onTap: () {
              setState(() {
                _priceController.text = price.round().toString();
              });
            },
            child: Container(
              width: 115,
              margin: const EdgeInsets.only(right: 10, bottom: 4, top: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF6B00) : theme.getBorderColor(context),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['icon'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(
                    m['name'] as String,
                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m['dispPrice'] as String,
                    style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFFFF6B00)),
                  ),
                  Text(
                    m['emi'] as String,
                    style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSyncSliderRow({
    required String title,
    required TextEditingController controller,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
  }) {
    final theme = widget.theme;
    final currentVal = double.tryParse(controller.text) ?? min;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5E6D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: const Color(0xFFFF6B00),
                  inactiveTrackColor: inactiveColor,
                  thumbColor: const Color(0xFFFF6B00),
                  overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: currentVal.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (val) {
                    setState(() {
                      controller.text = min is int ? val.round().toString() : val.toStringAsFixed(2);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              height: 32,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  filled: true,
                  fillColor: theme.getBgColor(context),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.getBorderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                ),
                onSubmitted: (val) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFFF6B00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String value, {required String sub, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: highlight ? 0.25 : 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: highlight ? 14 : 12,
              weight: FontWeight.w800,
              color: highlight ? const Color(0xFFFFDEA0) : Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
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
              Text(
                label,
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
              ),
              Text(
                value,
                style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankBar(String name, double rate, List<Color> colors) {
    final double pct = ((rate - 7.0) / (12.0 - 7.0)).clamp(0.1, 1.0);
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: theme.getMutedColor(context)),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 10,
                color: const Color(0xFFF0E0D0),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${rate.toStringAsFixed(2)}%',
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(
                  left: BorderSide(color: Colors.white12, width: 1.0),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white60,
                weight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 13,
                color: const Color(0xFFFFDEA0),
                weight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarDonutPainter extends CustomPainter {
  final double pctPrincipal;
  final double pctInterest;
  final double pctDown;

  _CarDonutPainter({required this.pctPrincipal, required this.pctInterest, required this.pctDown});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintBg = Paint()
      ..color = const Color(0xFFF0E0D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawCircle(center, radius, paintBg);

    final paintP = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintI = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintD = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    final pAngle = 2 * pi * pctPrincipal;
    if (pAngle > 0.001) {
      canvas.drawArc(rect, startAngle, pAngle, false, paintP);
      startAngle += pAngle;
    }

    final iAngle = 2 * pi * pctInterest;
    if (iAngle > 0.001) {
      canvas.drawArc(rect, startAngle, iAngle, false, paintI);
      startAngle += iAngle;
    }

    final dAngle = 2 * pi * pctDown;
    if (dAngle > 0.001) {
      canvas.drawArc(rect, startAngle, dAngle, false, paintD);
    }
  }

  @override
  bool shouldRepaint(covariant _CarDonutPainter oldDelegate) => true;
}
