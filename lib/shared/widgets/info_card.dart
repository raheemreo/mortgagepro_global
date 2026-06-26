// lib/shared/widgets/info_card.dart

import 'package:flutter/material.dart';
import '../../app/theme/text_styles.dart';

class InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconBgColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color chevronColor;
  final Color borderColor;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconBgColor = const Color(0xFFEEF3FF),
    this.titleColor = const Color(0xFF061528),
    this.subtitleColor = const Color(0xFF3D5280),
    this.chevronColor = const Color(0x281B3F72),
    this.borderColor = const Color(0x141B3F72),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBg = backgroundColor == Colors.white && isDark
        ? theme.cardColor
        : backgroundColor;
    final resolvedBorder = borderColor == const Color(0x141B3F72) && isDark
        ? Colors.white.withValues(alpha: 0.08)
        : borderColor;
    final resolvedTitle = titleColor == const Color(0xFF061528) && isDark
        ? Colors.white
        : titleColor;
    final resolvedSub = subtitleColor == const Color(0xFF3D5280) && isDark
        ? Colors.white60
        : subtitleColor;
    final resolvedIconBg = iconBgColor == const Color(0xFFEEF3FF) && isDark
        ? Colors.white.withValues(alpha: 0.1)
        : iconBgColor;
    final resolvedChevron = chevronColor == const Color(0x281B3F72) && isDark
        ? Colors.white30
        : chevronColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: resolvedBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: resolvedBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: resolvedIconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.infoTitle(resolvedTitle)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.infoSub(resolvedSub)),
                ],
              ),
            ),
            Text(
              '›',
              style: TextStyle(fontSize: 18, color: resolvedChevron),
            ),
          ],
        ),
      ),
    );
  }
}
