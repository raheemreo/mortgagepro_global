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

### Validation Commands Run
```bash
# 1. Verification of code style and lint warnings:
flutter analyze

# 2. Execution of complete unit and widget test harness:
flutter test
```
Result: **All checks passed with no warnings or errors!**
