// lib/features/uk/tools/uk_income_multiples.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class UKIncomeMultiples extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKIncomeMultiples({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKIncomeMultiples> createState() => _UKIncomeMultiplesState();
}

class _UKIncomeMultiplesState extends ConsumerState<UKIncomeMultiples> {
  String _appType = 'solo'; // solo, joint

  final _sal1Controller = TextEditingController(text: '60000');
  final _sal2Controller = TextEditingController(text: '40000');
  final _bonusController = TextEditingController(text: '10000');
  final _targetPriceController = TextEditingController(text: '350000');
  final _depController = TextEditingController(text: '50000');

  double _sal1 = 60000;
  double _sal2 = 40000;
  double _bonus = 10000;
  double _targetPrice = 350000;
  double _dep = 50000;

  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _sal1Controller.text = (inputs['sal1'] ?? 60000.0).toStringAsFixed(0);
      final double s2 = inputs['sal2'] ?? 0.0;
      _sal2Controller.text = s2.toStringAsFixed(0);
      _bonusController.text = (inputs['bonus'] ?? 10000.0).toStringAsFixed(0);
      _targetPriceController.text =
          (inputs['targetPrice'] ?? 350000.0).toStringAsFixed(0);
      _depController.text = (inputs['dep'] ?? 50000.0).toStringAsFixed(0);
      _appType = s2 > 0.0 ? 'joint' : 'solo';
      _hasCalculated = true;
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _sal1Controller.dispose();
    _sal2Controller.dispose();
    _bonusController.dispose();
    _targetPriceController.dispose();
    _depController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _sal1 = double.tryParse(_sal1Controller.text) ?? 0;
      _sal2 = _appType == 'joint'
          ? (double.tryParse(_sal2Controller.text) ?? 0)
          : 0;
      _bonus = double.tryParse(_bonusController.text) ?? 0;
      _targetPrice = double.tryParse(_targetPriceController.text) ?? 0;
      _dep = double.tryParse(_depController.text) ?? 0;
    });
  }

  final List<Map<String, dynamic>> lenders = const [
    {
      'name': 'Halifax',
      'multiple': 4.75,
      'note': 'Standard applicants',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Nationwide',
      'multiple': 4.5,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Barclays',
      'multiple': 4.75,
      'note': 'Mortgage Plus',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'NatWest',
      'multiple': 4.5,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'HSBC',
      'multiple': 4.75,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Santander',
      'multiple': 4.45,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Lloyds',
      'multiple': 5.0,
      'note': '>£50k income',
      'badge': 'badge-cond',
      'type': 'cond'
    },
    {
      'name': 'Virgin Money',
      'multiple': 5.0,
      'note': 'Salary conditions',
      'badge': 'badge-cond',
      'type': 'cond'
    },
    {
      'name': 'Kensington',
      'multiple': 5.5,
      'note': 'Specialist lender',
      'badge': 'badge-top',
      'type': 'top'
    },
    {
      'name': 'Accord',
      'multiple': 5.5,
      'note': 'Broker only',
      'badge': 'badge-top',
      'type': 'top'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final s2Val = _appType == 'joint' ? _sal2 : 0.0;
    final totalIncome = _sal1 + s2Val + (_bonus * 0.5);
    final reqBorrow = _targetPrice - _dep;
    final stdBorrow = totalIncome * 4.5;
    final shortfall = reqBorrow - stdBorrow;
    final multUsed = totalIncome > 0 ? (reqBorrow / totalIncome) : 0.0;
    final maxBorrow = totalIncome * 5.5;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141C33) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0x161A1A5E);

    // Live BoE base rate for context
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final isLive   = ukRates?.isLive == true;

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
                      'Standard', '4–4.5×', 'Most lenders', textThemeColor)),
              _divider(),
              Expanded(
                  child: _rateCell('Higher LTI', '4.5–5×', 'FCA limit',
                      isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))),
              _divider(),
              Expanded(
                  child: _rateCell('Maximum', '5–5.5×', 'Specialist',
                      isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
              _divider(),
              Expanded(
                  child: _rateCell(
                      'BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', 'Mortgage ref', textThemeColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'INCOME DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.mutedColor,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Income Card
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
              Text(
                'APPLICATION TYPE',
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.mutedColor,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      label: '👤 Solo',
                      active: _appType == 'solo',
                      onTap: () => setState(() {
                        _appType = 'solo';
                        _calculateValues();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tabButton(
                      label: '👫 Joint',
                      active: _appType == 'joint',
                      onTap: () => setState(() {
                        _appType = 'joint';
                        _calculateValues();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _inputField(
                  label: 'Annual Salary (Applicant 1) (£)',
                  controller: _sal1Controller),
              if (_appType == 'joint') ...[
                const SizedBox(height: 12),
                _inputField(
                    label: 'Annual Salary (Applicant 2) (£)',
                    controller: _sal2Controller),
              ],
              const SizedBox(height: 12),
              _inputField(
                  label: 'Bonus / Other Income (50% counted) (£)',
                  controller: _bonusController),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'PROPERTY & DEPOSIT',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.mutedColor,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Property Card
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
                  label: 'Target Property Price (£)',
                  controller: _targetPriceController),
              const SizedBox(height: 12),
              _inputField(
                  label: 'Deposit Available (£)', controller: _depController),
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
              '📋 Check Income Multiples',
              style: AppTextStyles.dmSans(
                  size: 14, color: Colors.white, weight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          // Result Hero Card
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
                  'STANDARD BORROWING (4.5×)',
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
                      CurrencyFormatter.format(stdBorrow, symbol: '£')
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
                          calcType: 'Income Multiples',
                          inputs: {
                            'sal1': _sal1,
                            'sal2': _sal2,
                            'bonus': _bonus,
                            'targetPrice': _targetPrice,
                            'dep': _dep,
                          },
                          results: {
                            'Standard Borrowing': stdBorrow,
                            'Required Borrowing': reqBorrow,
                            'Shortfall': shortfall,
                            'Multiple Used': multUsed,
                          },
                          label:
                              '${CurrencyFormatter.compact(stdBorrow, symbol: '£')} std borrow · ${multUsed.toStringAsFixed(1)}x multiple',
                          currencyCode: 'GBP',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).save(calc);
                        messenger.showSnackBar(
                          const SnackBar(
                            content:
                                Text('✓ Income Multiple calculation saved'),
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
                  'Combined income: ${CurrencyFormatter.format(totalIncome, symbol: '£').split('.').first} p.a.',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text('Required',
                                style: AppTextStyles.dmSans(
                                    size: 9, color: Colors.white54)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(reqBorrow, symbol: '£')
                                  .split('.')
                                  .first,
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text('Shortfall',
                                style: AppTextStyles.dmSans(
                                    size: 9, color: Colors.white54)),
                            const SizedBox(height: 2),
                            Text(
                              shortfall > 0
                                  ? '-${CurrencyFormatter.format(shortfall, symbol: '£').split('.').first}'
                                  : '+${CurrencyFormatter.format(shortfall.abs(), symbol: '£').split('.').first}',
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: shortfall > 0
                                      ? Colors.redAccent
                                      : const Color(0xFF90EE90)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text('Multiple Used',
                                style: AppTextStyles.dmSans(
                                    size: 9, color: Colors.white54)),
                            const SizedBox(height: 2),
                            Text(
                              '${multUsed.toStringAsFixed(2)}×',
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'LENDER CAPACITY & BANDS',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: widget.theme.mutedColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Lender list grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
            ),
            itemCount: lenders.length,
            itemBuilder: (context, idx) {
              final lender = lenders[idx];
              final mult = lender['multiple'] as double;
              final maxAmt = totalIncome * mult;
              final ok = maxAmt >= reqBorrow;
              final topLender = lender['type'] == 'top' && ok;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: topLender
                      ? (isDark
                          ? const Color(0xFF022C22)
                          : const Color(0xFFF0FDF4))
                      : cardBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: topLender
                        ? const Color(0xFF059669)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0x161A1A5E)),
                    width: topLender ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lender['name'] as String,
                          style: AppTextStyles.dmSans(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: textThemeColor)
                              .copyWith(fontFamily: 'Georgia'),
                        ),
                        Text(
                          '$mult× income · ${lender['note']}',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: widget.theme.mutedColor),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(maxAmt, symbol: '£')
                          .split('.')
                          .first,
                      style: AppTextStyles.dmSans(
                          size: 14.5,
                          weight: FontWeight.w800,
                          color: ok
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ok
                            ? (isDark
                                ? const Color(0xFF065F46).withValues(alpha: 0.2)
                                : const Color(0xFFD1FAE5))
                            : (isDark
                                ? const Color(0xFF991B1B).withValues(alpha: 0.2)
                                : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ok ? '✓ Sufficient' : '✗ Short',
                        style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: ok
                              ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                              : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Capacity Bars Card
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
                  'Borrowing Capacity by Multiple',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                ...[3.5, 4.0, 4.5, 5.0, 5.5].map((m) {
                  final amt = totalIncome * m;
                  final pct = maxBorrow > 0 ? (amt / maxBorrow) : 0.0;
                  final color = m <= 4.0
                      ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))
                      : m <= 4.5
                          ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                          : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            '$m× salary',
                            style: AppTextStyles.dmSans(
                                size: 10,
                                color: widget.theme.mutedColor,
                                weight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              height: 18,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF5F5F8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: pct.clamp(0.0, 1.0),
                                  child: Container(color: color),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 60,
                          child: Text(
                            CurrencyFormatter.compact(amt, symbol: '£'),
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: textThemeColor),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _tabButton(
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0D0D2B)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF0D0D2B)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: active ? const Color(0xFFFFD700) : widget.theme.mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8, color: widget.theme.mutedColor, weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.mutedColor),
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
            color: widget.theme.mutedColor,
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
