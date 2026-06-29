// lib/features/usa/tools/usa_debt_payoff_planner.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class Debt {
  int id;
  String name;
  double balance;
  double rate;
  double minPmt;

  Debt({
    required this.id,
    required this.name,
    required this.balance,
    required this.rate,
    required this.minPmt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'rate': rate,
        'minPmt': minPmt,
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as int,
        name: json['name'] as String,
        balance: (json['balance'] as num).toDouble(),
        rate: (json['rate'] as num).toDouble(),
        minPmt: (json['minPmt'] as num).toDouble(),
      );
}

class USADebtPayoffPlanner extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USADebtPayoffPlanner({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USADebtPayoffPlanner> createState() => _USADebtPayoffPlannerState();
}

class _USADebtPayoffPlannerState extends ConsumerState<USADebtPayoffPlanner> {
  String _strategy = 'avalanche';
  final List<Debt> _debts = [
    Debt(id: 1, name: 'Chase Credit Card', balance: 4200, rate: 22.99, minPmt: 84),
    Debt(id: 2, name: 'Citi Credit Card', balance: 7800, rate: 19.49, minPmt: 156),
    Debt(id: 3, name: 'Personal Loan', balance: 6500, rate: 11.49, minPmt: 180),
  ];
  int _nextId = 4;
  final _extraPmtController = TextEditingController(text: '200');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _extraPmtController.addListener(_markDirty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _extraPmtController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  void _addDebt() {
    setState(() {
      _debts.add(Debt(id: _nextId++, name: 'New Debt', balance: 1000, rate: 15.0, minPmt: 25.0));
      _isCalcDirty = true;
    });
  }

  void _removeDebt(int id) {
    setState(() {
      _debts.removeWhere((d) => d.id == id);
      _isCalcDirty = true;
    });
  }

  Map<String, dynamic> _simulate(List<Debt> list, double extra) {
    final bals = list.map((d) => {'id': d.id, 'name': d.name, 'bal': d.balance, 'rate': d.rate, 'minPmt': d.minPmt}).toList();
    int months = 0;
    double totalInt = 0;
    final Map<int, int> firstWin = {};

    while (bals.any((b) => (b['bal'] as double) > 0.01) && months < 600) {
      months++;
      double minSum = 0;
      for (final b in bals) {
        if ((b['bal'] as double) > 0) {
          minSum += b['minPmt'] as double;
        }
      }
      double avail = extra + minSum;

      // First pass: apply minimums, calculate interest
      for (var i = 0; i < bals.length; i++) {
        final double bal = bals[i]['bal'] as double;
        if (bal <= 0) continue;
        final double rateVal = bals[i]['rate'] as double;
        final double minPmtVal = bals[i]['minPmt'] as double;

        final double interest = bal * (rateVal / 1200);
        totalInt += interest;
        double newBal = bal + interest;

        final double payment = min(minPmtVal, newBal);
        newBal -= payment;
        avail -= payment;

        bals[i]['bal'] = newBal;
        if (newBal <= 0 && !firstWin.containsKey(bals[i]['id'] as int)) {
          firstWin[bals[i]['id'] as int] = months;
        }
      }

      // Second pass: apply extra payments to the target debt (first active debt in sort order)
      if (avail > 0) {
        for (var i = 0; i < bals.length; i++) {
          final double bal = bals[i]['bal'] as double;
          if (bal > 0) {
            final double payment = min(avail, bal);
            bals[i]['bal'] = bal - payment;
            avail -= payment;
            if ((bals[i]['bal'] as double) <= 0 && !firstWin.containsKey(bals[i]['id'] as int)) {
              firstWin[bals[i]['id'] as int] = months;
            }
            if (avail <= 0) break;
          }
        }
      }

      for (var i = 0; i < bals.length; i++) {
        bals[i]['bal'] = max(0.0, bals[i]['bal'] as double);
      }
    }

    return {'months': months, 'totalInt': totalInt, 'firstWin': firstWin};
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final extra = _val(_extraPmtController);
    final totalDebt = _debts.fold(0.0, (sum, d) => sum + d.balance);

    final avOrder = List<Debt>.from(_debts)..sort((a, b) => b.rate.compareTo(a.rate));
    final snOrder = List<Debt>.from(_debts)..sort((a, b) => a.balance.compareTo(b.balance));
    final currentOrder = _strategy == 'avalanche' ? avOrder : snOrder;

    final curSim = _simulate(currentOrder, extra);
    final months = curSim['months'] as int;
    final totalInt = curSim['totalInt'] as double;

    final labelCtrl = TextEditingController(text: 'Debt Payoff');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_debt_payoff_planner/save'),
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
              'Saving: Total Debt: ${CurrencyFormatter.compact(totalDebt, symbol: r'$')} · Free in $months months · Interest: ${CurrencyFormatter.compact(totalInt, symbol: r'$')}',
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
                hintText: 'Label (e.g. My Debt Payoff Plan)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Debt Payoff';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Debt Payoff Planner',
        inputs: {
          'ExtraPmt': extra,
          'TotalDebt': totalDebt,
          'StrategyIndex': _strategy == 'avalanche' ? 0.0 : 1.0,
        },
        results: {
          'PayoffTime': months.toDouble(),
          'TotalInterest': totalInt,
          'TotalDebt': totalDebt,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Payoff plan saved successfully!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _fmtMo(int m) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month + m);
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final extra = _val(_extraPmtController);

    final totalDebt = _debts.fold(0.0, (sum, d) => sum + d.balance);
    final minSum = _debts.fold(0.0, (sum, d) => sum + d.minPmt);

    // Sort order for calculations
    final avOrder = List<Debt>.from(_debts)..sort((a, b) => b.rate.compareTo(a.rate));
    final snOrder = List<Debt>.from(_debts)..sort((a, b) => a.balance.compareTo(b.balance));
    final currentOrder = _strategy == 'avalanche' ? avOrder : snOrder;

    final avSim = _simulate(avOrder, extra);
    final snSim = _simulate(snOrder, extra);
    final minSim = _simulate(avOrder, 0); // simulation with zero extra payment

    final curSim = _strategy == 'avalanche' ? avSim : snSim;
    final payoffMonths = curSim['months'] as int;
    final totalInterest = curSim['totalInt'] as double;
    final firstWin = curSim['firstWin'] as Map<int, int>;

    final avFirstWin = avSim['firstWin'] as Map<int, int>;
    final snFirstWin = snSim['firstWin'] as Map<int, int>;
    final avFirstId = avFirstWin.isEmpty ? 0 : (avFirstWin.keys.toList()..sort((a, b) => avFirstWin[a]!.compareTo(avFirstWin[b]!))).first;
    final snFirstId = snFirstWin.isEmpty ? 0 : (snFirstWin.keys.toList()..sort((a, b) => snFirstWin[a]!.compareTo(snFirstWin[b]!))).first;
    final avFirstName = _debts.firstWhere((d) => d.id == avFirstId, orElse: () => Debt(id: 0, name: '—', balance: 0, rate: 0, minPmt: 0)).name;
    final snFirstName = _debts.firstWhere((d) => d.id == snFirstId, orElse: () => Debt(id: 0, name: '—', balance: 0, rate: 0, minPmt: 0)).name;

    final aprColors = [const Color(0xFFB91C1C), const Color(0xFFD97706), const Color(0xFFEAB308), const Color(0xFF84CC16), const Color(0xFF0F766E), const Color(0xFF1B3F72), const Color(0xFF6D28D9)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Avg CC APR', '21.51%', 'Fed Reserve', theme, context),
              _buildHeaderStat('Auto Loan', '7.18%', 'Avg 60mo', theme, context),
              _buildHeaderStat('Student Loan', '5.50%', 'Federal', theme, context),
              _buildHeaderStat('Personal Loan', '11.48%', 'Avg APR', theme, context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('CHOOSE STRATEGY', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Avalanche/Snowball Toggle Button
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _strategy = 'avalanche'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: _strategy == 'avalanche' ? const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]) : null,
                      color: _strategy == 'avalanche' ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('Avalanche', style: AppTextStyles.dmSans(size: 10, color: _strategy == 'avalanche' ? Colors.white : theme.getTextColor(context), weight: FontWeight.bold)),
                        Text(r'Highest rate first · saves most $', style: AppTextStyles.dmSans(size: 8, color: _strategy == 'avalanche' ? Colors.white70 : theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _strategy = 'snowball'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: _strategy == 'snowball' ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF065F46)]) : null,
                      color: _strategy == 'snowball' ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('⛄', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('Snowball', style: AppTextStyles.dmSans(size: 10, color: _strategy == 'snowball' ? Colors.white : theme.getTextColor(context), weight: FontWeight.bold)),
                        Text('Smallest balance first · motivation', style: AppTextStyles.dmSans(size: 8, color: _strategy == 'snowball' ? Colors.white70 : theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('YOUR DEBTS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
            TextButton(
              onPressed: _addDebt,
              child: Text('+ Add Debt', style: AppTextStyles.dmSans(size: 11, color: theme.primaryColor, weight: FontWeight.bold)),
            ),
          ],
        ),

        // Debts List Editor
        ..._debts.map((d) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: d.name,
                        style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          d.name = val;
                          _markDirty();
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeDebt(d.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDebtEditor('Balance', d.balance, (val) {
                        d.balance = double.tryParse(val) ?? 0.0;
                        _markDirty();
                      }, isMoney: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDebtEditor('APR %', d.rate, (val) {
                        d.rate = double.tryParse(val) ?? 0.0;
                        _markDirty();
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDebtEditor('Min Pmt', d.minPmt, (val) {
                        d.minPmt = double.tryParse(val) ?? 0.0;
                        _markDirty();
                      }, isMoney: true),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        if (_debts.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Extra payment
          Text('EXTRA MONTHLY CONTRIBUTION', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: TextField(
                    controller: _extraPmtController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context), weight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'EXTRA MONTHLY CONTRIBUTION',
                      labelStyle: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.bold),
                      border: InputBorder.none,
                      prefixText: r'$ ',
                      prefixStyle: AppTextStyles.dmSans(size: 14, color: theme.getMutedColor(context), weight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF065F46)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _calculate,
                          child: _calculating
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('📉 Calculate Payoff Plan', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showResults ? _saveCalculation : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _showResults ? const Color(0xFFD97706) : theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.getBorderColor(context)),
                        ),
                        alignment: Alignment.center,
                        child: Text('💾 Save',
                            style: AppTextStyles.dmSans(
                                size: 13,
                                color: _showResults ? Colors.white : theme.getMutedColor(context),
                                weight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_showResults && _debts.isNotEmpty) ...[
          // Result Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _strategy == 'avalanche' ? [const Color(0xFF0B1D3A), const Color(0xFF1B3F72)] : [const Color(0xFF0F766E), const Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: theme.primaryColor.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_strategy == 'avalanche' ? '🔥 Avalanche' : '⛄ Snowball'} Strategy', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('$payoffMonths months',
                    style: AppTextStyles.playfair(size: 36, color: Colors.white, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Debt-free by ${_fmtMo(payoffMonths)} · ${_strategy == 'avalanche' ? 'Highest interest rates first' : 'Smallest balances first'}',
                    style: AppTextStyles.dmSans(size: 10.5, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroStatItem('Total Debt', CurrencyFormatter.format(totalDebt, symbol: r'$')),
                    _buildHeroStatItem('Total Interest', CurrencyFormatter.format(totalInterest, symbol: r'$'), color: const Color(0xFFFCD34D)),
                    _buildHeroStatItem('Mo. Payment', CurrencyFormatter.format(minSum + extra, symbol: r'$')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Debt breakdown bars and donut
          Text('DEBT BREAKDOWN', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal balance bars sorted by APR
                ...avOrder.map((d) {
                  final col = aprColors[avOrder.indexOf(d) % aprColors.length];
                  final double scale = totalDebt > 0 ? (d.balance / totalDebt) : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(d.name, style: AppTextStyles.dmSans(size: 9.5, color: col, weight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: max(0.1, scale),
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: col,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 7),
                                child: Text(CurrencyFormatter.format(d.balance, symbol: r'$'), style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: Text('${d.rate}%', style: AppTextStyles.dmSans(size: 9, color: col, weight: FontWeight.bold), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Principal vs Interest donut chart
                Row(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CustomPaint(
                        painter: _PayoffDonutPainter(
                          principal: totalDebt,
                          interest: totalInterest,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDonutLegendItem('Principal', CurrencyFormatter.format(totalDebt, symbol: r'$'), const Color(0xFF0F766E), theme, context),
                          const SizedBox(height: 4),
                          _buildDonutLegendItem('Total Interest', CurrencyFormatter.format(totalInterest, symbol: r'$'), const Color(0xFFD97706), theme, context),
                          const SizedBox(height: 4),
                          _buildDonutLegendItem('Total Repaid', CurrencyFormatter.format(totalDebt + totalInterest, symbol: r'$'), const Color(0xFF1B3F72), theme, context),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Strategy comparison table
          Text('STRATEGY COMPARISON', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(child: Text('🔥 Avalanche', style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
                    Expanded(child: Text('⛄ Snowball', style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF0F766E), weight: FontWeight.bold), textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCompareRow('Payoff Time', '${avSim['months']} mo', '${snSim['months']} mo', theme, context),
                _buildCompareRow('Total Interest', CurrencyFormatter.format(avSim['totalInt'] as double, symbol: r'$'), CurrencyFormatter.format(snSim['totalInt'] as double, symbol: r'$'), theme, context),
                _buildCompareRow('Interest Saved vs Min', CurrencyFormatter.format(max(0.0, (minSim['totalInt'] as double) - (avSim['totalInt'] as double)), symbol: r'$'), CurrencyFormatter.format(max(0.0, (minSim['totalInt'] as double) - (snSim['totalInt'] as double)), symbol: r'$'), theme, context),
                _buildCompareRow('First Win (Paid)', '$avFirstName (mo ${firstWin[avFirstId] ?? '—'})', '$snFirstName (mo ${firstWin[snFirstId] ?? '—'})', theme, context),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payoff order
          Text('${_strategy == 'avalanche' ? '🔥 Avalanche' : '⛄ Snowball'} Payoff Order', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                ...currentOrder.map((d) {
                  final i = currentOrder.indexOf(d);
                  final tagText = _strategy == 'avalanche' ? '${d.rate}%' : CurrencyFormatter.format(d.balance, symbol: r'$');
                  final tagColor = _strategy == 'avalanche' ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
                  final tagTextColor = _strategy == 'avalanche' ? const Color(0xFFB91C1C) : const Color(0xFF15803D);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: i == currentOrder.length - 1 ? Colors.transparent : theme.getBorderColor(context))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF065F46)]),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                              Text('${CurrencyFormatter.format(d.balance, symbol: r'$')} · ${d.rate}% APR · Min ${CurrencyFormatter.format(d.minPmt, symbol: r'$')}/mo', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tagText, style: AppTextStyles.dmSans(size: 8.5, color: tagTextColor, weight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, String note, CountryTheme theme, BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildHeroStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.playfair(size: 13.5, color: color ?? Colors.white, weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDebtEditor(String label, double value, ValueChanged<String> onChanged, {bool isMoney = false}) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 7, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 1),
          TextFormField(
            initialValue: value == 0 ? '' : value.toString(),
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(size: 12, color: theme.getTextColor(context), weight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              prefixText: isMoney ? r'$ ' : null,
              prefixStyle: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context)),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(String label, String value, Color color, CountryTheme theme, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context), weight: FontWeight.w600))),
        Text(value, style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompareRow(String label, String avVal, String snVal, CountryTheme theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold))),
          Expanded(child: Text(avVal, style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
          Expanded(child: Text(snVal, style: AppTextStyles.playfair(size: 11, color: const Color(0xFF0F766E), weight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _PayoffDonutPainter extends CustomPainter {
  final double principal;
  final double interest;
  final bool isDark;

  _PayoffDonutPainter({
    required this.principal,
    required this.interest,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final total = principal + interest;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF2F8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    final double prinPct = principal / total;
    final double intPct = interest / total;

    const double startAngle = -pi / 2;

    final prinPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final intPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi * prinPct,
      false,
      prinPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (2 * pi * prinPct),
      2 * pi * intPct,
      false,
      intPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PayoffDonutPainter oldDelegate) {
    return oldDelegate.principal != principal || oldDelegate.interest != interest || oldDelegate.isDark != isDark;
  }
}

