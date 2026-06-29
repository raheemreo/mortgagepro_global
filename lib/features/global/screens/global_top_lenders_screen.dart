// lib/features/global/screens/global_top_lenders_screen.dart
// Redesigned by Senior App Developer — June 2026

import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_tools_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../../services/analytics_service.dart';
import '../../../services/analytics/analytics_country.dart';
import '../../../services/ad_config.dart';
import '../../../services/ad_manager.dart';
import '../../../services/ad_free_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class _Lender {
  final int id;
  final String company;
  final String shortName;
  final String logo;
  final String website;
  final String type;
  final String category;
  final double rating;
  final double fixedRate;
  final double variableRate;
  final double floatingRate;
  final double armRate;
  final double helocRate;
  final double share;
  final int reviewCount;
  final String processingFee;
  final String maxLoanTenure;
  final String maxLtv;
  final String minimumCreditScore;
  final String minimumIncome;
  final String minimumDownPayment;

  // Features / Support
  final bool firstHomeBuyer;
  final bool balanceTransfer;
  final bool topUpLoan;
  final bool homeConstruction;
  final bool plotLoan;
  final bool homeImprovement;
  final bool homeExtension;
  final bool nriHomeLoan;
  final bool onlineApplication;
  final bool digitalDocumentUpload;
  final bool preApproval;
  final bool emiCalculator;
  final bool customerSupport24x7;
  final bool womenBorrowerConcession;
  final bool interestOnly;
  final bool ownerOccupier;
  final bool investmentProperty;
  final bool refinance;
  final bool offsetAccount;
  final bool redrawFacility;
  final bool brokerOnly;
  final bool fha;
  final bool va;
  final bool usda;
  final bool jumbo;
  final bool heloc;

  // Regional Availability
  final List<String> states;
  final List<String> provinces;
  final List<String> regions;
  final List<String> mortgageProducts;

  final Map<String, dynamic> raw;

  const _Lender({
    required this.id,
    required this.company,
    this.shortName = '',
    this.logo = '',
    this.website = '',
    this.type = '',
    this.category = '',
    this.rating = 0.0,
    this.fixedRate = 0.0,
    this.variableRate = 0.0,
    this.floatingRate = 0.0,
    this.armRate = 0.0,
    this.helocRate = 0.0,
    this.share = 0.0,
    this.reviewCount = 0,
    this.processingFee = '',
    this.maxLoanTenure = '',
    this.maxLtv = '',
    this.minimumCreditScore = '',
    this.minimumIncome = '',
    this.minimumDownPayment = '',
    this.firstHomeBuyer = false,
    this.balanceTransfer = false,
    this.topUpLoan = false,
    this.homeConstruction = false,
    this.plotLoan = false,
    this.homeImprovement = false,
    this.homeExtension = false,
    this.nriHomeLoan = false,
    this.onlineApplication = false,
    this.digitalDocumentUpload = false,
    this.preApproval = false,
    this.emiCalculator = false,
    this.customerSupport24x7 = false,
    this.womenBorrowerConcession = false,
    this.interestOnly = false,
    this.ownerOccupier = false,
    this.investmentProperty = false,
    this.refinance = false,
    this.offsetAccount = false,
    this.redrawFacility = false,
    this.brokerOnly = false,
    this.fha = false,
    this.va = false,
    this.usda = false,
    this.jumbo = false,
    this.heloc = false,
    this.states = const [],
    this.provinces = const [],
    this.regions = const [],
    this.mortgageProducts = const [],
    this.raw = const {},
  });

  double get rate => fixedRate > 0
      ? fixedRate
      : (variableRate > 0 ? variableRate : floatingRate);

  String get icon {
    final nameLower = company.toLowerCase();
    if (nameLower.contains('rocket')) {
      return '🚀';
    }
    if (nameLower.contains('orange') || nameLower.contains('tangerine')) {
      return '🍊';
    }
    if (nameLower.contains('kiwi')) {
      return '🥝';
    }
    if (nameLower.contains('nationwide')) {
      return '🏛️';
    }
    if (nameLower.contains('navy')) {
      return '⚓';
    }
    if (nameLower.contains('veteran')) {
      return '🎖️';
    }
    if (nameLower.contains('agriculture') || nameLower.contains('agricole')) {
      return '🌾';
    }
    if (nameLower.contains('sun')) {
      return '☀️';
    }
    if (nameLower.contains('lion') || nameLower.contains('ing')) {
      return '🦁';
    }
    return '🏦';
  }

  _Lender copyWith({double? share}) {
    return _Lender(
      id: id,
      company: company,
      shortName: shortName,
      logo: logo,
      website: website,
      type: type,
      category: category,
      rating: rating,
      fixedRate: fixedRate,
      variableRate: variableRate,
      floatingRate: floatingRate,
      armRate: armRate,
      helocRate: helocRate,
      share: share ?? this.share,
      reviewCount: reviewCount,
      processingFee: processingFee,
      maxLoanTenure: maxLoanTenure,
      maxLtv: maxLtv,
      minimumCreditScore: minimumCreditScore,
      minimumIncome: minimumIncome,
      minimumDownPayment: minimumDownPayment,
      firstHomeBuyer: firstHomeBuyer,
      balanceTransfer: balanceTransfer,
      topUpLoan: topUpLoan,
      homeConstruction: homeConstruction,
      plotLoan: plotLoan,
      homeImprovement: homeImprovement,
      homeExtension: homeExtension,
      nriHomeLoan: nriHomeLoan,
      onlineApplication: onlineApplication,
      digitalDocumentUpload: digitalDocumentUpload,
      preApproval: preApproval,
      emiCalculator: emiCalculator,
      customerSupport24x7: customerSupport24x7,
      womenBorrowerConcession: womenBorrowerConcession,
      interestOnly: interestOnly,
      ownerOccupier: ownerOccupier,
      investmentProperty: investmentProperty,
      refinance: refinance,
      offsetAccount: offsetAccount,
      redrawFacility: redrawFacility,
      brokerOnly: brokerOnly,
      fha: fha,
      va: va,
      usda: usda,
      jumbo: jumbo,
      heloc: heloc,
      states: states,
      provinces: provinces,
      regions: regions,
      mortgageProducts: mortgageProducts,
      raw: raw,
    );
  }

  factory _Lender.fromJson(Map<String, dynamic> json, int index) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll('%', '').replaceAll('+', '').trim();
      return double.tryParse(s) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      final s = v.toString().replaceAll(',', '').trim();
      return int.tryParse(s) ?? 0;
    }

    final company = json['company'] as String? ??
        json['company_name'] as String? ??
        json['name'] as String? ??
        '';
    final shortName = json['short_name'] as String? ?? company.split(' ').first;
    final logo = json['logo'] as String? ??
        json['logo_url'] as String? ??
        json['company_logo_url'] as String? ??
        '';
    final website =
        json['website'] as String? ?? json['official_website'] as String? ?? '';
    final type = json['type'] as String? ??
        json['lender_type'] as String? ??
        json['bank/lender_type'] as String? ??
        json['bank/hfc/nbfc_type'] as String? ??
        '';
    final category = json['category'] as String? ?? '';
    final rating =
        parseDouble(json['rating'] ?? json['customer_rating'] ?? json['stars']);

    // Rates
    final fixedRate = parseDouble(json['fixed_rate'] ??
        json['fixed_rate_30yr'] ??
        json['fixed_home_loan_rate'] ??
        json['fixed_mortgage_rate']);
    final variableRate = parseDouble(json['variable_rate'] ??
        json['variable_rate_5yr'] ??
        json['floating_rate'] ??
        json['floating_home_loan_rate'] ??
        json['variable_mortgage_rate'] ??
        json['variable/floating_rate']);
    final floatingRate =
        parseDouble(json['floating_rate'] ?? json['floating_home_loan_rate']);
    final armRate = parseDouble(
        json['arm_rate'] ?? json['tracker_rate'] ?? json['tracker_rate_range']);
    final helocRate = parseDouble(
        json['heloc_rate'] ?? json['heloc_rate_range'] ?? json['heloc_rate']);

    final reviewCount = parseInt(json['review_count'] ??
        json['reviews'] ??
        json['review_counts'] ??
        json['review_count_range']);
    final processingFee = json['processing_fee'] as String? ?? '';
    final maxLoanTenure = json['max_loan_tenure'] as String? ?? '';
    final maxLtv = json['max_ltv'] as String? ??
        json['maximum_ltv'] as String? ??
        json['loan_to_value'] as String? ??
        json['maximum_loan_to_value_(ltv)'] as String? ??
        '';

    final minimumCreditScore = json['minimum_credit_score']?.toString() ?? '';
    final minimumIncome = json['minimum_income']?.toString() ?? '';
    final minimumDownPayment = json['minimum_down_payment']?.toString() ??
        json['down_payment_requirement']?.toString() ??
        json['down_payment_requirements']?.toString() ??
        '';

    // Features
    final firstHomeBuyer = json['first_home_buyer'] as bool? ??
        json['first_time_buyer'] as bool? ??
        json['first_home_buyer_support'] as bool? ??
        json['first-time_buyer'] as bool? ??
        false;
    final balanceTransfer = json['balance_transfer'] as bool? ?? false;
    final topUpLoan = json['top_up_loan'] as bool? ?? false;
    final homeConstruction = json['home_construction'] as bool? ??
        json['home_construction_loan'] as bool? ??
        false;
    final plotLoan = json['plot_loan'] as bool? ?? false;
    final homeImprovement = json['home_improvement'] as bool? ??
        json['home_improvement_loan'] as bool? ??
        false;
    final homeExtension = json['home_extension'] as bool? ??
        json['home_extension_loan'] as bool? ??
        false;
    final nriHomeLoan = json['nri_home_loan'] as bool? ??
        json['nri_home_loans'] as bool? ??
        false;

    final onlineApplication = json['online_application'] as bool? ?? false;
    final digitalDocumentUpload = json['digital_document_upload'] as bool? ??
        json['digital_document'] as bool? ??
        false;
    final preApproval = json['pre_approval'] as bool? ?? false;
    final emiCalculator = json['emi_calculator'] as bool? ?? false;
    final customerSupport24x7 = json['customer_support_24x7'] as bool? ??
        json['24x7_customer_support'] as bool? ??
        json['24×7_customer_support'] as bool? ??
        (json['customer_support']?.toString().contains('24/7') ?? false);
    final womenBorrowerConcession =
        json['women_borrower_concession'] as bool? ??
            json['women_borrower_interest_concession'] as bool? ??
            false;

    final interestOnly = json['interest_only'] as bool? ??
        json['interest_only_loans'] as bool? ??
        json['interest_only_availability'] as bool? ??
        false;
    final ownerOccupier = json['owner_occupier'] as bool? ??
        json['owner_occupier_mortgages'] as bool? ??
        false;
    final investmentProperty = json['investment_property'] as bool? ??
        json['investment_property_loans'] as bool? ??
        json['investment_loans'] as bool? ??
        false;
    final refinance = json['refinance'] as bool? ??
        json['refinancing'] as bool? ??
        json['refinance_support'] as bool? ??
        false;
    final offsetAccount = json['offset_account'] as bool? ??
        json['offset_account_availability'] as bool? ??
        false;
    final redrawFacility = json['redraw_facility'] as bool? ?? false;
    final brokerOnly = json['broker_only'] as bool? ??
        json['broker_only_indicator'] as bool? ??
        false;

    final fha = json['fha'] as bool? ?? false;
    final va = json['va'] as bool? ?? false;
    final usda = json['usda'] as bool? ?? false;
    final jumbo = json['jumbo'] as bool? ?? false;
    final heloc = json['heloc'] as bool? ?? false;

    List<String> parseList(dynamic val) {
      if (val == null) return const [];
      if (val is List) return val.map((e) => e.toString()).toList();
      return const [];
    }

    final states = parseList(json['states'] ??
        json['states_available'] ??
        json['available_states'] ??
        json['available_states/territories']);
    final provinces = parseList(json['provinces']);
    final regions = parseList(json['regions'] ?? json['available_regions']);
    final mortgageProducts = parseList(
        json['mortgage_products'] ?? json['loan_types'] ?? json['products']);

    return _Lender(
      id: json['id'] as int? ?? index + 1,
      company: company,
      shortName: shortName,
      logo: logo,
      website: website,
      type: type,
      category: category,
      rating: rating,
      fixedRate: fixedRate,
      variableRate: variableRate,
      floatingRate: floatingRate,
      armRate: armRate,
      helocRate: helocRate,
      share: parseDouble(json['share']),
      reviewCount: reviewCount,
      processingFee: processingFee,
      maxLoanTenure: maxLoanTenure,
      maxLtv: maxLtv,
      minimumCreditScore: minimumCreditScore,
      minimumIncome: minimumIncome,
      minimumDownPayment: minimumDownPayment,
      firstHomeBuyer: firstHomeBuyer,
      balanceTransfer: balanceTransfer,
      topUpLoan: topUpLoan,
      homeConstruction: homeConstruction,
      plotLoan: plotLoan,
      homeImprovement: homeImprovement,
      homeExtension: homeExtension,
      nriHomeLoan: nriHomeLoan,
      onlineApplication: onlineApplication,
      digitalDocumentUpload: digitalDocumentUpload,
      preApproval: preApproval,
      emiCalculator: emiCalculator,
      customerSupport24x7: customerSupport24x7,
      womenBorrowerConcession: womenBorrowerConcession,
      interestOnly: interestOnly,
      ownerOccupier: ownerOccupier,
      investmentProperty: investmentProperty,
      refinance: refinance,
      offsetAccount: offsetAccount,
      redrawFacility: redrawFacility,
      brokerOnly: brokerOnly,
      fha: fha,
      va: va,
      usda: usda,
      jumbo: jumbo,
      heloc: heloc,
      states: states,
      provinces: provinces,
      regions: regions,
      mortgageProducts: mortgageProducts,
      raw: json,
    );
  }
}

class _CountryData {
  final String flag;
  final String name;
  final String rateLabel;
  final String currency;
  final String centralBank;
  final String benchmarkRate;
  final List<_Lender> lenders;

  const _CountryData({
    required this.flag,
    required this.name,
    required this.rateLabel,
    required this.lenders,
    this.currency = '',
    this.centralBank = '',
    this.benchmarkRate = '',
  });
}

enum _ListSectionType {
  marketOverview,
  topRankedLabel,
  topRankedCard,
  allLendersLabel,
  lenderCard,
  adSlot,
  rateChart,
  marketShare,
  statsSummary,
  bottomSpacer,
}

class _ListItem {
  final _ListSectionType type;
  final _Lender? lender;
  final int? index;
  _ListItem({required this.type, this.lender, this.index});
}

final Map<String, _CountryData> _staticData = {
  'us': const _CountryData(
    flag: '🇺🇸',
    name: 'United States',
    rateLabel: '30-Yr Fixed',
    currency: 'USD',
    centralBank: 'Federal Reserve',
    benchmarkRate: '5.33%',
    lenders: [
      _Lender(
          id: 1,
          company: 'Rocket Mortgage',
          rating: 4.8,
          fixedRate: 6.52,
          share: 8.4,
          reviewCount: 250000,
          type: 'Online Lender'),
      _Lender(
          id: 2,
          company: 'Chase Bank',
          rating: 4.6,
          fixedRate: 6.58,
          share: 4.8,
          reviewCount: 120000,
          type: 'National Bank'),
    ],
  ),
  'ca': const _CountryData(
    flag: '🇨🇦',
    name: 'Canada',
    rateLabel: '5-Yr Fixed',
    currency: 'CAD',
    centralBank: 'Bank of Canada',
    benchmarkRate: '3.75%',
    lenders: [
      _Lender(
          id: 1,
          company: 'Royal Bank (RBC)',
          rating: 4.8,
          fixedRate: 4.39,
          share: 22.1,
          type: 'Big 5 Bank'),
      _Lender(
          id: 2,
          company: 'TD Bank',
          rating: 4.7,
          fixedRate: 4.35,
          share: 19.4,
          type: 'Big 5 Bank'),
    ],
  ),
  'uk': const _CountryData(
    flag: '🇬🇧',
    name: 'United Kingdom',
    rateLabel: '2-Yr Fixed',
    currency: 'GBP',
    centralBank: 'Bank of England',
    benchmarkRate: '5.25%',
    lenders: [
      _Lender(
          id: 1,
          company: 'Halifax',
          rating: 4.8,
          fixedRate: 3.89,
          share: 17.8,
          type: 'High Street Bank'),
      _Lender(
          id: 2,
          company: 'Nationwide',
          rating: 4.9,
          fixedRate: 3.87,
          share: 15.4,
          type: 'Building Society'),
    ],
  ),
  'au': const _CountryData(
    flag: '🇦🇺',
    name: 'Australia',
    rateLabel: 'Variable P&I',
    currency: 'AUD',
    centralBank: 'Reserve Bank of Australia',
    benchmarkRate: '4.35%',
    lenders: [
      _Lender(
          id: 1,
          company: 'Commonwealth Bank',
          rating: 4.5,
          fixedRate: 6.09,
          share: 24.8,
          type: 'Big 4 Bank'),
      _Lender(
          id: 2,
          company: 'Westpac',
          rating: 4.4,
          fixedRate: 6.14,
          share: 20.1,
          type: 'Big 4 Bank'),
    ],
  ),
  'nz': const _CountryData(
    flag: '🇳🇿',
    name: 'New Zealand',
    rateLabel: '1-Yr Fixed',
    currency: 'NZD',
    centralBank: 'Reserve Bank of NZ',
    benchmarkRate: '5.50%',
    lenders: [
      _Lender(
          id: 1,
          company: 'ANZ New Zealand',
          rating: 4.5,
          fixedRate: 6.59,
          share: 30.2,
          type: 'Major Bank'),
      _Lender(
          id: 2,
          company: 'ASB Bank',
          rating: 4.6,
          fixedRate: 6.55,
          share: 23.1,
          type: 'Major Bank'),
    ],
  ),
  'eu': const _CountryData(
    flag: '🇪🇺',
    name: 'Europe',
    rateLabel: 'Avg Mortgage Rate',
    currency: 'EUR',
    centralBank: 'European Central Bank',
    benchmarkRate: '3.65%',
    lenders: [
      _Lender(
          id: 1,
          company: 'BNP Paribas',
          rating: 4.5,
          fixedRate: 3.65,
          share: 15.4,
          type: 'Major Eurozone Bank'),
      _Lender(
          id: 2,
          company: 'ING Group',
          rating: 4.7,
          fixedRate: 3.60,
          share: 10.8,
          type: 'Digital & Retail'),
    ],
  ),
  'in': const _CountryData(
    flag: '🇮🇳',
    name: 'India',
    rateLabel: 'Avg Home Loan Rate',
    currency: 'INR',
    centralBank: 'Reserve Bank of India',
    benchmarkRate: '6.50%',
    lenders: [
      _Lender(
          id: 1,
          company: 'SBI',
          rating: 4.5,
          fixedRate: 8.50,
          share: 26.4,
          type: 'Public Sector Bank'),
      _Lender(
          id: 2,
          company: 'HDFC Bank',
          rating: 4.7,
          fixedRate: 8.75,
          share: 22.1,
          type: 'Private Bank'),
    ],
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Firebase Storage Bucket
// ─────────────────────────────────────────────────────────────────────────────
const String _kBucket = 'mortgagepro-global.firebasestorage.app';

// ─────────────────────────────────────────────────────────────────────────────
// Auto-seeding from assets
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _seedStorageFile(String code) async {
  try {
    final jsonString =
        await rootBundle.loadString('Lenders/${code}_lenders.json');
    final data = utf8.encode(jsonString);

    await FirebaseStorage.instanceFor(bucket: _kBucket)
        .ref()
        .child('${code}_lenders.json')
        .putData(data, SettableMetadata(contentType: 'application/json'));
    debugPrint(
        '✅ Successfully seeded ${code}_lenders.json from local assets to Firebase Storage.');
  } catch (e) {
    debugPrint('⚠️ Failed to seed ${code}_lenders.json from local assets: $e');
  }
}

Future<_CountryData?> _fetchCountryFile(String code) async {
  try {
    final bytes = await FirebaseStorage.instanceFor(bucket: _kBucket)
        .ref()
        .child('${code}_lenders.json')
        .getData(2 * 1024 * 1024); // 2MB limit
    if (bytes == null || bytes.isEmpty) return null;

    final decodedString = utf8.decode(bytes);
    final v = json.decode(decodedString) as Map<String, dynamic>;
    final rawLenders = v['lenders'] ?? v['loan_companies'];
    if (rawLenders is! List) return null;

    final lenders = <_Lender>[];
    for (int i = 0; i < rawLenders.length; i++) {
      if (rawLenders[i] is Map<String, dynamic>) {
        lenders.add(_Lender.fromJson(rawLenders[i] as Map<String, dynamic>, i));
      }
    }

    // Proportional market share calculation if missing
    final totalReviews =
        lenders.fold<double>(0, (sum, l) => sum + l.reviewCount);
    for (int i = 0; i < lenders.length; i++) {
      if (lenders[i].share == 0.0) {
        double calculatedShare;
        if (totalReviews > 0) {
          calculatedShare = (lenders[i].reviewCount / totalReviews) * 75.0;
        } else {
          calculatedShare = max(3.0, 30.0 - (i * 3.5));
        }
        lenders[i] = lenders[i]
            .copyWith(share: double.parse(calculatedShare.toStringAsFixed(1)));
      }
    }

    return _CountryData(
      flag: v['flag'] as String? ??
          v['country']?.toString().substring(0, 2) ??
          '',
      name: v['name'] as String? ?? v['country'] as String? ?? '',
      rateLabel: v['rateLabel'] as String? ?? _getFallbackRateLabel(code),
      currency: v['currency'] as String? ?? 'USD',
      centralBank: v['centralBank'] as String? ?? _getFallbackCentralBank(code),
      benchmarkRate:
          v['benchmarkRate'] as String? ?? _getFallbackBenchmark(code),
      lenders: lenders,
    );
  } catch (e) {
    debugPrint('⚠️ Fetch failed for $code: $e');
    // Auto seed if not found
    if (e.toString().contains('object-not-found') ||
        e.toString().contains('does not exist')) {
      await _seedStorageFile(code);
    }
    return null;
  }
}

String _getFallbackRateLabel(String code) {
  switch (code) {
    case 'us':
      return '30-Yr Fixed';
    case 'ca':
      return '5-Yr Fixed';
    case 'uk':
      return '2-Yr Fixed';
    case 'au':
      return 'Variable Rate';
    case 'nz':
      return '1-Yr Fixed';
    case 'eu':
      return 'Avg Mortgage Rate';
    case 'in':
      return 'Home Loan Rate';
    default:
      return 'Mortgage Rate';
  }
}

String _getFallbackCentralBank(String code) {
  switch (code) {
    case 'us':
      return 'Federal Reserve';
    case 'ca':
      return 'Bank of Canada';
    case 'uk':
      return 'Bank of England';
    case 'au':
      return 'RBA';
    case 'nz':
      return 'RBNZ';
    case 'eu':
      return 'ECB';
    case 'in':
      return 'RBI';
    default:
      return 'Central Bank';
  }
}

String _getFallbackBenchmark(String code) {
  switch (code) {
    case 'us':
      return '5.33%';
    case 'ca':
      return '3.75%';
    case 'uk':
      return '5.25%';
    case 'au':
      return '4.35%';
    case 'nz':
      return '5.50%';
    case 'eu':
      return '3.65%';
    case 'in':
      return '6.50%';
    default:
      return '0.00%';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
class GlobalLendersNotifier extends StateNotifier<AsyncValue<Map<String, _CountryData>>> {
  GlobalLendersNotifier() : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    final localData = <String, _CountryData>{};
    for (final code in _countryOrder) {
      localData[code] = await _loadLocalCountryData(code);
    }
    state = AsyncValue.data(localData);

    // Fetch remote data in the background
    _fetchRemoteData(localData);
  }

  Future<_CountryData> _loadLocalCountryData(String code) async {
    try {
      final jsonString =
          await rootBundle.loadString('Lenders/${code}_lenders.json');
      final v = json.decode(jsonString) as Map<String, dynamic>;
      
      final rawLenders = v['lenders'] ?? v['loan_companies'];
      final lenders = <_Lender>[];
      if (rawLenders is List) {
        for (int i = 0; i < rawLenders.length; i++) {
          lenders.add(
              _Lender.fromJson(rawLenders[i] as Map<String, dynamic>, i));
        }
      }
      final totalReviews =
          lenders.fold<double>(0, (sum, l) => sum + l.reviewCount);
      for (int i = 0; i < lenders.length; i++) {
        if (lenders[i].share == 0.0) {
          double calculatedShare = totalReviews > 0
              ? (lenders[i].reviewCount / totalReviews) * 75.0
              : max(3.0, 30.0 - (i * 3.5));
          lenders[i] = lenders[i].copyWith(
              share: double.parse(calculatedShare.toStringAsFixed(1)));
        }
      }
      return _CountryData(
        flag: v['flag'] as String? ?? '',
        name: v['name'] as String? ?? v['country'] as String? ?? '',
        rateLabel: v['rateLabel'] as String? ?? _getFallbackRateLabel(code),
        currency: v['currency'] as String? ?? 'USD',
        centralBank:
            v['centralBank'] as String? ?? _getFallbackCentralBank(code),
        benchmarkRate:
            v['benchmarkRate'] as String? ?? _getFallbackBenchmark(code),
        lenders: lenders,
      );
    } catch (e) {
      debugPrint(
          '⚠️ Failed to load local fallback asset for $code: $e. Using static fallback.');
      return _staticData[code]!;
    }
  }

  Future<void> _fetchRemoteData(Map<String, _CountryData> currentData) async {
    final updatedData = Map<String, _CountryData>.from(currentData);
    bool hasUpdates = false;

    await Future.wait(_countryOrder.map((code) async {
      final remote = await _fetchCountryFile(code);
      if (remote != null) {
        updatedData[code] = remote;
        hasUpdates = true;
      }
    }));

    if (hasUpdates) {
      state = AsyncValue.data(updatedData);
    }
  }
}

final globalLendersProvider =
    StateNotifierProvider<GlobalLendersNotifier, AsyncValue<Map<String, _CountryData>>>((ref) {
  return GlobalLendersNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// Design Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0B1D3A);
const _kRoyal = Color(0xFF1A3A8F);
const _kBlue = Color(0xFF1B3F72);
const _kGold = Color(0xFFD97706);
const _kGoldLt = Color(0xFFFCD34D);
const _kRed = Color(0xFFB91C1C);
const _kTeal = Color(0xFF0D9488);
const _kGreen = Color(0xFF15803D);
const _kBg = Color(0xFFF0F4FF);
const _kMuted = Color(0xFF5B6E8F);
const _kBgDark = Color(0xFF070D1A);
const _kCardDk = Color(0xFF111827);

const List<Color> _kChartColors = [
  Color(0xFF1A3A8F),
  Color(0xFF0D9488),
  Color(0xFFD97706),
  Color(0xFFC0392B),
  Color(0xFF15803D),
  Color(0xFF3B82F6),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen Widget
// ─────────────────────────────────────────────────────────────────────────────
class GlobalTopLendersScreen extends ConsumerStatefulWidget {
  const GlobalTopLendersScreen({super.key});
  @override
  ConsumerState<GlobalTopLendersScreen> createState() => _State();
}

class _State extends ConsumerState<GlobalTopLendersScreen>
    with SingleTickerProviderStateMixin {
  String _sel = 'us';
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();


  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _switch(String code) {
    if (code == _sel) return;
    _animCtrl.reset();
    setState(() => _sel = code);
    _animCtrl.forward();
  }

  String _stars(double s) {
    final f = s.floor().clamp(0, 5);
    final h = (s - f) >= 0.5;
    return '★' * f + (h ? '½' : '') + '☆' * (5 - f - (h ? 1 : 0)).clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = dark ? _kBgDark : _kBg;
    final cardCol = dark ? _kCardDk : Colors.white;
    final navyCol = dark ? Colors.white : _kNavy;
    final mutedCol = dark ? const Color(0xFF94A3B8) : _kMuted;
    final borderCol =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);

    final async = ref.watch(globalLendersProvider);
    final saved = ref.watch(savedToolsProvider);
    final isSaved = saved.contains('global_top_lenders');

    return Scaffold(
      backgroundColor: bgCol,
      body: Column(
        children: [
          _Header(
              sel: _sel,
              onCountry: _switch,
              isSaved: isSaved,
              async: async,
              ref: ref),
          Expanded(
            child: async.when(
              loading: () => _Loading(),
              error: (err, stack) {
                debugPrint('Riverpod error: $err\n$stack');
                return Center(child: Text('Error loading data: $err'));
              },
              data: (map) => _buildBody(
                  map, bgCol, cardCol, navyCol, mutedCol, borderCol, dark),
            ),
          ),
          BottomNav(
            activeIndex: 3,
            activeColor:
                dark ? const Color(0xFFF97316) : const Color(0xFF7C2D12),
            countryIcon: '🌐',
            countryLabel: 'Global',
            countryRoute: '/global',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Map<String, _CountryData> map, Color bgCol, Color cardCol,
      Color navyCol, Color mutedCol, Color borderCol, bool dark) {
    final country = map[_sel]!;
    final byShare = country.lenders.isEmpty
        ? <_Lender>[]
        : (List<_Lender>.from(country.lenders)
          ..sort((a, b) => b.share.compareTo(a.share)));
    final byRate = country.lenders.isEmpty
        ? <_Lender>[]
        : (List<_Lender>.from(country.lenders)
          ..sort((a, b) => a.rate.compareTo(b.rate)));
    final top = byShare.isNotEmpty ? byShare.first : null;

    final listItems = <_ListItem>[];
    
    // 1. Market Overview
    listItems.add(_ListItem(type: _ListSectionType.marketOverview));
    
    // 2. Top Ranked Lender
    listItems.add(_ListItem(type: _ListSectionType.topRankedLabel));
    if (top != null) {
      listItems.add(_ListItem(type: _ListSectionType.topRankedCard, lender: top));
    }
    
    // 3. All Lenders Ranked Label
    listItems.add(_ListItem(type: _ListSectionType.allLendersLabel));
    
    // 4. Lender Cards & Ad Slots
    final adSlots = _calculateAdSlots(byRate.length);
    int lenderIndex = 0;
    int adCount = 0;
    
    while (lenderIndex < byRate.length) {
      listItems.add(_ListItem(
        type: _ListSectionType.lenderCard, 
        lender: byRate[lenderIndex], 
        index: lenderIndex
      ));
      
      lenderIndex++;
      
      if (adSlots.contains(lenderIndex) && adCount < 5) {
        listItems.add(_ListItem(type: _ListSectionType.adSlot, index: adCount));
        adCount++;
      }
    }
    
    // 5. Rate Chart
    if (byRate.isNotEmpty) {
      listItems.add(_ListItem(type: _ListSectionType.rateChart));
    }
    
    // 6. Market Share Donut
    if (byShare.isNotEmpty) {
      listItems.add(_ListItem(type: _ListSectionType.marketShare));
    }
    
    // 7. Stats Summary Card
    if (country.lenders.isNotEmpty) {
      listItems.add(_ListItem(type: _ListSectionType.statsSummary));
    }
    
    // 8. Bottom Spacer
    listItems.add(_ListItem(type: _ListSectionType.bottomSpacer));

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        key: PageStorageKey('global_lenders_list_$_sel'),
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
        itemCount: listItems.length,
        itemBuilder: (context, i) {
          final item = listItems[i];
          switch (item.type) {
            case _ListSectionType.marketOverview:
              return Padding(
                key: const ValueKey('market_overview'),
                padding: const EdgeInsets.only(bottom: 16),
                child: _MarketOverviewBar(
                    country: country, navyCol: navyCol, mutedCol: mutedCol),
              );
              
            case _ListSectionType.topRankedLabel:
              return Padding(
                key: const ValueKey('top_ranked_label'),
                padding: const EdgeInsets.only(bottom: 10),
                child: _SectionLabel(
                    label: 'Top Ranked Lender',
                    right: 'June 2026',
                    navyCol: navyCol,
                    mutedCol: mutedCol),
              );
              
            case _ListSectionType.topRankedCard:
              return Padding(
                key: ValueKey('top_leader_${item.lender!.id}'),
                padding: const EdgeInsets.only(bottom: 18),
                child: GestureDetector(
                  onTap: () {
                    AnalyticsService.instance.logLenderViewed(1);
                    _showLenderDetails(context, item.lender!, country, dark);
                  },
                  child: _LeaderCard(top: item.lender!, country: country, starsFn: _stars),
                ),
              );
              
            case _ListSectionType.allLendersLabel:
              return Padding(
                key: const ValueKey('all_lenders_label'),
                padding: const EdgeInsets.only(bottom: 10),
                child: _SectionLabel(
                    label: 'All Lenders Ranked',
                    right: 'By Rate →',
                    navyCol: navyCol,
                    mutedCol: mutedCol),
              );
              
            case _ListSectionType.lenderCard:
              final idx = item.index!;
              return Padding(
                key: ValueKey('lender_${item.lender!.id}'),
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    AnalyticsService.instance.logLenderViewed(idx + 1);
                    _showLenderDetails(context, item.lender!, country, dark);
                  },
                  child: _LenderCard(
                    lender: item.lender!,
                    rank: idx + 1,
                    country: country,
                    cardCol: cardCol,
                    navyCol: navyCol,
                    mutedCol: mutedCol,
                    borderCol: borderCol,
                    starsFn: _stars,
                  ),
                ),
              );
              
            case _ListSectionType.adSlot:
              final adIdx = item.index!;
              return _LenderListAdSlot(
                key: ValueKey('ad_slot_$adIdx'),
                country: _getAnalyticsCountry(country.name),
                slotIndex: adIdx,
                dark: dark,
              );
              
            case _ListSectionType.rateChart:
              return Padding(
                key: const ValueKey('rate_chart'),
                padding: const EdgeInsets.only(top: 6, bottom: 14),
                child: _RateBarChart(
                    lenders: byRate,
                    country: country,
                    cardCol: cardCol,
                    navyCol: navyCol,
                    mutedCol: mutedCol,
                    borderCol: borderCol,
                    bgCol: bgCol),
              );
              
            case _ListSectionType.marketShare:
              return Padding(
                key: const ValueKey('market_share'),
                padding: const EdgeInsets.only(bottom: 14),
                child: _MarketShareCard(
                    lenders: byShare,
                    cardCol: cardCol,
                    navyCol: navyCol,
                    mutedCol: mutedCol,
                    borderCol: borderCol,
                    bgCol: bgCol),
              );
              
            case _ListSectionType.statsSummary:
              return Padding(
                key: const ValueKey('stats_summary'),
                padding: const EdgeInsets.only(bottom: 14),
                child: _StatsSummaryCard(
                    lenders: country.lenders,
                    country: country,
                    cardCol: cardCol,
                    navyCol: navyCol,
                    mutedCol: mutedCol,
                    borderCol: borderCol),
              );
              
            case _ListSectionType.bottomSpacer:
              return const SizedBox(
                key: ValueKey('bottom_spacer'),
                height: 80,
              );
          }
        },
      ),
    );
  }

  void _showLenderDetails(
      BuildContext context, _Lender lender, _CountryData country, bool dark) {
    showModalBottomSheet(
      context: context,
      routeSettings: const RouteSettings(name: '/lender_details'),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LenderDetailsSheet(
          lender: lender, country: country, dark: dark, starsFn: _stars),
    );
  }

  List<int> _calculateAdSlots(int count) {
    if (count < 6) {
      return const [];
    }
    if (count <= 12) {
      return const [4];
    }
    if (count <= 24) {
      return const [4, 10];
    }
    if (count <= 40) {
      return const [4, 10, 18];
    }
    
    // For > 40 lenders, 1 ad per 9 cards, capped at 5 ads
    final slots = <int>[];
    int pos = 4;
    for (int i = 0; i < 5; i++) {
      slots.add(pos);
      pos += 9;
      if (pos >= count) {
        break;
      }
    }
    return slots;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Widget
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String sel;
  final void Function(String) onCountry;
  final bool isSaved;
  final AsyncValue<Map<String, _CountryData>> async;
  final WidgetRef ref;
  const _Header(
      {required this.sel,
      required this.onCountry,
      required this.isSaved,
      required this.async,
      required this.ref});

  @override
  Widget build(BuildContext context) {
    final isLive = async.hasValue && async.value != null;
    final loading = async.isLoading;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNavy, _kBlue, _kRed],
          stops: [0.0, 0.50, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Top Row
            Row(children: [
              _HdrBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop()),
              const SizedBox(width: 10),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Top Mortgage Lenders',
                      style: AppTextStyles.playfair(
                          size: 18,
                          color: Colors.white,
                          weight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 3),
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('7 Markets · June 2026',
                            style: AppTextStyles.dmSans(
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.50))),
                        const SizedBox(width: 6),
                        _LiveBadge(live: isLive, loading: loading),
                      ]),
                ]),
              ),
              const SizedBox(width: 10),
              _HdrBtn(
                icon: isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                active: isSaved,
                onTap: () async {
                  await ref
                      .read(savedToolsProvider.notifier)
                      .toggleFavorite('global_top_lenders');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isSaved
                        ? 'Removed from Saved Tools'
                        : 'Saved to Favourites!'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: _kNavy,
                  ));
                },
              ),
            ]),
            const SizedBox(height: 14),
            // Country tabs (USA, Canada, UK, Australia, New Zealand, Europe, India)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: _countryOrder.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final code = _countryOrder[i];
                  final d = _staticData[code]!;
                  final active = sel == code;
                  return GestureDetector(
                    onTap: () => onCountry(code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active
                            ? _kGold
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: active
                                ? _kGold
                                : Colors.white.withValues(alpha: 0.18)),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                    color: _kGold.withValues(alpha: 0.35),
                                    blurRadius: 10)
                              ]
                            : [],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(d.flag, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          code == 'us'
                              ? 'USA'
                              : code == 'ca'
                                  ? 'Canada'
                                  : code == 'uk'
                                      ? 'UK'
                                      : code == 'au'
                                          ? 'Australia'
                                          : code == 'nz'
                                              ? 'New Zealand'
                                              : code == 'eu'
                                                  ? 'Europe'
                                                  : 'India',
                          style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.w700,
                              color: active
                                  ? _kNavy
                                  : Colors.white.withValues(alpha: 0.85)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HdrBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _HdrBtn({required this.icon, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active
                ? _kGold.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: active
                    ? _kGold.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, color: active ? _kGold : Colors.white, size: 18),
        ),
      );
}

class _LiveBadge extends StatelessWidget {
  final bool live;
  final bool loading;
  const _LiveBadge({required this.live, required this.loading});
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Colors.white54));
    }
    if (!live) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.40)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Colors.greenAccent, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        const Text('Live',
            style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 8,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading & Section Label
// ─────────────────────────────────────────────────────────────────────────────
class _Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _kGold,
                  backgroundColor: _kRoyal.withValues(alpha: 0.15))),
          const SizedBox(height: 16),
          Text('Fetching live rates…',
              style: AppTextStyles.dmSans(size: 13, color: _kMuted)),
        ],
      ));
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String right;
  final Color navyCol;
  final Color mutedCol;
  const _SectionLabel(
      {required this.label,
      required this.right,
      required this.navyCol,
      required this.mutedCol});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w800,
                color: mutedCol,
                letterSpacing: 1.0)),
        Text(right,
            style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: dark ? const Color(0xFF60A5FA) : _kRoyal)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Market Overview Bar
// ─────────────────────────────────────────────────────────────────────────────
class _MarketOverviewBar extends StatelessWidget {
  final _CountryData country;
  final Color navyCol;
  final Color mutedCol;
  const _MarketOverviewBar(
      {required this.country, required this.navyCol, required this.mutedCol});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (country.centralBank.isNotEmpty)
        ('Central Bank', country.centralBank.split(' ').last),
      if (country.benchmarkRate.isNotEmpty)
        ('Benchmark Rate', country.benchmarkRate),
      ('Lenders Listed', '${country.lenders.length}'),
      if (country.currency.isNotEmpty) ('Currency', country.currency),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kNavy.withValues(alpha: 0.06),
            _kRoyal.withValues(alpha: 0.04)
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRoyal.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: items
            .take(4)
            .map((item) => Expanded(
                  child: Column(children: [
                    Text(item.$2,
                        style: AppTextStyles.dmSans(
                            size: 12, weight: FontWeight.w800, color: navyCol),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.$1,
                        style: AppTextStyles.dmSans(size: 8, color: mutedCol),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leader Card
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderCard extends StatelessWidget {
  final _Lender top;
  final _CountryData country;
  final String Function(double) starsFn;
  const _LeaderCard(
      {required this.top, required this.country, required this.starsFn});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kNavy, _kBlue],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _kNavy.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Stack(children: [
          Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGold.withValues(alpha: 0.18)),
              )),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Leading Lender by Market Share · ${country.flag} ${country.name}',
              style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Row(children: [
              _LenderLogo(
                  logoUrl: top.logo,
                  fallbackChar: top.company.substring(0, 1),
                  size: 48),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(top.company,
                        style: AppTextStyles.playfair(
                            size: 17,
                            color: Colors.white,
                            weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(top.type,
                        style: AppTextStyles.dmSans(
                            size: 10.5,
                            color: Colors.white.withValues(alpha: 0.55))),
                    const SizedBox(height: 2),
                    Text(
                        '${starsFn(top.rating)}  ${top.rating.toStringAsFixed(1)} (${top.reviewCount > 0 ? top.reviewCount.toString() : 'Popular'})',
                        style: AppTextStyles.dmSans(
                            size: 10, color: _kGold, weight: FontWeight.w600)),
                  ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _LcBox(
                  label: country.rateLabel,
                  value:
                      '${top.fixedRate > 0 ? top.fixedRate.toStringAsFixed(2) : top.variableRate.toStringAsFixed(2)}%'),
              const SizedBox(width: 8),
              _LcBox(
                  label: 'Market Share',
                  value: '${top.share.toStringAsFixed(1)}%'),
              const SizedBox(width: 8),
              _LcBox(
                  label: 'Rating', value: '${top.rating.toStringAsFixed(1)}/5'),
            ]),
            if (top.mortgageProducts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: top.mortgageProducts
                      .take(4)
                      .map((p) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Text(p,
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    weight: FontWeight.w600,
                                    color:
                                        Colors.white.withValues(alpha: 0.65))),
                          ))
                      .toList()),
            ],
          ]),
        ]),
      );
}

class _LcBox extends StatelessWidget {
  final String label;
  final String value;
  const _LcBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(label.toUpperCase(),
                style: AppTextStyles.dmSans(
                    size: 7.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.46),
                    letterSpacing: 0.4),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(value,
                style: AppTextStyles.dmSans(
                    size: 13, weight: FontWeight.w800, color: _kGoldLt),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Lender Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _LenderCard extends StatelessWidget {
  final _Lender lender;
  final int rank;
  final _CountryData country;
  final Color cardCol, navyCol, mutedCol, borderCol;
  final String Function(double) starsFn;
  const _LenderCard(
      {required this.lender,
      required this.rank,
      required this.country,
      required this.cardCol,
      required this.navyCol,
      required this.mutedCol,
      required this.borderCol,
      required this.starsFn});

  static const _rankGrads = [
    [Color(0xFFD97706), Color(0xFFB45309)], // Gold
    [Color(0xFF94A3B8), Color(0xFF64748B)], // Silver
    [Color(0xFFB45309), Color(0xFF92400E)], // Bronze
    [Color(0xFF1A3A8F), Color(0xFF0B1D3A)], // Default
  ];

  @override
  Widget build(BuildContext context) {
    final gi = rank <= 3 ? rank - 1 : 3;
    final grad = _rankGrads[gi];
    final displayRate =
        lender.fixedRate > 0 ? lender.fixedRate : lender.variableRate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad),
                borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Text('$rank',
                style: AppTextStyles.dmSans(
                    size: 13, weight: FontWeight.w800, color: Colors.white))),
        const SizedBox(width: 12),
        _LenderLogo(
            logoUrl: lender.logo,
            fallbackChar: lender.company.substring(0, 1),
            size: 36),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lender.company,
              style: AppTextStyles.dmSans(
                  size: 13, weight: FontWeight.w800, color: navyCol),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(lender.type,
              style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Text(starsFn(lender.rating),
                style: AppTextStyles.dmSans(
                    size: 9.5, color: _kGold, weight: FontWeight.w700)),
            const SizedBox(width: 3),
            Text(lender.rating.toStringAsFixed(1),
                style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
            if (lender.onlineApplication) ...[
              const SizedBox(width: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Online ✓',
                      style: AppTextStyles.dmSans(
                          size: 8, weight: FontWeight.w700, color: _kGreen))),
            ],
            if (lender.brokerOnly) ...[
              const SizedBox(width: 5),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Broker',
                      style: AppTextStyles.dmSans(
                          size: 8, weight: FontWeight.w700, color: _kGold))),
            ],
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${displayRate.toStringAsFixed(2)}%',
              style: AppTextStyles.dmSans(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF60A5FA)
                      : _kRoyal)),
          Text(country.rateLabel,
              style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(5)),
            child: Text('${lender.share.toStringAsFixed(1)}% share',
                style: AppTextStyles.dmSans(
                    size: 8.5, weight: FontWeight.w700, color: _kTeal)),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rate Bar Chart
// ─────────────────────────────────────────────────────────────────────────────
class _RateBarChart extends StatelessWidget {
  final List<_Lender> lenders;
  final _CountryData country;
  final Color cardCol, navyCol, mutedCol, borderCol, bgCol;
  const _RateBarChart(
      {required this.lenders,
      required this.country,
      required this.cardCol,
      required this.navyCol,
      required this.mutedCol,
      required this.borderCol,
      required this.bgCol});

  @override
  Widget build(BuildContext context) {
    final rates = lenders
        .map((l) => l.fixedRate > 0 ? l.fixedRate : l.variableRate)
        .toList();
    final minR = rates.reduce(min);
    final maxR = rates.reduce(max);
    final range = (maxR - minR).abs();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Rate Comparison',
              style: AppTextStyles.dmSans(
                  size: 12, weight: FontWeight.w800, color: navyCol)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6)),
            child: Text(country.rateLabel,
                style: AppTextStyles.dmSans(
                    size: 10, weight: FontWeight.w600, color: _kTeal)),
          ),
        ]),
        const SizedBox(height: 14),
        ...lenders.take(6).map((l) {
          final rate = l.fixedRate > 0 ? l.fixedRate : l.variableRate;
          final pct = range > 0.001
              ? ((rate - minR) / range * 100).clamp(5.0, 100.0) / 100.0
              : 1.0;
          final isLow = rate == minR;
          final barCol = isLow ? _kGreen : _kRoyal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                  width: 78,
                  child: Text(
                    l.shortName,
                    style: AppTextStyles.dmSans(
                        size: 9.5, weight: FontWeight.w700, color: mutedCol),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
              const SizedBox(width: 8),
              Expanded(
                  child: Stack(children: [
                Container(
                    height: 16,
                    decoration: BoxDecoration(
                        color: bgCol, borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                        color: barCol, borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 6),
                    child: Text('${rate.toStringAsFixed(2)}%',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
                if (isLow)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: _kGreen,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('BEST ↓',
                          style: TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Market Share Card
// ─────────────────────────────────────────────────────────────────────────────
class _MarketShareCard extends StatelessWidget {
  final List<_Lender> lenders;
  final Color cardCol, navyCol, mutedCol, borderCol, bgCol;
  const _MarketShareCard(
      {required this.lenders,
      required this.cardCol,
      required this.navyCol,
      required this.mutedCol,
      required this.borderCol,
      required this.bgCol});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardCol,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Market Share by Volume',
              style: AppTextStyles.dmSans(
                  size: 12, weight: FontWeight.w800, color: navyCol)),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                    painter: _DonutPainter(
                        lenders: lenders,
                        colors: _kChartColors,
                        trackCol: bgCol))),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    children: List.generate(min(6, lenders.length), (i) {
              final l = lenders[i];
              final col = _kChartColors[i % _kChartColors.length];
              return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                            color: col,
                            borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(l.company,
                            style: AppTextStyles.dmSans(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: navyCol),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('${l.share.toStringAsFixed(1)}%',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w600,
                            color: mutedCol)),
                  ]));
            }))),
          ]),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatsSummaryCard extends StatelessWidget {
  final List<_Lender> lenders;
  final _CountryData country;
  final Color cardCol, navyCol, mutedCol, borderCol;
  const _StatsSummaryCard(
      {required this.lenders,
      required this.country,
      required this.cardCol,
      required this.navyCol,
      required this.mutedCol,
      required this.borderCol});

  @override
  Widget build(BuildContext context) {
    if (lenders.isEmpty) return const SizedBox.shrink();
    final rates = lenders
        .map((l) => l.fixedRate > 0 ? l.fixedRate : l.variableRate)
        .toList();
    final avg = rates.reduce((a, b) => a + b) / rates.length;
    final best = rates.reduce(min);
    final avgRating =
        lenders.map((l) => l.rating).reduce((a, b) => a + b) / lenders.length;
    final onlineCount = lenders.where((l) => l.onlineApplication).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = [
      (
        'Avg Rate',
        '${avg.toStringAsFixed(2)}%',
        isDark ? const Color(0xFF60A5FA) : _kRoyal
      ),
      (
        'Best Rate',
        '${best.toStringAsFixed(2)}%',
        isDark ? const Color(0xFF4ADE80) : _kGreen
      ),
      (
        'Avg Rating',
        '${avgRating.toStringAsFixed(1)}/5',
        isDark ? const Color(0xFFFBBF24) : _kGold
      ),
      (
        'Online App',
        '$onlineCount/${lenders.length}',
        isDark ? const Color(0xFF2DD4BF) : _kTeal
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Market Statistics — ${country.flag} ${country.name}',
            style: AppTextStyles.dmSans(
                size: 12, weight: FontWeight.w800, color: navyCol)),
        const SizedBox(height: 12),
        Row(
            children: stats
                .map((s) => Expanded(
                        child: Column(children: [
                      Text(s.$2,
                          style: AppTextStyles.dmSans(
                              size: 14, weight: FontWeight.w800, color: s.$3),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 3),
                      Text(s.$1,
                          style:
                              AppTextStyles.dmSans(size: 8.5, color: mutedCol),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])))
                .toList()),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lender Details Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LenderDetailsSheet extends StatefulWidget {
  final _Lender lender;
  final _CountryData country;
  final bool dark;
  final String Function(double) starsFn;

  const _LenderDetailsSheet({
    required this.lender,
    required this.country,
    required this.dark,
    required this.starsFn,
  });

  @override
  State<_LenderDetailsSheet> createState() => _LenderDetailsSheetState();
}

class _LenderDetailsSheetState extends State<_LenderDetailsSheet> {
  double _loanAmount = 250000;
  double _loanTenure = 30;

  double get _interestRate {
    final r = widget.lender.fixedRate > 0
        ? widget.lender.fixedRate
        : widget.lender.variableRate;
    return r > 0 ? r : 5.0; // fallback
  }

  double get _monthlyEMI {
    final double monthlyRate = _interestRate / 12 / 100;
    final double months = _loanTenure * 12;
    if (monthlyRate == 0) return _loanAmount / months;
    return (_loanAmount * monthlyRate * pow(1 + monthlyRate, months)) /
        (pow(1 + monthlyRate, months) - 1);
  }

  @override
  void initState() {
    super.initState();
    // Adjust default loan amount by currency
    if (widget.country.currency == 'INR') {
      _loanAmount = 5000000; // 50 Lakhs
      _loanTenure = 20;
    } else if (widget.country.currency == 'EUR') {
      _loanAmount = 200000;
    }
  }

  Future<void> _showExternalWarningDialog(
      BuildContext context, String websiteUrl) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? _kCardDk : Colors.white;
    final textCol = dark ? Colors.white : _kNavy;
    final secondaryText = dark ? Colors.white70 : _kMuted;

    await showDialog(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/global_top_lenders_screen'),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: _kGold, size: 24),
              const SizedBox(width: 10),
              Text(
                'Security Notice',
                style: AppTextStyles.playfair(
                    size: 18, color: textCol, weight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are leaving the app to visit:',
                style: AppTextStyles.dmSans(size: 11, color: secondaryText),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : _kNavy.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : _kNavy.withValues(alpha: 0.05)),
                ),
                child: Text(
                  websiteUrl,
                  style: AppTextStyles.dmSans(
                      size: 11.5,
                      color: dark ? const Color(0xFF60A5FA) : _kRoyal,
                      weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'You are leaving Mortgage Pro Global and opening an external website. Always verify the website address before entering any personal or financial information. Third-party websites operate independently and have their own privacy policies, security measures, and terms of use.',
                style: AppTextStyles.dmSans(
                    size: 11.5, color: textCol, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.dmSans(
                    size: 13.5, color: secondaryText, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRoyal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Log external link click via Firebase Analytics
                await AnalyticsService.instance.logExternalLinkOpened();

                final url = Uri.parse(websiteUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                'Proceed',
                style: AppTextStyles.dmSans(
                    size: 13.5, color: Colors.white, weight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final bg = widget.dark ? _kCardDk : Colors.white;
    final textCol = widget.dark ? Colors.white : _kNavy;
    final secondaryText = widget.dark ? Colors.white70 : _kMuted;
    final dividerColor = widget.dark ? Colors.white12 : Colors.black12;

    // Themed container styles for better contrast and premium look
    final containerBg = widget.dark
        ? Colors.white.withValues(alpha: 0.05)
        : _kNavy.withValues(alpha: 0.03);
    final containerBorder = widget.dark
        ? Colors.white.withValues(alpha: 0.08)
        : _kNavy.withValues(alpha: 0.06);
    final royalCol = widget.dark ? const Color(0xFF60A5FA) : _kRoyal;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            // Handle
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: secondaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),

            // Header Info
            Row(children: [
              _LenderLogo(
                  logoUrl: widget.lender.logo,
                  fallbackChar: widget.lender.company.substring(0, 1),
                  size: 56),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.lender.company,
                        style: AppTextStyles.playfair(
                            size: 18, color: textCol, weight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(widget.lender.type,
                        style: AppTextStyles.dmSans(
                            size: 11, color: secondaryText)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(widget.starsFn(widget.lender.rating),
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: _kGold,
                              weight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(
                          '${widget.lender.rating} (${widget.lender.reviewCount > 0 ? widget.lender.reviewCount.toString() : 'Popular'})',
                          style: AppTextStyles.dmSans(
                              size: 11, color: secondaryText)),
                    ]),
                  ])),
              IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context)),
            ]),

            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 16),

                  // Rate Comparison Grid
                  _buildSectionTitle('Rate Details'),
                  _buildRateGrid(),
                  const SizedBox(height: 20),

                  // Interactive EMI Calculator
                  _buildSectionTitle('Interactive EMI Estimator'),
                  _buildEMICalculator(textCol, secondaryText, containerBg,
                      containerBorder, royalCol),
                  const SizedBox(height: 20),

                  // Eligibility & Requirements
                  _buildSectionTitle('Eligibility & Terms'),
                  _buildEligibilityDetails(secondaryText, textCol),
                  const SizedBox(height: 20),

                  // Feature Checklist Grid
                  _buildSectionTitle('Features & Support'),
                  _buildFeaturesChecklist(secondaryText, textCol),
                  const SizedBox(height: 20),

                  // Products & Regions
                  _buildSectionTitle('Availability'),
                  _buildAvailabilityInfo(secondaryText),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Action Button
            SafeArea(
              top: false,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRoyal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await _showExternalWarningDialog(
                      context, widget.lender.website);
                },
                child: Text('Visit Official Website ↗',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: _kTeal,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildRateGrid() {
    final rates = <(String, double)>[];
    if (widget.lender.fixedRate > 0) {
      rates.add(('Fixed Rate', widget.lender.fixedRate));
    }
    if (widget.lender.variableRate > 0) {
      rates.add(('Variable Rate', widget.lender.variableRate));
    }
    if (widget.lender.floatingRate > 0) {
      rates.add(('Floating Rate', widget.lender.floatingRate));
    }
    if (widget.lender.armRate > 0) {
      rates.add(('ARM / Tracker', widget.lender.armRate));
    }
    if (widget.lender.helocRate > 0) {
      rates.add(('HELOC Rate', widget.lender.helocRate));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2),
      itemCount: max(3, rates.length),
      itemBuilder: (context, i) {
        final containerBg = widget.dark
            ? Colors.white.withValues(alpha: 0.05)
            : _kNavy.withValues(alpha: 0.03);
        final royalCol = widget.dark ? const Color(0xFF60A5FA) : _kRoyal;
        final secondaryText = widget.dark ? Colors.white70 : _kMuted;

        if (i >= rates.length) {
          return Container(
            decoration: BoxDecoration(
                color: containerBg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text('N/A',
                style: AppTextStyles.dmSans(size: 11, color: secondaryText)),
          );
        }
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: royalCol.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: royalCol.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rates[i].$1,
                  style: AppTextStyles.dmSans(
                      size: 8.5, color: secondaryText, weight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${rates[i].$2.toStringAsFixed(2)}%',
                  style: AppTextStyles.dmSans(
                      size: 13, weight: FontWeight.w800, color: royalCol)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEMICalculator(Color textCol, Color secondaryText,
      Color containerBg, Color containerBorder, Color royalCol) {
    final currency = widget.country.currency;
    final isIndia = currency == 'INR';

    // Formatting helper
    String formatAmount(double amt) {
      if (isIndia) {
        if (amt >= 10000000) {
          return '₹ ${(amt / 10000000).toStringAsFixed(2)} Cr';
        }
        if (amt >= 100000) {
          return '₹ ${(amt / 100000).toStringAsFixed(2)} Lakh';
        }
        return '₹ $amt';
      }
      return '$currency ${amt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: containerBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Payment',
                  style: AppTextStyles.dmSans(size: 12, color: secondaryText)),
              Text(
                isIndia
                    ? '₹ ${_monthlyEMI.toStringAsFixed(0)} / mo'
                    : '$currency ${_monthlyEMI.toStringAsFixed(2)} / mo',
                style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.w800,
                    color: widget.dark ? const Color(0xFF4ADE80) : _kGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Loan Amount Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Amount',
                  style: AppTextStyles.dmSans(size: 11, color: secondaryText)),
              Text(formatAmount(_loanAmount),
                  style: AppTextStyles.dmSans(
                      size: 11, weight: FontWeight.bold, color: textCol)),
            ],
          ),
          Slider(
            value: _loanAmount,
            min: isIndia ? 500000 : 50000,
            max: isIndia ? 50000000 : 2000000,
            activeColor: royalCol,
            inactiveColor: royalCol.withValues(alpha: 0.15),
            onChanged: (val) => setState(() => _loanAmount = val),
          ),
          // Loan Tenure Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tenure',
                  style: AppTextStyles.dmSans(size: 11, color: secondaryText)),
              Text('${_loanTenure.toInt()} Years',
                  style: AppTextStyles.dmSans(
                      size: 11, weight: FontWeight.bold, color: textCol)),
            ],
          ),
          Slider(
            value: _loanTenure,
            min: 5,
            max: 30,
            divisions: 5,
            activeColor: royalCol,
            inactiveColor: royalCol.withValues(alpha: 0.15),
            onChanged: (val) => setState(() => _loanTenure = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityDetails(Color secondaryText, Color textCol) {
    final detailItems = [
      if (widget.lender.minimumCreditScore.isNotEmpty)
        ('Min Credit Score', widget.lender.minimumCreditScore),
      if (widget.lender.minimumDownPayment.isNotEmpty)
        ('Min Down Payment', widget.lender.minimumDownPayment),
      if (widget.lender.minimumIncome.isNotEmpty)
        ('Min Income Required', widget.lender.minimumIncome),
      if (widget.lender.maxLtv.isNotEmpty)
        ('Max LTV Support', widget.lender.maxLtv),
      if (widget.lender.processingFee.isNotEmpty)
        ('Processing Fee', widget.lender.processingFee),
      if (widget.lender.maxLoanTenure.isNotEmpty)
        ('Max Loan Tenure', widget.lender.maxLoanTenure),
    ];

    if (detailItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
            'Standard market criteria apply. Contact lender for eligibility details.',
            style: AppTextStyles.dmSans(size: 11, color: secondaryText)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.5),
      itemCount: detailItems.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.dark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(detailItems[i].$1,
                    style:
                        AppTextStyles.dmSans(size: 9.5, color: secondaryText),
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            Text(detailItems[i].$2,
                style: AppTextStyles.dmSans(
                    size: 10.5, weight: FontWeight.bold, color: textCol)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesChecklist(Color secondaryText, Color textCol) {
    final l = widget.lender;
    final checklist = [
      ('Online Application', l.onlineApplication),
      ('Digital Doc Upload', l.digitalDocumentUpload),
      ('Instant Pre-Approval', l.preApproval),
      ('Offset Account', l.offsetAccount),
      ('Redraw Facility', l.redrawFacility),
      ('First Home Buyer Support', l.firstHomeBuyer),
      ('Refinance Support', l.refinance),
      ('Interest-Only Option', l.interestOnly),
      if (l.womenBorrowerConcession)
        ('Women Borrower Concession', l.womenBorrowerConcession),
      if (l.balanceTransfer) ('Balance Transfer Support', l.balanceTransfer),
      if (l.topUpLoan) ('Top-up Loan Support', l.topUpLoan),
      if (l.nriHomeLoan) ('NRI Home Loan Support', l.nriHomeLoan),
      if (l.fha) ('FHA Loans', l.fha),
      if (l.va) ('VA Loans', l.va),
      if (l.usda) ('USDA Loans', l.usda),
      if (l.jumbo) ('Jumbo Loans', l.jumbo),
      if (l.heloc) ('HELOC Support', l.heloc),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 6,
          childAspectRatio: 4.5),
      itemCount: checklist.length,
      itemBuilder: (context, i) {
        final supported = checklist[i].$2;
        return Row(
          children: [
            Icon(
              supported ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: supported ? _kGreen : Colors.grey.withValues(alpha: 0.4),
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                checklist[i].$1,
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  color: supported
                      ? textCol
                      : secondaryText.withValues(alpha: 0.6),
                  weight: supported ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailabilityInfo(Color secondaryText) {
    final list = widget.lender.states.isNotEmpty
        ? widget.lender.states
        : widget.lender.provinces.isNotEmpty
            ? widget.lender.provinces
            : widget.lender.regions;

    final tealCol = widget.dark ? const Color(0xFF2DD4BF) : _kTeal;
    final royalCol = widget.dark ? const Color(0xFF60A5FA) : _kRoyal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (list.isNotEmpty) ...[
          Text('Regional Coverage',
              style: AppTextStyles.dmSans(
                  size: 9.5, weight: FontWeight.bold, color: secondaryText)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: list
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tealCol.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: tealCol.withValues(alpha: 0.15)),
                      ),
                      child: Text(item,
                          style: AppTextStyles.dmSans(
                              size: 9,
                              weight: FontWeight.w600,
                              color: tealCol)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        Text('Offered Loan Products',
            style: AppTextStyles.dmSans(
                size: 9.5, weight: FontWeight.bold, color: secondaryText)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.lender.mortgageProducts
              .map((p) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: royalCol.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: royalCol.withValues(alpha: 0.15)),
                    ),
                    child: Text(p,
                        style: AppTextStyles.dmSans(
                            size: 9, weight: FontWeight.w600, color: royalCol)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lender Logo Widget (Network Image with Circular Fallback)
// ─────────────────────────────────────────────────────────────────────────────
class _LenderLogo extends StatelessWidget {
  final String logoUrl;
  final String fallbackChar;
  final double size;

  const _LenderLogo({
    required this.logoUrl,
    required this.fallbackChar,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return _buildFallback();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: size / 2,
                height: size / 2,
                child: const CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(_kRoyal)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kRoyal, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackChar.toUpperCase(),
        style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut Painter
// ─────────────────────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<_Lender> lenders;
  final List<Color> colors;
  final Color trackCol;
  const _DonutPainter(
      {required this.lenders, required this.colors, required this.trackCol});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20);

    if (lenders.isEmpty) return;
    final total = lenders.fold<double>(0, (s, l) => s + l.share);
    if (total == 0) return;

    double start = -pi / 2;
    for (int i = 0; i < lenders.length; i++) {
      final sweep = (lenders[i].share / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.lenders != lenders || old.trackCol != trackCol;
}

const List<String> _countryOrder = ['us', 'ca', 'uk', 'au', 'nz', 'eu', 'in'];

String _getAnalyticsCountry(String name) {
  final n = name.toLowerCase();
  if (n.contains('united states') || n.contains('usa')) {
    return AnalyticsCountry.usa;
  }
  if (n.contains('canada')) {
    return AnalyticsCountry.canada;
  }
  if (n.contains('united kingdom') || n.contains('uk')) {
    return AnalyticsCountry.uk;
  }
  if (n.contains('australia')) {
    return AnalyticsCountry.australia;
  }
  if (n.contains('new zealand')) {
    return AnalyticsCountry.newZealand;
  }
  if (n.contains('europe')) {
    return AnalyticsCountry.europe;
  }
  if (n.contains('india')) {
    return AnalyticsCountry.india;
  }
  return AnalyticsCountry.usa;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lender List Ad Slot Widget (Self-Contained)
// ─────────────────────────────────────────────────────────────────────────────
class _LenderListAdSlot extends StatefulWidget {
  final String country;
  final int slotIndex;
  final bool dark;

  const _LenderListAdSlot({
    super.key,
    required this.country,
    required this.slotIndex,
    required this.dark,
  });

  @override
  State<_LenderListAdSlot> createState() => _LenderListAdSlotState();
}

class _LenderListAdSlotState extends State<_LenderListAdSlot>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  NativeAd? _ad;
  bool _isLoading = true;
  bool _isFailed = false;
  late AnimationController _shimmerController;

  @override
  bool get wantKeepAlive => true;

  String get _adUnitId => Platform.isIOS
      ? AdConfig.nativeAdUnitIos
      : AdConfig.nativeAdUnitAndroid;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadAd();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (AdFreeManager.instance.isActive || !AdManager.instance.canShowAds) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFailed = true;
        });
      }
      return;
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Log request event
    await AnalyticsService.instance.logEvent(
      name: 'ad_native_requested',
      parameters: {
        'country': widget.country,
        'slot_index': widget.slotIndex,
      },
    );

    _ad = NativeAd(
      adUnitId: _adUnitId,
      factoryId: 'lenderNativeAd',
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
      ),
      customOptions: {
        'isDark': widget.dark,
      },
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            // Log loaded event
            AnalyticsService.instance.logEvent(
              name: 'ad_native_loaded',
              parameters: {
                'country': widget.country,
                'slot_index': widget.slotIndex,
                'load_time_ms': elapsed,
              },
            );
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isFailed = true;
            });
            // Log failed event
            AnalyticsService.instance.logEvent(
              name: 'ad_native_failed',
              parameters: {
                'country': widget.country,
                'slot_index': widget.slotIndex,
                'error_code': error.code,
              },
            );
          }
        },
        onAdOpened: (ad) {
          AnalyticsService.instance.logEvent(
            name: 'ad_native_clicked',
            parameters: {
              'country': widget.country,
              'slot_index': widget.slotIndex,
            },
          );
        },
        onAdImpression: (ad) {
          AnalyticsService.instance.logEvent(
            name: 'ad_native_impression',
            parameters: {
              'country': widget.country,
              'slot_index': widget.slotIndex,
            },
          );
        },
      ),
    );

    try {
      await _ad!.load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isFailed) {
      return const SizedBox.shrink();
    }

    final borderCol = widget.dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
    final cardCol = widget.dark ? _kCardDk : Colors.white;

    return Semantics(
      label: 'Advertisement',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 268,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardCol,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isLoading
              ? AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.3 + (_shimmerController.value * 0.4),
                      child: Container(
                        color: widget.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        child: Center(
                          child: Icon(
                            Icons.ad_units_rounded,
                            color: widget.dark ? Colors.white30 : Colors.black26,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Stack(
                  children: [
                    AdWidget(ad: _ad!),
                    // WCAG AA compliant contrast ratio "Ad" badge (Gold background, white text)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706), // Gold
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ad',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
