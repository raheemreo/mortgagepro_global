# MortgagePro Global — Native Ads Implementation Spec (v2)
**Scope:** All calculator screens across all 7 country modules (USA, Canada, UK, Australia, New Zealand, Europe [6 EU countries via `EuCountryData`], India)

**Ground rule:** This is an EXTENSION spec. Do not build a new ad system. Extend the existing `AdManager`, the existing native/banner fallback widgets (blank-space-prevention pattern already implemented), and the existing rewarded-ad-based ad-free session flow. If any instruction below conflicts with existing `AdManager` behavior, existing behavior wins unless explicitly told to change it.

---

## 1. Screen Eligibility

Native ads are permitted ONLY on:
- Results/summary screens (post-calculation)
- Amortization schedule / table screens
- Chart/visualization screens
- Country selector / comparison screens (chip-based EU selector included), between groups, never inline with chips

Native ads are explicitly FORBIDDEN on:
- Any input/form entry screen (fields still being edited)
- The ad-free session unlock dialog itself
- Any screen shown mid-calculation or mid-load
- Legal, privacy policy, settings, or onboarding screens
- Any screen where the primary CTA (Calculate, Reset, Submit, Continue, Save) is visible within one scroll-viewport of the ad slot

## 2. Ad-Free Session Gating (mandatory, checked first)

Before any native ad widget renders, check ad-free session state via `AdManager`:
- If an active ad-free session exists (granted via rewarded ad unlock), the ad container must not render at all — not collapsed, not loading, fully absent, and take up zero layout space.
- This check happens on every screen build/rebuild, not just on first load, since the ad-free timer can expire mid-session.
- When the ad-free session expires while a screen is open, native ad slots may reload on the next natural lifecycle event (screen re-entry or explicit refresh) — not by force-injecting an ad into an already-rendered screen.

## 3. Placement Density & Frequency Rules

- Maximum 1 native ad per screen for single-screen calculators (results screens).
- Maximum 1 native ad per 6–8 list items for scrollable content (amortization tables) — inserted as a genuine list item via `ListView.builder`, never as an overlay.
- Minimum 60 seconds between ad reloads on the same slot within a session.
- No two native ad slots visible in the same viewport at once, regardless of screen size.
- No native ad within 150 logical pixels of any primary CTA button.

## 4. Consent & Regional Compliance

- Before requesting any ad (AdMob or Meta) in UK, EU (all 6 `EuCountryData` countries), or Australia, verify UMP/consent status via the existing Firebase/consent integration.
- If consent is required and not yet given, do not request personalized ads — request non-personalized ads only, or skip the ad slot entirely if the network requires consent for any request.
- Consent check is per-country using the active `EuCountryData` selection, not a single global toggle — a user switching from Germany to France mid-session re-evaluates against that country's requirement if it differs.
- USA, Canada, India, New Zealand: standard AdMob/Meta default consent flow (existing implementation), no additional per-country branching needed unless a specific regional law is flagged later.

## 5. Fallback Chain (mediation-based — not manual dual-network requests)

Given the existing AdMob Mediation setup with Meta and InMobi adapters: fallback is handled by the AdMob Mediation waterfall, not by the app manually requesting Meta after an AdMob no-fill. Do not implement a manual "AdMob fails → call Meta SDK directly" chain — that duplicates what mediation already does and risks double requests/conflicting impressions.

1. Request a native ad through the AdMob Mediation entry point (the mediation-configured ad unit), not a network-specific SDK call. Timeout: 8 seconds.
2. Mediation internally waterfalls across configured networks (Meta, InMobi, AdMob demand). The app only sees: fill (with a network-agnostic native ad object) or final no-fill after mediation exhausts its waterfall.
3. On final no-fill (including `ERROR_CODE_NO_FILL` / error code 3 surfaced after the full waterfall) or timeout → collapse the ad container to zero height/width, no placeholder, no retry within this screen session.
4. Retry ceiling: max 1 retry of the mediation request per screen visit. No infinite retry loops.
5. Log every state transition (request start, fill + winning network if exposed by the mediation SDK, no-fill, timeout, collapse) through the existing logging setup — this directly supports the current MIUI `ERROR_CODE_NO_FILL` investigation, since you'll be able to see which network(s) in the waterfall actually failed.
6. **If native ad units are not yet added to the existing mediation configuration** (only banner/rewarded may be configured today), this is a prerequisite step: add native ad units to the AdMob mediation groups for Meta/InMobi before writing any fallback-handling code — otherwise the waterfall has nothing to fall back to.

## 5a. Error Handling — Additional Edge Cases

Beyond the fallback chain in Section 5, handle these failure modes explicitly so none leave stale UI or trigger a retry loop:

| Condition | Required behavior |
|---|---|
| Ad SDK fails to initialize (AdMob or mediation adapter) | Skip all ad requests for the session; collapse ad containers app-wide; do not retry initialization mid-session. |
| Network unavailable at request time | Skip the request immediately (don't wait for timeout); collapse container; retry only on next natural lifecycle event (screen re-entry), not on connectivity-restored callback. |
| Invalid/malformed native creative returned | Treat identically to no-fill — collapse, log, no crash. Never attempt to partially render an incomplete creative. |
| Activity/screen destroyed while ad is loading | Cancel the in-flight request and dispose any partial ad object; never assign the result to a widget that no longer exists in the tree. |
| App backgrounded while ad is loading | Cancel or ignore the in-flight result on background; re-request fresh (don't resume a stale in-flight request) if the screen is still active on foreground return. |

## 6. Native Ad Rendering Requirements

- Use a single reusable native ad widget (extend the existing one) that accepts either an AdMob `NativeAd` or Meta `NativeAd` object and renders a layout-compatible view for both — no separate widget trees per network.
- Required visible elements, never hidden or cropped: "Ad" label (always visible, high-contrast, top-left or top-right of the ad card), AdChoices/attribution icon, headline, body text (if present), media, CTA button, advertiser name.
- Ad card must be visually distinct (e.g. subtle border, background tint, or "Ad" tag) but follow the app's existing per-country design system tokens (colors/typography) rather than a mismatched generic style.
- No ad container may render before the ad has successfully loaded. Show nothing (zero space) while loading — no placeholder shimmer that reserves the eventual ad's exact dimensions, since this causes perceived-layout-shift complaints; only reserve space at the moment content is ready to paint.

### 6a. Native Ad Validator Compliance

Every native layout must pass AdMob's Native Ad Validator checks in production builds:
- All advertiser-provided assets (headline, media, icon, CTA, AdChoices) remain completely inside the `NativeAdView` bounding box — nothing rendered outside it via absolute positioning, negative margins, or transforms.
- `AdChoicesView` and the advertiser app icon are sized at least 32×32 dp.
- No overlay, translation, or clipping on required assets that could obscure them or trigger validator warnings, even partially or during animation/scroll.
- Run the Validator against every distinct native layout variant (results screen, table row, country comparison) before release, not just one representative screen — layouts differ enough across the 7 country modules that a pass on one doesn't guarantee a pass on all.

## 7. Lifecycle & State Management

- Ad load/dispose lifecycle is owned by the existing `AdManager`, driven by Riverpod providers already in use elsewhere in the app — no local `StatefulWidget` ad logic duplicated per screen.
- Dispose native ad objects (`nativeAd.dispose()` equivalent) on screen `dispose()`, on navigation away, and on app backgrounding beyond a defined threshold (reuse whatever threshold `AdManager` already applies to banners).
- Prevent duplicate concurrent requests for the same slot key (debounce or in-flight guard in `AdManager`).
- No ad reload triggered by widget rebuilds from unrelated state changes (e.g. theme toggle, locale change) — only by explicit lifecycle events (screen enter, ad-free session expiry, manual retry).

## 7a. Remote Config Integration (should-have, not blocking)

Using the existing Firebase Remote Config integration:
- A Remote Config key controls whether native ads are enabled globally (e.g. `native_ads_enabled: bool`). If false, no native ad requests are made anywhere, and all containers stay collapsed.
- Changes to this key take effect on next app foreground/config fetch — no app update required.
- Missing or invalid Remote Config values fall back to a safe default (ads enabled, matching current production behavior) rather than crashing or leaving an undefined state.
- This is an operational kill switch, not a per-screen or per-country toggle — keep it simple; granular control isn't required for this pass.

## 7b. Accessibility

- CTA button within the native ad card meets the same minimum touch-target size used elsewhere in the app.
- "Ad" label maintains sufficient contrast against its background per the app's existing design system tokens (don't introduce a new contrast standard just for ads).
- Ad content is exposed to screen readers as a distinct, clearly labeled region (e.g. semantic label "Advertisement") separate from surrounding app content, so assistive tech doesn't read it as part of the results/table content.
- Beyond the above, native ad internal accessibility (media descriptions, etc.) is controlled by the ad SDK's rendered view, not something the app can further customize — don't over-invest here.

## 8. Build & Testing

- Test ad unit IDs only in debug builds; production IDs gated behind release build config (already partially handled via existing `build.gradle.kts` setup — confirm the gate covers native ad units specifically, not just banner/rewarded).
- Verify native ad rendering on at least: one small phone, one tablet, one foldable/large-screen emulator, both portrait and landscape.
- Verify the MIUI no-fill case specifically against the new fallback chain (Section 5) as a regression check for the existing open bug.

## 9. Success Criteria (definition of done)

- [ ] No native ad renders during an active ad-free session, on any screen, across all 7 country modules.
- [ ] No native ad renders on any forbidden screen from Section 1.
- [ ] Fallback chain in Section 5 verified end-to-end with AdMob forced no-fill (test tool) triggering Meta fallback, and both forced no-fill triggering clean collapse.
- [ ] Consent gating verified for at least one EU country, UK, and Australia before any ad request fires.
- [ ] Zero layout shift confirmed visually (before/after screenshots) on results and table screens across phone + tablet.
- [ ] Firebase Analytics (existing integration) shows fill-rate/eCPM events tagged per country and per network, so results are measurable post-launch.
- [ ] No duplicate ad requests logged for a single slot in a single screen visit.
- [ ] Production build confirmed to use production ad unit IDs (manual release-build check, not just code review).
- [ ] Zero AdMob Native Ad Validator warnings (asset-outside-bounds, sub-32dp AdChoices/icon, or clipped required assets) across every distinct native layout variant used in the app.
- [ ] All Section 5a error-handling edge cases (SDK init failure, network unavailable, invalid creative, screen destroyed mid-load, backgrounded mid-load) manually triggered and confirmed to fail gracefully with no crash and no stale UI.
