// lib/features/india/tools/in_stamp_duty_all_states.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' show min, pi;
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INStampDutyAllStates extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INStampDutyAllStates({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INStampDutyAllStates> createState() =>
      _INStampDutyAllStatesState();
}

class _INStampDutyAllStatesState extends ConsumerState<INStampDutyAllStates> {
  // Input states
  String _selectedStateCode = 'MH';
  String _gender = 'male'; // male, female, joint
  double _propValue = 7500000; // 75 Lakhs default
  String _propType = 'residential'; // residential, commercial, agricultural
  String _constrStatus = 'ready'; // ready, under

  // Filter & Search states
  String _activeFilter = 'all'; // all, low, high, concession, metro
  String _searchQuery = '';

  // Controllers
  late TextEditingController _propValueCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultPanelKey = GlobalKey();

  // Expansion states for SRO guidelines
  final Map<String, bool> _stateGuidelinesExpanded = {};

  // Full 28 States Database from HTML
  static final List<Map<String, dynamic>> _states = [
    {
      'code': 'MH',
      'icon': '🌆',
      'name': 'Maharashtra',
      'capital': 'Mumbai',
      'category': 'high',
      'male': 6.0,
      'female': 5.0,
      'joint': 5.5,
      'reg': 1.0,
      'metro': 1.0,
      'other': 'Local Body Tax 1% (MCGM area)',
      'notes':
          'Metro cess 1% applies in Mumbai, Pune, Nagpur, Thane. Women get 1% concession. Maximum stamp duty capped at ₹30,000 for agreements. Registration fee 1% of property value (max ₹30,000 for agreements). Surcharge in Mumbai: LBT 1%.',
      'concession': true,
      'metroSurcharge': true,
      'tags': [
        'tag-s',
        'Metro Surcharge',
        'tag-g',
        'Women -1%',
        'tag-b',
        'PSU Banks'
      ]
    },
    {
      'code': 'DL',
      'icon': '🏙️',
      'name': 'Delhi',
      'capital': 'New Delhi',
      'category': 'mid',
      'male': 6.0,
      'female': 4.0,
      'joint': 5.0,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          'Women buyers get 2% concession on stamp duty (4% vs 6%). Registration fee is 1% of agreement value. No metro surcharge. Property in DDA colonies may have additional charges. NDMC area properties have the same rates.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 4%', 'tag-b', 'Men 6%']
    },
    {
      'code': 'KA',
      'icon': '💻',
      'name': 'Karnataka',
      'capital': 'Bengaluru',
      'category': 'mid',
      'male': 5.0,
      'female': 5.0,
      'joint': 5.0,
      'reg': 1.0,
      'metro': 0.0,
      'other': 'BBMP Cess up to 0.5%',
      'notes':
          'Stamp duty is 5% for both male and female. Registration charge 1%. Additional BBMP cess up to 0.5% for Bengaluru properties. Property valued below ₹20 lakh has concessional duty of 2%. Agricultural land has different rates.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-o', 'Flat 5%', 'tag-b', 'BBMP +0.5%']
    },
    {
      'code': 'TN',
      'icon': '🌊',
      'name': 'Tamil Nadu',
      'capital': 'Chennai',
      'category': 'high',
      'male': 7.0,
      'female': 7.0,
      'joint': 7.0,
      'reg': 4.0,
      'metro': 0.0,
      'other': 'Transfer duty 0.5%',
      'notes':
          'Highest combined rate in India: 7% stamp duty + 4% registration = 11% total. No gender concession. Transfer duty of 0.5% additional. Gift deed: 7%. Properties in Chennai Corporation area attract additional local charges.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-s', 'Highest 11%', 'tag-o', 'No Concession']
    },
    {
      'code': 'TS',
      'icon': '🏗️',
      'name': 'Telangana',
      'capital': 'Hyderabad',
      'category': 'low',
      'male': 4.0,
      'female': 4.0,
      'joint': 4.0,
      'reg': 0.5,
      'metro': 0.0,
      'other': 'Transfer duty 1.5%',
      'notes':
          'Stamp duty 4% + Registration 0.5% + Transfer duty 1.5% = 6% total. No gender concession. Gift deeds also 4%. Properties in GHMC area may have additional local body taxes. Sub-registrar offices provide e-registration facility.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Low 4%', 'tag-b', '6% Total']
    },
    {
      'code': 'UP',
      'icon': '🕌',
      'name': 'Uttar Pradesh',
      'capital': 'Lucknow',
      'category': 'high',
      'male': 7.0,
      'female': 6.0,
      'joint': 6.5,
      'reg': 1.0,
      'metro': 0.0,
      'other': 'Municipal tax varies',
      'notes':
          '7% for male, 6% for female buyers. Registration 1%. Additional municipal surcharge in Lucknow, Agra, Kanpur, Varanasi urban areas. Gift deeds attract 2% stamp duty (max ₹5,000 for near relatives).',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-s', '7% Male', 'tag-g', 'Women 6%']
    },
    {
      'code': 'GJ',
      'icon': '🏭',
      'name': 'Gujarat',
      'capital': 'Ahmedabad',
      'category': 'mid',
      'male': 4.9,
      'female': 3.9,
      'joint': 4.4,
      'reg': 1.0,
      'metro': 0.0,
      'other': 'Revenue surcharge 1%',
      'notes':
          'Stamp duty 4.9% (male) / 3.9% (female) + 1% surcharge = effective ~5.9% / 4.9%. Registration fee 1%. Urban areas in Ahmedabad, Surat, Vadodara attract same rates. E-registration available via SRO online portal.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 3.9%', 'tag-o', '+1% Surcharge']
    },
    {
      'code': 'RJ',
      'icon': '🏰',
      'name': 'Rajasthan',
      'capital': 'Jaipur',
      'category': 'high',
      'male': 6.0,
      'female': 5.0,
      'joint': 5.5,
      'reg': 1.0,
      'metro': 0.0,
      'other': 'Surcharge 10% of duty',
      'notes':
          '6% (male), 5% (female), plus 10% surcharge on stamp duty amount. Registration 1%. Agricultural land: 5%. In Jaipur Municipal Corporation area, additional urban improvement trust charges may apply.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-s', '6% + Surcharge', 'tag-g', 'Women 5%']
    },
    {
      'code': 'WB',
      'icon': '🎶',
      'name': 'West Bengal',
      'capital': 'Kolkata',
      'category': 'high',
      'male': 7.0,
      'female': 7.0,
      'joint': 7.0,
      'reg': 1.0,
      'metro': 1.0,
      'other': 'Local body tax 1% (KMC)',
      'notes':
          '7% stamp duty + 1% registration + 1% KMC (Kolkata Municipal Corporation) cess = 9% total in Kolkata. No gender concession. Same rate across urban and semi-urban areas. Agricultural land: 5%.',
      'concession': false,
      'metroSurcharge': true,
      'tags': ['tag-s', '9% in Kolkata', 'tag-o', 'KMC +1%']
    },
    {
      'code': 'HR',
      'icon': '🌾',
      'name': 'Haryana',
      'capital': 'Chandigarh',
      'category': 'high',
      'male': 7.0,
      'female': 5.0,
      'joint': 6.0,
      'reg': 0.0,
      'metro': 0.0,
      'other': 'Registry fee ₹100-₹15,000',
      'notes':
          '7% (male), 5% (female). No separate registration percentage — fixed registry fee from ₹100 to ₹15,000 based on value slab. Properties in Gurgaon, Faridabad, Panchkula: same duty. Urban areas: additional Haryana Urban Development Authority charges may apply.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 5%', 'tag-b', 'Fixed Reg Fee']
    },
    {
      'code': 'PB',
      'icon': '🌻',
      'name': 'Punjab',
      'capital': 'Chandigarh',
      'category': 'mid',
      'male': 5.0,
      'female': 3.0,
      'joint': 4.0,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '5% (male), 3% (female) — highest concession in India. Registration 1%. Properties in Chandigarh (UT): separate rates. Agricultural land: 5%. Gift to blood relative: 3% (male) / 1% (female).',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 3% ⭐', 'tag-s', 'Best Concession']
    },
    {
      'code': 'MP',
      'icon': '🌿',
      'name': 'Madhya Pradesh',
      'capital': 'Bhopal',
      'category': 'high',
      'male': 7.5,
      'female': 7.5,
      'joint': 7.5,
      'reg': 3.0,
      'metro': 0.0,
      'other': 'Jantri surcharge',
      'notes':
          '7.5% stamp duty + 3% registration = 10.5% total — among the highest. No gender concession. Jantri (circle rate) surcharge applies. Properties in Bhopal, Indore, Jabalpur urban areas same rates. Gift deed: 5%.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-s', '10.5% Total', 'tag-o', 'No Concession']
    },
    {
      'code': 'BR',
      'icon': '🏛️',
      'name': 'Bihar',
      'capital': 'Patna',
      'category': 'high',
      'male': 6.0,
      'female': 5.7,
      'joint': 5.8,
      'reg': 2.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '6% stamp duty (male), 5.7% (female). Registration 2%. Total: 8% for male. Properties in Patna Municipal Corporation area same rates. Gift deed: 1.8%. Agricultural land: 5.7%.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-s', '8% Total (Male)', 'tag-g', 'Women 7.7%']
    },
    {
      'code': 'OR',
      'icon': '🌴',
      'name': 'Odisha',
      'capital': 'Bhubaneswar',
      'category': 'mid',
      'male': 5.0,
      'female': 4.0,
      'joint': 4.5,
      'reg': 2.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '5% (male) + 2% registration = 7% total. Female buyers get 1% concession on stamp duty. Agricultural land: 3%. Gift deed to relative: 2%. Properties in BMC (Bhubaneswar) area have same rates.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 4%', 'tag-b', 'Reg 2%']
    },
    {
      'code': 'KL',
      'icon': '🌊',
      'name': 'Kerala',
      'capital': 'Thiruvananthapuram',
      'category': 'mid',
      'male': 8.0,
      'female': 8.0,
      'joint': 8.0,
      'reg': 2.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '8% stamp duty for all (no gender concession) + 2% registration = 10% total. The highest in south India after Tamil Nadu total. Agricultural land: 8%. Gift deed: 2% (between relatives). Patta transfer fee separate.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-s', '10% Total', 'tag-o', 'No Concession']
    },
    {
      'code': 'AP',
      'icon': '🌾',
      'name': 'Andhra Pradesh',
      'capital': 'Vijayawada',
      'category': 'mid',
      'male': 5.0,
      'female': 5.0,
      'joint': 5.0,
      'reg': 1.0,
      'metro': 0.0,
      'other': 'Transfer duty 1.5%',
      'notes':
          '5% stamp duty + 1% registration + 1.5% transfer duty = 7.5% total. No gender concession. Properties in Vijayawada, Visakhapatnam, Tirupati same rates. Gift deed to close family: 2%.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-o', '7.5% Total', 'tag-b', 'Transfer duty 1.5%']
    },
    {
      'code': 'HP',
      'icon': '🏔️',
      'name': 'Himachal Pradesh',
      'capital': 'Shimla',
      'category': 'low',
      'male': 6.0,
      'female': 4.0,
      'joint': 5.0,
      'reg': 2.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '6% (male), 4% (female). Registration 2%. Among the lowest effective rates for women. Agricultural land: 8%. Properties in tribal areas may have different rates. Gift deed to near relatives: 2%.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 4%', 'tag-b', 'Reg 2%']
    },
    {
      'code': 'UA',
      'icon': '🏔️',
      'name': 'Uttarakhand',
      'capital': 'Dehradun',
      'category': 'mid',
      'male': 5.0,
      'female': 3.75,
      'joint': 4.5,
      'reg': 2.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '5% (male), 3.75% (female). Registration 2%. Tourist/hill station properties same rate. Agricultural land: 5%. Gift deed: 2%. Properties in Dehradun Municipal Corporation area same.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 3.75%', 'tag-b', 'Hill State']
    },
    {
      'code': 'AS',
      'icon': '🌿',
      'name': 'Assam',
      'capital': 'Guwahati',
      'category': 'mid',
      'male': 6.0,
      'female': 5.0,
      'joint': 5.5,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '6% (male), 5% (female). Registration 1%. Properties in GMC (Guwahati) area same. Tea garden land: separate rates. Agricultural land: 6%. Gift deed: 3%.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 5%', 'tag-o', 'NE State']
    },
    {
      'code': 'JH',
      'icon': '⛏️',
      'name': 'Jharkhand',
      'capital': 'Ranchi',
      'category': 'mid',
      'male': 4.0,
      'female': 4.0,
      'joint': 4.0,
      'reg': 3.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '4% stamp duty + 3% registration = 7% total. No gender concession. Properties in Ranchi, Dhanbad, Jamshedpur urban areas. Agricultural land: 4%. Tribal land transactions have separate regulations.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-o', '7% Total', 'tag-b', 'No Concession']
    },
    {
      'code': 'CG',
      'icon': '🌾',
      'name': 'Chhattisgarh',
      'capital': 'Raipur',
      'category': 'low',
      'male': 5.0,
      'female': 4.0,
      'joint': 4.5,
      'reg': 4.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '5% (male), 4% (female). Registration 4% (high). Total: 9% for male. Properties in Raipur, Bilaspur urban areas. Agricultural land: 3%. Gift deed: 4%.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 4%', 'tag-s', 'High Reg 4%']
    },
    {
      'code': 'GA',
      'icon': '🌴',
      'name': 'Goa',
      'capital': 'Panaji',
      'category': 'low',
      'male': 3.5,
      'female': 2.5,
      'joint': 3.0,
      'reg': 0.5,
      'metro': 0.0,
      'other': '—',
      'notes':
          'Lowest combined rate in India. 3.5% (male), 2.5% (female). Registration 0.5%. Total for female: 3%. No metro surcharge. Tourist properties same rate. Gift deed: 2%. Inheritance: 0.5%.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Lowest Rates ⭐', 'tag-b', 'Women 2.5%']
    },
    {
      'code': 'MZ',
      'icon': '🌿',
      'name': 'Mizoram',
      'capital': 'Aizawl',
      'category': 'low',
      'male': 2.0,
      'female': 2.0,
      'joint': 2.0,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          'Lowest stamp duty in India at 2% for all buyers. No gender concession. Registration 1%. Total: 3% only. Village community land has different regulations. NE special provisions apply.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Lowest 2% ⭐', 'tag-b', 'NE State']
    },
    {
      'code': 'NL',
      'icon': '🌿',
      'name': 'Nagaland',
      'capital': 'Kohima',
      'category': 'low',
      'male': 3.0,
      'female': 3.0,
      'joint': 3.0,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '3% stamp duty + 1% registration = 4% total. No gender concession. Tribal land governed by customary law and may not require stamp duty. Special NE provisions.',
      'concession': false,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Low 4% Total', 'tag-b', 'NE State']
    },
    {
      'code': 'MN',
      'icon': '🌿',
      'name': 'Manipur',
      'capital': 'Imphal',
      'category': 'low',
      'male': 7.0,
      'female': 6.0,
      'joint': 6.5,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '7% (male), 6% (female). Registration 1%. Though duty rates are mid-high, overall transactions lower. Tribal hill areas: customary law applies. No metro surcharge.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 6%', 'tag-b', 'NE State']
    },
    {
      'code': 'TR',
      'icon': '🌿',
      'name': 'Tripura',
      'capital': 'Agartala',
      'category': 'mid',
      'male': 5.0,
      'female': 4.0,
      'joint': 4.5,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '5% (male), 4% (female). Registration 1%. Agricultural land: 5%. Gift deed: 2%. Tribal land has special regulations under TTAADC.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 4%', 'tag-b', 'NE State']
    },
    {
      'code': 'SK',
      'icon': '🏔️',
      'name': 'Sikkim',
      'capital': 'Gangtok',
      'category': 'low',
      'male': 4.0,
      'female': 3.0,
      'joint': 3.5,
      'reg': 0.5,
      'metro': 0.0,
      'other': '—',
      'notes':
          '4% (male), 3% (female). Registration 0.5%. Very low total cost. Non-Sikkimese cannot own land; restrictions on property purchase for outsiders under special law.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Low 3.5%', 'tag-s', 'Restricted Buyers']
    },
    {
      'code': 'AR',
      'icon': '🏔️',
      'name': 'Arunachal Pradesh',
      'capital': 'Itanagar',
      'category': 'low',
      'male': 6.0,
      'female': 5.0,
      'joint': 5.5,
      'reg': 1.0,
      'metro': 0.0,
      'other': '—',
      'notes':
          '6% (male), 5% (female). Registration 1%. Only Arunachali tribal people can own land under Inner Line Permit system. Non-tribal residents require special permission.',
      'concession': true,
      'metroSurcharge': false,
      'tags': ['tag-g', 'Women 5%', 'tag-s', 'ILP Required']
    }
  ];

  @override
  void initState() {
    super.initState();
    _propValueCtrl = TextEditingController(text: _propValue.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _propValueCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveStampDutyReport() async {
    final state = _states.firstWhere((s) => s['code'] == _selectedStateCode);
    final double dutyPct = _gender == 'male'
        ? state['male']
        : (_gender == 'female' ? state['female'] : state['joint']);
    final double regPct = state['reg'];
    final double metroAdd = state['metroSurcharge'] ? state['metro'] : 0.0;

    final stampAmt = _propValue * (dutyPct / 100);
    final regAmt = _propValue * (regPct / 100);
    final metroAmt = _propValue * (metroAdd / 100);
    final totalAmt = stampAmt + regAmt + metroAmt;

    final labelCtrl =
        TextEditingController(text: 'Stamp Duty Snapshot - ${state['name']}');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_stamp_duty_all_states'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Stamp Duty Snapshot',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: ${_fmt(totalAmt)} govt fees for ${state['name']}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Pune Property Reg)',
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
              backgroundColor: const Color(0xFF046A38),
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
          : 'Stamp Duty Report';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'State Stamp Duty',
        inputs: {
          'propertyValue': _propValue,
          'stateIndex': _states.indexOf(state).toDouble(),
          'gender': _gender == 'male' ? 0.0 : (_gender == 'female' ? 1.0 : 2.0),
        },
        results: {
          'stampDuty': stampAmt,
          'registrationFee': regAmt,
          'otherCharges': metroAmt,
          'totalCost': totalAmt,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stamp duty report saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  void _scrollToResultsPanel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultPanelKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedState =
        _states.firstWhere((s) => s['code'] == _selectedStateCode);
    final double dutyPct = _gender == 'male'
        ? selectedState['male']
        : (_gender == 'female'
            ? selectedState['female']
            : selectedState['joint']);
    final double regPct = selectedState['reg'];
    final double metroAdd =
        selectedState['metroSurcharge'] ? selectedState['metro'] : 0.0;

    final stampAmt = _propValue * (dutyPct / 100);
    final regAmt = _propValue * (regPct / 100);
    final metroAmt = _propValue * (metroAdd / 100);
    final totalAmt = stampAmt + regAmt + metroAmt;

    // Filter states list based on active filter bar chip and search query
    final filteredStates = _states.where((s) {
      final nameMatch = s['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final capMatch = s['capital']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final codeMatch = s['code']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final queryMatch = nameMatch || capMatch || codeMatch;

      bool filterMatch = true;
      if (_activeFilter == 'low') filterMatch = s['male'] <= 4.0;
      if (_activeFilter == 'high') filterMatch = s['male'] >= 6.5;
      if (_activeFilter == 'concession') filterMatch = s['concession'] == true;
      if (_activeFilter == 'metro') filterMatch = s['metroSurcharge'] == true;

      return queryMatch && filterMatch;
    }).toList();

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
              _infoCell('Lowest', '2%', 'HP / Mizoram', isGreen: true),
              _infoCell('Highest', '7%', 'Tamil Nadu', isSaffron: true),
              _infoCell('Avg Reg.', '1%', 'National'),
              _infoCell('States', '36', 'Incl. UTs'),
            ],
          ),
        ),

        // Stamp Duty Calculator setup card
        Text('Stamp Duty Calculator',
            style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('भारत · STAMP DUTY & REGISTRATION CHARGES',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Calculate Total Cost of Property Registration',
                  style: AppTextStyles.playfair(
                      size: 17, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 14),

              // State Select Dropdown
              Text('SELECT STATE / UT',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: Colors.white70,
                      weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStateCode,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0B1F48),
                    style: AppTextStyles.dmSans(
                        size: 13, weight: FontWeight.w700, color: Colors.white),
                    items: _states.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['code'],
                        child: Text(s['name']),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedStateCode = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Buyer Gender choice row
              Text('GENDER OF BUYER',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: Colors.white70,
                      weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _choiceBtn('Male', _gender == 'male',
                      () => setState(() => _gender = 'male')),
                  const SizedBox(width: 5),
                  _choiceBtn('Female (Concess.)', _gender == 'female',
                      () => setState(() => _gender = 'female')),
                  const SizedBox(width: 5),
                  _choiceBtn('Joint', _gender == 'joint',
                      () => setState(() => _gender = 'joint')),
                ],
              ),
              const SizedBox(height: 12),

              // Property Value input-slider sync
              _buildSyncedInputRow(
                label: 'PROPERTY VALUE',
                controller: _propValueCtrl,
                value: _propValue,
                min: 100000,
                max: 100000000, // 10 Cr max
                prefix: '₹ ',
                onChangedText: (val) => setState(() => _propValue = val),
                onChangedSlider: (val) => setState(() {
                  _propValue = val;
                  _propValueCtrl.text = val.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 12),

              // Property Type & Construction Status dropdowns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROPERTY TYPE',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white60,
                                weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _propType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1F48),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: 'residential',
                                    child: Text('Residential')),
                                DropdownMenuItem(
                                    value: 'commercial',
                                    child: Text('Commercial')),
                                DropdownMenuItem(
                                    value: 'agricultural',
                                    child: Text('Agricultural')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _propType = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONSTRUCTION STATUS',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white60,
                                weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _constrStatus,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1F48),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: 'ready',
                                    child: Text('Ready Possession')),
                                DropdownMenuItem(
                                    value: 'under',
                                    child: Text('Under Construction')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _constrStatus = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _scrollToResultsPanel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('🏛️ Calculate Stamp Duty & Charges',
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Calculated Results Card
        Container(
          key: _resultPanelKey,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
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
                  Text('${selectedState['name']} — Stamp Duty Result',
                      style: AppTextStyles.dmSans(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  GestureDetector(
                    onTap: _saveStampDutyReport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF046A38), Color(0xFF07543A)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Save',
                          style: AppTextStyles.dmSans(
                              size: 9,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Summary stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 1.6,
                children: [
                  _resBoxSummary(
                      'STAMP DUTY',
                      _fmt(stampAmt),
                      '${dutyPct.toStringAsFixed(2)}% of value',
                      const Color(0xFFFF6B00),
                      context),
                  _resBoxSummary(
                      'REGISTRATION FEE',
                      _fmt(regAmt),
                      '${regPct.toStringAsFixed(2)}% registration',
                      const Color(0xFF0B1F48),
                      context),
                  _resBoxSummary(
                      'OTHER CHARGES',
                      metroAmt > 0
                          ? _fmt(metroAmt)
                          : (selectedState['other'] != '—'
                              ? 'See Notes'
                              : '₹0'),
                      metroAmt > 0
                          ? 'Metro / local cess'
                          : selectedState['other'],
                      const Color(0xFF046A38),
                      context),
                  _resBoxSummary('TOTAL COST', _fmt(totalAmt), 'All-in charges',
                      const Color(0xFF0B1F48), context,
                      isTotal: true),
                ],
              ),
              const SizedBox(height: 16),

              // Donut split breakdown chart
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _ThreeSegmentDonutPainter(
                        v1: stampAmt,
                        v2: regAmt,
                        v3: metroAmt,
                        c1: const Color(0xFFFF6B00),
                        c2: const Color(0xFF0B1F48),
                        c3: const Color(0xFF046A38),
                        centerText: _fmtShort(totalAmt),
                        textColor: theme.getTextColor(context),
                        mutedColor: theme.getMutedColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(
                            const Color(0xFFFF6B00), 'Stamp Duty', context),
                        const SizedBox(height: 6),
                        _legendRow(
                            const Color(0xFF0B1F48), 'Registration', context),
                        const SizedBox(height: 6),
                        _legendRow(
                            const Color(0xFF046A38), 'Other Charges', context),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cost breakdown progress bars
              _bdProgressBar(
                  'Stamp Duty', stampAmt, totalAmt, const Color(0xFFFF6B00)),
              _bdProgressBar('Registration Fee', regAmt, totalAmt,
                  const Color(0xFF0B1F48)),
              _bdProgressBar(
                  'Other Charges', metroAmt, totalAmt, const Color(0xFF046A38)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: const Color(0xFFFF6B00))),
                  Text(_fmt(totalAmt),
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: const Color(0xFFFF6B00))),
                ],
              ),
              const SizedBox(height: 12),

              // State Specific Notes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                  border: Border.all(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 State-Specific Notes',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    const SizedBox(height: 4),
                    Text(selectedState['notes'] as String,
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: theme.getMutedColor(context),
                            height: 1.55)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // India Stamp Duty Overview summary banner
        Text('India Stamp Duty Overview',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
                width: 1.5),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _overviewItem('Avg Stamp Duty', '5.2%', context),
              _overviewItem('Avg Reg. Fee', '1.0%', context),
              _overviewItem('States w/ Concession', '14', context),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // State Card list with filters and search
        Text('State Overview & Guidelines',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        // Filter chips bar
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All States', 'all'),
              _buildFilterChip('Low Duty', 'low', isGreen: true),
              _buildFilterChip('High Duty', 'high'),
              _buildFilterChip('Women Concession', 'concession', isBlue: true),
              _buildFilterChip('Metro Surcharge', 'metro'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Search inputs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: TextField(
            style: AppTextStyles.dmSans(
                size: 13, color: theme.getTextColor(context)),
            decoration: InputDecoration(
              icon: Text('🔍',
                  style: TextStyle(
                      fontSize: 16, color: theme.getMutedColor(context))),
              hintText: 'Search state or city…',
              hintStyle: AppTextStyles.dmSans(
                  size: 12.5, color: theme.getMutedColor(context)),
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

        // Grid cards list for all states
        Column(
          children: filteredStates.map((s) {
            final cat = s['category'] as String;
            final isExpanded = _stateGuidelinesExpanded[s['code']] ?? false;

            Color sideBorderColor = theme.getBorderColor(context);
            if (cat == 'high') {
              sideBorderColor = const Color(0xFFFF6B00);
            } else if (cat == 'mid') {
              sideBorderColor = const Color(0xFFFFDEA0);
            } else if (cat == 'low') {
              sideBorderColor = const Color(0xFF046A38);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                border: Border.all(color: theme.getBorderColor(context)),
                borderRadius: BorderRadius.circular(17),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: isExpanded ? 150 : 80,
                    color: sideBorderColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStateCode = s['code'];
                                  });
                                  _scrollToResultsPanel();
                                },
                                child: Row(
                                  children: [
                                    Text(s['icon'],
                                        style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'],
                                            style: AppTextStyles.dmSans(
                                                size: 13.5,
                                                weight: FontWeight.w800,
                                                color: theme
                                                    .getTextColor(context))),
                                        Text(s['capital'],
                                            style: AppTextStyles.dmSans(
                                                size: 9,
                                                color: theme
                                                    .getMutedColor(context))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sideBorderColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${s['male']}%',
                                    style: AppTextStyles.dmSans(
                                        size: 11,
                                        color: Colors.white,
                                        weight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _subStatBox('Male', '${s['male']}%', context),
                              _subStatBox('Female', '${s['female']}%', context),
                              _subStatBox('Reg Fee', '${s['reg']}%', context),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: (s['tags'] as List).map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme
                                      .getBorderColor(context)
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(t as String,
                                    style: AppTextStyles.dmSans(
                                        size: 7.5,
                                        color: theme.getMutedColor(context),
                                        weight: FontWeight.w700)),
                              );
                            }).toList(),
                          ),

                          // SRO state guidelines accordion expand
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _stateGuidelinesExpanded[s['code']] =
                                    !isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('📋 State Notes',
                                      style: AppTextStyles.dmSans(
                                          size: 9,
                                          color: const Color(0xFFFF6B00),
                                          weight: FontWeight.w700)),
                                  Icon(
                                    isExpanded
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: const Color(0xFFFF6B00),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isExpanded) ...[
                            const SizedBox(height: 4),
                            Text(s['notes'] as String,
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: theme.getMutedColor(context),
                                    height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note,
      {bool isGreen = false, bool isSaffron = false}) {
    Color valColor = Colors.white;
    if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    } else if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    }
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white.withValues(alpha: 0.55),
                weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(note,
            style: AppTextStyles.dmSans(
                size: 7.5, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _choiceBtn(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6B00)
                : Colors.white.withValues(alpha: 0.1),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6B00)
                    : Colors.white.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.w800,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),
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
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white70, weight: FontWeight.w800)),
            Text('$prefix${_fmtShort(value)}$suffix',
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFFDEA0))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 12.5, color: Colors.white, weight: FontWeight.w800),
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
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
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

  Widget _resBoxSummary(String label, String value, String subText, Color color,
      BuildContext context,
      {bool isTotal = false}) {
    final theme = widget.theme;
    Color bg = theme.getCardColor(context);
    Color border = theme.getBorderColor(context);

    if (isTotal) {
      bg = const Color(0xFF0B1F48).withValues(alpha: 0.05);
      border = const Color(0xFF0B1F48).withValues(alpha: 0.18);
    } else {
      bg = color.withValues(alpha: 0.04);
      border = color.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 14.5,
                  weight: FontWeight.w800,
                  color: isTotal ? theme.getTextColor(context) : color)),
          const SizedBox(height: 1),
          Text(subText,
              style: AppTextStyles.dmSans(
                  size: 8, color: theme.getMutedColor(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9.5,
                color: widget.theme.getTextColor(context),
                weight: FontWeight.w600)),
      ],
    );
  }

  Widget _bdProgressBar(String label, double val, double total, Color color) {
    final double pct = total > 0 ? val / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: widget.theme.getTextColor(context),
                    weight: FontWeight.w700)),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: widget.theme
                    .getBorderColor(context)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              _fmt(val),
              style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w800,
                  color: widget.theme.getTextColor(context)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 8,
                color: const Color(0xFF07543A),
                weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 15,
                weight: FontWeight.w800,
                color: const Color(0xFF07543A))),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filter,
      {bool isGreen = false, bool isBlue = false}) {
    final isSelected = _activeFilter == filter;
    Color border = const Color(0xFFFF6B00).withValues(alpha: 0.18);
    Color bg = const Color(0xFFFF6B00).withValues(alpha: 0.08);
    Color color = const Color(0xFFFF6B00);

    if (isGreen) {
      border = const Color(0xFF046A38).withValues(alpha: 0.25);
      bg = const Color(0xFF046A38).withValues(alpha: 0.07);
      color = const Color(0xFF046A38);
    } else if (isBlue) {
      border = const Color(0xFF1D4ED8).withValues(alpha: 0.25);
      bg = const Color(0xFF1D4ED8).withValues(alpha: 0.06);
      color = const Color(0xFF1D4ED8);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : bg,
          border: Border.all(color: isSelected ? color : border),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _subStatBox(String label, String value, BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8, color: widget.theme.getMutedColor(context))),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: widget.theme.getTextColor(context))),
        ],
      ),
    );
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }
}

class _ThreeSegmentDonutPainter extends CustomPainter {
  final double v1;
  final double v2;
  final double v3;
  final Color c1;
  final Color c2;
  final Color c3;
  final String centerText;
  final Color textColor;
  final Color mutedColor;

  _ThreeSegmentDonutPainter({
    required this.v1,
    required this.v2,
    required this.v3,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.centerText,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final total = v1 + v2 + v3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) {
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.grey.withValues(alpha: 0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      return;
    }

    final p1 = v1 / total;
    final p2 = v2 / total;
    final p3 = v3 / total;

    double startAngle = -pi / 2;

    if (p1 > 0) {
      final sweep = p1 * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = c1
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (p2 > 0) {
      final sweep = p2 * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = c2
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (p3 > 0) {
      final sweep = p3 * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = c3
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // Center Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(
            fontFamily: 'Book Antiqua',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2 + 5));

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'Total Cost',
        style: TextStyle(
            fontFamily: 'Trebuchet MS',
            fontSize: 8,
            color: mutedColor,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas,
        center - Offset(subPainter.width / 2, subPainter.height / 2 - 9));
  }

  @override
  bool shouldRepaint(covariant _ThreeSegmentDonutPainter oldDelegate) {
    return oldDelegate.v1 != v1 ||
        oldDelegate.v2 != v2 ||
        oldDelegate.v3 != v3 ||
        oldDelegate.textColor != textColor;
  }
}
