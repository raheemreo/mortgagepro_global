// lib/shared/widgets/result_panel.dart
// Calculation result display panel

import 'package:flutter/material.dart';
import '../../app/theme/text_styles.dart';
import '../../core/utils/currency_formatter.dart';

class ResultRow {
  final String label;
  final double value;
  final String currencyCode;
  final bool isHighlighted;
  final bool isPercent;
  final bool isYears;
  final String? customValue;

  const ResultRow({
    required this.label,
    required this.value,
    this.currencyCode = 'USD',
    this.isHighlighted = false,
    this.isPercent = false,
    this.isYears = false,
    this.customValue,
  });
}

class ResultPanel extends StatelessWidget {
  final List<ResultRow> rows;
  final Color primaryColor;
  final Color backgroundColor;
  final VoidCallback? onSave;

  const ResultPanel({
    super.key,
    required this.rows,
    this.primaryColor = const Color(0xFF0F2D6B),
    this.backgroundColor = Colors.white,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBg = backgroundColor == Colors.white && isDark
        ? theme.cardColor
        : backgroundColor;

    final resolvedPrimary = isDark
        ? (primaryColor == const Color(0xFF0F2D6B) // USA
            ? const Color(0xFF38BDF8)
            : (primaryColor == const Color(0xFF14145A) // UK
                ? const Color(0xFF93C5FD)
                : (primaryColor == const Color(0xFF6B1E08) // Australia
                    ? const Color(0xFFFF9E80)
                    : (primaryColor == const Color(0xFF14492A) // Canada
                        ? const Color(0xFFA7F3D0)
                        : (primaryColor == const Color(0xFF00236B) // Europe
                            ? const Color(0xFFC7D2FE)
                            : (primaryColor == const Color(0xFFE05F00) // India
                                ? const Color(0xFFFFD8A8)
                                : (primaryColor == const Color(0xFF1A6B4A) // New Zealand
                                    ? const Color(0xFF99F6E4)
                                    : const Color(0xFF38BDF8))))))))
        : primaryColor;

    final labelColor = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    final valueColor = isDark ? Colors.white : const Color(0xFF0A1528);

    return Container(
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resolvedPrimary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final isLast = i == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: row.isHighlighted
                    ? resolvedPrimary.withValues(alpha: 0.10)
                    : null,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: resolvedPrimary.withValues(alpha: 0.08),
                        ),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.label,
                    style: AppTextStyles.resultLabel(
                      row.isHighlighted
                          ? resolvedPrimary
                          : labelColor,
                    ),
                  ),
                  Text(
                    row.customValue != null
                        ? row.customValue!
                        : (row.isYears
                            ? '${row.value.toStringAsFixed(1)} yrs'
                            : (row.isPercent
                                ? CurrencyFormatter.percent(row.value)
                                : CurrencyFormatter.forCountry(
                                    row.value, row.currencyCode))),
                    style: row.isHighlighted
                        ? AppTextStyles.dmSans(
                            size: 22,
                            weight: FontWeight.w800,
                            color: resolvedPrimary,
                          )
                        : AppTextStyles.dmSans(
                            size: 16,
                            weight: FontWeight.w700,
                            color: valueColor,
                          ),
                  ),
                ],
              ),
            );
          }),
          if (onSave != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: onSave,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: resolvedPrimary.withValues(alpha: 0.30)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🔖 Save Calculation',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: resolvedPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
