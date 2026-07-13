// lib/providers/calculator_draft_provider.dart
//
// PHASE-3: Riverpod provider for cross-calculator draft state.
//
// When a user completes a calculation and taps a workflow continuation card,
// the source calculator writes a CalculatorDraft here and the destination
// calculator reads it to pre-fill shared fields.
//
// Important: This provider is NOT persisted to disk. It is in-memory only
// (session-scoped). Workflow continuation is a within-session convenience
// feature, not a preference that should survive an app restart.
//
// Architecture note: This is Path B as resolved from Blocking Question B1
// in the v3 implementation plan — ToolLaunchArgs handles route-level args
// (country code, saved calc restore) and this provider handles cross-calc
// calculation value transfer. They are separate concerns.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calculator_draft.dart';

class CalculatorDraftNotifier extends StateNotifier<CalculatorDraft?> {
  CalculatorDraftNotifier() : super(null);

  /// Sets the current draft. Called by a calculator after a successful result.
  void setDraft(CalculatorDraft draft) {
    state = draft;
  }

  /// Clears the draft. Call this if the user explicitly dismisses the
  /// workflow continuation UI, or if the destination screen has been loaded.
  void clearDraft() {
    state = null;
  }
}

final calculatorDraftProvider =
    StateNotifierProvider<CalculatorDraftNotifier, CalculatorDraft?>((ref) {
  return CalculatorDraftNotifier();
});
