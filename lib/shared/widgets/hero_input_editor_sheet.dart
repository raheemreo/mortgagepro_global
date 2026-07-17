// lib/shared/widgets/hero_input_editor_sheet.dart

import 'package:flutter/material.dart';
import '../../app/theme/text_styles.dart';

/// Configuration for a single slider in [HeroInputEditorSheet].
class HeroInputConfig {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;

  const HeroInputConfig({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
  });
}

/// A reusable draggable bottom sheet that lets the user edit
/// HeroCalculatorCard input values before triggering a calculation.
class HeroInputEditorSheet extends StatefulWidget {
  final String title;
  final Color primaryColor;
  final List<HeroInputConfig> configs;
  final void Function(List<double> values) onApply;

  const HeroInputEditorSheet({
    super.key,
    required this.title,
    required this.primaryColor,
    required this.configs,
    required this.onApply,
  });

  @override
  State<HeroInputEditorSheet> createState() => _HeroInputEditorSheetState();
}

class _HeroInputEditorSheetState extends State<HeroInputEditorSheet> {
  late List<double> _values;

  @override
  void initState() {
    super.initState();
    _values = widget.configs.map((c) => c.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.80,
      minChildSize: 0.40,
      expand: false,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: AppTextStyles.dmSans(
                size: 17,
                weight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Drag sliders to adjust values, then tap Apply.',
              style: AppTextStyles.dmSans(
                size: 11,
                color: isDark ? Colors.white54 : Colors.grey[500]!,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(widget.configs.length, (i) {
              final cfg = widget.configs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cfg.label,
                          style: AppTextStyles.dmSans(
                            size: 9,
                            weight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white54 : Colors.grey[500]!,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cfg.format(_values[i]),
                            style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Slider(
                      value: _values[i].clamp(cfg.min, cfg.max),
                      min: cfg.min,
                      max: cfg.max,
                      divisions: cfg.divisions,
                      activeColor: widget.primaryColor,
                      inactiveColor: widget.primaryColor.withValues(alpha: 0.15),
                      onChanged: (v) => setState(() => _values[i] = v),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_values);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  '✅  Apply & Calculate',
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
