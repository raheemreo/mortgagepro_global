// lib/shared/widgets/hero_calculator_card.dart

import 'package:flutter/material.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';

class HeroInputBox {
  final String label;
  final String value;

  const HeroInputBox({required this.label, required this.value});
}

class HeroCalculatorCard extends StatelessWidget {
  final CountryTheme theme;
  final String tag;
  final String titleLine1;
  final String accentWord;
  final String titleLine2;
  final String buttonEmoji;
  final String buttonText;
  final List<HeroInputBox> inputs;
  final VoidCallback onCalculate;
  final VoidCallback? onInputTap;
  final LinearGradient? buttonGradient;

  const HeroCalculatorCard({
    super.key,
    required this.theme,
    required this.tag,
    required this.titleLine1,
    required this.accentWord,
    this.titleLine2 = '',
    required this.buttonEmoji,
    required this.buttonText,
    required this.inputs,
    required this.onCalculate,
    this.onInputTap,
    this.buttonGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          // Watermark emoji
          Positioned(
            right: 6,
            top: 4,
            child: Text(
              theme.emoji,
              style: const TextStyle(fontSize: 65),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.toUpperCase(),
                  style: AppTextStyles.heroTag(
                    Colors.white.withValues(alpha: 0.48),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: titleLine1,
                        style: AppTextStyles.heroTitle(Colors.white),
                      ),
                      TextSpan(
                        text: ' $accentWord',
                        style: AppTextStyles.heroTitle(
                          const Color(0xFFFFD700),
                        ),
                      ),
                      if (titleLine2.isNotEmpty) ...[
                        TextSpan(
                          text: '\n$titleLine2',
                          style: AppTextStyles.heroTitle(Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                // Input boxes row
                Row(
                  children: inputs.map((box) {
                    final isLast = box == inputs.last;
                    return Expanded(
                      child: GestureDetector(
                        onTap: onInputTap,
                        child: Container(
                          margin: EdgeInsets.only(right: isLast ? 0 : 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                box.label,
                                style: AppTextStyles.inputLabel(
                                  Colors.white.withValues(alpha: 0.48),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                box.value,
                                style: AppTextStyles.inputValue(Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // CTA Button
                GestureDetector(
                  onTap: onCalculate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: buttonGradient ??
                          LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              theme.accentColor,
                              theme.accentColor.withValues(alpha: 0.8),
                            ],
                          ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.accentColor.withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$buttonEmoji $buttonText',
                      style: AppTextStyles.buttonText(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
