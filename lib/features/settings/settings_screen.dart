// lib/features/settings/settings_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/text_styles.dart';
import '../../providers/settings_provider.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../services/ad_free_manager.dart';
import '../../services/ad_config.dart';
import '../../services/ad_free_analytics_tracker.dart';
import '../../services/ad_manager.dart';
import '../../services/consent_service.dart';
import '../../services/analytics/analytics_screen.dart';
import '../../core/analytics/screen_timer_mixin.dart';
import 'widgets/pro_adfree_dialog.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static Color navy = const Color(0xFF0B1D3A);
  static Color teal = const Color(0xFF0D9488);
  static Color bg = const Color(0xFFF0F4FF);
  static Color muted = const Color(0xFF5B6E8F);
  static Color border = const Color(0x171B3A8F);

  static void update(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    navy = isDark ? Colors.white : const Color(0xFF0B1D3A);
    teal = const Color(0xFF0D9488);
    bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    muted = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    border =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ⚙️  SETTINGS SCREEN
// ════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with ScreenTimerMixin {
  @override
  String get screenName => AnalyticsScreen.settings;

  // Toggle states — local but functional
  bool _liveRates = true;
  bool _rateAlerts = true;
  bool _marketNews = false;

  Timer? _localTimer;

  @override
  void initState() {
    super.initState();
    startScreenTimer();
    final adUnitId = Platform.isIOS
        ? AdConfig.rewardedAdUnitIos
        : AdConfig.rewardedAdUnitAndroid;
    AdManager.instance.loadRewarded(adUnitId, screen: 'settings_screen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocalTimerIfNeeded();
    });
  }

  @override
  void dispose() {
    stopScreenTimer();
    _localTimer?.cancel();
    super.dispose();
  }

  void _startLocalTimerIfNeeded() {
    _localTimer?.cancel();
    if (AdFreeManager.instance.isActive) {
      _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && AdFreeManager.instance.isActive) {
          setState(() {});
        } else {
          timer.cancel();
          setState(() {});
        }
      });
    }
  }

  // ── Ad-Free: open the dialog ─────────────────────────────────────────────
  void _openAdFreeDialog() {
    showProDialog(
      context,
      onWatchAdvertisement: _onWatchAd,
    );
  }

  void _onWatchAd() {
    if (!AdFreeManager.instance.canWatchAd) {
      AdFreeAnalyticsTracker.instance.trackRewardDenied(
        placement: 'settings_screen',
        reason: 'cap_reached',
      );
      return;
    }

    final adUnitId = Platform.isIOS
        ? AdConfig.rewardedAdUnitIos
        : AdConfig.rewardedAdUnitAndroid;

    AdManager.instance.showRewarded(
      adUnitId,
      screen: 'settings_screen',
      onEarned: (ad, reward) {
        AdFreeManager.instance
            .unlockFor(AdFreeManager.instance.sessionDuration);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _C.update(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Watch the ad-free active state reactively
    final adFreeActive = ref.watch(adFreeActiveProvider);

    // Listen to changes in ad-free active provider to start/stop local timer
    ref.listen<bool>(adFreeActiveProvider, (previous, next) {
      if (next) {
        _startLocalTimerIfNeeded();
      } else {
        _localTimer?.cancel();
        setState(() {});
      }
    });

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Gradient Header with Profile Card ──────────────────────
          _SettingsHeader(settings: settings, notifier: notifier),

          // ── Scrollable Content ──────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 110),
              children: [
                // ── General ───────────────────────────────────────────
                const _SecLabel('General'),
                _SetGroup(children: [
                  _SetItem(
                    icon: '🌍',
                    iconBg: const Color(0xFFEFF6FF),
                    name: 'Default Country',
                    desc: 'Primary country for calculations',
                    trailing: _SetValue(
                      '${_getCountryFlag(settings.preferredCountry)} ${settings.preferredCountry.isNotEmpty ? settings.preferredCountry : "USA"}',
                    ),
                    onTap: () => _showCountryPicker(
                        context, notifier, settings.preferredCountry),
                  ),
                  _SetItem(
                    icon: '💵',
                    iconBg: const Color(0xFFFFF7ED),
                    name: 'Currency Display',
                    desc: 'Default currency for all results',
                    trailing: _SetValue(
                      '${settings.preferredCurrency} (${_getCurrencySymbol(settings.preferredCurrency)})',
                    ),
                    onTap: () => _showCurrencyPicker(
                        context, notifier, settings.preferredCurrency),
                  ),
                  _SetItem(
                    icon: '🎨',
                    iconBg: const Color(0xFFF5F3FF),
                    name: 'App Theme',
                    desc: 'Light, Dark or follow system',
                    trailing: _SetValue(_themeLabel(settings.themeMode)),
                    isLast: true,
                    onTap: () =>
                        _showThemePicker(context, notifier, settings.themeMode),
                  ),
                ]),

                // ── Rates & Data ──────────────────────────────────────
                const _SecLabel('Rates & Data'),
                _SetGroup(children: [
                  _SetItem(
                    icon: '📡',
                    iconBg: const Color(0xFFF0FDF4),
                    name: 'Live Rate Updates',
                    desc: 'Auto-refresh mortgage rates',
                    trailing: _Toggle(
                        value: _liveRates,
                        onChanged: (v) => setState(() => _liveRates = v)),
                    isLast: true,
                  ),
                ]),

                // ── Notifications ─────────────────────────────────────
                const _SecLabel('Notifications'),
                _SetGroup(children: [
                  _SetItem(
                    icon: '🔔',
                    iconBg: const Color(0xFFEFF6FF),
                    name: 'Rate Change Alerts',
                    desc: 'Notify when rates change ±0.10%',
                    trailing: _Toggle(
                        value: _rateAlerts,
                        onChanged: (v) => setState(() => _rateAlerts = v)),
                  ),
                  _SetItem(
                    icon: '📈',
                    iconBg: const Color(0xFFF0FDFA),
                    name: 'Market News',
                    desc: 'Daily housing market digest',
                    trailing: _Toggle(
                        value: _marketNews,
                        onChanged: (v) => setState(() => _marketNews = v)),
                    isLast: true,
                  ),
                ]),

                // ── Ad-Free Session ────────────────────────────────────
                const _SecLabel('Ad Experience'),
                _SetGroup(children: [
                  _SetItem(
                    icon: '⭐',
                    iconBg: const Color(0xFFFFFBEB),
                    name: adFreeActive
                        ? 'Ad-Free Session Active'
                        : 'Ad-Free Session',
                    desc: adFreeActive
                        ? _formatRemaining(AdFreeManager.instance.remaining)
                        : 'Watch an ad · Unlock 10 minutes ad-free',
                    trailing: adFreeActive ? _ActiveBadge() : const _SetArrow(),
                    isLast: true,
                    onTap: _openAdFreeDialog,
                  ),
                ]),

                // ── Feedback / Contact ────────────────────────────────
                const _SecLabel('Feedback / Contact'),
                _SetGroup(children: [
                  _SetItem(
                    icon: '✉️',
                    iconBg: const Color(0xFFF5F3FF),
                    name: 'Feedback / Contact',
                    desc: 'support@mortgageproglobal.com',
                    trailing: const _SetArrow(),
                    isLast: true,
                    onTap: () => context.push('/settings/feedback'),
                  ),
                ]),

                // ── Privacy & Legal ────────────────────────────────────
                const _SecLabel('Privacy & Legal'),
                _SetGroup(children: [
                  _SetItem(
                    icon: '🌐',
                    iconBg: const Color(0xFFECFDF5),
                    name: 'Visit Our Website',
                    desc: 'mortgageproglobal.com',
                    trailing: const _SetArrow(),
                    onTap: () => _launchURL('https://mortgageproglobal.com'),
                  ),
                  _SetItem(
                    icon: '🛡️',
                    iconBg: const Color(0xFFF0FDF4),
                    name: 'Your Privacy Choices',
                    desc: 'Opt out of selling or sharing personal info (CA)',
                    trailing: _Toggle(
                      value: settings.privacyChoicesOptOut,
                      onChanged: (v) => notifier.setPrivacyChoicesOptOut(v),
                    ),
                  ),
                  _SetItem(
                    icon: '⚙️',
                    iconBg: const Color(0xFFEFF6FF),
                    name: 'Consent Settings',
                    desc: 'Change your ad consent preferences',
                    trailing: const _SetArrow(),
                    onTap: () =>
                        ConsentService.instance.showPrivacyOptionsForm(context),
                  ),
                  _SetItem(
                    icon: '🔒',
                    iconBg: _C.bg,
                    name: 'Privacy Policy',
                    desc: 'How we use your data',
                    trailing: const _SetArrow(),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  _SetItem(
                    icon: '📄',
                    iconBg: _C.bg,
                    name: 'Terms of Service',
                    desc: 'User agreement',
                    trailing: const _SetArrow(),
                    onTap: () => _showTermsOfService(context),
                  ),
                  _SetItem(
                    icon: '⚠️',
                    iconBg: const Color(0xFFFFFBEB),
                    name: 'Disclaimer',
                    desc: 'Calculator estimates & limitations',
                    trailing: const _SetArrow(),
                    onTap: () => _showDisclaimer(context),
                  ),
                  _SetItem(
                    icon: '🏢',
                    iconBg: const Color(0xFFEFF6FF),
                    name: 'About Us',
                    desc: 'Our mission, values & contact',
                    trailing: const _SetArrow(),
                    onTap: () => _showAboutUs(context),
                  ),
                  _SetItem(
                    icon: '🗑️',
                    iconBg: const Color(0xFFFEF2F2),
                    name: 'Delete Account',
                    desc: 'Permanently remove all data',
                    trailing: const _SetArrow(isRed: true),
                    isLast: true,
                    onTap: () => _showDeleteConfirm(context),
                  ),
                ]),

                // ── App Info footer ────────────────────────────────────
                const _AppInfo(),
              ],
            ),
          ),

          // ── Bottom Navigation ───────────────────────────────────────
          BottomNav(
            activeIndex: 4,
            activeColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF38BDF8)
                : const Color(0xFF1A3A8F),
            countryIcon: '🌐',
            countryLabel: 'Tools',
            countryRoute: '/',
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _formatRemaining(Duration r) {
    if (r == Duration.zero) return '00:00 remaining';
    final m = r.inMinutes;
    final s = r.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} remaining';
  }

  String _getCountryFlag(String country) {
    switch (country.toLowerCase()) {
      case 'usa':
        return '🇺🇸';
      case 'canada':
        return '🇨🇦';
      case 'uk':
        return '🇬🇧';
      case 'australia':
        return '🇦🇺';
      case 'new zealand':
        return '🇳🇿';
      case 'europe':
        return '🇪🇺';
      case 'india':
        return '🇮🇳';
      case 'japan':
        return '🇯🇵';
      case 'singapore':
        return '🇸🇬';
      case 'switzerland':
        return '🇨🇭';
      case 'south africa':
        return '🇿🇦';
      case 'uae':
        return '🇦🇪';
      case 'brazil':
        return '🇧🇷';
      default:
        return '🇺🇸';
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'AUD':
        return 'AU\$';
      case 'CAD':
        return 'CA\$';
      case 'NZD':
        return 'NZ\$';
      default:
        return '\$';
    }
  }

  // ── Theme helpers ──────────────────────────────────────────────
  String _themeLabel(String mode) {
    switch (mode) {
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      default:
        return 'System';
    }
  }

  void _showThemePicker(
      BuildContext ctx, SettingsNotifier notifier, String current) {
    // (icon, mode, label, desc, accentColor, gradientStart, gradientEnd)
    const options = [
      (
        Icons.brightness_auto_rounded,
        'system',
        'System',
        'Follow device theme',
        Color(0xFF6C63FF), // indigo accent
        Color(0xFF8B5CF6), // violet start
        Color(0xFF6C63FF), // indigo end
      ),
      (
        Icons.wb_sunny_rounded,
        'light',
        'Light',
        'Always use light theme',
        Color(0xFFF59E0B), // amber accent
        Color(0xFFFBBF24), // yellow start
        Color(0xFFF97316), // orange end
      ),
      (
        Icons.dark_mode_rounded,
        'dark',
        'Dark',
        'Always use dark theme',
        Color(0xFF3B82F6), // blue accent
        Color(0xFF1E40AF), // navy start
        Color(0xFF3B82F6), // blue end
      ),
    ];

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/settings/theme'),
      builder: (_) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF141C33) : Colors.white;
        final handleColor = isDark ? Colors.white24 : const Color(0xFFE2E8F0);
        // per-option accent colors are carried in each option record

        return Material(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  'App Theme',
                  style: AppTextStyles.playfair(size: 17, color: _C.navy),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how Mortgage Pro Global looks',
                  style: AppTextStyles.dmSans(
                      size: 13, color: _C.muted, weight: FontWeight.w400),
                ),
                const SizedBox(height: 20),
                // Option tiles
                ...options.map((opt) {
                  final (
                    icon,
                    mode,
                    label,
                    desc,
                    optAccent,
                    gradStart,
                    gradEnd
                  ) = opt;
                  final isSelected = current == mode;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        notifier.setThemeMode(mode);
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? optAccent.withValues(
                                  alpha: isDark ? 0.15 : 0.08)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF8FAFF)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? optAccent.withValues(alpha: 0.9)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: optAccent.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // ── Gradient icon bubble ──
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [gradStart, gradEnd]
                                      : isDark
                                          ? [
                                              Colors.white
                                                  .withValues(alpha: 0.10),
                                              Colors.white
                                                  .withValues(alpha: 0.06),
                                            ]
                                          : [
                                              const Color(0xFFEEF2FF),
                                              const Color(0xFFE0E7FF),
                                            ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              gradEnd.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                size: 23,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white54
                                        : optAccent.withValues(alpha: 0.65)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // ── Label + description ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: AppTextStyles.dmSans(
                                      size: 15,
                                      color: isSelected ? optAccent : _C.navy,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: AppTextStyles.dmSans(
                                      size: 12,
                                      color: _C.muted,
                                      weight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ── Checkmark ──
                            AnimatedOpacity(
                              opacity: isSelected ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [gradStart, gradEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradEnd.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCountryPicker(
      BuildContext ctx, SettingsNotifier notifier, String current) {
    final countries = [
      ('🇺🇸', 'USA'),
      ('🇨🇦', 'Canada'),
      ('🇬🇧', 'UK'),
      ('🇦🇺', 'Australia'),
      ('🇳🇿', 'New Zealand'),
      ('🇪🇺', 'Europe'),
      ('🇮🇳', 'India'),
      ('🇯🇵', 'Japan'),
      ('🇸🇬', 'Singapore'),
      ('🇨🇭', 'Switzerland'),
      ('🇿🇦', 'South Africa'),
      ('🇦🇪', 'UAE'),
      ('🇧🇷', 'Brazil'),
    ];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      routeSettings: const RouteSettings(name: '/settings/country'),
      builder: (_) => Material(
        color: Theme.of(ctx).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white24
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('Default Country',
                  style: AppTextStyles.playfair(size: 16, color: _C.navy)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: countries.map((entry) {
                    final (flag, name) = entry;
                    final isSelected =
                        (current.isEmpty ? 'USA' : current) == name;
                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 22)),
                      title: Text(name,
                          style: AppTextStyles.dmSans(
                              size: 14,
                              color: _C.navy,
                              weight: FontWeight.w700)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF0D9488))
                          : null,
                      onTap: () {
                        notifier.setPreferredCountry(name);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(
      BuildContext ctx, SettingsNotifier notifier, String current) {
    final currencies = [
      ('🇺🇸', 'USD', 'US Dollar (\$)'),
      ('🇨🇦', 'CAD', 'Canadian Dollar (CA\$)'),
      ('🇬🇧', 'GBP', 'British Pound (£)'),
      ('🇪🇺', 'EUR', 'Euro (€)'),
      ('🇦🇺', 'AUD', 'Australian Dollar (AU\$)'),
      ('🇳🇿', 'NZD', 'New Zealand Dollar (NZ\$)'),
      ('🇮🇳', 'INR', 'Indian Rupee (₹)'),
    ];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/settings/currency'),
      builder: (_) => Material(
        color: Theme.of(ctx).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? Colors.white24
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('Currency Display',
                style: AppTextStyles.playfair(size: 16, color: _C.navy)),
            const SizedBox(height: 8),
            ...currencies.map((entry) {
              final (flag, code, name) = entry;
              final isSelected = (current.isEmpty ? 'USD' : current) == code;
              return ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 22)),
                title: Text(name,
                    style: AppTextStyles.dmSans(
                        size: 14, color: _C.navy, weight: FontWeight.w700)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF0D9488))
                    : null,
                onTap: () {
                  notifier.setPreferredCurrency(code);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx) {
    showDialog(
      context: ctx,
      routeSettings: const RouteSettings(name: '/dialog/settings_screen'),
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Account',
            style: AppTextStyles.playfair(size: 18, color: _C.navy)),
        content: Text(
          'This will permanently remove all your settings, preferences, and saved calculations. This action cannot be undone.',
          style: AppTextStyles.dmSans(size: 13, color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.dmSans(
                    size: 14, color: _C.muted, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              // 1. Clear saved calculations (Hive)
              await ref.read(savedProvider.notifier).clearAll();
              // 2. Clear app settings (SharedPreferences)
              await ref.read(settingsProvider.notifier).clearAll();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been permanently deleted.'),
                    backgroundColor: Color(0xFFB91C1C),
                  ),
                );
              }
            },
            child: Text('Delete Everything',
                style: AppTextStyles.dmSans(
                    size: 14,
                    color: const Color(0xFFB91C1C),
                    weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/settings/privacy'),
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white24
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Privacy Policy',
                    style: AppTextStyles.playfair(
                      size: 20,
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0B1D3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _legalSection('1. About Mortgage Pro Global',
                        'Mortgage Pro Global provides mortgage calculators, home loan tools, EMI calculators, refinancing calculators, affordability calculators, mortgage-related educational resources, lender information, and housing market reference information for multiple countries. We are not a bank, lender, mortgage broker, financial advisor, legal advisor, tax advisor, or investment advisor.'),
                    _legalSection('2. Information We Collect',
                        'Our app does not require you to create an account to use core features. We do not require your name, address, phone number, email address, government identification, bank information, or credit card information unless you voluntarily contact us.\n\nMortgage calculations are performed on your device. Calculator inputs such as loan amount, interest rate, property value, down payment, income, and mortgage term are used only to generate calculation results and are not transmitted to our servers.\n\nIf you choose to save calculators or tools, this information is stored locally on your device.'),
                    _legalSection('3. Analytics Information',
                        'With your consent where required by law, we use Google Firebase Analytics to understand how the app is used. Analytics may include app version, device model, operating system, screen views, app interactions, crash diagnostics, performance information, and general geographic region. We do not use Firebase Analytics to collect personally identifiable financial information.\n\nAnalytics collection remains disabled until consent is obtained where required. You may withdraw consent at any time through the app\'s privacy settings.'),
                    _legalSection('4. Advertising',
                        'Mortgage Pro Global uses Google AdMob to display advertisements. AdMob may collect information including advertising identifiers, device information, approximate location, and interaction with advertisements. Advertising is subject to Google\'s Privacy Policy. Where required by law, personalized advertising is shown only after obtaining valid user consent.'),
                    _legalSection('5. Consent Management',
                        'Mortgage Pro Global uses Google User Messaging Platform (UMP) to manage consent where required. This includes users in the European Economic Area (EEA), United Kingdom, Switzerland, and applicable United States jurisdictions. Before analytics or personalized advertising is enabled in these regions, consent is requested when required by law. Users may change their consent preferences at any time.'),
                    _legalSection('6. Information We Do NOT Collect',
                        'Mortgage Pro Global does not intentionally collect bank account numbers, credit card numbers, mortgage account numbers, government identification numbers, passport information, Social Security Numbers, National Insurance Numbers, Aadhaar numbers, user-entered mortgage calculations, or financial application forms.'),
                    _legalSection('7. Third-Party Services',
                        'Mortgage Pro Global uses third-party services including Google Firebase, Firebase Analytics, Firebase Remote Config, Google AdMob, Google User Messaging Platform (UMP), and Google Play Services. These services operate under their own privacy policies.'),
                    _legalSection('8. Data Sharing',
                        'We do not sell your personal information. We may share limited information with trusted service providers solely to operate and improve our app and website. These providers include Google services used for analytics, advertising, crash reporting, and application functionality.'),
                    _legalSection('9. Data Retention',
                        'Analytics information is retained according to Google Firebase retention settings. Locally stored calculator preferences remain on your device until you remove them or uninstall the app.'),
                    _legalSection('10. Security',
                        'We use reasonable administrative, technical, and organizational measures to protect information. However, no internet transmission or electronic storage system is completely secure.'),
                    _legalSection('11. Children\'s Privacy',
                        'Mortgage Pro Global is not directed to children under the age of 13 or the minimum legal age required in their jurisdiction. We do not knowingly collect personal information from children.'),
                    _legalSection('12. Your Privacy Rights',
                        'Depending on your location, you may have rights to access, correct, delete, or restrict processing of personal information, withdraw consent, object to processing, or request data portability. California residents may have additional rights under CCPA/CPRA. Users in the EEA, UK, and Switzerland may have rights under GDPR or similar laws. To exercise these rights, please contact us at privacy@mortgageproglobal.com.'),
                    _legalSection('13. Changes to This Policy',
                        'We may update this Privacy Policy periodically. Any changes will be published at mortgageproglobal.com with an updated "Last Updated" date. Continued use of Mortgage Pro Global after changes become effective constitutes acceptance of the revised Privacy Policy.'),
                    _legalSection('14. Contact Us',
                        'Website: mortgageproglobal.com\nEmail: support@mortgageproglobal.com\nPrivacy: privacy@mortgageproglobal.com'),
                    _legalSection('15. Google Play Compliance',
                        'Mortgage Pro Global is committed to complying with applicable privacy laws and platform requirements, including Google Play policies. The app requests user consent where required before enabling analytics or personalized advertising and provides users with options to manage applicable privacy preferences.'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: AppTextStyles.dmSans(
                        size: 14, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsOfService(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/settings/terms'),
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white24
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('📄', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Terms of Service',
                    style: AppTextStyles.playfair(
                      size: 20,
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0B1D3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _legalSection('1. About Mortgage Pro Global',
                        'Mortgage Pro Global provides mortgage calculators, home loan calculators, EMI calculators, refinancing tools, affordability calculators, mortgage-related educational content, lender information, housing market resources, and reference financial information for supported countries. Mortgage Pro Global is designed for informational and educational purposes only.'),
                    _legalSection('2. Eligibility',
                        'You must comply with all applicable laws when using Mortgage Pro Global. The App and Website are intended for users who are legally permitted to use such services within their jurisdiction. If you are under the age of majority in your jurisdiction, you should use Mortgage Pro Global only under the supervision of a parent or legal guardian.'),
                    _legalSection(
                        '3. No Financial, Legal, Tax, or Investment Advice',
                        'Mortgage Pro Global is not a bank, mortgage lender, mortgage broker, financial institution, financial advisor, investment advisor, legal advisor, or tax advisor. Nothing provided within the App or Website constitutes professional financial, legal, investment, mortgage, accounting, or tax advice. Always consult qualified professionals before making financial decisions.'),
                    _legalSection('4. Calculator Results',
                        'All calculators generate estimates only. Results may vary due to lender-specific policies, changing interest rates, taxes, insurance costs, government regulations, local lending requirements, fees, and rounding methods. Calculator results should never be considered guarantees, loan offers, or financial approvals.'),
                    _legalSection('5. Mortgage Rates & Market Information',
                        'Mortgage Pro Global may display reference mortgage rates, central bank reference rates, lender information, market trends, housing data, and educational content for general reference only. Mortgage rates, lending criteria, fees, and market conditions change frequently. Always verify information directly with the relevant lender, bank, government authority, or qualified professional.'),
                    _legalSection('6. Lender Information',
                        'Lender information is provided for informational purposes only. Mortgage Pro Global does not recommend specific lenders, rank lenders as financial advice, broker loans, negotiate loans, process mortgage applications, approve loans, or guarantee loan availability. Any decision to contact or engage with a lender is solely your responsibility.'),
                    _legalSection('7. External Websites',
                        'Mortgage Pro Global may contain links to third-party websites. These websites operate independently. We do not control or endorse their content, privacy practices, availability, security, products, services, or terms of use. Accessing third-party websites is entirely at your own risk.'),
                    _legalSection('8. User Responsibilities',
                        'You agree to use Mortgage Pro Global lawfully, provide accurate information when using calculators, and independently verify important financial information. You agree not to misuse the App, attempt unauthorized access, interfere with services, distribute malware, reverse engineer protected software, or use automated systems to abuse the service.'),
                    _legalSection('9. Intellectual Property',
                        'All content within Mortgage Pro Global, including application design, user interface, graphics, icons, branding, logos, software, source code, text, documentation, calculators, and original content is owned by or licensed to Mortgage Pro Global and is protected by applicable intellectual property laws. You may not reproduce, modify, distribute, or commercially exploit any part without prior written permission.'),
                    _legalSection('10. Advertisements',
                        'Mortgage Pro Global may display advertisements through third-party advertising providers, including Google AdMob. Advertisements are provided by third parties. We do not guarantee or endorse products or services advertised within the App.'),
                    _legalSection('11. Disclaimer of Warranties',
                        'Mortgage Pro Global is provided on an "as is" and "as available" basis. To the fullest extent permitted by law, we make no warranties regarding uninterrupted availability, accuracy, reliability, completeness, fitness for a particular purpose, merchantability, or error-free operation.'),
                    _legalSection('12. Limitation of Liability',
                        'To the maximum extent permitted by applicable law, Mortgage Pro Global and its owners, developers, affiliates, employees, and partners shall not be liable for any direct, indirect, incidental, consequential, special, or financial damages arising from use of the App, Website, calculators, or related information.'),
                    _legalSection('13. Governing Law',
                        'These Terms shall be governed by and interpreted in accordance with the applicable laws of the jurisdiction in which Mortgage Pro Global operates, unless otherwise required by mandatory consumer protection laws in your country. Nothing in these Terms limits any consumer rights that cannot legally be waived under applicable law.'),
                    _legalSection('14. Changes to These Terms',
                        'We may update these Terms from time to time. Updated versions will be published on the Website and may also be made available within the App. Your continued use of Mortgage Pro Global after changes become effective constitutes acceptance of the revised Terms.'),
                    _legalSection('15. Contact Us',
                        'Website: mortgageproglobal.com\nEmail: support@mortgageproglobal.com\nContact: mortgageproglobal.com/contact'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: AppTextStyles.dmSans(
                        size: 14, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisclaimer(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/settings/disclaimer'),
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white24
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Disclaimer',
                    style: AppTextStyles.playfair(
                      size: 20,
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0B1D3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _legalSection('1. Informational Purposes Only',
                        'Mortgage Pro Global provides mortgage calculators, home loan calculators, EMI calculators, refinancing tools, affordability calculators, property tax estimators, stamp duty calculators, lender information, housing market resources, and educational content. All information, calculators, estimates, tools, and resources are provided solely for general informational and educational purposes. Nothing contained within the App or Website should be interpreted as professional advice.'),
                    _legalSection(
                        '2. Not Financial, Legal, Tax, or Investment Advice',
                        'Mortgage Pro Global is not a bank, mortgage lender, mortgage broker, financial institution, financial advisor, legal advisor, tax advisor, investment advisor, or insurance provider. The App and Website do not provide personalized financial, legal, tax, investment, mortgage, insurance, or accounting advice. Always consult qualified professionals before making financial, legal, tax, or property-related decisions.'),
                    _legalSection('3. Calculator Results Are Estimates',
                        'All calculator results are estimates generated from the information you enter. Results may differ from actual figures due to interest rate changes, loan terms, lending policies, property taxes, insurance premiums, government regulations, bank fees, closing costs, currency fluctuations, local lending requirements, and rounding differences. Calculator outputs should not be considered guarantees, loan approvals, offers, or binding financial information.'),
                    _legalSection('4. Mortgage Rates & Financial Information',
                        'Mortgage Pro Global may display reference mortgage rates, central bank reference rates, housing market information, economic indicators, educational resources, and lender information for general reference only. Rates, fees, lending criteria, government programs, and market conditions frequently change. We do not guarantee that any information displayed is current, complete, or accurate at all times. Always verify information directly with the relevant bank, lender, government authority, or qualified financial professional.'),
                    _legalSection('5. Lender Information',
                        'Lender information is provided for research and comparison purposes only. Mortgage Pro Global does not recommend specific lenders, endorse any lender, negotiate loans, arrange financing, process mortgage applications, approve loans, or guarantee loan availability or eligibility. Your interactions with any lender are solely between you and that lender.'),
                    _legalSection('6. No Professional Relationship',
                        'Your use of Mortgage Pro Global does not create any professional relationship between you and Mortgage Pro Global. No client, advisor, consultant, broker, fiduciary, attorney-client, accountant-client, or lender-borrower relationship is created through your use of the App or Website.'),
                    _legalSection('7. Investment & Property Decisions',
                        'Buying, selling, refinancing, or investing in property involves financial risk. You are solely responsible for evaluating any financial decisions made using information obtained from Mortgage Pro Global. We recommend seeking independent professional advice before making significant financial commitments.'),
                    _legalSection('8. Government Programs',
                        'The App may reference government housing programs, grants, tax benefits, or assistance schemes. Eligibility requirements, funding availability, regulations, and program details may change at any time. Always verify eligibility and current information through the relevant government authority.'),
                    _legalSection('9. No Warranty',
                        'Mortgage Pro Global is provided on an "as is" and "as available" basis. To the fullest extent permitted by applicable law, we make no warranties regarding availability, accuracy, reliability, completeness, fitness for a particular purpose, merchantability, or non-infringement.'),
                    _legalSection('10. Limitation of Liability',
                        'To the maximum extent permitted by applicable law, Mortgage Pro Global, its owners, developers, affiliates, employees, and partners shall not be liable for any loss or damage arising from use of the App or Website, calculator estimates, financial decisions, property purchases, refinancing decisions, loan approvals or rejections, mortgage applications, investment decisions, tax decisions, inaccurate or outdated information, third-party websites, service interruptions, or data loss. You use Mortgage Pro Global entirely at your own risk.'),
                    _legalSection('11. Advertising',
                        'Mortgage Pro Global may display advertisements provided by third-party advertising partners, including Google AdMob. We do not endorse or guarantee products or services advertised within the App or Website. Users should independently evaluate any advertised products or services before making purchasing decisions.'),
                    _legalSection('12. International Users',
                        'Mortgage laws, taxes, lending regulations, and property rules vary by jurisdiction. Information provided may not apply equally in every country, state, province, or region. Users are responsible for ensuring compliance with local laws and regulations.'),
                    _legalSection('13. Contact Us',
                        'Website: mortgageproglobal.com\nEmail: support@mortgageproglobal.com\nContact: mortgageproglobal.com/contact'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: AppTextStyles.dmSans(
                        size: 14, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutUs(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/settings/about'),
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white24
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text('🏢', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'About Us',
                    style: AppTextStyles.playfair(
                      size: 20,
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0B1D3A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _legalSection('Welcome to Mortgage Pro Global',
                        'Mortgage Pro Global is a modern mortgage and home finance platform designed to help people make more informed property financing decisions through reliable calculators, educational resources, and country-specific mortgage tools.\n\nWhether you\'re buying your first home, refinancing an existing mortgage, comparing loan options, or exploring property investment opportunities, our goal is to make mortgage calculations and home finance planning simpler, faster, and more accessible.'),
                    _legalSection('Our Mission',
                        'Our mission is to provide easy-to-use mortgage calculators and educational financial tools that help users better understand home financing across major international mortgage markets. We believe that financial planning should be accessible to everyone, regardless of experience or location.'),
                    _legalSection('What We Offer',
                        'Mortgage Pro Global combines a wide range of home finance tools including Mortgage Payment Calculators, Home Loan EMI Calculators, Mortgage Affordability Calculators, Amortization Schedules, Refinance Calculators, Extra Payment & Early Payoff Calculators, Property Tax Calculators, Stamp Duty Calculators, Debt-to-Income (DTI) Calculators, GDS/TDS Calculators, Country-specific mortgage tools, Housing market resources, Reference interest rate information, Currency conversion tools, and Mortgage lender information. Many core calculators work offline.'),
                    _legalSection('Countries We Support',
                        '🇺🇸 United States  🇨🇦 Canada  🇬🇧 United Kingdom  🇦🇺 Australia  🇳🇿 New Zealand  🇪🇺 Europe  🇮🇳 India\n\nWe continue to improve and expand our coverage with new tools, calculators, and regional features.'),
                    _legalSection('Our Values',
                        'Accuracy — We strive to provide reliable calculators and educational resources based on widely accepted mortgage calculation methods and publicly available reference information.\n\nSimplicity — Financial planning can be complex. We focus on creating clear, intuitive tools that are easy to understand and use.\n\nPrivacy — We value user privacy. Core calculators do not require an account, and we are committed to handling information responsibly.\n\nTransparency — We clearly distinguish between educational content, calculator estimates, and professional financial advice.\n\nContinuous Improvement — We regularly update our App and Website with new calculators, performance improvements, security enhancements, and additional regional features.'),
                    _legalSection('Important Information',
                        'Mortgage Pro Global is an informational and educational platform. We are not a bank, mortgage lender, mortgage broker, financial institution, financial advisor, legal advisor, tax advisor, or investment advisor. We do not approve loans, process mortgage applications, offer financial products, recommend specific lenders, guarantee mortgage rates, or provide personalized financial advice.\n\nCalculator results are estimates only and should be used as a planning aid. Always verify important financial information directly with the relevant lender, financial institution, government authority, or a qualified professional before making financial decisions.'),
                    _legalSection('Contact Us',
                        'Website: mortgageproglobal.com\nSupport: support@mortgageproglobal.com\nPrivacy: privacy@mortgageproglobal.com\nBusiness: business@mortgageproglobal.com\nSecurity: security@mortgageproglobal.com'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: AppTextStyles.dmSans(
                        size: 14, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  Future<void> _launchEmail(String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Could not launch email $emailAddress: $e');
    }
  }

  Widget _buildBodyText(String text, bool isDark) {
    final regex = RegExp(
      r'((?:https?://)?(?:www\.)?mortgageproglobal\.com(?:/[^\s]*)?)|([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.dmSans(
          size: 11,
          height: 1.5,
          color: isDark ? Colors.white60 : const Color(0xFF5B6E8F),
        ),
      );
    }

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final matchText = match.group(0)!;
      final isEmail = matchText.contains('@');

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () {
              if (isEmail) {
                _launchEmail(matchText);
              } else {
                var url = matchText;
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                _launchURL(url);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                matchText,
                style: AppTextStyles.dmSans(
                  size: 11,
                  height: 1.5,
                  color: const Color(0xFF0D9488),
                  weight: FontWeight.w700,
                ).copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.dmSans(
          size: 11,
          height: 1.5,
          color: isDark ? Colors.white60 : const Color(0xFF5B6E8F),
        ),
        children: spans,
      ),
    );
  }

  Widget _legalSection(String title, String body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0B1D3A),
            ),
          ),
          const SizedBox(height: 4),
          _buildBodyText(body, isDark),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  GRADIENT HEADER + PROFILE CARD
//  Note: PRO badge removed — no paid subscription tier in this version.
// ════════════════════════════════════════════════════════════════════════════
class _SettingsHeader extends StatelessWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;
  const _SettingsHeader({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1D3A), Color(0xFF1A3A8F), Color(0xFF0D9488)],
          stops: [0.0, 0.70, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative teal circle (top-right)
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1F0D9488),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: title + help button
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings',
                              style: AppTextStyles.playfair(
                                  size: 22, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Preferences · Account · App',
                              style: AppTextStyles.dmSans(
                                  size: 11, color: Colors.white54)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20)),
                          ),
                          alignment: Alignment.center,
                          child:
                              const Text('❓', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Profile card — no PRO badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [Color(0xFFD97706), Color(0xFFB45309)]),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                                width: 2),
                          ),
                          alignment: Alignment.center,
                          child:
                              const Text('👤', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MORTGAGE PRO GLOBAL',
                                style: AppTextStyles.dmSans(
                                    size: 16,
                                    color: Colors.white,
                                    weight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('support@mortgageproglobal.com',
                                style: AppTextStyles.dmSans(
                                    size: 10, color: Colors.white54)),
                          ],
                        ),
                        // No PRO badge — subscription not implemented
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ════════════════════════════════════════════════════════════════════════════
class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(text.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 11, color: _C.muted, weight: FontWeight.w700)),
    );
  }
}

class _SetGroup extends StatelessWidget {
  final List<Widget> children;
  const _SetGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SetItem extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String name;
  final String desc;
  final Widget trailing;
  final bool isLast;
  final VoidCallback? onTap;

  const _SetItem({
    required this.icon,
    required this.iconBg,
    required this.name,
    required this.desc,
    required this.trailing,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: _C.border)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: AppTextStyles.dmSans(
                      size: 13, color: _C.navy, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(desc,
                  style: AppTextStyles.dmSans(size: 10, color: _C.muted)),
            ]),
          ),
          trailing,
        ]),
      ),
    );
  }
}

// Animated toggle
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? _C.teal : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetValue extends StatelessWidget {
  final String text;
  const _SetValue(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(text,
          style: AppTextStyles.dmSans(
              size: 11, color: _C.teal, weight: FontWeight.w700)),
      const SizedBox(width: 6),
      Text('›',
          style:
              TextStyle(fontSize: 16, color: _C.navy.withValues(alpha: 0.20))),
    ]);
  }
}

class _SetArrow extends StatelessWidget {
  final bool isRed;
  const _SetArrow({this.isRed = false});
  @override
  Widget build(BuildContext context) {
    return Text('›',
        style: TextStyle(
            fontSize: 16,
            color: isRed
                ? const Color(0xFFB91C1C)
                : _C.navy.withValues(alpha: 0.20)));
  }
}

// ── Active ad-free session badge for the settings row ────────────────────
class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.30)),
      ),
      child: Text(
        'Active',
        style: AppTextStyles.dmSans(
          size: 10,
          color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── App Info footer ──────────────────────────────────────────────────────
class _AppInfo extends StatelessWidget {
  const _AppInfo();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        Text('MortgagePro Global',
            style: AppTextStyles.dmSans(
                size: 13, color: _C.navy, weight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text('Version 1.0.0 · REO Technologies · © 2026',
            style: AppTextStyles.dmSans(size: 11, color: _C.muted)),
      ]),
    );
  }
}
