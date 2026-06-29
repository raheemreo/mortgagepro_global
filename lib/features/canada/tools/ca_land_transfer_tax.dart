// lib/features/canada/tools/ca_land_transfer_tax.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as dm;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CALandTransferTax extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CALandTransferTax({super.key, required this.theme});

  @override
  ConsumerState<CALandTransferTax> createState() => _CALandTransferTaxState();
}

class _CALandTransferTaxState extends ConsumerState<CALandTransferTax> {
  final _priceController = TextEditingController(text: '750000');
  String _selectedProvince = 'ON';
  bool _isToronto = false;
  bool _isFirstTimeBuyer = false;
  bool _isForeignBuyer = false;

  final List<String> _provinces = ['ON', 'BC', 'AB', 'QC', 'MB', 'NS', 'NB', 'SK'];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  // --- Calculate math functions ---

  double _calcON(double price) {
    double tax = 0;
    final brackets = [
      {'upper': 55000.0, 'rate': 0.005},
      {'upper': 250000.0, 'rate': 0.01},
      {'upper': 400000.0, 'rate': 0.015},
      {'upper': 2000000.0, 'rate': 0.02},
      {'upper': double.infinity, 'rate': 0.025},
    ];
    double prev = 0;
    for (var bracket in brackets) {
      final double upper = bracket['upper']!;
      final double rate = bracket['rate']!;
      if (price <= prev) break;
      tax += (dm.min(price, upper) - prev) * rate;
      prev = upper;
    }
    return tax;
  }

  double _calcBC(double price) {
    if (price <= 200000) {
      return price * 0.01;
    } else if (price <= 2000000) {
      return 200000 * 0.01 + (price - 200000) * 0.02;
    } else {
      return 200000 * 0.01 + 1800000 * 0.02 + (price - 2000000) * 0.03;
    }
  }

  double _calcQC(double price) {
    double tax = 0;
    final brackets = [
      {'upper': 55200.0, 'rate': 0.005},
      {'upper': 276200.0, 'rate': 0.01},
      {'upper': 552300.0, 'rate': 0.015},
      {'upper': 1104400.0, 'rate': 0.02},
      {'upper': double.infinity, 'rate': 0.025},
    ];
    double prev = 0;
    for (var bracket in brackets) {
      final double upper = bracket['upper']!;
      final double rate = bracket['rate']!;
      if (price <= prev) break;
      tax += (dm.min(price, upper) - prev) * rate;
      prev = upper;
    }
    return tax;
  }

  double _calcMB(double price) {
    if (price <= 30000) return 0;
    double tax = 0;
    final brackets = [
      {'upper': 90000.0, 'rate': 0.005},
      {'upper': 150000.0, 'rate': 0.01},
      {'upper': 200000.0, 'rate': 0.015},
      {'upper': double.infinity, 'rate': 0.02},
    ];
    double prev = 0;
    for (var bracket in brackets) {
      final double upper = bracket['upper']!;
      final double rate = bracket['rate']!;
      if (price <= prev) break;
      tax += (dm.min(price, upper) - prev) * rate;
      prev = upper;
    }
    return tax;
  }

  Map<String, double> _calculateTax(double price) {
    double provTax = 0;
    double muniTax = 0;
    double rebate = 0;
    double foreignTax = 0;

    switch (_selectedProvince) {
      case 'ON':
        provTax = _calcON(price);
        if (_isToronto) {
          muniTax = _calcON(price);
        }
        if (_isFirstTimeBuyer) {
          double provRebate = dm.min(4000.0, provTax);
          double muniRebate = _isToronto ? dm.min(4475.0, muniTax) : 0.0;
          rebate = provRebate + muniRebate;
        }
        if (_isForeignBuyer) {
          foreignTax = price * 0.25;
        }
        break;

      case 'BC':
        provTax = _calcBC(price);
        if (_isFirstTimeBuyer) {
          if (price <= 500000) {
            rebate = provTax;
          } else if (price < 525000) {
            rebate = provTax * (525000 - price) / 25000;
          }
        }
        if (_isForeignBuyer) {
          foreignTax = price * 0.20;
        }
        break;

      case 'AB':
        // Title Registration Fee
        provTax = 50 + (price / 5000).ceil() * 5.0;
        break;

      case 'QC':
        provTax = _calcQC(price);
        break;

      case 'MB':
        provTax = _calcMB(price);
        break;

      case 'NS':
        // Flat 1.5% deed transfer tax (Halifax baseline)
        provTax = price * 0.015;
        break;

      case 'NB':
        // Flat 1.0% Real Property Transfer Tax
        provTax = price * 0.01;
        break;

      case 'SK':
        // Flat 0.3% title transfer fee
        provTax = price * 0.003;
        break;
    }

    final total = provTax + muniTax - rebate + foreignTax;
    return {
      'provLtt': provTax,
      'muniLtt': muniTax,
      'rebate': rebate,
      'foreignTax': foreignTax,
      'total': dm.max(0.0, total),
    };
  }

  void _saveCalculation(double price, Map<String, double> res) async {
    final labelCtrl = TextEditingController(text: 'Land Transfer Tax');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_land_transfer_tax'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save LTT Estimate',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Total Tax ${CurrencyFormatter.compact(res['total']!, symbol: 'CA\$')} · Price: ${CurrencyFormatter.compact(price, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. My LTT Ontario)',
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
          : 'Land Transfer Tax';
      
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Land Transfer Tax',
        inputs: {
          'Price': price,
          'IsToronto': _isToronto ? 1.0 : 0.0,
          'IsFirstTime': _isFirstTimeBuyer ? 1.0 : 0.0,
          'IsForeign': _isForeignBuyer ? 1.0 : 0.0,
        },
        results: {
          'Total Tax': res['total']!,
          'Provincial LTT': res['provLtt']!,
          'Municipal LTT': res['muniLtt']!,
          'Rebate': res['rebate']!,
          'Foreign Tax': res['foreignTax']!,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ LTT Estimate saved successfully!',
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
    final double price = double.tryParse(_priceController.text) ?? 750000;
    final res = _calculateTax(price);

    // Live USD/CAD from BoC for foreign buyer cost context
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final usdCad = ratesAsync.valueOrNull?.usdCad.value ?? 1.3977;
    final isLive = ratesAsync.valueOrNull?.isLive == true;
    final lottUsd = res['total']! / usdCad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Province Selection Grid
        Text(
          'SELECT PROVINCE',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.0,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: _provinces.length,
          itemBuilder: (context, index) {
            final prov = _provinces[index];
            final isSelected = prov == _selectedProvince;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProvince = prov;
                  if (prov != 'ON') {
                    _isToronto = false;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? theme.primaryColor : theme.getBorderColor(context),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  prov,
                  style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.bold,
                    color: isSelected ? Colors.white : theme.getTextColor(context),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Inputs Card
        Text(
          'CALCULATION DETAILS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
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
              // Home price input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Price',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Home value',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'CA\$',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.bold,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 110,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.getBorderColor(context)),
                        ),
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.bold,
                            color: theme.getTextColor(context),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: price.clamp(100000, 3000000),
                min: 100000,
                max: 3000000,
                divisions: 290,
                activeColor: theme.primaryColor,
                inactiveColor: theme.getBorderColor(context),
                onChanged: (val) {
                  setState(() {
                    _priceController.text = val.round().toString();
                  });
                },
              ),
              const Divider(height: 20, thickness: 0.5),

              // City of Toronto Toggle (ON only)
              if (_selectedProvince == 'ON') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: theme.primaryColor,
                  title: Text(
                    'City of Toronto',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.bold,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    '+Municipal LTT applies',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                  value: _isToronto,
                  onChanged: (val) {
                    setState(() {
                      _isToronto = val;
                    });
                  },
                ),
                const Divider(height: 20, thickness: 0.5),
              ],

              // First-time Home Buyer
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: theme.primaryColor,
                title: Text(
                  'First-Time Home Buyer',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                ),
                subtitle: Text(
                  'Eligible for rebates in ON, Toronto & BC',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: theme.getMutedColor(context),
                  ),
                ),
                value: _isFirstTimeBuyer,
                onChanged: (val) {
                  setState(() {
                    _isFirstTimeBuyer = val;
                  });
                },
              ),
              const Divider(height: 20, thickness: 0.5),

              // Foreign Buyer Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: theme.primaryColor,
                title: Text(
                  'Foreign / Non-Resident Buyer',
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                ),
                subtitle: Text(
                  'Adds NRST (25% in ON, 20% in BC)',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: theme.getMutedColor(context),
                  ),
                ),
                value: _isForeignBuyer,
                onChanged: (val) {
                  setState(() {
                    _isForeignBuyer = val;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculated results hero card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TAX OWING',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context),
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              onTap: () => _saveCalculation(price, res),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('💾', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      'Save',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL LAND TRANSFER TAX',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: Colors.white60,
                  weight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'CA\$',
                    style: AppTextStyles.dmSans(
                      size: 18,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.compact(res['total']!, symbol: ''),
                    style: AppTextStyles.playfair(
                      size: 36,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFF8A9A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _selectedProvince == 'ON' && _isToronto
                    ? 'Ontario Provincial + Toronto Municipal LTT'
                    : '$_selectedProvince Land Transfer Tax',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                children: [
                  _resultMiniBox('Provincial LTT', res['provLtt']!),
                  const SizedBox(width: 8),
                  _resultMiniBox(
                      'Municipal LTT', _selectedProvince == 'ON' && _isToronto ? res['muniLtt']! : null),
                  const SizedBox(width: 8),
                  _resultMiniBox('Rebate Saved', res['rebate']!, isRebate: true),
                ],
              ),
              const SizedBox(height: 12),
              // USD/CAD live conversion row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('💱', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'USD Equivalent ${isLive ? '🟢' : ''}',
                            style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            'Rate: 1 USD = CA\$${usdCad.toStringAsFixed(4)}',
                            style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'US\$${(lottUsd / 1000).toStringAsFixed(1)}K',
                    style: AppTextStyles.playfair(
                      size: 16,
                      weight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Breakdown Section
        Text(
          'BREAKDOWN',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: _buildBreakdownList(res),
          ),
        ),
        const SizedBox(height: 20),

        // Province Comparison Grid
        Text(
          'PROVINCE COMPARISON — CA\$750K',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _cmpCard('🏙️ Toronto, ON', '\$21,475', 'Prov + Muni LTT', isHigh: true),
            _cmpCard('🌊 Vancouver, BC', '\$13,000', 'Property Transfer Tax', isHigh: true),
            _cmpCard('🍁 Ontario (ex-TO)', '\$10,475', 'Provincial only'),
            _cmpCard('❄️ Alberta', '~\$380', 'Reg. fee only', isLow: true),
            _cmpCard('🌾 Quebec (MTL)', '\$9,975', 'Welcome Tax'),
            _cmpCard('🌻 Manitoba', '\$8,870', 'Provincial LTT'),
          ],
        ),
        const SizedBox(height: 20),

        // Rate Table
        Text(
          '$_selectedProvince RATE BRACKETS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF0A2E1A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Property Value Bracket',
                        style: AppTextStyles.dmSans(
                            size: 10, weight: FontWeight.bold, color: Colors.white60)),
                    Text('Rate',
                        style: AppTextStyles.dmSans(
                            size: 10, weight: FontWeight.bold, color: Colors.white60)),
                  ],
                ),
              ),
              ..._buildRateRows(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultMiniBox(String label, double? val, {bool isRebate = false}) {
    final displayVal = val == null
        ? 'N/A'
        : (isRebate && val > 0 ? '-' : '') + CurrencyFormatter.format(val, symbol: 'CA\$');
    final valCol = isRebate
        ? (val != null && val > 0 ? const Color(0xFF6EDFA0) : Colors.white60)
        : Colors.white;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white60),
            ),
            const SizedBox(height: 2),
            Text(
              displayVal,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: valCol,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBreakdownList(Map<String, double> res) {
    List<Widget> list = [];
    final textStyle = AppTextStyles.dmSans(
      size: 12,
      weight: FontWeight.bold,
      color: widget.theme.getTextColor(context),
    );
    final valueStyle = AppTextStyles.dmSans(
      size: 12,
      weight: FontWeight.w800,
      color: widget.theme.primaryColor,
    );

    switch (_selectedProvince) {
      case 'ON':
        list.add(_breakdownRow('Ontario LTT (marginal)', res['provLtt']!, valueStyle, textStyle));
        if (_isToronto) {
          list.add(_breakdownRow('Toronto Municipal LTT', res['muniLtt']!, valueStyle, textStyle));
        }
        if (_isFirstTimeBuyer) {
          list.add(_breakdownRow(
            'First-Time Buyer Rebate',
            -res['rebate']!,
            AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF1A5C35)),
            textStyle,
          ));
        }
        if (_isForeignBuyer) {
          list.add(_breakdownRow(
            'NRST Speculation Tax (25%)',
            res['foreignTax']!,
            AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFFC8102E)),
            textStyle,
          ));
        }
        break;

      case 'BC':
        list.add(_breakdownRow('BC Property Transfer Tax', res['provLtt']!, valueStyle, textStyle));
        if (_isFirstTimeBuyer && res['rebate']! > 0) {
          list.add(_breakdownRow(
            'First-Time Buyer Rebate',
            -res['rebate']!,
            AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF1A5C35)),
            textStyle,
          ));
        }
        if (_isForeignBuyer) {
          list.add(_breakdownRow(
            'Foreign Buyer Tax (20%)',
            res['foreignTax']!,
            AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFFC8102E)),
            textStyle,
          ));
        }
        break;

      case 'AB':
        list.add(_breakdownRow('Title Registration Fee', res['provLtt']!, valueStyle, textStyle));
        list.add(Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No LTT in Alberta',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)),
              ),
              const Text('✓ Significant savings vs ON/BC',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1A5C35), fontWeight: FontWeight.bold)),
            ],
          ),
        ));
        break;

      case 'QC':
        list.add(_breakdownRow('Bienvenue / Welcome Tax', res['provLtt']!, valueStyle, textStyle));
        list.add(Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Note: No FTHB rebate in QC',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)),
              ),
              Text('Check municipal rules',
                  style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ));
        break;

      case 'MB':
        list.add(_breakdownRow('MB LTT (marginal)', res['provLtt']!, valueStyle, textStyle));
        list.add(Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No FTHB rebate in MB',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)),
              ),
              Text('Check Winnipeg rules',
                  style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ));
        break;

      case 'NS':
        list.add(_breakdownRow('Deed Transfer Tax (1.5%)', res['provLtt']!, valueStyle, textStyle));
        list.add(Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rate varies by municipality',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)),
              ),
              Text('1.5% is Halifax baseline',
                  style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ));
        break;

      case 'NB':
        list.add(_breakdownRow('Real Property Transfer Tax (1%)', res['provLtt']!, valueStyle, textStyle));
        break;

      case 'SK':
        list.add(_breakdownRow('Title Transfer Fee (0.3%)', res['provLtt']!, valueStyle, textStyle));
        list.add(Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No full LTT in Saskatchewan',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)),
              ),
              Text('Much lower than ON/BC',
                  style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ));
        break;
    }

    return list;
  }

  Widget _breakdownRow(String label, double val, TextStyle valStyle, TextStyle labelStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(CurrencyFormatter.format(val, symbol: 'CA\$'), style: valStyle),
        ],
      ),
    );
  }

  Widget _cmpCard(String label, String value, String note, {bool isHigh = false, bool isLow = false}) {
    final valueColor = isHigh
        ? const Color(0xFFC8102E)
        : (isLow ? const Color(0xFF1A5C35) : widget.theme.getTextColor(context));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.bold,
              color: widget.theme.getMutedColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 16,
              weight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: AppTextStyles.dmSans(
              size: 9,
              color: widget.theme.getMutedColor(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRateRows() {
    final rowBorder = BorderSide(color: widget.theme.getBorderColor(context));
    final labelStyle = AppTextStyles.dmSans(
      size: 12,
      color: widget.theme.getTextColor(context),
    );
    final valueStyle = AppTextStyles.dmSans(
      size: 12,
      weight: FontWeight.bold,
      color: widget.theme.getTextColor(context),
    );

    List<Map<String, String>> rows = [];
    switch (_selectedProvince) {
      case 'ON':
        rows = [
          {'bracket': 'First \$55,000', 'rate': '0.50%'},
          {'bracket': '\$55,000 – \$250,000', 'rate': '1.00%'},
          {'bracket': '\$250,000 – \$400,000', 'rate': '1.50%'},
          {'bracket': '\$400,000 – \$2,000,000', 'rate': '2.00%'},
          {'bracket': 'Over \$2,000,000', 'rate': '2.50%'},
        ];
        break;
      case 'BC':
        rows = [
          {'bracket': 'First \$200,000', 'rate': '1.00%'},
          {'bracket': '\$200,000 – \$2,000,000', 'rate': '2.00%'},
          {'bracket': 'Over \$2,000,000', 'rate': '3.00%'},
        ];
        break;
      case 'AB':
        rows = [
          {'bracket': 'Base registration fee', 'rate': '\$50.00'},
          {'bracket': 'Per \$5,000 of value', 'rate': '+\$5.00'},
        ];
        break;
      case 'QC':
        rows = [
          {'bracket': 'First \$55,200', 'rate': '0.50%'},
          {'bracket': '\$55,200 – \$276,200', 'rate': '1.00%'},
          {'bracket': '\$276,200 – \$552,300', 'rate': '1.50%'},
          {'bracket': '\$552,300 – \$1,104,400', 'rate': '2.00%'},
          {'bracket': 'Over \$1,104,400', 'rate': '2.50%'},
        ];
        break;
      case 'MB':
        rows = [
          {'bracket': 'First \$30,000', 'rate': '0.00%'},
          {'bracket': '\$30,000 – \$90,000', 'rate': '0.50%'},
          {'bracket': '\$90,000 – \$150,000', 'rate': '1.00%'},
          {'bracket': '\$150,000 – \$200,000', 'rate': '1.50%'},
          {'bracket': 'Over \$200,000', 'rate': '2.00%'},
        ];
        break;
      case 'NS':
        rows = [
          {'bracket': 'Deed Transfer baseline (Halifax)', 'rate': '1.50%'},
        ];
        break;
      case 'NB':
        rows = [
          {'bracket': 'Real Property Transfer Tax', 'rate': '1.00%'},
        ];
        break;
      case 'SK':
        rows = [
          {'bracket': 'Title Transfer baseline', 'rate': '0.30%'},
        ];
        break;
    }

    return rows.map((r) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: rowBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(r['bracket']!, style: labelStyle),
            Text(r['rate']!, style: valueStyle),
          ],
        ),
      );
    }).toList();
  }
}
