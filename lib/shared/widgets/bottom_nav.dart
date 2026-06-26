// lib/shared/widgets/bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mortgagepro_global/services/analytics_service.dart';
import '../../app/theme/text_styles.dart';

class BottomNav extends StatelessWidget {
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;
  final String countryIcon;
  final String countryLabel;
  final String countryRoute;

  const BottomNav({
    super.key,
    required this.activeIndex,
    required this.activeColor,
    this.inactiveColor = const Color(0xFF5B6E8F),
    this.countryIcon = '🌐',
    this.countryLabel = 'Country',
    this.countryRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).uri.path;
    int index = activeIndex;
    if (route == '/') {
      index = 0;
    } else if (route == '/global') {
      index = 1;
    } else if (route == '/tools') {
      index = 2;
    } else if (route == '/saved') {
      index = 3;
    } else if (route == '/settings') {
      index = 4;
    } else {
      index = -1;
    }

    final items = [
      const _NavItem(icon: '🏠', label: 'Home', route: '/'),
      const _NavItem(icon: '🌍', label: 'Global', route: '/global'),
      const _NavItem(icon: '🛠️', label: 'Tools', route: '/tools'),
      const _NavItem(icon: '🔖', label: 'Saved', route: '/saved'),
      const _NavItem(icon: '⚙️', label: 'Settings', route: '/settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: activeColor.withValues(alpha: 0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isActive) {
                      // Map route to screen name
                      String screenName = 'home_screen';
                      if (item.route == '/saved') {
                        screenName = 'saved_screen';
                      } else if (item.route == '/global') {
                        screenName = 'global_screen';
                      } else if (item.route == '/settings') {
                        screenName = 'settings_screen';
                      } else if (item.route.startsWith('/')) {
                        final path = item.route.substring(1);
                        screenName = path.isEmpty ? 'home_screen' : '${path}_screen';
                      }
                      
                      AnalyticsService.instance.trackTab(i, screenName);
                      context.go(item.route);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          item.icon,
                          style: TextStyle(
                            fontSize: 20,
                            shadows: isActive
                                ? [
                                    Shadow(
                                      color: activeColor.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: AppTextStyles.navLabel(
                          isActive ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
