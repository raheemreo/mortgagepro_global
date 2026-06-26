// lib/screens/privacy/consent_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/consent_service.dart';
import '../../services/crashlytics_service.dart';

/// ConsentSettingsScreen — Allows the user to review and update their ad
/// consent preferences at any time.
///
/// Presents the UMP privacy options form via
/// [ConsentService.instance.showPrivacyOptionsForm()] when the form
/// is applicable in the user's jurisdiction.
///
/// Displays the current [ConsentStatus] for transparency.
/// All colours from [Theme.of(context).colorScheme] only.
class ConsentSettingsScreen extends StatefulWidget {
  const ConsentSettingsScreen({super.key});

  @override
  State<ConsentSettingsScreen> createState() => _ConsentSettingsScreenState();
}

class _ConsentSettingsScreenState extends State<ConsentSettingsScreen> {
  bool _isLoading = true; // true while async privacy status is being resolved
  bool _privacyRequired = false;

  @override
  void initState() {
    super.initState();
    _resolvePrivacyStatus();
  }

  /// Resolves getPrivacyOptionsRequirementStatus() asynchronously.
  /// In google_mobile_ads v5 this is a Future — never a sync getter.
  Future<void> _resolvePrivacyStatus() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      if (mounted) {
        setState(() {
          _privacyRequired = status == PrivacyOptionsRequirementStatus.required;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'ConsentSettingsScreen._resolvePrivacyStatus() failed',
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Human-readable label for the current [ConsentStatus].
  ///
  /// ConsentStatus values in google_mobile_ads v5:
  ///   obtained    — user explicitly granted consent.
  ///   notRequired — outside a regulated region; ads allowed.
  ///   required    — consent required but not yet obtained.
  ///   unknown     — status is undetermined.
  String _statusLabel(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.obtained:
        return 'Consent Granted';
      case ConsentStatus.notRequired:
        return 'Not Required in Your Region';
      case ConsentStatus.required:
        return 'Consent Required';
      case ConsentStatus.unknown:
        return 'Unknown';
    }
  }

  Color _statusColor(ConsentStatus status, ColorScheme cs) {
    switch (status) {
      case ConsentStatus.obtained:
      case ConsentStatus.notRequired:
        return cs.primary;
      case ConsentStatus.required:
        return cs.error;
      case ConsentStatus.unknown:
        return cs.onSurfaceVariant;
    }
  }

  IconData _statusIcon(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.obtained:
      case ConsentStatus.notRequired:
        return Icons.check_circle_outline_rounded;
      case ConsentStatus.required:
        return Icons.warning_amber_rounded;
      case ConsentStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openPrivacyOptions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ConsentService.instance.showPrivacyOptionsForm(context);
      // Re-resolve after form dismissal to reflect updated status.
      if (mounted) await _resolvePrivacyStatus();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'ConsentSettingsScreen._openPrivacyOptions() failed',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open privacy options. Try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = ConsentService.instance.currentStatus;
    final canShowPersonalized = ConsentService.instance.canShowPersonalizedAds;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Consent Settings'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: cs.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ── Status card ───────────────────────────────────────────
                _StatusCard(
                  cs: cs,
                  tt: tt,
                  status: status,
                  statusLabel: _statusLabel(status),
                  statusColor: _statusColor(status, cs),
                  statusIcon: _statusIcon(status),
                  canShowPersonalized: canShowPersonalized,
                ),

                const SizedBox(height: 20),

                // ── Explanation ───────────────────────────────────────────
                _ExplanationCard(cs: cs, tt: tt),

                const SizedBox(height: 20),

                // ── Privacy options form button ────────────────────────────
                if (_privacyRequired) ...[
                  _UpdateConsentButton(
                    cs: cs,
                    tt: tt,
                    isLoading: _isLoading,
                    onTap: _openPrivacyOptions,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Not applicable notice ─────────────────────────────────
                if (!_privacyRequired)
                  _NotApplicableCard(cs: cs, tt: tt, status: status),

                const SizedBox(height: 24),

                // ── Info footer ───────────────────────────────────────────
                _InfoFooter(cs: cs, tt: tt),

                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.cs,
    required this.tt,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.canShowPersonalized,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final ConsentStatus status;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final bool canShowPersonalized;

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
            'Current Ad Consent Status',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(statusIcon, size: 22, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 10),
          _StatusRow(
            cs: cs,
            tt: tt,
            label: 'Personalised Ads',
            value: canShowPersonalized ? 'Enabled' : 'Disabled',
            valueColor: canShowPersonalized ? cs.primary : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.cs,
    required this.tt,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Explanation card ──────────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

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
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'About Ad Personalisation',
                style: tt.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'MortgagePro Global is supported by advertising. In regions '
            'governed by GDPR or applicable US state privacy laws, you have '
            'the right to control whether personalised ads are shown to you.\n\n'
            'Personalised ads use data to show you more relevant '
            'advertisements. Non-personalised ads do not use personal data '
            'but may still appear based on your approximate location or '
            'app context.\n\n'
            'Your consent choice does not affect access to any app features.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Update consent button ─────────────────────────────────────────────────────

class _UpdateConsentButton extends StatelessWidget {
  const _UpdateConsentButton({
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
                const Icon(Icons.tune_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Update Privacy Preferences',
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

// ── Not applicable card ───────────────────────────────────────────────────────

class _NotApplicableCard extends StatelessWidget {
  const _NotApplicableCard({
    required this.cs,
    required this.tt,
    required this.status,
  });

  final ColorScheme cs;
  final TextTheme tt;
  final ConsentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status == ConsentStatus.notRequired
                  ? 'Ad consent management is not required in your region. '
                      'Ads are displayed in accordance with applicable laws '
                      'without a consent requirement.'
                  : 'Privacy preference options are not currently available. '
                      'Please try again later.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info footer ───────────────────────────────────────────────────────────────

class _InfoFooter extends StatelessWidget {
  const _InfoFooter({required this.cs, required this.tt});

  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Powered by Google User Messaging Platform (UMP). '
      'Consent data is managed by Google and is not stored '
      'by REO Technologies.',
      textAlign: TextAlign.center,
      style: tt.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        height: 1.5,
      ),
    );
  }
}
