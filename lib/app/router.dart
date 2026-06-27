// lib/app/router.dart

import 'package:go_router/go_router.dart';
import 'theme/country_themes.dart';
import '../shared/models/saved_calc.dart';
import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/usa/usa_screen.dart';
import '../features/uk/uk_screen.dart';
import '../features/australia/australia_screen.dart';
import '../features/canada/canada_screen.dart';
import '../features/europe/europe_screen.dart';
import '../features/india/india_screen.dart';
import '../features/newzealand/nz_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/global/global_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/tools/tools_screen.dart';
import '../features/ai_advisor/ai_advisor_screen.dart';
import '../features/tool_host/tool_host_screen.dart';
import '../features/usa/screens/usa_property_tax_by_state_screen.dart';
import '../features/usa/screens/usa_fed_funds_rate_screen.dart';
import '../features/usa/screens/usa_rate_trends_screen.dart';
import '../features/usa/screens/usa_first_time_homebuyer_screen.dart';
import '../features/usa/screens/usa_va_benefits_screen.dart';
import '../features/usa/screens/usa_retirement_withdrawal_screen.dart';
import '../features/usa/screens/usa_usda_rural_development_screen.dart';
import '../features/usa/screens/usa_fha_203k_rehab_loan_screen.dart';
import '../features/usa/screens/usa_fha_loan_limits_screen.dart';
import '../features/usa/screens/usa_fha_credit_score_requirements_screen.dart';
import '../features/usa/screens/usa_fha_mip_cancellation_rules_screen.dart';
import '../features/usa/screens/usa_fha_property_standards_screen.dart';
import '../features/usa/screens/usa_jumbo_top_lenders_screen.dart';
import '../features/usa/screens/usa_jumbo_documentation_screen.dart';
import '../features/usa/screens/usa_jumbo_arm_options_screen.dart';
import '../features/usa/screens/usa_jumbo_vs_conforming_screen.dart';
import '../features/usa/screens/usa_usda_eligibility_map_screen.dart';
import '../features/usa/screens/usa_usda_502_direct_vs_guaranteed_screen.dart';
import '../features/usa/screens/usa_usda_2025_income_limits_screen.dart';
import '../features/usa/screens/usa_usda_streamline_refinance_screen.dart';
import '../features/usa/screens/usa_va_coe_screen.dart';
import '../features/usa/screens/usa_va_entitlement_limits_screen.dart';
import '../features/usa/screens/usa_va_surviving_spouse_screen.dart';
import '../features/usa/screens/usa_va_irrrl_refinance_screen.dart';
import '../features/usa/screens/usa_ai_mortgage_advisor_screen.dart';
import '../features/usa/screens/usa_arm_vs_fixed_breakeven_screen.dart';
import '../features/usa/screens/usa_sofr_rate_history_screen.dart';
import '../features/usa/screens/usa_refinancing_arm_screen.dart';
import '../features/usa/screens/usa_arm_risk_factors_screen.dart';
import '../features/usa/screens/usa_fred_rate_history_screen.dart';
import '../features/usa/screens/usa_fedwatch_screen.dart';
import '../features/usa/screens/usa_yield_curve_screen.dart';
import '../features/usa/screens/usa_cpi_vs_fed_rate_screen.dart';
import '../features/usa/screens/usa_home_price_index_screen.dart';
import '../features/usa/screens/usa_median_home_prices_state_screen.dart';
import '../features/usa/screens/usa_top_lenders_screen.dart';
import '../features/usa/screens/usa_prequal_guide_screen.dart';
import '../features/usa/screens/usa_one_close_vs_two_close_screen.dart';
import '../features/usa/screens/usa_builder_requirements_screen.dart';
import '../features/usa/screens/usa_top_construction_lenders_screen.dart';
import '../features/usa/screens/usa_fha_203k_alternative_screen.dart';
import '../features/australia/tools/au_ai_advisor.dart';
import '../features/newzealand/tools/nz_ai_advisor.dart';
import '../features/uk/screens/uk_shared_ownership.dart';
import '../features/uk/screens/uk_boe_base_rate_tracker.dart';
import '../features/uk/screens/uk_ai_mortgage_advisor.dart';
import '../features/uk/screens/uk_house_price_index.dart';
import '../features/usa/screens/usa_emergency_fund_screen.dart';
import '../features/usa/screens/usa_home_maintenance_budget_screen.dart';
import '../features/usa/screens/usa_fico_better_rate_screen.dart';
import '../features/usa/screens/usa_hoa_what_fees_cover_screen.dart';
import '../features/usa/screens/usa_hoa_reserve_fund_health_screen.dart';
import '../features/usa/screens/usa_hoa_fee_increases_screen.dart';
import '../features/usa/screens/usa_hoa_lender_treatment_screen.dart';
import '../features/usa/screens/usa_pmi_bpmi_screen.dart';
import '../features/usa/screens/usa_pmi_lpmi_screen.dart';
import '../features/usa/screens/usa_pmi_spmi_screen.dart';
import '../features/usa/screens/usa_pmi_split_screen.dart';
import '../features/global/screens/global_top_lenders_screen.dart';

import 'package:mortgagepro_global/services/analytics_service.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  observers: [
    // FirebaseAnalyticsObserver is constructed once inside AnalyticsService.
    // Do NOT construct FirebaseAnalyticsObserver anywhere else.
    AnalyticsService.instance.analyticsObserver,
  ],
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadeTransition(
        state,
        const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/usa',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/uk',
      pageBuilder: (context, state) => _slideTransition(
        state,
        UKScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/australia',
      pageBuilder: (context, state) => _slideTransition(
        state,
        AustraliaScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/canada',
      pageBuilder: (context, state) => _slideTransition(
        state,
        CanadaScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/europe',
      pageBuilder: (context, state) => _slideTransition(
        state,
        EuropeScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/india',
      pageBuilder: (context, state) => _slideTransition(
        state,
        IndiaScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/newzealand',
      pageBuilder: (context, state) => _slideTransition(
        state,
        NZScreen(
          toolId: state.uri.queryParameters['toolId'],
          fallback: state.uri.queryParameters['fallback'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/saved',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const SavedScreen(),
      ),
    ),
    GoRoute(
      path: '/global',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const GlobalScreen(),
      ),
    ),
    GoRoute(
      path: '/global/top-lenders',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const GlobalTopLendersScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const NotificationScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/feedback',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const FeedbackScreen(),
      ),
    ),
    GoRoute(
      path: '/tools',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const ToolsScreen(),
      ),
    ),
    GoRoute(
      path: '/tool/:country/:toolId',
      pageBuilder: (context, state) => _slideTransition(
        state,
        ToolHostScreen(
          country: state.pathParameters['country']!,
          toolId: state.pathParameters['toolId']!,
          savedCalc: state.extra as SavedCalc?,
        ),
      ),
    ),
    GoRoute(
      path: '/usa/property-tax-by-state',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAPropertyTaxByStateScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/fed-funds-rate',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAFedFundsRateScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/rate-trends',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USARateTrendsScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/first-time-homebuyer',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAFirstTimeHomebuyerScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/va-benefits',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAVaBenefitsScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/retirement-withdrawal',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USARetirementWithdrawalScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/usda-rural',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAUsdaRuralDevelopmentScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/usda-eligibility-map',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAUsdaEligibilityMapScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/usda-502-direct-vs-guaranteed',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAUsda502DirectVsGuaranteedScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/usda-2025-income-limits',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAUsda2025IncomeLimitsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/usda-streamline-refinance',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAUsdaStreamlineRefinanceScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fha-203k',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFha203kRehabLoanScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/one-close-vs-two-close',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAOneCloseVsTwoCloseScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/builder-requirements',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USABuilderRequirementsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/top-construction-lenders',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USATopConstructionLendersScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fha-203k-alternative',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFha203kAlternativeScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fha-loan-limits',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFhaLoanLimitsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fha-credit-score-requirements',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFhaCreditScoreRequirementsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fha-mip-cancellation-rules',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFhaMipCancellationRulesScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fha-property-standards',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFhaPropertyStandardsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/jumbo-lenders',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAJumboTopLendersScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/jumbo-documentation',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAJumboDocumentationScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/jumbo-arm',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAJumboArmOptionsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/jumbo-vs-conforming',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAJumboVsConformingScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/va-coe',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAVaCoeScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/va-entitlement-limits',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAVaEntitlementLimitsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/va-surviving-spouse',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAVaSurvivingSpouseScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/va-irrrl',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAVaIrrrlRefinanceScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/arm-vs-fixed-breakeven',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAArmVsFixedBreakevenScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/sofr-history',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USASofrRateHistoryScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/refinance-arm',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USARefinancingArmScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/arm-risk-factors',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAArmRiskFactorsScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/ai-advisor',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAAIMortgageAdvisorScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/fred-rate-history',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAFredRateHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/fedwatch',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAFedWatchScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/yield-curve',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAYieldCurveScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/cpi-vs-fed-rate',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USACpiVsFedRateScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/home-price-index',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAHomePriceIndexScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/median-home-prices',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAMedianHomePricesStateScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/top-lenders',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USATopLendersScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/prequal-guide',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAMortgagePrequalGuideScreen(),
      ),
    ),
    GoRoute(
      path: '/ai/au',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const AUAIAdvisorScreen(),
      ),
    ),
    GoRoute(
      path: '/ai/nz',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const NZAIAdvisorScreen(),
      ),
    ),
    GoRoute(
      path: '/ai/:country',
      pageBuilder: (context, state) => _slideTransition(
        state,
        AIAdvisorScreen(country: state.pathParameters['country']!),
      ),
    ),
    GoRoute(
      path: '/uk/shared-ownership',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const UKSharedOwnership(theme: CountryThemes.uk),
      ),
    ),
    GoRoute(
      path: '/uk/boe-base-rate',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const UKBoeBaseRateTracker(theme: CountryThemes.uk),
      ),
    ),
    GoRoute(
      path: '/uk/ai-advisor',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const UKAiMortgageAdvisor(theme: CountryThemes.uk),
      ),
    ),
    GoRoute(
      path: '/uk/house-price-index',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const UKHousePriceIndex(theme: CountryThemes.uk),
      ),
    ),
    GoRoute(
      path: '/usa/emergency-fund',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAEmergencyFundScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/home-maintenance-budget',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAHomeMaintenanceBudgetScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/fico-better-rate',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAFicoBetterRateScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/hoa-what-fees-cover',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const USAHoaWhatFeesCoverScreen(),
      ),
    ),
    GoRoute(
      path: '/usa/hoa-reserve-fund-health',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAHoaReserveFundHealthScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/hoa-fee-increases',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAHoaFeeIncreasesScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/hoa-lender-treatment',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAHoaLenderTreatmentScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/pmi-bpmi',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAPmiBpmiScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/pmi-lpmi',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAPmiLpmiScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/pmi-spmi',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAPmiSpmiScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
    GoRoute(
      path: '/usa/pmi-split',
      pageBuilder: (context, state) => _slideTransition(
        state,
        USAPmiSplitScreen(savedCalc: state.extra as SavedCalc?),
      ),
    ),
  ],
);

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
  );
}

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}
