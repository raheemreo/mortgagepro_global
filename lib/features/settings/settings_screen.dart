// lib/features/settings/settings_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      builder: (_) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg =
            isDark ? const Color(0xFF141C33) : Colors.white;
        final handleColor =
            isDark ? Colors.white24 : const Color(0xFFE2E8F0);
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
                      size: 13,
                      color: _C.muted,
                      weight: FontWeight.w400),
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
                              ? optAccent.withValues(alpha: isDark ? 0.15 : 0.08)
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
                                              Colors.white.withValues(alpha: 0.10),
                                              Colors.white.withValues(alpha: 0.06),
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
                                          color: gradEnd.withValues(alpha: 0.35),
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
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
                  _legalSection('1. Data We Collect',
                      'We prioritize your privacy. MortgagePro Global does not collect, sell, or share personal user data or mortgage calculation histories. All data remains stored locally on your device.'),
                  _legalSection('2. How We Use Information',
                      'Any input provided to our calculators, including interest rates, property values, and financial indicators, is processed in-memory locally. If you use the Gemini AI Mortgage Advisor, query inputs are sent securely to Google AI APIs and are not stored by REO Technologies.'),
                  _legalSection('3. Analytics & Cookies',
                      'We do not deploy third-party advertising cookies or trackers. We may collect anonymous crash reports and application usage metrics to improve stability and performance.'),
                  _legalSection('4. Security',
                      'Industry-standard protocols are used to secure your local preferences (like favorite countries, currency choices, and saved mortgage scenarios). However, users are encouraged to maintain basic device security.'),
                  _legalSection('5. Policy Updates',
                      'This policy may change occasionally. Check the settings panel inside the app for the latest updates. Contact us at support@mortgageproglobal.com for concerns.'),
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
    );
  }

  void _showTermsOfService(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
                  _legalSection('1. Agreement to Terms',
                      'By using MortgagePro Global, you agree to comply with and be bound by these Terms of Service. If you disagree with any part, please discontinue use.'),
                  _legalSection('2. Financial Disclaimer',
                      'This application is designed for educational and informational purposes only. The estimates, values, interest rates, and loan structures provided are calculations based on mathematical models and do not constitute professional financial, tax, or legal advice. Always consult a certified mortgage advisor before committing to financial decisions.'),
                  _legalSection('3. AI Advisor Usage',
                      'The Gemini AI Mortgage Advisor generates text using third-party large language models. The accuracy, completeness, or suitability of AI-generated answers cannot be guaranteed. REO Technologies is not liable for errors or discrepancies.'),
                  _legalSection('4. Account & Subscription',
                      'MortgagePro PRO subscriptions are managed via Google Play Store / Apple App Store. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Charges are non-refundable.'),
                  _legalSection('5. Limitation of Liability',
                      'In no event shall REO Technologies, its directors, or affiliates be liable for direct, indirect, special, incidental, or consequential damages resulting from the use or inability to use this application.'),
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
          Text(
            body,
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.5,
              color: isDark ? Colors.white60 : const Color(0xFF5B6E8F),
            ),
          ),
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
