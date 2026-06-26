// lib/features/australia/tools/au_first_home_grant.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUFirstHomeGrant extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUFirstHomeGrant({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUFirstHomeGrant> createState() => _AUFirstHomeGrantState();
}

class _AUFirstHomeGrantState extends ConsumerState<AUFirstHomeGrant> {
  int _activeTab =
      0; // 0 = Eligibility, 1 = All States, 2 = Schemes, 3 = Checklist

  // Eligibility Inputs
  String _selectedState = 'NSW';
  double _propVal = 650000;
  double _depositVal = 65000;
  String _propType = 'new'; // 'new', 'established', 'vacant'
  bool _ownedBefore = false; // false = Never, true = Yes
  bool _showEligibilityResult = true;

  // Checklist state (tracks selected index checkboxes)
  final Set<String> _checkedItems = {};

  static const Map<String, dynamic> _grantsData = {
    'NSW': {
      'name': 'New South Wales',
      'amount': 10000.0,
      'cap': 600000.0,
      'propType': 'new',
      'note':
          'New homes only. Cap \$600K for new builds, \$750K for off-the-plan.',
      'extra': 'Stamp duty exemption <\$800K for FHB.'
    },
    'VIC': {
      'name': 'Victoria',
      'amount': 10000.0,
      'cap': 750000.0,
      'propType': 'new',
      'note': 'New homes only. Increased to \$20K in regional VIC.',
      'extra': 'First Home Buyer Duty Reduction.'
    },
    'QLD': {
      'name': 'Queensland',
      'amount': 30000.0,
      'cap': 750000.0,
      'propType': 'new',
      'note': 'Boosted to \$30K until 30 Jun 2025. New builds only.',
      'extra': 'Transfer duty concession for owner-occupiers.'
    },
    'WA': {
      'name': 'Western Australia',
      'amount': 10000.0,
      'cap': 750000.0,
      'propType': 'new',
      'note': 'New homes only for FHOG. Established homes no FHOG.',
      'extra': 'First Home Owner Rate of Duty reduction.'
    },
    'SA': {
      'name': 'South Australia',
      'amount': 15000.0,
      'cap': 650000.0,
      'propType': 'new',
      'note': 'New homes only, value up to \$650K.',
      'extra': 'Off-the-plan stamp duty concession.'
    },
    'TAS': {
      'name': 'Tasmania',
      'amount': 30000.0,
      'cap': 750000.0,
      'propType': 'new',
      'note': '\$30K grant until 30 Jun 2025 for new/substantially renovated.',
      'extra': '50% stamp duty discount for FHB.'
    },
    'ACT': {
      'name': 'Australian Capital Territory',
      'amount': 0.0,
      'cap': 0.0,
      'propType': 'any',
      'note':
          'ACT has abolished FHOG but offers generous stamp duty concessions.',
      'extra': 'Home Buyer Concession Scheme — no duty <\$1M.'
    },
    'NT': {
      'name': 'Northern Territory',
      'amount': 10000.0,
      'cap': 700000.0,
      'propType': 'any',
      'note': 'Applies to new and established properties. Up to \$10K FHOG.',
      'extra': 'First Home Owner Discount of up to \$26,730.'
    }
  };

  void _saveResult() async {
    final g = _grantsData[_selectedState];
    bool isEligible = false;
    double grantAmt = 0;

    if (!_ownedBefore) {
      if (_propType == 'new' && _propVal <= g['cap'] && g['amount'] > 0) {
        isEligible = true;
        grantAmt = g['amount'];
      } else if (_propType == 'established' &&
          g['amount'] > 0 &&
          g['propType'] == 'any') {
        isEligible = true;
        grantAmt = g['amount'];
      }
    }

    final labelCtrl =
        TextEditingController(text: 'FHB Grant - $_selectedState');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save FHB Grant Result',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: FHOG eligibility in $_selectedState. Est Grant: \$${CurrencyFormatter.compact(grantAmt, symbol: 'AU\$')}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My NSW Grant)',
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
              backgroundColor: const Color(0xFF002868),
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
          : 'FHB Grant';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'First Home Owner Grant',
        inputs: {
          'propertyValue': _propVal,
          'deposit': _depositVal,
          'stateIndex': _selectedState == 'NSW'
              ? 0.0
              : _selectedState == 'VIC'
                  ? 1.0
                  : _selectedState == 'QLD'
                      ? 2.0
                      : _selectedState == 'WA'
                          ? 3.0
                          : _selectedState == 'SA'
                              ? 4.0
                              : _selectedState == 'TAS'
                                  ? 5.0
                                  : _selectedState == 'ACT'
                                      ? 6.0
                                      : 7.0,
          'propertyTypeIndex': _propType == 'new'
              ? 0.0
              : _propType == 'established'
                  ? 1.0
                  : 2.0,
          'ownedBefore': _ownedBefore ? 1.0 : 0.0,
        },
        results: {
          'eligible': isEligible ? 1.0 : 0.0,
          'grantAmt': grantAmt,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF002868),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTabBtn('Eligibility', 0)),
              Expanded(child: _buildTabBtn('All States', 1)),
              Expanded(child: _buildTabBtn('Schemes', 2)),
              Expanded(child: _buildTabBtn('Checklist', 3)),
            ],
          ),
        ),

        // Active Tab Screen
        if (_activeTab == 0) _buildEligibilityTab(theme),
        if (_activeTab == 1) _buildAllStatesTab(theme),
        if (_activeTab == 2) _buildSchemesTab(theme),
        if (_activeTab == 3) _buildChecklistTab(theme),
      ],
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w800,
            color: active
                ? Colors.white
                : widget.theme.getTextColor(context).withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: ELIGIBILITY CHECKER ────────────────────────────────────
  Widget _buildEligibilityTab(CountryTheme theme) {
    final g = _grantsData[_selectedState];
    bool isEligible = false;
    String reason = '';
    double grantAmt = 0;

    if (_ownedBefore) {
      reason =
          'You have previously owned property in Australia. FHOG requires all buyers to be purchasing their first home.';
    } else {
      if (_propType == 'new' && _propVal <= g['cap'] && g['amount'] > 0) {
        isEligible = true;
        grantAmt = g['amount'];
      } else if (_propType == 'new' && g['amount'] > 0) {
        reason =
            'Property value exceeds the cap of ${CurrencyFormatter.format(g['cap'], currencyCode: 'AUD')} for this state.';
      } else if (_propType == 'established' &&
          g['amount'] > 0 &&
          g['propType'] == 'any') {
        isEligible = true;
        grantAmt = g['amount'];
      } else if (_propType == 'established' && g['amount'] > 0) {
        reason =
            '$_selectedState FHOG applies to new homes only. No FHOG for established properties.';
      } else if (_selectedState == 'ACT') {
        reason =
            'ACT has abolished FHOG but you may qualify for stamp duty concessions.';
      }
    }

    // Determine LMI risk
    final lvr =
        _propVal > 0 ? ((_propVal - _depositVal) / _propVal * 100) : 0.0;
    final fhbgEligible = _propVal <= 900000 && lvr >= 80;

    // Package benefits
    double stampDutyConcession = 0;
    if (!_ownedBefore) {
      if (_selectedState == 'NSW' && _propVal < 800000) {
        stampDutyConcession = 28000;
      } else if (_selectedState == 'ACT' && _propVal < 1000000) {
        stampDutyConcession = 40000;
      } else if (_selectedState == 'VIC' && _propVal < 750000) {
        stampDutyConcession = 15000;
      } else {
        stampDutyConcession = 5000;
      }
    }

    final lmiSavings = fhbgEligible ? 18000.0 : 0.0;
    const superSavings = 50000.0; // Max FHSS release
    final totalPotentialSavings = (isEligible ? grantAmt : 0) +
        stampDutyConcession +
        lmiSavings +
        superSavings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Text('SELECT STATE / TERRITORY',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),

              // States buttons grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                childAspectRatio: 1.8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: ['NSW', 'VIC', 'QLD', 'WA', 'SA', 'TAS', 'ACT', 'NT']
                    .map((st) {
                  final active = st == _selectedState;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedState = st),
                    child: Container(
                      decoration: BoxDecoration(
                        color: active
                            ? theme.primaryColor
                            : theme.getBgColor(context),
                        border: Border.all(
                            color: active
                                ? theme.primaryColor
                                : theme.getBorderColor(context)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        st,
                        style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : theme.getTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Property Value (AUD)',
                      value: _propVal,
                      onChanged: (val) => setState(() => _propVal = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      label: 'Deposit Saved',
                      value: _depositVal,
                      onChanged: (val) => setState(() => _depositVal = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property Type Tabs
              Text('PROPERTY TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _buildToggleTab(
                          'New Build 🏗️',
                          _propType == 'new',
                          () => setState(() => _propType = 'new'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildToggleTab(
                          'Established 🏘️',
                          _propType == 'established',
                          () => setState(() => _propType = 'established'))),
                  const SizedBox(width: 4),
                  Expanded(
                      child: _buildToggleTab(
                          'Vacant Land 🌱',
                          _propType == 'vacant',
                          () => setState(() => _propType = 'vacant'))),
                ],
              ),
              const SizedBox(height: 12),

              // Owned before toggle
              Text('HAVE YOU OWNED PROPERTY IN AUSTRALIA BEFORE?',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _buildToggleTab('Never', !_ownedBefore,
                          () => setState(() => _ownedBefore = false))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildToggleTab('Yes', _ownedBefore,
                          () => setState(() => _ownedBefore = true))),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  setState(() => _showEligibilityResult = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('🏡 Check My Eligibility',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        if (_showEligibilityResult) ...[
          const SizedBox(height: 16),

          // Eligibility Result Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _ownedBefore
                  ? const Color(0xFFFFF1F2)
                  : isEligible
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFF7ED),
              border: Border.all(
                  color: _ownedBefore
                      ? const Color(0xFFFDA4AF)
                      : isEligible
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFB923C),
                  width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                        _ownedBefore
                            ? '❌'
                            : isEligible
                                ? '✅'
                                : '⚠️',
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _ownedBefore
                                  ? 'Not Eligible'
                                  : isEligible
                                      ? 'Eligible for FHOG!'
                                      : 'Check State Eligibility',
                              style: AppTextStyles.playfair(
                                  size: 16,
                                  weight: FontWeight.w900,
                                  color: _ownedBefore
                                      ? const Color(0xFF9F1239)
                                      : isEligible
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF9A3412))),
                          Text(
                              _ownedBefore
                                  ? 'Prior property ownership detected.'
                                  : '$_selectedState — ${g['name']}',
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  color: _ownedBefore
                                      ? const Color(0xFFBE123C)
                                      : isEligible
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFC2410C))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                    _ownedBefore
                        ? '\$0'
                        : isEligible
                            ? CurrencyFormatter.format(grantAmt,
                                currencyCode: 'AUD')
                            : 'See Concessions',
                    style: AppTextStyles.playfair(
                        size: 30,
                        weight: FontWeight.w900,
                        color: _ownedBefore
                            ? const Color(0xFF9F1239)
                            : isEligible
                                ? const Color(0xFF166534)
                                : const Color(0xFF9A3412))),
                const SizedBox(height: 4),
                Text(
                    _ownedBefore
                        ? reason
                        : isEligible
                            ? g['note']
                            : reason,
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        color: _ownedBefore
                            ? const Color(0xFFBE123C)
                            : isEligible
                                ? const Color(0xFF15803D)
                                : const Color(0xFFC2410C))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: Text('💾 Save This Result',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: Colors.black)),
                ),
              ],
            ),
          ),

          // Total benefit package card
          if (!_ownedBefore) ...[
            const SizedBox(height: 16),
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
                  Text('💰 Total Potential Benefit Package',
                      style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  const SizedBox(height: 14),
                  _buildTimelineBar('FHOG Grant', isEligible ? grantAmt : 0,
                      totalPotentialSavings, theme.primaryColor),
                  _buildTimelineBar(
                      'Stamp Duty Concession',
                      stampDutyConcession,
                      totalPotentialSavings,
                      const Color(0xFF002868)),
                  _buildTimelineBar('FHBG LMI Savings', lmiSavings,
                      totalPotentialSavings, const Color(0xFFD97706)),
                  _buildTimelineBar('FHSS Super Savings (Max)', superSavings,
                      totalPotentialSavings, const Color(0xFF0F766E)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Est. Total Potential Savings',
                          style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context))),
                      Text(
                          CurrencyFormatter.format(totalPotentialSavings,
                              currencyCode: 'AUD'),
                          style: AppTextStyles.playfair(
                              size: 18,
                              weight: FontWeight.w900,
                              color: theme.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTimelineBar(
      String label, double val, double maxVal, Color color) {
    if (val <= 0) return const SizedBox.shrink();
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.bold,
                      color: widget.theme.getTextColor(context))),
              Text(CurrencyFormatter.format(val, currencyCode: 'AUD'),
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w900,
                      color: widget.theme.getTextColor(context))),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 9,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: ALL STATES ─────────────────────────────────────────────
  Widget _buildAllStatesTab(CountryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _grantsData.entries.map((entry) {
        final st = entry.key;
        final g = entry.value;
        final amt = g['amount'] as double;
        final cap = g['cap'] as double;
        final propType = g['propType'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🏛️ $st — ${g['name']}',
                      style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context))),
                  Text(
                      amt > 0
                          ? CurrencyFormatter.format(amt, currencyCode: 'AUD')
                          : 'Concession Only',
                      style: AppTextStyles.playfair(
                          size: 15,
                          weight: FontWeight.w900,
                          color: theme.primaryColor)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  'Value Cap: ${cap > 0 ? CurrencyFormatter.format(cap, currencyCode: 'AUD') : 'No Cap (Stamp Duty Limit Only)'}',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 4),
              Text(g['note'],
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      color:
                          theme.getTextColor(context).withValues(alpha: 0.75))),
              if (g['extra'].isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('+ ${g['extra']}',
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        color: const Color(0xFF002868),
                        weight: FontWeight.bold)),
              ],
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: propType == 'new'
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  propType == 'new'
                      ? 'New Homes Only'
                      : 'All Properties (New & Established)',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w800,
                    color: propType == 'new'
                        ? const Color(0xFF166534)
                        : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── TAB 3: FEDERAL SCHEMES ────────────────────────────────────────
  Widget _buildSchemesTab(CountryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSchemeCard(
          icon: '🏦',
          iconColor: Colors.blue,
          title: 'First Home Guarantee (FHBG)',
          sub: 'Housing Australia — 5% deposit, no LMI',
          details: {
            'Places (2024–25)': '35,000 national places',
            'Min Deposit': '5% (Government guarantees remaining 15%)',
            'Price Cap (Syd/Melb)': '\$900,000 (NSW), \$800,000 (VIC)',
            'Price Cap (Regional)': '\$750,000 (NSW), \$700,000 (VIC)',
            'Income Limit (Single)': '≤ \$125,000 per annum',
            'Income Limit (Joint)': '≤ \$200,000 per annum',
            'Est. LMI Saving': '~\$15,000 – \$33,000 saved',
          },
          badgeText: 'New & Existing Properties',
          badgeColor: const Color(0xFFEFF6FF),
          badgeTextColor: const Color(0xFF1D4ED8),
        ),
        _buildSchemeCard(
          icon: '🏘️',
          iconColor: Colors.green,
          title: 'Regional First Home Guarantee',
          sub: 'Regional areas only — 5% deposit, no LMI',
          details: {
            'Places (2024–25)': '10,000 regional places',
            'Price Cap (Reg. NSW/VIC)': '\$750,000 (NSW), \$700,000 (VIC)',
            'Price Cap (Other Reg.)': '\$550,000 – \$600,000',
            'Regional Residency Req.':
                'Must have lived/worked in region for 12 months',
          },
          badgeText: 'Regional Capital & Towns Only',
          badgeColor: const Color(0xFFF0FDF4),
          badgeTextColor: const Color(0xFF166534),
        ),
        _buildSchemeCard(
          icon: '💰',
          iconColor: Colors.amber,
          title: 'First Home Super Saver (FHSS)',
          sub: 'Save deposit inside super — tax savings',
          details: {
            'Max Withdraw Limit': '\$50,000 per person',
            'Annual Concession Cap': '\$15,000 per financial year',
            'Tax Rate on Contributions':
                '15% (compared to marginal income tax rate)',
            'Est. Tax Saving': 'Up to \$15,000 combined benefit',
            'Joint Buyers Eligible': 'Yes (up to \$100,000 combined)',
          },
          badgeText: 'Tax-Advantaged Super Saving',
          badgeColor: const Color(0xFFFEFCE8),
          badgeTextColor: const Color(0xFF92400E),
        ),
        _buildSchemeCard(
          icon: '🤝',
          iconColor: Colors.purple,
          title: 'Family Home Guarantee',
          sub: 'Single parents / guardians — 2% deposit, no LMI',
          details: {
            'Places (2024–25)': '5,000 places',
            'Min Deposit': '2% (Government guarantees up to 18%)',
            'Income Limit': '≤ \$125,000 per annum',
            'Dependent Required': 'Yes, must have at least one dependent child',
          },
          badgeText: 'Single Parents & Legal Guardians',
          badgeColor: const Color(0xFFFAF5FF),
          badgeTextColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildSchemeCard({
    required String icon,
    required Color iconColor,
    required String title,
    required String sub,
    required Map<String, String> details,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.playfair(
                            size: 13.5,
                            weight: FontWeight.bold,
                            color: widget.theme.getTextColor(context))),
                    Text(sub,
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: widget.theme.getMutedColor(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: AppTextStyles.dmSans(
                            size: 10.5,
                            color: widget.theme
                                .getTextColor(context)
                                .withValues(alpha: 0.7))),
                    Text(e.value,
                        style: AppTextStyles.dmSans(
                            size: 10.5,
                            weight: FontWeight.bold,
                            color: widget.theme.getTextColor(context))),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w800,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 4: CHECKLIST ──────────────────────────────────────────────
  Widget _buildChecklistTab(CountryTheme theme) {
    final fhogItems = [
      'Completed FHOG application form (signed by all parties)',
      'Identity documents (Australian Passport, Citizenship or birth cert)',
      'Partner identity documents (even if not on the title)',
      'Contract of Sale (signed by buyer and vendor)',
      'Building contract (if building a new home, signed/dated)',
      'Bank details for grant deposit payout',
      'Statutory declaration confirming first home status',
      'Marriage or change of name certificate (if applicable)',
    ];

    final fhbgItems = [
      'Notice of Assessment (ATO) for last financial year',
      'Home loan pre-approval with a participating lender',
      'Proof of Australian citizenship (Passport or Birth Certificate)',
      'Evidence property fits price cap for capital/regional zones',
      'Proof of at least 5% genuine savings deposit',
      'No prior residential property ownership anywhere in Australia',
    ];

    final fhssItems = [
      'Voluntary super contributions (pre or post-tax, up to \$15K/yr)',
      'Request FHSS determination from ATO before signing contract',
      'Ensure total voluntary contributions under \$50,000 lifetime',
      'Apply to release FHSS funds from myGov ATO portal',
      'Sign a contract to purchase/build within 12 months of release',
      'Notify ATO of contract signing within 28 days of purchase',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChecklistSection(
            'First Home Owner Grant (FHOG)', fhogItems, 'fhog'),
        const SizedBox(height: 14),
        _buildChecklistSection(
            'First Home Guarantee (FHBG)', fhbgItems, 'fhbg'),
        const SizedBox(height: 14),
        _buildChecklistSection('Super Saver Scheme (FHSS)', fhssItems, 'fhss'),
      ],
    );
  }

  Widget _buildChecklistSection(
      String title, List<String> items, String prefix) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.playfair(
                  size: 13.5,
                  weight: FontWeight.bold,
                  color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final key = '$prefix-$idx';
            final checked = _checkedItems.contains(key);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (checked) {
                      _checkedItems.remove(key);
                    } else {
                      _checkedItems.add(key);
                    }
                  });
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            checked ? theme.primaryColor : Colors.transparent,
                        border: Border.all(
                            color: checked
                                ? theme.primaryColor
                                : theme
                                    .getTextColor(context)
                                    .withValues(alpha: 0.3),
                            width: 2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: checked
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTextStyles.dmSans(
                          size: 11,
                          color: checked
                              ? theme
                                  .getTextColor(context)
                                  .withValues(alpha: 0.5)
                              : theme.getTextColor(context),
                        ).copyWith(
                          decoration:
                              checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper Inputs
  Widget _buildInputField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9,
                color: theme.getMutedColor(context),
                weight: FontWeight.w800,
                letterSpacing: 0.5)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text('\$ ',
                  style: AppTextStyles.dmSans(
                      size: 13.5,
                      color: theme.primaryColor,
                      weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: value.toInt().toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.dmSans(
                      size: 13.5,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800),
                  decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTab(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF002868)
              : widget.theme.getBgColor(context),
          border: Border.all(
              color: active
                  ? const Color(0xFF002868)
                  : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF92400E),
          ),
        ),
      ),
    );
  }
}
