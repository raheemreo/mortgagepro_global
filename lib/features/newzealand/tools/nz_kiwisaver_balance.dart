// lib/features/newzealand/tools/nz_kiwisaver_balance.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZKiwiSaverBalance extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZKiwiSaverBalance({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZKiwiSaverBalance> createState() => _NZKiwiSaverBalanceState();
}

class _NZKiwiSaverBalanceState extends ConsumerState<NZKiwiSaverBalance> {
  final _ageController = TextEditingController(text: '33');
  final _balanceController = TextEditingController(text: '28000');
  final _salaryController = TextEditingController(text: '75000');

  double _contribRate = 4.0; // 3, 4, 6, 8, 10
  double _fundType = 5.5; // Conservative (3.5), Balanced (5.5), Growth (7.0), Aggressive (8.5)
  double _salaryGrowth = 2.0; // 0, 2, 3, 5

  @override
  void dispose() {
    _ageController.dispose();
    _balanceController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _saveCalculation() async {
    final int age = int.tryParse(_ageController.text) ?? 33;
    final double curBal = double.tryParse(_balanceController.text) ?? 0;
    final double salary = double.tryParse(_salaryController.text) ?? 75000;

    final result = _runProjection(age, curBal, salary);

    final labelCtrl = TextEditingController(text: 'NZ KiwiSaver Balance');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_kiwisaver_balance/save'),
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
              'Saving: Projected Balance ${CurrencyFormatter.compact(result.total, symbol: 'NZ\$')} at Age 65',
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
                hintText: 'Label (e.g. Retirement Goal)',
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
              backgroundColor: const Color(0xFF1A6B4A),
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
          : 'KiwiSaver Balance';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'KiwiSaver Balance',
        inputs: {
          'age': age.toDouble(),
          'currentBalance': curBal,
          'salary': salary,
          'contribRate': _contribRate,
          'fundType': _fundType,
          'salaryGrowth': _salaryGrowth,
        },
        results: {
          'projectedBalance': result.total,
          'yourContributions': result.totalYou,
          'employerGovtContributions': result.totalEmp,
          'investmentReturns': result.totalReturns,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ KiwiSaver projection saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  _ProjectionResult _runProjection(int age, double curBal, double salary) {
    final rate = _fundType / 100;
    const empRate = 0.03;
    const govtMax = 521.43;
    final years = max(0, 65 - age);

    double balance = curBal;
    double totalYou = 0;
    double totalEmp = 0;
    double totalReturns = 0;
    double annualSalary = salary;

    final List<_YearPoint> points = [_YearPoint(0, curBal)];

    for (int y = 1; y <= years; y++) {
      final yourContrib = annualSalary * (_contribRate / 100);
      final empContrib = annualSalary * empRate;
      final govtContrib = min(yourContrib * 0.5, govtMax);
      final yearContrib = yourContrib + empContrib + govtContrib;

      final interest = (balance + yearContrib / 2) * rate;
      balance += yearContrib + interest;

      totalYou += yourContrib;
      totalEmp += empContrib + govtContrib;
      totalReturns += interest;

      annualSalary *= (1 + _salaryGrowth / 100);

      if (y % max(1, (years / 8).floor()) == 0 || y == years) {
        points.add(_YearPoint(y, balance));
      }
    }

    final total = totalYou + totalEmp + totalReturns + curBal;
    final pYou = total > 0 ? (totalYou / total * 100).round() : 0;
    final pEmp = total > 0 ? (totalEmp / total * 100).round() : 0;
    final pRet = max(0, 100 - pYou - pEmp);

    return _ProjectionResult(
      total: total,
      totalYou: totalYou,
      totalEmp: totalEmp,
      totalReturns: totalReturns,
      years: years,
      points: points,
      pYou: pYou,
      pEmp: pEmp,
      pRet: pRet,
    );
  }

  double _projectToAge(int targetAge, int currentAge, double curBal, double salary) {
    if (targetAge <= currentAge) return curBal;
    final rate = _fundType / 100;
    final years = targetAge - currentAge;
    double balance = curBal;
    double annualSalary = salary;

    for (int y = 0; y < years; y++) {
      final contrib = (annualSalary * (_contribRate / 100)) +
          (annualSalary * 0.03) +
          min(annualSalary * (_contribRate / 100) * 0.5, 521.43);
      final interest = (balance + contrib / 2) * rate;
      balance += contrib + interest;
      annualSalary *= (1 + _salaryGrowth / 100);
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final int age = int.tryParse(_ageController.text) ?? 33;
    final double curBal = double.tryParse(_balanceController.text) ?? 0;
    final double salary = double.tryParse(_salaryController.text) ?? 75000;

    final result = _runProjection(age, curBal, salary);

    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Projected Balance',
              style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                border: Border.all(color: const Color(0xFF5EEAD4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Live Estimate',
                style: AppTextStyles.dmSans(
                    size: 9, color: const Color(0xFF0F766E), weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Result Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KIWISAVER PROJECTION · AT RETIREMENT (AGE 65)',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white60,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(result.total, currencyCode: 'NZD'),
                style: AppTextStyles.playfair(
                  size: 30,
                  weight: FontWeight.w800,
                  color: const Color(0xFFF5D060),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estimated balance in ${result.years} years (${currentYear + result.years})',
                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStatBox(
                      label: 'Your Contribs',
                      val: CurrencyFormatter.compact(result.totalYou, symbol: 'NZ\$'),
                      valColor: const Color(0xFF5EEAD4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroStatBox(
                      label: 'Employer + Govt',
                      val: CurrencyFormatter.compact(result.totalEmp, symbol: 'NZ\$'),
                      valColor: const Color(0xFFF5D060),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroStatBox(
                      label: 'Returns',
                      val: CurrencyFormatter.compact(result.totalReturns, symbol: 'NZ\$'),
                      valColor: const Color(0xFF6EE7B7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Inputs Card
        Text(
          'Your Details',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👤 Personal & Income',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextInput(
                      label: 'Current Age',
                      controller: _ageController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextInput(
                      label: 'Current Balance',
                      controller: _balanceController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTextInput(
                label: 'Annual Salary (NZD)',
                controller: _salaryController,
              ),
              const SizedBox(height: 12),

              // Contrib Rate Buttons
              Text(
                'Employee Contribution Rate',
                style: AppTextStyles.dmSans(
                    size: 9, weight: FontWeight.w700, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [3.0, 4.0, 6.0, 8.0, 10.0].map((rate) {
                  final active = _contribRate == rate;
                  return InkWell(
                    onTap: () => setState(() => _contribRate = rate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? theme.primaryColor : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? theme.primaryColor : theme.getBorderColor(context)),
                      ),
                      child: Text(
                        '${rate.toInt()}%',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.bold,
                          color: active ? Colors.white : theme.getTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Fund Type Dropdown
              Text(
                'KiwiSaver Fund Type',
                style: AppTextStyles.dmSans(
                    size: 9, weight: FontWeight.w700, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  border: Border.all(color: theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _fundType,
                    items: const [
                      DropdownMenuItem(value: 3.5, child: Text('Conservative (avg 3.5% p.a.)')),
                      DropdownMenuItem(value: 5.5, child: Text('Balanced (avg 5.5% p.a.)')),
                      DropdownMenuItem(value: 7.0, child: Text('Growth (avg 7.0% p.a.)')),
                      DropdownMenuItem(value: 8.5, child: Text('Aggressive Growth (avg 8.5% p.a.)')),
                    ],
                    onChanged: (val) => setState(() => _fundType = val!),
                    dropdownColor: theme.getCardColor(context),
                    style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context)),
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Salary Growth Buttons
              Text(
                'Expected Annual Salary Growth',
                style: AppTextStyles.dmSans(
                    size: 9, weight: FontWeight.w700, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.0, 2.0, 3.0, 5.0].map((rate) {
                  final active = _salaryGrowth == rate;
                  return InkWell(
                    onTap: () => setState(() => _salaryGrowth = rate),
                    child: Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? theme.primaryColor : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? theme.primaryColor : theme.getBorderColor(context)),
                      ),
                      child: Text(
                        '${rate.toInt()}%',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.bold,
                          color: active ? Colors.white : theme.getTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🔖 Save This Calculation',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Chart Card
        Text(
          'Balance Growth Over Time',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance Trajectory',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.bold,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  Text(
                    'Growth to Age 65',
                    style: AppTextStyles.dmSans(
                      size: 9,
                      color: const Color(0xFF0D9488),
                      weight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Area Chart via CustomPainter
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _NZKiwiSaverBalanceAreaPainter(
                    points: result.points,
                    maxBal: result.points.map((p) => p.balance).reduce(max),
                    theme: theme,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Legend and Breakdown bars
              _buildBreakdownRow(
                label: 'Your Contributions',
                val: CurrencyFormatter.compact(result.totalYou, symbol: 'NZ\$'),
                pct: '${result.pYou}%',
                color: const Color(0xFF5EEAD4),
                widthFactor: result.pYou / 100,
              ),
              const SizedBox(height: 10),
              _buildBreakdownRow(
                label: 'Employer + Govt',
                val: CurrencyFormatter.compact(result.totalEmp, symbol: 'NZ\$'),
                pct: '${result.pEmp}%',
                color: const Color(0xFFF5D060),
                widthFactor: result.pEmp / 100,
              ),
              const SizedBox(height: 10),
              _buildBreakdownRow(
                label: 'Investment Returns',
                val: CurrencyFormatter.compact(result.totalReturns, symbol: 'NZ\$'),
                pct: '${result.pRet}%',
                color: const Color(0xFF6EE7B7),
                widthFactor: result.pRet / 100,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Milestones
        Text(
          'Balance Milestones',
          style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [45, 55, 60, 65].map((targetAge) {
              if (targetAge <= age) return const SizedBox.shrink();
              final yearsFromNow = targetAge - age;
              final balAtAge = _projectToAge(targetAge, age, curBal, salary);
              final isLast = targetAge == 65;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: targetAge >= 60
                                  ? [const Color(0xFFD4A017), const Color(0xFFA07810)]
                                  : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            targetAge == 65 ? '🥝' : '🌿',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Age $targetAge (${currentYear + yearsFromNow})',
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.bold,
                                  color: theme.getTextColor(context)),
                            ),
                            Text(
                              '$yearsFromNow years from now',
                              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.compact(balAtAge, symbol: 'NZ\$'),
                              style: AppTextStyles.playfair(
                                size: 12,
                                weight: FontWeight.bold,
                                color: const Color(0xFF1A6B4A),
                              ),
                            ),
                            Text(
                              'Projected balance',
                              style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5EEAD4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏛️ 2025 KiwiSaver Rules (IRD / MSD)',
                style: AppTextStyles.dmSans(
                    size: 11, weight: FontWeight.bold, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(height: 6),
              _buildBulletItem('Min employee contrib: 3%'),
              _buildBulletItem('Employer min: 3%'),
              _buildBulletItem('Govt contribution: 50c per \$1'),
              _buildBulletItem('Max govt: \$521.43/yr'),
              _buildBulletItem('First-home withdrawal after 3 years'),
              _buildBulletItem('NZ Super age: 65'),
              _buildBulletItem('PIE tax rate up to 28%'),
              _buildBulletItem('Contribution holiday: up to 1yr'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatBox({required String label, required String val, required Color valColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white54, weight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.bold, color: valColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: widget.theme.getMutedColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(
                size: 14,
                color: widget.theme.getTextColor(context),
                weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String val,
    required String pct,
    required Color color,
    required double widthFactor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getTextColor(context)),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  val,
                  style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: widget.theme.getTextColor(context)),
                ),
                const SizedBox(width: 4),
                Text(
                  pct,
                  style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widthFactor.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF0D9488), fontSize: 10)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF0D9488)),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearPoint {
  final int year;
  final double balance;
  _YearPoint(this.year, this.balance);
}

class _ProjectionResult {
  final double total;
  final double totalYou;
  final double totalEmp;
  final double totalReturns;
  final int years;
  final List<_YearPoint> points;
  final int pYou;
  final int pEmp;
  final int pRet;

  _ProjectionResult({
    required this.total,
    required this.totalYou,
    required this.totalEmp,
    required this.totalReturns,
    required this.years,
    required this.points,
    required this.pYou,
    required this.pEmp,
    required this.pRet,
  });
}

class _NZKiwiSaverBalanceAreaPainter extends CustomPainter {
  final List<_YearPoint> points;
  final double maxBal;
  final CountryTheme theme;

  _NZKiwiSaverBalanceAreaPainter({
    required this.points,
    required this.maxBal,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final W = size.width;
    final H = size.height;
    const lPad = 48.0;
    const rPad = 10.0;
    const tPad = 10.0;
    const bPad = 24.0;

    final cW = W - lPad - rPad;
    final cH = H - tPad - bPad;

    final maxYear = points.last.year == 0 ? 1 : points.last.year;

    double xS(int year) => lPad + (year / maxYear) * cW;
    double yS(double val) => tPad + cH - (maxBal > 0 ? (val / maxBal) * cH : 0);

    // Grid lines & Y-axis labels
    final paintGrid = Paint()
      ..color = theme.borderColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (double f in [0.0, 0.5, 1.0]) {
      final y = tPad + cH - f * cH;
      final val = maxBal * f;

      // Draw dashed line
      if (f > 0) {
        canvas.drawLine(Offset(lPad, y), Offset(W - rPad, y), paintGrid);
      }

      String label;
      if (val >= 1000000) {
        label = '\$${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        label = '\$${(val / 1000).toStringAsFixed(0)}K';
      } else {
        label = '\$${val.toStringAsFixed(0)}';
      }

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 7.5,
          color: theme.mutedColor,
          fontFamily: 'Helvetica Neue',
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(lPad - textPainter.width - 5, y - textPainter.height / 2));
    }

    // Build area & line paths
    final Path areaPath = Path();
    final Path linePath = Path();

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final x = xS(pt.year);
      final y = yS(pt.balance);

      if (i == 0) {
        areaPath.moveTo(x, tPad + cH);
        areaPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        areaPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    areaPath.lineTo(xS(points.last.year), tPad + cH);
    areaPath.close();

    // Draw area fill
    final Paint paintArea = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D9488).withValues(alpha: 0.25),
          const Color(0xFF0D9488).withValues(alpha: 0.02)
        ],
      ).createShader(Rect.fromLTWH(lPad, tPad, cW, cH))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, paintArea);

    // Draw line stroke
    final Paint paintStroke = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, paintStroke);

    // Draw dots and X-axis labels
    final paintDot = Paint()..color = const Color(0xFF0D9488);
    final paintWhiteDot = Paint()..color = Colors.white;

    final int currentYear = DateTime.now().year;

    // Draw labels at start, mid, end
    final labelIndexes = [0, points.length ~/ 2, points.length - 1];
    for (int idx in labelIndexes) {
      if (idx >= points.length) continue;
      final pt = points[idx];
      final x = xS(pt.year);
      final y = yS(pt.balance);

      // Dot
      canvas.drawCircle(Offset(x, y), 4.5, paintWhiteDot);
      canvas.drawCircle(Offset(x, y), 3.0, paintDot);

      // Label (Year)
      textPainter.text = TextSpan(
        text: '${currentYear + pt.year}',
        style: TextStyle(
          fontSize: 8,
          color: theme.mutedColor,
          fontFamily: 'Helvetica Neue',
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, tPad + cH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _NZKiwiSaverBalanceAreaPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.maxBal != maxBal;
  }
}
