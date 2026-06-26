// lib/screens/privacy/privacy_policy_screen.dart

import 'package:flutter/material.dart';

/// PrivacyPolicyScreen — Scrollable privacy policy for MortgagePro Global.
///
/// All colours from [Theme.of(context).colorScheme] only.
/// Supports system / light / dark themes.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildLastUpdated(cs, tt),
          const SizedBox(height: 20),
          _buildIntro(cs, tt),
          const SizedBox(height: 24),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '1. Information We Collect',
            body: 'MortgagePro Global does not collect personally identifiable '
                'information (PII) such as your name, email address, phone '
                'number, or precise location. We collect anonymised usage data '
                'to improve app performance and user experience. This includes '
                'event data such as which calculator types are used, which '
                'country screens are visited, and general feature engagement '
                'metrics. No financial input data entered into any calculator '
                'is transmitted to our servers.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '2. How We Use Information',
            body: 'Anonymised usage analytics are used solely to improve the '
                'quality, reliability, and feature set of MortgagePro Global. '
                'Crash reports collected via Firebase Crashlytics help us '
                'identify and resolve technical issues promptly. Ad revenue '
                'data collected via Google AdMob is used for business '
                'operations and is processed in accordance with Google\'s '
                'privacy policies.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '3. Third-Party Services',
            body: 'This app uses the following third-party services, each '
                'governed by their own privacy policies:\n\n'
                '• Google Firebase Analytics — usage analytics\n'
                '• Google Firebase Crashlytics — crash reporting\n'
                '• Google Firebase Performance — performance monitoring\n'
                '• Google Firebase Remote Config — remote feature flags\n'
                '• Google AdMob — advertising\n'
                '• Google Firebase App Check — app integrity\n\n'
                'We do not sell or share your data with any other third '
                'parties beyond those listed above.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '4. Advertising & Consent',
            body: 'We display advertisements served by Google AdMob. In '
                'regions governed by GDPR (EEA, UK, Switzerland) or applicable '
                'US state privacy laws (CPRA, CPA, VCDPA, CTDPA, UCPA), you '
                'will be shown a consent form before any personalised ads are '
                'displayed. You may update your ad preferences at any time via '
                'Settings \u2192 Privacy Center \u2192 Ad Preferences.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '5. Data Retention',
            body: 'Anonymised analytics and crash data are retained by '
                'Firebase in accordance with Google\'s data retention '
                'policies. Calculator inputs and saved calculations are stored '
                'locally on your device only and are never transmitted to '
                'external servers. You may delete all locally saved '
                'calculations at any time from the Saved screen.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '6. Children\'s Privacy',
            body: 'MortgagePro Global is not directed at children under the '
                'age of 13 (or 16 in the EEA). We do not knowingly collect '
                'information from children. If you believe a child has '
                'provided information through this app, please contact us '
                'immediately.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '7. Your Rights',
            body: 'Depending on your jurisdiction, you may have the right to '
                'access, rectify, erase, or restrict the processing of your '
                'personal data. Since MortgagePro Global does not collect PII, '
                'most such requests are satisfied by the absence of personal '
                'data. For data held by Google Firebase or AdMob, please refer '
                'to Google\'s privacy controls at myaccount.google.com.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '8. App Tracking Transparency (iOS)',
            body: 'On iOS, we request App Tracking Transparency (ATT) '
                'permission in accordance with Apple\'s guidelines. Your '
                'decision regarding ATT affects whether ads are personalised '
                'but does not affect access to any app features.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '9. Changes to This Policy',
            body: 'We may update this Privacy Policy from time to time. '
                'Changes will be reflected by an updated "Last updated" date '
                'at the top of this screen. Continued use of the app after '
                'changes are published constitutes your acceptance of the '
                'updated policy.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '10. Contact Us',
            body: 'If you have questions or concerns about this Privacy '
                'Policy, please contact REO Technologies at:\n\n'
                'Email: privacy@reotechnologies.com\n'
                'Address: REO Technologies, [Address Placeholder]',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLastUpdated(ColorScheme cs, TextTheme tt) {
    return Text(
      'Last updated: June 2026',
      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    );
  }

  Widget _buildIntro(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy',
          style: tt.headlineSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'REO Technologies ("we", "our", or "us") built MortgagePro Global '
          'as a commercial application. This page informs you of our policies '
          'regarding the collection, use, and disclosure of information when '
          'you use our app.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required ColorScheme cs,
    required TextTheme tt,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: cs.primary, width: 3),
              ),
            ),
            child: Text(
              title,
              style: tt.titleSmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
