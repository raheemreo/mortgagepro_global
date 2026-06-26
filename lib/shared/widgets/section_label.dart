// lib/shared/widgets/section_label.dart

import 'package:flutter/material.dart';
import '../../app/theme/text_styles.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final String? moreText;
  final VoidCallback? onMoreTap;
  final Color labelColor;
  final Color moreColor;
  final EdgeInsetsGeometry margin;

  const SectionLabel({
    super.key,
    required this.text,
    this.moreText,
    this.onMoreTap,
    this.labelColor = const Color(0xFF3D5280),
    this.moreColor = const Color(0xFF0F2D6B),
    this.margin = const EdgeInsets.only(top: 20, bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: AppTextStyles.sectionLabel(labelColor),
          ),
          if (moreText != null)
            GestureDetector(
              onTap: onMoreTap,
              child: Text(
                moreText!,
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: moreColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
