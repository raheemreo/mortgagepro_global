// lib/features/uk/tools/uk_help_to_buy.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKHelpToBuy extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKHelpToBuy({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKHelpToBuy> createState() => _UKHelpToBuyState();
}

class _UKHelpToBuyState extends ConsumerState<UKHelpToBuy> {
  final _priceController = TextEditingController(text: '320000');
  final _rateController = TextEditingController(text: '4.75');
  final _yearsController = TextEditingController(text: '0');
  final _currValController = TextEditingController(text: '320000');

  double _price = 320000;
  double _regionPct = 20; // England = 20, London = 40
  double _loanPct = 20; // 5% to max regionPct
  double _rate = 4.75;
  int _yearsSince = 0;
  double _currVal = 320000;

  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _priceController.text = (inputs['price'] ?? 320000.0).toStringAsFixed(0);
      _regionPct = inputs['regionPct'] ?? 20.0;
      _loanPct = inputs['loanPct'] ?? 20.0;
      _rateController.text = (inputs['rate'] ?? 4.75).toString();
      _yearsController.text = (inputs['yearsSince'] ?? 0.0).toStringAsFixed(0);
      _currValController.text =
          (inputs['currVal'] ?? 320000.0).toStringAsFixed(0);
      _hasCalculated = true;
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    _currValController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _price = double.tryParse(_priceController.text) ?? 0;
      _rate = double.tryParse(_rateController.text) ?? 4.75;
      _yearsSince = int.tryParse(_yearsController.text) ?? 0;
      _currVal = double.tryParse(_currValController.text) ?? _price;
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);
    final depositColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF0D0D2B);

    // Live BoE rate for context
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final isLive   = ukRates?.isLive == true;

    // Calculation results
    const depositPct = 0.05; // 5%
    final deposit = _price * depositPct;
    final loanAmt = _price * (_loanPct / 100);
    final mortAmt = _price - loanAmt - deposit;
    final mortPct = 100 - _loanPct - (depositPct * 100);

    final rMo = _rate / 100 / 12;
    final monthlyMort = _pmt(rMo, 300, mortAmt); // 25 year term = 300 months

    final currLoanVal = _currVal * (_loanPct / 100);
    const baseFeeRate = 0.0175; // 1.75%
    final yr6FeeAmt = loanAmt * baseFeeRate / 12;
    final yr10Rate = baseFeeRate * math.pow(1.04, 4); // ~4% inflation each year
    final yr10Fee = loanAmt * yr10Rate / 12;

    final ownedEquity = _currVal * (1 - _loanPct / 100);
    final savings = mortAmt - (_price * 0.75); // vs standard 75% LTV mortgage

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _rateCell(
                      'Equity Loan', 'Up to 20%', 'England', textThemeColor)),
              _divider(),
              Expanded(
                  child: _rateCell('London Limit', 'Up to 40%', 'GLA areas',
                      isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))),
              _divider(),
              Expanded(
                  child: _rateCell(
                      'Min Deposit', '5%', 'Of price', textThemeColor)),
              _divider(),
              Expanded(
                  child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', 'Mortgage ref',
                      isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help to Buy: Equity Loan (Legacy)',
                style: AppTextStyles.dmSans(
                    size: 13, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                'The Help to Buy: Equity Loan scheme closed to new applications on 31 October 2022. This calculator helps existing borrowers understand their loan and repayment obligations.',
                style: AppTextStyles.dmSans(size: 10.5, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                '⚠️ New applicants: See Shared Ownership or First Homes scheme instead.',
                style: AppTextStyles.dmSans(
                    size: 10,
                    color: const Color(0xFFFFD700),
                    weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'PROPERTY & LOAN DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Inputs Card 1
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
              _inputField(
                  label: 'Property Purchase Price (£)',
                  controller: _priceController),
              const SizedBox(height: 12),
              Text(
                'REGION',
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.getMutedColor(context),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF5F5F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: _regionPct,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: textThemeColor),
                    items: const [
                      DropdownMenuItem(
                          value: 20.0,
                          child: Text('England (outside London) – 20% limit')),
                      DropdownMenuItem(
                          value: 40.0, child: Text('London – 40% limit')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _regionPct = val;
                          if (_loanPct > _regionPct) {
                            _loanPct = _regionPct;
                          }
                          _calculateValues();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EQUITY LOAN %',
                    style: AppTextStyles.dmSans(
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: widget.theme.getMutedColor(context),
                        letterSpacing: 0.5),
                  ),
                  Text(
                    '${_loanPct.toInt()}%',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: widget.theme.accentColor),
                  ),
                ],
              ),
              Slider(
                value: _loanPct.clamp(5, _regionPct),
                min: 5,
                max: _regionPct,
                divisions: ((_regionPct - 5) / 5).round(),
                activeColor: widget.theme.primaryColor,
                onChanged: (val) {
                  setState(() {
                    _loanPct = val;
                    _calculateValues();
                  });
                },
              ),
              const SizedBox(height: 4),
              _inputField(
                  label: 'Your Mortgage Rate (%)', controller: _rateController),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Inputs Card 2 (Existing Borrowers)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(
                  label: 'Years Since Purchase (for fee calculation)',
                  controller: _yearsController),
              const SizedBox(height: 12),
              _inputField(
                  label: 'Current Property Value (£) (if different)',
                  controller: _currValController),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculate Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8102E),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
            onPressed: () {
              _calculateValues();
              setState(() => _hasCalculated = true);
            },
            child: Text(
              '🏘️ Calculate Help to Buy',
              style: AppTextStyles.dmSans(
                  size: 14, color: Colors.white, weight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          // Results Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR MORTGAGE NEEDED',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 0.7),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(mortAmt, symbol: '£')
                          .split('.')
                          .first,
                      style: AppTextStyles.dmSans(
                              size: 34,
                              weight: FontWeight.w800,
                              color: Colors.white)
                          .copyWith(fontFamily: 'Georgia'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final calc = SavedCalc.create(
                          country: 'UK',
                          calcType: 'Help to Buy',
                          inputs: {
                            'price': _price,
                            'regionPct': _regionPct,
                            'loanPct': _loanPct,
                            'rate': _rate,
                            'yearsSince': _yearsSince.toDouble(),
                            'currVal': _currVal,
                          },
                          results: {
                            'Mortgage Needed': mortAmt,
                            'Government Loan': loanAmt,
                            'Deposit': deposit,
                            'Monthly Mortgage': monthlyMort,
                            'Year 6 Fee': yr6FeeAmt,
                            'Current Loan Value': currLoanVal,
                          },
                          label:
                              '${CurrencyFormatter.compact(mortAmt, symbol: '£')} mortgage · ${_loanPct.toInt()}% govt loan',
                          currencyCode: 'GBP',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).save(calc);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✓ Help to Buy calculation saved'),
                            backgroundColor: Color(0xFF0D9488),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.save,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('Save',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.format(deposit, symbol: '£').split('.').first} deposit + ${CurrencyFormatter.format(loanAmt, symbol: '£').split('.').first} government loan',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Save ${CurrencyFormatter.format(savings.abs(), symbol: '£').split('.').first} vs. standard 75% LTV mortgage',
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        color: const Color(0xFF90EE90),
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Funding Stack Visual Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Funding Structure',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 28,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5, // 5% Deposit
                          child: Container(
                            color: depositColor,
                            alignment: Alignment.center,
                            child: Text('5%',
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: isDark ? const Color(0xFF0D0D2B) : Colors.white,
                                    weight: FontWeight.w800)),
                          ),
                        ),
                        Expanded(
                          flex: _loanPct.toInt(),
                          child: Container(
                            color: const Color(0xFF4F46E5),
                            alignment: Alignment.center,
                            child: Text('${_loanPct.toInt()}%',
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: Colors.white,
                                    weight: FontWeight.w800)),
                          ),
                        ),
                        Expanded(
                          flex: mortPct.toInt(),
                          child: Container(
                            color: const Color(0xFFC8102E),
                            alignment: Alignment.center,
                            child: Text('${mortPct.round()}%',
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: Colors.white,
                                    weight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _legendRow(
                    depositColor, 'Your Deposit (5%)', deposit),
                const SizedBox(height: 6),
                _legendRow(const Color(0xFF4F46E5),
                    'Govt Equity Loan (${_loanPct.toInt()}%)', loanAmt),
                const SizedBox(height: 6),
                _legendRow(const Color(0xFFC8102E),
                    'Your Mortgage (${mortPct.round()}%)', mortAmt),
              ],
            ),
          ),
          const SizedBox(height: 12),
 
          // Metrics Panel
          ResultPanel(
            primaryColor: widget.theme.primaryColor,
            rows: [
              ResultRow(
                  label: 'Monthly Mortgage (25 yr)',
                  value: monthlyMort,
                  currencyCode: 'GBP'),
              ResultRow(
                  label: 'Equity Loan Fee (Yr 6)',
                  value: yr6FeeAmt,
                  currencyCode: 'GBP',
                  isHighlighted: true),
              ResultRow(
                  label: 'Current Loan Value',
                  value: currLoanVal,
                  currencyCode: 'GBP'),
              ResultRow(
                  label: 'Equity Owned (${(100 - _loanPct).toInt()}%)',
                  value: ownedEquity,
                  currencyCode: 'GBP'),
            ],
          ),
          const SizedBox(height: 12),
 
          // Timeline Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 Equity Loan Fee Timeline',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                _timelineRow(
                  icon: '✓',
                  iconColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                  title: 'Years 1–5',
                  description: 'Interest-free government equity loan',
                  feeText: '£0/month fee',
                ),
                const SizedBox(height: 10),
                _timelineRow(
                  icon: '£',
                  iconColor: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
                  title: 'Year 6 onwards',
                  description: 'Fee starts at 1.75% of loan, rising annually',
                  feeText:
                      '${CurrencyFormatter.format(yr6FeeAmt, symbol: '£').split('.').first}/month',
                ),
                const SizedBox(height: 10),
                _timelineRow(
                  icon: '↑',
                  iconColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                  title: 'Annual increase',
                  description: 'CPI/RPI + 1% each year – can become costly',
                  feeText:
                      'Est. yr 10: ${CurrencyFormatter.format(yr10Fee, symbol: '£').split('.').first}/mo',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
 
          // Warning Box
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEF2F2),
              border: Border.all(color: isDark ? const Color(0xFFFCA5A5).withValues(alpha: 0.3) : const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Key Risks to Consider',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Equity loan repayment is % of property value — if prices rise, you repay more.\n• Fees escalate rapidly after year 5 (RPI + 1% p.a.).\n• You cannot part-repay less than 10% of property value.\n• Scheme closed Oct 2022 — existing borrowers only.',
                  style: AppTextStyles.dmSans(
                      size: 11, color: isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _legendRow(Color color, String label, double val) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: widget.theme.getTextColor(context).withValues(alpha: 0.7))),
        ),
        Text(
          CurrencyFormatter.format(val, symbol: '£').split('.').first,
          style: AppTextStyles.dmSans(
              size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _timelineRow({
    required String icon,
    required Color iconColor,
    required String title,
    required String description,
    required String feeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : const Color(0xFF0D0D2B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(icon,
              style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: const Color(0xFF0D0D2B))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.dmSans(
                      size: 11, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 2),
              Text(description,
                  style: AppTextStyles.dmSans(
                      size: 10, color: widget.theme.getMutedColor(context))),
              const SizedBox(height: 2),
              Text(feeText,
                  style: AppTextStyles.dmSans(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _inputField(
      {required String label, required TextEditingController controller}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _calculateValues(),
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5F5F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
