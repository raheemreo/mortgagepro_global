// lib/shared/widgets/country_header.dart
// Gradient header + flag + title + rate strip — matches mockup design

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/country_themes.dart';
import '../../app/theme/text_styles.dart';
import '../../features/notifications/providers/notifications_provider.dart';

class RateItem {
  final String label;
  final String value;
  final String note;
  final RateColor color;

  const RateItem({
    required this.label,
    required this.value,
    required this.note,
    this.color = RateColor.normal,
  });
}

enum RateColor { normal, red, green, gold }

class CountryHeader extends StatelessWidget {
  final CountryTheme theme;
  final List<RateItem> rates;
  final VoidCallback? onBack;
  final VoidCallback? onNotification;
  final bool showBackButton;

  const CountryHeader({
    super.key,
    required this.theme,
    required this.rates,
    this.onBack,
    this.onNotification,
    this.showBackButton = true,
  });

  Color _rateColor(RateColor rc) {
    switch (rc) {
      case RateColor.red:
        return const Color(0xFFFF8A9A);
      case RateColor.green:
        return const Color(0xFF86EFAC);
      case RateColor.gold:
        return const Color(0xFFFFD700);
      case RateColor.normal:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: theme.headerGradient),
      child: Stack(
        children: [
          // Decorative circle top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Watermark emoji
          Positioned(
            right: 12,
            top: 52,
            child: Text(
              theme.emoji,
              style: const TextStyle(fontSize: 72),
            ),
          ),
          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      if (showBackButton)
                        _IconBtn(
                          icon: '←',
                          onTap: onBack ?? () => Navigator.of(context).pop(),
                        )
                      else
                        const SizedBox(width: 36),
                      // Center: flag + title
                      Column(
                        children: [
                          Text(theme.flag,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 2),
                          Text(
                            theme.name,
                            style: AppTextStyles.headerTitle(Colors.white),
                          ),
                          Text(
                            theme.subtitle,
                            style: AppTextStyles.headerSub(
                              Colors.white.withValues(alpha: 0.52),
                            ),
                          ),
                        ],
                      ),
                      // Notification button
                      _NotificationIconBtn(
                        onTap: onNotification ?? () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Rate Strip
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: List.generate(rates.length, (i) {
                        final rate = rates[i];
                        return Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 4,
                            ),
                            decoration: i < rates.length - 1
                                ? BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        width: 1,
                                      ),
                                    ),
                                  )
                                : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rate.label,
                                  style: AppTextStyles.rateLabel(
                                    Colors.white.withValues(alpha: 0.48),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rate.value,
                                  style: AppTextStyles.rateValue(
                                    _rateColor(rate.color),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  rate.note,
                                  style: AppTextStyles.rateNote(
                                    Colors.white.withValues(alpha: 0.38),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

class _IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _NotificationIconBtn extends ConsumerWidget {
  final VoidCallback onTap;

  const _NotificationIconBtn({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            alignment: Alignment.center,
            child: const Text('🔔', style: TextStyle(fontSize: 16)),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
