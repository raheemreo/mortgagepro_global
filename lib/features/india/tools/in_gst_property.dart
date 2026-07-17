// lib/features/india/tools/in_gst_property.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INGSTProperty extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INGSTProperty({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INGSTProperty> createState() => _INGSTPropertyState();
}

class _INGSTPropertyState extends ConsumerState<INGSTProperty> {
  // Input states
  double _propValue = 4500000; // default ₹45 Lakhs
  double _sdRate = 5.0; // default 5%
  double _regFeePct = 1.0; // default 1%
  String _cityType = 'metro'; // metro, nonmetro
  double _carpetArea = 55.0; // default 55 sqm
  String _selectedType = 'uc'; // uc, rp, aff, plot

  // Controllers
  late TextEditingController _propValueCtrl;
  late TextEditingController _sdRateCtrl;
  late TextEditingController _regFeePctCtrl;
  late TextEditingController _carpetAreaCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultPanelKey = GlobalKey();

  bool _calculated = false;

  // Validation error flags
  bool _propValueError = false;
  bool _sdRateError = false;
  bool _regFeePctError = false;
  bool _carpetAreaError = false;

  // Frozen calculation inputs
  double _calcPropValue = 4500000;
  double _calcSdRate = 5.0;
  double _calcRegFeePct = 1.0;
  String _calcCityType = 'metro';
  double _calcCarpetArea = 55.0;
  String _calcSelectedType = 'uc';

  final Map<String, _GstPropTypeData> _typeData = {
    'uc': _GstPropTypeData(
      icon: '🏗️',
      name: 'Under-Construction',
      rate: 5.0,
      desc: 'New flat/apartment before receiving OC from builder',
      themeColor: const Color(0xFFFF6B00),
    ),
    'rp': _GstPropTypeData(
      icon: '🏠',
      name: 'Ready Possession',
      rate: 0.0,
      desc: 'OC received or resale property — no GST applicable',
      themeColor: const Color(0xFF046A38),
    ),
    'aff': _GstPropTypeData(
      icon: '🏘️',
      name: 'Affordable Housing',
      rate: 1.0,
      desc: 'Metro ≤60 sqm / Non-metro ≤90 sqm AND value ≤₹45L',
      themeColor: const Color(0xFF1D4ED8),
    ),
    'plot': _GstPropTypeData(
      icon: '🗺️',
      name: 'Plot / Land',
      rate: 0.0,
      desc: 'Bare land sale — GST exempt from transactions',
      themeColor: const Color(0xFF7C3AED),
    ),
  };

  @override
  void initState() {
    super.initState();
    _propValueCtrl = TextEditingController(text: _propValue.toStringAsFixed(0));
    _sdRateCtrl = TextEditingController(text: _sdRate.toStringAsFixed(1));
    _regFeePctCtrl = TextEditingController(text: _regFeePct.toStringAsFixed(1));
    _carpetAreaCtrl =
        TextEditingController(text: _carpetArea.toStringAsFixed(0));

    _propValueCtrl.addListener(_onInputChanged);
    _sdRateCtrl.addListener(_onInputChanged);
    _regFeePctCtrl.addListener(_onInputChanged);
    _carpetAreaCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _propValueCtrl.removeListener(_onInputChanged);
    _sdRateCtrl.removeListener(_onInputChanged);
    _regFeePctCtrl.removeListener(_onInputChanged);
    _carpetAreaCtrl.removeListener(_onInputChanged);

    _propValueCtrl.dispose();
    _sdRateCtrl.dispose();
    _regFeePctCtrl.dispose();
    _carpetAreaCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  bool _areInputsChanged() {
    final propVal = double.tryParse(_propValueCtrl.text) ?? 0.0;
    final sdVal = double.tryParse(_sdRateCtrl.text) ?? 0.0;
    final regVal = double.tryParse(_regFeePctCtrl.text) ?? 0.0;
    final carpetVal = double.tryParse(_carpetAreaCtrl.text) ?? 0.0;

    return propVal != _calcPropValue ||
        sdVal != _calcSdRate ||
        regVal != _calcRegFeePct ||
        carpetVal != _calcCarpetArea ||
        _cityType != _calcCityType ||
        _selectedType != _calcSelectedType;
  }

  void _reset() {
    setState(() {
      _propValue = 4500000;
      _sdRate = 5.0;
      _regFeePct = 1.0;
      _cityType = 'metro';
      _carpetArea = 55.0;
      _selectedType = 'uc';

      _propValueCtrl.text = '4500000';
      _sdRateCtrl.text = '5.0';
      _regFeePctCtrl.text = '1.0';
      _carpetAreaCtrl.text = '55';

      _calculated = false;
      _propValueError = false;
      _sdRateError = false;
      _regFeePctError = false;
      _carpetAreaError = false;

      _calcPropValue = 4500000;
      _calcSdRate = 5.0;
      _calcRegFeePct = 1.0;
      _calcCityType = 'metro';
      _calcCarpetArea = 55.0;
      _calcSelectedType = 'uc';
    });
  }

  void _saveGstCalculation() async {
    final double gstRate = _typeData[_calcSelectedType]!.rate / 100;
    final gstAmt = _calcPropValue * gstRate;
    final sdAmt = _calcPropValue * (_calcSdRate / 100);
    final regAmt = _calcPropValue * (_calcRegFeePct / 100);
    final totalAmt = _calcPropValue + gstAmt + sdAmt + regAmt;
    final extraAmt = gstAmt + sdAmt + regAmt;

    final typeName = _typeData[_calcSelectedType]!.name;

    final labelCtrl = TextEditingController(text: 'GST Outflow - $typeName');

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_gst_property'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save GST Outflow Report',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: ${_fmt(totalAmt)} all-in cost for $typeName',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Flat Purchase)',
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
          : 'GST Outflow Report';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Property GST Outflow',
        inputs: {
          'propertyValue': _calcPropValue,
          'gstRate': _typeData[_calcSelectedType]!.rate,
          'stampDutyRate': _calcSdRate,
          'registrationRate': _calcRegFeePct,
          'carpetArea': _calcCarpetArea,
          'isMetro': _calcCityType == 'metro' ? 1.0 : 0.0,
        },
        results: {
          'gstAmount': gstAmt,
          'stampDuty': sdAmt,
          'registration': regAmt,
          'totalOutflow': totalAmt,
          'extraCharges': extraAmt,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Outflow report saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  void _calculateAndScroll() {
    setState(() {
      _propValueError = false;
      _sdRateError = false;
      _regFeePctError = false;
      _carpetAreaError = false;
    });

    final propVal = double.tryParse(_propValueCtrl.text) ?? 0.0;
    final sdVal = double.tryParse(_sdRateCtrl.text) ?? 0.0;
    final regVal = double.tryParse(_regFeePctCtrl.text) ?? 0.0;
    final carpetVal = double.tryParse(_carpetAreaCtrl.text) ?? 0.0;

    bool hasErr = false;
    if (propVal <= 0) {
      setState(() => _propValueError = true);
      hasErr = true;
    }
    if (sdVal < 0 || sdVal > 50) {
      setState(() => _sdRateError = true);
      hasErr = true;
    }
    if (regVal < 0 || regVal > 50) {
      setState(() => _regFeePctError = true);
      hasErr = true;
    }
    if (carpetVal <= 0) {
      setState(() => _carpetAreaError = true);
      hasErr = true;
    }

    if (hasErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Please correct the invalid fields in red.', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _calculated = true;
      _calcPropValue = propVal;
      _calcSdRate = sdVal;
      _calcRegFeePct = regVal;
      _calcCarpetArea = carpetVal;
      _calcCityType = _cityType;
      _calcSelectedType = _selectedType;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultPanelKey.currentContext;
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

    final double gstRate = _typeData[_calcSelectedType]!.rate / 100;
    final gstAmt = _calcPropValue * gstRate;
    final sdAmt = _calcPropValue * (_calcSdRate / 100);
    final regAmt = _calcPropValue * (_calcRegFeePct / 100);
    final totalAmt = _calcPropValue + gstAmt + sdAmt + regAmt;
    final extraAmt = gstAmt + sdAmt + regAmt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF9A3412),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('Under-Constr.', '5%', 'Standard', isSaffron: true),
              _infoCell('Affordable', '1%', '<₹45L Value', isGreen: true),
              _infoCell('Ready Flat', 'NIL', 'Possession'),
              _infoCell('ITC', 'N/A', 'Not Claimable'),
            ],
          ),
        ),

        // Title Section
        Text('Select Property Type',
            style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        // 2x2 Selector Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.15,
          children: _typeData.entries.map((e) {
            final isSelected = _selectedType == e.key;
            final d = e.value;
            final cardColor = isSelected
                ? d.themeColor.withValues(alpha: 0.12)
                : theme.getCardColor(context);
            final borderColor =
                isSelected ? d.themeColor : theme.getBorderColor(context);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = e.key;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(
                      color: borderColor, width: isSelected ? 2.2 : 1.0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 5),
                        Text(d.name,
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('GST: ${d.rate.toStringAsFixed(0)}%',
                            style: AppTextStyles.dmSans(
                                size: 11.5,
                                weight: FontWeight.w800,
                                color: d.themeColor)),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(d.desc,
                              style: AppTextStyles.dmSans(
                                  size: 7.5,
                                  color: theme.getMutedColor(context)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                              color: d.themeColor, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Form Card Setup
        Text('Enter Property Details',
            style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9A3412), Color(0xFFC2410C), Color(0xFFFF6B00)],
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
                  Text('📊 GST CALCULATION',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: Colors.white70,
                          weight: FontWeight.w700)),
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
              const SizedBox(height: 14),

              // Property Value synced text-slider
              _buildSyncedInputRow(
                label: 'PROPERTY VALUE / AGREEMENT VALUE',
                controller: _propValueCtrl,
                value: _propValue,
                min: 500000,
                max: 50000000, // 5 Cr max
                prefix: '₹ ',
                hasError: _propValueError,
                onChangedText: (v) {
                  setState(() {
                    _propValue = v;
                  });
                },
                onChangedSlider: (v) {
                  setState(() {
                    _propValue = v;
                    _propValueCtrl.text = v.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Stamp Duty & Registration inputs
              Row(
                children: [
                  Expanded(
                    child: _buildSyncedInputRow(
                      label: 'STAMP DUTY RATE (%)',
                      controller: _sdRateCtrl,
                      value: _sdRate,
                      min: 0.0,
                      max: 15.0,
                      suffix: '%',
                      hasError: _sdRateError,
                      onChangedText: (v) {
                        setState(() {
                          _sdRate = v;
                        });
                      },
                      onChangedSlider: (v) {
                        setState(() {
                          _sdRate = v;
                          _sdRateCtrl.text = v.toStringAsFixed(1);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSyncedInputRow(
                      label: 'REGISTRATION RATE (%)',
                      controller: _regFeePctCtrl,
                      value: _regFeePct,
                      min: 0.0,
                      max: 5.0,
                      suffix: '%',
                      hasError: _regFeePctError,
                      onChangedText: (v) {
                        setState(() {
                          _regFeePct = v;
                        });
                      },
                      onChangedSlider: (v) {
                        setState(() {
                          _regFeePct = v;
                          _regFeePctCtrl.text = v.toStringAsFixed(1);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // City Type Dropdown & Carpet Area slider
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CITY TYPE',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white70,
                                weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cityType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF9A3412),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: 'metro', child: Text('Metro City')),
                                DropdownMenuItem(
                                    value: 'nonmetro',
                                    child: Text('Non-Metro')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _cityType = v;
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
                    child: _buildSyncedInputRow(
                      label: 'CARPET AREA (SQM)',
                      controller: _carpetAreaCtrl,
                      value: _carpetArea,
                      min: 10.0,
                      max: 300.0,
                      suffix: ' sqm',
                      hasError: _carpetAreaError,
                      onChangedText: (v) {
                        setState(() {
                          _carpetArea = v;
                        });
                      },
                      onChangedSlider: (v) {
                        setState(() {
                          _carpetArea = v;
                          _carpetAreaCtrl.text = v.toStringAsFixed(0);
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _calculateAndScroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('📋 Calculate GST & Total Cost',
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_calculated) ...[
          const SizedBox(height: 20),
          // Warning banner if inputs changed
          if (_areInputsChanged())
            Container(
              key: _resultPanelKey,
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
                      'Inputs changed. Tap Calculate GST & Total Cost to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultPanelKey, height: 0),

          // Calculated Results Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '📊 ${_typeData[_calcSelectedType]!.name}',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveGstCalculation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF046A38), Color(0xFF07543A)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Save',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: Colors.white,
                                weight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2x3 Grid of results
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 1.6,
                  children: [
                    _resBoxSummary(
                        'GST Amount',
                        _fmt(gstAmt),
                        '${_typeData[_calcSelectedType]!.rate.toStringAsFixed(0)}% GST rate',
                        const Color(0xFFFF6B00),
                        context,
                        highlight: true),
                    _resBoxSummary(
                        'Property Value',
                        _fmt(_calcPropValue),
                        'Agreement Value',
                        theme.getTextColor(context),
                        context),
                    _resBoxSummary(
                        'Stamp Duty',
                        _fmt(sdAmt),
                        '${_calcSdRate.toStringAsFixed(1)}% state rate',
                        const Color(0xFF0B1F48),
                        context),
                    _resBoxSummary(
                        'Registration',
                        _fmt(regAmt),
                        '${_calcRegFeePct.toStringAsFixed(1)}% SRO rate',
                        const Color(0xFF046A38),
                        context),
                    _resBoxSummary('Total Outflow', _fmt(totalAmt),
                        'All-in cost', const Color(0xFF9A3412), context,
                        highlight: true),
                    _resBoxSummary(
                        'Extra over Value',
                        _fmt(extraAmt),
                        'Taxes + fees total',
                        theme.getTextColor(context),
                        context),
                  ],
                ),
                const SizedBox(height: 16),

                // Cost Breakdown progress bars
                Text('📊 Total Cost Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                _costBreakdownBar(
                    'Property Value',
                    _calcPropValue,
                    totalAmt,
                    const LinearGradient(
                        colors: [Color(0xFF1A3A8F), Color(0xFF0D9488)])),
                _costBreakdownBar(
                    'Stamp Duty',
                    sdAmt,
                    totalAmt,
                    const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFE05A00)])),
                _costBreakdownBar(
                    'Registration',
                    regAmt,
                    totalAmt,
                    const LinearGradient(
                        colors: [Color(0xFF046A38), Color(0xFF10B981)])),
                _costBreakdownBar(
                    'GST',
                    gstAmt,
                    totalAmt,
                    const LinearGradient(
                        colors: [Color(0xFFC2410C), Color(0xFF9A3412)])),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // GST Rates Table
          Text('GST Rates — All Property Types',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 8),

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
                Text('📋 India GST on Real Estate (2025)',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                _gstRateTableRow(
                    '🏗️',
                    'Under-Construction (Standard)',
                    'New flat/apartment before receiving OC',
                    '5%',
                    const Color(0xFFFF6B00)),
                _gstRateTableRow(
                    '🏘️',
                    'Affordable Housing',
                    'Metro ≤60 sqm, Non-metro ≤90 sqm, Value ≤₹45L',
                    '1%',
                    const Color(0xFF1D4ED8)),
                _gstRateTableRow(
                    '🏠',
                    'Ready Possession / Resale',
                    'OC received or resale — GST exempt',
                    'NIL',
                    const Color(0xFF046A38)),
                _gstRateTableRow(
                    '🗺️',
                    'Plot / Land Purchase',
                    'Bare land purchase — GST exempt',
                    'NIL',
                    const Color(0xFF046A38)),
                _gstRateTableRow(
                    '🏢',
                    'Commercial Property (UC)',
                    'Under-construction commercial spaces (offices/shops)',
                    '12%',
                    const Color(0xFFC2410C)),
                _gstRateTableRow(
                    '🏬',
                    'Long-term Lease (>30 yrs)',
                    'Long-term lease treated as sale of rights',
                    '18%',
                    const Color(0xFF9A3412)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDEA0).withValues(alpha: 0.12),
              border: Border.all(
                  color: const Color(0xFFFFDEA0).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📌 Key GST on Property Facts (India 2025)',
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: const Color(0xFF9A3412))),
                const SizedBox(height: 8),
                _tipRow(
                    'GST is applicable only on under-construction properties. Ready-to-move properties (with OC) are exempt.'),
                _tipRow(
                    'ITC (Input Tax Credit) is NOT available to home buyers — only builders can claim ITC.'),
                _tipRow(
                    'GST is charged on the total agreement value including parking, club fees, etc.'),
                _tipRow(
                    'Affordable housing: carpet area ≤60 sqm in metro (Delhi NCR, Mumbai, Bengaluru, Chennai, Hyderabad, Kolkata) and ≤90 sqm in non-metro AND value ≤₹45 Lakh.'),
                _tipRow(
                    'Stamp duty and registration are calculated on the circle rate or agreement value, whichever is higher — separate from GST.'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoCell(String label, String value, String note,
      {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    }
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white.withValues(alpha: 0.55),
                weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(note,
            style: AppTextStyles.dmSans(
                size: 7.5, color: Colors.white.withValues(alpha: 0.4))),
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
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.dmSans(
                      size: 8, color: Colors.white70, weight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Text('$prefix${_fmtShort(value)}$suffix',
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFFDEA0))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: hasError ? Colors.red : Colors.white.withValues(alpha: 0.18),
              width: hasError ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
                size: 12.5, color: Colors.white, weight: FontWeight.w800),
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
            activeTrackColor: const Color(0xFF0B1F48),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFF0B1F48).withValues(alpha: 0.24),
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

  Widget _resBoxSummary(String label, String value, String subText, Color color,
      BuildContext context,
      {bool highlight = false}) {
    final theme = widget.theme;
    Color bg = highlight ? color : theme.getCardColor(context);
    Color border = highlight ? color : theme.getBorderColor(context);

    if (highlight) {
      bg = color.withValues(alpha: 0.15);
      border = color.withValues(alpha: 0.4);
    } else {
      bg = color.withValues(alpha: 0.03);
      border = color.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: highlight ? color : theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 14,
                  weight: FontWeight.w800,
                  color: highlight ? color : theme.getTextColor(context))),
          const SizedBox(height: 1),
          Text(subText,
              style: AppTextStyles.dmSans(
                  size: 8, color: theme.getMutedColor(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _costBreakdownBar(
      String label, double val, double total, Gradient grad) {
    final pct = total > 0 ? (val / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: widget.theme.getTextColor(context),
                    weight: FontWeight.w700)),
          ),
          Expanded(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: widget.theme
                    .getBorderColor(context)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              _fmt(val),
              style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w800,
                  color: widget.theme.getTextColor(context)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gstRateTableRow(
      String emoji, String type, String desc, String rate, Color rateColor) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: theme.getBorderColor(context).withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type,
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 1),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 8.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rate,
            style: AppTextStyles.dmSans(
                size: 14.5, weight: FontWeight.w800, color: rateColor),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF9A3412)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.dmSans(
                  size: 9.5, color: const Color(0xFF9A3412), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _GstPropTypeData {
  final String icon;
  final String name;
  final double rate;
  final String desc;
  final Color themeColor;

  _GstPropTypeData({
    required this.icon,
    required this.name,
    required this.rate,
    required this.desc,
    required this.themeColor,
  });
}
