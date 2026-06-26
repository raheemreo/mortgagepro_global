// lib/shared/models/saved_calc.dart

import 'package:hive_flutter/hive_flutter.dart';

part 'saved_calc.g.dart';

@HiveType(typeId: 0)
class SavedCalc extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String country;

  @HiveField(2)
  late String calcType;

  @HiveField(3)
  late Map<String, double> inputs;

  @HiveField(4)
  late Map<String, double> results;

  @HiveField(5)
  late String label;

  @HiveField(6)
  late DateTime savedAt;

  @HiveField(7)
  late String currencyCode;

  SavedCalc({
    required this.id,
    required this.country,
    required this.calcType,
    required this.inputs,
    required this.results,
    required this.label,
    required this.savedAt,
    required this.currencyCode,
  });

  factory SavedCalc.create({
    required String country,
    required String calcType,
    required Map<String, double> inputs,
    required Map<String, double> results,
    required String label,
    required String currencyCode,
  }) {
    return SavedCalc(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      country: country,
      calcType: calcType,
      inputs: inputs,
      results: results,
      label: label,
      savedAt: DateTime.now(),
      currencyCode: currencyCode,
    );
  }
}

// Fallback adapter (since we can't run build_runner in this flow)
// Run: dart run build_runner build --delete-conflicting-outputs
// to auto-generate saved_calc.g.dart

class SavedCalcAdapter extends TypeAdapter<SavedCalc> {
  @override
  final int typeId = 0;

  @override
  SavedCalc read(BinaryReader reader) {
    return SavedCalc(
      id: reader.read() as String,
      country: reader.read() as String,
      calcType: reader.read() as String,
      inputs: Map<String, double>.from(reader.read() as Map),
      results: Map<String, double>.from(reader.read() as Map),
      label: reader.read() as String,
      savedAt: DateTime.fromMillisecondsSinceEpoch(reader.read() as int),
      currencyCode: reader.read() as String,
    );
  }

  @override
  void write(BinaryWriter writer, SavedCalc obj) {
    writer.write(obj.id);
    writer.write(obj.country);
    writer.write(obj.calcType);
    writer.write(obj.inputs);
    writer.write(obj.results);
    writer.write(obj.label);
    writer.write(obj.savedAt.millisecondsSinceEpoch);
    writer.write(obj.currencyCode);
  }
}
