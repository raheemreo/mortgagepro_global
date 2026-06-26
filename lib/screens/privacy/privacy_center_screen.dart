// lib/screens/privacy/privacy_center_screen.dart

import 'package:flutter/material.dart';

import '../../services/consent_service.dart';
import '../../services/remote_config_service.dart';
import 'ad_preferences_screen.dart';
import 'consent_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

/// PrivacyCenterScreen — Top-level hub linking all privacy-related screens.
///
/// Navigation targets:
///   • Privacy Policy         → PrivacyPolicyScreen
///   • Terms & Conditions     → TermsScreen
///   • Consent Settings       → ConsentSettingsScreen
///   • Ad Preferences         → AdPreferencesScreen
///
/// All colours from [Theme.of(context).colorScheme] only.
/// Supports system / light / dark themes.
class PrivacyCenterScreen extends StatelessWidget {
  const PrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isConsentGranted = ConsentService.instance.isConsentGranted;
    final adsEnabled = RemoteConfigService.instance.adsEnabled;
    final canPersonalized = ConsentService.instance.canShowPersonalizedAds;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Privacy Center'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Header description ──────────────────────────────────────────
          _HeaderCard(cs: cs, tt: tt),
          const SizedBox(height: 24),

          // ── Legal section ───────────────────────────────────────────────
          _SectionLabel(cs: cs, tt: tt, label: 'Legal'),
          const SizedBox(height: 8),
          _NavTile(
            cs: cs,
            tt: tt,
            icon: Icons.policy_outlined,
            iconBgColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            title: 'Privacy Policy',
            subtitle: 'How we collect, use, and protect your data.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            cs: cs,
            tt: tt,
            icon: Icons.gavel_rounded,
            iconBgColor: cs.secondaryContainer,
            iconColor: cs.onSecondaryContainer,
            title: 'Terms & Conditions',
            subtitle: 'Your agreement with REO Technologies.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TermsScreen(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Advertising section ─────────────────────────────────────────
          _SectionLabel(cs: cs, tt: tt, label: 'Advertising'),
          const SizedBox(height: 8),
          _NavTile(
            cs: cs,
            tt: tt,
            icon: Icons.tune_rounded,
            iconBgColor: cs.tertiaryContainer,
            iconColor: cs.onTertiaryContainer,
            title: 'Consent Settings',
            subtitle: 'Review or update your ad consent preferences.',
            badge: !isConsentGranted ? 'Action needed' : null,
            badgeColor: cs.error,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConsentSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            cs: cs,
            tt: tt,
            icon: Icons.ads_click_rounded,
            iconBgColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            title: 'Ad Preferences',
            subtitle: 'See which ad formats are active and how ads are shown.',
            badge: canPersonalized ? 'Personalised' : null,
            badgeColor: cs.primary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdPreferencesScreen(),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Summary status ──────────────────────────────────────────────
          _StatusSummaryCard(
            cs: cs,
            tt: tt,
            isConsentGranted: isConsentGranted,
            adsEnabled: adsEnabled,
            canPersonalized: canPersonalized,
          ),

          const SizedBox(height: 24),

          // ── Footer ──────────────────────────────────────────────────────
          _Footer(cs: cs, tt: tt),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.55),
            cs.secondaryContainer.withValues(alpha: 0.30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, size: 28, color: cs.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy',
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your data, consent, and advertising preferences '
                  'from one place. Your choices take effect immediately.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.cs,
    required this.tt,
    required this.label,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Navigation tile ───────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant, width: 0.5),
          ),
          child: Row(
            children: [
              // ── Icon chip ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              // ── Text ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor?.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: badgeColor?.withValues(alpha: 0.4) ??
                                    cs.outlineVariant,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: tt.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── Chevron ───────────────────────────────────────────────
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status summary card ───────────────────────────────────────────────────────

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.cs,
    required this.tt,
    required this.isConsentGranted,
    required this.adsEnabled,
    required this.canPersonalized,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final bool isConsentGranted;
  final bool adsEnabled;
  final bool canPersonalized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Status',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            cs: cs,
            tt: tt,
            label: 'Advertising',
            value: adsEnabled ? 'Active' : 'Disabled',
            icon: adsEnabled
                ? Icons.check_circle_outline_rounded
                : Icons.block_rounded,
            iconColor: adsEnabled ? cs.primary : cs.error,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            cs: cs,
            tt: tt,
            label: 'Consent',
            value: isConsentGranted ? 'Granted' : 'Not granted',
            icon: isConsentGranted
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            iconColor: isConsentGranted ? cs.primary : cs.error,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            cs: cs,
            tt: tt,
            label: 'Ad Type',
            value: canPersonalized ? 'Personalised' : 'Non-personalised',
            icon: canPersonalized
                ? Icons.person_pin_circle_outlined
                : Icons.person_off_outlined,
            iconColor: canPersonalized ? cs.primary : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.cs,
    required this.tt,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Text(
      'MortgagePro Global by REO Technologies.\n'
      'Advertising powered by Google AdMob.',
      textAlign: TextAlign.center,
      style: tt.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        height: 1.5,
      ),
    );
  }
}
