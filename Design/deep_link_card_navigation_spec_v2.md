# MortgagePro Global — Deep-Link Card Navigation Spec (Canonical v2 — All 7 Countries)

## Objective

When a user taps any calculator/tool card from **Home**, **Global**, **Country Overview**, **Search
Results**, **Saved Items**, or **Recommended Tools**, the app must open the correct Country Screen
and land the user exactly on the matching tool card — not just at the top of the screen.

```
Tap Card → Open Correct Country → Scroll to Correct Tool Position → Highlight Tool → Ready to Use
```

This must behave identically across **Flutter (Android/iOS)** and the **HTML/web prototypes**, and
must survive back-navigation without resetting scroll position or losing context.

---

## 0. Pre-implementation finding: markup is inconsistent across the 7 country screens

Auditing the actual HTML prototypes for all 7 countries surfaced a split that must be resolved
**before** IDs are assigned, or the mapping table will be built on two incompatible foundations:

| Screen | Card class | Name class | Card count | Layout |
|---|---|---|---|---|
| Canada | `.tcard` | `.tname` | 8 | 1 grid, "Core Tools" |
| Australia | `.tcard` | `.tname` | 10 | 1 grid, "Core Tools" |
| UK | `.tcard` | `.tname` | 10 | 1 grid, "Core Tools" |
| Europe | `.tcard` | `.tname` | 10 | 1 grid, "Core Tools" + country picker pills |
| USA | `.tc` | `.tn` | 19 | 6 grids across 6 sections |
| New Zealand | `.tc` | `.tn` | 20 | 6 grids across 6 sections |
| India | `.tc` | `.tn` | 19 | 7 grids across 7 sections |

Two distinct generations of the same UI exist side-by-side:

- **CA/AU/UK/EU** — simpler, one "Core Tools" grid per screen (8–10 cards), single section.
- **USA/NZ/India** — richer, content-rich layout with cards spread across 6–7 thematically grouped
  sections (Loan Programs, Insurance & Tax, State-by-State Tools, Personal Finance, Govt Schemes,
  NRI Tools, etc.), using `.tc`/`.tn` instead of `.tcard`/`.tname`.

**Decision needed before §1 below can be finalized:** either (a) bring CA/AU/UK/EU up to the
richer USA/NZ/India pattern so all 7 screens share one markup convention, or (b) keep both
patterns but make the ID attribute itself convention-agnostic (an `id`/`Key` works on `.tcard` or
`.tc` identically — only the *visual* layout differs, not the addressability). Option (b) is the
pragmatic short-term path and is what the rest of this spec assumes; option (a) is the cleaner
long-term fix once all 7 screens are due for a visual pass anyway. Either way, **do not assign IDs
under the assumption that every screen has a single flat "Core Tools" grid** — USA/NZ/India do not,
and any card-counting or "Nth card in the grid" addressing scheme will break on those three.

---

## 1. Stable ID convention (single naming scheme)

Every tool card gets one global, unique ID. Convention: `{country_code}_{tool_slug}`.

For CA/AU/UK/EU (single "Core Tools" grid), the slug is just the tool name. For USA/NZ/India
(multi-section layout), prefix the slug with the section to avoid collisions where two sections
both have, e.g., an "Amortization" or "Affordability" card — see the full lists below.

### Canada (8 cards — Core Tools)
```
canada_mortgage_calc      canada_cmhc               canada_gds_tds
canada_stress_test        canada_affordability      canada_amortization
canada_renewal_planner    canada_prepayment_calc
```

### Australia (10 cards — Core Tools)
```
australia_mortgage_calc      australia_lmi                australia_offset
australia_dti                australia_affordability       australia_amortization
australia_stamp_duty         australia_refinance_tool      australia_extra_repayments
australia_construction_loan
```

### UK (10 cards — Core Tools)
```
uk_mortgage_calc      uk_stamp_duty_sdlt     uk_ltv_calc
uk_remortgage_tool     uk_affordability       uk_help_to_buy
uk_amortization        uk_buy_to_let          uk_income_multiples
uk_sdlt_calculator
```
Note: UK has two SDLT-related cards with distinct purposes — `uk_stamp_duty_sdlt` ("Stamp Duty
(SDLT)" / tax on purchase) and `uk_sdlt_calculator` ("SDLT Calculator" / 2nd home surcharge). Keep
them as separate IDs; don't collapse into one.

### Europe (10 cards — Core Tools, multi-country selector)
```
europe_mortgage_calc        europe_dti               europe_property_tax_calc
europe_affordability        europe_amortization      europe_euribor_tracker
europe_country_comparison   europe_notary_fee_calc   europe_non_resident_calc
europe_currency_converter
```
Europe also has a country-pill selector (Germany/France/Spain/Italy/Netherlands/Portugal) above the
grid. If/when those per-country views get their own card sets (e.g. Baufinanzierung-specific tools
under Germany), each gets its own sub-namespace: `europe_de_*`, `europe_fr_*`, `europe_es_*`, etc.
Not needed yet since today's cards are shared across the selector, but reserve the pattern now.

### USA (19 cards across 6 sections)
```
# Core Mortgage Tools
usa_core_piti_calculator       usa_core_mortgage_calc        usa_core_dti_calculator
usa_core_amortization          usa_core_affordability        usa_core_down_payment
usa_core_refinance_calc        usa_core_auto_loan

# Loan Programs
usa_loan_fha                   usa_loan_va                   usa_loan_usda
usa_loan_jumbo                 usa_loan_construction          usa_loan_arm

# Insurance & Tax
usa_insctax_pmi                usa_insctax_homeowner_ins     usa_insctax_flood_ins
usa_insctax_property_tax       usa_insctax_closing_costs     usa_insctax_hoa_fee_impact

# State-by-State Tools
usa_state_california            usa_state_texas               usa_state_new_york
usa_state_florida               usa_state_illinois            usa_state_all_states

# Personal Finance
usa_pf_credit_score_impact      usa_pf_heloc                  usa_pf_home_equity_loan
usa_pf_debt_payoff_planner      usa_pf_student_loan_dti       usa_pf_tax_deduction_calc
usa_pf_moving_cost_calc         usa_pf_rent_vs_buy

# Real Estate Investment
usa_invest_rental_yield_calc    usa_invest_cash_on_cash       usa_invest_fix_and_flip
usa_invest_1031_exchange
```

### New Zealand (20 cards across 6 sections)
```
# Core Home Loan Tools
nz_core_mortgage_calc          nz_core_repayment_calc        nz_core_dti_calculator
nz_core_amortization           nz_core_affordability_calc    nz_core_refixing_calc
nz_core_extra_repayments       nz_core_car_loan_calc

# LVR Restrictions
nz_lvr_calculator              nz_lvr_deposit_builder        nz_lvr_band_tool
nz_lvr_low_equity_margin

# KiwiSaver
nz_kiwisaver_calc              nz_kiwisaver_homestart_grant   nz_kiwisaver_balance
nz_kiwisaver_employer_contrib

# First Home Buyer Tools
nz_fhb_first_home_buyer        nz_fhb_deposit_calc           nz_fhb_preapproval_guide
nz_fhb_solicitor_costs

# Tax & Investment Tools
nz_tax_rental_yield_calc       nz_tax_ring_fencing_rules     nz_tax_bright_line_test
nz_tax_investment_property     nz_tax_interest_deductibility nz_tax_nzx_investor_calc

# Personal Finance
nz_pf_credit_score             nz_pf_revolving_credit        nz_pf_debt_consolidation
nz_pf_income_tax_calc          nz_pf_refinance_calc          nz_pf_construction_loan
nz_pf_budget_planner
```

### India (19 cards across 7 sections)
```
# Core Home Loan Tools
india_core_emi_calculator       india_core_amortization        india_core_loan_eligibility
india_core_prepayment_calc      india_core_balance_transfer    india_core_foir_calculator
india_core_under_construction   india_core_joint_loan_calc     india_core_floating_vs_fixed
india_core_car_loan_emi

# Govt. Housing Schemes
india_govt_stamp_duty_calc      india_govt_gst_calculator       india_govt_pmay_subsidy
india_govt_section_80c          india_govt_section_24b          india_govt_rera_compliance
india_govt_cibil_score_impact   india_govt_first_home_buyer    india_govt_tds_on_property
india_govt_capital_gains_tax

# Personal Finance
india_pf_personal_loan_emi      india_pf_education_loan        india_pf_ppf_calculator
india_pf_epf_calculator         india_pf_sip_calculator        india_pf_nps_calculator
india_pf_income_tax_calc        india_pf_gold_loan_calc         india_pf_lap_calculator
india_pf_ai_advisor

# Stamp Duty by State
india_state_maharashtra         india_state_delhi              india_state_karnataka
india_state_tamil_nadu          india_state_telangana          india_state_all_states

# NRI Home Loan Tools
india_nri_home_loan             india_nri_account               india_nri_fema_compliance
india_nri_usd_inr_converter
```
Note: India's section labels repeat `fu7` as a CSS animation class for two different sections
("City Property Prices" and "Stamp Duty by State") — purely a styling artifact, not a card-naming
issue, but flag it for whoever touches that screen next so the duplicate isn't mistaken for a bug
in the ID scheme itself.

Extend the same pattern for any future countries.

### HTML prototypes
```html
<div id="canada_cmhc" class="tcard">...</div>
<div id="usa_loan_fha" class="tc">...</div>
```

### Flutter
IDs aren't DOM elements, so each tool card widget gets a matching `Key` instead:
```dart
const Key kCanadaCmhc = Key('canada_cmhc');
const Key kUsaLoanFha = Key('usa_loan_fha');
// ...
Container(key: kCanadaCmhc, child: ToolCard(...))
```

---

## 2. Shared ID-mapping table (single source of truth)

One file, imported everywhere — HTML prototypes, search index, saved-items storage, and the Flutter
app all read from this. Nothing hardcodes a target ID inline without it being registered here first.

With 86 cards across 7 countries (see §1's full lists), this map is too large to maintain by hand in
two places — generate `tool_id_map.json` once from the §1 lists above and treat it as the single
build artifact every layer imports. Representative excerpt:

```json
{
  "canada_cmhc":            { "country": "canada", "section": "core", "label": "CMHC Insurance" },
  "canada_stress_test":     { "country": "canada", "section": "core", "label": "Stress Test Calc" },

  "australia_offset":       { "country": "australia", "section": "core", "label": "Offset Account" },
  "australia_lmi":          { "country": "australia", "section": "core", "label": "LMI Calculator" },

  "uk_stamp_duty_sdlt":     { "country": "uk", "section": "core", "label": "Stamp Duty (SDLT)" },
  "uk_sdlt_calculator":     { "country": "uk", "section": "core", "label": "SDLT Calculator" },

  "usa_loan_fha":           { "country": "usa", "section": "loan_programs", "label": "FHA Loan Calc" },
  "usa_state_california":  { "country": "usa", "section": "state_tools", "label": "California" },

  "nz_kiwisaver_calc":      { "country": "nz", "section": "kiwisaver", "label": "KiwiSaver Calc" },

  "india_govt_pmay_subsidy":{ "country": "india", "section": "govt_schemes", "label": "PMAY Subsidy" }
}
```

Note the added `"section"` field for the multi-section countries (USA/NZ/India) — the navigation
function needs this to know *which* grid to scroll within when a screen has 6–7 stacked sections,
not just which screen to open.

Add a **build-time check** (lint script or test) that walks every `data-target` / `toolId` reference
in the codebase and confirms it exists as a key in this map. A typo or renamed card should fail CI,
not surface as a silent broken link in production.

---

## 3. Universal navigation function

One function, called identically from every source surface (Home, Global, Search, Saved,
Recommended):

```
navigateToTool(countryId, toolId)
```

```js
navigateToTool('canada', 'canada_cmhc');
navigateToTool('australia', 'australia_offset');
```

### Responsibilities (same logic, two runtimes)

| Step | HTML / Web | Flutter |
|---|---|---|
| 1. Open country screen | swap `.page` visibility / route | `Navigator.push` with `toolId` as route argument |
| 2. Wait for render | next frame (`requestAnimationFrame`, only if needed) | `addPostFrameCallback` after `initState` |
| 3. Locate target card | `document.getElementById(toolId)` | look up `Key`/`GlobalKey` from the shared map |
| 4. Scroll | `element.scrollIntoView({behavior:'smooth', block:'start'})` | `Scrollable.ensureVisible(context, duration: 300ms, alignment: 0.15)` |
| 5. Header offset | CSS `scroll-margin-top: 90px;` on every `.tcard` | add top padding equal to header height when computing `alignment`, or wrap target in a `Padding` that accounts for the sticky `AppBar`/filter bar height |
| 6. Highlight | add `.card-focus` class, animate, remove after 2s | animate a `Border`/`BoxShadow` via `AnimationController` (300ms in / 1.4s hold / 300ms out ≈ 2s total), then clear |

If `toolId` is null/absent (opened via bottom-nav, region pill, etc.), skip steps 3–6 entirely —
default to top-of-screen, no highlight, exactly as today.

### Multi-section screens (USA / NZ / India) need one extra consideration

Because these three screens stack 6–7 sections vertically (Core Tools, Loan Programs, State Tools,
Personal Finance, etc.), a target card several sections down can be a long scroll from the top.
Use the `"section"` field from the mapping table to jump near the right section first (e.g. via an
in-page section anchor or a Flutter `ScrollController.jumpTo` estimate based on section order), then
do the fine-grained `scrollIntoView` / `ensureVisible` to the exact card — rather than relying on a
single long animated scroll from y=0, which feels sluggish on a 19-card screen and risks overshooting
on slower devices. CA/AU/UK/EU don't need this since they have only one grid.

---

## 4. Card highlight animation

**Web/HTML:**
```css
.tcard { scroll-margin-top: 90px; }

.card-focus { animation: cardFocus 2s ease; }

@keyframes cardFocus {
  0%   { transform: scale(1);    box-shadow: 0 0 0 rgba(59,130,246,0); }
  50%  { transform: scale(1.02); box-shadow: 0 0 24px rgba(59,130,246,.35); }
  100% { transform: scale(1);    box-shadow: none; }
}
```
```js
target.classList.add('card-focus');
setTimeout(() => target.classList.remove('card-focus'), 2000);
```

**Flutter** — equivalent via `AnimatedContainer` or `AnimationController` driving `BoxShadow` +
`Transform.scale`, same 2-second envelope, same easing curve (`Curves.easeInOut`). Must look and
feel identical to the web version, not just functionally equivalent.

Highlight color/contrast must pass WCAG AA in **both** light and dark themes — don't reuse a single
hardcoded shadow color; pull from the theme's accent token.

---

## 5. Source surface integration

Every source surface stores or carries `{ countryId, toolId }` and calls `navigateToTool` — no
surface gets its own bespoke logic.

- **Home Screen** — Top Tools grid cards: `data-country` + `data-target` (web) / `(countryId,
  toolId)` passed to `onTap` (Flutter). Mortgage Calculator → that country's Mortgage Calc card,
  Affordability → that country's Affordability card, Refinancing → Refinance card, Amortization →
  Amortization card, Rate Comparison → Rate Comparison card. No Home card should ever land on the
  wrong position.
- **Global Screen** — country cards preserve context: tapping "Canada → Stress Test" opens Canada
  scrolled to `canada_stress_test`, never the top of the page.
- **Country Overview Cards** — same mechanism for any cross-country link (e.g. "Compare to
  Canada" inside the Australia screen).
- **Search Results** — each result stores `{ countryId, toolId }` at index time; tapping a result
  calls `navigateToTool(countryId, toolId)` directly, no re-derivation from the label string.
- **Saved Items** — same `{ countryId, toolId }` pair persisted with the saved entry; reopening a
  saved calculator returns the user directly to that exact card, not the country screen's top.
- **Recommended Tools** — same contract as Home.

---

## 6. Back-navigation behavior

- Back returns to the *previous* screen state, not a fresh reload.
- Scroll position on the screen the user came from is preserved (don't reset to top).
- Selected country/tab context is preserved.
- The destination card's highlight state should **not** replay on back — it only plays once, on
  arrival via deep link.
- Flutter: rely on `Navigator`'s default state preservation (`AutomaticKeepAliveClientMixin` on the
  scrollable country screen) rather than rebuilding the screen from scratch on pop.

---

## 7. Error handling

If `toolId` doesn't resolve to a real card (stale saved item, renamed tool, bad search index entry):

1. Still open the correct country screen.
2. Scroll to the top of the tools section (not a hard crash, not a blank screen).
3. Show a small inline fallback message: *"Tool not found. Showing available calculators."*
4. Log the bad `toolId` (so it surfaces in analytics/crash reporting rather than silently recurring).

The app must never crash on a missing target.

---

## 8. Performance & cross-platform requirements

- No double-scroll, no flicker, no duplicate navigation triggers — debounce the tap handler or
  disable the source card while the transition is in flight.
- No race condition between "screen finished building" and "scroll to target" — always gate the
  scroll behind the post-render callback (step 2 in the table above), never a fixed arbitrary
  `setTimeout` guess.
- Works on Android, iOS, and Web.
- Works in light and dark themes.
- Identical behavior and timing across all three.

---

## 9. Accessibility

- Screen reader announces the destination tool name on arrival (e.g. via `SemanticsService.announce`
  in Flutter, or an `aria-live` region update on web).
- Focus moves to the target card programmatically, not just visually scrolled into view.
- Full keyboard navigation support on web (tab order lands logically on/after the target card).
- Highlight contrast meets WCAG AA in both themes (see §4).

---

## Acceptance criteria

- [ ] Markup divergence between CA/AU/UK/EU (`.tcard`/`.tname`) and USA/NZ/India (`.tc`/`.tn`) is
      explicitly decided on (§0) before ID assignment begins — not silently worked around.
- [ ] Every tool card across all 7 country screens (86 cards total) has a stable ID following
      `{country}_{tool_slug}`, with `{section}_` prefixes for USA/NZ/India per §1.
- [ ] One generated `tool_id_map.json` is the single source of truth, including a `section` field
      for the 3 multi-section countries; a build-time check fails if any `toolId` reference doesn't
      resolve to a real entry.
- [ ] `navigateToTool(countryId, toolId)` is the only entry point used by Home, Global, Country
      Overview, Search, Saved, and Recommended — no surface has bespoke navigation logic.
- [ ] Tapping a source card opens the correct country screen, scrolls to the exact card (offset
      below sticky headers, section-aware for USA/NZ/India per §3), and briefly highlights it — in
      both Flutter and HTML prototypes, with matching timing/feel.
- [ ] Opening a country screen with no target (bottom nav, region pill) behaves exactly as today.
- [ ] Back navigation preserves scroll position and context; highlight does not replay.
- [ ] Missing/stale `toolId` falls back gracefully with a visible message — never crashes.
- [ ] Behavior is verified on Android, iOS, and Web, in both light and dark themes.
- [ ] Screen reader announces the destination and focus moves to the target card.
