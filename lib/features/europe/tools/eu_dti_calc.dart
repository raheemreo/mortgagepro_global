// lib/features/europe/tools/eu_dti_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUDtiCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUDtiCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUDtiCalc> createState() => _EUDtiCalcState();
}

class _EUDtiCalcState extends ConsumerState<EUDtiCalc> {
  String _countryCode = 'DE';
  double _income = 5500;
  double _partnerIncome = 0;

  final TextEditingController _rentCtrl = TextEditingController(text: '1200');
  final TextEditingController _carCtrl = TextEditingController(text: '250');
  final TextEditingController _cardCtrl = TextEditingController(text: '80');
  final TextEditingController _studentCtrl = TextEditingController(text: '120');
  final TextEditingController _personalCtrl = TextEditingController(text: '0');
  final TextEditingController _otherCtrl = TextEditingController(text: '0');

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  // State variables for calculation output
  bool _hasCalculated = false;

  final Map<String, Map<String, dynamic>> _countryData = {
    'DE': {'name': 'Germany', 'max': 40.0, 'flag': '🇩🇪'},
    'FR': {'name': 'France', 'max': 35.0, 'flag': '🇫🇷'},
    'ES': {'name': 'Spain', 'max': 40.0, 'flag': '🇪🇸'},
    'IT': {'name': 'Italy', 'max': 40.0, 'flag': '🇮🇹'},
    'NL': {'name': 'Netherlands', 'max': 43.0, 'flag': '🇳🇱'},
    'PT': {'name': 'Portugal', 'max': 50.0, 'flag': '🇵🇹'},
  };

  final List<Map<String, dynamic>> _euLimits = [
    {'flag': '🇩🇪', 'name': 'Germany', 'max': 40.0, 'color': const Color(0xFF003399)},
    {'flag': '🇫🇷', 'name': 'France', 'max': 35.0, 'color': const Color(0xFF1E3A8A)},
    {'flag': '🇪🇸', 'name': 'Spain', 'max': 40.0, 'color': const Color(0xFFDC2626)},
    {'flag': '🇮🇹', 'name': 'Italy', 'max': 40.0, 'color': const Color(0xFF166534)},
    {'flag': '🇳🇱', 'name': 'Netherlands', 'max': 43.0, 'color': const Color(0xFF9A3412)},
    {'flag': '🇵🇹', 'name': 'Portugal', 'max': 50.0, 'color': const Color(0xFF4338CA)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _income = inputs['income'] ?? 5500.0;
      _partnerIncome = inputs['partnerIncome'] ?? 0.0;
      _rentCtrl.text = (inputs['rent'] ?? 1200.0).toStringAsFixed(0);
      _carCtrl.text = (inputs['car'] ?? 250.0).toStringAsFixed(0);
      _cardCtrl.text = (inputs['card'] ?? 80.0).toStringAsFixed(0);
      _studentCtrl.text = (inputs['student'] ?? 120.0).toStringAsFixed(0);
      _personalCtrl.text = (inputs['personal'] ?? 0.0).toStringAsFixed(0);
      _otherCtrl.text = (inputs['other'] ?? 0.0).toStringAsFixed(0);
      _countryCode = widget.savedCalc!.label.split(' - ').last;

      _calcSnapshot['income'] = _income;
      _calcSnapshot['partnerIncome'] = _partnerIncome;
      _calcSnapshot['rent'] = double.tryParse(_rentCtrl.text) ?? 1200.0;
      _calcSnapshot['car'] = double.tryParse(_carCtrl.text) ?? 250.0;
      _calcSnapshot['card'] = double.tryParse(_cardCtrl.text) ?? 80.0;
      _calcSnapshot['student'] = double.tryParse(_studentCtrl.text) ?? 120.0;
      _calcSnapshot['personal'] = double.tryParse(_personalCtrl.text) ?? 0.0;
      _calcSnapshot['other'] = double.tryParse(_otherCtrl.text) ?? 0.0;
      _calcSnapshot['countryCode'] = _countryCode;

      _hasCalculated = true;
    }
  }

  @override
  void dispose() {
    _rentCtrl.dispose();
    _carCtrl.dispose();
    _cardCtrl.dispose();
    _studentCtrl.dispose();
    _personalCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {}

  void _runCalc() {
    setState(() {
      _calcSnapshot['income'] = _income;
      _calcSnapshot['partnerIncome'] = _partnerIncome;
      _calcSnapshot['rent'] = double.tryParse(_rentCtrl.text) ?? 0.0;
      _calcSnapshot['car'] = double.tryParse(_carCtrl.text) ?? 0.0;
      _calcSnapshot['card'] = double.tryParse(_cardCtrl.text) ?? 0.0;
      _calcSnapshot['student'] = double.tryParse(_studentCtrl.text) ?? 0.0;
      _calcSnapshot['personal'] = double.tryParse(_personalCtrl.text) ?? 0.0;
      _calcSnapshot['other'] = double.tryParse(_otherCtrl.text) ?? 0.0;
      _calcSnapshot['countryCode'] = _countryCode;
      _hasCalculated = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _income = 5500;
      _partnerIncome = 0;
      _rentCtrl.text = '1200';
      _carCtrl.text = '250';
      _cardCtrl.text = '80';
      _studentCtrl.text = '120';
      _personalCtrl.text = '0';
      _otherCtrl.text = '0';
      _countryCode = 'DE';
      _hasCalculated = false;
      _calcSnapshot.clear();
    });
  }

  void _saveDTI() async {
    if (!_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Calculate first, then save!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double snapIncome = _calcSnapshot['income'] ?? _income;
    final double snapPartnerIncome = _calcSnapshot['partnerIncome'] ?? _partnerIncome;
    final double snapRent = _calcSnapshot['rent'] ?? 0.0;
    final double snapCar = _calcSnapshot['car'] ?? 0.0;
    final double snapCard = _calcSnapshot['card'] ?? 0.0;
    final double snapStudent = _calcSnapshot['student'] ?? 0.0;
    final double snapPersonal = _calcSnapshot['personal'] ?? 0.0;
    final double snapOther = _calcSnapshot['other'] ?? 0.0;
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final double totalInc = snapIncome + snapPartnerIncome;
    final double totalDebt = snapRent + snapCar + snapCard + snapStudent + snapPersonal + snapOther;
    final double dti = totalInc > 0 ? (totalDebt / totalInc) * 100 : 0.0;

    final labelCtrl = TextEditingController(text: 'Europe DTI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/eu_dti_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save DTI Result',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: DTI Ratio ${dti.toStringAsFixed(1)}% · Combined Income ${CurrencyFormatter.compact(totalInc, symbol: '€')}',
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
                hintText: 'Label (e.g. Budget Plan)',
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
            child: const Text('Save',
                style: TextStyle(
                    fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'Europe DTI';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'DTI Calc',
        inputs: {
          'income': snapIncome,
          'partnerIncome': snapPartnerIncome,
          'rent': snapRent,
          'car': snapCar,
          'card': snapCard,
          'student': snapStudent,
          'personal': snapPersonal,
          'other': snapOther,
        },
        results: {
          'DTI': dti,
          'Income': totalInc,
          'Debt': totalDebt,
          'Status': dti <= (_countryData[snapCountryCode]?['max'] ?? 40.0) ? 1.0 : 0.0,
        },
        label: '$label - $snapCountryCode',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ DTI calculation saved!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedText = theme.getMutedColor(context);

    final double currentTotalInc = _income + _partnerIncome;
    final double currentTotalDebt = (double.tryParse(_rentCtrl.text) ?? 0.0) +
        (double.tryParse(_carCtrl.text) ?? 0.0) +
        (double.tryParse(_cardCtrl.text) ?? 0.0) +
        (double.tryParse(_studentCtrl.text) ?? 0.0) +
        (double.tryParse(_personalCtrl.text) ?? 0.0) +
        (double.tryParse(_otherCtrl.text) ?? 0.0);

    final double snapIncome = _calcSnapshot['income'] ?? _income;
    final double snapPartnerIncome = _calcSnapshot['partnerIncome'] ?? _partnerIncome;
    final double snapRent = _calcSnapshot['rent'] ?? (double.tryParse(_rentCtrl.text) ?? 0.0);
    final double snapCar = _calcSnapshot['car'] ?? (double.tryParse(_carCtrl.text) ?? 0.0);
    final double snapCard = _calcSnapshot['card'] ?? (double.tryParse(_cardCtrl.text) ?? 0.0);
    final double snapStudent = _calcSnapshot['student'] ?? (double.tryParse(_studentCtrl.text) ?? 0.0);
    final double snapPersonal = _calcSnapshot['personal'] ?? (double.tryParse(_personalCtrl.text) ?? 0.0);
    final double snapOther = _calcSnapshot['other'] ?? (double.tryParse(_otherCtrl.text) ?? 0.0);
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final double totalInc = snapIncome + snapPartnerIncome;
    final double totalDebt = snapRent + snapCar + snapCard + snapStudent + snapPersonal + snapOther;
    final double dti = totalInc > 0 ? (totalDebt / totalInc) * 100 : 0.0;

    final countryInfo = _countryData[snapCountryCode]!;
    final double maxDTI = countryInfo['max'];
    final String countryName = countryInfo['name'];

    Color ratingColor;
    String statusText;
    String subText;

    if (dti <= 35) {
      ratingColor = Colors.green;
      statusText = '✅ Excellent';
      subText = 'Well within $countryName limit (${maxDTI.toStringAsFixed(0)}%)';
    } else if (dti <= maxDTI) {
      ratingColor = Colors.orange;
      statusText = '⚠️ Acceptable';
      subText = 'Within $countryName limit (${maxDTI.toStringAsFixed(0)}%)';
    } else if (dti <= 50) {
      ratingColor = Colors.orange.shade700;
      statusText = '🔶 Caution';
      subText = 'Exceeds $countryName guideline of ${maxDTI.toStringAsFixed(0)}%';
    } else {
      ratingColor = Colors.red;
      statusText = '❌ High Risk';
      subText = 'Likely to be declined by EU lenders';
    }

    final maxMonthlyDebt = totalInc * (maxDTI / 100);
    final headroom = math.max(0.0, maxMonthlyDebt - totalDebt);

    final isDirty = _hasCalculated && (
      _income != snapIncome ||
      _partnerIncome != snapPartnerIncome ||
      (double.tryParse(_rentCtrl.text) ?? 0.0) != snapRent ||
      (double.tryParse(_carCtrl.text) ?? 0.0) != snapCar ||
      (double.tryParse(_cardCtrl.text) ?? 0.0) != snapCard ||
      (double.tryParse(_studentCtrl.text) ?? 0.0) != snapStudent ||
      (double.tryParse(_personalCtrl.text) ?? 0.0) != snapPersonal ||
      (double.tryParse(_otherCtrl.text) ?? 0.0) != snapOther ||
      _countryCode != snapCountryCode
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sliderActiveColor = isDark ? theme.accentColor : theme.primaryColor;
    final sliderInactiveColor = (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15);

    // Live ECB rate
    final liveEcb = ref.watch(europeRatesProvider).valueOrNull?.ecbRate.value ?? 4.00;
    final isLive = ref.watch(europeRatesProvider).valueOrNull?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live DTI Strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dtiLimitStripItem('🇩🇪 Max DTI', '40%', 'Germany'),
              _dtiLimitDivider(),
              _dtiLimitStripItem('🇫🇷 Max DTI', '35%', 'France (HCSF)'),
              _dtiLimitDivider(),
              _dtiLimitStripItem('🇪🇸 Max DTI', '40%', 'Spain'),
              _dtiLimitDivider(),
              _dtiLimitStripItem('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Rate'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Country Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COUNTRY & INCOME', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
            GestureDetector(
              onTap: _reset,
              child: Text('Reset', style: AppTextStyles.dmSans(size: 11, color: theme.primaryColor, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _countryData.keys.map((code) {
              final active = _countryCode == code;
              final data = _countryData[code]!;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _countryCode = code;
                    _markDirty();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? theme.primaryColor : cardBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: active ? theme.primaryColor : borderCol),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${data['flag']} ${data['name']}',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: active ? theme.accentColor : theme.getMutedColor(context),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Income Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💼 Monthly Gross Income', style: AppTextStyles.cardTitle(textColor)),
              const SizedBox(height: 14),

              // Gross Monthly Income
              _sliderHeader('Your Gross Monthly Income', CurrencyFormatter.format(_income, symbol: '€')),
              Slider(
                value: _income,
                min: 1000,
                max: 20000,
                divisions: 190,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) {
                  setState(() {
                    _income = v;
                    _markDirty();
                  });
                },
              ),

              // Partner Monthly Income
              _sliderHeader('Partner Income (Optional)', CurrencyFormatter.format(_partnerIncome, symbol: '€')),
              Slider(
                value: _partnerIncome,
                min: 0,
                max: 15000,
                divisions: 150,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) {
                  setState(() {
                    _partnerIncome = v;
                    _markDirty();
                  });
                },
              ),

              if (_partnerIncome > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Combined Monthly Income', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText)),
                      Text(CurrencyFormatter.format(currentTotalInc, symbol: '€'),
                          style: AppTextStyles.playfair(
                              size: 15,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? theme.accentColor
                                  : theme.primaryColor,
                              weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Debt Payments Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋 Monthly Debt Payments', style: AppTextStyles.cardTitle(textColor)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _debtInputBox('Mortgage / Rent', _rentCtrl),
                  _debtInputBox('Car Loan', _carCtrl),
                  _debtInputBox('Credit Cards', _cardCtrl),
                  _debtInputBox('Student Loan', _studentCtrl),
                  _debtInputBox('Personal Loan', _personalCtrl),
                  _debtInputBox('Other Debt', _otherCtrl),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Monthly Debt', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText)),
                    Text(CurrencyFormatter.format(currentTotalDebt, symbol: '€'),
                        style: AppTextStyles.playfair(
                            size: 15,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? theme.accentColor
                                : theme.primaryColor,
                            weight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003399), Color(0xFF1A0040)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003399).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _runCalc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📐', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Calculate DTI',
                        style: AppTextStyles.playfair(size: 14, color: const Color(0xFFFFCC00), weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _saveDTI,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: !_hasCalculated ? Colors.grey.shade200 : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: !_hasCalculated ? Colors.transparent : theme.primaryColor,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '💾',
                  style: TextStyle(
                    fontSize: 20,
                    color: !_hasCalculated ? Colors.grey : theme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Results Section
        if (_hasCalculated)
          Column(
            key: _resultsKey,
            children: [
              if (isDirty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Inputs have changed. Calculate again to update results.',
                          style: AppTextStyles.dmSans(
                            size: 11.5,
                            color: const Color(0xFFB45309),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Gauge Results Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text('📈 Your DTI Score', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      width: 210,
                      child: CustomPaint(
                        painter: DTIGaugePainter(
                          dti: dti,
                          limit: maxDTI,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                        child: Container(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dti.toStringAsFixed(1)}%',
                      style: AppTextStyles.playfair(size: 34, color: ratingColor, weight: FontWeight.w900),
                    ),
                    Text(
                      statusText,
                      style: AppTextStyles.dmSans(size: 14, color: ratingColor, weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: AppTextStyles.dmSans(size: 11, color: mutedText),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _bandBox('Excellent\n≤35%', Colors.green, dti <= 35),
                        const SizedBox(width: 4),
                        _bandBox('Good\n36–43%', Colors.orange, dti > 35 && dti <= 43),
                        const SizedBox(width: 4),
                        _bandBox('Caution\n44–50%', Colors.orange.shade800, dti > 43 && dti <= 50),
                        const SizedBox(width: 4),
                        _bandBox('High Risk\n50%+', Colors.red, dti > 50),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mini Stats Card Grid
              Row(
                children: [
                  _miniStatBox('Your DTI', '${dti.toStringAsFixed(1)}%', ratingColor),
                  const SizedBox(width: 8),
                  _miniStatBox('Max Budget', CurrencyFormatter.compact(maxMonthlyDebt, symbol: '€'), Theme.of(context).brightness == Brightness.dark ? theme.accentColor : theme.primaryColor),
                  const SizedBox(width: 8),
                  _miniStatBox('Headroom', CurrencyFormatter.compact(headroom, symbol: '€'), headroom > 0 ? Colors.green : Colors.red),
                ],
              ),
              const SizedBox(height: 16),

              // Stacked Allocation Bar Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💰 Income Allocation', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 6),
                    Text('Monthly gross income breakdown', style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 24,
                        width: double.infinity,
                        color: Colors.green,
                        child: Row(
                          children: [
                            if (dti > 0)
                              Flexible(
                                flex: dti.round(),
                                child: Container(
                                  color: ratingColor,
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    child: Text(
                                      '${dti.toStringAsFixed(0)}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            Flexible(
                              flex: (100 - math.min(100.0, dti)).round(),
                              child: Container(
                                color: Colors.green,
                                alignment: Alignment.center,
                                child: FittedBox(
                                  child: Text(
                                    '${(100 - math.min(100.0, dti)).toStringAsFixed(0)}%',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _legendDot(ratingColor, 'Debt (${dti.toStringAsFixed(1)}%)'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.green, 'Free Income (${(100 - math.min(100.0, dti)).toStringAsFixed(1)}%)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Itemized Debt Breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔍 Payment Breakdown', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 14),
                    _buildDebtBreakdownList(theme, cardBg),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Headroom checks against other EU countries
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏳️ Your DTI vs EU Country Limits', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 14),
                    ..._euLimits.map((limitInfo) {
                      final double limitVal = limitInfo['max'];
                      final double pctOfLimit = totalInc > 0 ? math.min((dti / limitVal) * 100, 130.0) : 0.0;
                      final bool overLimit = dti > limitVal;
                      final Color fillCol = overLimit ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? theme.accentColor : theme.primaryColor);
                      final statusLabel = overLimit
                          ? '❌ Over limit by ${(dti - limitVal).toStringAsFixed(1)}%'
                          : '✅ ${(limitVal - dti).toStringAsFixed(1)}% headroom';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${limitInfo['flag']} ${limitInfo['name']} (Limit: ${limitVal.toStringAsFixed(0)}%)',
                                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: textColor)),
                                Text(statusLabel,
                                    style: AppTextStyles.dmSans(
                                        size: 10.5,
                                        weight: FontWeight.bold,
                                        color: overLimit ? Colors.red : Colors.green.shade800)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 8,
                                width: double.infinity,
                                color: theme.getBgColor(context),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: math.min(pctOfLimit / 100, 1.0),
                                    child: Container(color: fillCol),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Personalized Smart Insight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [theme.primaryColor.withValues(alpha: 0.7), theme.primaryColor.withValues(alpha: 0.5)]
                        : [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Smart Insight', style: AppTextStyles.cardTitle(Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      dti <= 35
                          ? '🟢 Strong Financial Position'
                          : dti <= maxDTI
                              ? '🟡 Borderline Acceptable'
                              : '🔴 Exceeds Country Limit',
                      style: AppTextStyles.dmSans(size: 13, color: const Color(0xFFFFCC00), weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dti <= 35
                          ? 'Your DTI of ${dti.toStringAsFixed(1)}% qualifies you with all major EU lenders. You have ${CurrencyFormatter.compact(headroom, symbol: '€')}/month headroom before hitting limit.'
                          : dti <= maxDTI
                              ? 'You qualify but are approaching the limit. Reducing monthly debt by ${CurrencyFormatter.compact(totalDebt - totalInc * 0.35, symbol: '€')} would put you in the "Excellent" range.'
                              : 'Your DTI of ${dti.toStringAsFixed(1)}% is above the ${maxDTI.toStringAsFixed(0)}% guideline. Consider paying down credit cards or personal loans first.',
                      style: AppTextStyles.dmSans(size: 11.5, color: Colors.white.withValues(alpha: 0.95), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // EU Lender Limits guidelines card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏛️ EU Lender DTI Limits (2025)', style: AppTextStyles.cardTitle(Colors.white)),
                    const SizedBox(height: 14),
                    _euLenderLimitRow('🇩🇪 Germany – BaFin Guidelines', 'No hard cap; 40% common practice', '40%', 0.57),
                    _euLenderLimitRow('🇫🇷 France – HCSF Regulation', 'Hard cap enforced since Jan 2022', '35%', 0.50),
                    _euLenderLimitRow('🇪🇸 Spain – Banco de España', 'Max 40% recommended', '40%', 0.57),
                    _euLenderLimitRow('🇳🇱 Netherlands – NHG Rules', 'Up to 43% with NHG guarantee', '43%', 0.61),
                    _euLenderLimitRow('🇵🇹 Portugal – Banco de Portugal', 'Max 50% (36% preferred)', '50%', 0.71),
                  ],
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                const Text('⚖️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Calculate DTI Ratio',
                    style: AppTextStyles.playfair(
                        size: 15, weight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  'Enter your monthly gross income and current monthly debts,\nthen tap Calculate DTI to see your debt-to-income ratio guidelines.',
                  style: AppTextStyles.dmSans(size: 11, color: mutedText, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dtiLimitStripItem(String label, String val, String subtitle) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
        const SizedBox(height: 1),
        Text(subtitle, style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _dtiLimitDivider() {
    return Container(
      width: 0.5,
      height: 26,
      color: widget.theme.getBorderColor(context),
    );
  }

  Widget _sliderHeader(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))),
          Text(value, style: AppTextStyles.playfair(
              size: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? widget.theme.accentColor
                  : widget.theme.primaryColor,
              weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _debtInputBox(String label, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8.0, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _markDirty(),
          ),
        ],
      ),
    );
  }

  Widget _bandBox(String label, Color col, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: active ? col.withValues(alpha: 0.12) : widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? col : widget.theme.getBorderColor(context), width: active ? 1.5 : 1.0),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.bold,
            color: active ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : col) : widget.theme.getTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _miniStatBox(String label, String value, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.theme.getCardColor(context),
          border: Border.all(color: widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.playfair(size: 15, color: col, weight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color col, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
      ],
    );
  }

  Widget _buildDebtBreakdownList(CountryTheme theme, Color cardBg) {
    final double snapIncome = _calcSnapshot['income'] ?? _income;
    final double snapPartnerIncome = _calcSnapshot['partnerIncome'] ?? _partnerIncome;
    final double snapRent = _calcSnapshot['rent'] ?? 0.0;
    final double snapCar = _calcSnapshot['car'] ?? 0.0;
    final double snapCard = _calcSnapshot['card'] ?? 0.0;
    final double snapStudent = _calcSnapshot['student'] ?? 0.0;
    final double snapPersonal = _calcSnapshot['personal'] ?? 0.0;
    final double snapOther = _calcSnapshot['other'] ?? 0.0;
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final double totalInc = snapIncome + snapPartnerIncome;
    final double totalDebt = snapRent + snapCar + snapCard + snapStudent + snapPersonal + snapOther;
    final double dti = totalInc > 0 ? (totalDebt / totalInc) * 100 : 0.0;

    final List<Map<String, dynamic>> debts = [
      {'name': 'Mortgage / Rent', 'color': const Color(0xFF003399), 'val': snapRent},
      {'name': 'Car Loan', 'color': const Color(0xFF6D28D9), 'val': snapCar},
      {'name': 'Credit Cards', 'color': const Color(0xFFFFCC00), 'val': snapCard},
      {'name': 'Student Loan', 'color': const Color(0xFF0F766E), 'val': snapStudent},
      {'name': 'Personal Loan', 'color': const Color(0xFFB45309), 'val': snapPersonal},
      {'name': 'Other', 'color': const Color(0xFF6B21A8), 'val': snapOther},
    ].where((d) => (d['val'] as double) > 0.0).toList();

    if (debts.isEmpty) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No debt entries — add amounts above',
          style: AppTextStyles.dmSans(size: 12, color: theme.getMutedColor(context)),
        ),
      );
    }

    final double countryMax = _countryData[snapCountryCode]?['max'] ?? 40.0;

    return Column(
      children: [
        ...debts.map((d) {
          final double val = d['val'];
          final double pct = totalInc > 0 ? (val / totalInc) * 100 : 0.0;
          final double barW = totalInc > 0
              ? math.min((val / totalInc) * 100 / countryMax * 100, 100.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.getBgColor(context),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: d['color'], borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d['name'], style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: theme.getTextColor(context))),
                      ),
                      Text(CurrencyFormatter.format(val, symbol: '€'),
                          style: AppTextStyles.playfair(
                              size: 13,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? theme.accentColor
                                  : theme.primaryColor,
                              weight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(1)}%', style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: barW / 100,
                          child: Container(color: d['color']),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        (() {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final totalBg = isDark ? theme.primaryColor.withValues(alpha: 0.12) : const Color(0xFFEEF2FF);
          final totalBorder = isDark ? theme.primaryColor.withValues(alpha: 0.35) : const Color(0xFF818CF8);
          final totalText = isDark ? theme.accentColor : const Color(0xFF4338CA);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: totalBg,
              border: Border.all(color: totalBorder),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: totalText,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Total Debt', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: totalText)),
                ),
                Text(CurrencyFormatter.format(totalDebt, symbol: '€'),
                    style: AppTextStyles.playfair(size: 13, color: totalText, weight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text('${dti.toStringAsFixed(1)}%', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: totalText)),
              ],
            ),
          );
        })(),
      ],
    );
  }

  Widget _euLenderLimitRow(String label, String note, String limitText, double fillVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(note, style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
              Text(limitText, style: AppTextStyles.playfair(size: 14, color: const Color(0xFFFFCC00), weight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: Colors.white.withValues(alpha: 0.15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fillVal,
                  child: Container(color: const Color(0xFFFFCC00).withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DTIGaugePainter extends CustomPainter {
  final double dti;
  final double limit;
  final bool isDark;

  DTIGaugePainter({
    required this.dti,
    required this.limit,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 15);
    final radius = size.width / 2 - 15;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = Colors.grey.withValues(alpha: 0.15);

    // Draw track
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    final double fillPct = (dti / 70.0).clamp(0.0, 1.0);
    final double sweepAngle = fillPct * math.pi;

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const gradient = LinearGradient(
      colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
    );
    fillPaint.shader = gradient.createShader(rect);

    if (sweepAngle > 0.0) {
      canvas.drawArc(rect, math.pi, sweepAngle, false, fillPaint);
    }

    // Limit marker
    final double limitPct = (limit / 70.0).clamp(0.0, 1.0);
    final double limitAngle = math.pi + limitPct * math.pi;
    final markerPaint = Paint()
      ..color = Colors.orange.shade900
      ..style = PaintingStyle.fill;
    final markerCenter = Offset(
      center.dx + radius * math.cos(limitAngle),
      center.dy + radius * math.sin(limitAngle),
    );
    canvas.drawCircle(markerCenter, 4.5, markerPaint);

    // Needle
    final needlePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF1A0040)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double needleAngle = math.pi + fillPct * math.pi;
    final needleEnd = Offset(
      center.dx + (radius - 12) * math.cos(needleAngle),
      center.dy + (radius - 12) * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    // Center cap
    canvas.drawCircle(center, 5.0, needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
