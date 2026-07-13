# Feature: Default Country Pinning to Tab Bar (v2 — Implementation-Ready)

## Role

Act as a Senior Flutter Developer and Senior UX Designer working on Mortgage Pro Global.

Implement a Default Country Pinning feature that allows users to choose one preferred country from Settings. The selected country automatically appears next to the Global tab in the main navigation.

## Objective

Allow users to pin one frequently used country beside the Global tab for quicker access. Only one country — or none — may be pinned at any time.

---

## Current Behavior (confirmed against `home_screen.dart`)

- The main tab bar is fully static: `const _tabs = [Global, USA, Canada, UK, Australia, NZ, Europe, India]`, consumed by both the `TabBar` (`tabs: _tabs.map(...)`) and an 8-length `TabController`.
- Each country panel is a separate widget with its own `AutomaticKeepAliveClientMixin` and a stable per-country `PageStorageKey` (e.g. `PageStorageKey('canada')`) — this is good existing architecture and should be preserved/reused, not replaced.
- Tab taps are logged via `AnalyticsService.instance.logCountryTabTap(index)` — **by numeric index**, not by country. This is load-bearing for the fix below.
- No "Countries Default" settings section, toggle group, or pinning state currently exists anywhere in `home_screen.dart`. (Confirm same in the settings screen file before implementation — see Blocking Item below.)

---

## New Behavior

When the user selects a country in Settings → Default Country:

- That country becomes the pinned country.
- It immediately appears next to the Global tab in the main tab bar.
- All remaining tabs keep their existing relative order.
- No tab is duplicated, added, or removed.

**Example**

```
Before:  Global | USA | Canada | Europe | UK | Australia | India | New Zealand
User pins Canada.
After:   Global | Canada | USA | Europe | UK | Australia | India | New Zealand
User later pins Australia.
After:   Global | Australia | USA | Canada | Europe | UK | India | New Zealand
```

Only the pinned position changes — the rest of the list is the original fixed order with the pinned entry removed from its normal slot and reinserted after Global.

---

## Selection Model — Single-Select, With Explicit "No Default" State

**Resolved (previously ambiguous):** the exclusivity rule must support returning to an unpinned state, because the "Before" example in this spec depicts exactly that state. A pure radio-button group over the 7 countries cannot represent "none" without an explicit option for it.

**Decision:** the Settings list is a single-select list with **8 items**, not 7:

```
◉ No default (standard order)
○ USA
○ Canada
○ UK
○ Australia
○ New Zealand
○ Europe
○ India
```

- Selecting a country pins it and deselects whatever was previously selected (including "No default").
- Selecting "No default" unpins — the tab bar reverts to its original static order.
- This is the single-select list-tile UI recommended in v1 of this spec, made concrete with the missing "none" case included.

**Section header copy:** "Choose one default country for quick access, or leave unset for the standard order."

---

## Main Tab Bar — Single Source of Order (fixes the v1 gap)

**Resolved (previously missing):** v1 only specified reordering the `TabBar` labels. This omitted that the `TabBarView` children — the actual country panel widgets — must be reordered identically, or the tab label and its content will mismatch (e.g. "Canada" label showing the USA panel).

**Implementation requirement:** introduce one pure function that is the single source of truth for display order, consumed by both the `TabBar` and the `TabBarView`:

```dart
List<String> computeTabOrder({
  required List<String> baseOrder, // fixed: ['GLOBAL','USA','CA','UK','AU','NZ','EU','IN']
  required String? pinnedCountry,  // e.g. 'CA', or null for no pin
}) {
  if (pinnedCountry == null || !baseOrder.contains(pinnedCountry)) {
    return baseOrder;
  }
  final rest = baseOrder.where((c) => c != 'GLOBAL' && c != pinnedCountry).toList();
  return ['GLOBAL', pinnedCountry, ...rest];
}
```

- Both `_tabs` (labels) and the `TabBarView` `children` list must be built by mapping over the **same** `computeTabOrder(...)` result — never two independently maintained arrays.
- Each country panel widget keeps its existing `PageStorageKey`/`AutomaticKeepAliveClientMixin` — reordering position does not require rebuilding panel identity, since Flutter resolves keyed widgets by key, not by list index. This is why the existing per-country `PageStorageKey`s matter: they're what makes this reorder safe without state loss.
- Unit test `computeTabOrder`: no pin (returns base order unchanged), valid pin (moves correctly), pin value not in base order (defensive — falls back to base order rather than crashing), pin equal to `'GLOBAL'` (defensive — treated as invalid, falls back to base order).

### Current tab index / navigation behavior on reorder

**Resolved (previously unspecified):** if the user is on the Home screen when the pin changes (e.g. navigating back from Settings), the `TabController` snaps to index 0 (Global) rather than attempting to preserve "which country was I looking at" across a reorder. This is the simpler, unambiguous behavior and avoids needing to resolve a country-identity-to-new-index mapping on every settings change.

### Analytics — index no longer has fixed meaning

**Resolved (previously missing):** since tab order is now per-user, `logCountryTabTap(index)` alone is no longer comparable across users or sessions. Change the call site to also pass the resolved country code:

```dart
AnalyticsService.instance.logCountryTabTap(index, countryCode: _currentOrder[index]);
```

(Exact parameter naming should match whatever `AnalyticsService.logCountryTabTap` already accepts — if it can't be extended without touching the analytics service itself, that's a Non-Goal boundary question to flag before implementation, not something to work around silently.)

---

## Persistence

- Persist `pinnedCountry` (`String?`) through the existing `AppSettings` / `SettingsProvider` — no new provider or storage mechanism.
- `null` represents "No default" and is a valid, distinct, persisted state (not merely the absence of a key).
- Restore automatically on: app restart, resume from background, app reopen.
- Existing installs with no stored value read as `null` ("No default") — matches current static-order behavior, so this is a safe default with no migration needed.

---

## State Management

- Extend `SettingsProvider`'s existing model with `pinnedCountry`. No new provider.
- Widgets that depend on tab order (the `TabBar`/`TabBarView` builder) read via a scoped selector:
  ```dart
  final pinned = ref.watch(settingsProvider.select((s) => s.pinnedCountry));
  ```
  so that unrelated `AppSettings` field changes (theme, language, etc.) do not trigger a tab-bar rebuild.
- The Settings screen's selection list itself can watch the same selector to render its current selection state.

---

## Non-Goals

Do not:
- Change calculator logic or country-specific calculations.
- Change navigation routes.
- Change existing tab order beyond inserting/removing the pinned country beside Global.
- Allow more than one pinned country at a time.
- Introduce drag-and-drop tab customization.
- Modify `AnalyticsService`'s internal implementation beyond adding the country-code parameter to the existing tab-tap log call (if extending the signature isn't feasible without deeper analytics-service changes, flag this before implementation rather than improvising a workaround).

---

## Blocking Item Before Implementation

`settings_provider.dart` and the Settings/Countries-Default screen file have not yet been reviewed against this spec. Confirm before writing code:
- Real shape of `AppSettings` (so `pinnedCountry` is added consistently with existing fields, e.g. matching how `preferredCountry` or similar is already modeled).
- Whether a "Countries Default" toggle section already exists to be converted to single-select, or needs to be built new.
- The exact signature of `AnalyticsService.logCountryTabTap` (to confirm whether it can accept a country-code parameter without a breaking change elsewhere).

---

## Acceptance Criteria

- ✅ Settings presents a single-select list of 8 options (7 countries + "No default"); selecting one deselects any previous selection automatically, with no confirmation dialog.
- ✅ Selecting "No default" returns the tab bar to its original static order.
- ✅ The pinned country appears immediately after Global in the main tab bar; no tab is duplicated.
- ✅ `TabBar` labels and `TabBarView` content are always in agreement — verified by a widget test that pins a country and asserts the visible panel content (not just the label) matches.
- ✅ Remaining tab order (excluding Global and the pinned country) is unchanged from the original fixed order.
- ✅ Pinned selection persists across app restart and background/resume.
- ✅ `computeTabOrder` unit-tested for: no pin, valid pin, invalid/stale pin value, pin value of `'GLOBAL'`.
- ✅ Existing per-country `PageStorageKey`/`AutomaticKeepAliveClientMixin` state (scroll position, etc.) survives a reorder — verified manually or via widget test.
- ✅ Tab-tap analytics call includes country code, not index alone (or blocking item flagged if infeasible).
- ✅ Reordering the tab bar while on the Home screen resolves to Global (index 0), not a stale/mismatched index.
- ✅ Existing navigation, routing, and calculations remain unaffected.
- ✅ `flutter analyze` reports no new issues.
- ✅ Existing tests continue to pass; new tests (above) are added and passing.

---

## Manual Verification Checklist

1. Fresh install (no stored preference) → tab bar shows original static order, Settings shows "No default" selected.
2. Pin Canada → tab bar updates immediately, Canada tab shows the Canada panel (not USA's), scroll position/state in other panels is preserved.
3. Pin Australia while Canada was pinned → Canada auto-deselects, Australia appears in its place, no confirmation prompt.
4. Select "No default" → tab bar reverts to original order.
5. Kill app, reopen → pinned selection (or "No default") restored correctly.
6. Background/resume → selection unaffected.
7. Tap through several tabs after pinning → confirm analytics log includes the correct country code per tap, not just an index that no longer matches the label.
