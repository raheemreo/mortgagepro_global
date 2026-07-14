// lib/features/newzealand/tools/nz_compare_lenders.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZCompareLenders extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZCompareLenders({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZCompareLenders> createState() => _NZCompareLendersState();
}

class _NZCompareLendersState extends ConsumerState<NZCompareLenders> {
  final _amountController = TextEditingController(text: '680000');
  int _termYears = 30;
  double _depositPct = 20;
  bool _isOwnerOccupier = true;
  String _selectedTerm = '1-Year'; // '1-Year', '2-Year', '3-Year', '5-Year', 'Floating'

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  final List<LenderInfo> _lenders = [
    LenderInfo(
      name: 'Kiwibank',
      type: 'NZ-owned bank · Full-service',
      logo: '🥝',
      logoBg: const Color(0xFFE8F8F4),
      rates: {
        '1-Year': 5.99,
        '2-Year': 5.89,
        '3-Year': 5.85,
        '5-Year': 5.79,
        'Floating': 7.89,
      },
      isBest: true,
    ),
    LenderInfo(
      name: 'ANZ',
      type: 'Australia-owned · Largest NZ lender',
      logo: '🏦',
      logoBg: const Color(0xFFEDF5F2),
      rates: {
        '1-Year': 6.09,
        '2-Year': 5.95,
        '3-Year': 5.89,
        '5-Year': 5.85,
        'Floating': 8.39,
      },
    ),
    LenderInfo(
      name: 'ASB Bank',
      type: 'CBA-owned · Strong digital banking',
      logo: '🏦',
      logoBg: const Color(0xFFEDF5F2),
      rates: {
        '1-Year': 6.09,
        '2-Year': 5.95,
        '3-Year': 5.89,
        '5-Year': 5.85,
        'Floating': 8.39,
      },
    ),
    LenderInfo(
      name: 'BNZ',
      type: 'NAB-owned · TotalMoney offset',
      logo: '🏦',
      logoBg: const Color(0xFFEDF5F2),
      rates: {
        '1-Year': 6.09,
        '2-Year': 5.95,
        '3-Year': 5.89,
        '5-Year': 5.85,
        'Floating': 8.39,
      },
    ),
    LenderInfo(
      name: 'Westpac NZ',
      type: 'Australian-owned · Airpoints rewards',
      logo: '🏦',
      logoBg: const Color(0xFFEDF5F2),
      rates: {
        '1-Year': 6.19,
        '2-Year': 6.09,
        '3-Year': 5.99,
        '5-Year': 5.89,
        'Floating': 8.39,
      },
    ),
    LenderInfo(
      name: 'TSB Bank',
      type: 'NZ community bank · Taranaki-based',
      logo: '🏦',
      logoBg: const Color(0xFFEFF6FF),
      rates: {
        '1-Year': 6.25,
        '2-Year': 6.15,
        '3-Year': 6.05,
        '5-Year': 5.99,
        'Floating': 8.45,
      },
    ),
  ];

  void _reset() {
    setState(() {
      _amountController.text = '680000';
      _termYears = 30;
      _depositPct = 20;
      _isOwnerOccupier = true;
      _selectedTerm = '1-Year';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount <= 0) {
      errors['amount'] = 'Enter valid loan amount';
    }
    if (_termYears <= 0 || _termYears > 50) {
      errors['term'] = 'Enter valid term';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['amount'] = amount;
      _calcSnapshot['term'] = _termYears;
      _calcSnapshot['depositPct'] = _depositPct;
      _calcSnapshot['isOwnerOccupier'] = _isOwnerOccupier;
      _calcSnapshot['selectedTerm'] = _selectedTerm;
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

  void _saveSnapshot() async {
    final double snapAmount = _calcSnapshot['amount'] ?? (double.tryParse(_amountController.text) ?? 680000.0);
    final int snapTerm = _calcSnapshot['term'] ?? _termYears;
    final double snapDepositPct = _calcSnapshot['depositPct'] ?? _depositPct;
    final String snapTermLabel = _calcSnapshot['selectedTerm'] ?? _selectedTerm;

    final bestLender = _lenders.firstWhere((l) => l.isBest, orElse: () => _lenders.first);
    final bestRate = bestLender.rates[snapTermLabel] ?? 5.99;
    final monthlyPay = MortgageMath.monthlyPayment(principal: snapAmount, annualRatePercent: bestRate, termYears: snapTerm);

    final results = {
      'Best Rate': bestRate,
      'Monthly Payment': monthlyPay,
      'Loan Amount': snapAmount,
    };
    final inputs = {
      'Term Years': snapTerm.toDouble(),
      'Deposit Pct': snapDepositPct,
    };

    final labelCtrl = TextEditingController(text: 'NZ Lender Compare');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_compare_lenders'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparison',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best rate: $bestRate% · Est. payment: ${CurrencyFormatter.compact(monthlyPay, symbol: 'NZ\$')}/mo',
              style: AppTextStyles.dmSans(
                  size: 11.5, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. FHB 30-Year Compare)',
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
                    size: 12,
                    weight: FontWeight.bold,
                    color: widget.theme.getMutedColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && labelCtrl.text.isNotEmpty) {
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Compare Lenders',
        inputs: inputs,
        results: results,
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );
      await ref.read(savedProvider.notifier).save(calc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${labelCtrl.text}" to saved list!'),
            backgroundColor: widget.theme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);
    final borderCol = theme.getBorderColor(context);

    final double rawAmount = double.tryParse(_amountController.text) ?? 680000;
    final int rawTerm = _termYears;
    final double rawDepositPct = _depositPct;
    final bool rawIsOwner = _isOwnerOccupier;
    final String rawTermLabel = _selectedTerm;

    final double amount = _showResults ? (_calcSnapshot['amount'] ?? rawAmount) : rawAmount;
    final int term = _showResults ? (_calcSnapshot['term'] ?? rawTerm) : rawTerm;
    final double depositPct = _showResults ? (_calcSnapshot['depositPct'] ?? rawDepositPct) : rawDepositPct;
    final bool isOwner = _showResults ? (_calcSnapshot['isOwnerOccupier'] ?? rawIsOwner) : rawIsOwner;
    final String termLabel = _showResults ? (_calcSnapshot['selectedTerm'] ?? rawTermLabel) : rawTermLabel;

    final isDirty = _showResults && (
      _amountController.text != (_calcSnapshot['amount']?.toString() ?? '') ||
      _termYears != (_calcSnapshot['term'] ?? 0) ||
      _depositPct != (_calcSnapshot['depositPct'] ?? 0.0) ||
      _isOwnerOccupier != (_calcSnapshot['isOwnerOccupier'] ?? true) ||
      _selectedTerm != (_calcSnapshot['selectedTerm'] ?? '')
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YOUR LOAN', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
              GestureDetector(
                onTap: _reset,
                child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFFC0392B))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏦 NZ LENDER RATE COMPARISON TOOL',
                  style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: Colors.white70,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    text: 'Find your ',
                    style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: Colors.white),
                    children: const [
                      TextSpan(text: 'best rate', style: TextStyle(color: Color(0xFFF5D060), fontWeight: FontWeight.bold)),
                      TextSpan(text: ' across all NZ lenders'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                          border: _errors['amount'] != null ? Border.all(color: Colors.red) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LOAN AMOUNT', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _amountController,
                              style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TERM', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _termYears,
                                isDense: true,
                                dropdownColor: const Color(0xFF0D3B2E),
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text('15 yr')),
                                  DropdownMenuItem(value: 20, child: Text('20 yr')),
                                  DropdownMenuItem(value: 25, child: Text('25 yr')),
                                  DropdownMenuItem(value: 30, child: Text('30 yr')),
                                ],
                                onChanged: (val) => setState(() => _termYears = val ?? 30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DEPOSIT %', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: _depositPct,
                                isDense: true,
                                dropdownColor: const Color(0xFF0D3B2E),
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 5, child: Text('5% (Kainga Ora)')),
                                  DropdownMenuItem(value: 10, child: Text('10%')),
                                  DropdownMenuItem(value: 20, child: Text('20%')),
                                  DropdownMenuItem(value: 30, child: Text('30%')),
                                ],
                                onChanged: (val) => setState(() => _depositPct = val ?? 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OWNER-OCCUPIER?', style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
                            const SizedBox(height: 2),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<bool>(
                                value: _isOwnerOccupier,
                                isDense: true,
                                dropdownColor: const Color(0xFF0D3B2E),
                                style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: true, child: Text('Yes')),
                                  DropdownMenuItem(value: false, child: Text('No (Investor)')),
                                ],
                                onChanged: (val) => setState(() => _isOwnerOccupier = val ?? true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: Text('🌿 Compare All NZ Lenders Now', style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Results Block
          if (_showResults) ...[
            if (isDirty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        'Inputs have changed. Tap Compare All NZ Lenders Now to refresh results.',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              key: _resultsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Term Selection Tabs
                  Text('SELECT FIXED TERM', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['1-Year', '2-Year', '3-Year', '5-Year', 'Floating'].map((t) {
                        final active = _selectedTerm == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: active,
                            selectedColor: const Color(0xFF0D3B2E),
                            labelStyle: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.bold,
                              color: active ? Colors.white : textCol,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedTerm = t;
                                  if (_showResults) {
                                    _calcSnapshot['selectedTerm'] = t;
                                  }
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Best Rate Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      border: Border.all(color: const Color(0xFF5EEAD4)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Text('🥇', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Best $termLabel Rate — Kiwibank', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF0F766E))),
                              Text('${CurrencyFormatter.compact(amount, symbol: 'NZ\$')} loan · ${depositPct.toStringAsFixed(0)}% deposit · ${isOwner ? "Owner-occupied" : "Investor"}',
                                  style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF0D9488))),
                            ],
                          ),
                        ),
                        Text(
                          '${_lenders.firstWhere((l) => l.name == 'Kiwibank').rates[termLabel]}%',
                          style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w800, color: const Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bar Chart Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$termLabel Fixed — All Lenders', style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol)),
                            Text('Lower is better', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: theme.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ..._lenders.map((lender) {
                          final rate = lender.rates[termLabel] ?? 6.0;
                          final double maxForScale = termLabel == 'Floating' ? 9.0 : 6.5;
                          final double pct = (rate / maxForScale).clamp(0.0, 1.0);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                  SizedBox(
                                  width: 70,
                                  child: Text(lender.name, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: textCol)),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: pct,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: lender.isBest
                                                ? [const Color(0xFF0D9488), const Color(0xFF1A6B4A)]
                                                : [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${rate.toStringAsFixed(2)}%',
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.dmSans(
                                      size: 11,
                                      weight: FontWeight.bold,
                                      color: lender.isBest ? const Color(0xFF0D9488) : textCol,
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

                  // Save Snapshot
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Text('💾', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Save Comparison', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: Colors.white)),
                              Text('${CurrencyFormatter.compact(amount, symbol: 'NZ\$')} Snapshot', style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _saveSnapshot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5D060),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: Text('Save', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Lender list details
                  Text('FULL LENDER DETAILS', style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: mutedCol, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lenders.length,
                    itemBuilder: (context, index) {
                      final lender = _lenders[index];
                      final double lenderRate = lender.rates[termLabel] ?? 6.0;
                      final double monthlyPay = MortgageMath.monthlyPayment(principal: amount, annualRatePercent: lenderRate, termYears: term);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: lender.isBest ? const Color(0xFF0D9488) : borderCol, width: lender.isBest ? 2 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(color: lender.logoBg, borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.center,
                                  child: Text(lender.logo, style: const TextStyle(fontSize: 20)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(lender.name, style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: textCol)),
                                      Text(lender.type, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                                      if (lender.isBest)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(20)),
                                          child: Text('⭐ BEST RATE', style: AppTextStyles.dmSans(size: 7.5, weight: FontWeight.bold, color: Colors.white)),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${lenderRate.toStringAsFixed(2)}%', style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w800, color: theme.primaryColor)),
                                    Text('$termLabel fixed', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: lender.rates.entries.map((e) {
                                final isActive = e.key == termLabel;
                                return Column(
                                  children: [
                                    Text(e.key.replaceAll('Year', 'Yr'), style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${e.value.toStringAsFixed(2)}%',
                                      style: AppTextStyles.dmSans(
                                        size: 11,
                                        weight: FontWeight.bold,
                                        color: isActive
                                            ? const Color(0xFF0D9488)
                                            : e.key == 'Floating'
                                                ? const Color(0xFFC0392B)
                                                : textCol,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${CurrencyFormatter.compact(monthlyPay, symbol: 'NZ\$')}/mo', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textCol)),
                                    Text('P&I · ${CurrencyFormatter.compact(amount, symbol: 'NZ\$')} · $term yr', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: lender.isBest ? const Color(0xFF0D9488) : theme.primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Apply →', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LenderInfo {
  final String name;
  final String type;
  final String logo;
  final Color logoBg;
  final Map<String, double> rates;
  final bool isBest;

  LenderInfo({
    required this.name,
    required this.type,
    required this.logo,
    required this.logoBg,
    required this.rates,
    this.isBest = false,
  });
}
