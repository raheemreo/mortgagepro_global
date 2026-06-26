// lib/features/usa/screens/usa_hoa_what_fees_cover_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';

class USAHoaWhatFeesCoverScreen extends StatelessWidget {
  const USAHoaWhatFeesCoverScreen({super.key});

  static const _theme = CountryThemes.usa;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    // Rate strip values
    const rateStats = [
      {'label': 'Nat\'l Avg', 'value': '\$291', 'note': 'Per Month'},
      {'label': 'Condo Avg', 'value': '\$415', 'note': 'Per Month'},
      {'label': 'SFR Avg', 'value': '\$188', 'note': 'Per Month'},
      {'label': 'HOA States', 'value': '73%', 'note': 'New Homes'},
    ];

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 155,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF4C1D95), Color(0xFF6D28D9)],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 50,
                    child: Opacity(
                      opacity: 0.07,
                      child: Text(
                        '📋',
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('←', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('📋', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'What HOA Fees Cover',
                                    style: AppTextStyles.playfair(size: 17, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 36), // Balanced spacing
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              'Services · Amenities · Maintenance',
                              style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate Strip Block
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: rateStats.map((stat) {
                  final idx = rateStats.indexOf(stat);
                  final isLast = idx == rateStats.length - 1;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                right: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1),
                              ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stat['label']!,
                            style: AppTextStyles.dmSans(
                                size: 8.5, weight: FontWeight.w700, color: Colors.white54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat['value']!,
                            style: AppTextStyles.playfair(
                              size: 15,
                              weight: FontWeight.w800,
                              color: stat['label'] == 'Nat\'l Avg' || stat['label'] == 'HOA States' ? const Color(0xFFFCD34D) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            stat['note']!,
                            style: AppTextStyles.dmSans(
                                size: 7.5, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content body
          SliverList(
            delegate: SliverChildListDelegate([
              // Typical Fee Allocation
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Text(
                  'TYPICAL FEE ALLOCATION',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              // Allocation Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where Your HOA Dollars Go',
                      style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: textCol),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          height: 130,
                          width: 130,
                          child: CustomPaint(
                            painter: _AllocDonutPainter(
                              vals: const [32, 25, 18, 15, 10],
                              colors: const [
                                Color(0xFF1B3F72),
                                Color(0xFF6D28D9),
                                Color(0xFFD97706),
                                Color(0xFF15803D),
                                Color(0xFFB91C1C)
                              ],
                              centerLabel: 'Avg/Mo',
                              centerVal: '\$291',
                              textColor: textCol,
                              mutedColor: mutedCol,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildLegRow('Maintenance', '32%', const Color(0xFF1B3F72), textCol),
                              _buildLegRow('Reserves', '25%', const Color(0xFF6D28D9), textCol),
                              _buildLegRow('Insurance', '18%', const Color(0xFFD97706), textCol),
                              _buildLegRow('Amenities', '15%', const Color(0xFF15803D), textCol),
                              _buildLegRow('Admin/Mgmt', '10%', const Color(0xFFB91C1C), textCol),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Key Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('🏘️', 'HOA Communities', '358K', 'In the U.S. (2024)', cardBg, textCol, mutedCol, borderCol, isDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard('👨‍👩‍👧', 'People in HOAs', '74.2M', '~22% of U.S. pop.', cardBg, textCol, mutedCol, borderCol, isDark),
                    ),
                  ],
                ),
              ),

              // Categories
              _buildCategoryHeader('Exterior & Structure', mutedCol),
              _buildCategoryCard(
                icon: '🏗️',
                title: 'Building & Structural',
                sub: 'Roofs, siding, foundations — typically condo/townhouse',
                items: [
                  const _ItemRow('Roof Repair & Replacement', 'Condo', Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
                  const _ItemRow('Exterior Siding & Paint', 'Condo/TH', Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
                  const _ItemRow('Foundation & Structural', 'Condo', Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
                  const _ItemRow('Windows & Doors (exterior)', 'Varies', Color(0xFFF3E8FF), Color(0xFF6D28D9)),
                  const _ItemRow('Parking Lots & Driveways', 'Most HOAs', Color(0xFFDCFCE7), Color(0xFF15803D)),
                ],
                cardBg: cardBg,
                textCol: textCol,
                mutedCol: mutedCol,
                borderCol: borderCol,
                bgCol: bgCol,
                isDark: isDark,
              ),

              _buildCategoryHeader('Landscaping & Grounds', mutedCol),
              _buildCategoryCard(
                icon: '🌳',
                title: 'Grounds Maintenance',
                sub: 'Lawns, trees, seasonal care — most HOA communities',
                items: [
                  const _ItemRow('Lawn Mowing & Edging', 'Common Areas', Color(0xFFDCFCE7), Color(0xFF15803D)),
                  const _ItemRow('Tree Trimming & Removal', 'Common Areas', Color(0xFFDCFCE7), Color(0xFF15803D)),
                  const _ItemRow('Snow & Ice Removal', 'Climate-Dep.', Color(0xFFFEF9C3), Color(0xFF92400E)),
                  const _ItemRow('Irrigation Systems', 'Most HOAs', Color(0xFFDCFCE7), Color(0xFF15803D)),
                  const _ItemRow('Seasonal Planting', 'Mid–High HOAs', Color(0xFFFEF9C3), Color(0xFF92400E)),
                ],
                cardBg: cardBg,
                textCol: textCol,
                mutedCol: mutedCol,
                borderCol: borderCol,
                bgCol: bgCol,
                isDark: isDark,
              ),

              _buildCategoryHeader('Amenities & Facilities', mutedCol),
              _buildCategoryCard(
                icon: '🏊',
                title: 'Shared Amenities',
                sub: 'Pools, gyms, clubs — depends on community tier',
                items: [
                  const _ItemRow('Swimming Pool & Spa', '\$+50–150/mo', Color(0xFFF3E8FF), Color(0xFF6D28D9)),
                  const _ItemRow('Fitness Center / Gym', '\$+20–60/mo', Color(0xFFF3E8FF), Color(0xFF6D28D9)),
                  const _ItemRow('Clubhouse & Event Space', 'Mid–High HOAs', Color(0xFFF3E8FF), Color(0xFF6D28D9)),
                  const _ItemRow('Tennis / Pickleball Courts', 'Varies', Color(0xFFFEF9C3), Color(0xFF92400E)),
                  const _ItemRow('Playground & Dog Park', 'Common', Color(0xFFDCFCE7), Color(0xFF15803D)),
                  const _ItemRow('Gated Security / Guard', '\$+100–300/mo', Color(0xFFFEE2E2), Color(0xFFB91C1C)),
                ],
                cardBg: cardBg,
                textCol: textCol,
                mutedCol: mutedCol,
                borderCol: borderCol,
                bgCol: bgCol,
                isDark: isDark,
              ),

              _buildCategoryHeader('Utilities & Services', mutedCol),
              _buildCategoryCard(
                icon: '⚡',
                title: 'Utilities & Services',
                sub: 'Shared utilities, trash, internet — varies widely',
                items: [
                  const _ItemRow('Trash & Recycling Collection', 'Most HOAs', Color(0xFFDCFCE7), Color(0xFF15803D)),
                  const _ItemRow('Water & Sewer (common)', 'Condo', Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
                  const _ItemRow('Common Area Electric', 'All HOAs', Color(0xFFDCFCE7), Color(0xFF15803D)),
                  const _ItemRow('Cable / Internet Bundle', 'Some HOAs', Color(0xFFFEF9C3), Color(0xFF92400E)),
                  const _ItemRow('Pest Control (exterior)', 'Varies', Color(0xFFFEF9C3), Color(0xFF92400E)),
                ],
                cardBg: cardBg,
                textCol: textCol,
                mutedCol: mutedCol,
                borderCol: borderCol,
                bgCol: bgCol,
                isDark: isDark,
              ),

              // Coverage Comparison Table
              _buildCategoryHeader('Coverage Comparison', mutedCol),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Condo vs. Single-Family HOA',
                      style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: textCol),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Condo HOA
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark 
                                    ? [const Color(0xFF1E2B4A), const Color(0xFF17203B)]
                                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: const Color(0x3B3B82F6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🏢 Condo HOA',
                                    style: AppTextStyles.dmSans(
                                        size: 11, weight: FontWeight.w800, color: const Color(0xFF1D4ED8))),
                                const SizedBox(height: 8),
                                _buildCompItem('✅ Roof & Exterior', textCol),
                                _buildCompItem('✅ Master Insurance', textCol),
                                _buildCompItem('✅ Plumbing (shared)', textCol),
                                _buildCompItem('✅ All Landscaping', textCol),
                                _buildCompItem('✅ Hallways/Elevators', textCol),
                                _buildCompItem('✅ Pool/Gym', textCol),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // SFR HOA
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF2D1E4A), const Color(0xFF23173B)]
                                    : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: const Color(0x2E6D28D9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🏡 SFR HOA',
                                    style: AppTextStyles.dmSans(
                                        size: 11, weight: FontWeight.w800, color: const Color(0xFF6D28D9))),
                                const SizedBox(height: 8),
                                _buildCompItem('⚠️ Common Areas Only', textCol),
                                _buildCompItem('⚠️ Community Insurance', textCol),
                                _buildCompItem('❌ Your Plumbing', textCol),
                                _buildCompItem('⚠️ Common Landscape', textCol),
                                _buildCompItem('✅ Entrance/Roads', textCol),
                                _buildCompItem('⚠️ Pool if shared', textCol),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // What's NOT Covered
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF3F1B1B), const Color(0xFF2E1414)]
                        : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                  ),
                  border: Border.all(color: const Color(0x38B91C1C)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚫 What HOA Fees Do NOT Cover',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: const Color(0xFFB91C1C))),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 7,
                      crossAxisSpacing: 7,
                      childAspectRatio: 3.2,
                      children: const [
                        _NotCoveredItem(text: '🔧 Your HVAC System'),
                        _NotCoveredItem(text: '🪟 Interior Windows'),
                        _NotCoveredItem(text: '💧 Interior Plumbing'),
                        _NotCoveredItem(text: '🍽️ Your Appliances'),
                        _NotCoveredItem(text: '🎨 Interior Painting'),
                        _NotCoveredItem(text: '🔌 Your Electricity'),
                        _NotCoveredItem(text: '📦 Storage Unit'),
                        _NotCoveredItem(text: '🚗 Your Parking Spot'),
                      ],
                    ),
                  ],
                ),
              ),

              // Due Diligence Tip
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2E1A47), const Color(0xFF1E1030)]
                        : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
                  ),
                  border: Border.all(color: const Color(0x2E6D28D9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Buyer\'s Due Diligence Tip',
                        style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: const Color(0xFF4C1D95))),
                    const SizedBox(height: 5),
                    Text(
                      'Always request the HOA\'s Governing Documents, Meeting Minutes, and Reserve Fund Study before closing. The CC&Rs define exactly what is and isn\'t covered. CAI (Community Associations Institute) reports that 73% of new U.S. homes built in 2024 were in HOA-governed communities.',
                      style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF6D28D9), height: 1.55),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegRow(String name, String pct, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 7),
              Text(name, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: textColor)),
            ],
          ),
          Text(pct, style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String icon, String label, String value, String sub,
      Color cardBg, Color textCol, Color mutedCol, Color borderCol, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.playfair(size: 20, weight: FontWeight.w800, color: textCol)),
          Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String text, Color mutedCol) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String icon,
    required String title,
    required String sub,
    required List<_ItemRow> items,
    required Color cardBg,
    required Color textCol,
    required Color mutedCol,
    required Color borderCol,
    required Color bgCol,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
                    Text(sub, style: AppTextStyles.dmSans(size: 10, color: mutedCol)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.badgeTextColor, // Use same shade for bullet dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(item.name, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: textCol)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.badgeText,
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w800,
                          color: item.badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompItem(String text, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.only(bottom: 5),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x120B1D3A), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: textCol),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  final String name;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;

  const _ItemRow(this.name, this.badgeText, this.badgeBgColor, this.badgeTextColor);
}

class _NotCoveredItem extends StatelessWidget {
  final String text;
  const _NotCoveredItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF4A1A1A) : Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 10.5,
          weight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
        ),
      ),
    );
  }
}

// Custom Painter for Allocation Donut Chart
class _AllocDonutPainter extends CustomPainter {
  final List<double> vals;
  final List<Color> colors;
  final String centerLabel;
  final String centerVal;
  final Color textColor;
  final Color mutedColor;

  const _AllocDonutPainter({
    required this.vals,
    required this.colors,
    required this.centerLabel,
    required this.centerVal,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    final total = vals.reduce((a, b) => a + b);
    if (total == 0) return;

    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < vals.length; i++) {
      final sweepAngle = (vals[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Draw central text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: centerLabel.toUpperCase(),
      style: AppTextStyles.dmSans(size: 7.5, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 8));

    textPainter.text = TextSpan(
      text: centerVal,
      style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 4));
  }

  @override
  bool shouldRepaint(covariant _AllocDonutPainter oldDelegate) {
    return oldDelegate.centerVal != centerVal ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}
