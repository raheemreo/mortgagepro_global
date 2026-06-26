// lib/shared/widgets/alert_banner.dart

import 'package:flutter/material.dart';
import '../../app/theme/text_styles.dart';

class AlertBanner extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color bgColor1;
  final Color bgColor2;
  final Color borderColor;
  final Color buttonColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const AlertBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.bgColor1,
    required this.bgColor2,
    required this.borderColor,
    required this.buttonColor,
    this.titleColor = const Color(0xFF7C2D12),
    this.subtitleColor = const Color(0xFFC2410C),
    required this.onTap,
  });

  /// Factory: Australia LMI
  factory AlertBanner.lmi({required VoidCallback onTap}) => AlertBanner(
        icon: '🛡️',
        title: 'Lenders Mortgage Insurance',
        subtitle: 'Required when deposit is below 20% — calculate LMI cost',
        buttonText: 'Calculate',
        bgColor1: const Color(0xFFFFF7ED),
        bgColor2: const Color(0xFFFFEDD5),
        borderColor: const Color(0xFFFCA5A5),
        buttonColor: const Color(0xFFEA580C),
        onTap: onTap,
      );

  /// Factory: Canada Stress Test
  factory AlertBanner.stressTest({required VoidCallback onTap}) => AlertBanner(
        icon: '⚠️',
        title: 'Mortgage Stress Test',
        subtitle: 'Qualify at 7.00% or contract+2% — whichever is higher',
        buttonText: 'Test Now',
        bgColor1: const Color(0xFFFEF3C7),
        bgColor2: const Color(0xFFFDE68A),
        borderColor: const Color(0xFFF59E0B),
        buttonColor: const Color(0xFFF59E0B),
        titleColor: const Color(0xFF92400E),
        subtitleColor: const Color(0xFFB45309),
        onTap: onTap,
      );

  /// Factory: UK SDLT
  factory AlertBanner.sdlt({required VoidCallback onTap}) => AlertBanner(
        icon: '🏛️',
        title: 'Stamp Duty Land Tax',
        subtitle: 'First-time buyer relief up to £425,000 — calculate now',
        buttonText: 'Calculate',
        bgColor1: const Color(0xFFEEF2FF),
        bgColor2: const Color(0xFFE0E7FF),
        borderColor: const Color(0xFFA5B4FC),
        buttonColor: const Color(0xFF4F46E5),
        titleColor: const Color(0xFF1E1B4B),
        subtitleColor: const Color(0xFF4338CA),
        onTap: onTap,
      );

  /// Factory: Europe Euribor
  factory AlertBanner.euribor({required VoidCallback onTap}) => AlertBanner(
        icon: '📊',
        title: 'Euribor Rate Tracker',
        subtitle: 'Track ECB rates across Germany, France, Spain and more',
        buttonText: 'View',
        bgColor1: const Color(0xFFEEF2FF),
        bgColor2: const Color(0xFFE0E7FF),
        borderColor: const Color(0xFF818CF8),
        buttonColor: const Color(0xFF4F46E5),
        titleColor: const Color(0xFF1E1B4B),
        subtitleColor: const Color(0xFF4338CA),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor1, bgColor2],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTextStyles.infoTitle(titleColor).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.infoSub(subtitleColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  buttonText,
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
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
