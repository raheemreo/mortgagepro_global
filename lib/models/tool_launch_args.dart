// lib/models/tool_launch_args.dart
// Typed container for the GoRouter `extra` parameter on /tool/:country/:toolId.
//
// Use [ToolLaunchArgs.forSavedCalc] when opening a tool from Saved Calcs.
// Use [ToolLaunchArgs.forCountry]  when opening a tool from a country screen
// that wants to pre-select a specific country inside the tool.

import '../shared/models/saved_calc.dart';

class ToolLaunchArgs {
  /// Populated when the tool is launched from the Saved Calcs screen.
  final SavedCalc? savedCalc;

  /// Two-letter country code (e.g. 'FR') passed from the Europe screen so the
  /// tool opens pre-selected to the country the user was already viewing.
  final String? initialCountry;

  const ToolLaunchArgs({
    this.savedCalc,
    this.initialCountry,
  });

  /// Convenience constructor for launching from Saved Calcs.
  const ToolLaunchArgs.forSavedCalc(SavedCalc calc)
      : savedCalc = calc,
        initialCountry = null;

  /// Convenience constructor for launching with a country pre-selection.
  const ToolLaunchArgs.forCountry(String code)
      : savedCalc = null,
        initialCountry = code;

  @override
  String toString() =>
      'ToolLaunchArgs(savedCalc: $savedCalc, initialCountry: $initialCountry)';
}
