// lib/core/utils/tab_order_helper.dart

/// Computes the active display order for the dashboard tabs.
///
/// If [pinnedCountry] is provided and matches a country in [baseOrder] (excluding 'GLOBAL'),
/// it will be moved immediately next to the 'GLOBAL' tab (index 1).
/// All remaining tabs keep their relative default order.
List<String> computeTabOrder({
  required List<String> baseOrder,
  required String? pinnedCountry,
}) {
  if (pinnedCountry == null ||
      pinnedCountry == 'GLOBAL' ||
      !baseOrder.contains(pinnedCountry)) {
    return baseOrder;
  }
  final rest = baseOrder.where((c) => c != 'GLOBAL' && c != pinnedCountry).toList();
  return ['GLOBAL', pinnedCountry, ...rest];
}
