# Mortgage Pro Global — UX Improvement Implementation Plan (v3)

## Summary

Implement the UX improvement spec (`mortgagepro-ux-spec-v2.md`) in three phases, with two hard blockers resolved *before* Phase 3 begins (see "Blocking Questions" below) and dead/unwired fields removed from Phase 2.

- **Phase 1** — Fix text color defaults & minimum sizes in `text_styles.dart`
- **Phase 2** — Persistent user preferences (country, region, EU country, calculator tab, theme, language, currency)
- **Phase 3** — Calculator workflow continuity ("Continue Your Mortgage Planning") — **blocked pending verification below**

Plus Requirement 4 (context preservation), 5 (accessibility), 6 (performance), 7 (architecture adherence) — each now has a concrete proposal, not just a checklist mention.

---

## Blocking Questions — Resolve Before Writing Phase 3 Code

### B1. Does `SavedCalc` / `ToolLaunchArgs` already do what `CalculatorDraft` would do?

Not yet verified against source. Upload `ToolLaunchArgs.dart`, `SavedCalc.dart` (or wherever they live) plus the GoRouter route table before Phase 3 starts. This determines which path below applies:

- **Path A — reuse existing infra.** If `ToolLaunchArgs` already carries calculation values (loan amount, property price, etc.) across screens, extend it instead of introducing `CalculatorDraftProvider`. This is the Requirement 7–compliant choice — one state-passing mechanism, not two.
- **Path B — new provider justified.** If `ToolLaunchArgs` is scoped only to route-level arguments (e.g., country code) and has no general calculation-value payload, `CalculatorDraftProvider` as originally proposed stands, but should be named/structured to make clear it's a distinct concern from `ToolLaunchArgs`, not a competing duplicate.

Do not start Phase 3 implementation until this is answered.

### B2. Are the per-country tool route slugs real?

The tool-relevance map (`'sdlt'`, `'stress-test'`, `'gds-tds'`, `'lmi'`, `'notary-fee'`, `'foir'`, `'kiwisaver'`, etc.) was drafted as plausible route identifiers, not confirmed against the actual `go_router` route table. An unmatched slug fails at runtime (`context.push(...)` throw), not at compile time. Verify every slug against the real route table before Phase 3 ships.

### B3. Does a `dark_mode` bool legacy key actually exist in `settings_provider.dart`?

The Phase 2 test plan mentions a migration test for "old `dark_mode` bool key." Confirm this key is real before writing that test — if it isn't, drop the test case rather than covering a migration path that doesn't exist.

---

## Audit Findings (Current State)

### Phase 1 — Text Styles
- `AppTextStyles.playfair()` defaults to `color: Colors.white`; `AppTextStyles.dmSans()` defaults to `color: Colors.black`. Both are **static methods with no `BuildContext` parameter**, which matters for the decision below.
- Sub-11sp styles: `rateNote` (8), `heroTag` (9), `inputLabel` (8.5), `badgeText` (8.5), `cardDesc` (9.5), `rateLabel` (8), `headerSub` (10).
- No `InputDecorationTheme` in `app_theme.dart`.

### Phase 2 — Persistence
- `SettingsNotifier` already uses `shared_preferences` and persists: `theme_mode`, `default_term`, `default_deposit`, `preferred_country`, `preferred_currency`, `privacy_choices_opt_out`.
- Since `preferred_country` already has a default at construction, first-run is **not** an empty-state problem — no locale inference is needed (see Phase 2 changes below).
- Missing persisted values per spec: `region`, `selectedEuropeCountry`, `preferredCalculatorTab`.

### Phase 3 — Workflow Continuity
- No "Continue Your Mortgage Planning" UI anywhere.
- Calculator results are shown as `ModalBottomSheet` (see `USAMortgageCalcSheet`).
- Cross-screen value-passing mechanism: **see Blocking Question B1** — do not assume a new provider is needed.

---

## Resolved Decisions (Changed from v2 of this plan)

| Item | v2 plan | v3 decision | Why |
|---|---|---|---|
| Font sizes | Blanket-raise all sub-11sp styles to 11sp | Audit each style individually; raise only where genuinely hard to read; document exceptions inline (e.g. `// EXCEPTION: badge counter, deliberate micro-label`) | Original spec always allowed documented exceptions — the plan dropped that clause. `badgeText`/`rateLabel`/`heroTag` are plausible legitimate exceptions. |
| Country default on first run | Guess from device locale if no saved value | Restore saved preference if present; otherwise keep the existing static default. Never infer from locale. | `preferred_country` already has a non-null default per the audit, so there's no true empty state to solve for. Locale-guessing also risks wrong-country friction (e.g. India-based user doing US mortgages). |
| `recentlyUsedCalculators` | Added to model + tested, no call site | **Cut from Phase 2 entirely.** Revisit only as an explicit, separately-scoped requirement if there's a product reason for it. | Field was modeled and unit-tested but nothing in the plan ever calls `addRecentCalculator()`. Not core to the original tester feedback ("remember my country") — don't ship dead state. |
| `preferredCalculatorTab` | Ambiguous — resolved to interpretation (a) in prose, but implemented as (b) in code | **Interpretation (b), explicit call site.** Each country dashboard's tool-tap handler calls `setCalculatorTab(country, toolId)`. | (a) is redundant with the already-persisted `preferred_country` field. (b) is what the original spec table actually asked for ("last-viewed calculator tab within that country's dashboard") and is the only interpretation that makes the field non-dead. |
| `color` param on `playfair()`/`dmSans()` | Make required, unconditionally | **Measure first** — see Phase 1 decision tree below | Optional-with-fallback isn't free either: both methods are static with no `BuildContext`, so `color ?? Theme.of(context).colorScheme.onSurface` requires adding a `BuildContext` param regardless — that's its own signature change touching every call site. The real question is call-site count, not which approach sounds less invasive. |
| In-progress input persistence ("Loan Amount → Back → still there") | Implicitly folded into Phase 3 | **Split out as a new, optional Requirement 8** (below) — not tester-reported, needs its own sign-off before scoping | Different feature from cross-calculator value passing. Silently expanding Phase 3 scope risks the same "modeled but unwired" pattern already found twice in this plan. |

---

## Phase 1 — Text Style Fixes

### Decision tree for `color` on `playfair()`/`dmSans()`

Run before writing any Phase 1 code:

```bash
grep -rn "AppTextStyles.playfair(" lib/ | grep -v "color:"
grep -rn "AppTextStyles.dmSans(" lib/ | grep -v "color:"
```

- **If combined count is roughly < 20 call sites:** make `color` a required named parameter on both methods. Compile errors surface every affected site — fix each to pass `theme.getTextColor(context)` or `theme.getMutedColor(context)`. This is the compile-time-safe outcome and the original spec's intent.
- **If count is high (≈20+):** required-param churn is real. As a scoped alternative, add an explicit `BuildContext context` parameter (not optional) to both methods and default `color` via `color ?? Theme.of(context).colorScheme.onSurface` — but note this *still* touches every call site to pass `context`, so it does not avoid the churn, it only avoids a hard compile break at each site (call sites silently get a theme-correct color instead of a compile error). Choose this path only if minimizing merge conflicts matters more than compile-time enforcement.

Either way, first check whether most call sites already route through the safe named helpers (`headerTitle`, `cardTitle`, `cardDesc`, etc.) which already require `color` — if so, the raw-method call-site count may be much smaller than it looks from a first grep.

#### [MODIFY] `text_styles.dart`
- Apply the decision above.
- Audit each sub-11sp style individually — raise only where genuinely low-readability; document exceptions inline for the rest.

#### [MODIFY] `app_theme.dart`
- Add explicit `InputDecorationTheme` to `AppTheme.light()` with AA-compliant hint/disabled colors.

#### [NEW] `test/theme/wcag_contrast_test.dart`
- Unit test computing WCAG contrast ratio for every `CountryTheme.mutedColor` against its `cardColor` and `backgroundColor`. Fails build below 4.5:1.

---

## Phase 2 — Persistent Preferences

#### [MODIFY] `settings_provider.dart`
- Extend `AppSettings` with:
  - `region` (`String?`)
  - `selectedEuropeCountry` (`String?`)
  - `preferredCalculatorTab` (`Map<String, String>` — keyed by country code, so each country remembers its own last-viewed tab independently)
- Add setters: `setRegion`, `setEuropeCountry`, `setCalculatorTab(String country, String toolId)`.
- **Explicit call site**: each country dashboard's tool-tap handler calls `setCalculatorTab(currentCountry, toolId)` on navigation into a calculator.
- All reads have safe defaults; all writes are fire-and-forget.
- `country` restores from saved value if present; otherwise keeps existing static default. No locale inference.
- `language` and MRU list: **not included in this phase** (language deferred pending confirmation it's still wanted; MRU cut per decision above).

#### [NEW] `test/providers/settings_provider_test.dart`
- Persistence round-trip for `region`, `selectedEuropeCountry`, `preferredCalculatorTab`.
- Safe defaults on missing keys.
- **Only include the `dark_mode` legacy migration test if B3 confirms the key exists.**

---

## Phase 3 — Calculator Workflow Continuity

**Do not begin until B1 and B2 are resolved.**

Once resolved, proceed per Path A or Path B from B1:

#### [Path-dependent] Draft/value-passing mechanism
- Path A: extend `ToolLaunchArgs` with the fields needed (loan amount, property price, interest rate, loan term, country, currency, down payment).
- Path B: `lib/models/calculator_draft.dart` (immutable, `copyWith`) + `lib/providers/calculator_draft_provider.dart`, named/scoped to avoid confusion with `ToolLaunchArgs`.

#### [NEW] `lib/shared/widgets/workflow_continuation_card.dart`
- Horizontal-scroll card row titled "Continue Your Mortgage Planning."
- Cards show calculator name, what data is reused, navigate via `context.push(...)`.
- Per-country tool map — **slugs verified against real route table per B2** before use:
  ```dart
  static const Map<String, List<String>> _countryTools = {
    'USA': [/* verified slugs */],
    'UK':  [/* verified slugs */],
    'CA':  [/* verified slugs */],
    'AU':  [/* verified slugs */],
    'EU':  [/* verified slugs */],
    'IN':  [/* verified slugs */],
    'NZ':  [/* verified slugs */],
  };
  ```

#### [MODIFY] Country calculator result sheets
- After calculation, write draft values via the Path A/B mechanism.
- Embed `WorkflowContinuationCard` at bottom of result sheet, filtered to active country.
- Do not overwrite destination calculator fields with existing user input.

#### [NEW] `test/widgets/workflow_continuation_test.dart`
- Country-tool filtering for USA, UK, one EU country.
- Pre-fill does not overwrite existing user edits.

---

## Requirement 8 (New, Optional) — Persist In-Progress Calculator Input

Not part of the original tester feedback — split out here rather than folded into Phase 3 so it gets an explicit go/no-go decision.

**Behavior**: user types Loan Amount → navigates back → returns → value still present.

**Scope if approved**: per-screen local draft autosave (e.g. to `shared_preferences` keyed by screen+field, or in-memory only if navigation stack is preserved — needs a decision on how far "still there" should survive, e.g. across app kill or only within-session).

**Status**: hold for explicit approval before scoping further — do not implement alongside Phase 3.

---

## Requirement 6 — Performance (concrete proposal, not just a checklist item)

- `calculator_draft_provider.dart` (if Path B) or the extended `ToolLaunchArgs` (if Path A): consumers use `ref.watch(provider.select((d) => d.someField))` rather than watching the whole object, so unrelated field changes don't trigger full-card rebuilds.
- `WorkflowContinuationCard` built with `const` constructors for static sub-elements (icons, labels); only the data-bound parts rebuild.
- Verify via Flutter DevTools frame chart on the result sheet before/after Phase 3, comparing against baseline — add this as an explicit manual verification step (see below), not just a code-quality aspiration.

## Requirement 7 — Architecture / Ad-Trigger Verification (concrete proposal)

- Enumerate existing ad trigger call sites (rewarded/interstitial) before Phase 3 changes — a short list of file:line references, gathered via `grep -rn "showInterstitial\|showRewarded" lib/` or equivalent.
- After Phase 3, re-run the same grep and diff the call site list — confirms no trigger was accidentally removed or duplicated by new navigation paths.
- If no existing automated ad-trigger test harness exists, this remains a manual QA checklist item — state that explicitly rather than implying automated coverage.

---

## Verification Plan

### Automated Tests
```bash
flutter analyze
flutter test test/theme/wcag_contrast_test.dart
flutter test test/providers/settings_provider_test.dart
flutter test test/widgets/workflow_continuation_test.dart   # Phase 3 only, post-blockers
flutter test
```

### Manual Verification
1. **Phase 1**: Toggle light mode. Confirm all text is readable (no white-on-white or black-on-black).
2. **Phase 2**: Select Canada → navigate to USA → navigate back → confirm Canada still active. Kill app → reopen → confirm Canada still active. Confirm `preferredCalculatorTab` restores the last-viewed tool per country independently.
3. **Phase 3** (post-blocker resolution): Open USA Mortgage Calculator → calculate → confirm "Continue Your Mortgage Planning" cards appear → tap a suggested tool → confirm the route resolves (no crash) and shared fields are pre-filled → edit a field → confirm edit sticks.
4. **Ad triggers**: diff the ad-trigger call site list (Req 7) before/after Phase 3.
5. **Performance**: DevTools frame chart comparison on the result sheet, Phase 3 before/after.
6. **Build**: `flutter build apk --debug` — confirm no errors.

---

## Phasing Summary

| Phase | Risk | Status | Files Changed |
|---|---|---|---|
| 1 (text) | Medium — churn depends on grep count | Ready to start | `text_styles.dart`, `app_theme.dart`, call sites per decision tree, 1 new test |
| 2 (persist) | Low | Ready to start | `settings_provider.dart`, 1 new test |
| 3 (workflow) | Highest | **Blocked on B1 + B2** | Path-dependent — see above |
| 8 (in-progress input) | N/A | **Awaiting approval** — not scoped yet | TBD |
