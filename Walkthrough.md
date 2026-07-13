# Mortgage Pro Global — Comprehensive Project Walkthrough

This document provides a complete and detailed walkthrough of all the features, refactorings, optimizations, and bug fixes implemented during our pairing sessions for the **Mortgage Pro Global** application.

---

## Table of Contents
1. [AI Advisor Centralization & API Security](#1-ai-advisor-centralization--api-security)
2. [AI Advisor UI & Layout Optimizations](#2-ai-advisor-ui--layout-optimizations)
3. [UX Improvements — Phase 1 (Text Styles & Color Contrasts)](#3-ux-improvements--phase-1-text-styles--color-contrasts)
4. [UX Improvements — Phase 2 (Persistent Settings & Preferences)](#4-ux-improvements--phase-2-persistent-settings--preferences)
5. [UX Improvements — Phase 3 (Workflow Continuity & Shared State)](#5-ux-improvements--phase-3-workflow-continuity--shared-state)
6. [Testing & Quality Assurance](#6-testing--quality-assurance)

---

## 1. AI Advisor Centralization & API Security

### Problem Summary
Previously, every country's AI Advisor screen duplicated its own API request logic using inline `Dio` calls. This duplicated approximately 800 lines of code across 8 different advisor screens. Additionally, API keys were injected via compile-time `--dart-define` (e.g. `String.fromEnvironment`), resulting in broken features during local development runs if flags were omitted.

### Implementation Details
1. **Centralized `AIService`**:
   - Refactored `AIService` into a robust, centralized singleton responsible for managing API request lifecycle, system instructions, chat history formatting, and model selection.
   - Built a sequential fallback key pool containing multiple Gemini keys, with an automatic fallback mechanism to Groq (Llama) models if Gemini quotas are exceeded.
2. **Runtime Key Loading**:
   - Bundled API keys securely in `secrets.json` (gitignored to prevent exposure) as a local Flutter asset.
   - Wired the startup logic in [main.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/main.dart) to asynchronously load and initialize these keys using `AIService.instance.loadKeysFromAssets()` prior to running the main app, resolving all local development environment issues.
3. **Screen Refactoring**:
   - Refactored all AI Advisor screens to use `AIService.instance.sendMessage(...)`, eliminating ~100 lines of redundant API request logic per screen.
   - Preserved all custom system prompts and chat configurations specific to each region.

---

## 2. AI Advisor UI & Layout Optimizations

### USA AI Advisor
- **Bug Fix**: Resolved a critical issue where the chat input layout would be obscured by the on-screen keyboard.
- **Scaffold Restructuring**: Converted the absolute layout from `Stack` + `Positioned(bottom: 0)` to a structured `Scaffold` body column combined with native bottom padding, guaranteeing that the text entry field is always pushed above the keyboard.
- Removed the legacy "Customize Borrower Context" block to declutter the screen.

### UK AI Advisor
- **Space & Margins Optimization**: Removed unnecessary bottom gaps and padding to maximize the visible chat area.
- Removed the "Save Action Buttons" row and session summary cards to simplify user experience.
- Converted screen layout to expand the chat list to 100% height and docked the text input bar at the bottom.

### New Zealand AI Advisor
- Removed the "NZ Financial AI Advisor" section header.
- Removed the "👤 Tell the AI About You" customization card section to streamline UI.

---

## 3. UX Improvements — Phase 1 (Text Styles & Color Contrasts)

### Theme-Aware Typography
- Modified [text_styles.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/app/theme/text_styles.dart) to make the default text colors for `playfair()` and `dmSans()` nullable.
- When `color` is omitted, it now defaults to `null`, enabling text to automatically and dynamically inherit colors from the active `ThemeData` rather than relying on hardcoded white/black. This resolved readability issues when switching between Light and Dark modes.

### Accessible Inputs
- Added an explicit `InputDecorationTheme` in [app_theme.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/app/theme/app_theme.dart).
- Enforced a contrast-compliant color (`Color(0xFF4C5D7E)`) for hint text in light mode, ensuring adherence to Web Content Accessibility Guidelines (WCAG) AA standards.

---

## 4. UX Improvements — Phase 2 (Persistent Settings & Preferences)

- **Independent Calculator Tab Memory**: Extended `settingsProvider` to persist the last-viewed calculator tab independently for each country. For example, if a user views the Property Tax calculator in the USA dashboard, but views the LTV calculator in the UK dashboard, both tabs are correctly saved and restored.
- **Region & Europe Country Persistence**: Added settings keys to persist the user's selected regional state (`region` for US/CA states, and `selectedEuropeCountry` for EU countries) across app restarts.
- **Unified Navigation Tracking**: Refactored the generic tool host screen to invoke `setCalculatorTab()` inside its state initialization, making tab updates fire-and-forget.

---

## 5. UX Improvements — Phase 3 (Workflow Continuity & Shared State)

### Problem Summary
Previously, calculations performed on a main mortgage screen were lost when navigating to secondary tools (e.g. Property Tax, DTI, or Closing Costs). Users were forced to manually re-enter their home price, interest rate, term, and down payment.

### Implementation Details
1. **In-Memory Shared State**:
   - Introduced a session-scoped, immutable model `CalculatorDraft` and its corresponding `StateNotifier` (`calculatorDraftProvider`).
2. **Interactive Continuation UI**:
   - Created the horizontal-scroll [WorkflowContinuationCard](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/shared/widgets/workflow_continuation_card.dart) component.
   - Embedded this continuation row at the bottom of the USA Mortgage Calculator results sheet. The card dynamically suggests relevant follow-up steps (e.g., "Estimate Property Taxes", "Calculate Closing Costs").
3. **Seamless Multi-Screen Prefill**:
   - Prefilled USA Property Tax (`_assessedValue`).
   - Prefilled USA Affordability (`_rate`, `_selectedTerm`, and `_selectedDP`).
   - Prefilled USA DTI (Housing P&I payment, Property Taxes, and Home Insurance).
   - Prefilled USA PMI (`_price`, `_downPct`, and `_loanTerm`).
   - Prefilled USA Closing Costs (`_price` and `_downPct`).
   - Cleared the draft state immediately after a destination screen consumed the inputs to prevent accidental overrides during subsequent unrelated calculator visits.

---

## 6. Testing & Quality Assurance

### Automated Testing
Created and updated multiple unit and widget test files, passing all checks:
- **WCAG Contrast Tests**: Validated contrast ratios for country theme palettes, ensuring `textColor` and `mutedColor` satisfy AA (4.5:1) and AAA (7:1) criteria.
- **Workflow Continuation Tests**: Verified dynamic calculator mapping filtering per country (e.g. ensuring UK-specific options don't appear for USA).
- **Settings Provider Tests**: Validated persistence and fallback logic for all newly introduced settings fields.
- **Draft State Tests**: Tested immutable copying and prefill consistency calculations.

---

## 7. Startup & Initialization Fix (Stuck Splash Screen)

### Problem Summary
During startup, the application initializes Firebase, Firebase Messaging, Remote Config, App Check, and the Google User Messaging Platform (UMP) Consent SDK. On certain devices or emulators, calls to platform services (such as asking for notification permissions, getting FCM tokens, or loading consent forms) can hang indefinitely due to missing or blocked Google Play Services IPC. Because these steps were fully awaited without timeouts, any single hang would freeze the startup sequence, leaving the app permanently stuck on the splash screen.

### Implementation Details
1. **Asynchronous Call Safeguards**:
   - Refactored `ConsentService._showConsentForm()` to trigger UMP initialization asynchronously (`ConsentForm.loadAndShowConsentFormIfRequired`) and handle callbacks inside a robust, timeout-guarded Future.
2. **Defensive Startup Timeouts**:
   - Refactored `_runInitialization()` in [main.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/main.dart) to wrap all platform-bound asynchronous initializations (Firebase Messaging, Consent SDK, Remote Config, Performance, and App Check) in explicit timeouts (ranging from 3 to 5 seconds).
   - If any setup step hangs or fails, the timeout catches the hang, prints a debug warning, degrades gracefully, and safely continues the initialization sequence to guarantee transition to the home screen.

---

## 8. Phase 8: In-Progress Calculator Input Persistence

### Problem Summary
In the original implementation, the state of input fields (such as home price, down payment, interest rate, term) was stored purely inside transient widget state. If the user navigated away from the calculator or closed/switched screens, their inputs were immediately lost, requiring them to re-enter all values upon return.

### Implementation Details
1. **Generic Settings Schema Extension**:
   - Added a generic `Map<String, String> calculatorInputs` mapping tool IDs (e.g. `usa_mortgage`, `usa_mortgage_sheet`) to JSON-serialized key-value input records inside `AppSettings` in [settings_provider.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/providers/settings_provider.dart).
   - Wired inputs to persist automatically to local disk storage using `shared_preferences`.
2. **Auto-Save & Restoring State**:
   - Integrated input persistence inside `initState` and `_persistInputs` callbacks for:
     - **USA**: `USAMortgageCalc` (screen) & `USAMortgageCalcSheet` (sheet) in [usa_mortgage_calc.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/usa/tools/usa_mortgage_calc.dart).
     - **UK**: `UKMortgageCalc` in [uk_mortgage_calc.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/uk/tools/uk_mortgage_calc.dart).
     - **Canada**: `CAMortgageCalc` in [ca_mortgage_calc.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/canada/tools/ca_mortgage_calc.dart).
     - **Australia**: `AUMortgageCalc` in [au_mortgage_calc.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/australia/tools/au_mortgage_calc.dart).
     - **New Zealand**: `NZMortgageCalc` in [nz_mortgage_calc.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/newzealand/tools/nz_mortgage_calc.dart).
   - Every input adjustment (slider movement, text field edits, dropdown selections, or term choices) automatically persists its state. Navigating away or closing the page restores all values immediately upon return.
3. **Workflow Integration**:
   - Integrated `WorkflowContinuationCard` in the USA full-screen calculator results screen so that calculated inputs can seamlessly propagate to subsequent tools like DTI, Property Tax, PMI, and Closing Costs.

---

## 9. Down Payment Guide UI Overflow Fix

### Problem Summary
In the "Zero Down Programs" section of the USA Down Payment Guide ([usa_down_payment_calc.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/usa/tools/usa_down_payment_calc.dart)), the program cards were placed inside a standard unscrollable horizontal `Row`. When rendered on standard mobile screens, the combined width of the four cards exceeded the screen constraints, causing a 174px right-side layout overflow error.

### Implementation Details
1. **Scrollable Layout Wrapper**:
   - Wrapped the program card horizontal layout inside a `SingleChildScrollView` with `scrollDirection: Axis.horizontal` and `physics: BouncingScrollPhysics()`. This allows users to swipe through the cards smoothly without layout breaks.
2. **Unified Sizing**:
   - Set a fixed `width: 155` and `height: 135` for all program cards in `_buildProgramCard()`. This ensures that they align perfectly vertically and maintain visual consistency across standard and high-density screens.

---

## 10. Interstitial Ad Cooldown Update

### Problem Summary
The default cooldown period between interstitial ad impressions was previously configured to 60 seconds (both as the local fallback default value and the hardcoded minimum floor). To improve user experience and reduce ad fatigue, this time gap needed to be increased to 90 seconds.

### Implementation Details
1. **Default Config Update**:
   - Changed the default value of `interstitialCooldownSeconds` in [remote_config_service.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/services/remote_config_service.dart) from `60` to `90`.
2. **Floor Constraint Update**:
   - Updated the minimum cooldown constraint floor inside `showInterstitial` in [ad_manager.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/services/ad_manager.dart) from `max(60, ...)` to `max(90, ...)`.

---

## 11. India Screen Market Snapshot & Rates Cleanup

### Problem Summary
In [india_screen.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/india/india_screen.dart), the static const `_rates` list and the "Indian Market Snapshot" widget (`_IndiaMarketTicker`) were deprecated or no longer required. These needed to be removed cleanly from both state properties, layout structures, and helper class definitions to keep the screen uncluttered and avoid static analysis warnings.

### Implementation Details
1. **Rates Removal**:
   - Removed the static const list definition `_rates`.
   - Updated the rates parameter in `CountryHeader` on `IndiaScreen` to pass `const []`.
2. **Snapshot Section Removal**:
   - Removed the "Indian Market Snapshot" `SectionLabel` and the `_IndiaMarketTicker()` widget call from the main `CustomScrollView` widget list.
3. **Dead Code Cleanup**:
   - Deleted the unused private widget class `_IndiaMarketTicker` to resolve unused element warning/lints.

---

## 12. New Zealand Screen Cleanups

### Problem Summary
In [nz_screen.dart](file:///e:/Android%20App%20Projects/Mortgage Pro Global/mortgagepro_global/lib/features/newzealand/nz_screen.dart), several sections were no longer needed and needed to be removed cleanly:
1. Reserve Bank NZ Official Cash Rate banner
2. NZ Market Snapshot section
3. Live Home Loan Rates section

### Implementation Details
1. **Layout Removal**:
   - Removed the `SectionLabel` and the `_RBNZBanner()` widget call for the "Reserve Bank NZ" section.
   - Removed the `SectionLabel` and the `_NZMarketTicker()` widget call for the "NZ Market Snapshot" section.
   - Removed the `SectionLabel` and the `_MortgageRatesScroll()` widget call for the "Live Home Loan Rates" section.
2. **Dead Code Cleanup**:
   - Deleted the unused private widget class definitions `_RBNZBanner`, `_NZMarketTicker`, and `_MortgageRatesScroll` to prevent dead-code and unused element static analysis warnings.

---

## 13. Australia Screen Rates Cleanup

### Problem Summary
In [australia_screen.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/australia/australia_screen.dart), the static const `_rates` list was no longer required. It needed to be removed cleanly to match the design updates of other country screens.

### Implementation Details
1. **Rates Removal**:
   - Removed the static const list definition `_rates`.
   - Updated the rates parameter in `CountryHeader` on `AustraliaScreen` to pass `const []`.

---

## 14. Global Screen Rates Grid Cleanup

### Problem Summary
In [global_screen.dart](file:///e:/Android%20App%20Projects/Mortgage%20Pro%20Global/mortgagepro_global/lib/features/global/global_screen.dart), the "2x3 Central Bank Rate Grid" displaying policy rates (Fed Funds, BoC, BoE, RBA, RBNZ, ECB) was no longer required. It needed to be removed cleanly along with its unused helper widgets, enums, style definitions, and unused Riverpod watch bindings.

### Implementation Details
1. **Layout Removal**:
   - Removed the `GridView.count` element defining the 2x3 policy rates grid from the `_GlobalHeader` widget.
2. **State & Providers Cleanup**:
   - Removed the unused watch bindings for `fredFedFundsProvider` (`fedFundsAsync` and `fedFundsVal`) inside `_GlobalHeader.build()`.
3. **Dead Code Cleanup**:
   - Deleted the unused grid item helper class `_GrItem` and its associated `_RateValStyle` enum.
   - Deleted the unused `goldLt` design token definition inside the `_C` style configuration class to resolve unused field warnings/lints.

---

## Verification & Build Results

### 1. Automated Tests
All 79 unit, widget, and regression tests passed successfully (including a new test suite verifying calculator inputs auto-saving and restoring across simulated app restarts):
```bash
flutter test
...
00:01 +79: All tests passed!
```

### 2. Static Analysis
The Dart analyzer verified the codebase with zero warnings, errors, or lints:
```bash
flutter analyze
...
No issues found! (ran in 13.0s)
```


