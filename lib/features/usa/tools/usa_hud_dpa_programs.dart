// lib/features/usa/tools/usa_hud_dpa_programs.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class HudDpaProgram {
  final String id;
  final String name;
  final String org;
  final String icon;
  final String iconClass;
  final List<String> type;
  final double maxAmt;
  final String awardType;
  final String repay;
  final int minFico;
  final double maxIncome;
  final double maxPrice;
  final String description;
  final List<String> requirements;
  final String badge;
  final String badgeText;

  const HudDpaProgram({
    required this.id,
    required this.name,
    required this.org,
    required this.icon,
    required this.iconClass,
    required this.type,
    required this.maxAmt,
    required this.awardType,
    required this.repay,
    required this.minFico,
    required this.maxIncome,
    required this.maxPrice,
    required this.description,
    required this.requirements,
    required this.badge,
    required this.badgeText,
  });
}

class USAHudDpaPrograms extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const USAHudDpaPrograms({
    super.key,
    this.theme = CountryThemes.usa,
    this.savedCalc,
  });

  @override
  ConsumerState<USAHudDpaPrograms> createState() => _USAHudDpaProgramsState();
}

class _USAHudDpaProgramsState extends ConsumerState<USAHudDpaPrograms> {
  // Input Controllers
  final _incomeController = TextEditingController(text: '72000');
  final _priceController = TextEditingController(text: '350000');

  String _ftbStatus = 'yes'; // 'yes' or 'no'
  int _selectedFico = 660; // 580, 620, 660, 720

  String _currentFilter = 'all'; // 'all', 'grant', 'firsttime', 'federal', 'state', 'teacher'
  final Set<String> _expandedCards = {}; // Stores IDs of expanded program cards

  // Available programs
  static const List<HudDpaProgram> _programs = [
    HudDpaProgram(
      id: 'nchfa',
      name: 'NC Home Advantage Mortgage',
      org: 'NC Housing Finance Agency',
      icon: '🏛️',
      iconClass: 'nv',
      type: ['grant', 'firsttime', 'state'],
      maxAmt: 15000,
      awardType: 'Forgivable Loan',
      repay: 'None after 15 yrs',
      minFico: 640,
      maxIncome: 126000,
      maxPrice: 385000,
      description: 'Up to \$15,000 forgivable loan, forgiven 20% per year starting year 11.',
      requirements: [
        'First-time or military buyer',
        '640+ FICO score',
        'Income ≤ 80% AMI',
        'HUD counseling required'
      ],
      badge: 'ptag-g',
      badgeText: 'Forgivable',
    ),
    HudDpaProgram(
      id: 'hpap',
      name: 'Home Purchase Assistance (HPAP)',
      org: 'Washington DC DHCD',
      icon: '🏙️',
      iconClass: 'nv',
      type: ['grant', 'firsttime', 'state'],
      maxAmt: 202000,
      awardType: 'Deferred Loan',
      repay: 'At sale/refi',
      minFico: 640,
      maxIncome: 131850,
      maxPrice: 748000,
      description: 'DC\'s flagship DPA — up to \$202,000 deferred, 0% interest.',
      requirements: [
        'DC resident ≥ 12 months',
        'First-time buyer',
        '640+ FICO',
        'Income ≤ 80% AMI'
      ],
      badge: 'ptag-b',
      badgeText: 'Deferred Loan',
    ),
    HudDpaProgram(
      id: 'chdap',
      name: 'California CHDAP',
      org: 'CalHFA',
      icon: '☀️',
      iconClass: 'gd',
      type: ['grant', 'firsttime', 'state'],
      maxAmt: 20000,
      awardType: 'Grant',
      repay: 'Never',
      minFico: 660,
      maxIncome: 180000,
      maxPrice: 660000,
      description: '3.5% of purchase price, max \$20K. Only repaid if you sell within 3 years.',
      requirements: [
        'First-time buyer',
        '660+ FICO',
        'Income limits vary by county',
        'Owner-occupied only'
      ],
      badge: 'ptag-g',
      badgeText: 'Grant',
    ),
    HudDpaProgram(
      id: 'gnnd',
      name: 'Good Neighbor Next Door',
      org: 'HUD / FHA',
      icon: '👮',
      iconClass: 'pur',
      type: ['grant', 'teacher', 'federal'],
      maxAmt: 50000,
      awardType: '50% Discount',
      repay: 'None if 3-yr residency',
      minFico: 580,
      maxIncome: 999999,
      maxPrice: 999999,
      description: '50% off HUD-listed homes for teachers, police, firefighters, EMTs.',
      requirements: [
        'Teacher / Law Enforcement / Firefighter / EMT',
        'Primary residence 36 months',
        'HUD-designated revitalization area',
        'FHA, VA, or Conv. financing'
      ],
      badge: 'ptag-pur',
      badgeText: '50% Discount',
    ),
    HudDpaProgram(
      id: 'nfmc',
      name: 'Freddie Mac BorrowSmart Access',
      org: 'Freddie Mac',
      icon: '🏦',
      iconClass: 'nv',
      type: ['grant', 'federal'],
      maxAmt: 2500,
      awardType: 'Grant',
      repay: 'Never',
      minFico: 620,
      maxIncome: 80000,
      maxPrice: 999999,
      description: '\$2,500 grant for low-income borrowers using Freddie Mac Home Possible.',
      requirements: [
        '620+ FICO',
        'Income ≤ 50% AMI',
        'Home Possible loan only',
        'First-use within 90 days'
      ],
      badge: 'ptag-g',
      badgeText: 'Grant',
    ),
    HudDpaProgram(
      id: 'fannie',
      name: 'Fannie Mae HomeReady DPA',
      org: 'Fannie Mae / State HFAs',
      icon: '🇺🇸',
      iconClass: 'nv',
      type: ['grant', 'firsttime', 'federal'],
      maxAmt: 10000,
      awardType: 'Grant + Forgivable',
      repay: 'Partial if sold < 5 yrs',
      minFico: 620,
      maxIncome: 102000,
      maxPrice: 648000,
      description: 'Paired with HomeReady 3% down; DPA varies by state HFA partnership.',
      requirements: [
        '620+ FICO',
        'Income ≤ 80% AMI',
        'HomeReady mortgage required',
        'Online homebuyer education'
      ],
      badge: 'ptag-b',
      badgeText: 'Federal + State',
    ),
    HudDpaProgram(
      id: 'neighbor',
      name: 'Bank of America Community DPA',
      org: 'Bank of America',
      icon: '🏧',
      iconClass: 'grn',
      type: ['grant', 'firsttime'],
      maxAmt: 17500,
      awardType: 'Grant',
      repay: 'Never',
      minFico: 640,
      maxIncome: 120500,
      maxPrice: 999999,
      description: '\$10K Down Payment Grant + \$7.5K closing cost grant in select markets.',
      requirements: [
        'First-time buyer',
        '640+ FICO',
        'Income limits apply',
        'Eligible markets only (30 cities)'
      ],
      badge: 'ptag-g',
      badgeText: 'Grant — Never Repay',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      _loadSaved(widget.savedCalc!);
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _loadSaved(SavedCalc calc) {
    setState(() {
      _incomeController.text = (calc.inputs['Income'] ?? 72000.0).toStringAsFixed(0);
      _priceController.text = (calc.inputs['Price'] ?? 350000.0).toStringAsFixed(0);
      _ftbStatus = (calc.inputs['FirstTime'] ?? 1.0) == 1.0 ? 'yes' : 'no';
      _selectedFico = (calc.inputs['CreditScore'] ?? 660.0).round();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded saved calculation!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _saveCalculation() async {
    final income = _val(_incomeController);
    final price = _val(_priceController);
    final matches = _getMatches();
    final maxAmt = matches.fold<double>(0.0, (prev, p) => max(prev, p.maxAmt));
    final grants = matches.where((p) => p.awardType.toLowerCase().contains('grant'));
    final maxGrant = grants.fold<double>(0.0, (prev, p) => max(prev, p.maxAmt));
    final forgivable = matches.where((p) => p.awardType.toLowerCase().contains('forgiv'));
    final maxForgivable = forgivable.fold<double>(0.0, (prev, p) => max(prev, p.maxAmt));
    final dpNeeded = price * 0.03;
    final effDP = max(0.0, dpNeeded - maxAmt);

    // Calculate score
    int score = 50;
    if (_selectedFico >= 720) {
      score += 30;
    } else if (_selectedFico >= 660) {
      score += 20;
    } else if (_selectedFico >= 620) {
      score += 10;
    }
    if (_ftbStatus == 'yes') {
      score += 15;
    }
    if (matches.length >= 5) {
      score += 5;
    }
    score = min(score, 100);

    final labelCtrl = TextEditingController(text: 'HUD DPA Eligibility');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Eligibility Results',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Max Assistance ${_formatK(maxAmt)} · Income: ${_formatCompact(income)} · Price: ${_formatCompact(price)}',
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
                hintText: 'Label (e.g. My DPA Results)',
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
          : 'HUD DPA Eligibility';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HUD DPA Eligibility',
        inputs: {
          'Income': income,
          'Price': price,
          'FirstTime': _ftbStatus == 'yes' ? 1.0 : 0.0,
          'CreditScore': _selectedFico.toDouble(),
        },
        results: {
          'MaxAssistance': maxAmt,
          'GrantAmount': maxGrant,
          'ForgivableAmount': maxForgivable,
          'EffectiveDP': effDP,
          'MatchCount': matches.length.toDouble(),
          'EligibilityScore': score.toDouble(),
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eligibility results saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<HudDpaProgram> _getMatches() {
    final income = _val(_incomeController);
    final price = _val(_priceController);

    return _programs.where((p) {
      if (_selectedFico < p.minFico) return false;
      if (income > p.maxIncome && p.maxIncome < 999999) return false;
      if (price > p.maxPrice && p.maxPrice < 999999) return false;
      if (_ftbStatus == 'no' && p.type.contains('firsttime') && !p.type.contains('federal')) return false;

      if (_currentFilter != 'all') {
        if (!p.type.contains(_currentFilter)) return false;
      }

      return true;
    }).toList();
  }

  void _clearAllSaved() async {
    final curCalcs = ref.read(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'HUD DPA Eligibility').toList();
    for (final calc in curCalcs) {
      await ref.read(savedProvider.notifier).delete(calc.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All saved calculations cleared', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatK(double value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  String _formatCompact(double value) {
    return CurrencyFormatter.compact(value, symbol: '\$');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = widget.theme;

    // Trigger local updates
    final income = _val(_incomeController);
    final price = _val(_priceController);

    final matches = _getMatches();
    final maxAmt = matches.fold<double>(0.0, (prev, p) => max(prev, p.maxAmt));
    final grants = matches.where((p) => p.awardType.toLowerCase().contains('grant'));
    final maxGrant = grants.fold<double>(0.0, (prev, p) => max(prev, p.maxAmt));
    final forgivable = matches.where((p) => p.awardType.toLowerCase().contains('forgiv'));
    final maxForgivable = forgivable.fold<double>(0.0, (prev, p) => max(prev, p.maxAmt));
    final dpNeeded = price * 0.03;
    final effDP = max(0.0, dpNeeded - maxAmt);

    // Score calculations
    int score = 50;
    if (_selectedFico >= 720) {
      score += 30;
    } else if (_selectedFico >= 660) {
      score += 20;
    } else if (_selectedFico >= 620) {
      score += 10;
    }
    if (_ftbStatus == 'yes') {
      score += 15;
    }
    if (matches.length >= 5) {
      score += 5;
    }
    score = min(score, 100);

    Color scoreColor = score >= 70
        ? const Color(0xFFD97706)
        : score >= 50
            ? const Color(0xFFB45309)
            : const Color(0xFFB91C1C);

    String scoreLabel = score >= 70
        ? 'Strong Eligibility — Most programs apply'
        : score >= 50
            ? 'Moderate — Review income limits carefully'
            : 'Limited — Check FICO & income requirements';

    // Watch saved
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'HUD DPA Eligibility').toList();

    final isAlreadySaved = savedCalcs.any((calc) {
      final savedIncome = calc.inputs['Income'] ?? 0.0;
      final savedPrice = calc.inputs['Price'] ?? 0.0;
      final savedFtb = (calc.inputs['FirstTime'] ?? 1.0) == 1.0 ? 'yes' : 'no';
      final savedFico = (calc.inputs['CreditScore'] ?? 660.0).round();
      return savedIncome == income &&
          savedPrice == price &&
          savedFtb == _ftbStatus &&
          savedFico == _selectedFico;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info Banner (Static info matching HTML)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildRsCell('Programs', '2,500+', 'Nationwide', isGold: true)),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('Max Grant', '\$25K', 'Select States')),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('Avg Award', '\$10K', '2024 Data')),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('Forgiven', '100%', 'After 5 yrs', isGold: true)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION: Eligibility Estimate Header
        _buildSectionHeader('Your Eligibility Estimate', countBadge: '${matches.length} Programs'),
        const SizedBox(height: 8),

        // Result Hero Card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 36,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED DPA ASSISTANCE AVAILABLE',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Up to ${_formatCompact(maxAmt)}',
                        style: AppTextStyles.dmSans(
                          size: 34,
                          weight: FontWeight.w800,
                          color: const Color(0xFFFCD34D),
                        ).copyWith(fontFamily: 'Georgia', height: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Based on ${_formatCompact(income)} income · ${matches.length} programs found',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroStat('Grant (Free)', _formatCompact(maxGrant), 'Non-repayable'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStat('Forgivable Loan', _formatCompact(maxForgivable), '0% if you stay 5 yrs'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStat('Effective DP', effDP <= 0 ? '\$0 Possible' : _formatCompact(effDP), 'Out-of-pocket'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Circular decorative shape
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // House emoji watermark
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Text(
                    '🏠',
                    style: TextStyle(
                      fontSize: 72,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Stats boxes strip
        Row(
          children: [
            Expanded(
              child: _buildStatBox(matches.length.toString(), 'Programs Match'),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _buildStatBox(grants.length.toString(), 'Grant Only'),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _buildStatBox(_formatK(maxAmt), 'Max Assist.', textColor: const Color(0xFF15803D)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Filter pills row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterPill('all', 'All Programs'),
              _buildFilterPill('grant', 'Grants Only'),
              _buildFilterPill('firsttime', 'First-Time Buyer'),
              _buildFilterPill('federal', 'Federal'),
              _buildFilterPill('state', 'State'),
              _buildFilterPill('teacher', 'Public Servant'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // INPUTS CARD
        _buildSectionHeader('Check Your Eligibility'),
        const SizedBox(height: 8),
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
                  const Text('🔍 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'DPA Eligibility Search',
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Annual Household Income
              _buildInputField(
                label: 'Annual Household Income',
                controller: _incomeController,
                prefix: '\$',
              ),
              const SizedBox(height: 13),

              // Home Purchase Price
              _buildInputField(
                label: 'Home Purchase Price',
                controller: _priceController,
                prefix: '\$',
              ),
              const SizedBox(height: 13),

              // First-time homebuyer toggle
              Text(
                'FIRST-TIME HOMEBUYER?',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTogglePill('yes', 'Yes — First Time'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTogglePill('no', 'No — Repeat Buyer'),
                  ),
                ],
              ),
              const SizedBox(height: 13),

              // Credit score selection
              Text(
                'CREDIT SCORE (FICO)',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildFicoPill(580, '580–619')),
                  const SizedBox(width: 5),
                  Expanded(child: _buildFicoPill(620, '620–659')),
                  const SizedBox(width: 5),
                  Expanded(child: _buildFicoPill(660, '660–719')),
                  const SizedBox(width: 5),
                  Expanded(child: _buildFicoPill(720, '720+')),
                ],
              ),
              const SizedBox(height: 16),

              // Find DPA programs button
              GestureDetector(
                onTap: () => setState(() {}),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFF92400E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🔍 Find My DPA Programs',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Save button (Gold Outline or Green Solid if saved)
              GestureDetector(
                onTap: isAlreadySaved
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('This scenario is already saved in history!',
                                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                            backgroundColor: const Color(0xFF15803D),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : _saveCalculation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: isAlreadySaved
                        ? (isDark ? const Color(0xFF166534).withValues(alpha: 0.2) : const Color(0xFFDCFCE7))
                        : theme.getCardColor(context),
                    border: Border.all(
                      color: isAlreadySaved ? const Color(0xFF15803D) : const Color(0xFFD97706),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAlreadySaved ? '✓' : '💾',
                        style: TextStyle(
                          fontSize: 14,
                          color: isAlreadySaved ? const Color(0xFF15803D) : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAlreadySaved ? 'Results Saved to History' : 'Save My Eligibility Results',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: isAlreadySaved ? const Color(0xFF15803D) : const Color(0xFFD97706),
                        ).copyWith(fontFamily: 'Georgia'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ELIGIBILITY BREAKDOWN CARD
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
              Text(
                '📊 Eligibility Breakdown',
                style: AppTextStyles.dmSans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 14),

              // Radial progress indicator row
              Row(
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _EligibilityDonutPainter(
                      score: score / 100.0,
                      scoreColor: scoreColor,
                      isDark: isDark,
                      centerText: '$score%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$score%',
                          style: AppTextStyles.dmSans(
                            size: 32,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ).copyWith(fontFamily: 'Georgia', height: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scoreLabel,
                          style: AppTextStyles.dmSans(
                            size: 10.5,
                            color: theme.getMutedColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details criteria rows
              _buildCriteriaRow(
                'Credit Score',
                _selectedFico >= 720 ? 100 : _selectedFico >= 660 ? 75 : _selectedFico >= 620 ? 50 : 25,
                _selectedFico >= 720 ? const Color(0xFF15803D) : _selectedFico >= 660 ? const Color(0xFFD97706) : const Color(0xFFB91C1C),
                _selectedFico >= 720 ? 'Excellent' : _selectedFico >= 660 ? 'Good' : 'Fair',
              ),
              const SizedBox(height: 9),
              _buildCriteriaRow(
                'Income Limit',
                75,
                const Color(0xFFD97706),
                'Within Range',
              ),
              const SizedBox(height: 9),
              _buildCriteriaRow(
                'First-Time Buyer',
                _ftbStatus == 'yes' ? 100 : 60,
                _ftbStatus == 'yes' ? const Color(0xFF15803D) : const Color(0xFF4A5C7A),
                _ftbStatus == 'yes' ? 'Eligible' : 'May Qualify',
              ),
              const SizedBox(height: 9),
              _buildCriteriaRow(
                'Program Matches',
                min((matches.length / 7.0) * 100.0, 100.0),
                const Color(0xFF1B3F72),
                '${matches.length} Found',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // PROGRAM CARDS LIST
        _buildSectionHeader('Top Matching Programs', countBadge: matches.length.toString()),
        const SizedBox(height: 8),

        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No matching programs found based on your parameters.',
                style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final prog = matches[index];
              final isFeatured = index == 0;
              final isExpanded = _expandedCards.contains(prog.id);

              return _buildProgramCardWidget(prog, isFeatured, isExpanded);
            },
          ),
        const SizedBox(height: 20),

        // COMPARISON TABLE
        _buildComparisonTable(matches),
        const SizedBox(height: 20),

        // HOW TO APPLY SECTION
        _buildSectionHeader('How to Apply'),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildApplyStep('1️⃣', 'Get Pre-Approved First', 'HUD-approved lenders only · Confirm income limits'),
            const SizedBox(height: 9),
            _buildApplyStep('2️⃣', 'Complete Homebuyer Education', 'Required for most programs · 8-hr HUD course · Often free'),
            const SizedBox(height: 9),
            _buildApplyStep('3️⃣', 'Gather Documentation', 'W-2s, tax returns, bank statements, pay stubs'),
            const SizedBox(height: 9),
            _buildApplyStep('4️⃣', 'Apply Through HUD-Approved Lender', 'Visit hud.gov/findahousinucounselor or call 800-569-4287'),
          ],
        ),
        const SizedBox(height: 20),

        // SAVED HISTORIES PANEL
        _buildSectionHeader('Saved Results', onClearAll: savedCalcs.isNotEmpty ? _clearAllSaved : null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: savedCalcs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No saved results yet. Tap "Save My Eligibility Results" above to bookmark a plan.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: savedCalcs.map((calc) {
                    final isLast = savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                    final savedMax = calc.results['MaxAssistance'] ?? 0.0;
                    final savedIncome = calc.inputs['Income'] ?? 0.0;
                    final savedPrice = calc.inputs['Price'] ?? 0.0;
                    final savedMatches = calc.results['MatchCount'] ?? 0.0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isLast
                                ? Colors.transparent
                                : theme.getBorderColor(context).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _loadSaved(calc),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Up to ${_formatCompact(savedMax)} DPA',
                                    style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: theme.getTextColor(context),
                                    ).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Income ${_formatCompact(savedIncome)} · Price ${_formatCompact(savedPrice)} · ${savedMatches.toInt()} programs',
                                    style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      color: theme.getMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await ref.read(savedProvider.notifier).delete(calc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed saved calculation', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('🗑️', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(String title, {String? countBadge, VoidCallback? onClearAll}) {
    final theme = widget.theme;
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
                color: theme.getMutedColor(context),
                letterSpacing: 1,
              ),
            ),
            if (countBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.getTextColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  countBadge,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0A0F1E)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onClearAll != null)
          GestureDetector(
            onTap: onClearAll,
            child: Text(
              'Clear All',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRsCell(String label, String value, String note, {bool isGold = false}) {
    final textColor = isGold ? const Color(0xFFFCD34D) : Colors.white;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            color: Colors.white.withValues(alpha: 0.48),
            weight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 15,
            weight: FontWeight.w800,
            color: textColor,
          ).copyWith(fontFamily: 'Georgia'),
        ),
        const SizedBox(height: 1),
        Text(
          note,
          style: AppTextStyles.dmSans(
            size: 8,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }

  Widget _buildRsDivider() {
    return Container(
      width: 1,
      height: 25,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }

  Widget _buildHeroStat(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.50),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: Colors.white,
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 8,
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, {Color? textColor}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 18,
              weight: FontWeight.w900,
              color: textColor ?? theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8.5,
              color: theme.getMutedColor(context),
              weight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String filterId, String label) {
    final theme = widget.theme;
    final isActive = _currentFilter == filterId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filterId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? theme.textColor : theme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.textColor : theme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0F1E) : Colors.white)
                : theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? prefix,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 8),
                  child: Text(
                    prefix,
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTogglePill(String id, String label) {
    final theme = widget.theme;
    final isActive = _ftbStatus == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _ftbStatus = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.textColor : theme.getBgColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.textColor : theme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0F1E) : Colors.white)
                : theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFicoPill(int value, String label) {
    final theme = widget.theme;
    final isActive = _selectedFico == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFico = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.textColor : theme.getBgColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.textColor : theme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0F1E) : Colors.white)
                : theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String name, double pct, Color color, String status) {
    final theme = widget.theme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w700,
                color: theme.getTextColor(context),
              ),
            ),
            Text(
              status,
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: theme.getBgColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * 0.7 * (pct / 100.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgramCardWidget(HudDpaProgram prog, bool isFeatured, bool isExpanded) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color cardBgColor = theme.getCardColor(context);
    Border border = Border.all(color: theme.getBorderColor(context));
    if (isFeatured) {
      cardBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB);
      border = Border.all(color: const Color(0xFFD97706), width: 2.0);
    }

    Gradient? iconGradient;
    Color? iconBg;
    if (prog.iconClass == 'nv') {
      iconGradient = const LinearGradient(
        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (prog.iconClass == 'gd') {
      iconGradient = const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFF92400E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (prog.iconClass == 'grn') {
      iconGradient = const LinearGradient(
        colors: [Color(0xFF15803D), Color(0xFF166534)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (prog.iconClass == 'pur') {
      iconGradient = const LinearGradient(
        colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      iconBg = const Color(0xFFF0F4FF);
    }

    Color tagBg = const Color(0xFFEFF6FF);
    Color tagColor = const Color(0xFF1D4ED8);
    if (prog.badge == 'ptag-g') {
      tagBg = const Color(0xFFDCFCE7);
      tagColor = const Color(0xFF15803D);
    } else if (prog.badge == 'ptag-pur') {
      tagBg = const Color(0xFFF5F3FF);
      tagColor = const Color(0xFF6D28D9);
    } else if (prog.badge == 'ptag-o') {
      tagBg = const Color(0xFFFEF3C7);
      tagColor = const Color(0xFFB45309);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCards.remove(prog.id);
          } else {
            _expandedCards.add(prog.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: border,
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
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    gradient: iconGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    prog.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prog.name,
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context),
                        ).copyWith(fontFamily: 'Georgia', height: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prog.org,
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatK(prog.maxAmt),
                      style: AppTextStyles.dmSans(
                        size: 16,
                        weight: FontWeight.w800,
                        color: const Color(0xFF1B3F72),
                      ).copyWith(fontFamily: 'Georgia'),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Max Award',
                      style: AppTextStyles.dmSans(
                        size: 8.5,
                        color: theme.getMutedColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tags
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prog.badgeText,
                    style: AppTextStyles.dmSans(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: tagColor,
                    ),
                  ),
                ),
                if (prog.type.contains('firsttime'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'First-Time',
                      style: AppTextStyles.dmSans(
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                if (prog.type.contains('federal'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Federal',
                      style: AppTextStyles.dmSans(
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF6D28D9),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Details 2x2 grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildDetailsItem('Min FICO', '${prog.minFico}+'),
                _buildDetailsItem('Repayment', prog.repay),
                _buildDetailsItem('Award Type', prog.awardType),
                _buildDetailsItem('Income Limit', prog.maxIncome < 999999 ? '${_formatK(prog.maxIncome)}/yr' : 'No Limit'),
              ],
            ),

            // Footer / Expand trigger
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.getBorderColor(context),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✓ Likely Eligible',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.getMutedColor(context),
                  ),
                ],
              ),
            ),

            // Expanded Area
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                '📋 Requirements',
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: prog.requirements.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req,
                            style: AppTextStyles.dmSans(
                              size: 10.5,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                prog.description,
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  color: theme.getMutedColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsItem(String label, String value) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8,
              color: theme.getMutedColor(context),
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(List<HudDpaProgram> matches) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = matches.take(6).toList();

    return Container(
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
          Text(
            'Side-by-Side Comparison',
            style: AppTextStyles.dmSans(
              size: 12.5,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('PROGRAM', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              ),
              Expanded(
                child: Text('MAX \$', textAlign: TextAlign.center, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              ),
              Expanded(
                child: Text('FICO', textAlign: TextAlign.center, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              ),
              Expanded(
                child: Text('REPAY?', textAlign: TextAlign.center, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(),

          // Rows
          ...displayList.map((p) {
            final isRepayNo = p.repay.toLowerCase() == 'never' || p.repay.toLowerCase().contains('none');
            final isFicoLow = p.minFico <= 620;
            final isFicoMedium = p.minFico <= 660;

            final List<String> wordsName = p.name.split(' ');
            final shortName = wordsName.length > 3 ? '${wordsName.take(3).join(' ')}...' : p.name;
            final List<String> wordsOrg = p.org.split(' ');
            final shortOrg = wordsOrg.length > 2 ? '${wordsOrg.take(2).join(' ')}...' : p.org;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.getBorderColor(context).withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shortName,
                          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          shortOrg,
                          style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatK(p.maxAmt),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF15803D)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${p.minFico}+',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isFicoLow
                            ? const Color(0xFF15803D)
                            : isFicoMedium
                                ? const Color(0xFFB45309)
                                : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isRepayNo ? 'No' : 'Yes',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isRepayNo ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApplyStep(String stepNum, String title, String desc) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
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
            child: Text(stepNum, style: const TextStyle(fontSize: 17)),
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
                  ).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
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

class _EligibilityDonutPainter extends CustomPainter {
  final double score;
  final Color scoreColor;
  final bool isDark;
  final String centerText;

  _EligibilityDonutPainter({
    required this.score,
    required this.scoreColor,
    required this.isDark,
    required this.centerText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 10.0;

    // Background track
    final paintBg = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0x131B3F72)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    // Active progress arc
    if (score > 0) {
      final sweepAngle = 2 * pi * score;
      final paintActive = Paint()
        ..color = scoreColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Rotate to start from top
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, paintActive);
    }

    // Paint the score text in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
