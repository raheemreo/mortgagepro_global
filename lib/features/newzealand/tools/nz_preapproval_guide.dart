// lib/features/newzealand/tools/nz_preapproval_guide.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZPreApprovalGuide extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZPreApprovalGuide({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZPreApprovalGuide> createState() => _NZPreApprovalGuideState();
}

class _NZPreApprovalGuideState extends ConsumerState<NZPreApprovalGuide> {
  final _incomeController = TextEditingController(text: '87000');
  final _partnerController = TextEditingController(text: '0');
  final _debtController = TextEditingController(text: '0');
  final _depositController = TextEditingController(text: '130000');

  int _term = 30; // 25, 30
  double _stressRate = 8.5; // 8.5, 7.0, 6.59

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _incomeController.dispose();
    _partnerController.dispose();
    _debtController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _incomeController.text = '87000';
      _partnerController.text = '0';
      _debtController.text = '0';
      _depositController.text = '130000';
      _term = 30;
      _stressRate = 8.5;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final double inc = double.tryParse(_incomeController.text) ?? 0.0;
    final double partnerInc = double.tryParse(_partnerController.text) ?? 0.0;
    final double otherDebt = double.tryParse(_debtController.text) ?? 0.0;
    final double deposit = double.tryParse(_depositController.text) ?? 0.0;

    if (inc + partnerInc <= 0) {
      errors['income'] = 'Enter gross annual income (primary or partner)';
    }
    if (otherDebt < 0) {
      errors['debt'] = 'Monthly debts cannot be negative';
    }
    if (deposit < 0) {
      errors['deposit'] = 'Deposit cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['income'] = inc;
      _calcSnapshot['partnerIncome'] = partnerInc;
      _calcSnapshot['otherDebt'] = otherDebt;
      _calcSnapshot['deposit'] = deposit;
      _calcSnapshot['term'] = _term.toDouble();
      _calcSnapshot['stressRate'] = _stressRate;
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

  void _saveCalculation(double maxLoan, double dti) async {
    final snapInc = _calcSnapshot['income'] ?? (double.tryParse(_incomeController.text) ?? 87000.0);
    final snapPartnerInc = _calcSnapshot['partnerIncome'] ?? (double.tryParse(_partnerController.text) ?? 0.0);
    final snapDebt = _calcSnapshot['otherDebt'] ?? (double.tryParse(_debtController.text) ?? 0.0);
    final snapDeposit = _calcSnapshot['deposit'] ?? (double.tryParse(_depositController.text) ?? 130000.0);
    final snapTerm = _calcSnapshot['term'] ?? _term.toDouble();
    final snapStressRate = _calcSnapshot['stressRate'] ?? _stressRate;

    final labelCtrl = TextEditingController(text: 'NZ Pre-Approval Guide');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_preapproval_guide/save'),
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
              'Max Borrow: ${CurrencyFormatter.compact(maxLoan, symbol: 'NZ\$')} · DTI: ${dti.toStringAsFixed(1)}x',
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
                hintText: 'Label (e.g. Max Borrowing Cap)',
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
          : 'NZ Pre-Approval Guide';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Pre-Approval Guide',
        inputs: {
          'income': snapInc,
          'partnerIncome': snapPartnerInc,
          'otherDebt': snapDebt,
          'deposit': snapDeposit,
          'term': snapTerm,
          'stressRate': snapStressRate,
        },
        results: {
          'maxLoan': maxLoan,
          'dtiRatio': dti,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Pre-approval calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Snapshot variables if results are shown, otherwise live inputs
    final double rawInc = double.tryParse(_incomeController.text) ?? 87000.0;
    final double rawPartnerInc = double.tryParse(_partnerController.text) ?? 0.0;
    final double rawDebt = double.tryParse(_debtController.text) ?? 0.0;
    final double rawDeposit = double.tryParse(_depositController.text) ?? 130000.0;
    final int rawTerm = _term;
    final double rawStressRate = _stressRate;

    final double inc = _showResults ? (_calcSnapshot['income'] ?? rawInc) : rawInc;
    final double partnerInc = _showResults ? (_calcSnapshot['partnerIncome'] ?? rawPartnerInc) : rawPartnerInc;
    final double totalInc = inc + partnerInc;
    final double otherDebt = _showResults ? (_calcSnapshot['otherDebt'] ?? rawDebt) : rawDebt;
    final double deposit = _showResults ? (_calcSnapshot['deposit'] ?? rawDeposit) : rawDeposit;
    final int term = _showResults ? ((_calcSnapshot['term'] ?? rawTerm.toDouble()) as double).toInt() : rawTerm;
    final double stressRate = _showResults ? (_calcSnapshot['stressRate'] ?? rawStressRate) : rawStressRate;

    final double stressRateDec = stressRate / 100 / 12;
    final int n = term * 12;

    const double dtiCap = 6.0;
    final maxLoanByDTI = totalInc * dtiCap;
    final maxMonthly = totalInc / 12 * 0.35 - otherDebt;
    final maxLoanByServiceability = stressRateDec > 0
        ? maxMonthly * (1 - pow(1 + stressRateDec, -n)) / stressRateDec
        : maxMonthly * n;

    final maxLoan = max(0.0, min(maxLoanByDTI, maxLoanByServiceability));
    final double totalProp = maxLoan + deposit;
    final dti = totalInc > 0 ? maxLoan / totalInc : 0.0;

    // Monthly payment at stress rate
    final double monthlyPmt = stressRateDec > 0
        ? maxLoan * stressRateDec / (1 - pow(1 + stressRateDec, -n))
        : maxLoan / n;

    final double reqDeposit = maxLoan * 0.20;

    final isDirty = _showResults && (
      (double.tryParse(_incomeController.text) ?? 0.0) != (_calcSnapshot['income'] ?? 0.0) ||
      (double.tryParse(_partnerController.text) ?? 0.0) != (_calcSnapshot['partnerIncome'] ?? 0.0) ||
      (double.tryParse(_debtController.text) ?? 0.0) != (_calcSnapshot['otherDebt'] ?? 0.0) ||
      (double.tryParse(_depositController.text) ?? 0.0) != (_calcSnapshot['deposit'] ?? 0.0) ||
      _term != ((_calcSnapshot['term'] ?? 30.0) as double).toInt() ||
      _stressRate != (_calcSnapshot['stressRate'] ?? 0.0)
    );

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title banner matching HTML layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Borrowing Power',
                style: AppTextStyles.playfair(
                  size: 15,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  border: Border.all(color: const Color(0xFFC4B5FD)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'RBNZ DTI 6x',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: const Color(0xFF6D28D9),
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Inputs Card
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
                    Row(
                      children: [
                        const Text('💼 ', style: TextStyle(fontSize: 16)),
                        Text(
                          'Income & Existing Debt',
                          style: AppTextStyles.playfair(
                            size: 13,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _reset,
                      child: Text(
                        'Reset ↺',
                        style: AppTextStyles.dmSans(
                          size: 11,
                          color: const Color(0xFF7C3AED),
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GROSS ANNUAL INCOME',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context))),
                          const SizedBox(height: 6),
                          _buildInputBox(_incomeController, errorText: _errors['income']),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PARTNER INCOME',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context))),
                          const SizedBox(height: 6),
                          _buildInputBox(_partnerController),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OTHER DEBTS (MONTHLY)',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context))),
                          const SizedBox(height: 6),
                          _buildInputBox(_debtController, errorText: _errors['debt']),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEPOSIT AVAILABLE',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context))),
                          const SizedBox(height: 6),
                          _buildInputBox(_depositController, errorText: _errors['deposit']),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOAN TERM',
                        style: AppTextStyles.dmSans(
                            size: 8,
                            weight: FontWeight.w800,
                            color: theme.getMutedColor(context))),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _term,
                          isExpanded: true,
                          dropdownColor: theme.getCardColor(context),
                          items: const [
                            DropdownMenuItem(value: 25, child: Text('25 years')),
                            DropdownMenuItem(value: 30, child: Text('30 years')),
                          ],
                          onChanged: (val) =>
                              setState(() => _term = val ?? 30),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INTEREST RATE (STRESS TEST)',
                        style: AppTextStyles.dmSans(
                            size: 8,
                            weight: FontWeight.w800,
                            color: theme.getMutedColor(context))),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: _stressRate,
                          isExpanded: true,
                          dropdownColor: theme.getCardColor(context),
                          items: const [
                            DropdownMenuItem(value: 8.5, child: Text('8.50% (Bank stress test)')),
                            DropdownMenuItem(value: 7.0, child: Text('7.00% (Current rate)')),
                            DropdownMenuItem(value: 6.59, child: Text('6.59% (1yr Fixed ANZ)')),
                          ],
                          onChanged: (val) =>
                              setState(() => _stressRate = val ?? 8.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('💳 Calculate Pre-Approval',
                      style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ],
            ),
          ),

          if (_showResults) ...[
            if (isDirty) ...[
              const SizedBox(height: 12),
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
                        'Inputs have changed. Tap Calculate Pre-Approval to refresh results.',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Container(
              key: _resultsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Borrowing power hero box
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
                          'MAXIMUM PRE-APPROVAL ESTIMATE · NZD',
                          style: AppTextStyles.dmSans(
                            size: 8,
                            color: Colors.white70,
                            weight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.compact(maxLoan, symbol: 'NZ\$'),
                          style: AppTextStyles.playfair(
                            size: 34,
                            weight: FontWeight.w800,
                            color: const Color(0xFFF5D060),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on \$${(totalInc / 1000).toStringAsFixed(0)}K income · ${dti.toStringAsFixed(1)}x DTI · deposit assessed',
                          style: AppTextStyles.dmSans(
                            size: 10,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.1,
                          children: [
                            _buildHeroBox('Your DTI Ratio', '${dti.toStringAsFixed(1)}x', const Color(0xFFC4B5FD)),
                            _buildHeroBox('Monthly Payment', '${CurrencyFormatter.compact(monthlyPmt, symbol: 'NZ\$')}/mo', const Color(0xFF5EEAD4)),
                            _buildHeroBox('Required Deposit', CurrencyFormatter.compact(reqDeposit, symbol: 'NZ\$'), const Color(0xFFF5D060)),
                            _buildHeroBox('Total Property', CurrencyFormatter.compact(totalProp, symbol: 'NZ\$'), Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DTI Assessment needle gauge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DTI Assessment',
                        style: AppTextStyles.playfair(
                          size: 12,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          border: Border.all(color: const Color(0xFFC4B5FD)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'RBNZ 6x Cap',
                          style: AppTextStyles.dmSans(
                            size: 8,
                            color: const Color(0xFF7C3AED),
                            weight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Debt-to-Income Ratio',
                            style: AppTextStyles.playfair(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Needle Gauge Painter
                        SizedBox(
                          height: 110,
                          width: 200,
                          child: CustomPaint(
                            painter: _NZDTINeedleGaugePainter(
                              dti: dti,
                              cap: dtiCap,
                              theme: theme,
                            ),
                          ),
                        ),
                        Text(
                          '${dti.toStringAsFixed(1)}x',
                          style: AppTextStyles.playfair(
                            size: 22,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dti <= 5.0
                              ? '✅ Comfortable — well within limits'
                              : dti <= 6.0
                                  ? '⚠️ Acceptable — within RBNZ 6x cap'
                                  : '❌ Exceeds RBNZ DTI cap of 6x',
                          style: AppTextStyles.dmSans(
                            size: 10,
                            color: theme.getMutedColor(context),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildDtiBandCell('≤ 5x', 'Comfortable', const Color(0xFFECFDF5), const Color(0xFF065F46))),
                            const SizedBox(width: 4),
                            Expanded(child: _buildDtiBandCell('5–6x', 'Acceptable', const Color(0xFFFEF3C7), const Color(0xFF92400E))),
                            const SizedBox(width: 4),
                            Expanded(child: _buildDtiBandCell('> 6x', 'Exceeds Cap', const Color(0xFFFEF2F2), const Color(0xFFC0392B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Journey steps list
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
                          '📋 Your Application Journey',
                          style: AppTextStyles.playfair(
                            size: 13,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildJourneyStep('✓', 'Check Eligibility & Borrowing', 'DTI, income, deposit assessment', 'Complete', true),
                        _buildJourneyStep('2', 'Gather Documents', '3 months payslips, bank statements, ID', 'In Progress', false, active: true),
                        _buildJourneyStep('3', 'Choose Lender / Broker', 'Compare ANZ, ASB, Kiwibank, BNZ, Westpac', 'Todo', false),
                        _buildJourneyStep('4', 'Submit Pre-Approval Application', 'Usually 1–3 business days for decision', 'Todo', false),
                        _buildJourneyStep('5', 'Receive Conditional Approval', 'Valid ~90 days · start house-hunting', 'Todo', false),
                        _buildJourneyStep('6', 'Unconditional Approval', 'Once property found & valuated', 'Todo', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Required documents checklist
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
                          '📄 Document Checklist',
                          style: AppTextStyles.playfair(
                            size: 13,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDocumentItem('🪪', 'Photo ID (Passport / Drivers Licence)', 'Must be current and valid', 'Must Have', true),
                        _buildDocumentItem('💵', '3 Recent Payslips', 'Or last 2 years IR3 if self-employed', 'Must Have', true),
                        _buildDocumentItem('🏦', '3 Months Bank Statements', 'All accounts — savings, transaction, credit', 'Must Have', true),
                        _buildDocumentItem('🥝', 'KiwiSaver Statement', 'Recent balance & membership length', 'Must Have', true),
                        _buildDocumentItem('📝', 'IRD Number', 'Required for NZ mortgage applications', 'Must Have', true),
                        _buildDocumentItem('🏘️', 'Existing Property Details', 'Rates notice, insurance if refinancing', 'If Applicable', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lenders Rates Compare
                  Text(
                    'Compare NZ Lenders',
                    style: AppTextStyles.playfair(
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _buildLenderCard('🥝 Kiwibank', '6.55%', '1yr fixed · Best rate', 'Lowest 1yr', isBest: true),
                      _buildLenderCard('🏦 ANZ', '6.59%', '1yr fixed · Large network', 'Popular'),
                      _buildLenderCard('🏦 ASB Bank', '6.59%', '1yr fixed · Good FHB', 'FHB Friendly'),
                      _buildLenderCard('🏦 BNZ', '6.59%', '1yr fixed · Flexible', 'Classic'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => _saveCalculation(maxLoan, dti),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B4A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💾 ', style: TextStyle(fontSize: 14)),
                        Text('Save Pre-Approval Estimate',
                            style: AppTextStyles.playfair(
                                size: 12,
                                weight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 7,
              color: Colors.white60,
              weight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 12.5,
              weight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDtiBandCell(String band, String desc, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            band,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: text,
            ),
          ),
          Text(
            desc,
            style: AppTextStyles.dmSans(
              size: 8,
              color: const Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller, {String? errorText}) {
    final theme = widget.theme;
    return Container(
      height: errorText != null ? 58 : 44,
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorText != null ? Colors.red : theme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: AppTextStyles.dmSans(
                    size: 14, weight: FontWeight.w700, color: theme.getTextColor(context)),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (errorText != null)
              Text(
                errorText,
                style: AppTextStyles.dmSans(size: 7, color: Colors.red, weight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyStep(
      String num, String title, String sub, String badge, bool done,
      {bool active = false}) {
    final theme = widget.theme;

    Color stepBg = theme.getBgColor(context);
    Color stepText = theme.getTextColor(context);
    Color badgeBg = theme.getBgColor(context);
    Color badgeText = theme.getMutedColor(context);

    if (done) {
      stepBg = const Color(0xFFECFDF5);
      stepText = const Color(0xFF065F46);
      badgeBg = const Color(0xFFECFDF5);
      badgeText = const Color(0xFF065F46);
    } else if (active) {
      stepBg = const Color(0xFF7C3AED);
      stepText = Colors.white;
      badgeBg = const Color(0xFFF5F3FF);
      badgeText = const Color(0xFF7C3AED);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: stepBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              num,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: stepText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: AppTextStyles.dmSans(
                  size: 8.5, weight: FontWeight.w700, color: badgeText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
      String icon, String name, String sub, String tag, bool must) {
    final theme = widget.theme;
    final bg = must ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final text = must ? const Color(0xFFC0392B) : const Color(0xFF065F46);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: AppTextStyles.dmSans(
                  size: 8.5, weight: FontWeight.w700, color: text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLenderCard(
      String name, String rate, String sub, String badge,
      {bool isBest = false}) {
    final theme = widget.theme;

    final bg = isBest
        ? const Color(0xFF0D3B2E)
        : theme.getCardColor(context);

    final border = isBest
        ? Border.all(color: const Color(0xFF0D3B2E))
        : Border.all(color: theme.getBorderColor(context));

    final textCol = isBest ? Colors.white : theme.getTextColor(context);
    final mutedCol = isBest ? Colors.white60 : theme.getMutedColor(context);

    final badgeBg = isBest ? const Color(0xFFF5D060).withValues(alpha: 0.2) : const Color(0xFFEFF6FF);
    final badgeText = isBest ? const Color(0xFFF5D060) : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rate,
            style: AppTextStyles.playfair(
              size: 18,
              weight: FontWeight.bold,
              color: isBest ? const Color(0xFFF5D060) : theme.primaryColor,
            ),
          ),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 8.5,
              color: mutedCol,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.bold,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NZDTINeedleGaugePainter extends CustomPainter {
  final double dti;
  final double cap;
  final CountryTheme theme;

  _NZDTINeedleGaugePainter({
    required this.dti,
    required this.cap,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height;
    const double r = 75.0;

    final double pct = min(dti / (cap * 1.2), 1.0);
    final double needleAngle = pi - pct * pi;

    final List<Map<String, dynamic>> segments = [
      {'from': 0.0, 'to': 5.0 / 7.2, 'color': const Color(0xFF6EE7B7)},
      {'from': 5.0 / 7.2, 'to': 6.0 / 7.2, 'color': const Color(0xFFF5D060)},
      {'from': 6.0 / 7.2, 'to': 1.0, 'color': const Color(0xFFFCA5A5)},
    ];

    const double ri = r - 16.0;

    for (final s in segments) {
      final double a1 = pi - s['from'] * pi;
      final double a2 = pi - s['to'] * pi;

      final Path path = Path();
      final double x1 = cx + r * cos(a1);
      final double y1 = cy - r * sin(a1);
      final double x2 = cx + r * cos(a2);
      final double y2 = cy - r * sin(a2);

      final double ix1 = cx + ri * cos(a1);
      final double iy1 = cy - ri * sin(a1);
      final double ix2 = cx + ri * cos(a2);
      final double iy2 = cy - ri * sin(a2);

      path.moveTo(x1, y1);
      path.arcToPoint(Offset(x2, y2), radius: const Radius.circular(r), clockwise: false);
      path.lineTo(ix2, iy2);
      path.arcToPoint(Offset(ix1, iy1), radius: const Radius.circular(ri), clockwise: true);
      path.close();

      final Paint paint = Paint()..color = s['color'];
      canvas.drawPath(path, paint);
    }

    // Draw needle
    final double nx = cx + (r - 10) * cos(needleAngle);
    final double ny = cy - (r - 10) * sin(needleAngle);

    final Paint needlePaint = Paint()
      ..color = const Color(0xFF0A0F0D)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, cy), Offset(nx, ny), needlePaint);
    canvas.drawCircle(Offset(cx, cy), 5, needlePaint);

    // Draw labels 0x, 3x, 6x, 9x
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final List<String> labels = ['0x', '3x', '6x', '9x'];
    for (int i = 0; i < labels.length; i++) {
      final double a = pi - (i / 3) * pi;
      final double lx = cx + (r + 10) * cos(a);
      final double ly = cy - (r + 10) * sin(a);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      canvas.drawText(
        canvas,
        textPainter,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NZDTINeedleGaugePainter oldDelegate) {
    return oldDelegate.dti != dti || oldDelegate.cap != cap;
  }
}

extension on Canvas {
  void drawText(Canvas canvas, TextPainter tp, Offset offset) {
    tp.paint(canvas, offset);
  }
}
