// lib/features/usa/screens/usa_fha_mip_cancellation_rules_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAFhaMipCancellationRulesScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFhaMipCancellationRulesScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFhaMipCancellationRulesScreen> createState() => _USAFhaMipCancellationRulesScreenState();
}

class _USAFhaMipCancellationRulesScreenState extends ConsumerState<USAFhaMipCancellationRulesScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  final _homePriceController = TextEditingController(text: '350000');
  final _downPctController = TextEditingController(text: '3.5');
  final _currentValueController = TextEditingController(text: '380000');
  DateTime _selectedDate = DateTime(2024, 6, 1);
  bool _calculated = false;

  // Outputs
  double _downPct = 0;
  String _removalDateStr = '';
  double _currentLtv = 0;
  String _bestPath = '';
  String _resultTitle = '';
  String _resultSub = '';
  bool _isLifetime = true;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _homePriceController.text = (inputs['homePrice'] ?? 350000.0).toStringAsFixed(0);
      _downPctController.text = (inputs['downPct'] ?? 3.5).toStringAsFixed(1);
      _currentValueController.text = (inputs['currentValue'] ?? 380000.0).toStringAsFixed(0);
      final ms = (inputs['loanDateMs'] ?? DateTime(2024, 6, 1).millisecondsSinceEpoch.toDouble()).toInt();
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(ms);
      _calculate();
    }
  }

  @override
  void dispose() {
    _homePriceController.dispose();
    _downPctController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final price = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final downPct = double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final currentVal = double.tryParse(_currentValueController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (price <= 0) {
      errors['price'] = 'Enter positive home price';
    }
    if (downPct < 0 || downPct > 100) {
      errors['downPct'] = 'Enter down payment % (0-100)';
    }
    if (currentVal <= 0) {
      errors['currentValue'] = 'Enter positive current value';
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

    final downAmt = price * (downPct / 100);
    final loanAmt = price - downAmt;
    final ltv = currentVal > 0 ? (loanAmt / currentVal * 100) : 0.0;

    final removalDate = DateTime(_selectedDate.year + 11, _selectedDate.month, _selectedDate.day);
    final formattedRemovalDate = '${_getMonthName(removalDate.month)} ${removalDate.day}, ${removalDate.year}';

    setState(() {
      _calcSnapshot['price'] = price;
      _calcSnapshot['downPct'] = downPct;
      _calcSnapshot['currentValue'] = currentVal;
      _calcSnapshot['selectedDateMs'] = _selectedDate.millisecondsSinceEpoch.toDouble();

      _downPct = downPct;
      _currentLtv = ltv;
      if (downPct < 10) {
        _isLifetime = true;
        _resultTitle = 'Life-of-Loan MIP Applies';
        _resultSub = 'With ${downPct.toStringAsFixed(1)}% down (below 10%), MIP cannot be cancelled by reaching a certain LTV. Refinancing to a conventional loan is your main path to remove it.';
        _removalDateStr = 'N/A — Life of Loan';
        _bestPath = 'Refinance to Conventional';
      } else {
        _isLifetime = false;
        _resultTitle = 'MIP Auto-Cancels at 11 Years';
        _resultSub = 'With ${downPct.toStringAsFixed(1)}% down (10%+), your MIP automatically cancels after 11 years of payments, regardless of LTV.';
        _removalDateStr = formattedRemovalDate;
        _bestPath = 'Wait for 11-Yr Mark or Refi';
      }
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

  String _getMonthName(int month) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? names[month] : '';
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _theme.primaryColor,
              onPrimary: Colors.white,
              onSurface: _theme.getTextColor(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveCalc() {
    if (!_calculated) return;
    final price = _calcSnapshot['price'] ?? 350000.0;
    final downPct = _calcSnapshot['downPct'] ?? 3.5;
    final currentVal = _calcSnapshot['currentValue'] ?? price;
    final dateMs = _calcSnapshot['selectedDateMs'] ?? _selectedDate.millisecondsSinceEpoch.toDouble();

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FHA MIP Cancellation Rules',
      label: 'FHA MIP Check: ${downPct.toStringAsFixed(1)}% Down',
      currencyCode: 'USD',
      inputs: {
        'homePrice': price,
        'downPct': downPct,
        'currentValue': currentVal,
        'loanDateMs': dateMs,
      },
      results: {
        'LtvPercent': _currentLtv,
        'LifetimeMIP': _isLifetime ? 1.0 : 0.0,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ MIP cancellation rules check saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['price'] ?? 0.0) ||
      (double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['downPct'] ?? 0.0) ||
      (double.tryParse(_currentValueController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['currentValue'] ?? 0.0) ||
      _selectedDate.millisecondsSinceEpoch != (_calcSnapshot['selectedDateMs'] ?? 0.0)
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      const Text('🛡️', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('MIP Cancellation Rules',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Mortgage Insurance Premium · Life-of-Loan vs 11-Yr',
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
                    child: _buildStripItem('UFMIP', '1.75%', 'Upfront', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Annual MIP', '0.55%', '>95% LTV', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Cancel at 10%+ Down', '11 Years', 'Max duration', isDark),
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
                _buildSectionHeader('MIP Rule Overview', badgeText: 'Post-June 2013 Rule'),

                // Hero Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFFB45309)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FHA Mortgage Insurance Premium — HUD Handbook 4000.1'.toUpperCase(),
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 5),
                      Text('Down payment under 10%? MIP lasts the life of the loan',
                          style: AppTextStyles.dmSans(
                              size: 16,
                              color: Colors.white,
                              weight: FontWeight.w800,
                              height: 1.25)),
                      const SizedBox(height: 6),
                      Text(
                          'Since June 3, 2013, FHA changed the rules: MIP no longer auto-cancels at 78% LTV like before. The only ways out now are 10%+ down, refinancing, or selling.',
                          style: AppTextStyles.dmSans(
                              size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTierBox('Down < 10%', 'Life of Loan'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTierBox('Down ≥ 10%', '11 Years', isGold: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('The Two Scenarios'),

                // Compare Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCompareCard(
                        title: '< 10% Down',
                        subtitle: 'Most FHA Borrowers (3.5%)',
                        isLifetime: true,
                        rows: [
                          _buildCompareRow('MIP Duration', 'Entire Loan Term'),
                          _buildCompareRow('Cancel via LTV?', 'No — Not Allowed'),
                          _buildCompareRow('Only Exit Options', 'Refinance / Sell'),
                          _buildCompareRow('Typical Borrower', '3.5% down, 580+ FICO'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompareCard(
                        title: '≥ 10% Down',
                        subtitle: 'Higher Down Payment',
                        isLifetime: false,
                        rows: [
                          _buildCompareRow('MIP Duration', '11 Years Maximum'),
                          _buildCompareRow('Cancel via LTV?', 'Auto-cancels at 11 yrs'),
                          _buildCompareRow('Only Exit Options', 'Wait 11 yrs / refi'),
                          _buildCompareRow('Typical Borrower', '10%+ down, 700+ FICO'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('MIP Removal Estimator'),

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
                      Text('🔍 When Can I Remove My MIP?',
                          style: AppTextStyles.dmSans(
                              size: 12.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Home Price (\$)', _homePriceController, errorText: _errors['price']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Down Payment (%)', _downPctController, errorText: _errors['downPct']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerField('Loan Origination Date'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Current Home Value (\$)', _currentValueController, errorText: _errors['currentValue']),
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
                            '🛡️ Check My MIP Status',
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
                                    'Inputs have changed. Tap "Check Cancellation Rules" to update results.',
                                    style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
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
                        colors: _isLifetime
                            ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]
                            : [const Color(0xFF0B1D3A), const Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isLifetime ? '⏳ $_resultTitle' : '✅ $_resultTitle',
                            style: AppTextStyles.dmSans(
                                size: 17, color: Colors.white, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(_resultSub,
                            style: AppTextStyles.dmSans(
                                size: 10, color: Colors.white.withValues(alpha: 0.70), height: 1.4)),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            _buildResultItemCardStr('Down Payment', '${_downPct.toStringAsFixed(1)}%'),
                            _buildResultItemCardStr('MIP Removal Date', _removalDateStr),
                            _buildResultItemCardStr('Current LTV', '${_currentLtv.toStringAsFixed(1)}%'),
                            _buildResultItemCardStr('Best Path to Remove', _bestPath),
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
                              '🔖 Save This Result',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Path to Removing MIP'),

                // Timeline Card
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
                      _buildTimelineItem('1️⃣', 'Build 20% Equity', 'Through paydown or appreciation — needed for conventional refinance with no PMI.', isGreen: true),
                      _buildTimelineItem('2️⃣', 'Get a New Appraisal', 'Lender orders appraisal to confirm current value supports 80% LTV or better.', isGold: true),
                      _buildTimelineItem('3️⃣', 'Refinance to Conventional Loan', 'Replace your FHA loan with a conventional mortgage — eliminates MIP entirely if 20%+ equity.', isGreen: true),
                      _buildTimelineItem('⚠️', 'Or: Sell the Home', 'MIP obligation ends automatically when the loan is paid off through sale.', isRed: true, isLast: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('MIP Cost Over Time'),

                // Cost Chart Card
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
                      Text('📊 Cumulative MIP Paid — \$337,750 Loan @ 0.55%',
                          style: AppTextStyles.dmSans(
                              size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      _buildChartBar('Year 1', '\$1,857', 0.08, [const Color(0xFF1B3F72), const Color(0xFF0B1D3A)]),
                      const SizedBox(height: 10),
                      _buildChartBar('Year 5', '\$8,900', 0.38, [const Color(0xFFD97706), const Color(0xFFB45309)]),
                      const SizedBox(height: 10),
                      _buildChartBar('Year 11 (Conventional Cutoff)', '\$18,500', 0.70, [const Color(0xFFB91C1C), const Color(0xFF7F1D1D)]),
                      const SizedBox(height: 10),
                      _buildChartBar('Year 30 (If Never Removed)', '\$26,400', 1.0, [const Color(0xFF7F1D1D), const Color(0xFF450A0A)]),
                      const SizedBox(height: 10),
                      Text('Estimate assumes flat MIP rate on declining balance. Refinancing earlier reduces lifetime MIP cost significantly.',
                          style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Key Facts to Know'),

                // Key Facts List
                Column(
                  children: [
                    _buildFactCard('📅', 'Rule Changed June 3, 2013', 'Loans before this date may follow older 78% LTV cancellation rules', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('🔄', 'Refinancing Resets MIP', 'A new FHA refinance restarts MIP terms under current rules', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('💰', 'UFMIP Refund on Refi', 'Partial UFMIP refund possible if refinancing FHA-to-FHA within 3 years', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('🏠', 'Conventional PMI is Different', 'Conventional loans auto-cancel PMI at 78% LTV by federal law (HPA)', cardBg, textCol, mutedCol, borderCol),
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
                color: isDark ? const Color(0xFF5D4017) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
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
    required bool isLifetime,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLifetime
              ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]
              : [const Color(0xFF0B1D3A), const Color(0xFF15803D)],
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
          ...rows,
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

  Widget _buildInputField(String label, TextEditingController controller, {String? errorText}) {
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
            border: Border.all(
              color: hasError ? Colors.red : _theme.getBorderColor(context),
              width: 1.5,
            ),
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
      ],
    );
  }

  Widget _buildDatePickerField(String label) {
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
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              border: Border.all(color: _theme.getBorderColor(context), width: 1.5),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w800,
                    color: _theme.getTextColor(context),
                  ),
                ),
                Icon(Icons.calendar_today, size: 14, color: _theme.getMutedColor(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItemCardStr(String label, String value) {
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
                  color: Colors.white,
                  weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String step, String title, String subtitle, {bool isGreen = false, bool isGold = false, bool isRed = false, bool isLast = false}) {
    Color dotBg = const Color(0xFFECFDF5);
    Color dotColor = const Color(0xFF15803D);
    if (isGold) {
      dotBg = const Color(0xFFFEF3C7);
      dotColor = const Color(0xFFD97706);
    }
    if (isRed) {
      dotBg = const Color(0xFFFEE2E2);
      dotColor = const Color(0xFFB91C1C);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: dotBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(step, style: TextStyle(color: dotColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 35,
                color: _theme.getBorderColor(context),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 11.5, color: _theme.getTextColor(context), weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.dmSans(size: 9, color: _theme.getMutedColor(context), height: 1.4)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartBar(String year, String limit, double fillFactor, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(year, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: _theme.getTextColor(context))),
            Text(limit, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: _theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fillFactor,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  limit.substring(0, limit.length >= 4 ? 4 : limit.length),
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFactCard(
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
