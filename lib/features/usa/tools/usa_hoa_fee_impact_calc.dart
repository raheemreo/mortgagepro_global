// lib/features/usa/tools/usa_hoa_fee_impact_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHoaFeeImpactCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAHoaFeeImpactCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAHoaFeeImpactCalc> createState() => _USAHoaFeeImpactCalcState();
}

class _USAHoaFeeImpactCalcState extends ConsumerState<USAHoaFeeImpactCalc> {
  final _homePriceController = TextEditingController(text: '450000');
  final _downPctController = TextEditingController(text: '10');
  final _rateController = TextEditingController(text: '6.82');
  final _hoaController = TextEditingController(text: '350');
  final _incomeController = TextEditingController(text: '8500');
  final _otherDebtsController = TextEditingController(text: '500');
  final _taxRateController = TextEditingController(text: '1.10');
  final _insuranceController = TextEditingController(text: '1800');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final list = [
      _homePriceController,
      _downPctController,
      _rateController,
      _hoaController,
      _incomeController,
      _otherDebtsController,
      _taxRateController,
      _insuranceController,
    ];
    for (final controller in list) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    final list = [
      _homePriceController,
      _downPctController,
      _rateController,
      _hoaController,
      _incomeController,
      _otherDebtsController,
      _taxRateController,
      _insuranceController,
    ];
    for (final controller in list) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _resetInputs() {
    setState(() {
      _homePriceController.text = '450000';
      _downPctController.text = '10';
      _rateController.text = '6.82';
      _hoaController.text = '350';
      _incomeController.text = '8500';
      _otherDebtsController.text = '500';
      _taxRateController.text = '1.10';
      _insuranceController.text = '1800';
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  // Unused: _loadSavedCalculation removed to resolve analyzer warnings.

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final price = _val(_homePriceController);
    final downPct = _val(_downPctController);
    final rate = _val(_rateController);
    final hoa = _val(_hoaController);
    final income = _val(_incomeController);
    final otherDebts = _val(_otherDebtsController);
    final taxRate = _val(_taxRateController);
    final annualIns = _val(_insuranceController);

    final loan = price * (1 - downPct / 100);
    final mo = rate / 100 / 12;
    const n = 360;
    final pi = mo == 0 ? loan / n : loan * mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1);
    final taxMo = price * taxRate / 100 / 12;
    final insMo = annualIns / 12;
    final withoutHoa = pi + taxMo + insMo;
    final total = withoutHoa + hoa;
    final dti = income > 0 ? (total + otherDebts) / income * 100 : 0.0;

    final labelCtrl = TextEditingController(text: 'HOA Fee Impact');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_hoa_fee_impact_calc/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Total PITI+HOA: ${CurrencyFormatter.compact(total, symbol: r'$')}/mo · DTI: ${dti.toStringAsFixed(1)}%',
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
                hintText: 'Label (e.g. HOA Impact)',
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
              backgroundColor: widget.theme.primaryColor,
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
          : 'HOA Fee Impact';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HOA Fee Impact',
        inputs: {
          'HomePrice': price,
          'DownPct': downPct,
          'InterestRate': rate,
          'HoaFee': hoa,
          'Income': income,
          'OtherDebts': otherDebts,
          'TaxRate': taxRate,
          'AnnualIns': annualIns,
        },
        results: {
          'PITI + HOA': total,
          'Without HOA': withoutHoa,
          'DTI ratio': dti,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
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
    final primaryColor = theme.primaryColor;
    final cardColor = theme.getCardColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    // Compute active calculation
    final price = _val(_homePriceController);
    final downPct = _val(_downPctController);
    final rate = _val(_rateController);
    final hoa = _val(_hoaController);
    final income = _val(_incomeController);
    final otherDebts = _val(_otherDebtsController);
    final taxRate = _val(_taxRateController);
    final annualIns = _val(_insuranceController);

    final loan = price * (1 - downPct / 100);
    final mo = rate / 100 / 12;
    const n = 360;
    final pi = mo == 0 ? loan / n : loan * mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1);
    final taxMo = price * taxRate / 100 / 12;
    final insMo = annualIns / 12;
    final withoutHoa = pi + taxMo + insMo;
    final total = withoutHoa + hoa;
    final dti = income > 0 ? (total + otherDebts) / income * 100 : 0.0;
    final dtiNoHoa = income > 0 ? (withoutHoa + otherDebts) / income * 100 : 0.0;

    final maxHousing = 0.43 * income - otherDebts;
    final down = downPct / 100;
    final factor = mo == 0 ? (1 - down) / n : (1 - down) * mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1);
    final taxFactor = taxRate / 100 / 12;
    final insConst = insMo;

    double maxPrice(double maxPITI) {
      if (factor + taxFactor == 0) return 0.0;
      return max(0.0, (maxPITI - insConst) / (factor + taxFactor));
    }

    final mxNoHoa = maxPrice(maxHousing);
    final mxWithHoa = maxPrice(maxHousing - hoa);
    final bpLoss = mxNoHoa - mxWithHoa;

    final dtiFmt = dti.toStringAsFixed(1);
    final dtiIncrease = (dti - dtiNoHoa).toStringAsFixed(1);
    final bpLossK = (bpLoss / 1000).round();

    // DTI Alert info
    String dtiStatus = '';
    Color dtiBarColor = const Color(0xFF15803D);
    if (dti <= 36) {
      dtiStatus = '✅ Excellent DTI — strong approval likelihood';
      dtiBarColor = const Color(0xFF15803D);
    } else if (dti <= 43) {
      dtiStatus = '⚠️ Acceptable range — lenders may require compensating factors';
      dtiBarColor = const Color(0xFFD97706);
    } else {
      dtiStatus = '🚨 High DTI — approval unlikely without large down or co-borrower';
      dtiBarColor = const Color(0xFFB91C1C);
    }

    // Rate strip values
    const rateStats = [
      {'label': 'Nat\'l Avg HOA', 'value': '\$291', 'note': 'Per Month'},
      {'label': 'Max DTI', 'value': '43%', 'note': 'FHA/Conv.'},
      {'label': '30-Yr Rate', 'value': '6.82%', 'note': 'Freddie Mac'},
      {'label': 'Front-End', 'value': '28%', 'note': 'Max Rule'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2547) : const Color(0xFFE2ECF7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: rateStats.map((stat) {
              final idx = rateStats.indexOf(stat);
              final isLast = idx == rateStats.length - 1;
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            right: BorderSide(
                                color: textColor.withValues(alpha: 0.12),
                                width: 1),
                          ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        stat['label']!,
                        style: AppTextStyles.dmSans(
                            size: 8.5, weight: FontWeight.w700, color: mutedColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat['value']!,
                        style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.w800,
                          color: stat['label'] == 'Nat\'l Avg HOA' || stat['label'] == 'Front-End' ? const Color(0xFFD97706) : textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        stat['note']!,
                        style: AppTextStyles.dmSans(
                            size: 7.5, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Input Card Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calculator',
              style: AppTextStyles.playfair(
                  size: 13, weight: FontWeight.w700, color: textColor),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                    size: 11, color: primaryColor, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏘️', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOA Fee Impact',
                        style: AppTextStyles.playfair(
                            size: 14.5, weight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        'See how HOA fees affect your DTI & buying power',
                        style: AppTextStyles.dmSans(size: 9.5, color: mutedColor),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),

              _buildTextInputRow('Home Purchase Price', _homePriceController, prefix: '\$'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextInputRow('Down Payment', _downPctController, suffix: '%')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextInputRow('Interest Rate', _rateController, suffix: '%')),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextInputRow('Monthly HOA Fee', _hoaController, prefix: '\$')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextInputRow('Gross Income/Mo', _incomeController, prefix: '\$')),
                ],
              ),
              const SizedBox(height: 12),

              _buildTextInputRow('Other Monthly Debts (car, student, cards)', _otherDebtsController, prefix: '\$'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextInputRow('Annual Property Tax', _taxRateController, suffix: '%')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextInputRow('Annual Insurance', _insuranceController, prefix: '\$')),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D28D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        elevation: 2,
                      ),
                      child: _calculating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              '🧮 Calculate HOA Impact',
                              style: AppTextStyles.playfair(
                                  size: 13, weight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_showResults && !_isCalcDirty) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveCalculation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: const Color(0xFF6D28D9),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                          side: const BorderSide(color: Color(0xFF6D28D9), width: 2),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '🔖 Save',
                        style: AppTextStyles.dmSans(
                            size: 12, weight: FontWeight.w700, color: const Color(0xFF6D28D9)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults && !_isCalcDirty) ...[
          // Result Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL MONTHLY PITI + HOA',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(total, symbol: r'$'),
                  style: AppTextStyles.playfair(
                      size: 36, weight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  dti <= 43 ? '✅ DTI $dtiFmt% — within lender guidelines' : '🚨 DTI $dtiFmt% — exceeds 43% max',
                  style: AppTextStyles.dmSans(
                      size: 10, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildHeroBottomBox('Without HOA', CurrencyFormatter.format(withoutHoa, symbol: r'$')),
                    const SizedBox(width: 8),
                    _buildHeroBottomBox('HOA Adds', '+${CurrencyFormatter.format(hoa, symbol: r'$')}'),
                    const SizedBox(width: 8),
                    _buildHeroBottomBox('Back-End DTI', '$dtiFmt%'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cost Breakdown Donut Chart
          Text(
            'Payment Breakdown',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Cost Composition',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Donut graphic
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CustomPaint(
                        painter: _HoaDonutPainter(
                          vals: [pi, taxMo, insMo, hoa],
                          colors: const [Color(0xFF1B3F72), Color(0xFFD97706), Color(0xFF15803D), Color(0xFF6D28D9)],
                          totalCost: total,
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow('P&I', pi, const Color(0xFF1B3F72)),
                          _buildLegendRow('Tax', taxMo, const Color(0xFFD97706)),
                          _buildLegendRow('Insurance', insMo, const Color(0xFF15803D)),
                          _buildLegendRow('HOA', hoa, const Color(0xFF6D28D9), isLast: true),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: AppTextStyles.dmSans(
                                        size: 11.5, weight: FontWeight.w800, color: textColor)),
                                Text(
                                  CurrencyFormatter.format(total, symbol: r'$'),
                                  style: AppTextStyles.playfair(
                                      size: 13, weight: FontWeight.w800, color: const Color(0xFF6D28D9)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // DTI Analysis Bar
          Text(
            'DTI Analysis',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Back-End DTI: ',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textColor)),
                    Text('$dtiFmt%',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w900, color: const Color(0xFF6D28D9))),
                    Text(' (with HOA)',
                        style: AppTextStyles.dmSans(size: 9.5, color: mutedColor)),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress DTI bar
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (dti / 50.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: dtiBarColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                    Text('28%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                    Text('36%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                    Text('43%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                    Text('50%+', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDtiZoneBox('Excellent', '≤36%', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
                    const SizedBox(width: 8),
                    _buildDtiZoneBox('Acceptable', '37–43%', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    _buildDtiZoneBox('High Risk', '>43%', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dtiStatus,
                          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 2),
                      Text(
                        'HOA adds ${CurrencyFormatter.format(hoa, symbol: r'$')}/mo which increases your DTI by $dtiIncrease percentage points',
                        style: AppTextStyles.dmSans(size: 9, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Buying Power Impact Chart
          Text(
            'Buying Power Impact',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Max Purchase Price at 43% DTI',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 12),
                // Custom drawn buying power comparisons
                _buildBuyingPowerRow('No HOA', mxNoHoa, max(1.0, mxNoHoa), const Color(0xFF15803D)),
                const SizedBox(height: 10),
                _buildBuyingPowerRow('With HOA', mxWithHoa, max(1.0, mxNoHoa), const Color(0xFFB91C1C)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildBuyingPowerBox('🏡', 'Max Price (No HOA)', CurrencyFormatter.compact(mxNoHoa, symbol: r'$'), 'Based on 43% DTI', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
                    const SizedBox(width: 8),
                    _buildBuyingPowerBox('📉', 'Max Price (With HOA)', CurrencyFormatter.compact(mxWithHoa, symbol: r'$'), 'Reduced by HOA', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Loss statement
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E1A47) : const Color(0xFFF3E8FF),
              border: Border.all(color: const Color(0x336D28D9)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOA reduces buying power by ~\$${bpLossK.toString().replaceAll('-', '')},000',
                  style: AppTextStyles.playfair(
                      size: 11, weight: FontWeight.w800, color: const Color(0xFF4C1D95)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Each \$100/mo in HOA fees typically reduces max purchase price by ~\$16,500',
                  style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF6D28D9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // National HOA averages (2025)
        Text(
          'National HOA Averages (2025)',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B2E0F) : const Color(0xFFFEF3C7),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏘️ HOA Fees by Community Type',
                style: AppTextStyles.playfair(
                    size: 12, weight: FontWeight.w800, color: const Color(0xFF92400E)),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.5,
                children: [
                  _buildAverageItem('Condo', '\$415'),
                  _buildAverageItem('Townhouse', '\$305'),
                  _buildAverageItem('SFR HOA', '\$188'),
                  _buildAverageItem('High-Rise', '\$812'),
                  _buildAverageItem('Luxury', '\$1,200+'),
                  _buildAverageItem('National', '\$291'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // HOA considerations
        Text(
          'HOA Considerations',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        _buildInfoCard('📋', 'What HOA Fees Cover', 'Exterior maintenance · amenities · landscaping · insurance', textColor, mutedColor, borderColor, cardColor, onTap: () => context.push('/usa/hoa-what-fees-cover')),
        _buildInfoCard('⚠️', 'HOA Reserve Fund Health', 'Check reserve study · underfunded HOAs = special assessments', textColor, mutedColor, borderColor, cardColor, onTap: () => context.push('/usa/hoa-reserve-fund-health')),
        _buildInfoCard('📈', 'HOA Fee Increases', 'Average 3–5% annual increase · factor into long-term budget', textColor, mutedColor, borderColor, cardColor, onTap: () => context.push('/usa/hoa-fee-increases')),
        _buildInfoCard('🏦', 'Lender Treatment', 'Counted in back-end DTI · FHA/VA/Conv. all include HOA', textColor, mutedColor, borderColor, cardColor, onTap: () => context.push('/usa/hoa-lender-treatment')),
      ],
    );
  }

  Widget _buildBuyingPowerRow(String label, double val, double maxVal, Color color) {
    final fillPct = (val / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 9.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context)),
          ),
        ),
        Expanded(
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillPct,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  CurrencyFormatter.compact(val, symbol: r'$'),
                  style: AppTextStyles.dmSans(
                      size: 10, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyingPowerBox(String icon, String label, String value, String sub, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textCol.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value,
                style: AppTextStyles.playfair(size: 18, weight: FontWeight.w800, color: textCol)),
            const SizedBox(height: 2),
            Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageItem(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF92400E), weight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(value,
              style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF7C2D12))),
        ],
      ),
    );
  }

  Widget _buildDtiZoneBox(String label, String val, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(String name, double val, Color color, {bool isLast = false}) {
    final textColor = widget.theme.getTextColor(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(name, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: textColor)),
            ],
          ),
          Text(
            CurrencyFormatter.format(val, symbol: r'$'),
            style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.w800, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputRow(String label, TextEditingController controller,
      {String? prefix, String? suffix}) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8.5, weight: FontWeight.w700, color: mutedColor, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (prefix != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    border: Border(right: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Text(prefix,
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: mutedColor)),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.playfair(
                        size: 14, weight: FontWeight.w800, color: textColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Text(suffix,
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedColor)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBottomBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String icon, String title, String subtitle, Color textColor,
      Color mutedColor, Color borderColor, Color cardColor, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.theme.getBgColor(context),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.playfair(
                        size: 12, weight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.dmSans(size: 9, color: mutedColor),
                  ),
                ],
              ),
            ),
            Text('›', style: TextStyle(fontSize: 16, color: mutedColor)),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Cost Breakdown Donut Chart
class _HoaDonutPainter extends CustomPainter {
  final List<double> vals;
  final List<Color> colors;
  final double totalCost;
  final Color textColor;
  final Color mutedColor;

  const _HoaDonutPainter({
    required this.vals,
    required this.colors,
    required this.totalCost,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    final total = vals.reduce((a, b) => a + b);
    if (total == 0) return;

    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < vals.length; i++) {
      final sweepAngle = (vals[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Draw central text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: 'Total'.toUpperCase(),
      style: AppTextStyles.dmSans(size: 7.5, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 8));

    textPainter.text = TextSpan(
      text: CurrencyFormatter.compact(totalCost, symbol: r'$'),
      style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 4));
  }

  @override
  bool shouldRepaint(covariant _HoaDonutPainter oldDelegate) {
    return oldDelegate.totalCost != totalCost ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}

