// lib/core/utils/compat.dart

import 'dart:math' as math;
import 'package:intl/intl.dart';

class Math {
  static int round(num value) => value.round();
  static double log(num value) => math.log(value);
  static double pow(num x, num y) => math.pow(x, y).toDouble();
  static double min(num x, num y) => math.min(x, y).toDouble();
  static double max(num x, num y) => math.max(x, y).toDouble();
}

class Compat {
  static int round(num value) => value.round();
}

extension NumLocaleString on num {
  String toLocaleString() {
    return NumberFormat.decimalPattern('en_IN').format(this);
  }
}

