// lib/features/newzealand/tools/nz_kainga_ora.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZKaingaOra extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZKaingaOra({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZKaingaOra> createState() => _NZKaingaOraState();
}

class _NZKaingaOraState extends ConsumerState<NZKaingaOra> {
  final _incomeController = TextEditingController(text: '120000');
  final _propValueController = TextEditingController(text: '750000');

  int _buyers = 2; // 1 or 2
  String _propType = 'existing'; // 'new' | 'existing'
  int _ksDuration = 3; // 0 (Under 3yrs), 3 (3-4yrs), 5 (5+yrs)
  String _region = 'chch'; // 'auckland', 'wellington', 'chch', 'other'

  bool _showResults = true;

  final Map<String, double> _priceCaps = {
    'auckland': 875000,
    'wellington': 750000,
    'chch': 550000,
    'other': 525000,
  };

  final Map<int, double> _incomeCaps = {
    1: 150000,
    2: 180000,
  };

  @override
  void dispose() {
    _incomeController.dispose();
    _propValueController.dispose();
    super.dispose();
  }

  void _saveEligibility() async {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final propValue = double.tryParse(_propValueController.text) ?? 0;
    final incomeCap = _incomeCaps[_buyers] ?? 180000;
    final priceCap = _priceCaps[_region] ?? 525000;

    final incomeOk = income <= incomeCap;
    final priceOk = propValue <= priceCap;
    final ksOk = _ksDuration >= 3;
    final eligible = incomeOk && priceOk && ksOk;

    int grantPerBuyer = 0;
    if (_ksDuration >= 5) {
      grantPerBuyer = _propType == 'new' ? 10000 : 5000;
    } else if (_ksDuration >= 3) {
      grantPerBuyer = _propType == 'new' ? 6000 : 3000;
    }
    final grantTotal = grantPerBuyer * _buyers;
    final depositSupport = eligible ? grantTotal + 37500.0 : 0.0;

    final labelCtrl = TextEditingController(text: 'Kāinga Ora Eligibility');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_kainga_ora'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Eligibility Result',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving Kāinga Ora Eligibility Report\nStatus: ${eligible ? "Eligible" : "Not Eligible"} · Est. Deposit: ${CurrencyFormatter.compact(depositSupport, symbol: "NZ\$")}',
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
                hintText: 'Label (e.g. FHB Eligibility Check)',
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
          : 'Kāinga Ora Eligibility';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Kāinga Ora Eligibility',
        inputs: {
          'income': income,
          'buyers': _buyers.toDouble(),
          'propType': _propType == 'new' ? 1.0 : 0.0,
          'ksDuration': _ksDuration.toDouble(),
          'propValue': propValue,
          'region': _region == 'auckland'
              ? 0.0
              : _region == 'wellington'
                  ? 1.0
                  : _region == 'chch'
                      ? 2.0
                      : 3.0,
        },
        results: {
          'grantTotal': grantTotal.toDouble(),
          'eligible': eligible ? 1.0 : 0.0,
          'depositSupport': depositSupport,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eligibility check saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final income = double.tryParse(_incomeController.text) ?? 0;
    final propValue = double.tryParse(_propValueController.text) ?? 0;

    final incomeCap = _incomeCaps[_buyers] ?? 180000;
    final priceCap = _priceCaps[_region] ?? 525000;

    final incomeOk = income <= incomeCap;
    final priceOk = propValue <= priceCap;
    final ksOk = _ksDuration >= 3;
    final eligible = incomeOk && priceOk && ksOk;

    int grantPerBuyer = 0;
    if (_ksDuration >= 5) {
      grantPerBuyer = _propType == 'new' ? 10000 : 5000;
    } else if (_ksDuration >= 3) {
      grantPerBuyer = _propType == 'new' ? 6000 : 3000;
    }
    final grantTotal = grantPerBuyer * _buyers;
    final depositSupport = eligible ? grantTotal + 37500.0 : 0.0;

    final cardColor = theme.getCardColor(context);
    final borderColor = theme.getBorderColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About Kāinga Ora',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'kaingaora.govt.nz →',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Hero Info Box
        Container(
          padding: const EdgeInsets.all(19),
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
                'KĀINGA ORA – HOMES AND COMMUNITIES · TE TŪĀPOKA',
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: Colors.white60,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'Government '),
                    TextSpan(text: 'Housing & Support', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: ' Schemes NZ 2025'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStat('Public Houses', '72,000+', const Color(0xFF6EE7B7)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroStat('First Home Grants', '\$10K', const Color(0xFFF5D060)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroStat('FHP Equity', 'Up to 25%', Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Eligibility Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Check Your Eligibility',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Full Guide →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Calculator Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧮 HomeStart Grant & First Home Partner Calculator',
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 14),

              // Row 1: Income and Buyers
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Household Income (NZD)',
                      controller: _incomeController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Buyers',
                      value: _buyers,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 Person')),
                        DropdownMenuItem(value: 2, child: Text('2 People')),
                      ],
                      onChanged: (val) => setState(() => _buyers = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Property Type and KS Duration
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Property Type',
                      value: _propType,
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New Build')),
                        DropdownMenuItem(value: 'existing', child: Text('Existing Home')),
                      ],
                      onChanged: (val) => setState(() => _propType = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: 'KiwiSaver Duration',
                      value: _ksDuration,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Under 3 years')),
                        DropdownMenuItem(value: 3, child: Text('3–4 years')),
                        DropdownMenuItem(value: 5, child: Text('5+ years')),
                      ],
                      onChanged: (val) => setState(() => _ksDuration = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 3: Property Value and Region
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Property Value (NZD)',
                      controller: _propValueController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Region',
                      value: _region,
                      items: const [
                        DropdownMenuItem(value: 'auckland', child: Text('Auckland')),
                        DropdownMenuItem(value: 'wellington', child: Text('Wellington')),
                        DropdownMenuItem(value: 'chch', child: Text('Christchurch')),
                        DropdownMenuItem(value: 'other', child: Text('Other NZ')),
                      ],
                      onChanged: (val) => setState(() => _region = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: () => setState(() => _showResults = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  '🌿 Check My Eligibility',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),

              if (_showResults) ...[
                const SizedBox(height: 14),
                // Results banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: eligible
                        ? const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)])
                        : const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]),
                    border: Border.all(
                      color: eligible ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eligible ? '✅ You May Be Eligible!' : '❌ Not Currently Eligible',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: eligible ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        eligible
                            ? 'Income of ${CurrencyFormatter.compact(income, symbol: "NZ\$")} is within the ${CurrencyFormatter.compact(incomeCap.toDouble(), symbol: "NZ\$")} cap. Property value is within regional cap. KiwiSaver requirement met.'
                            : _buildFailReason(incomeOk, priceOk, ksOk, income, incomeCap, propValue, priceCap),
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: eligible ? const Color(0xFF047857) : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Result Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: [
                    _buildResultBox('HomeStart Grant', CurrencyFormatter.compact(grantTotal.toDouble(), symbol: 'NZ\$'), 'per buyer'),
                    _buildResultBox('KiwiSaver Withdrawal', eligible ? 'Eligible' : (ksOk ? 'Eligible' : 'Not yet'), 'min 3yrs contrib.'),
                    _buildResultBox('FHP Equity Share', eligible ? 'Up to 25%' : 'N/A', 'Govt co-buys'),
                    _buildResultBox('Est. Deposit Support', eligible ? '~${CurrencyFormatter.compact(depositSupport, symbol: "NZ\$")}' : 'Check again', 'combined boost'),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Save Button
        if (_showResults) ...[
          ElevatedButton.icon(
            onPressed: _saveEligibility,
            icon: const Text('📥', style: TextStyle(fontSize: 14)),
            label: Text(
              'Save Eligibility Result',
              style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // First Home Partner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'First Home Partner (FHP)',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Apply →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A6B4A), Color(0xFF0D3B2E)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🤝', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('First Home Partner', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: textCol)),
                        Text('Kāinga Ora co-buys up to 25% equity in your home', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Active 2025', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF065F46), weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Key Criteria', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: mutedCol)),
              const SizedBox(height: 8),
              _buildCriteriaRow('Income limit (single)', 0.8, r'≤ $150K', theme.primaryColor),
              _buildCriteriaRow('Income limit (couple)', 0.9, r'≤ $180K', theme.primaryColor),
              _buildCriteriaRow('Max equity share', 0.25, '25%', const Color(0xFF0D9488)),
              _buildCriteriaRow('Max property value (AKL)', 0.7, '\$875K', const Color(0xFFD4A017)),

              const SizedBox(height: 16),
              // Donut Chart Container
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _CoOwnershipDonutPainter(isDark: isDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem('Your Mortgage', '50%', theme.primaryColor),
                        _buildLegendItem('Your Deposit', '25%', const Color(0xFF0D9488)),
                        _buildLegendItem('Kāinga Ora Share', '25%', const Color(0xFFC0C8C1)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // HomeStart Grant Breakdowns
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HomeStart Grant (2025 Rates)',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Apply via Kāinga Ora →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🎁', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HomeStart Grant', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: textCol)),
                        Text('KiwiSaver-linked grant for first home buyers', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Up to \$10,000 per buyer', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF0F766E), weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Grant Amount by Property & KiwiSaver Duration', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: mutedCol)),
              const SizedBox(height: 8),
              _buildCriteriaRow('New Build (3–4 yrs KS)', 0.6, '\$6,000', theme.primaryColor),
              _buildCriteriaRow('New Build (5+ yrs KS)', 1.0, '\$10,000', theme.primaryColor),
              _buildCriteriaRow('Existing Home (3–4 yrs KS)', 0.3, '\$3,000', const Color(0xFF0D9488)),
              _buildCriteriaRow('Existing Home (5+ yrs KS)', 0.5, '\$5,000', const Color(0xFF0D9488)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEDF5F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⚠️ Income caps: Single ≤ \$150,000 / Couple ≤ \$180,000 combined gross income.\n🏠 Price caps (2025): Auckland \$875K · Wellington \$750K · Christchurch \$550K · Other \$525K.',
                  style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Public Housing waitlist
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Public Housing Register 2025',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Apply →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋 NZ Public Housing Waitlist Snapshot (Q1 2025)', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 12),
              _buildCriteriaRow('Households waiting', 0.92, '23,100+', const Color(0xFFC0392B)),
              _buildCriteriaRow('Auckland', 0.75, '~8,500', const Color(0xFFF97316)),
              _buildCriteriaRow('Wellington', 0.38, '~3,200', const Color(0xFF0D9488)),
              _buildCriteriaRow('Avg wait (weeks)', 0.6, '68 wks', const Color(0xFFD4A017)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.15) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFECACA)),
                ),
                child: Text(
                  '📞 Need public housing? Call Kāinga Ora on 0800 801 601 or apply at kaingaora.govt.nz. Priority given to those in severe housing need.',
                  style: AppTextStyles.dmSans(size: 9.5, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Application Journey
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'First Home Application Journey',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: textCol,
              ),
            ),
            Text(
              'Full Guide →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📍 Step-by-Step: First Home Partner', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: textCol)),
              const SizedBox(height: 16),
              _buildTimelineItem(1, 'Check Eligibility Online', 'Visit kaingaora.govt.nz · confirm income & KiwiSaver meet thresholds', true, false),
              _buildTimelineItem(2, 'Get Mortgage Pre-Approval', 'Approach ANZ, ASB, Kiwibank or other approved lenders for pre-approval', false, true),
              _buildTimelineItem(3, 'Find an Eligible Property', 'New build or existing home within regional price caps · must be NZ citizen/PR', false, false),
              _buildTimelineItem(4, 'Apply to Kāinga Ora', 'Submit application with income proof, KS statement and property details', false, false),
              _buildTimelineItem(5, 'Settlement & Move In', 'Buy back Kāinga Ora\'s share anytime · no set timeline required', false, false, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Official Resources List
        Text(
          'Official Resources',
          style: AppTextStyles.playfair(
            size: 15,
            weight: FontWeight.w800,
            color: textCol,
          ),
        ),
        const SizedBox(height: 10),
        _buildResourceCard('🏛️', 'Kāinga Ora Official Site', 'kaingaora.govt.nz · Applications & eligibility'),
        _buildResourceCard('🥝', 'KiwiSaver First Home Withdrawal', 'ird.govt.nz · Withdraw your KiwiSaver savings'),
        _buildResourceCard('📋', 'HomeStart Grant Application', 'Apply via Kāinga Ora · Required documents checklist'),
        _buildResourceCard('📞', 'Housing Help Line', '0800 801 601 · Mon–Fri 8am–5pm NZST'),
      ],
    );
  }

  Widget _buildHeroStat(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          height: 38,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: widget.theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.playfair(size: 13, color: widget.theme.getTextColor(context), weight: FontWeight.w800),
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

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          height: 38,
          decoration: BoxDecoration(
            color: widget.theme.getBgColor(context),
            border: Border.all(color: widget.theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: isDark ? const Color(0xFF141C33) : Colors.white,
              style: AppTextStyles.dmSans(size: 12, color: widget.theme.getTextColor(context), weight: FontWeight.bold),
              icon: Icon(Icons.arrow_drop_down, color: widget.theme.getTextColor(context), size: 18),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBox(String label, String val, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: widget.theme.primaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String name, double widthPct, String val, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              name,
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
            ),
          ),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: widget.theme.getBgColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widthPct,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              val,
              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(int step, String title, String desc, bool active, bool done, {bool isLast = false}) {
    final dotColor = active
        ? widget.theme.primaryColor
        : (done ? const Color(0xFFECFDF5) : widget.theme.getBgColor(context));
    final dotBorder = active
        ? widget.theme.primaryColor
        : (done ? widget.theme.primaryColor : widget.theme.getBorderColor(context));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotBorder, width: 2),
                  boxShadow: active
                      ? [BoxShadow(color: widget.theme.primaryColor.withValues(alpha: 0.15), blurRadius: 4, spreadRadius: 2)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  step.toString(),
                  style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.bold,
                    color: active ? Colors.white : (done ? widget.theme.primaryColor : widget.theme.getTextColor(context)),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  color: widget.theme.getBorderColor(context),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
                  const SizedBox(height: 2),
                  Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: widget.theme.getCardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.theme.getBorderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.theme.getBgColor(context),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
                  const SizedBox(height: 2),
                  Text(sub, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: widget.theme.getTextColor(context).withValues(alpha: 0.18)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context)),
            ),
          ),
          Text(
            pct,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
          ),
        ],
      ),
    );
  }

  String _buildFailReason(bool incomeOk, bool priceOk, bool ksOk, double income, double incomeCap, double propValue, double priceCap) {
    List<String> reasons = [];
    if (!incomeOk) {
      reasons.add('income ${CurrencyFormatter.compact(income, symbol: "NZ\$")} exceeds ${CurrencyFormatter.compact(incomeCap.toDouble(), symbol: "NZ\$")} cap');
    }
    if (!priceOk) {
      reasons.add('property value ${CurrencyFormatter.compact(propValue, symbol: "NZ\$")} exceeds ${CurrencyFormatter.compact(priceCap.toDouble(), symbol: "NZ\$")} regional cap');
    }
    if (!ksOk) {
      reasons.add('KiwiSaver must be active for at least 3 years');
    }
    return 'Issue: ${reasons.join("; ")}.\nContact Kāinga Ora for alternative options.';
  }
}

class _CoOwnershipDonutPainter extends CustomPainter {
  final bool isDark;
  const _CoOwnershipDonutPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    const double strokeW = 12.0;
    final double ringRadius = radius - strokeW / 2;

    final basePaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    // Mortgage: 50% = 180 degrees (starts at -90deg)
    final mortgagePaint = Paint()
      ..color = const Color(0xFF1A6B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -3.14159 / 2, 3.14159, false, mortgagePaint);

    // Deposit: 25% = 90 degrees (starts at 90deg)
    final depositPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 3.14159 / 2, 3.14159 / 2, false, depositPaint);

    // Kāinga Ora: 25% = 90 degrees (starts at 180deg)
    final koPaint = Paint()
      ..color = const Color(0xFFC0C8C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawArc(rect, 3 * 3.14159 / 2, -3.14159 / 2, false, koPaint);

    // Draw center text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: '75%',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0A0F0D),
        fontFamily: 'Palatino',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -textPainter.height + 4));

    final subPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    subPainter.text = TextSpan(
      text: 'Your Share',
      style: TextStyle(
        fontSize: 8,
        color: isDark ? Colors.white54 : const Color(0xFF4A6358),
        fontFamily: 'Helvetica Neue',
      ),
    );
    subPainter.layout();
    subPainter.paint(canvas, center + Offset(-subPainter.width / 2, 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
