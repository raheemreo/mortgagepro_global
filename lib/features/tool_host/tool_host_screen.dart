// lib/features/tool_host/tool_host_screen.dart
// Universal tool host — routes /tool/:country/:toolId to the right calculator

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/result_panel.dart';
import '../../core/utils/mortgage_math.dart';
import '../../core/utils/pmi_calculator.dart';
import '../../core/utils/currency_formatter.dart';
import '../usa/tools/usa_piti_calc.dart';
import '../usa/tools/usa_mortgage_calc.dart';
import '../usa/tools/usa_amortization_calc.dart';
import '../usa/tools/usa_affordability_calc.dart';
import '../usa/tools/usa_down_payment_calc.dart';
import '../usa/tools/usa_hud_dpa_programs.dart';
import '../usa/tools/usa_piggyback_loan_calc.dart';
import '../usa/tools/usa_refinance_calc.dart';
import '../usa/tools/usa_auto_loan_calc.dart';
import '../usa/tools/usa_fha_loan_calc.dart';
import '../usa/tools/usa_usda_loan_calc.dart';
import '../usa/tools/usa_jumbo_loan_calc.dart';
import '../usa/tools/usa_construction_loan_calc.dart';
import '../usa/tools/usa_dti_calc.dart';
import '../usa/tools/usa_va_loan_calc.dart';
import '../usa/tools/usa_arm_calc.dart';
import '../usa/tools/usa_closing_costs_calc.dart';
import '../usa/tools/usa_flood_insurance_calc.dart';
import '../usa/tools/usa_hoa_fee_impact_calc.dart';
import '../usa/tools/usa_homeowner_insurance_calc.dart';
import '../usa/tools/usa_homeowner_insurance_ho3_calc.dart';
import '../usa/tools/usa_homeowner_insurance_ho5_calc.dart';
import '../usa/tools/usa_homeowner_insurance_ho1_calc.dart';
import '../usa/tools/usa_homeowner_insurance_ho6_calc.dart';
import '../usa/tools/usa_homeowner_insurance_wildfire_calc.dart';
import '../usa/tools/usa_homeowner_insurance_hurricane_calc.dart';
import '../usa/tools/usa_pmi_calc.dart';
import '../usa/tools/usa_property_tax_calc.dart';
import '../usa/tools/usa_credit_score_impact_calc.dart';
import '../usa/tools/usa_heloc_calc.dart';
import '../usa/tools/usa_debt_payoff_planner.dart';
import '../usa/tools/usa_home_equity_loan_calc.dart';
import '../usa/tools/usa_moving_cost_calc.dart';
import '../usa/tools/usa_rent_vs_buy_calc.dart';
import '../usa/tools/usa_student_loan_dti_calc.dart';
import '../usa/tools/usa_tax_deduction_calc.dart';
import '../usa/tools/usa_1031_exchange_calc.dart';
import '../usa/tools/usa_cash_on_cash_calc.dart';
import '../usa/tools/usa_fix_flip_calc.dart';
import '../usa/tools/usa_rental_yield_calc.dart';
import '../canada/tools/ca_stress_test.dart';
import '../canada/tools/ca_cmhc_insurance.dart';
import '../canada/tools/ca_gds_tds_ratio.dart';
import '../canada/tools/ca_affordability.dart';
import '../canada/tools/ca_amortization.dart';
import '../canada/tools/ca_renewal_planner.dart';
import '../canada/tools/ca_prepayment.dart';
import '../canada/tools/ca_land_transfer_tax.dart';
import '../canada/tools/ca_first_home_buyer.dart';
import '../canada/tools/ca_boc_rate_history.dart';
import '../canada/tools/ca_mortgage_calc.dart';
import '../canada/tools/ca_ai_advisor.dart';
import '../australia/tools/au_mortgage_calc.dart';
import '../australia/tools/au_lmi_calculator.dart';
import '../australia/tools/au_offset_account.dart';
import '../australia/tools/au_dti_ratio.dart';
import '../australia/tools/au_affordability.dart';
import '../australia/tools/au_amortization.dart';
import '../australia/tools/au_stamp_duty.dart';
import '../australia/tools/au_refinance.dart';
import '../australia/tools/au_extra_repayments.dart';
import '../australia/tools/au_construction_loan.dart';
import '../australia/tools/au_stamp_duty_by_state.dart';
import '../australia/tools/au_first_home_grant.dart';
import '../australia/tools/au_rba_rate_history.dart';
import '../newzealand/tools/nz_mortgage_calc.dart';
import '../newzealand/tools/nz_repayment_calc.dart';
import '../newzealand/tools/nz_dti_calculator.dart';
import '../newzealand/tools/nz_amortization.dart';
import '../newzealand/tools/nz_affordability_calc.dart';
import '../newzealand/tools/nz_refixing_calc.dart';
import '../newzealand/tools/nz_extra_repayments.dart';
import '../newzealand/tools/nz_car_loan_calc.dart';
import '../newzealand/tools/nz_lvr_calculator.dart';
import '../newzealand/tools/nz_deposit_builder.dart';
import '../newzealand/tools/nz_lvr_band_tool.dart';
import '../newzealand/tools/nz_low_equity_margin.dart';
import '../newzealand/tools/nz_kiwisaver_calc.dart';
import '../newzealand/tools/nz_homestart_grant.dart';
import '../newzealand/tools/nz_kiwisaver_balance.dart';
import '../newzealand/tools/nz_employer_contrib.dart';
import '../newzealand/tools/nz_rental_yield.dart';
import '../newzealand/tools/nz_ring_fencing.dart';
import '../newzealand/tools/nz_bright_line.dart';
import '../newzealand/tools/nz_investment_property.dart';
import '../newzealand/tools/nz_interest_deductibility.dart';
import '../newzealand/tools/nz_nzx_investor_calc.dart';
import '../newzealand/tools/nz_first_home_buyer.dart';
import '../newzealand/tools/nz_deposit_calc.dart';
import '../newzealand/tools/nz_preapproval_guide.dart';
import '../newzealand/tools/nz_solicitor_costs.dart';
import '../newzealand/tools/nz_credit_score_nz.dart';
import '../newzealand/tools/nz_revolving_credit.dart';
import '../newzealand/tools/nz_debt_consolidation.dart';
import '../newzealand/tools/nz_income_tax_calc.dart';
import '../newzealand/tools/nz_refinance_calc.dart';
import '../newzealand/tools/nz_construction_loan.dart';
import '../newzealand/tools/nz_budget_planner.dart';
import '../newzealand/tools/nz_ocr_history.dart';
import '../newzealand/tools/nz_compare_lenders.dart';
import '../newzealand/tools/nz_kiwisaver_withdrawal.dart';
import '../newzealand/tools/nz_all_regions.dart';
import '../newzealand/tools/nz_kainga_ora.dart';
import '../newzealand/tools/nz_reinz_hpi.dart';
import '../newzealand/tools/nz_overseas_investment_act.dart';
import '../newzealand/tools/nz_healthy_homes.dart';
import '../newzealand/tools/nz_moneyhub_mortgage.dart';
import '../newzealand/tools/nz_property_market_report.dart';

// India Tools
import '../india/tools/in_emi_calculator.dart';
import '../india/tools/in_amortization.dart';
import '../india/tools/in_loan_eligibility.dart';
import '../india/tools/in_prepayment_calc.dart';
import '../india/tools/in_balance_transfer.dart';
import '../india/tools/in_foir_calculator.dart';
import '../india/tools/in_under_construction.dart';
import '../india/tools/in_joint_loan.dart';
import '../india/tools/in_floating_vs_fixed.dart';
import '../india/tools/in_car_loan_emi.dart';
import '../india/tools/in_cibil_score_impact.dart';
import '../india/tools/in_first_home_buyer.dart';
import '../india/tools/in_tds_on_property.dart';
import '../india/tools/in_capital_gains_tax.dart';
import '../india/tools/in_personal_loan_emi.dart';
import '../india/tools/in_education_loan.dart';
import '../india/tools/in_ppf_calculator.dart';
import '../india/tools/in_epf_calculator.dart';
import '../india/tools/in_sip_calculator.dart';
import '../india/tools/in_nps_calculator.dart';
import '../india/tools/in_income_tax_calculator.dart';
import '../india/tools/in_gold_loan_calculator.dart';
import '../india/tools/in_lap_calculator.dart';
import '../india/tools/in_rbi_repo_rate_history.dart';
import '../india/tools/in_nhb_residex.dart';
import '../india/tools/in_nri_home_loan.dart';
import '../india/tools/in_nre_nro_account.dart';
import '../india/tools/in_fema_compliance.dart';
import '../india/tools/in_usd_inr_converter.dart';
import '../india/tools/in_pmay_eligibility.dart';
import '../india/tools/in_gst_property.dart';
import '../india/tools/in_rbi_monetary_policy.dart';
import '../india/tools/in_compare_banks.dart';
import '../india/tools/in_city_property_prices.dart';
import '../india/tools/in_stamp_duty_all_states.dart';
import '../india/tools/in_banks_hfcs_compare.dart';
import '../india/tools/in_india_ai_advisor.dart';
import '../india/tools/in_stamp_duty_calc.dart';
import '../india/tools/in_gst_calculator.dart';
import '../india/tools/in_pmay_subsidy.dart';
import '../india/tools/in_section_80c.dart';
import '../india/tools/in_section_24b.dart';
import '../india/tools/in_pmay_housing_for_all.dart';
import '../india/tools/in_80c_24b_guide.dart';

import '../uk/tools/uk_affordability.dart';
import '../uk/tools/uk_amortization.dart';
import '../uk/tools/uk_buy_to_let.dart';
import '../uk/tools/uk_help_to_buy.dart';
import '../uk/tools/uk_income_multiples.dart';
import '../uk/tools/uk_ltv_calculator.dart';
import '../uk/tools/uk_mortgage_calc.dart';
import '../uk/tools/uk_remortgage.dart';
import '../uk/tools/uk_sdlt_calculator.dart';
import '../uk/tools/uk_stamp_duty.dart';

// Europe Tools
import '../europe/tools/eu_mortgage_calc.dart';
import '../europe/tools/eu_affordability_calc.dart';
import '../europe/tools/eu_amortization_calc.dart';
import '../europe/tools/eu_country_comparison.dart';
import '../europe/tools/eu_currency_converter.dart';
import '../europe/tools/eu_dti_calc.dart';
import '../europe/tools/eu_euribor_tracker.dart';
import '../europe/tools/eu_nonresident_calc.dart';
import '../europe/tools/eu_notary_fee_calc.dart';
import '../europe/tools/eu_property_tax_calc.dart';

import '../../shared/models/saved_calc.dart';
import '../../services/ad_config.dart';
import '../../services/ad_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class ToolHostScreen extends ConsumerStatefulWidget {
  final String country;
  final String toolId;
  final SavedCalc? savedCalc;

  const ToolHostScreen({
    super.key,
    required this.country,
    required this.toolId,
    this.savedCalc,
  });

  @override
  ConsumerState<ToolHostScreen> createState() => _ToolHostScreenState();
}

class _ToolHostScreenState extends ConsumerState<ToolHostScreen> {
  CountryTheme get _theme => CountryThemes.fromCode(widget.country);

  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    final adUnitId = Platform.isIOS
        ? AdConfig.interstitialAdUnitIos
        : AdConfig.interstitialAdUnitAndroid;
    AdManager.instance.loadInterstitial(adUnitId, screen: 'tool_host_screen');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).setCalculatorTab(widget.country, widget.toolId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _toolName {
    if (widget.country.toLowerCase() == 'uk') {
      switch (widget.toolId.toLowerCase()) {
        case 'mortgage':
          return 'Mortgage Calculator';
        case 'stampduty':
          return 'Stamp Duty Land Tax';
        case 'ltv':
          return 'LTV Calculator';
        case 'remortgage':
          return 'Remortgage Planner';
        case 'affordability':
          return 'Mortgage Affordability';
        case 'helptobuy':
          return 'Help to Buy Calculator';
        case 'amortization':
          return 'Amortization Schedule';
        case 'btl':
          return 'Buy-to-Let Yield';
        case 'incomemultiples':
          return 'Income Multiples';
        case 'sdlt':
          return 'SDLT Calculator';
      }
    }

    switch (widget.toolId) {
      case 'fha':
        return 'FHA Loan Calculator';
      case 'va':
        return 'VA Loan Calculator';
      case 'usda':
        return 'USDA Loan Calculator';
      case 'jumbo':
        return 'Jumbo Loan Calculator';
      case 'construction':
        return 'Construction Loan';
      case 'arm':
        return 'ARM Calculator';
      case 'mortgage':
        return 'Mortgage Calculator';
      case 'piti':
        return 'PITI Calculator';
      case 'dti':
        return 'DTI Calculator';
      case 'amortization':
        return 'Amortization Schedule';
      case 'affordability':
        return 'Affordability Calculator';
      case 'pmi':
        return 'PMI Calculator';
      case 'homeinsurance':
        return 'Homeowner Ins.';
      case 'homeinsurance_ho3':
        return 'HO-3 Standard';
      case 'homeinsurance_ho5':
        return 'HO-5 Premium';
      case 'homeinsurance_ho1':
        return 'HO-1 Basic';
      case 'homeinsurance_ho6':
        return 'HO-6 Condo';
      case 'homeinsurance_wildfire':
        return 'Wildfire Rider';
      case 'homeinsurance_hurricane':
        return 'Hurricane Rider';
      case 'floodinsurance':
        return 'Flood Insurance';
      case 'propertytax':
        return 'Property Tax Calc';
      case 'closingcosts':
        return 'Closing Costs';
      case 'hoaimpact':
        return 'HOA Fee Impact';
      case 'rentalyield':
        return 'Rental Yield Calc';
      case 'cashoncash':
        return 'Cash-on-Cash Return';
      case 'fixflip':
        return 'Fix & Flip Calc';
      case 'exchange1031':
        return '1031 Exchange';
      case 'creditscore':
        return 'Credit Score Impact';
      case 'heloc':
        return 'HELOC Calculator';
      case 'homeequity':
        return 'Home Equity Loan';
      case 'debtpayoff':
        return 'Debt Payoff Planner';
      case 'studentloandti':
        return 'Student Loan DTI';
      case 'taxdeduction':
        return 'Tax Deduction Calc';
      case 'movingcost':
        return 'Moving Cost Calc';
      case 'rentvsbuy':
        return 'Rent vs Buy';
      case 'sdlt':
        return 'Stamp Duty (SDLT)';
      case 'stampduty':
        return 'Stamp Duty (AUS)';
      case 'extrarepayments':
        return 'Extra Repayments';
      case 'stampdutybystate':
        return 'Stamp Duty by State';
      case 'fhog':
        return 'First Home Owner Grant';
      case 'rbahistory':
        return 'RBA Rate History';
      case 'lmi':
        return 'LMI Calculator';
      case 'cmhc':
        return 'CMHC Insurance';
      case 'stresstest':
        return 'Stress Test';
      case 'gdstds':
        return 'GDS / TDS Ratio';
      case 'renewal':
        return 'Renewal Planner';
      case 'ltt':
        return 'Land Transfer Tax';
      case 'firsthome':
        return 'First-Home Buyer';
      case 'bocrate':
        return 'BoC Rate History';
      case 'aiadvisor':
        return 'Canada AI Advisor';
      case 'refinance':
        return 'Refinance Calculator';
      case 'downpayment':
        return 'Down Payment Guide';
      case 'huddpa':
        return 'HUD DPA Programs';
      case 'piggyback':
        return 'Piggyback Loan';
      case 'offset':
        return 'Offset Account';
      case 'lvr':
        return 'LVR Calculator';
      case 'btl':
        return 'Buy-to-Let Yield';
      case 'emi':
        return 'EMI Calculator';
      case 'tax':
        return 'Tax Benefit Calculator';
      case 'prepayment':
        return 'Prepayment Calculator';
      case 'autoloan':
        return 'Auto Loan Calculator';
      case 'euribor':
        return 'Euribor Tracker';
      case 'comparison':
        return 'Country Comparison';
      case 'notaryfee':
        return 'Notary Fee Calc';
      case 'nonresident':
        return 'Non-Resident Calc';
      case 'currency':
        return 'Currency Converter';
      case 'repayment':
        return 'Repayment Calculator';
      case 'refixing':
        return 'Rate Refixing Calculator';
      case 'carloan':
        return 'Car Loan Calculator';
      case 'depositbuilder':
        return 'Deposit Builder';
      case 'lvrband':
        return 'LVR Band Visualiser';
      case 'lowequity':
        return 'Low Equity Margin';
      case 'kiwisavercalc':
        return 'KiwiSaver Calculator';
      case 'homestartgrant':
        return 'First Home Grant';
      case 'kiwisaverbalance':
        return 'KiwiSaver Balance';
      case 'employercontrib':
        return 'Employer Contribution';
      case 'ringfencing':
        return 'Ring-Fencing Rules';
      case 'brightline':
        return 'Bright-Line Test';
      case 'investmentproperty':
        return 'Investment Property';
      case 'interestdeductibility':
        return 'Interest Deductibility';
      case 'nzxinvestor':
        return 'NZX Investor Calc';
      case 'firsthomebuyer':
        return 'First Home Buyer';
      case 'depositcalc':
        return 'Deposit Calc';
      case 'preapprovalguide':
        return 'Pre-approval Guide';
      case 'solicitorcosts':
        return 'Solicitor Costs';
      case 'creditscorenz':
        return 'Credit Score NZ';
      case 'revolvingcredit':
        return 'Revolving Credit';
      case 'debtconsolidation':
        return 'Debt Consolidation';
      case 'incometaxcalc':
        return 'Income Tax Calc';
      case 'refinancecalc':
        return 'Refinance Calc';
      case 'constructionloan':
        return 'Construction Loan';
      case 'budgetplanner':
        return 'Budget Planner';
      case 'ocrhistory':
        return 'OCR History';
      case 'comparelenders':
        return 'Compare Lenders';
      case 'kiwisaverwithdrawal':
        return 'KiwiSaver Withdrawal';
      case 'allregions':
        return 'NZ House Prices';
      case 'property_market_report':
        return 'NZ Property Market Report';
      case 'kaingaora':
        return 'Kāinga Ora Eligibility';
      case 'reinz_hpi':
        return 'REINZ House Price Index';
      case 'overseas_investment_act':
        return 'Overseas Investment Act';
      case 'healthy_homes':
        return 'Healthy Homes Standards';
      case 'moneyhub_mortgage':
        return 'MoneyHub Mortgage Guide';
      case 'in_emi':
        return 'EMI Calculator';
      case 'in_amortization':
        return 'Amortization Schedule';
      case 'in_loan_eligibility':
        return 'Loan Eligibility';
      case 'in_prepayment':
        return 'Prepayment Calculator';
      case 'in_balance_transfer':
        return 'Balance Transfer';
      case 'in_foir':
        return 'FOIR Calculator';
      case 'in_under_construction':
        return 'Under Construction';
      case 'in_joint_loan':
        return 'Joint Loan Calculator';
      case 'in_floating_vs_fixed':
        return 'Floating vs Fixed';
      case 'in_car_loan':
        return 'Car Loan EMI';
      case 'in_stamp_duty':
        return 'Stamp Duty Calculator';
      case 'in_gst':
        return 'GST Calculator';
      case 'in_pmay':
        return 'PMAY Eligibility & Subsidy';
      case 'in_cibil':
        return 'CIBIL Score Impact';
      case 'in_first_home':
        return 'First-Home Buyer';
      case 'in_tds':
        return 'TDS on Property';
      case 'in_capital_gains':
        return 'Capital Gains Tax';
      case 'in_personal_loan_emi':
        return 'Personal Loan EMI';
      case 'in_education_loan':
        return 'Education Loan';
      case 'in_ppf_calculator':
        return 'PPF Calculator';
      case 'in_epf_calculator':
        return 'EPF Calculator';
      case 'in_sip_calculator':
        return 'SIP Calculator';
      case 'in_nps_calculator':
        return 'NPS Calculator';
      case 'in_income_tax_calculator':
        return 'Income Tax Calc';
      case 'in_gold_loan_calculator':
        return 'Gold Loan Calc';
      case 'in_lap_calculator':
        return 'LAP Calculator';
      case 'in_rbi_repo_rate_history':
        return 'RBI Repo Rate History';
      case 'in_nhb_residex':
        return 'NHB Residex';
      case 'in_nri_home_loan':
        return 'NRI Home Loan';
      case 'in_nre_nro_account':
        return 'NRE / NRO Account';
      case 'in_fema_compliance':
        return 'FEMA Compliance';
      case 'in_usd_inr_converter':
        return 'USD / INR Converter';
      case 'in_pmay_eligibility':
        return 'PMAY Eligibility';
      case 'in_gst_property':
        return 'GST Property';
      case 'in_rbi_monetary_policy':
        return 'RBI Monetary Policy';
      case 'in_compare_banks':
        return 'Compare All Banks';
      case 'in_city_property_prices':
        return 'City Property Prices';
      case 'in_stamp_duty_all_states':
        return 'All States Stamp Duty';
      case 'in_banks_hfcs_compare':
        return 'Banks vs HFCs Compare';
      case 'in_india_ai_advisor':
        return 'India AI Advisor';
      case 'in_stamp_duty_calc':
        return 'Stamp Duty Calculator';
      case 'in_gst_calculator':
        return 'GST Calculator';
      case 'in_pmay_subsidy':
        return 'PMAY Subsidy';
      case 'in_section_80c':
        return 'Section 80C Calculator';
      case 'in_section_24b':
        return 'Section 24(b) Calculator';
      case 'in_pmay_housing_for_all':
        return 'PMAY Housing for All';
      case 'in_80c_24b_guide':
        return 'Section 80C / 24(b) Guide';
      default:
        return 'Calculator';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdvisor = widget.toolId.toLowerCase().contains('advisor');
    final Widget child;
    if (isAdvisor) {
      child = Scaffold(
        backgroundColor: _theme.getBgColor(context),
        body: _buildTool(),
      );
    } else {
      child = Scaffold(
        backgroundColor: _theme.getBgColor(context),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: false,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: _theme.headerGradient),
              ),
              expandedHeight: 120,
              pinned: true,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  alignment: Alignment.center,
                  child: Text('←',
                      style:
                          AppTextStyles.dmSans(size: 18, color: Colors.white)),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_theme.flag}  $_toolName',
                      style: AppTextStyles.dmSans(
                          size: 16,
                          weight: FontWeight.w800,
                          color: Colors.white)),
                  Text(_theme.currencyCode,
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTool(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Suppress keyboard first to avoid click overlaps on ad
        FocusScope.of(context).unfocus();
        // Show Interstitial and pop when closed/failed/suppressed
        final adUnitId = Platform.isIOS
            ? AdConfig.interstitialAdUnitIos
            : AdConfig.interstitialAdUnitAndroid;
        AdManager.instance.showInterstitial(
          adUnitId,
          context,
          screen: 'tool_host_screen',
          onDismissed: () {
            if (mounted) {
              setState(() {
                _canPop = true;
              });
              context.pop();
            }
          },
        );
      },
      child: child,
    );
  }

  Widget _buildTool() {
    if (widget.country.toLowerCase() == 'uk') {
      switch (widget.toolId.toLowerCase()) {
        case 'mortgage':
          return UKMortgageCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'stampduty':
          return UKStampDuty(theme: _theme, savedCalc: widget.savedCalc);
        case 'ltv':
          return UKLtvCalculator(theme: _theme, savedCalc: widget.savedCalc);
        case 'remortgage':
          return UKRemortgage(theme: _theme, savedCalc: widget.savedCalc);
        case 'affordability':
          return UKAffordability(theme: _theme, savedCalc: widget.savedCalc);
        case 'helptobuy':
          return UKHelpToBuy(theme: _theme, savedCalc: widget.savedCalc);
        case 'amortization':
          return UKAmortization(theme: _theme, savedCalc: widget.savedCalc);
        case 'btl':
          return UKBuyToLet(theme: _theme, savedCalc: widget.savedCalc);
        case 'incomemultiples':
          return UKIncomeMultiples(theme: _theme, savedCalc: widget.savedCalc);
        case 'sdlt':
          return UKSdltCalculator(theme: _theme, savedCalc: widget.savedCalc);
      }
    }

    if (widget.country.toLowerCase() == 'usa') {
      switch (widget.toolId.toLowerCase()) {
        case 'fha':
          return USAFhaLoanCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'usda':
          return USAUsdaLoanCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'jumbo':
          return USAJumboLoanCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'construction':
          return USAConstructionLoanCalc(theme: _theme);
        case 'piti':
          return USAPitiCalc(theme: _theme);
        case 'mortgage':
          return USAMortgageCalc(theme: _theme);
        case 'amortization':
          return USAAmortizationCalc(theme: _theme);
        case 'affordability':
          return USAAffordabilityCalc(theme: _theme);
        case 'downpayment':
          return USADownPaymentCalc(theme: _theme);
        case 'huddpa':
          return USAHudDpaPrograms(theme: _theme, savedCalc: widget.savedCalc);
        case 'piggyback':
          return USAPiggybackLoanCalc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'refinance':
          return USARefinanceCalc(theme: _theme);
        case 'autoloan':
          return USAAutoLoanCalc(theme: _theme);
        case 'dti':
          return USADtiCalc(theme: _theme);
        case 'va':
          return USAVaLoanCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'arm':
          return USAArmCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'closingcosts':
          return USAClosingCostsCalc(theme: _theme);
        case 'floodinsurance':
          return USAFloodInsuranceCalc(theme: _theme);
        case 'hoaimpact':
          return USAHoaFeeImpactCalc(theme: _theme);
        case 'homeinsurance':
          return USAHomeownerInsuranceCalc(theme: _theme);
        case 'homeinsurance_ho3':
          return USAHomeownerInsuranceHo3Calc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'homeinsurance_ho5':
          return USAHomeownerInsuranceHo5Calc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'homeinsurance_ho1':
          return USAHomeownerInsuranceHo1Calc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'homeinsurance_ho6':
          return USAHomeownerInsuranceHo6Calc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'homeinsurance_wildfire':
          return USAHomeownerInsuranceWildfireCalc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'homeinsurance_hurricane':
          return USAHomeownerInsuranceHurricaneCalc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'pmi':
          return USAPmiCalc(theme: _theme);
        case 'propertytax':
          return USAPropertyTaxCalc(theme: _theme);
        case 'creditscore':
          return USACreditScoreImpactCalc(theme: _theme);
        case 'heloc':
          return USAHelocCalc(theme: _theme);
        case 'debtpayoff':
          return USADebtPayoffPlanner(theme: _theme);
        case 'homeequity':
          return USAHomeEquityLoanCalc(theme: _theme);
        case 'movingcost':
          return USAMovingCostCalc(theme: _theme);
        case 'rentvsbuy':
          return USARentVsBuyCalc(theme: _theme);
        case 'studentloandti':
          return USAStudentLoanDtiCalc(theme: _theme);
        case 'taxdeduction':
          return USATaxDeductionCalc(theme: _theme);
        case 'exchange1031':
          return USA1031ExchangeCalc(theme: _theme);
        case 'cashoncash':
          return USACashOnCashCalc(theme: _theme);
        case 'fixflip':
          return USAFixFlipCalc(theme: _theme);
        case 'rentalyield':
          return USARentalYieldCalc(theme: _theme);
      }
    }

    if (widget.country.toLowerCase() == 'canada' ||
        widget.country.toLowerCase() == 'ca') {
      switch (widget.toolId.toLowerCase()) {
        case 'mortgage':
          return CAMortgageCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'cmhc':
          return CACmhcInsurance(theme: _theme);
        case 'gdstds':
          return CAGdsTdsRatio(theme: _theme);
        case 'stresstest':
          return CAStressTest(theme: _theme);
        case 'affordability':
          return CAAffordability(theme: _theme);
        case 'amortization':
          return CAAmortization(theme: _theme);
        case 'renewal':
          return CARenewalPlanner(theme: _theme);
        case 'prepayment':
          return CAPrepayment(theme: _theme);
        case 'ltt':
          return CALandTransferTax(theme: _theme);
        case 'firsthome':
          return CAFirstHomeBuyer(theme: _theme);
        case 'bocrate':
          return CABocRateHistory(theme: _theme);
        case 'aiadvisor':
          return CAAiAdvisor(theme: _theme);
      }
    }

    if (widget.country.toLowerCase() == 'australia') {
      switch (widget.toolId.toLowerCase()) {
        case 'mortgage':
          return AUMortgageCalc(theme: _theme);
        case 'lmi':
          return AULmiCalc(theme: _theme);
        case 'offset':
          return AUOffsetAccount(theme: _theme);
        case 'dti':
          return AUDtiRatio(theme: _theme);
        case 'affordability':
          return AUAffordability(theme: _theme);
        case 'amortization':
          return AUAmortization(theme: _theme);
        case 'stampduty':
          return AUStampDuty(theme: _theme);
        case 'refinance':
          return AURefinance(theme: _theme);
        case 'extrarepayments':
          return AUExtraRepayments(theme: _theme);
        case 'construction':
          return AUConstructionLoan(theme: _theme);
        case 'stampdutybystate':
          return AUStampDutyByState(theme: _theme);
        case 'fhog':
          return AUFirstHomeGrant(theme: _theme);
        case 'rbahistory':
          return AURbaRateHistory(theme: _theme);
      }
    }

    if (widget.country.toLowerCase() == 'newzealand' ||
        widget.country.toLowerCase() == 'nz') {
      switch (widget.toolId.toLowerCase()) {
        case 'mortgage':
          return NZMortgageCalc(theme: _theme);
        case 'repayment':
          return NZRepaymentCalc(theme: _theme);
        case 'dti':
          return NZDtiCalculator(theme: _theme);
        case 'amortization':
          return NZAmortization(theme: _theme);
        case 'affordability':
          return NZAffordabilityCalc(theme: _theme);
        case 'refixing':
          return NZRefixingCalc(theme: _theme);
        case 'extrarepayments':
          return NZExtraRepayments(theme: _theme);
        case 'carloan':
          return NZCarLoanCalc(theme: _theme);
        case 'lvr':
          return NZLvrCalculator(theme: _theme);
        case 'depositbuilder':
          return NZDepositBuilder(theme: _theme);
        case 'lvrband':
          return NZLvrBandTool(theme: _theme);
        case 'lowequity':
          return NZLowEquityMargin(theme: _theme);
        case 'kiwisavercalc':
          return NZKiwiSaverCalc(theme: _theme);
        case 'homestartgrant':
          return NZHomeStartGrant(theme: _theme);
        case 'kiwisaverbalance':
          return NZKiwiSaverBalance(theme: _theme);
        case 'employercontrib':
          return NZEmployerContrib(theme: _theme);
        case 'rentalyield':
          return NZRentalYieldCalc(theme: _theme);
        case 'ringfencing':
          return NZRingFencingRules(theme: _theme);
        case 'brightline':
          return NZBrightLineTest(theme: _theme);
        case 'investmentproperty':
          return NZInvestmentProperty(theme: _theme);
        case 'interestdeductibility':
          return NZInterestDeductibility(theme: _theme);
        case 'nzxinvestor':
          return NZNZXInvestorCalc(theme: _theme);
        case 'firsthomebuyer':
          return NZFirstHomeBuyer(theme: _theme);
        case 'depositcalc':
          return NZDepositCalc(theme: _theme);
        case 'preapprovalguide':
          return NZPreApprovalGuide(theme: _theme);
        case 'solicitorcosts':
          return NZSolicitorCosts(theme: _theme);
        case 'creditscorenz':
          return NZCreditScoreNZ(theme: _theme);
        case 'revolvingcredit':
          return NZRevolvingCredit(theme: _theme);
        case 'debtconsolidation':
          return NZDebtConsolidation(theme: _theme);
        case 'incometaxcalc':
          return NZIncomeTaxCalc(theme: _theme);
        case 'refinancecalc':
          return NZRefinanceCalc(theme: _theme);
        case 'constructionloan':
          return NZConstructionLoan(theme: _theme);
        case 'budgetplanner':
          return NZBudgetPlanner(theme: _theme);
        case 'ocrhistory':
          return NZOCRHistory(theme: _theme);
        case 'comparelenders':
          return NZCompareLenders(theme: _theme);
        case 'kiwisaverwithdrawal':
          return NZKiwiSaverWithdrawal(theme: _theme);
        case 'allregions':
          return NZAllRegions(theme: _theme);
        case 'property_market_report':
          return NZPropertyMarketReport(theme: _theme);
        case 'kaingaora':
          return NZKaingaOra(theme: _theme);
        case 'reinz_hpi':
          return NZReinzHpi(theme: _theme);
        case 'overseas_investment_act':
          return NZOverseasInvestmentAct(theme: _theme);
        case 'healthy_homes':
          return NZHealthyHomes(theme: _theme);
        case 'moneyhub_mortgage':
          return NZMoneyHubMortgage(theme: _theme);
      }
    }

    if (widget.country.toLowerCase() == 'india' ||
        widget.country.toLowerCase() == 'in') {
      switch (widget.toolId.toLowerCase()) {
        case 'in_emi':
          return INEmiCalculator(theme: _theme);
        case 'in_amortization':
          return INAmortization(theme: _theme);
        case 'in_loan_eligibility':
          return INLoanEligibility(theme: _theme);
        case 'in_prepayment':
          return INPrepaymentCalc(theme: _theme);
        case 'in_balance_transfer':
          return INBalanceTransfer(theme: _theme);
        case 'in_foir':
          return INFOIRCalculator(theme: _theme);
        case 'in_under_construction':
          return INUnderConstruction(theme: _theme);
        case 'in_joint_loan':
          return INJointLoan(theme: _theme);
        case 'in_floating_vs_fixed':
          return INFloatingVsFixed(theme: _theme);
        case 'in_car_loan':
          return INCarLoanEMI(theme: _theme);
        case 'in_stamp_duty':
          return INStampDutyAllStates(theme: _theme);
        case 'in_gst':
          return INGSTProperty(theme: _theme);
        case 'in_pmay':
          return INPMAYEligibility(theme: _theme);
        case 'in_cibil':
          return INCIBILScoreImpact(theme: _theme);
        case 'in_first_home':
          return INFirstHomeBuyer(theme: _theme);
        case 'in_tds':
          return INTDSOnProperty(theme: _theme);
        case 'in_capital_gains':
          return INCapitalGainsTax(theme: _theme);
        case 'in_personal_loan_emi':
          return INPersonalLoanEMI(theme: _theme);
        case 'in_education_loan':
          return INEducationLoan(theme: _theme);
        case 'in_ppf_calculator':
          return INPPFCalculator(theme: _theme);
        case 'in_epf_calculator':
          return INEPFCalculator(theme: _theme);
        case 'in_sip_calculator':
          return INSIPCalculator(theme: _theme);
        case 'in_nps_calculator':
          return INNPSCalculator(theme: _theme);
        case 'in_income_tax_calculator':
          return INIncomeTaxCalculator(theme: _theme);
        case 'in_gold_loan_calculator':
          return INGoldLoanCalculator(theme: _theme);
        case 'in_lap_calculator':
          return INLAPCalculator(theme: _theme);
        case 'in_rbi_repo_rate_history':
          return INRBIRepoRateHistory(theme: _theme);
        case 'in_nhb_residex':
          return INNHBResidex(theme: _theme);
        case 'in_nri_home_loan':
          return INNRIHomeLoan(theme: _theme);
        case 'in_nre_nro_account':
          return INNRENROAccount(theme: _theme);
        case 'in_fema_compliance':
          return INFEMACompliance(theme: _theme);
        case 'in_usd_inr_converter':
          return INUSDINRConverter(theme: _theme);
        case 'in_pmay_eligibility':
          return INPMAYEligibility(theme: _theme);
        case 'in_gst_property':
          return INGSTProperty(theme: _theme);
        case 'in_rbi_monetary_policy':
          return INRBIMonetaryPolicy(theme: _theme);
        case 'in_compare_banks':
          return INCompareBanks(theme: _theme);
        case 'in_city_property_prices':
          return INCityPropertyPrices(theme: _theme);
        case 'in_stamp_duty_all_states':
          return INStampDutyAllStates(theme: _theme);
        case 'in_banks_hfcs_compare':
          return INBanksHFCsCompare(theme: _theme);
        case 'in_india_ai_advisor':
          return INIndiaAIAdvisor(theme: _theme);
        case 'in_stamp_duty_calc':
          return INStampDutyCalc(theme: _theme);
        case 'in_gst_calculator':
          return INGSTCalculator(theme: _theme);
        case 'in_pmay_subsidy':
          return INPMAYSubsidy(theme: _theme);
        case 'in_section_80c':
          return INSection80C(theme: _theme);
        case 'in_section_24b':
          return INSection24B(theme: _theme);
        case 'in_pmay_housing_for_all':
          return INPMAYHousingForAll(theme: _theme);
        case 'in_80c_24b_guide':
          return IN80C24BGuide(theme: _theme);
      }
    }

    if (widget.country.toLowerCase() == 'europe') {
      switch (widget.toolId.toLowerCase()) {
        case 'mortgage':
          return EUMortgageCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'affordability':
          return EUAffordabilityCalc(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'amortization':
          return EUAmortizationCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'comparison':
          return EUCountryComparison(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'currency':
          return EUCurrencyConverter(
              theme: _theme, savedCalc: widget.savedCalc);
        case 'dti':
          return EUDtiCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'euribor':
          return EUEuriborTracker(theme: _theme, savedCalc: widget.savedCalc);
        case 'nonresident':
          return EUNonResidentCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'notaryfee':
          return EUNotaryFeeCalc(theme: _theme, savedCalc: widget.savedCalc);
        case 'propertytax':
          return EUPropertyTaxCalc(theme: _theme, savedCalc: widget.savedCalc);
      }
    }

    switch (widget.toolId) {
      case 'dti':
        return _DTICalc(theme: _theme);
      case 'affordability':
        return _AffordabilityCalc(theme: _theme);
      case 'pmi':
        return _PMICalc(theme: _theme);
      case 'refinance':
        return _RefinanceCalc(theme: _theme);
      case 'btl':
        return _BTLCalc(theme: _theme);
      default:
        return _GenericMortgageCalc(theme: _theme);
    }
  }
}

// ─── Generic Mortgage Calc ────────────────────────────────────────
class _GenericMortgageCalc extends StatefulWidget {
  final CountryTheme theme;
  const _GenericMortgageCalc({required this.theme});

  @override
  State<_GenericMortgageCalc> createState() => _GenericMortgageCalcState();
}

class _GenericMortgageCalcState extends State<_GenericMortgageCalc> {
  double _loan = 400000;
  double _rate = 6.5;
  int _term = 30;

  double get _monthly => MortgageMath.monthlyPayment(
      principal: _loan, annualRatePercent: _rate, termYears: _term);
  double get _totalInterest => MortgageMath.totalInterest(
      principal: _loan, annualRatePercent: _rate, termYears: _term);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          theme: widget.theme,
          children: [
            _LabelSlider(
                label: 'Loan Amount',
                value: _loan,
                min: 10000,
                max: 5000000,
                divisions: 499,
                display: CurrencyFormatter.compact(_loan,
                    symbol: widget.theme.currencySymbol),
                color: widget.theme.primaryColor,
                onChanged: (v) => setState(() => _loan = v)),
            _LabelSlider(
                label: 'Interest Rate',
                value: _rate,
                min: 1,
                max: 15,
                divisions: 140,
                display: '${_rate.toStringAsFixed(2)}%',
                color: widget.theme.primaryColor,
                onChanged: (v) => setState(() => _rate = v)),
            Row(
                children: [10, 15, 20, 25, 30].map((t) {
              final active = t == _term;
              return Expanded(
                  child: GestureDetector(
                      onTap: () => setState(() => _term = t),
                      child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              color: active
                                  ? widget.theme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: active
                                      ? widget.theme.primaryColor
                                      : widget.theme.primaryColor
                                          .withValues(alpha: 0.2))),
                          alignment: Alignment.center,
                          child: Text('${t}yr',
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : widget.theme.primaryColor)))));
            }).toList()),
          ],
        ),
        const SizedBox(height: 16),
        ResultPanel(
          primaryColor: widget.theme.primaryColor,
          rows: [
            ResultRow(
                label: 'Monthly Payment',
                value: _monthly,
                currencyCode: widget.theme.currencyCode,
                isHighlighted: true),
            ResultRow(
                label: 'Total Interest',
                value: _totalInterest,
                currencyCode: widget.theme.currencyCode),
            ResultRow(
                label: 'Total Cost',
                value: _loan + _totalInterest,
                currencyCode: widget.theme.currencyCode),
            const ResultRow(label: 'LTV Estimate', value: 80, isPercent: true),
          ],
        ),
      ],
    );
  }
}

// ─── DTI Calculator ──────────────────────────────────────────────
class _DTICalc extends StatefulWidget {
  final CountryTheme theme;
  const _DTICalc({required this.theme});

  @override
  State<_DTICalc> createState() => _DTICalcState();
}

class _DTICalcState extends State<_DTICalc> {
  double _monthlyDebts = 2500;
  double _grossMonthlyIncome = 8000;
  double _proposedPayment = 1800;

  double get _frontEndDTI =>
      MortgageMath.dti(_proposedPayment, _grossMonthlyIncome);
  double get _backEndDTI =>
      MortgageMath.dti(_monthlyDebts + _proposedPayment, _grossMonthlyIncome);
  bool get _passes => _frontEndDTI <= 28 && _backEndDTI <= 36;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(theme: widget.theme, children: [
          _LabelSlider(
              label: 'Gross Monthly Income',
              value: _grossMonthlyIncome,
              min: 1000,
              max: 50000,
              divisions: 490,
              display: CurrencyFormatter.compact(_grossMonthlyIncome,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _grossMonthlyIncome = v)),
          _LabelSlider(
              label: 'Proposed Mortgage Payment',
              value: _proposedPayment,
              min: 100,
              max: 20000,
              divisions: 199,
              display: CurrencyFormatter.compact(_proposedPayment,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _proposedPayment = v)),
          _LabelSlider(
              label: 'Other Monthly Debts',
              value: _monthlyDebts,
              min: 0,
              max: 20000,
              divisions: 200,
              display: CurrencyFormatter.compact(_monthlyDebts,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _monthlyDebts = v)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color:
                  _passes ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _passes
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5))),
          child: Column(children: [
            Text(_passes ? '✅ Passes 28/36 Rule' : '❌ Fails 28/36 Rule',
                style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.w800,
                    color: _passes
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C))),
            const SizedBox(height: 6),
            Text(
                'Front-End: ${_frontEndDTI.toStringAsFixed(1)}% (limit 28%) · Back-End: ${_backEndDTI.toStringAsFixed(1)}% (limit 36%)',
                style: AppTextStyles.dmSans(
                    size: 11,
                    color: _passes
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B)),
                textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 16),
        ResultPanel(primaryColor: widget.theme.primaryColor, rows: [
          ResultRow(
              label: 'Front-End DTI',
              value: _frontEndDTI,
              isPercent: true,
              isHighlighted: true),
          ResultRow(label: 'Back-End DTI', value: _backEndDTI, isPercent: true),
          ResultRow(
              label: 'Max Housing at 28%',
              value: _grossMonthlyIncome * 0.28,
              currencyCode: widget.theme.currencyCode),
          ResultRow(
              label: 'Max Total at 36%',
              value: _grossMonthlyIncome * 0.36,
              currencyCode: widget.theme.currencyCode),
        ]),
      ],
    );
  }
}

// ─── Affordability Calculator ────────────────────────────────────
class _AffordabilityCalc extends StatefulWidget {
  final CountryTheme theme;
  const _AffordabilityCalc({required this.theme});

  @override
  State<_AffordabilityCalc> createState() => _AffordabilityCalcState();
}

class _AffordabilityCalcState extends State<_AffordabilityCalc> {
  double _income = 100000;
  double _rate = 6.82;
  final int _term = 30;
  double _downPayment = 20;

  double get _maxLoan => MortgageMath.maxBorrowing(
      grossAnnualIncome: _income,
      annualRatePercent: _rate,
      termYears: _term,
      maxDtiPercent: 28);
  double get _maxHomePrice => _maxLoan / (1 - _downPayment / 100);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(theme: widget.theme, children: [
          _LabelSlider(
              label: 'Annual Gross Income',
              value: _income,
              min: 20000,
              max: 500000,
              divisions: 480,
              display: CurrencyFormatter.compact(_income,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _income = v)),
          _LabelSlider(
              label: 'Down Payment %',
              value: _downPayment,
              min: 3,
              max: 50,
              divisions: 47,
              display: '${_downPayment.toInt()}%',
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _downPayment = v)),
          _LabelSlider(
              label: 'Interest Rate',
              value: _rate,
              min: 1,
              max: 15,
              divisions: 140,
              display: '${_rate.toStringAsFixed(2)}%',
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _rate = v)),
        ]),
        const SizedBox(height: 16),
        ResultPanel(primaryColor: widget.theme.primaryColor, rows: [
          ResultRow(
              label: 'Max Home Price',
              value: _maxHomePrice,
              currencyCode: widget.theme.currencyCode,
              isHighlighted: true),
          ResultRow(
              label: 'Max Loan Amount',
              value: _maxLoan,
              currencyCode: widget.theme.currencyCode),
          ResultRow(
              label: 'Down Payment',
              value: _maxHomePrice * _downPayment / 100,
              currencyCode: widget.theme.currencyCode),
          ResultRow(
              label: 'Est. Monthly Payment',
              value: MortgageMath.monthlyPayment(
                  principal: _maxLoan,
                  annualRatePercent: _rate,
                  termYears: _term),
              currencyCode: widget.theme.currencyCode),
        ]),
      ],
    );
  }
}

// ─── PMI Calculator ──────────────────────────────────────────────
class _PMICalc extends StatefulWidget {
  final CountryTheme theme;
  const _PMICalc({required this.theme});

  @override
  State<_PMICalc> createState() => _PMICalcState();
}

class _PMICalcState extends State<_PMICalc> {
  double _homeValue = 400000;
  double _downPct = 10;

  double get _loan => _homeValue * (1 - _downPct / 100);
  double get _ltv => MortgageMath.ltv(_loan, _homeValue);
  double get _monthlyPMI =>
      PMICalculator.monthlyPMI(loanAmount: _loan, ltvPercent: _ltv);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(theme: widget.theme, children: [
          _LabelSlider(
              label: 'Home Value',
              value: _homeValue,
              min: 50000,
              max: 3000000,
              divisions: 295,
              display: CurrencyFormatter.compact(_homeValue),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _homeValue = v)),
          _LabelSlider(
              label: 'Down Payment %',
              value: _downPct,
              min: 3,
              max: 30,
              divisions: 27,
              display: '${_downPct.toInt()}%',
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _downPct = v)),
        ]),
        const SizedBox(height: 16),
        ResultPanel(primaryColor: widget.theme.primaryColor, rows: [
          ResultRow(
              label: 'Monthly PMI',
              value: _monthlyPMI,
              currencyCode: 'USD',
              isHighlighted: true),
          ResultRow(
              label: 'Annual PMI',
              value: _monthlyPMI * 12,
              currencyCode: 'USD'),
          ResultRow(label: 'LTV Ratio', value: _ltv, isPercent: true),
          ResultRow(
              label: 'PMI Cancels at',
              value: PMICalculator.propertyValueAtCancellation(_loan),
              currencyCode: 'USD'),
        ]),
        if (_monthlyPMI == 0) ...[
          const SizedBox(height: 12),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC))),
              child: Text('✅ No PMI Required — 20%+ down payment',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF15803D)))),
        ],
      ],
    );
  }
}

// ─── Refinance Calculator ─────────────────────────────────────────
class _RefinanceCalc extends StatefulWidget {
  final CountryTheme theme;
  const _RefinanceCalc({required this.theme});

  @override
  State<_RefinanceCalc> createState() => _RefinanceCalcState();
}

class _RefinanceCalcState extends State<_RefinanceCalc> {
  double _currentBalance = 350000;
  double _currentRate = 7.5;
  double _newRate = 6.5;
  double _closingCosts = 5000;
  final int _term = 30;

  double get _currentPayment => MortgageMath.monthlyPayment(
      principal: _currentBalance,
      annualRatePercent: _currentRate,
      termYears: _term);
  double get _newPayment => MortgageMath.monthlyPayment(
      principal: _currentBalance,
      annualRatePercent: _newRate,
      termYears: _term);
  double get _monthlySaving => _currentPayment - _newPayment;
  int get _breakEven => MortgageMath.refinanceBreakEven(
      closingCosts: _closingCosts, monthlySavings: _monthlySaving);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(theme: widget.theme, children: [
          _LabelSlider(
              label: 'Current Balance',
              value: _currentBalance,
              min: 50000,
              max: 2000000,
              divisions: 195,
              display: CurrencyFormatter.compact(_currentBalance,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _currentBalance = v)),
          _LabelSlider(
              label: 'Current Rate',
              value: _currentRate,
              min: 1,
              max: 15,
              divisions: 140,
              display: '${_currentRate.toStringAsFixed(2)}%',
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _currentRate = v)),
          _LabelSlider(
              label: 'New Rate',
              value: _newRate,
              min: 1,
              max: 15,
              divisions: 140,
              display: '${_newRate.toStringAsFixed(2)}%',
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _newRate = v)),
          _LabelSlider(
              label: 'Closing Costs',
              value: _closingCosts,
              min: 0,
              max: 30000,
              divisions: 300,
              display: CurrencyFormatter.compact(_closingCosts,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _closingCosts = v)),
        ]),
        const SizedBox(height: 16),
        ResultPanel(primaryColor: widget.theme.primaryColor, rows: [
          ResultRow(
              label: 'Monthly Savings',
              value: _monthlySaving,
              currencyCode: widget.theme.currencyCode,
              isHighlighted: true),
          ResultRow(label: 'Break-Even (months)', value: _breakEven.toDouble()),
          ResultRow(
              label: 'Current Payment',
              value: _currentPayment,
              currencyCode: widget.theme.currencyCode),
          ResultRow(
              label: 'New Payment',
              value: _newPayment,
              currencyCode: widget.theme.currencyCode),
        ]),
      ],
    );
  }
}

// ─── Buy-to-Let Yield Calc ────────────────────────────────────────
class _BTLCalc extends StatefulWidget {
  final CountryTheme theme;
  const _BTLCalc({required this.theme});

  @override
  State<_BTLCalc> createState() => _BTLCalcState();
}

class _BTLCalcState extends State<_BTLCalc> {
  double _purchasePrice = 350000;
  double _monthlyRent = 1800;
  double _annualExpenses = 5000;

  double get _grossYield =>
      _purchasePrice > 0 ? (_monthlyRent * 12) / _purchasePrice * 100 : 0;
  double get _netYield => _purchasePrice > 0
      ? ((_monthlyRent * 12) - _annualExpenses) / _purchasePrice * 100
      : 0;
  double get _annualProfit => (_monthlyRent * 12) - _annualExpenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(theme: widget.theme, children: [
          _LabelSlider(
              label: 'Purchase Price',
              value: _purchasePrice,
              min: 50000,
              max: 3000000,
              divisions: 295,
              display: CurrencyFormatter.compact(_purchasePrice,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _purchasePrice = v)),
          _LabelSlider(
              label: 'Monthly Rent',
              value: _monthlyRent,
              min: 200,
              max: 10000,
              divisions: 98,
              display: CurrencyFormatter.compact(_monthlyRent,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _monthlyRent = v)),
          _LabelSlider(
              label: 'Annual Expenses',
              value: _annualExpenses,
              min: 0,
              max: 50000,
              divisions: 500,
              display: CurrencyFormatter.compact(_annualExpenses,
                  symbol: widget.theme.currencySymbol),
              color: widget.theme.primaryColor,
              onChanged: (v) => setState(() => _annualExpenses = v)),
        ]),
        const SizedBox(height: 16),
        ResultPanel(primaryColor: widget.theme.primaryColor, rows: [
          ResultRow(
              label: 'Gross Rental Yield',
              value: _grossYield,
              isPercent: true,
              isHighlighted: true),
          ResultRow(
              label: 'Net Rental Yield', value: _netYield, isPercent: true),
          ResultRow(
              label: 'Annual Profit',
              value: _annualProfit,
              currencyCode: widget.theme.currencyCode),
          ResultRow(
              label: 'Annual Rent Income',
              value: _monthlyRent * 12,
              currencyCode: widget.theme.currencyCode),
        ]),
      ],
    );
  }
}

// ─── Shared Helper Widgets ────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final CountryTheme theme;
  final List<Widget> children;

  const _SectionCard({required this.theme, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: theme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.getBorderColor(context)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.2
                        : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3))
          ]),
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }
}

class _LabelSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final Color color;
  final ValueChanged<double> onChanged;

  const _LabelSlider(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.divisions,
      required this.display,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF5B6E8F))),
        Text(display,
            style: AppTextStyles.dmSans(
                size: 13.5, weight: FontWeight.w700, color: color)),
      ]),
      SliderTheme(
          data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.20),
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 3),
          child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged)),
    ]);
  }
}
