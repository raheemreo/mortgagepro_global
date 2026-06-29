// lib/services/analytics/analytics_screen.dart

class ScreenInfo {
  final String screenName;
  final String screenClass;
  final String pageTitle;

  const ScreenInfo({
    required this.screenName,
    required this.screenClass,
    required this.pageTitle,
  });
}

/// Screen name vocabulary for Firebase Analytics.
///
/// All screenName parameters must come from these constants.
/// Never pass:
///   - Route paths ("/home", "/usa")
///   - Widget class names ("_HomeScreenState")
///   - URLs, query strings, or dynamic identifiers
///
/// Add a constant here when adding a new screen.
/// Update DATA COLLECTION NOTICE in AnalyticsService.
/// Update AnalyticsScreen.all to include the new value.
abstract final class AnalyticsScreen {
  static const String home        = 'home';
  static const String usa         = 'usa';
  static const String canada      = 'canada';
  static const String uk          = 'uk';
  static const String australia   = 'australia';
  static const String newZealand  = 'new_zealand';
  static const String europe      = 'europe';
  static const String india       = 'india';
  static const String settings    = 'settings';
  static const String resources   = 'resources';
  static const String propertyTax = 'property_tax';
  static const String saved       = 'saved';
  static const String about       = 'about';
  static const String globalTopLenders = 'global_top_lenders';

  /// Used for runtime validation in ScreenTimerMixin
  /// and ScrollDepthTracker. Update when adding
  /// new screen constants above.
  static const Set<String> all = {
    home, usa, canada, uk, australia, newZealand,
    europe, india, settings, resources, propertyTax,
    saved, about, globalTopLenders,
  };

  /// Single source of truth mapping route paths to screen info.
  static const Map<String, ScreenInfo> routeRegistry = {
    // Core routes
    '/': ScreenInfo(screenName: 'home_global', screenClass: 'HomeScreen', pageTitle: 'Global Home'),
    '/home': ScreenInfo(screenName: 'home_global', screenClass: 'HomeScreen', pageTitle: 'Global Home'),
    '/usa': ScreenInfo(screenName: 'lender_list_usa', screenClass: 'USAScreen', pageTitle: 'Top Lenders'),
    '/uk': ScreenInfo(screenName: 'lender_list_uk', screenClass: 'UKScreen', pageTitle: 'Top Lenders'),
    '/canada': ScreenInfo(screenName: 'lender_list_canada', screenClass: 'CanadaScreen', pageTitle: 'Top Lenders'),
    '/australia': ScreenInfo(screenName: 'lender_list_australia', screenClass: 'AustraliaScreen', pageTitle: 'Top Lenders'),
    '/newzealand': ScreenInfo(screenName: 'lender_list_nz', screenClass: 'NZScreen', pageTitle: 'Top Lenders'),
    '/europe': ScreenInfo(screenName: 'lender_list_europe', screenClass: 'EuropeScreen', pageTitle: 'Top Lenders'),
    '/india': ScreenInfo(screenName: 'lender_list_india', screenClass: 'IndiaScreen', pageTitle: 'Top Lenders'),
    '/global': ScreenInfo(screenName: 'lender_list_global', screenClass: 'GlobalScreen', pageTitle: 'Top Lenders'),
    '/global/top-lenders': ScreenInfo(screenName: 'lender_list_global_top', screenClass: 'GlobalTopLendersScreen', pageTitle: 'Top Lenders'),
    '/saved': ScreenInfo(screenName: 'saved', screenClass: 'SavedScreen', pageTitle: 'Saved'),
    '/settings': ScreenInfo(screenName: 'settings', screenClass: 'SettingsScreen', pageTitle: 'Settings'),
    '/notifications': ScreenInfo(screenName: 'notifications', screenClass: 'NotificationScreen', pageTitle: 'Notifications'),
    '/settings/feedback': ScreenInfo(screenName: 'feedback', screenClass: 'FeedbackScreen', pageTitle: 'Feedback'),
    '/tools': ScreenInfo(screenName: 'tools_global', screenClass: 'ToolsScreen', pageTitle: 'Global Tools'),
    '/lender_details': ScreenInfo(screenName: 'lender_details', screenClass: '_LenderDetailsSheet', pageTitle: 'Lender Details'),
    '/privacy_policy': ScreenInfo(screenName: 'privacy_policy', screenClass: 'PrivacyPolicyScreen', pageTitle: 'Privacy Policy'),
    '/terms_of_use': ScreenInfo(screenName: 'terms_of_use', screenClass: 'TermsOfUseScreen', pageTitle: 'Terms of Use'),
    '/about': ScreenInfo(screenName: 'about', screenClass: 'AboutScreen', pageTitle: 'About'),
    '/disclaimer': ScreenInfo(screenName: 'disclaimer', screenClass: 'DisclaimerScreen', pageTitle: 'Disclaimer'),
    '/support': ScreenInfo(screenName: 'support', screenClass: 'SupportScreen', pageTitle: 'Support'),
    '/onboarding': ScreenInfo(screenName: 'onboarding', screenClass: 'OnboardingScreen', pageTitle: 'Onboarding'),
    '/consent_form': ScreenInfo(screenName: 'consent_form', screenClass: 'ConsentFormScreen', pageTitle: 'Consent Form'),
    
    // USA specific articles/sub-screens
    '/usa/property-tax-by-state': ScreenInfo(screenName: 'home_prices_region_tax_usa', screenClass: 'USAPropertyTaxByStateScreen', pageTitle: 'Property Tax by State'),
    '/usa/fed-funds-rate': ScreenInfo(screenName: 'central_bank_rates_fed_usa', screenClass: 'USAFedFundsRateScreen', pageTitle: 'Central Bank Rates'),
    '/usa/rate-trends': ScreenInfo(screenName: 'mortgage_rates_trends_usa', screenClass: 'USARateTrendsScreen', pageTitle: 'Mortgage Rates'),
    '/usa/first-time-homebuyer': ScreenInfo(screenName: 'onboarding_first_buyer_usa', screenClass: 'USAFirstTimeHomebuyerScreen', pageTitle: 'First-Time Homebuyer'),
    '/usa/va-benefits': ScreenInfo(screenName: 'calc_va_benefits_usa', screenClass: 'USAVaBenefitsScreen', pageTitle: 'VA Benefits'),
    '/usa/retirement-withdrawal': ScreenInfo(screenName: 'calc_retirement_withdrawal_usa', screenClass: 'USARetirementWithdrawalScreen', pageTitle: 'Retirement Withdrawal'),
    '/usa/usda-rural': ScreenInfo(screenName: 'calc_usda_rural_usa', screenClass: 'USAUsdaRuralDevelopmentScreen', pageTitle: 'USDA Rural Development'),
    '/usa/usda-eligibility-map': ScreenInfo(screenName: 'calc_usda_eligibility_map_usa', screenClass: 'USAUsdaEligibilityMapScreen', pageTitle: 'USDA Eligibility Map'),
    '/usa/usda-502-direct-vs-guaranteed': ScreenInfo(screenName: 'calc_usda_502_direct_vs_guaranteed_usa', screenClass: 'USAUsda502DirectVsGuaranteedScreen', pageTitle: 'USDA 502 Direct vs Guaranteed'),
    '/usa/usda-2025-income-limits': ScreenInfo(screenName: 'calc_usda_2025_income_limits_usa', screenClass: 'USAUsda2025IncomeLimitsScreen', pageTitle: 'USDA Income Limits'),
    '/usa/usda-streamline-refinance': ScreenInfo(screenName: 'calc_usda_streamline_refinance_usa', screenClass: 'USAUsdaStreamlineRefinanceScreen', pageTitle: 'USDA Streamline Refinance'),
    '/usa/fha-203k': ScreenInfo(screenName: 'calc_fha_203k_rehab_usa', screenClass: 'USAFha203kRehabLoanScreen', pageTitle: 'FHA 203k Rehab'),
    '/usa/one-close-vs-two-close': ScreenInfo(screenName: 'calc_one_close_vs_two_close_usa', screenClass: 'USAOneCloseVsTwoCloseScreen', pageTitle: 'One-Close vs Two-Close'),
    '/usa/builder-requirements': ScreenInfo(screenName: 'calc_builder_requirements_usa', screenClass: 'USABuilderRequirementsScreen', pageTitle: 'Builder Requirements'),
    '/usa/top-construction-lenders': ScreenInfo(screenName: 'calc_top_construction_lenders_usa', screenClass: 'USATopConstructionLendersScreen', pageTitle: 'Top Construction Lenders'),
    '/usa/fha-203k-alternative': ScreenInfo(screenName: 'calc_fha_203k_alternative_usa', screenClass: 'USAFha203kAlternativeScreen', pageTitle: 'FHA 203k Alternative'),
    '/usa/fha-loan-limits': ScreenInfo(screenName: 'calc_fha_loan_limits_usa', screenClass: 'USAFhaLoanLimitsScreen', pageTitle: 'FHA Loan Limits'),
    '/usa/fha-credit-score-requirements': ScreenInfo(screenName: 'calc_fha_credit_score_requirements_usa', screenClass: 'USAFhaCreditScoreRequirementsScreen', pageTitle: 'FHA Credit Score'),
    '/usa/fha-mip-cancellation-rules': ScreenInfo(screenName: 'calc_fha_mip_cancellation_rules_usa', screenClass: 'USAFhaMipCancellationRulesScreen', pageTitle: 'FHA MIP Cancellation'),
    '/usa/fha-property-standards': ScreenInfo(screenName: 'calc_fha_property_standards_usa', screenClass: 'USAFhaPropertyStandardsScreen', pageTitle: 'FHA Property Standards'),
    '/usa/jumbo-lenders': ScreenInfo(screenName: 'calc_jumbo_lenders_usa', screenClass: 'USAJumboTopLendersScreen', pageTitle: 'Jumbo Lenders'),
    '/usa/jumbo-documentation': ScreenInfo(screenName: 'calc_jumbo_documentation_usa', screenClass: 'USAJumboDocumentationScreen', pageTitle: 'Jumbo Documentation'),
    '/usa/jumbo-arm': ScreenInfo(screenName: 'calc_jumbo_arm_options_usa', screenClass: 'USAJumboArmOptionsScreen', pageTitle: 'Jumbo ARM Options'),
    '/usa/jumbo-vs-conforming': ScreenInfo(screenName: 'calc_jumbo_vs_conforming_usa', screenClass: 'USAJumboVsConformingScreen', pageTitle: 'Jumbo vs Conforming'),
    '/usa/va-coe': ScreenInfo(screenName: 'calc_va_coe_usa', screenClass: 'USAVaCoeScreen', pageTitle: 'VA COE'),
    '/usa/va-entitlement-limits': ScreenInfo(screenName: 'calc_va_entitlement_limits_usa', screenClass: 'USAVaEntitlementLimitsScreen', pageTitle: 'VA Entitlement Limits'),
    '/usa/va-surviving-spouse': ScreenInfo(screenName: 'calc_va_surviving_spouse_usa', screenClass: 'USAVaSurvivingSpouseScreen', pageTitle: 'VA Surviving Spouse'),
    '/usa/va-irrrl': ScreenInfo(screenName: 'calc_va_irrrl_refinance_usa', screenClass: 'USAVaIrrrlRefinanceScreen', pageTitle: 'VA IRRRL'),
    '/usa/arm-vs-fixed-breakeven': ScreenInfo(screenName: 'calc_arm_vs_fixed_breakeven_usa', screenClass: 'USAArmVsFixedBreakevenScreen', pageTitle: 'ARM vs Fixed Breakeven'),
    '/usa/sofr-history': ScreenInfo(screenName: 'mortgage_rates_sofr_usa', screenClass: 'USASofrRateHistoryScreen', pageTitle: 'SOFR History'),
    '/usa/refinance-arm': ScreenInfo(screenName: 'calc_refinance_arm_usa', screenClass: 'USARefinancingArmScreen', pageTitle: 'Refinancing ARM'),
    '/usa/arm-risk-factors': ScreenInfo(screenName: 'calc_arm_risk_factors_usa', screenClass: 'USAArmRiskFactorsScreen', pageTitle: 'ARM Risk Factors'),
    '/usa/ai-advisor': ScreenInfo(screenName: 'calc_ai_advisor_usa', screenClass: 'USAAIMortgageAdvisorScreen', pageTitle: 'AI Advisor'),
    '/usa/fred-rate-history': ScreenInfo(screenName: 'mortgage_rates_fred_usa', screenClass: 'USAFredRateHistoryScreen', pageTitle: 'FRED Rate History'),
    '/usa/fedwatch': ScreenInfo(screenName: 'central_bank_rates_fedwatch_usa', screenClass: 'USAFedWatchScreen', pageTitle: 'FedWatch'),
    '/usa/yield-curve': ScreenInfo(screenName: 'central_bank_rates_yield_usa', screenClass: 'USAYieldCurveScreen', pageTitle: 'Yield Curve'),
    '/usa/cpi-vs-fed-rate': ScreenInfo(screenName: 'central_bank_rates_cpi_usa', screenClass: 'USACpiVsFedRateScreen', pageTitle: 'CPI vs Fed Rate'),
    '/usa/home-price-index': ScreenInfo(screenName: 'home_prices_region_hpi_usa', screenClass: 'USAHomePriceIndexScreen', pageTitle: 'Home Price Index'),
    '/usa/median-home-prices': ScreenInfo(screenName: 'home_prices_region_median_usa', screenClass: 'USAMedianHomePricesStateScreen', pageTitle: 'Median Home Prices'),
    '/usa/top-lenders': ScreenInfo(screenName: 'lender_list_top_usa', screenClass: 'USATopLendersScreen', pageTitle: 'Top Lenders'),
    '/usa/prequal-guide': ScreenInfo(screenName: 'onboarding_prequal_usa', screenClass: 'USAMortgagePrequalGuideScreen', pageTitle: 'Prequal Guide'),
    '/usa/emergency-fund': ScreenInfo(screenName: 'calc_emergency_fund_usa', screenClass: 'USAEmergencyFundScreen', pageTitle: 'Emergency Fund'),
    '/usa/home-maintenance-budget': ScreenInfo(screenName: 'calc_home_maintenance_usa', screenClass: 'USAHomeMaintenanceBudgetScreen', pageTitle: 'Home Maintenance Budget'),
    '/usa/fico-better-rate': ScreenInfo(screenName: 'calc_fico_better_rate_usa', screenClass: 'USAFicoBetterRateScreen', pageTitle: 'FICO Better Rate'),
    '/usa/hoa-what-fees-cover': ScreenInfo(screenName: 'calc_hoa_fees_cover_usa', screenClass: 'USAHoaWhatFeesCoverScreen', pageTitle: 'HOA What Fees Cover'),
    '/usa/hoa-reserve-fund-health': ScreenInfo(screenName: 'calc_hoa_reserve_health_usa', screenClass: 'USAHoaReserveFundHealthScreen', pageTitle: 'HOA Reserve Fund Health'),
    '/usa/hoa-fee-increases': ScreenInfo(screenName: 'calc_hoa_fee_increases_usa', screenClass: 'USAHoaFeeIncreasesScreen', pageTitle: 'HOA Fee Increases'),
    '/usa/hoa-lender-treatment': ScreenInfo(screenName: 'calc_hoa_lender_treatment_usa', screenClass: 'USAHoaLenderTreatmentScreen', pageTitle: 'HOA Lender Treatment'),
    '/usa/pmi-bpmi': ScreenInfo(screenName: 'calc_pmi_bpmi_usa', screenClass: 'USAPmiBpmiScreen', pageTitle: 'PMI BPMI'),
    '/usa/pmi-lpmi': ScreenInfo(screenName: 'calc_pmi_lpmi_usa', screenClass: 'USAPmiLpmiScreen', pageTitle: 'PMI LPMI'),
    '/usa/pmi-spmi': ScreenInfo(screenName: 'calc_pmi_spmi_usa', screenClass: 'USAPmiSpmiScreen', pageTitle: 'PMI SPMI'),
    '/usa/pmi-split': ScreenInfo(screenName: 'calc_pmi_split_usa', screenClass: 'USAPmiSplitScreen', pageTitle: 'PMI Split'),
    
    // UK specific articles/sub-screens
    '/uk/shared-ownership': ScreenInfo(screenName: 'calc_shared_ownership_uk', screenClass: 'UKSharedOwnership', pageTitle: 'Shared Ownership'),
    '/uk/boe-base-rate': ScreenInfo(screenName: 'central_bank_rates_boe_uk', screenClass: 'UKBoeBaseRateTracker', pageTitle: 'BOE Base Rate'),
    '/uk/ai-advisor': ScreenInfo(screenName: 'calc_ai_advisor_uk', screenClass: 'UKAiMortgageAdvisor', pageTitle: 'AI Advisor'),
    '/uk/house-price-index': ScreenInfo(screenName: 'home_prices_region_hpi_uk', screenClass: 'UKHousePriceIndex', pageTitle: 'House Price Index'),
    
    // AI specific
    '/ai/au': ScreenInfo(screenName: 'calc_ai_advisor_australia', screenClass: 'AUAIAdvisorScreen', pageTitle: 'AI Advisor'),
    '/ai/nz': ScreenInfo(screenName: 'calc_ai_advisor_nz', screenClass: 'NZAIAdvisorScreen', pageTitle: 'AI Advisor'),
    '/ai/global': ScreenInfo(screenName: 'calc_ai_advisor_global', screenClass: 'AIAdvisorScreen', pageTitle: 'AI Advisor'),
  };
}
