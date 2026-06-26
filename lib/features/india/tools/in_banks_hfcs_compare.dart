// lib/features/india/tools/in_banks_hfcs_compare.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' show max, min, pow;
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INBanksHFCsCompare extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INBanksHFCsCompare({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INBanksHFCsCompare> createState() => _INBanksHFCsCompareState();
}

class _INBanksHFCsCompareState extends ConsumerState<INBanksHFCsCompare> {
  // Input states
  double _loanAmt = 5000000; // default 50 Lakhs
  double _tenure = 20; // default 20 Years
  String _loanType = 'salaried'; // salaried, selfemployed, nri
  String _cibilRange = '800'; // 800, 750, 700, 650

  // Directory filter state
  String _activeDirectoryFilter = 'all'; // all, psu, private, hfc, nbfc, low

  // Expansion states for comparison and directory items
  final Map<String, bool> _lenderDetailsExpanded = {};

  // Controllers
  late TextEditingController _loanAmtCtrl;
  late TextEditingController _tenureCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _comparisonResultsKey = GlobalKey();

  // Lender Database (India June 2025/2026 Rates)
  static final List<Map<String, dynamic>> _lenders = [
    {
      'id': 'sbi',
      'icon': '🏦',
      'name': 'SBI Home Loan',
      'shortName': 'SBI',
      'type': 'psu',
      'typeLabel': 'PSU Bank · Nationalised',
      'rate': {'salaried': 8.50, 'selfemployed': 8.60, 'nri': 8.65},
      'cibilAdj': {'800': 0.0, '750': 0.05, '700': 0.15, '650': 0.40},
      'processingFee': '₹10,000 flat',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL for floating rate',
      'foreclosure': 'NIL floating',
      'minIncome': '₹25,000/mo',
      'maxAge': 70,
      'features': [
        'Lowest floating rate (EBR linked)',
        'No prepayment penalty',
        'Max 30 yr tenure',
        'Balance transfer available',
        'Overdraft facility (Maxgain)'
      ],
      'tags': [
        {'class': 'tag-g', 'text': 'Best Rate 8.50%'},
        {'class': 'tag-b', 'text': 'Zero Prepayment'},
        {'class': 'tag-g', 'text': 'Govt. Bank'},
        {'class': 'tag-s', 'text': 'Maxgain OD'}
      ],
      'scoreProcess': 5,
      'scoreDigital': 3,
      'scoreSvc': 4,
      'scoreFlexibility': 5,
      'special': 'RBI EBR-linked floating. SBI Maxgain is a home loan with overdraft facility that helps save interest.',
      'notes': 'SBI offers the lowest rate in India for home loans. EBR (External Benchmark Rate) linked to repo rate. Rates for salaried: 8.50%–9.65% depending on CIBIL.',
      'rbiLinked': true,
      'avgRating': 4.3
    },
    {
      'id': 'hdfc',
      'icon': '🏛️',
      'name': 'HDFC Bank',
      'shortName': 'HDFC',
      'type': 'private',
      'typeLabel': 'Private Bank · HFC Merged',
      'rate': {'salaried': 8.70, 'selfemployed': 8.80, 'nri': 8.90},
      'cibilAdj': {'800': 0.0, '750': 0.05, '700': 0.20, '650': 0.50},
      'processingFee': '0.5% of loan',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL individual floating',
      'foreclosure': 'NIL floating individual',
      'minIncome': '₹30,000/mo',
      'maxAge': 70,
      'features': [
        'Adjustable rate linked to MCLR',
        'Step-up EMI option',
        'Quick disbursal 3-4 days',
        'Online application',
        'Flexibility for NRI borrowers'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '8.70% Floating'},
        {'class': 'tag-b', 'text': 'Step-up EMI'},
        {'class': 'tag-g', 'text': 'Fast Disbursal'},
        {'class': 'tag-m', 'text': 'NRI Friendly'}
      ],
      'scoreProcess': 5,
      'scoreDigital': 5,
      'scoreSvc': 4,
      'scoreFlexibility': 4,
      'special': 'HDFC Bank (post merger with HDFC Ltd) offers competitive floating rates with MCLR linkage.',
      'notes': 'Post-merger with HDFC Ltd. Rate for salaried: 8.70%–9.65%. Higher for self-employed. Processing fee 0.5% (negotiable). Strong digital platform.',
      'rbiLinked': true,
      'avgRating': 4.4
    },
    {
      'id': 'icici',
      'icon': '🏢',
      'name': 'ICICI Bank',
      'shortName': 'ICICI',
      'type': 'private',
      'typeLabel': 'Private Bank · Top 3',
      'rate': {'salaried': 8.75, 'selfemployed': 8.90, 'nri': 9.00},
      'cibilAdj': {'800': 0.0, '750': 0.05, '700': 0.20, '650': 0.55},
      'processingFee': '0.5%–1% of loan',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL individual floating',
      'foreclosure': 'NIL floating individual',
      'minIncome': '₹30,000/mo',
      'maxAge': 70,
      'features': [
        'iHome smart tracking app',
        'Flexible EMI options',
        'Insta Home Loan for existing',
        'Balance transfer',
        'Co-applicant benefit'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '8.75% Floating'},
        {'class': 'tag-b', 'text': 'iHome App'},
        {'class': 'tag-g', 'text': 'Insta App'},
        {'class': 'tag-o', 'text': 'Co-applicant'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 5,
      'scoreSvc': 4,
      'scoreFlexibility': 4,
      'special': 'ICICI iHome loan portal gives real-time tracking and instant eligibility for existing customers.',
      'notes': 'Rate 8.75%–9.70% for salaried. Higher for SE. Balance transfer attractive. Strong digital offering. Processing fee 0.50%–1%.',
      'rbiLinked': true,
      'avgRating': 4.2
    },
    {
      'id': 'axis',
      'icon': '⚡',
      'name': 'Axis Bank',
      'shortName': 'Axis',
      'type': 'private',
      'typeLabel': 'Private Bank',
      'rate': {'salaried': 8.75, 'selfemployed': 8.90, 'nri': 9.00},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.25, '650': 0.55},
      'processingFee': '1% (min ₹10k)',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL individual floating',
      'foreclosure': 'NIL individual',
      'minIncome': '₹30,000/mo',
      'maxAge': 70,
      'features': [
        'EMI waiver offer (every 3 yrs)',
        'QuickPay digital process',
        'Joint home loan benefit',
        'Flexible repayment',
        'Top-up loan available'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '8.75% Floating'},
        {'class': 'tag-b', 'text': 'EMI Waiver'},
        {'class': 'tag-g', 'text': 'Digital Process'},
        {'class': 'tag-o', 'text': 'Top-up'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 5,
      'scoreSvc': 3,
      'scoreFlexibility': 4,
      'special': 'Axis Bank "Shubh Aarambh" offers 12 EMI waivers over loan tenure (1 every 3 years).',
      'notes': 'Rate 8.75%–9.65%. Shubh Aarambh scheme: 12 EMI waivers over loan life. Processing fee 1% negotiable. Strong in metro branches.',
      'rbiLinked': true,
      'avgRating': 4.1
    },
    {
      'id': 'kotak',
      'icon': '🔷',
      'name': 'Kotak Mahindra Bank',
      'shortName': 'Kotak',
      'type': 'private',
      'typeLabel': 'Private Bank · New-Gen',
      'rate': {'salaried': 8.75, 'selfemployed': 8.90, 'nri': 9.05},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.30, '650': 0.60},
      'processingFee': '0.5%–1%',
      'maxLTV': 90,
      'maxTenure': 25,
      'prepayment': 'NIL floating individual',
      'foreclosure': 'NIL',
      'minIncome': '₹30,000/mo',
      'maxAge': 60,
      'features': [
        'One of fastest approvals',
        'Digital-first experience',
        'Attractive for NRI',
        'NRE account-linked',
        'Competitive rural rates'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '8.75% Floating'},
        {'class': 'tag-b', 'text': 'Fast Approval'},
        {'class': 'tag-m', 'text': 'NRI Linked'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 5,
      'scoreSvc': 4,
      'scoreFlexibility': 3,
      'special': 'Kotak offers some of the fastest disbursals in private banking segment.',
      'notes': 'Rate 8.75%–9.75%. Lower max tenure (25 yrs). Strong in digital and NRI segment. Processing fee 0.5%–1%.',
      'rbiLinked': true,
      'avgRating': 4.1
    },
    {
      'id': 'bob',
      'icon': '🏦',
      'name': 'Bank of Baroda',
      'shortName': 'BoB',
      'type': 'psu',
      'typeLabel': 'PSU Bank · Nationalised',
      'rate': {'salaried': 8.40, 'selfemployed': 8.55, 'nri': 8.60},
      'cibilAdj': {'800': 0.0, '750': 0.05, '700': 0.15, '650': 0.40},
      'processingFee': '0.25%–0.50%',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL floating',
      'foreclosure': 'NIL floating',
      'minIncome': '₹20,000/mo',
      'maxAge': 70,
      'features': [
        'Baroda Advantage Home Loan',
        'Credit-linked subsidy CLSS',
        'Low processing fee',
        'Repo rate linked (RLLR)',
        'Joint loan for women'
      ],
      'tags': [
        {'class': 'tag-g', 'text': '8.40% 2nd Lowest'},
        {'class': 'tag-b', 'text': 'CLSS Subsidy'},
        {'class': 'tag-g', 'text': 'Low Proc Fee'},
        {'class': 'tag-s', 'text': 'Repo Linked'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 3,
      'scoreSvc': 4,
      'scoreFlexibility': 4,
      'special': 'Bank of Baroda Repo Rate Linked Lending Rate (RLLR) offers one of the lowest rates for salaried.',
      'notes': 'Rate 8.40%–9.25%. Among cheapest PSU banks after SBI. RLLR-linked product. Good for PMAY and CLSS applicants. Processing fee low.',
      'rbiLinked': true,
      'avgRating': 4.0
    },
    {
      'id': 'lichfl',
      'icon': '🏗️',
      'name': 'LIC Housing Finance',
      'shortName': 'LIC HFL',
      'type': 'hfc',
      'typeLabel': 'HFC · LIC Subsidiary',
      'rate': {'salaried': 8.65, 'selfemployed': 8.75, 'nri': 8.85},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.25, '650': 0.50},
      'processingFee': '₹10k–₹15k flat',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL floating individual',
      'foreclosure': 'NIL individual floating',
      'minIncome': '₹25,000/mo',
      'maxAge': 70,
      'features': [
        'LIC brand reliability',
        'Good for LIC policyholders',
        'Branch presence pan-India',
        'Fixed rate option available',
        'Home improvement loan'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '8.65% HFC Rate'},
        {'class': 'tag-b', 'text': 'Fixed Available'},
        {'class': 'tag-g', 'text': 'Pan-India Branches'},
        {'class': 'tag-o', 'text': 'LIC Benefit'}
      ],
      'scoreProcess': 3,
      'scoreDigital': 3,
      'scoreSvc': 4,
      'scoreFlexibility': 4,
      'special': 'LIC HFL offers fixed rate option alongside floating — rare in the market.',
      'notes': 'Rate 8.65%–9.50%. LIC policyholders may get slight benefit. One of the largest HFCs. Fixed rate: 8.65% for up to 3 years, then floating. Pan-India presence.',
      'rbiLinked': false,
      'avgRating': 4.0
    },
    {
      'id': 'pnbhfl',
      'icon': '🌿',
      'name': 'PNB Housing Finance',
      'shortName': 'PNB HFL',
      'type': 'hfc',
      'typeLabel': 'HFC · PNB Subsidiary',
      'rate': {'salaried': 8.50, 'selfemployed': 8.75, 'nri': 9.00},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.30, '650': 0.60},
      'processingFee': '0.35% (min ₹2.5k)',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL individual floating',
      'foreclosure': 'NIL',
      'minIncome': '₹20,000/mo',
      'maxAge': 70,
      'features': [
        'Flexible eligibility norms',
        'Balance transfer with top-up',
        'Good for Tier 2/3 cities',
        'Roshni scheme for women',
        'Rural housing'
      ],
      'tags': [
        {'class': 'tag-g', 'text': '8.50% Competitive'},
        {'class': 'tag-b', 'text': 'Rural Housing'},
        {'class': 'tag-m', 'text': 'Women Scheme'},
        {'class': 'tag-o', 'text': 'Balance Transfer'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 3,
      'scoreSvc': 3,
      'scoreFlexibility': 4,
      'special': 'PNB HFL Roshni scheme offers attractive rates for women borrowers in semi-urban areas.',
      'notes': 'Rate 8.50%–10.50% (range wide, depends on profile). Low processing fee. Good for T2/T3 cities. Roshni for women and rural home buyers.',
      'rbiLinked': false,
      'avgRating': 3.9
    },
    {
      'id': 'bajajhfl',
      'icon': '🔶',
      'name': 'Bajaj Housing Finance',
      'shortName': 'Bajaj HFL',
      'type': 'nbfc',
      'typeLabel': 'NBFC-HFC · Bajaj Group',
      'rate': {'salaried': 8.50, 'selfemployed': 8.70, 'nri': 8.80},
      'cibilAdj': {'800': 0.0, '750': 0.05, '700': 0.20, '650': 0.55},
      'processingFee': 'Up to 4% of loan',
      'maxLTV': 90,
      'maxTenure': 32,
      'prepayment': 'NIL individual floating',
      'foreclosure': '2% if fixed',
      'minIncome': '₹25,000/mo',
      'maxAge': 75,
      'features': [
        'Max tenure 32 years',
        'Quick digital approval',
        'Doorstep service',
        'Flexible EMI',
        'High LTV'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '8.50% NBFC'},
        {'class': 'tag-b', 'text': '32-yr Tenure'},
        {'class': 'tag-g', 'text': 'Quick Approval'},
        {'class': 'tag-o', 'text': 'High LTV 90%'}
      ],
      'scoreProcess': 5,
      'scoreDigital': 5,
      'scoreSvc': 4,
      'scoreFlexibility': 5,
      'special': 'Bajaj HFL offers longest tenure (32 yrs) and fastest digital approval in India.',
      'notes': 'Rate 8.50%–15%. High processing fee up to 4%. Best for fast disbursal and longer tenure. Strong digital platform. NBFC — rates slightly less sensitive to RBI changes.',
      'rbiLinked': false,
      'avgRating': 4.3
    },
    {
      'id': 'tata',
      'icon': '🏢',
      'name': 'Tata Capital Housing',
      'shortName': 'Tata',
      'type': 'nbfc',
      'typeLabel': 'NBFC-HFC · Tata Group',
      'rate': {'salaried': 8.75, 'selfemployed': 8.90, 'nri': 9.10},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.25, '650': 0.60},
      'processingFee': '0.5%',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL individual floating',
      'foreclosure': 'NIL',
      'minIncome': '₹25,000/mo',
      'maxAge': 70,
      'features': [
        'Tata brand trust',
        'Good for professionals',
        'NRI-friendly process',
        'Transparent charges',
        'Minimal documentation'
      ],
      'tags': [
        {'class': 'tag-b', 'text': 'Tata Trust'},
        {'class': 'tag-s', 'text': '8.75% Floating'},
        {'class': 'tag-m', 'text': 'NRI Docs'},
        {'class': 'tag-g', 'text': 'Transparent Fee'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 4,
      'scoreSvc': 4,
      'scoreFlexibility': 3,
      'special': 'Tata Capital leverages Tata brand trust with clean, transparent fee structure.',
      'notes': 'Rate 8.75%–12%. Tata brand preferred by many for trust. Process streamlined. NRI documentation clear. 0.5% processing fee.',
      'rbiLinked': false,
      'avgRating': 4.1
    },
    {
      'id': 'canfin',
      'icon': '🌾',
      'name': 'Can Fin Homes',
      'shortName': 'Can Fin',
      'type': 'hfc',
      'typeLabel': 'HFC · Canara Bank Subsidiary',
      'rate': {'salaried': 8.50, 'selfemployed': 8.65, 'nri': 8.80},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.25, '650': 0.50},
      'processingFee': '0.50% (max ₹10k)',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL floating individual',
      'foreclosure': 'NIL',
      'minIncome': '₹20,000/mo',
      'maxAge': 70,
      'features': [
        'South India focused',
        'Low processing fee',
        'Affordable housing spec.',
        'PMAY-eligible',
        'Rural/semi-urban coverage'
      ],
      'tags': [
        {'class': 'tag-g', 'text': '8.50% HFC'},
        {'class': 'tag-b', 'text': 'Affordable Focus'},
        {'class': 'tag-o', 'text': 'South India'},
        {'class': 'tag-s', 'text': 'PMAY'}
      ],
      'scoreProcess': 3,
      'scoreDigital': 3,
      'scoreSvc': 4,
      'scoreFlexibility': 3,
      'special': 'Can Fin Homes specialises in affordable housing with PMAY and EWS/LIG focus.',
      'notes': 'Rate 8.50%–10.25%. Strong in south India. Very good for PMAY/CLSS category. Low processing fee. Canara Bank subsidiary.',
      'rbiLinked': false,
      'avgRating': 3.9
    },
    {
      'id': 'aavas',
      'icon': '🌻',
      'name': 'Aavas Financiers',
      'shortName': 'Aavas',
      'type': 'hfc',
      'typeLabel': 'HFC · Affordable Housing',
      'rate': {'salaried': 9.75, 'selfemployed': 10.50, 'nri': 0.0},
      'cibilAdj': {'800': 0.0, '750': 0.25, '700': 0.50, '650': 1.00},
      'processingFee': '1%–2%',
      'maxLTV': 90,
      'maxTenure': 20,
      'prepayment': 'NIL individual',
      'foreclosure': 'NIL',
      'minIncome': '₹10,000/mo',
      'maxAge': 65,
      'features': [
        'No formal income proof',
        'Informal sector benefit',
        'Tribal & rural focus',
        'Lower income acceptance',
        'Small ticket loans'
      ],
      'tags': [
        {'class': 'tag-o', 'text': 'Informal Sector'},
        {'class': 'tag-b', 'text': 'Rural Focus'},
        {'class': 'tag-m', 'text': 'Low Income OK'},
        {'class': 'tag-g', 'text': 'No Income Proof'}
      ],
      'scoreProcess': 3,
      'scoreDigital': 2,
      'scoreSvc': 4,
      'scoreFlexibility': 5,
      'special': 'Aavas serves India\'s bottom-of-pyramid — no formal income proof for daily wage workers.',
      'notes': 'Rates higher (9.75%–14%) but serves borrowers with informal income. Perfect for self-employed without ITR, small farmers, rural borrowers. NRI not served.',
      'rbiLinked': false,
      'avgRating': 4.0
    },
    {
      'id': 'union',
      'icon': '🌐',
      'name': 'Union Bank of India',
      'shortName': 'Union',
      'type': 'psu',
      'typeLabel': 'PSU Bank · Nationalised',
      'rate': {'salaried': 8.35, 'selfemployed': 8.50, 'nri': 8.60},
      'cibilAdj': {'800': 0.0, '750': 0.05, '700': 0.20, '650': 0.45},
      'processingFee': '0.50% (max ₹15k)',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL floating',
      'foreclosure': 'NIL',
      'minIncome': '₹20,000/mo',
      'maxAge': 70,
      'features': [
        'Union Nari Shakti (women bonus)',
        'RLLR linked',
        'Repo rate transparent',
        'PMAY CLSS eligible',
        'Merged Andhra/Corp Bank'
      ],
      'tags': [
        {'class': 'tag-g', 'text': '8.35% Lowest PSU'},
        {'class': 'tag-b', 'text': 'Women -0.05%'},
        {'class': 'tag-s', 'text': 'CLSS PMAY'},
        {'class': 'tag-o', 'text': 'Repo Linked'}
      ],
      'scoreProcess': 4,
      'scoreDigital': 3,
      'scoreSvc': 3,
      'scoreFlexibility': 4,
      'special': 'Union Bank "Nari Shakti" gives additional 0.05% concession to women borrowers.',
      'notes': 'One of lowest rates 8.35%–9.10%. Strong in PMAY/affordable segment. Union Nari Shakti: 5 bps extra off for women. Processing 0.50% max ₹15,000.',
      'rbiLinked': true,
      'avgRating': 3.8
    },
    {
      'id': 'iob',
      'icon': '🏦',
      'name': 'Indian Overseas Bank',
      'shortName': 'IOB',
      'type': 'psu',
      'typeLabel': 'PSU Bank · TN Headquartered',
      'rate': {'salaried': 8.40, 'selfemployed': 8.55, 'nri': 8.75},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.25, '650': 0.50},
      'processingFee': '0.50% (max ₹20k)',
      'maxLTV': 90,
      'maxTenure': 30,
      'prepayment': 'NIL floating',
      'foreclosure': 'NIL',
      'minIncome': '₹20,000/mo',
      'maxAge': 70,
      'features': [
        'Strong in South India',
        'IOB Rainbow Home Loan (women)',
        'Good for Tamil Nadu properties',
        'PMAY eligible',
        'Competitive PSU rate'
      ],
      'tags': [
        {'class': 'tag-g', 'text': '8.40% PSU'},
        {'class': 'tag-b', 'text': 'Rainbow for Women'},
        {'class': 'tag-o', 'text': 'South India'},
        {'class': 'tag-s', 'text': 'PMAY'}
      ],
      'scoreProcess': 3,
      'scoreDigital': 2,
      'scoreSvc': 3,
      'scoreFlexibility': 3,
      'special': 'IOB Rainbow Home Loan offers special rates and benefits for women property buyers.',
      'notes': 'Rate 8.40%–9.35%. Good for south India, especially Tamil Nadu. IOB Rainbow for women: 0.10% off. Processing 0.5% max ₹20,000.',
      'rbiLinked': true,
      'avgRating': 3.7
    },
    {
      'id': 'yes',
      'icon': '🔵',
      'name': 'Yes Bank',
      'shortName': 'Yes Bank',
      'type': 'private',
      'typeLabel': 'Private Bank · Rebuilt',
      'rate': {'salaried': 9.15, 'selfemployed': 9.40, 'nri': 9.50},
      'cibilAdj': {'800': 0.0, '750': 0.10, '700': 0.30, '650': 0.70},
      'processingFee': '1%–2%',
      'maxLTV': 85,
      'maxTenure': 25,
      'prepayment': 'NIL individual floating',
      'foreclosure': 'NIL',
      'minIncome': '₹40,000/mo',
      'maxAge': 65,
      'features': [
        'Revived under SBI consortium',
        'Higher min income req.',
        'Digital-only experience',
        'Balance transfer friendly',
        'NRI loans'
      ],
      'tags': [
        {'class': 'tag-s', 'text': '9.15% Private'},
        {'class': 'tag-b', 'text': 'Digital Portal'},
        {'class': 'tag-m', 'text': 'Balance Transfer'},
        {'class': 'tag-o', 'text': 'NRI'}
      ],
      'scoreProcess': 3,
      'scoreDigital': 4,
      'scoreSvc': 3,
      'scoreFlexibility': 3,
      'special': 'Yes Bank, now revived and stable, offers fully digital home loan process.',
      'notes': 'Rate 9.15%–11%. Higher than peers post-revival. Fully digital process. Higher min income ₹40K/mo. Max LTV 85%. Processing fee 1%–2%.',
      'rbiLinked': true,
      'avgRating': 3.6
    }
  ];

  static const List<String> _barColors = [
    '#FF6B00',
    '#0B1F48',
    '#046A38',
    '#F5A623',
    '#0D9488',
    '#9333EA',
    '#BE185D',
    '#334155',
    '#1D4ED8',
    '#B45309',
    '#065F46',
    '#C2410C',
    '#6D28D9',
    '#E05A00',
    '#0F766E'
  ];

  @override
  void initState() {
    super.initState();
    _loanAmtCtrl = TextEditingController(text: _loanAmt.toStringAsFixed(0));
    _tenureCtrl = TextEditingController(text: _tenure.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _loanAmtCtrl.dispose();
    _tenureCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateEmi(double principal, double annualRate, double tenureYears) {
    final double monthlyRate = annualRate / 12 / 100;
    final int months = (tenureYears * 12).toInt();
    if (monthlyRate == 0) return principal / months;
    return principal * monthlyRate * pow(1 + monthlyRate, months) / (pow(1 + monthlyRate, months) - 1);
  }

  Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtK(double n) {
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)}K';
    return '₹${n.toStringAsFixed(0)}';
  }

  void _saveComparisonSnapshot() async {
    final labelCtrl = TextEditingController(text: 'Home Loan Comparison Report');
    final results = _getComparisonResults();
    if (results.isEmpty) return;

    final best = results.first;
    final worst = results.last;
    final double saving = worst['totalInterest'] - best['totalInterest'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparative Report', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving report: ${_fmt(_loanAmt)} loan comparison (${results.length} lenders)',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Flat Loan Compare)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Home Loan Compare';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Banks vs HFCs Compare',
        inputs: {
          'loanAmt': _loanAmt,
          'tenure': _tenure,
          'loanType': _loanType == 'salaried' ? 0.0 : (_loanType == 'selfemployed' ? 1.0 : 2.0),
          'cibilRange': double.parse(_cibilRange),
        },
        results: {
          'bestRate': best['effectiveRate'],
          'bestEMI': best['emi'],
          'worstRate': worst['effectiveRate'],
          'worstEMI': worst['emi'],
          'maxSaving': saving,
          'lendersCount': results.length.toDouble(),
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Comparative report saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getComparisonResults() {
    // Filter and compute
    final filtered = _lenders.where((l) {
      final Map<String, dynamic> rates = l['rate'];
      final double baseRate = rates[_loanType] ?? rates['salaried'] ?? 0.0;
      return baseRate > 0;
    }).toList();

    final results = filtered.map((l) {
      final Map<String, dynamic> rates = l['rate'];
      final double baseRate = rates[_loanType] ?? rates['salaried'] ?? 0.0;
      final Map<String, dynamic> cibilAdjs = l['cibilAdj'];
      final double adj = cibilAdjs[_cibilRange] ?? 0.0;
      final double effectiveRate = baseRate + adj;

      final double emi = _calculateEmi(_loanAmt, effectiveRate, _tenure);
      final double totalPaid = emi * _tenure * 12;
      final double totalInterest = totalPaid - _loanAmt;

      return {
        ...l,
        'effectiveRate': effectiveRate,
        'emi': emi,
        'totalPaid': totalPaid,
        'totalInterest': totalInterest,
      };
    }).toList();

    // Sort by EMI ascending (best deals first)
    results.sort((a, b) => (a['emi'] as double).compareTo(b['emi'] as double));
    return results;
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _comparisonResultsKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final results = _getComparisonResults();
    final hasResults = results.isNotEmpty;

    final best = hasResults ? results.first : null;
    final worst = hasResults ? results.last : null;
    final double saving = (best != null && worst != null) ? (worst['totalInterest'] as double) - (best['totalInterest'] as double) : 0.0;


    // Filter the full lender list based on directory filter bar selection
    List<Map<String, dynamic>> displayedLendersInDirectory = _lenders;
    if (_activeDirectoryFilter == 'psu') {
      displayedLendersInDirectory = _lenders.where((l) => l['type'] == 'psu').toList();
    } else if (_activeDirectoryFilter == 'private') {
      displayedLendersInDirectory = _lenders.where((l) => l['type'] == 'private').toList();
    } else if (_activeDirectoryFilter == 'hfc') {
      displayedLendersInDirectory = _lenders.where((l) => l['type'] == 'hfc').toList();
    } else if (_activeDirectoryFilter == 'nbfc') {
      displayedLendersInDirectory = _lenders.where((l) => l['type'] == 'nbfc').toList();
    } else if (_activeDirectoryFilter == 'low') {
      displayedLendersInDirectory = [..._lenders];
      displayedLendersInDirectory.sort((a, b) {
        final Map<String, dynamic> rA = a['rate'];
        final Map<String, dynamic> rB = b['rate'];
        return (rA['salaried'] as double).compareTo(rB['salaried'] as double);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info (June 2025/2026 Live data)
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
              _infoCell('Best Rate', '8.50%', 'SBI', isGreen: true),
              _infoCell('Avg Rate', '8.76%', 'Jun 2025', isSaffron: true),
              _infoCell('Repo Rate', '6.25%', 'RBI Jun\'25'),
              _infoCell('Lenders', '15+', 'Live Data'),
            ],
          ),
        ),

        // Hero title setup banner
        Text('Loan Setup', style: AppTextStyles.sectionLabel(theme.getTextColor(context))),
        const SizedBox(height: 8),

        // Setup Parameters Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48),
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
              Text('भारत · HOME LOAN EMI COMPARISON · ALL LENDERS',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.5), weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Compare EMI & Total Cost Across Lenders',
                  style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Loan Amount input-slider sync
              _buildSyncedInputRow(
                label: 'LOAN AMOUNT',
                controller: _loanAmtCtrl,
                value: _loanAmt,
                min: 100000,
                max: 100000000, // 10 Cr max
                prefix: '₹ ',
                onChangedText: (val) => setState(() => _loanAmt = val),
                onChangedSlider: (val) => setState(() {
                  _loanAmt = val;
                  _loanAmtCtrl.text = val.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 12),

              // Tenure input-slider sync
              _buildSyncedInputRow(
                label: 'TENURE (YEARS)',
                controller: _tenureCtrl,
                value: _tenure,
                min: 1,
                max: 35,
                suffix: ' Yrs',
                onChangedText: (val) => setState(() => _tenure = val),
                onChangedSlider: (val) => setState(() {
                  _tenure = val;
                  _tenureCtrl.text = val.toStringAsFixed(0);
                }),
              ),
              const SizedBox(height: 12),

              // Loan Type Selection Dropdown
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOAN TYPE', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _loanType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1F48),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'salaried', child: Text('Salaried Employee')),
                                DropdownMenuItem(value: 'selfemployed', child: Text('Self-Employed')),
                                DropdownMenuItem(value: 'nri', child: Text('NRI Applicant')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _loanType = v);
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
                        Text('CIBIL SCORE RANGE', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cibilRange,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1F48),
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: '800', child: Text('800+ (Excellent)')),
                                DropdownMenuItem(value: '750', child: Text('750–799 (Very Good)')),
                                DropdownMenuItem(value: '700', child: Text('700–749 (Good)')),
                                DropdownMenuItem(value: '650', child: Text('650–699 (Average)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _cibilRange = v);
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    _scrollToResults();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: Text('⚡ Compare All Banks & HFCs', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Section Wrapper
        Column(
          key: _comparisonResultsKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasResults && best != null && worst != null) ...[
              // Winner Banner
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7), width: 1.5),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${best['name']} — Best Rate',
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A))),
                          const SizedBox(height: 2),
                          Text('Saves ${_fmt(saving)} vs ${worst['shortName']} over ${_tenure.toInt()} yrs',
                              style: AppTextStyles.dmSans(
                                  size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF046A38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${(best['effectiveRate'] as double).toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),

              // Summary Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 1.6,
                children: [
                  _summaryBox(
                    label: 'LOWEST EMI',
                    value: _fmtK(best['emi']),
                    subText: '${best['shortName']} · ${(best['effectiveRate'] as double).toStringAsFixed(2)}%',
                    isSaffron: false,
                    isGreen: true,
                  ),
                  _summaryBox(
                    label: 'MAX SAVING VS WORST',
                    value: _fmt(saving),
                    subText: 'Over full tenure',
                    isSaffron: true,
                    isGreen: false,
                  ),
                  _summaryBox(
                    label: 'HIGHEST EMI',
                    value: _fmtK(worst['emi']),
                    subText: '${worst['shortName']} · ${(worst['effectiveRate'] as double).toStringAsFixed(2)}%',
                    isSaffron: false,
                    isGreen: false,
                  ),
                  _summaryBox(
                    label: 'EMI RANGE',
                    value: '${_fmtK(worst['emi'] - best['emi'])}/mo',
                    subText: 'Monthly difference',
                    isSaffron: false,
                    isGreen: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visual Bar Chart Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.getBorderColor(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('EMI Comparison — Monthly', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        Text('${results.length} lenders', style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFFF6B00), weight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: results.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final r = entry.value;
                        final double emiVal = r['emi'];
                        final double maxEmiVal = worst['emi'];
                        final pct = maxEmiVal > 0 ? emiVal / maxEmiVal : 0.0;
                        final color = _parseHexColor(_barColors[idx % _barColors.length]);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(r['shortName'], style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: theme.getTextColor(context))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 20,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: theme.getBorderColor(context).withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: LayoutBuilder(builder: (ctx, constraints) {
                                    final width = constraints.maxWidth * pct;
                                    return Container(
                                      width: max(width, 50.0),
                                      height: double.infinity,
                                      padding: const EdgeInsets.only(left: 8),
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        '${(r['effectiveRate'] as double).toStringAsFixed(2)}%',
                                        style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w800),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  _fmtK(emiVal),
                                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
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
              const SizedBox(height: 16),

              // Side-by-Side Breakdown Card List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detailed Comparison', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
                  GestureDetector(
                    onTap: _saveComparisonSnapshot,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.save, color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text('Save Comparison', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Renders the side-by-side break-down rows
              Column(
                children: results.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final isLenderBest = idx == 0;
                  final double emiVal = r['emi'];
                  final double bestEMIVal = best['emi'];
                  final maxEmiVal = worst['emi'];
                  final emiPct = maxEmiVal > 0 ? emiVal / maxEmiVal : 0.0;
                  final isExpanded = _lenderDetailsExpanded[r['id']] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLenderBest
                            ? const Color(0xFF6EE7B7).withValues(alpha: 0.5)
                            : theme.getBorderColor(context),
                        width: isLenderBest ? 1.5 : 1.0,
                      ),
                      gradient: isLenderBest
                          ? LinearGradient(
                              colors: [const Color(0xFF046A38).withValues(alpha: 0.04), const Color(0xFF07543A).withValues(alpha: 0.02)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row details
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B00).withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              alignment: Alignment.center,
                              child: Text(r['icon'], style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'], style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                                  Text(r['typeLabel'], style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${(r['effectiveRate'] as double).toStringAsFixed(2)}%',
                                    style: AppTextStyles.dmSans(
                                        size: 16,
                                        weight: FontWeight.w800,
                                        color: isLenderBest ? const Color(0xFF046A38) : const Color(0xFFFF6B00))),
                                if (isLenderBest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF046A38),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('🏆 Best Rate', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white, weight: FontWeight.w800)),
                                  )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid Row
                        Row(
                          children: [
                            _statBox('Monthly EMI', _fmtK(emiVal), context),
                            _statBox('Total Interest', _fmt(r['totalInterest']), context),
                            _statBox('Total Paid', _fmt(r['totalPaid']), context),
                            _statBox('Proc. Fee', (r['processingFee'] as String).split(' ').first, context),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // EMI compared bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('EMI vs Best (${_fmtK(bestEMIVal)})', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                            Text(
                              isLenderBest ? '🏆 Best' : '+${_fmtK(emiVal - bestEMIVal)}',
                              style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w700,
                                color: isLenderBest ? const Color(0xFF046A38) : const Color(0xFFFF6B00),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.getBorderColor(context).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: LayoutBuilder(builder: (ctx, constraints) {
                            return Container(
                              width: constraints.maxWidth * emiPct,
                              decoration: BoxDecoration(
                                gradient: isLenderBest
                                    ? const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)])
                                    : const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFE05A00)]),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),

                        // Dot rating scores
                        _scoreRow('Process Speed', r['scoreProcess'], const Color(0xFFFF6B00), context),
                        _scoreRow('Digital Exp.', r['scoreDigital'], const Color(0xFF1A3A8F), context),
                        _scoreRow('Flexibility', r['scoreFlexibility'], const Color(0xFF046A38), context),

                        // Tags Row
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (r['tags'] as List).map((t) {
                            final tagClass = t['class'] as String;
                            final text = t['text'] as String;
                            Color bg = const Color(0xFFEFF6FF);
                            Color fg = const Color(0xFF1D4ED8);
                            if (tagClass == 'tag-g') {
                              bg = const Color(0xFFECFDF5);
                              fg = const Color(0xFF065F46);
                            } else if (tagClass == 'tag-s') {
                              bg = const Color(0xFFFFF3E0);
                              fg = const Color(0xFFE05A00);
                            } else if (tagClass == 'tag-o') {
                              bg = const Color(0xFFFFF7ED);
                              fg = const Color(0xFFC2410C);
                            } else if (tagClass == 'tag-m') {
                              bg = const Color(0xFFF5F3FF);
                              fg = const Color(0xFF6D28D9);
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                              child: Text(text, style: AppTextStyles.dmSans(size: 8, color: fg, weight: FontWeight.w700)),
                            );
                          }).toList(),
                        ),

                        // Collapsible detailed notes accordion
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _lenderDetailsExpanded[r['id']] = !isExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('📋 Details & Features',
                                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFF6B00), weight: FontWeight.w700)),
                                Icon(
                                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                  color: const Color(0xFFFF6B00),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (isExpanded) ...[
                          const SizedBox(height: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (r['features'] as List).map((f) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('✓ ', style: TextStyle(color: Color(0xFF046A38), fontSize: 10)),
                                    Expanded(
                                      child: Text(f as String,
                                          style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(r['notes'] as String,
                              style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), height: 1.5)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text('ℹ️ ', style: TextStyle(fontSize: 10)),
                                Expanded(
                                  child: Text(r['special'] as String,
                                      style: AppTextStyles.dmSans(size: 9, color: theme.getTextColor(context))),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 4,
                            children: [
                              _infoKeyValue('Max LTV:', '${r['maxLTV']}%', context),
                              _infoKeyValue('Max Tenure:', '${r['maxTenure']} yrs', context),
                              _infoKeyValue('Min Income:', r['minIncome'], context),
                              _infoKeyValue('Max Age:', '${r['maxAge']} yrs', context),
                              _infoKeyValue('Prepayment:', r['prepayment'], context),
                              _infoKeyValue('Foreclosure:', r['foreclosure'], context),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Filter / Sort All Lenders Directory
        Text('All Lenders Directory', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 8),

        // Horizontal filter bar chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All Lenders', 'all'),
              _buildFilterChip('PSU Banks', 'psu'),
              _buildFilterChip('Private Banks', 'private'),
              _buildFilterChip('HFCs', 'hfc'),
              _buildFilterChip('NBFC', 'nbfc'),
              _buildFilterChip('Lowest Rate', 'low'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Renders the sorted full lender cards list
        Column(
          children: displayedLendersInDirectory.map((l) {
            final Map<String, dynamic> rates = l['rate'];
            final isDirectoryLenderExpanded = _lenderDetailsExpanded['dir_${l['id']}'] ?? false;
            final isLowestOverall = rates['salaried'] == _lenders.map((x) => x['rate']['salaried'] as double).reduce(min);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                border: Border.all(color: theme.getBorderColor(context)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l['icon'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(l['name'],
                                    style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                                if (isLowestOverall) ...[
                                  const SizedBox(width: 4),
                                  const Text('🏆', style: TextStyle(fontSize: 10)),
                                ],
                              ],
                            ),
                            Text(l['typeLabel'], style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
                          ],
                        ),
                      ),
                      Text('${(rates['salaried'] as double).toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: const Color(0xFFFF6B00))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _directorySubItem('Salaried', '${(rates['salaried'] as double).toStringAsFixed(2)}%', context),
                      _directorySubItem('Self-Emp.', '${(rates['selfemployed'] as double).toStringAsFixed(2)}%', context),
                      _directorySubItem('NRI', rates['nri'] > 0 ? '${(rates['nri'] as double).toStringAsFixed(2)}%' : 'N/A', context),
                    ],
                  ),

                  // Collapsible View Details inside directory
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _lenderDetailsExpanded['dir_${l['id']}'] = !isDirectoryLenderExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ℹ️ View Details',
                              style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFFF6B00), weight: FontWeight.w700)),
                          Icon(
                            isDirectoryLenderExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: const Color(0xFFFF6B00),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isDirectoryLenderExpanded) ...[
                    const SizedBox(height: 6),
                    Text(l['notes'] as String,
                        style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), height: 1.45)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.getBorderColor(context).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Special: ${l['special']}',
                        style: AppTextStyles.dmSans(size: 8.5, color: theme.getTextColor(context)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 4,
                      children: [
                        _infoKeyValue('Processing Fee:', l['processingFee'] as String, context),
                        _infoKeyValue('Max LTV Options:', '${l['maxLTV']}%', context),
                        _infoKeyValue('Prepayments:', l['prepayment'] as String, context),
                        _infoKeyValue('Max Age Limits:', '${l['maxAge']} yrs', context),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
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
        Text(value, style: AppTextStyles.dmSans(size: 13.5, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white.withValues(alpha: 0.4))),
      ],
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
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w800)),
            Text('$prefix${_fmt(value)}$suffix',
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFFFFDEA0))),
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
            style: AppTextStyles.dmSans(size: 12.5, color: Colors.white, weight: FontWeight.w800),
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

  Widget _summaryBox({
    required String label,
    required String value,
    required String subText,
    required bool isSaffron,
    required bool isGreen,
  }) {
    final theme = widget.theme;
    Color borderCol = theme.getBorderColor(context);
    Color bgCol = theme.getCardColor(context);

    if (isSaffron) {
      borderCol = const Color(0xFFFF6B00).withValues(alpha: 0.25);
      bgCol = const Color(0xFFFF6B00).withValues(alpha: 0.04);
    } else if (isGreen) {
      borderCol = const Color(0xFF046A38).withValues(alpha: 0.25);
      bgCol = const Color(0xFF046A38).withValues(alpha: 0.04);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 16.5,
              weight: FontWeight.w800,
              color: isSaffron
                  ? const Color(0xFFFF6B00)
                  : isGreen
                      ? const Color(0xFF046A38)
                      : theme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(subText, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 7.5, color: widget.theme.getMutedColor(context), weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(String label, int score, Color fillColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(5, (index) {
              final isFilled = index < score;
              return Container(
                margin: const EdgeInsets.only(right: 3),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? fillColor : Colors.grey.withValues(alpha: 0.18),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _infoKeyValue(String label, String value, BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _activeDirectoryFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeDirectoryFilter = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFFFF6B00).withValues(alpha: 0.08),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFFFF6B00).withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFFFF6B00),
          ),
        ),
      ),
    );
  }

  Widget _directorySubItem(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
      ],
    );
  }
}
