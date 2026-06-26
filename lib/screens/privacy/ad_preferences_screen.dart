// lib/screens/privacy/ad_preferences_screen.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/consent_service.dart';
import '../../services/crashlytics_service.dart';
import '../../services/remote_config_service.dart';

/// AdPreferencesScreen — Displays current ad personalisation preferences and
/// links to the UMP privacy options form for users who wish to update them.
///
/// This screen is informational. Preference changes are made via the UMP form
/// launched by the "Manage Ad Preferences" button.
///
/// All colours from [Theme.of(context).colorScheme] only.
/// Supports system / light / dark themes.
class AdPreferencesScreen extends StatefulWidget {
  const AdPreferencesScreen({super.key});

  @override
  State<AdPreferencesScreen> createState() => _AdPreferencesScreenState();
}

class _AdPreferencesScreenState extends State<AdPreferencesScreen> {
  bool _isLoading = false;
  bool _privacyRequired = false;

  @override
  void initState() {
    super.initState();
    _resolvePrivacyStatus();
  }

  /// getPrivacyOptionsRequirementStatus() is async in google_mobile_ads v5.
  Future<void> _resolvePrivacyStatus() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (mounted) {
        setState(() {
          _privacyRequired =
              status == PrivacyOptionsRequirementStatus.required;
        });
      }
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AdPreferencesScreen._resolvePrivacyStatus() failed',
      );
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openPrivacyOptions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ConsentService.instance.showPrivacyOptionsForm(context);
      if (mounted) setState(() {});
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AdPreferencesScreen._openPrivacyOptions() failed',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to open ad preferences. Please try again.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isConsentGranted = ConsentService.instance.isConsentGranted;
    final canPersonalized = ConsentService.instance.canShowPersonalizedAds;
    final adsEnabled = RemoteConfigService.instance.adsEnabled;
    final disableInterstitials =
        RemoteConfigService.instance.disableInterstitials;
    final disableRewarded = RemoteConfigService.instance.disableRewarded;
    final showBanner = RemoteConfigService.instance.showBannerAd;
    final showNative = RemoteConfigService.instance.showNativeAd;
    final showRewarded = RemoteConfigService.instance.showRewardedAd;
    // _privacyRequired is resolved asynchronously in initState()
    // and updated in setState() — never read synchronously here.

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Ad Preferences'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Personalisation status ──────────────────────────────────────
          _SectionHeader(cs: cs, tt: tt, title: 'Personalisation'),
          const SizedBox(height: 10),
          _PreferenceCard(
            cs: cs,
            tt: tt,
            icon: canPersonalized
                ? Icons.person_pin_circle_outlined
                : Icons.person_off_outlined,
            iconColor: canPersonalized ? cs.primary : cs.onSurfaceVariant,
            label: 'Personalised Ads',
            value: canPersonalized ? 'On' : 'Off',
            valueColor: canPersonalized ? cs.primary : cs.onSurfaceVariant,
            description: canPersonalized
                ? 'Ads are tailored based on your interests and app activity.'
                : 'Ads are shown without personalisation. Your data is not '
                    'used for ad targeting.',
          ),

          const SizedBox(height: 20),

          // ── Ad format status ────────────────────────────────────────────
          _SectionHeader(cs: cs, tt: tt, title: 'Active Ad Formats'),
          const SizedBox(height: 10),
          _PreferenceCard(
            cs: cs,
            tt: tt,
            icon: Icons.view_compact_alt_rounded,
            iconColor:
                (adsEnabled && showBanner) ? cs.primary : cs.onSurfaceVariant,
            label: 'Banner Ads',
            value: (!adsEnabled || !showBanner) ? 'Off' : 'On',
            valueColor:
                (!adsEnabled || !showBanner) ? cs.onSurfaceVariant : cs.primary,
            description: 'Displayed at the bottom of result screens.',
          ),
          const SizedBox(height: 8),
          _PreferenceCard(
            cs: cs,
            tt: tt,
            icon: Icons.article_outlined,
            iconColor:
                (adsEnabled && showNative) ? cs.primary : cs.onSurfaceVariant,
            label: 'Native Ads',
            value: (!adsEnabled || !showNative) ? 'Off' : 'On',
            valueColor:
                (!adsEnabled || !showNative) ? cs.onSurfaceVariant : cs.primary,
            description: 'Shown inline within content sections.',
          ),
          const SizedBox(height: 8),
          _PreferenceCard(
            cs: cs,
            tt: tt,
            icon: Icons.fullscreen_rounded,
            iconColor: (!adsEnabled || disableInterstitials)
                ? cs.onSurfaceVariant
                : cs.primary,
            label: 'Interstitial Ads',
            value: (!adsEnabled || disableInterstitials) ? 'Off' : 'On',
            valueColor: (!adsEnabled || disableInterstitials)
                ? cs.onSurfaceVariant
                : cs.primary,
            description:
                'Shown between screens after calculation results are viewed.',
          ),
          const SizedBox(height: 8),
          _PreferenceCard(
            cs: cs,
            tt: tt,
            icon: Icons.play_circle_outline_rounded,
            iconColor: (!adsEnabled || !showRewarded || disableRewarded)
                ? cs.onSurfaceVariant
                : cs.primary,
            label: 'Rewarded Ads',
            value: (!adsEnabled || !showRewarded || disableRewarded)
                ? 'Off'
                : 'On',
            valueColor: (!adsEnabled || !showRewarded || disableRewarded)
                ? cs.onSurfaceVariant
                : cs.primary,
            description:
                'Voluntary \u2014 watch to unlock bonus reports or features.',
          ),

          const SizedBox(height: 20),

          // ── Consent gate status ─────────────────────────────────────────
          _SectionHeader(cs: cs, tt: tt, title: 'Consent'),
          const SizedBox(height: 10),
          _ConsentStatusCard(
            cs: cs,
            tt: tt,
            isConsentGranted: isConsentGranted,
          ),

          const SizedBox(height: 20),

          // ── Manage preferences button ───────────────────────────────────
          if (_privacyRequired) ...[
            _ManageButton(
              cs: cs,
              tt: tt,
              isLoading: _isLoading,
              onTap: _openPrivacyOptions,
            ),
            const SizedBox(height: 12),
          ],

          if (!_privacyRequired) _NotRequiredNotice(cs: cs, tt: tt),

          const SizedBox(height: 24),

          // ── Footer note ─────────────────────────────────────────────────
          _FooterNote(cs: cs, tt: tt),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.cs,
    required this.tt,
    required this.title,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Preference card ───────────────────────────────────────────────────────────

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.description,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: tt.labelMedium?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
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

// ── Consent status card ───────────────────────────────────────────────────────

class _ConsentStatusCard extends StatelessWidget {
  const _ConsentStatusCard({
    required this.cs,
    required this.tt,
    required this.isConsentGranted,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final bool isConsentGranted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            isConsentGranted
                ? Icons.shield_outlined
                : Icons.shield_moon_outlined,
            size: 20,
            color: isConsentGranted ? cs.primary : cs.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConsentGranted
                  ? 'Ads are active. Consent is granted or not required in '
                      'your region.'
                  : 'Ads are paused. Consent is required but has not been '
                      'granted.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Manage button ─────────────────────────────────────────────────────────────

class _ManageButton extends StatelessWidget {
  const _ManageButton({
    required this.cs,
    required this.tt,
    required this.isLoading,
    required this.onTap,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onPrimary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Manage Ad Preferences',
                  style: tt.labelLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Not required notice ───────────────────────────────────────────────────────

class _NotRequiredNotice extends StatelessWidget {
  const _NotRequiredNotice({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ad preference management is not required in your region. '
              'No further action is needed.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer note ───────────────────────────────────────────────────────────────

class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ad formats marked "Off" are disabled by the app and cannot be '
      'changed from this screen. Ad personalisation is managed via the '
      'Google User Messaging Platform (UMP).',
      textAlign: TextAlign.center,
      style: tt.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }
}
