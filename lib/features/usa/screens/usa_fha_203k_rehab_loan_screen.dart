// lib/features/usa/screens/usa_fha_203k_rehab_loan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/currency_formatter.dart';

class USAFha203kRehabLoanScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFha203kRehabLoanScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFha203kRehabLoanScreen> createState() => _USAFha203kRehabLoanScreenState();
}

class _USAFha203kRehabLoanScreenState extends ConsumerState<USAFha203kRehabLoanScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  String _loanType = 'limited'; // limited, standard
  final _purchasePriceController = TextEditingController(text: '280000');
  final _rehabBudgetController = TextEditingController(text: '60000');
  int _selectedScore = 620;
  final _countyLimitController = TextEditingController(text: '541287');
  bool _calculated = false;

  // Outputs
  double _contingency = 0;
  double _downPct = 0.035;
  double _downAmt = 0;
  double _baseLoan = 0;
  double _ufmip = 0;
  double _finalLoan = 0;
  bool _withinLimit = true;
  bool _capExceeded = false;
  double _rehabBudgetActual = 0;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanType = (inputs['loanType'] ?? 0.0) == 0.0 ? 'limited' : 'standard';
      _purchasePriceController.text = (inputs['purchasePrice'] ?? 280000.0).toStringAsFixed(0);
      _rehabBudgetController.text = (inputs['rehabBudget'] ?? 60000.0).toStringAsFixed(0);
      _selectedScore = (inputs['creditScore'] ?? 620.0).toInt();
      _countyLimitController.text = (inputs['countyLimit'] ?? 541287.0).toStringAsFixed(0);
      _calculate();
    }
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _rehabBudgetController.dispose();
    _countyLimitController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final price = double.tryParse(_purchasePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final rehabVal = double.tryParse(_rehabBudgetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final countyLimit = double.tryParse(_countyLimitController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (price <= 0) {
      errors['price'] = 'Enter positive purchase price';
    }
    if (rehabVal <= 0) {
      errors['rehab'] = 'Enter positive rehab budget';
    }
    if (countyLimit <= 0) {
      errors['limit'] = 'Enter positive county limit';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _calculated = false;
      });
      return;
    }

    double rehab = rehabVal;
    bool capExceeded = false;
    if (_loanType == 'limited' && rehab > 75000) {
      rehab = 75000;
      capExceeded = true;
    }

    final contingency = rehab * 0.10;
    final combinedBeforeMIP = price + rehab + contingency;
    final downPct = _selectedScore >= 580 ? 0.035 : 0.10;
    final downAmt = combinedBeforeMIP * downPct;
    final baseLoan = combinedBeforeMIP - downAmt;
    final ufmip = baseLoan * 0.0175;
    final finalLoan = baseLoan + ufmip;

    final withinLimit = finalLoan <= countyLimit;

    setState(() {
      _calcSnapshot['purchasePrice'] = price;
      _calcSnapshot['rehabBudget'] = rehabVal;
      _calcSnapshot['countyLimit'] = countyLimit;
      _calcSnapshot['loanType'] = _loanType;
      _calcSnapshot['creditScore'] = _selectedScore;

      _rehabBudgetActual = rehab;
      _capExceeded = capExceeded;
      _contingency = contingency;
      _downPct = downPct;
      _downAmt = downAmt;
      _baseLoan = baseLoan;
      _ufmip = ufmip;
      _finalLoan = finalLoan;
      _withinLimit = withinLimit;
      _calculated = true;
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

  void _saveCalc() {
    if (!_calculated) return;
    final price = _calcSnapshot['purchasePrice'] ?? 280000.0;
    final rehab = _calcSnapshot['rehabBudget'] ?? 60000.0;
    final limit = _calcSnapshot['countyLimit'] ?? 541287.0;
    final loanType = _calcSnapshot['loanType'] ?? 'limited';
    final creditScore = (_calcSnapshot['creditScore'] ?? 620).toDouble();

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FHA 203k Rehab Loan',
      label: 'FHA 203k: ${CurrencyFormatter.format(_finalLoan, symbol: '\$').split('.').first}',
      currencyCode: 'USD',
      inputs: {
        'loanType': loanType == 'limited' ? 0.0 : 1.0,
        'purchasePrice': price,
        'rehabBudget': rehab,
        'creditScore': creditScore,
        'countyLimit': limit,
      },
      results: {
        'TotalLoanAmt': _finalLoan,
        'ContingencyAmt': _contingency,
        'DownPaymentAmt': _downAmt,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 203(k) rehab loan estimate saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_purchasePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['purchasePrice'] ?? 0.0) ||
      (double.tryParse(_rehabBudgetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['rehabBudget'] ?? 0.0) ||
      (double.tryParse(_countyLimitController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['countyLimit'] ?? 0.0) ||
      _loanType != (_calcSnapshot['loanType'] ?? 'limited') ||
      _selectedScore != (_calcSnapshot['creditScore'] ?? 620)
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Stacked bar chart values
    final purchasePrice = _calculated ? (_calcSnapshot['purchasePrice'] ?? 280000.0) : (double.tryParse(_purchasePriceController.text) ?? 0.0);
    final double total = purchasePrice + _rehabBudgetActual + _contingency + _ufmip;
    final double purchasePct = total > 0 ? (purchasePrice / total) : 0.0;
    final double rehabPct = total > 0 ? (_rehabBudgetActual / total) : 0.0;
    final double contingencyPct = total > 0 ? (_contingency / total) : 0.0;
    final double ufmipPct = total > 0 ? (_ufmip / total) : 0.0;

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: const Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF15803D), Color(0xFF166534)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔨', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('FHA 203(k) Rehab Loan',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Purchase + Renovation in One Loan · 2026',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rate Strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStripItem('Limited Cap', '\$75,000', 'Non-structural', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Standard Cap', 'County Limit', 'Structural OK', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Min Down', '3.5%', '580+ FICO', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('203(k) Overview', badgeText: '2026 Limits'),

                // Hero Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FHA Section 203(k) Rehabilitation Mortgage Insurance'.toUpperCase(),
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 5),
                      Text('Buy a fixer-upper, finance the fix in one loan',
                          style: AppTextStyles.dmSans(
                              size: 16,
                              color: Colors.white,
                              weight: FontWeight.w800,
                              height: 1.25)),
                      const SizedBox(height: 6),
                      Text(
                          'Instead of a separate renovation loan, 203(k) wraps purchase price + repair costs into a single FHA mortgage, with funds released to contractors as work is completed via an escrow account.',
                          style: AppTextStyles.dmSans(
                              size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTierBox('Loan Types', 'Limited / Standard'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTierBox('Rate Premium', '~+1% vs FHA Fxd', isGold: true),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTierBox('Occupancy', 'Primary Res.'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Limited vs. Standard 203(k)'),

                // Side by Side Cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCompareCard(
                        title: 'Limited',
                        subtitle: 'Cosmetic / Non-structural',
                        rehabAmt: '\$75,000 Max',
                        workAllowed: 'Paint, flooring, kitchen, bath',
                        consultant: 'No Consultant Needed',
                        timeline: '30-45 Days to Close',
                        isLimited: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompareCard(
                        title: 'Standard',
                        subtitle: 'Structural / Remodels',
                        rehabAmt: 'Up to FHA Limit',
                        workAllowed: 'Foundation, additions, full reno',
                        consultant: 'HUD-approved Consultant Req.',
                        timeline: '60-90 Days to Close',
                        isLimited: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('203(k) Loan Estimator'),

                // Calculator Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔨 Calculate Your Combined Loan',
                          style: AppTextStyles.dmSans(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      
                      // Toggle Button Row
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _loanType = 'limited');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _loanType == 'limited' ? const Color(0xFF0B1D3A) : cardBg,
                                  border: Border.all(color: _loanType == 'limited' ? const Color(0xFF0B1D3A) : borderCol),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Limited 203(k)',
                                  style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: _loanType == 'limited' ? Colors.white : mutedCol,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _loanType = 'standard');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _loanType == 'standard' ? const Color(0xFF0B1D3A) : cardBg,
                                  border: Border.all(color: _loanType == 'standard' ? const Color(0xFF0B1D3A) : borderCol),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Standard 203(k)',
                                  style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: _loanType == 'standard' ? Colors.white : mutedCol,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Purchase Price (\$)', _purchasePriceController, errorText: _errors['price']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField(
                              'Renovation Budget (\$)',
                              _rehabBudgetController,
                              hint: _loanType == 'limited' ? 'Max \$75,000' : 'HUD consultant limit',
                              errorText: _errors['rehab'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<int>(
                              label: 'Credit Score',
                              value: _selectedScore,
                              items: const [
                                DropdownMenuItem(value: 720, child: Text('720+ (Excellent)')),
                                DropdownMenuItem(value: 680, child: Text('680–719 (Good)')),
                                DropdownMenuItem(value: 620, child: Text('620–679 (Fair)')),
                                DropdownMenuItem(value: 580, child: Text('580–619 (Min 3.5%)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedScore = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('County FHA Limit (\$)', _countyLimitController, hint: 'National Floor: \$541,287', errorText: _errors['limit']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🔨 Calculate 203(k) Loan',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Calculation Results Card
                if (_calculated) ...[
                  const SizedBox(height: 12),
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
                                    'Inputs have changed. Tap "Calculate Rehab Loan" to update results.',
                                    style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _withinLimit
                            ? [const Color(0xFF0B1D3A), const Color(0xFF15803D)]
                            : [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Combined Loan Amount'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white54,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 5),
                        Text(CurrencyFormatter.format(_finalLoan, symbol: '\$').split('.').first,
                            style: AppTextStyles.dmSans(
                                size: 30, color: Colors.white, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            'Purchase ${CurrencyFormatter.format(double.tryParse(_purchasePriceController.text) ?? 0.0, symbol: '\$').split('.').first} + Rehab ${CurrencyFormatter.format(_rehabBudgetActual, symbol: '\$').split('.').first}'
                            '${_capExceeded ? ' (capped at Limited max)' : ''}'
                            '${_withinLimit ? ' — within county limit' : ' — EXCEEDS county limit'}',
                            style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _buildResultItemCardStr('Down Payment (${(_downPct * 100).toStringAsFixed(1)}%)', CurrencyFormatter.format(_downAmt, symbol: '\$').split('.').first),
                            _buildResultItemCardStr('Base Loan (Pre-MIP)', CurrencyFormatter.format(_baseLoan, symbol: '\$').split('.').first),
                            _buildResultItemCardStr('UFMIP (1.75%)', CurrencyFormatter.format(_ufmip, symbol: '\$').split('.').first, isGold: true),
                            _buildResultItemCardStr('Final Loan w/ UFMIP', CurrencyFormatter.format(_finalLoan, symbol: '\$').split('.').first),
                            _buildResultItemCardStr('10% Contingency Reserve', CurrencyFormatter.format(_contingency, symbol: '\$').split('.').first),
                            _buildResultItemCardStr('Within County Limit?', _withinLimit ? '✅ Yes' : '❌ Exceeds Limit', isRed: !_withinLimit),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _saveCalc,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🔖 Save This Estimate',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Loan Composition stacked bar chart
                if (_calculated) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader('Loan Composition'),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📊 Where Your 203(k) Loan Goes',
                            style: AppTextStyles.dmSans(
                                size: 12, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        
                        // Stacked bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 24,
                            width: double.infinity,
                            child: Row(
                              children: [
                                if (purchasePct > 0)
                                  Expanded(
                                    flex: (purchasePct * 100).round(),
                                    child: Container(
                                      color: const Color(0xFF15803D),
                                      alignment: Alignment.center,
                                      child: Text('${(purchasePct * 100).round()}%', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w700)),
                                    ),
                                  ),
                                if (rehabPct > 0)
                                  Expanded(
                                    flex: (rehabPct * 100).round(),
                                    child: Container(
                                      color: const Color(0xFFD97706),
                                      alignment: Alignment.center,
                                      child: Text('${(rehabPct * 100).round()}%', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w700)),
                                    ),
                                  ),
                                if (contingencyPct > 0)
                                  Expanded(
                                    flex: (contingencyPct * 100).round(),
                                    child: Container(
                                      color: const Color(0xFF1B3F72),
                                      alignment: Alignment.center,
                                      child: Text('${(contingencyPct * 100).round()}%', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w700)),
                                    ),
                                  ),
                                if (ufmipPct > 0)
                                  Expanded(
                                    flex: (ufmipPct * 100).round(),
                                    child: Container(
                                      color: const Color(0xFFB91C1C),
                                      alignment: Alignment.center,
                                      child: Text('${(ufmipPct * 100).round()}%', style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Legend List
                        _buildLegendRow(const Color(0xFF15803D), 'Purchase Price', CurrencyFormatter.format(double.tryParse(_purchasePriceController.text) ?? 0.0, symbol: '\$').split('.').first, textCol),
                        const SizedBox(height: 6),
                        _buildLegendRow(const Color(0xFFD97706), 'Renovation Budget', CurrencyFormatter.format(_rehabBudgetActual, symbol: '\$').split('.').first, textCol),
                        const SizedBox(height: 6),
                        _buildLegendRow(const Color(0xFF1B3F72), '10% Contingency Reserve', CurrencyFormatter.format(_contingency, symbol: '\$').split('.').first, textCol),
                        const SizedBox(height: 6),
                        _buildLegendRow(const Color(0xFFB91C1C), 'UFMIP (financed)', CurrencyFormatter.format(_ufmip, symbol: '\$').split('.').first, textCol),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Eligible Repairs'),

                // Renovation Categories
                Column(
                  children: [
                    _buildRepairCard('🛁', 'Kitchen & Bathroom Remodels', 'Both Limited and Standard — most common use case', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildRepairCard('🏗️', 'Structural Repairs (Standard Only)', 'Foundation, room additions, load-bearing walls', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildRepairCard('🌡️', 'HVAC, Plumbing & Electrical', 'System replacement or major repairs, both loan types', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildRepairCard('♿', 'Accessibility Improvements', 'Ramps, widened doorways, grab bars for accessibility', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildRepairCard('🏚️', 'Health & Safety Hazard Removal', 'Lead paint, mold, pest damage — both loan types', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildRepairCard('🚫', 'Luxury Items Excluded', 'Pools, outdoor kitchens, tennis courts not eligible', cardBg, textCol, mutedCol, borderCol),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? badgeText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: _theme.getMutedColor(context),
              letterSpacing: 1.0,
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF134E5E) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String value, String sub, bool isDark, {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: isDark ? Colors.white54 : _theme.getMutedColor(context),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white)),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : Colors.white60)),
      ],
    );
  }

  Widget _buildTierBox(String label, String value, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: isGold ? const Color(0xFFFCD34D) : Colors.white,
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildCompareCard({
    required String title,
    required String subtitle,
    required String rehabAmt,
    required String workAllowed,
    required String consultant,
    required String timeline,
    required bool isLimited,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLimited
              ? [const Color(0xFF1B3F72), const Color(0xFF0B1D3A)]
              : [const Color(0xFF15803D), const Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.w800)),
          Text(subtitle, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
          const SizedBox(height: 12),
          _buildCompareRow('Max Rehab Amount', rehabAmt),
          _buildCompareRow('Work Allowed', workAllowed),
          _buildCompareRow('Consultant Needed?', consultant),
          _buildCompareRow('Typical Timeline', timeline),
        ],
      ),
    );
  }

  Widget _buildCompareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 7.5, color: Colors.white54, letterSpacing: 0.3)),
          const SizedBox(height: 1),
          Text(value, style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, String? errorText}) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: hasError ? Colors.red : _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: hasError ? Colors.red : _theme.getBorderColor(context), width: hasError ? 2 : 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: _theme.getTextColor(context),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (hint != null && !hasError) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context))),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: _theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: _theme.getTextColor(context),
              ),
              dropdownColor: _theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: _theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItemCardStr(String label, String value, {bool isGold = false, bool isRed = false}) {
    Color valColor = Colors.white;
    if (isGold) valColor = const Color(0xFFFCD34D);
    if (isRed) valColor = const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11.5,
                  color: valColor,
                  weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color dotColor, String label, String value, Color textColor) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 9.5, color: _theme.getMutedColor(context))),
        ),
        Text(value, style: AppTextStyles.dmSans(size: 10, color: textColor, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildRepairCard(
    String emoji,
    String title,
    String sub,
    Color bg,
    Color textCol,
    Color mutedCol,
    Color borderCol,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
