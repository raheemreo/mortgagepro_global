// lib/providers/saved_tools_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

class SavedToolsNotifier extends StateNotifier<List<String>> {
  SavedToolsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('saved_tool_ids') ?? [];
  }

  Future<void> toggleFavorite(String toolId, {String itemType = 'calculator'}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(state);
    if (current.contains(toolId)) {
      current.remove(toolId);
    } else {
      current.add(toolId);
    }
    await prefs.setStringList('saved_tool_ids', current);
    state = current;
    AnalyticsService.instance.logFavoriteToggled(itemType: itemType);
  }

  Future<void> removeFavorite(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(state);
    if (current.contains(toolId)) {
      current.remove(toolId);
      await prefs.setStringList('saved_tool_ids', current);
      state = current;
    }
  }

  bool isFavorite(String toolId) {
    return state.contains(toolId);
  }
}

final savedToolsProvider =
    StateNotifierProvider<SavedToolsNotifier, List<String>>((ref) {
  return SavedToolsNotifier();
});
