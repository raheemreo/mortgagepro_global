// lib/shared/widgets/tool_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/text_styles.dart';
import '../../providers/saved_tools_provider.dart';

enum ToolCardVariant {
  light, // white bg
  dark, // dark navy gradient
  red, // red gradient
  gold, // amber gradient
  teal, // teal gradient
  green, // forest green
  slate, // dark slate
  violet, // indigo/purple
  maple, // amber-brown (Canada)
  blue, // blue gradient (Australia)
  royal, // indigo (UK/EU)
}

class ToolCard extends ConsumerWidget {
  final String? toolId;
  final String? flagIcon;
  final String icon;
  final String name;
  final String description;
  final ToolCardVariant variant;
  final String? badgeText;
  final Color? badgeTextColor;
  final Color? badgeBgColor;
  final VoidCallback onTap;
  final Color? lightBorderColor;
  final double iconSize;
  final double iconBgSize;
  final bool showFlag;

  const ToolCard({
    super.key,
    this.toolId,
    this.flagIcon,
    required this.icon,
    required this.name,
    required this.description,
    this.variant = ToolCardVariant.light,
    this.badgeText,
    this.badgeTextColor,
    this.badgeBgColor,
    required this.onTap,
    this.lightBorderColor,
    this.iconSize = 36.0,
    this.iconBgSize = 60.0,
    this.showFlag = false,
  });

  bool get _isDark => variant != ToolCardVariant.light;

  Gradient? get _gradient {
    switch (variant) {
      case ToolCardVariant.dark:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF061528), Color(0xFF0F2D6B)],
        );
      case ToolCardVariant.red:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
        );
      case ToolCardVariant.gold:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
        );
      case ToolCardVariant.teal:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        );
      case ToolCardVariant.green:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15803D), Color(0xFF166534)],
        );
      case ToolCardVariant.slate:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF334155), Color(0xFF1E293B)],
        );
      case ToolCardVariant.violet:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        );
      case ToolCardVariant.maple:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
        );
      case ToolCardVariant.blue:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
        );
      case ToolCardVariant.royal:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
        );
      case ToolCardVariant.light:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final cardIsDark = _isDark || isDarkTheme;

    final savedTools = toolId != null ? ref.watch(savedToolsProvider) : <String>[];
    final isFavorite = toolId != null && savedTools.contains(toolId);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: _gradient,
            color: _isDark
                ? null
                : (isDarkTheme ? Theme.of(context).cardColor : Colors.white),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _isDark
                  ? Colors.transparent
                  : (isDarkTheme
                      ? Colors.white.withValues(alpha: 0.08)
                      : (lightBorderColor ??
                          Colors.black.withValues(alpha: 0.07))),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(13, 15, 13, 13),
          child: Stack(
            children: [
              if ((flagIcon != null && showFlag) || toolId != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (flagIcon != null && showFlag)
                        Text(
                          flagIcon!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (flagIcon != null && showFlag && toolId != null)
                        const SizedBox(width: 5),
                      if (toolId != null)
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(savedToolsProvider.notifier)
                                .toggleFavorite(toolId!);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cardIsDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.bookmark : Icons.bookmark_border,
                              color: isFavorite
                                  ? const Color(0xFFFCD34D)
                                  : (cardIsDark ? Colors.white70 : Colors.black45),
                              size: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon container
                    Container(
                      width: iconBgSize,
                      height: iconBgSize,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : (isDarkTheme
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFEEF3FF)),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: TextStyle(fontSize: iconSize)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardTitle(
                        _isDark
                            ? Colors.white
                            : (isDarkTheme
                                ? Colors.white
                                : const Color(0xFF061528)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardDesc(
                        _isDark
                            ? Colors.white.withValues(alpha: 0.58)
                            : (isDarkTheme
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFF3D5280)),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor ?? const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText!,
                          style: AppTextStyles.badgeText(
                            badgeTextColor ?? const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              Positioned(
                bottom: 0,
                right: 0,
                child: Text(
                  '›',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDarkTheme
                            ? Colors.white30
                            : Colors.black.withValues(alpha: 0.16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
