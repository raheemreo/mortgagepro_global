// lib/providers/saved_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../shared/models/saved_calc.dart';

class SavedCalcsNotifier extends StateNotifier<List<SavedCalc>> {
  SavedCalcsNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<SavedCalc>('saved_calcs');
    state = box.values.toList().reversed.toList();
  }

  Future<void> save(SavedCalc calc) async {
    final box = Hive.box<SavedCalc>('saved_calcs');
    await box.put(calc.id, calc);
    _load();
  }

  Future<void> delete(String id) async {
    final box = Hive.box<SavedCalc>('saved_calcs');
    await box.delete(id);
    _load();
  }

  Future<void> clearAll() async {
    final box = Hive.box<SavedCalc>('saved_calcs');
    await box.clear();
    state = [];
  }

  List<SavedCalc> byCountry(String country) {
    return state
        .where((c) => c.country.toLowerCase() == country.toLowerCase())
        .toList();
  }
}

final savedProvider =
    StateNotifierProvider<SavedCalcsNotifier, List<SavedCalc>>((ref) {
  return SavedCalcsNotifier();
});
