# Prompt: Comprehensive AdMob Production Audit for Mortgage Pro Global (v2)

## Role

Act as a Senior Flutter Engineer, Google AdMob Monetization Expert, Firebase Analytics Specialist, and Google Play Policy Reviewer.

Perform a complete production audit of the AdMob implementation in Mortgage Pro Global.

Your goal is not to rewrite the ad system, but to verify that it works correctly, efficiently, and complies with current Google AdMob and Google Play policies.

## Project Context

- Flutter, Riverpod, Firebase Analytics, Firebase Remote Config, Firebase Crashlytics, Google Mobile Ads SDK, Google UMP Consent SDK, GoRouter.
- Calculator screens for USA, Canada, UK, Europe, Australia, New Zealand, India, and a Global tab.
- Ad types in use: Banner, Native, Interstitial, Rewarded.
- Ads are gated by Remote Config feature flags.
- Before citing any class (e.g. `AdManager`) as doing something, locate and cite the actual file — do not assume a class's responsibilities from its name.

---

## Non-Goals

Do NOT, in the course of this audit:
- Change ad unit IDs.
- Adjust mediation waterfall configuration.
- Change Remote Config default values or flag names.
- Modify monetization strategy (frequency, cooldowns, eCPM tuning) — recommend changes, don't make them.
- Rewrite ad-loading architecture. This is a read-only audit; all fixes go into the Recommendations deliverable, not into the codebase directly.

---

## Evidence Standard (applies to every phase, not just the Bugs Found deliverable)

Every finding — pass, fail, or partial — in every phase below must cite the specific file and, where applicable, method/line. A phase-level claim written as unsupported prose (e.g. "consent is correctly gated" with no file reference) does not satisfy that phase's requirement. If a check cannot be verified because the relevant code wasn't found or wasn't provided, state that explicitly as "Unverified — [file] not reviewed," rather than asserting a pass or fail.

---

## Phase 1 — Initialization

Verify, with citations:
- `GoogleMobileAds.instance.initialize()` is called exactly once.
- Initialization occurs after consent requirements are satisfied.
- UMP consent flow blocks personalized ads when required.
- Remote Config loads before ad decisions are made.
- The ad-management class (name TBD — cite whichever class actually owns this) is initialized only once, with no duplicate initialization path.

## Phase 2 — Banner Ads

Verify, with citations, for every banner implementation found:
- Correct lifecycle and `dispose()` call; no leaks.
- Adaptive banner sizing.
- No blank reserved space on load failure.
- No layout that risks accidental clicks.
- Reload/retry strategy and offline handling.

List every screen using banner ads (feeds the screen coverage table in the deliverables).

## Phase 3 — Native Ads

Verify, with citations, for every native ad placement:
- Correct loading and retry logic; exponential backoff if implemented; no infinite retry loops.
- Widget hides (not blank-placeholders) on load failure.
- Correct disposal, loading-state handling, refresh behavior.
- Google policy compliance for native ad labeling specifically.

## Phase 4 — Interstitial Ads

Verify, with citations:
- Preloading strategy, expiration handling, frequency limits, cooldown implementation.
- No duplicate show attempts; safe callbacks; correct disposal.
- Ads never interrupt an in-progress calculation, never appear unexpectedly, never appear immediately after app launch.
- **Cross-check against the Default Country Pinning / calculator-workflow-continuity changes**: confirm interstitial trigger points are unchanged by the new cross-calculator navigation paths — diff the trigger call sites against their pre-change state if a prior list exists, or establish one now as a baseline for future changes.

## Phase 5 — Rewarded Ads

Verify, with citations:
- Reward is granted only after the reward callback fires — never before.
- Reward expiration, retry handling, failure handling.
- Ad-free duration logic correctness.
- Analytics events fire correctly; proper disposal.

## Phase 6 — Remote Config

Verify, with citations, for every ad-related flag (`banner_enabled`, `native_enabled`, `interstitial_enabled`, `rewarded_enabled`, `native_frequency`, `interstitial_cooldown_seconds`, `reward_ad_free_duration`, and any others found):
- A safe default exists in code for every flag.
- **Current production-configured values** for each flag, not just confirmation that a default exists — report what's actually live.
- Behavior when Remote Config fails to download (confirm fallback to the coded default, not a crash or undefined ad state).

## Phase 7 — Consent & Privacy

Verify, with citations:
- GDPR, UK GDPR, and U.S. state privacy law handling via UMP.
- Personalized vs. non-personalized ad serving is correctly gated by actual consent state.
- Consent persistence and the consent-update flow.
- Where code inspection alone can't confirm runtime behavior (e.g. actual UMP dialog presentation), state this as a manual-verification item rather than asserting pass/fail from code alone.

## Phase 8 — Firebase Analytics

Verify, with citations, for every ad-related event (`ad_loaded`, `ad_failed`, `ad_impression`, `ad_clicked`, `rewarded_requested`, `rewarded_completed`, `reward_granted`, and any others found):
- No duplicate event firing.
- No sensitive financial data (loan amount, property price, income, etc.) or PII present in any ad-event payload — check specifically whether any ad event fires from a screen/method scope where these values are in scope and could be accidentally attached.
- Correct, consistent event naming.

## Phase 9 — Crashlytics

Verify, with citations:
- Expected ad failures (network error, timeout, no-fill) are NOT reported as exceptions to Crashlytics.
- Only genuinely unexpected SDK or application failures are recorded.
- Recommend specific code changes (as a Recommendation, not an in-place fix) if normal ad failures are currently polluting the crash dashboard.

## Phase 10 — Performance

Using named tooling (Flutter DevTools memory profiler and frame chart — not general impressions), inspect and report with citations/measurements where possible:
- Memory usage and ad caching behavior.
- Widget rebuild frequency around ad placements.
- Scroll performance impact.
- Loading delays, background/foreground transition handling, network efficiency.

This phase's findings are the sole source for the Performance Review deliverable below — do not re-investigate in the deliverables section, only report against what was found here.

## Phase 11 — Policy Compliance

Verify, with citations, against current Google AdMob/Play policy:
- No accidental-click-inducing layouts; proper spacing.
- Ads clearly distinguishable from content; native ads properly labeled.
- No ads placed immediately above primary action buttons.
- Banner placement compliance.
- Rewarded ads are genuinely optional, never gating required functionality.
- No deceptive implementations.

Flag every potential violation found, with citation.

## Phase 12 — Mediation Audit

Verify:

- All configured mediation adapters are present and initialized.
- Adapter versions are compatible with the installed Google Mobile Ads SDK.
- Missing adapters are identified.
- Initialization status is inspected using MobileAds.instance.initializationStatus.
- Adapter-specific failures are distinguished from AdMob failures.
- Recommendations are provided for outdated adapters.

If mediation configuration cannot be verified from source code alone, state what must be checked in AdMob Console and during runtime.

---

## Screen Coverage — Single Consolidated Table

Rather than a separate prose write-up per screen, produce **one table** covering every screen with an ad placement (sourced from the lists gathered in Phases 2–3):

| Screen | Ad Type(s) | Placement | Load/Retry Behavior | Disposal | Policy Compliance | Notes/Issues |
|---|---|---|---|---|---|---|

Only break out narrative prose for a specific screen if it has a unique issue worth explaining beyond what the table conveys.

---

## Scoring Rubric

Both numeric scores below must be traceable to this rubric — not a holistic gut call.

**Per-phase weighting (100 points total):**

| Phase | Points |
|---|---|
| 1. Initialization | 8 |
| 2. Banner Ads | 8 |
| 3. Native Ads | 10 |
| 4. Interstitial Ads | 10 |
| 5. Rewarded Ads | 10 |
| 6. Remote Config | 8 |
| 7. Consent & Privacy | 14 |
| 8. Firebase Analytics | 8 |
| 9. Crashlytics | 6 |
| 10. Performance | 8 |
| 11. Policy Compliance | 10 |

Deduct points within each phase's allocation based on severity of findings (a single Critical bug in a phase should cost most of that phase's points; Low-severity findings cost proportionally little). State the deduction reasoning per phase in the Executive Summary.

Any unresolved **Critical** bug (per the Bugs Found severity scale) caps the overall production-readiness score at 59/100 regardless of other phases' performance — a single critical ad-serving or consent violation should not be averaged away by strong scores elsewhere.

---

## Deliverables

### 1. Executive Summary
Overall health score (0–100) per the rubric above, with a one-line justification per phase's point deduction (if any).

### 2. Architecture Review
Strengths, weaknesses, risk areas.

### 3. Screen Coverage Table
The single consolidated table specified above (not reproduced separately from Phases 2–3's findings).

### 4. Bugs Found
Severity (Critical/High/Medium/Low), File, Method, Description, Root Cause, Recommended Fix — for every issue found across all phases.

### 5. Performance Review
Summarizes Phase 10's findings only — memory, CPU/rebuilds, network, loading. No new investigation here.

### 6. Policy Compliance
Pass/Fail checklist per Phase 11's findings, with explanation for each Fail.

### 7. Code Quality
SOLID principles, separation of concerns, reusability, lifecycle management, error handling, logging, state management — evaluated against the ad-related code specifically.

### 8. Recommendations
Prioritized: Must Fix / Should Fix / Nice to Have. Every Must Fix item must trace back to a specific Critical or High bug from section 4.

### 9. Final Score
Per-category scores: Architecture, Stability, Performance, Policy Compliance, UX, Monetization Readiness, Maintainability. Overall production-readiness score out of 100, using the rubric above (including the Critical-bug cap rule). State clearly: **ready for release**, or **requires changes before deployment** — and if the latter, list exactly which Must Fix items are blocking.

---

## Verification

Run and paste the actual output (not a summary) of:
```bash
flutter analyze
flutter test
```
Plus: relevant debug logs for ad callbacks, error handling, and lifecycle events observed during manual testing — cite what was actually run and observed, not what should theoretically happen.
