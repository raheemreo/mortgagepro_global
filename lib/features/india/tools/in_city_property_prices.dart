// lib/features/india/tools/in_city_property_prices.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' show max, min;
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INCityPropertyPrices extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INCityPropertyPrices({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INCityPropertyPrices> createState() => _INCityPropertyPricesState();
}

class _INCityPropertyPricesState extends ConsumerState<INCityPropertyPrices> {
  // Search & Filter state
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'all'; // all, tier1, tier2, tier3, trending

  // Estimator state
  String _selectedCity = 'Mumbai';
  double _carpetArea = 1000.0; // sqft
  late TextEditingController _carpetAreaCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _localityPanelKey = GlobalKey();

  // Full City Database from HTML
  static final List<Map<String, dynamic>> _cities = [
    {
      'icon': '🌆',
      'name': 'Mumbai',
      'state': 'Maharashtra',
      'price': 22400,
      'yoy': 3.2,
      'tier': 'tier1',
      'trending': true,
      'localities': [
        {'n': 'Bandra West', 'p': 55000, 'c': '+4.1%'},
        {'n': 'Powai', 'p': 18500, 'c': '+3.8%'},
        {'n': 'Thane', 'p': 12200, 'c': '+5.1%'},
        {'n': 'Navi Mumbai', 'p': 10800, 'c': '+4.7%'}
      ]
    },
    {
      'icon': '🏙️',
      'name': 'Delhi NCR',
      'state': 'Delhi · Noida · Gurgaon',
      'price': 12800,
      'yoy': 4.1,
      'tier': 'tier1',
      'trending': true,
      'localities': [
        {'n': 'Dwarka Expressway', 'p': 9200, 'c': '+8.2%'},
        {'n': 'Noida Sec 150', 'p': 7800, 'c': '+6.5%'},
        {'n': 'Greater Noida West', 'p': 5400, 'c': '+7.1%'},
        {'n': 'Gurgaon Golf Course', 'p': 18500, 'c': '+3.2%'}
      ]
    },
    {
      'icon': '💻',
      'name': 'Bengaluru',
      'state': 'Karnataka',
      'price': 11500,
      'yoy': 5.8,
      'tier': 'tier1',
      'trending': true,
      'localities': [
        {'n': 'Whitefield', 'p': 9200, 'c': '+7.2%'},
        {'n': 'Sarjapur Road', 'p': 8400, 'c': '+8.1%'},
        {'n': 'Electronic City', 'p': 6200, 'c': '+5.5%'},
        {'n': 'Koramangala', 'p': 14500, 'c': '+4.3%'}
      ]
    },
    {
      'icon': '🏗️',
      'name': 'Hyderabad',
      'state': 'Telangana',
      'price': 9100,
      'yoy': 6.2,
      'tier': 'tier1',
      'trending': true,
      'localities': [
        {'n': 'Gachibowli', 'p': 8500, 'c': '+7.8%'},
        {'n': 'Kondapur', 'p': 7900, 'c': '+6.9%'},
        {'n': 'Kukatpally', 'p': 6200, 'c': '+5.1%'},
        {'n': 'Jubilee Hills', 'p': 15000, 'c': '+4.2%'}
      ]
    },
    {
      'icon': '🌸',
      'name': 'Pune',
      'state': 'Maharashtra',
      'price': 8600,
      'yoy': 4.5,
      'tier': 'tier1',
      'trending': false,
      'localities': [
        {'n': 'Wakad', 'p': 8400, 'c': '+5.2%'},
        {'n': 'Hinjewadi', 'p': 7600, 'c': '+6.1%'},
        {'n': 'Kharadi', 'p': 9200, 'c': '+4.8%'},
        {'n': 'Koregaon Park', 'p': 14000, 'c': '+3.1%'}
      ]
    },
    {
      'icon': '🌊',
      'name': 'Chennai',
      'state': 'Tamil Nadu',
      'price': 8200,
      'yoy': 2.4,
      'tier': 'tier1',
      'trending': false,
      'localities': [
        {'n': 'OMR Perungudi', 'p': 7200, 'c': '+3.1%'},
        {'n': 'Velachery', 'p': 8800, 'c': '+2.8%'},
        {'n': 'Anna Nagar', 'p': 11500, 'c': '+2.1%'},
        {'n': 'Sholinganallur', 'p': 6800, 'c': '+4.2%'}
      ]
    },
    {
      'icon': '🎶',
      'name': 'Kolkata',
      'state': 'West Bengal',
      'price': 6400,
      'yoy': 1.9,
      'tier': 'tier1',
      'trending': false,
      'localities': [
        {'n': 'New Town', 'p': 5800, 'c': '+3.2%'},
        {'n': 'Salt Lake', 'p': 7500, 'c': '+2.1%'},
        {'n': 'Rajarhat', 'p': 4800, 'c': '+4.1%'},
        {'n': 'Alipore', 'p': 14000, 'c': '+1.2%'}
      ]
    },
    {
      'icon': '🌴',
      'name': 'Ahmedabad',
      'state': 'Gujarat',
      'price': 5800,
      'yoy': 3.6,
      'tier': 'tier2',
      'trending': true,
      'localities': [
        {'n': 'SG Road', 'p': 7200, 'c': '+4.5%'},
        {'n': 'Prahlad Nagar', 'p': 8500, 'c': '+3.8%'},
        {'n': 'Bopal', 'p': 5200, 'c': '+4.1%'},
        {'n': 'Satellite', 'p': 9200, 'c': '+3.1%'}
      ]
    },
    {
      'icon': '🏰',
      'name': 'Jaipur',
      'state': 'Rajasthan',
      'price': 4900,
      'yoy': 5.1,
      'tier': 'tier2',
      'trending': true,
      'localities': [
        {'n': 'Vaishali Nagar', 'p': 5500, 'c': '+5.8%'},
        {'n': 'Jagatpura', 'p': 4200, 'c': '+6.1%'},
        {'n': 'Mansarovar', 'p': 4800, 'c': '+4.9%'},
        {'n': 'C-Scheme', 'p': 8200, 'c': '+3.2%'}
      ]
    },
    {
      'icon': '🎓',
      'name': 'Lucknow',
      'state': 'Uttar Pradesh',
      'price': 4600,
      'yoy': 4.8,
      'tier': 'tier2',
      'trending': true,
      'localities': [
        {'n': 'Gomti Nagar', 'p': 5800, 'c': '+5.5%'},
        {'n': 'Aliganj', 'p': 4200, 'c': '+4.8%'},
        {'n': 'Hazratganj', 'p': 8500, 'c': '+2.1%'},
        {'n': 'Sushant Golf City', 'p': 4600, 'c': '+6.2%'}
      ]
    },
    {
      'icon': '⚡',
      'name': 'Surat',
      'state': 'Gujarat',
      'price': 4200,
      'yoy': 6.8,
      'tier': 'tier2',
      'trending': true,
      'localities': [
        {'n': 'Vesu', 'p': 5200, 'c': '+7.2%'},
        {'n': 'Pal', 'p': 4100, 'c': '+6.8%'},
        {'n': 'Adajan', 'p': 4800, 'c': '+6.1%'},
        {'n': 'City Light', 'p': 6200, 'c': '+5.1%'}
      ]
    },
    {
      'icon': '🌿',
      'name': 'Indore',
      'state': 'Madhya Pradesh',
      'price': 4100,
      'yoy': 7.2,
      'tier': 'tier2',
      'trending': true,
      'localities': [
        {'n': 'Vijay Nagar', 'p': 5100, 'c': '+7.8%'},
        {'n': 'Super Corridor', 'p': 3800, 'c': '+8.5%'},
        {'n': 'AB Road', 'p': 6500, 'c': '+4.2%'},
        {'n': 'Scheme 78', 'p': 4600, 'c': '+6.9%'}
      ]
    },
    {
      'icon': '🏖️',
      'name': 'Kochi',
      'state': 'Kerala',
      'price': 5200,
      'yoy': 3.1,
      'tier': 'tier2',
      'trending': false,
      'localities': [
        {'n': 'Marine Drive', 'p': 12000, 'c': '+2.8%'},
        {'n': 'Panampilly Nagar', 'p': 9500, 'c': '+3.1%'},
        {'n': 'Kakkanad', 'p': 5800, 'c': '+4.2%'},
        {'n': 'Thrikkakara', 'p': 4900, 'c': '+3.8%'}
      ]
    },
    {
      'icon': '🌾',
      'name': 'Nagpur',
      'state': 'Maharashtra',
      'price': 4000,
      'yoy': 3.9,
      'tier': 'tier2',
      'trending': false,
      'localities': [
        {'n': 'Wardha Road', 'p': 4800, 'c': '+4.5%'},
        {'n': 'Sitabuldi', 'p': 6200, 'c': '+2.8%'},
        {'n': 'Kalamna', 'p': 3500, 'c': '+4.1%'},
        {'n': 'Manish Nagar', 'p': 4200, 'c': '+3.9%'}
      ]
    },
    {
      'icon': '🎭',
      'name': 'Bhopal',
      'state': 'Madhya Pradesh',
      'price': 3800,
      'yoy': 4.2,
      'tier': 'tier3',
      'trending': false,
      'localities': []
    },
    {
      'icon': '🏛️',
      'name': 'Patna',
      'state': 'Bihar',
      'price': 3500,
      'yoy': 3.8,
      'tier': 'tier3',
      'trending': false,
      'localities': []
    },
    {
      'icon': '🌻',
      'name': 'Coimbatore',
      'state': 'Tamil Nadu',
      'price': 4400,
      'yoy': 5.4,
      'tier': 'tier3',
      'trending': true,
      'localities': []
    },
    {
      'icon': '🎪',
      'name': 'Chandigarh',
      'state': 'Punjab',
      'price': 5500,
      'yoy': 2.9,
      'tier': 'tier2',
      'trending': false,
      'localities': []
    },
    {
      'icon': '🌊',
      'name': 'Visakhapatnam',
      'state': 'Andhra Pradesh',
      'price': 4600,
      'yoy': 4.1,
      'tier': 'tier2',
      'trending': false,
      'localities': []
    },
    {
      'icon': '🎯',
      'name': 'Nashik',
      'state': 'Maharashtra',
      'price': 4200,
      'yoy': 5.6,
      'tier': 'tier3',
      'trending': true,
      'localities': []
    }
  ];

  static const List<LinearGradient> _barColors = [
    LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFE05A00)]),
    LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0D9488)]),
    LinearGradient(colors: [Color(0xFF046A38), Color(0xFF10B981)]),
    LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
    LinearGradient(colors: [Color(0xFFC2410C), Color(0xFF9A3412)]),
    LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0891B2)]),
    LinearGradient(colors: [Color(0xFFB45309), Color(0xFF92400E)]),
    LinearGradient(colors: [Color(0xFFBE185D), Color(0xFF9D174D)]),
  ];

  @override
  void initState() {
    super.initState();
    _carpetAreaCtrl = TextEditingController(text: _carpetArea.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _carpetAreaCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _savePriceEstimate() async {
    final cityData = _cities.firstWhere((element) => element['name'] == _selectedCity);
    final double baseRate = (cityData['price'] as int).toDouble();
    final double totalVal = _carpetArea * baseRate;

    final labelCtrl = TextEditingController(text: 'Valuation Snapshot - $_selectedCity');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Price Estimate', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving snapshot for $_selectedCity: ${_fmt(totalVal)} (${_carpetArea.toInt()} sqft)',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Dream 3BHK Budget)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Property Valuation';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'City Property Prices',
        inputs: {
          'carpetArea': _carpetArea,
          'cityIndex': _cities.indexWhere((element) => element['name'] == _selectedCity).toDouble(),
        },
        results: {
          'avgRate': baseRate,
          'estimatedCost': totalVal,
          'yoy': cityData['yoy'],
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Valuation estimate saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToLocalityPanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _localityPanelKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter cities dynamically
    final filteredCities = _cities.where((c) {
      final nameMatch = c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final stateMatch = c['state'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final queryMatch = nameMatch || stateMatch;

      bool tabMatch = true;
      if (_activeTab == 'tier1') tabMatch = c['tier'] == 'tier1';
      if (_activeTab == 'tier2') tabMatch = c['tier'] == 'tier2';
      if (_activeTab == 'tier3') tabMatch = c['tier'] == 'tier3';
      if (_activeTab == 'trending') tabMatch = c['trending'] == true;

      return queryMatch && tabMatch;
    }).toList();

    // Get top 8 sorted by price descending
    final top8Cities = [..._cities];
    top8Cities.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
    final chartCities = top8Cities.take(8).toList();
    final double maxChartPrice = chartCities.isNotEmpty ? (chartCities.first['price'] as int).toDouble() : 1.0;

    // Select the currently highlighted city details
    final selectedCityData = _cities.firstWhere((c) => c['name'] == _selectedCity);
    final double selectedCityPrice = (selectedCityData['price'] as int).toDouble();
    final double estimateVal = _carpetArea * selectedCityPrice;
    final List localities = selectedCityData['localities'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('Mumbai', '₹22.4K', '/sqft', isSaffron: true),
              _infoCell('Bengaluru', '₹11.5K', '/sqft', isGreen: true),
              _infoCell('Hyderabad', '₹9.1K', '/sqft'),
              _infoCell('Avg YoY', '+4.2%', 'India', isGreen: true),
            ],
          ),
        ),

        // Search and Filters Section
        Text('Search & Filter Cities', style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        // Search Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 10,
              )
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context)),
            decoration: InputDecoration(
              icon: Text('🔍', style: TextStyle(fontSize: 16, color: theme.getMutedColor(context))),
              hintText: 'Search city, state…',
              hintStyle: AppTextStyles.dmSans(size: 13, color: theme.getMutedColor(context)),
              border: InputBorder.none,
            ),
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // Filter Tabs list scrollable
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterTabChip('All Cities', 'all'),
              _buildFilterTabChip('Tier 1', 'tier1'),
              _buildFilterTabChip('Tier 2', 'tier2'),
              _buildFilterTabChip('Tier 3', 'tier3'),
              _buildFilterTabChip('🔥 Trending', 'trending'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top 8 chart visualization
        Text('Price Comparison — Top 8 Cities', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹/sqft Residential (Q1 2025)', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                  Text('NHB Residex', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: chartCities.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;
                  final double priceVal = (c['price'] as int).toDouble();
                  final pct = maxChartPrice > 0 ? priceVal / maxChartPrice : 0.0;
                  final gradient = _barColors[idx % _barColors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(c['name'], style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        ),
                        Expanded(
                          child: Container(
                            height: 11,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EDE0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: LayoutBuilder(builder: (ctx, constraints) {
                              return Container(
                                width: constraints.maxWidth * pct,
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '₹${(c['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/sqft',
                            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '+${c['yoy']}%',
                            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: const Color(0xFF046A38)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Locality Detail Panel (shown when a city is selected/clicked)
        Container(
          key: _localityPanelKey,
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${selectedCityData['icon']} $_selectedCity',
                          style: AppTextStyles.dmSans(size: 18, color: Colors.white, weight: FontWeight.w800)),
                      Text('${selectedCityData['state']} · ${selectedCityData['tier'].toString().toUpperCase()}',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Selected', style: AppTextStyles.dmSans(size: 8, color: Colors.white, weight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Detail stat boxes
              Row(
                children: [
                  _detailStatBox('Avg Price', '₹${(selectedCityData['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/sqft', isSaffron: true),
                  const SizedBox(width: 8),
                  _detailStatBox('YoY Growth', '+${selectedCityData['yoy']}%', isGreen: true),
                  const SizedBox(width: 8),
                  _detailStatBox('Tier', selectedCityData['tier'] == 'tier1' ? 'Tier 1' : (selectedCityData['tier'] == 'tier2' ? 'Tier 2' : 'Tier 3')),
                ],
              ),
              const SizedBox(height: 14),

              // Localities scrollable horizontal list
              Text('Popular Localities', style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (localities.isNotEmpty)
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: localities.length,
                    itemBuilder: (ctx, lIdx) {
                      final loc = localities[lIdx];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(loc['n'], style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('₹${(loc['p'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/sqft',
                                style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFFDEA0), weight: FontWeight.w800)),
                            Text('↑ ${loc['c']}', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF86EFAC))),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Locality data coming soon', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white38)),
                ),
            ],
          ),
        ),

        // Estimator Slider Calculator Section
        Text('Property Price Estimator', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimate purchase value of homes based on carpet area and city averages',
                  style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 14),

              // Synced input-slider: Carpet Area
              _buildSyncedInputRow(
                label: 'CARPET AREA',
                controller: _carpetAreaCtrl,
                value: _carpetArea,
                min: 300,
                max: 4000,
                suffix: ' sqft',
                onChangedText: (val) => setState(() => _carpetArea = val),
                onChangedSlider: (val) => setState(() {
                  _carpetArea = val;
                  _carpetAreaCtrl.text = val.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 14),

              // Estimated Output Bracket
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESTIMATED PROPERTY VALUATION RANGE',
                        style: AppTextStyles.dmSans(size: 8.5, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A), weight: FontWeight.w800, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(_fmt(estimateVal),
                        style: AppTextStyles.playfair(size: 28, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A), weight: FontWeight.w800)),
                    Text('Approximate valuation at ₹${selectedCityData['price']}/sqft (${selectedCityData['tier'].toString().toUpperCase()})',
                        style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _resBox('Lower Bracket (-5%)', _fmt(estimateVal * 0.95), context),
                        const SizedBox(width: 8),
                        _resBox('Upper Bracket (+5%)', _fmt(estimateVal * 1.05), context),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _savePriceEstimate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.bookmark, size: 14),
                  label: Text('Save Estimate Snapshot', style: AppTextStyles.dmSans(size: 11.5, color: Colors.white, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grid of all cities
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('All Cities', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
            Text('${filteredCities.length} cities', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredCities.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (ctx, idx) {
            final c = filteredCities[idx];
            final priceFormatted = '₹${(c['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
            final isCurrent = c['name'] == _selectedCity;
            Color borderCol = isCurrent ? const Color(0xFFFF6B00) : theme.getBorderColor(context);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCity = c['name'];
                });
                _scrollToLocalityPanel();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  border: Border.all(color: borderCol, width: isCurrent ? 1.5 : 1.0),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c['icon'], style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(c['name'], style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        Text(c['state'].toString().split(' · ').first, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        Text(priceFormatted, style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: const Color(0xFFFF6B00))),
                        Row(
                          children: [
                            Text('per sqft · ', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                            Text(
                              '↑ ${c['yoy']}% YoY',
                              style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF046A38), weight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c['tier'] == 'tier1'
                              ? const Color(0xFFFFF3E0)
                              : (c['tier'] == 'tier2' ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c['tier'] == 'tier1' ? 'Tier 1' : (c['tier'] == 'tier2' ? 'Tier 2' : 'Tier 3'),
                          style: AppTextStyles.dmSans(
                            size: 7.5,
                            weight: FontWeight.w700,
                            color: c['tier'] == 'tier1'
                                ? const Color(0xFFE05A00)
                                : (c['tier'] == 'tier2' ? const Color(0xFF1D4ED8) : const Color(0xFF046A38)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // India Property Price Trend (2020-2025)
        Text('India Property Price Trend (2020–2025)', style: AppTextStyles.playfair(size: 14, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📈 All-India Avg Residential Price Index', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text('₹/sqft · Source: NHB Residex', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 12),

              // Sparkline line chart
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklineChartPainter(
                    years: const ['2020', '2021', '2022', '2023', '2024', '2025'],
                    values: const [4200.0, 4500.0, 4900.0, 5500.0, 6200.0, 7200.0],
                    lineColor: const Color(0xFFFF6B00),
                    pointColor: const Color(0xFF046A38),
                    gridColor: const Color(0xFFF5EDE0),
                    textColor: theme.getTextColor(context),
                    mutedColor: theme.getMutedColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _legendIndicator(const Color(0xFFFF6B00), 'Avg Price Index'),
                  const SizedBox(width: 14),
                  _legendIndicator(const Color(0xFF046A38), '2025 (Latest)'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note, {bool isGreen = false, bool isSaffron = false}) {
    Color valColor = Colors.white;
    if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    } else if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    }
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildFilterTabChip(String label, String tab) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : widget.theme.getCardColor(context),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: isSelected ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _detailStatBox(String label, String value, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: valColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncedInputRow({
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
    String prefix = '',
    String suffix = '',
    required ValueChanged<double> onChangedText,
    required ValueChanged<double> onChangedSlider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w800)),
            Text('$prefix${value.toInt()}$suffix',
                style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
            border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context), weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed >= min && parsed <= max) {
                onChangedText(parsed);
              }
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF6B00),
            inactiveTrackColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.24),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChangedSlider,
          ),
        ),
      ],
    );
  }

  Widget _resBox(String label, String value, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF046A38).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF046A38))),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF07543A))),
          ],
        ),
      ),
    );
  }

  Widget _legendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
      ],
    );
  }
}

class _SparklineChartPainter extends CustomPainter {
  final List<String> years;
  final List<double> values;
  final Color lineColor;
  final Color pointColor;
  final Color gridColor;
  final Color textColor;
  final Color mutedColor;

  _SparklineChartPainter({
    required this.years,
    required this.values,
    required this.lineColor,
    required this.pointColor,
    required this.gridColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final double width = size.width;
    final double height = size.height - 20; // reserve space for X labels
    final double maxVal = values.reduce(max);
    final double minVal = values.reduce(min);
    final double valRange = maxVal - minVal;

    // Draw Y grid lines and labels
    const int gridCount = 3;
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (int i = 0; i < gridCount; i++) {
      final double y = (height / (gridCount - 1)) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      // Y-axis label text
      final double gridVal = maxVal - (valRange / (gridCount - 1)) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(gridVal / 1000).toStringAsFixed(1)}K',
          style: TextStyle(fontFamily: 'Trebuchet MS', fontSize: 8, color: mutedColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(2, y - textPainter.height - 1));
    }

    // Coordinates points list
    final List<Offset> points = [];
    final double stepX = width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final double x = stepX * i;
      final double yRatio = valRange > 0 ? (values[i] - minVal) / valRange : 0.5;
      final double y = height - (yRatio * height);
      points.add(Offset(x, y));
    }

    // Path area fill gradient underneath the line
    final Path areaPath = Path()..moveTo(points.first.dx, height);
    for (var pt in points) {
      areaPath.lineTo(pt.dx, pt.dy);
    }
    areaPath.lineTo(points.last.dx, height);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withValues(alpha: 0.25), lineColor.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, width, height));
    canvas.drawPath(areaPath, areaPaint);

    // Line Path
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Node circular point markers
    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      final color = isLast ? pointColor : lineColor;
      final radius = isLast ? 5.0 : 4.0;
      final double strokeW = isLast ? 2.0 : 1.5;

      canvas.drawCircle(points[i], radius, Paint()..color = color);
      canvas.drawCircle(
        points[i],
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );

      // X-axis label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: years[i],
          style: TextStyle(fontFamily: 'Trebuchet MS', fontSize: 8, color: mutedColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(points[i].dx - labelPainter.width / 2, height + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.textColor != textColor;
  }
}
