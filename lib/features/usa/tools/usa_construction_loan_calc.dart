// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_construction_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAConstructionLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAConstructionLoanCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAConstructionLoanCalc> createState() => _USAConstructionLoanCalcState();
}

class _USAConstructionLoanCalcState extends ConsumerState<USAConstructionLoanCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  // Input Controllers
  final _landCostController = TextEditingController(text: '120000');
  final _buildCostController = TextEditingController(text: '380000');
  final _constRateController = TextEditingController(text: '8.25');
  final _permRateController = TextEditingController(text: '6.82');
  final _buildMonthsController = TextEditingController(text: '12');
  final _downPctController = TextEditingController(text: '20');
  final _contingencyController = TextEditingController(text: '10');

  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedCalculation(widget.savedCalc!);
      });
    }
  }

  @override
  void dispose() {
    _landCostController.dispose();
    _buildCostController.dispose();
    _constRateController.dispose();
    _permRateController.dispose();
    _buildMonthsController.dispose();
    _downPctController.dispose();
    _contingencyController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    double defaultVal = 0.0;
    if (c == _landCostController) {
      defaultVal = 120000.0;
    } else if (c == _buildCostController) {
      defaultVal = 380000.0;
    } else if (c == _constRateController) {
      defaultVal = 8.25;
    } else if (c == _permRateController) {
      defaultVal = 6.82;
    } else if (c == _buildMonthsController) {
      defaultVal = 12.0;
    } else if (c == _downPctController) {
      defaultVal = 20.0;
    } else if (c == _contingencyController) {
      defaultVal = 10.0;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _resetInputs() {
    setState(() {
      _landCostController.text = '120000';
      _buildCostController.text = '380000';
      _constRateController.text = '8.25';
      _permRateController.text = '6.82';
      _buildMonthsController.text = '12';
      _downPctController.text = '20';
      _contingencyController.text = '10';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    final val_land = calc.inputs['LandCost'] ?? 120000.0;
    final val_build = calc.inputs['BuildCost'] ?? 380000.0;
    final val_constRate = calc.inputs['ConstRate'] ?? 8.25;
    final val_permRate = calc.inputs['PermRate'] ?? 6.82;
    final val_buildMonths = calc.inputs['BuildMonths'] ?? 12.0;
    final val_downPct = calc.inputs['DownPaymentPct'] ?? 20.0;
    final val_contingency = calc.inputs['ContingencyPct'] ?? 10.0;

    setState(() {
      _landCostController.text = val_land.toStringAsFixed(0);
      _buildCostController.text = val_build.toStringAsFixed(0);
      _constRateController.text = val_constRate.toStringAsFixed(2);
      _permRateController.text = val_permRate.toStringAsFixed(2);
      _buildMonthsController.text = val_buildMonths.toStringAsFixed(0);
      _downPctController.text = val_downPct.toStringAsFixed(0);
      _contingencyController.text = val_contingency.toStringAsFixed(0);

      _calcSnapshot[_landCostController] = val_land;
      _calcSnapshot[_buildCostController] = val_build;
      _calcSnapshot[_constRateController] = val_constRate;
      _calcSnapshot[_permRateController] = val_permRate;
      _calcSnapshot[_buildMonthsController] = val_buildMonths;
      _calcSnapshot[_downPctController] = val_downPct;
      _calcSnapshot[_contingencyController] = val_contingency;
      _showResults = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveCalculation() async {
    final land = _val(_landCostController);
    final buildVal = _val(_buildCostController);
    final constRateAnn = _val(_constRateController);
    final permRateAnn = _val(_permRateController);
    final buildMonths = _val(_buildMonthsController).toInt();
    final downPct = _val(_downPctController) / 100;
    final contPct = _val(_contingencyController) / 100;

    final contAmt = buildVal * contPct;
    final totalProject = land + buildVal + contAmt;
    final downAmt = totalProject * downPct;
    final constLoan = max(0.0, totalProject - downAmt);

    final avgBalance = constLoan * 0.50;
    final avgIntOnlyMo = (avgBalance * (constRateAnn / 100)) / 12;
    final totalConstInt = avgIntOnlyMo * buildMonths;

    final double permPI = MortgageMath.monthlyPayment(
      principal: constLoan,
      annualRatePercent: permRateAnn,
      termYears: 30,
    );

    final labelCtrl = TextEditingController(text: 'Construction Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_construction_loan_calc/save'),
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
              'Saving: Perm P&I Payment: ${CurrencyFormatter.format(permPI, symbol: '\$').split('.').first} · Const Loan: ${CurrencyFormatter.format(constLoan, symbol: '\$').split('.').first}',
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
                hintText: 'Label (e.g. Dream House Build)',
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
          : 'Construction Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Construction Loan Calculator',
        inputs: {
          'LandCost': land,
          'BuildCost': buildVal,
          'ConstRate': constRateAnn,
          'PermRate': permRateAnn,
          'BuildMonths': buildMonths.toDouble(),
          'DownPaymentPct': _val(_downPctController),
          'ContingencyPct': _val(_contingencyController),
        },
        results: {
          'TotalProjectCost': totalProject,
          'ConstructionLoan': constLoan,
          'AvgInterestOnlyMo': avgIntOnlyMo,
          'TotalConstInterest': totalConstInt,
          'PermanentPI': permPI,
          'ContingencyReserve': contAmt,
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

    void _calculate() {
    final errors = <String, String>{};
    
    final val_landCost = double.tryParse(_landCostController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_landCost < 0) {
      errors['landCost'] = 'Enter valid cost';
    } else if (val_landCost == 0) {
      errors['landCost'] = 'Cost required';
    }
    
    final val_buildCost = double.tryParse(_buildCostController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_buildCost < 0) {
      errors['buildCost'] = 'Enter valid cost';
    } else if (val_buildCost == 0) {
      errors['buildCost'] = 'Cost required';
    }
    
    final val_constRate = double.tryParse(_constRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_constRate < 0) {
      errors['constRate'] = 'Enter valid rate';
    } else if (val_constRate == 0) {
      errors['constRate'] = 'Rate required';
    }

    final val_permRate = double.tryParse(_permRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_permRate < 0) {
      errors['permRate'] = 'Enter valid rate';
    } else if (val_permRate == 0) {
      errors['permRate'] = 'Rate required';
    }

    final val_buildMonths = double.tryParse(_buildMonthsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? -1.0;
    if (val_buildMonths < 0) {
      errors['buildMonths'] = 'Enter valid months';
    } else if (val_buildMonths == 0) {
      errors['buildMonths'] = 'Months required';
    }

    final val_downPct = double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_downPct < 0) errors['downPct'] = 'Enter valid percent';

    final val_contingency = double.tryParse(_contingencyController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_contingency < 0) errors['contingency'] = 'Enter valid percent';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      _showResults = false;
      return;
    }

    setState(() {
      _calcSnapshot[_landCostController] = val_landCost;
      _calcSnapshot[_buildCostController] = val_buildCost;
      _calcSnapshot[_constRateController] = val_constRate;
      _calcSnapshot[_permRateController] = val_permRate;
      _calcSnapshot[_buildMonthsController] = val_buildMonths;
      _calcSnapshot[_downPctController] = val_downPct;
      _calcSnapshot[_contingencyController] = val_contingency;
      _showResults = true;
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

  @override
  Widget build(BuildContext context) {

    final isDirty = _showResults && (double.tryParse(_landCostController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_landCostController] ?? 0.0) || double.tryParse(_buildCostController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_buildCostController] ?? 0.0) || double.tryParse(_constRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_constRateController] ?? 0.0) || double.tryParse(_permRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_permRateController] ?? 0.0) || double.tryParse(_buildMonthsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_buildMonthsController] ?? 0.0) || double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_downPctController] ?? 0.0) || double.tryParse(_contingencyController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_contingencyController] ?? 0.0));

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final land = _val(_landCostController);
    final buildVal = _val(_buildCostController);
    final constRateAnn = _val(_constRateController);
    final permRateAnn = _val(_permRateController);
    final buildMonths = _val(_buildMonthsController).toInt();
    final downPct = _val(_downPctController) / 100;
    final contPct = _val(_contingencyController) / 100;

    // Calculations
    final contAmt = buildVal * contPct;
    final totalProject = land + buildVal + contAmt;
    final downAmt = totalProject * downPct;
    final constLoan = max(0.0, totalProject - downAmt);

    // Average interest-only payments (50% avg outstanding balance during build)
    final avgBalance = constLoan * 0.50;
    final avgIntOnlyMo = (avgBalance * (constRateAnn / 100)) / 12;
    final totalConstInt = avgIntOnlyMo * buildMonths;

    // Permanent payment P&I (30 years fixed)
    final double permPI = MortgageMath.monthlyPayment(
      principal: constLoan,
      annualRatePercent: permRateAnn,
      termYears: 30,
    );

    // Segments percentages for donut
    final landPct = totalProject > 0 ? (land / totalProject) : 0.0;
    final buildPct = totalProject > 0 ? (buildVal / totalProject) : 0.0;
    final contPctAlloc = totalProject > 0 ? (contAmt / totalProject) : 0.0;
    final downPctAlloc = totalProject > 0 ? (downAmt / totalProject) : 0.0;

    // Interest buildup bars values
    final buildupSteps = [0.25, 0.50, 0.75, 1.00];
    final List<Map<String, dynamic>> buildupData = buildupSteps.map((f) {
      final monthlyInt = ((constLoan * f) * (constRateAnn / 100)) / 12;
      return {
        'label': '${(f * 100).round()}% drawn',
        'val': monthlyInt,
      };
    }).toList();
    final maxInt = buildupData.isNotEmpty ? (buildupData.last['val'] as double) : 1.0;

    // Typical draw schedule disbursements
    final drawSchedule = [
      {'phase': 'Foundation', 'pct': 15},
      {'phase': 'Framing', 'pct': 25},
      {'phase': 'Mechanical', 'pct': 15},
      {'phase': 'Drywall', 'pct': 10},
      {'phase': 'Trim / Finish', 'pct': 25},
      {'phase': 'Cert. of Occ.', 'pct': 10},
    ];

    // Watch saved calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Construction Loan Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C), Color(0xFF78350F)],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('Const. Rate', '${constRateAnn.toStringAsFixed(2)}%', 'Int-Only Phase'),
              _buildRateStripItem('Perm Rate', '${permRateAnn.toStringAsFixed(2)}%', '30-Yr Fixed', isGold: true),
              _buildRateStripItem('Min. Down', '${(_val(_downPctController)).toStringAsFixed(0)}%', 'Project Cost'),
              _buildRateStripItem('Build Time', '${buildMonths}mo', 'Specified'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('Project Details', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏗️ ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Construction Project Parameters',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Land Cost', _landCostController, prefix: '\$', hint: 'Owned land = \$0', errorText: _errors['landCost']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Build Cost', _buildCostController, prefix: '\$', hint: 'Avg: ~\$300/sqft', errorText: _errors['buildCost']),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Const. Rate', _constRateController, suffix: '%', hint: 'Interest-only phase', errorText: _errors['constRate']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Permanent Rate', _permRateController, suffix: '%', hint: '30-Yr Fixed mortgage', errorText: _errors['permRate']),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Build Duration', _buildMonthsController, suffix: 'mo', hint: 'Typically 6-18 mo', errorText: _errors['buildMonths']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Down Payment', _downPctController, suffix: '%', hint: 'Of total project', errorText: _errors['downPct']),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildInputField('Contingency Reserve', _contingencyController, suffix: '%', hint: 'Typical: 10–15% of build cost', errorText: _errors['contingency']),
              const SizedBox(height: 16),

              // Calculate & Save buttons
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: GestureDetector(
                      onTap: _calculate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB91C1C).withValues(alpha: isDirty ? 0.45 : 0.25),
                              blurRadius: isDirty ? 16 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏗️ Calculate Construction Loan',
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Opacity(
                      opacity: _showResults ? 1.0 : 0.5,
                      child: GestureDetector(
                        onTap: () {
                          if (!_showResults) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please calculate before saving.', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            _saveCalculation();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.getCardColor(context),
                            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '💾 Save',
                            style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Saved list
        if (savedCalcs.isNotEmpty) ...[
          _buildSectionHeader(
            'Saved Calculations',
            onReset: () async {
              for (final calc in savedCalcs) {
                await ref.read(savedProvider.notifier).delete(calc.id);
              }
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All saved calculations cleared!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            resetLabel: 'Clear All',
            countBadge: savedCalcs.length,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              final totalCostVal = calc.results['TotalProjectCost'] ?? 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _loadSavedCalculation(calc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc.label,
                              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Project Cost: ${CurrencyFormatter.compact(totalCostVal, symbol: '\$')} · Build: ${calc.inputs['BuildMonths']?.toInt() ?? 12} mo',
                              style: AppTextStyles.dmSans(size: 9.0, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.compact(calc.results['PermanentPI'] ?? 0.0, symbol: '\$'),
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: theme.getMutedColor(context).withValues(alpha: 0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await ref.read(savedProvider.notifier).delete(calc.id);
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        if (!_showResults)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('🏗️', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Project & Cost Details Above',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll calculate your permanent monthly payment,\ninterest-only phase analysis, draw milestones, and build project timelines.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          )
        else ...[
          Container(
            key: _resultsKey,
            child: Column(
              children: [
                if (isDirty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inputs have changed. Tap "Calculate Construction Loan" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF0B1D3A), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSectionHeader('Cost & Payment Summary', onReset: null),
          const SizedBox(height: 8),

          // Result Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERMANENT MONTHLY PAYMENT (AFTER BUILD)',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$',
                      style: AppTextStyles.dmSans(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(permPI, symbol: '').split('.').first,
                      style: AppTextStyles.dmSans(
                        size: 38,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' /mo P&I',
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Total project: ${CurrencyFormatter.format(totalProject, symbol: '\$').split('.').first} · Down: ${CurrencyFormatter.format(downAmt, symbol: '\$').split('.').first} (${(_val(_downPctController)).toStringAsFixed(0)}%) · Const. avg int-only: ${CurrencyFormatter.format(avgIntOnlyMo, symbol: '\$').split('.').first}/mo',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 6-Card Breakdown Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.22,
            children: [
              _buildMetricCard('🏗️', 'Total Project Cost', CurrencyFormatter.format(totalProject), 'Land + Build + Contingency'),
              _buildMetricCard('💵', 'Construction Loan', CurrencyFormatter.format(constLoan), 'After down payment'),
              _buildMetricCard('📅', 'Avg Int-Only Pmt', CurrencyFormatter.format(avgIntOnlyMo), 'During build phase'),
              _buildMetricCard('🔄', 'Total Const. Interest', CurrencyFormatter.format(totalConstInt), 'Paid during build'),
              _buildMetricCard('🏠', 'Perm. P&I Payment', CurrencyFormatter.format(permPI), '30-yr @ perm rate'),
              _buildMetricCard('💰', 'Contingency Reserve', CurrencyFormatter.format(contAmt), 'Built into loan'),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Project Cost Breakdown', onReset: null),
          const SizedBox(height: 8),

          // Donut Cost Chart Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏗️ WHERE YOUR MONEY GOES',
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _ConstDonutPainter(
                            landPct: landPct,
                            buildPct: buildPct,
                            contPct: contPctAlloc,
                            downPct: downPctAlloc,
                            isDark: isDark,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total',
                              style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context),
                              ),
                            ),
                            Text(
                              '\$${(totalProject / 1000).toStringAsFixed(0)}K',
                              style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.w700,
                                color: theme.getMutedColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutLegendRow('Land', '\$${(land / 1000).toStringAsFixed(0)}K', const Color(0xFF0B1D3A)),
                          const SizedBox(height: 8),
                          _buildDonutLegendRow('Build Cost', '\$${(buildVal / 1000).toStringAsFixed(0)}K', const Color(0xFFB91C1C)),
                          const SizedBox(height: 8),
                          _buildDonutLegendRow('Contingency', '\$${(contAmt / 1000).toStringAsFixed(0)}K', const Color(0xFFD97706)),
                          const SizedBox(height: 8),
                          _buildDonutLegendRow('Down Pmt', '\$${(downAmt / 1000).toStringAsFixed(0)}K', const Color(0xFF15803D)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Interest Phase Analysis', onReset: null),
          const SizedBox(height: 8),

          // Interest Buildup Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📈 MONTHLY INTEREST PAID DURING BUILD',
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: buildupData.length,
                  itemBuilder: (context, idx) {
                    final d = buildupData[idx];
                    final labelStr = d['label'] as String;
                    final valAmt = d['val'] as double;
                    final scalePct = maxInt > 0 ? (valAmt / maxInt) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              labelStr,
                              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: theme.getMutedColor(context)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: scalePct,
                                child: Container(
                                  padding: const EdgeInsets.only(right: 7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '\$${valAmt.toStringAsFixed(0)}/mo',
                                    style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Typical Draw Schedule', onReset: null),
          const SizedBox(height: 8),

          // Draw schedule Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏗️ DRAW DISBURSEMENT BY PHASE',
                  style: AppTextStyles.dmSans(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: drawSchedule.length,
                  itemBuilder: (context, idx) {
                    final d = drawSchedule[idx];
                    final phaseStr = d['phase'] as String;
                    final pctVal = d['pct'] as int;
                    final dollarAmt = constLoan * pctVal / 100;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              phaseStr,
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.getTextColor(context)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: pctVal / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$pctVal%',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 58,
                            child: Text(
                              CurrencyFormatter.format(dollarAmt, symbol: '\$').split('.').first,
                              style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Construction Loan Timeline', onReset: null),
          const SizedBox(height: 8),

          // Timeline Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEF2F2),
              border: Border.all(color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.4) : const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗓️ Typical Construction-to-Perm Timeline',
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTimelineRow('Application & Approval', '30–60 days', isDark),
                _buildTimelineRow('Interest-Only Build Phase', '$buildMonths months', isDark),
                _buildTimelineRow('Draw Inspections', 'Per draw request', isDark),
                _buildTimelineRow('Certificate of Occupancy', 'Upon build completion', isDark),
                _buildTimelineRow('Modification to Perm Loan', 'One-time close', isDark),
                _buildTimelineRow('First Perm Payment Due', '30 days post-conversion', isDark),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        _buildSectionHeader('Construction Loan Resources', onReset: null),
        const SizedBox(height: 8),

        // Resources List
        Column(
          children: [
            GestureDetector(
              onTap: () => context.push('/usa/one-close-vs-two-close'),
              child: _buildGuidelineCard('🏗️', 'One-Close vs. Two-Close Loans', 'One-close: single closing cost · Two-close: separate builder loan + final mortgage'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/builder-requirements'),
              child: _buildGuidelineCard('📋', 'Builder Eligibility Requirements', 'Licensed general contractor · Lender-vetted approved builder status'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/top-construction-lenders'),
              child: _buildGuidelineCard('🏦', 'Top Construction Lenders', 'TD Bank · Flagstar · US Bank · Regional local bank options'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/fha-203k-alternative'),
              child: _buildGuidelineCard('🔄', 'FHA 203(k) Renovation Loan', 'Purchase + renovation option for existing fixer-upper properties'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRateStripItem(String label, String value, String note, {bool isGold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 15,
            weight: FontWeight.w800,
            color: isGold ? const Color(0xFFFCD34D) : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: AppTextStyles.dmSans(
            size: 7.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutLegendRow(String label, String value, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w600,
              color: theme.getMutedColor(context),
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String? resetLabel, int? countBadge}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w800,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 1,
              ),
            ),
            if (countBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF134E5E) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$countBadge',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              resetLabel ?? 'Reset',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? prefix,
    String? suffix,
    String? hint,
    String? errorText,
  }) {
    final theme = widget.theme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: hasError ? Colors.red : theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  errorText,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w700,
              color: theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              prefixText: prefix != null ? '$prefix ' : null,
              suffixText: suffix != null ? ' $suffix' : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ),
        if (hint != null && !hasError) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String emoji, String label, String value, String sub) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: theme.getMutedColor(context), letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.split('.').first,
            style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String key, String val, bool isDark) {
    final kColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
    final vColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    final bColor = isDark ? const Color(0xFF991B1B).withValues(alpha: 0.3) : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bColor, width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: kColor)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: vColor)),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard(String emoji, String title, String subtitle) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.getMutedColor(context).withValues(alpha: 0.18),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _ConstDonutPainter extends CustomPainter {
  final double landPct;
  final double buildPct;
  final double contPct;
  final double downPct;
  final bool isDark;

  _ConstDonutPainter({
    required this.landPct,
    required this.buildPct,
    required this.contPct,
    required this.downPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 9;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    const startAngle = -pi / 2;
    double currentStart = startAngle;

    void drawArcSegment(double pct, Color color) {
      if (pct <= 0) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = pct * 2 * pi;
      canvas.drawArc(rect, currentStart, sweepAngle, false, paint);
      currentStart += sweepAngle;
    }

    drawArcSegment(landPct, const Color(0xFF0B1D3A));
    drawArcSegment(buildPct, const Color(0xFFB91C1C));
    drawArcSegment(contPct, const Color(0xFFD97706));
    drawArcSegment(downPct, const Color(0xFF15803D));
  }

  @override
  bool shouldRepaint(covariant _ConstDonutPainter oldDelegate) {
    return oldDelegate.landPct != landPct ||
        oldDelegate.buildPct != buildPct ||
        oldDelegate.contPct != contPct ||
        oldDelegate.downPct != downPct ||
        oldDelegate.isDark != isDark;
  }
}

