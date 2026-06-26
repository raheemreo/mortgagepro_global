// lib/screens/privacy/terms_screen.dart

import 'package:flutter/material.dart';

/// TermsScreen — Scrollable Terms & Conditions for MortgagePro Global.
///
/// All colours from [Theme.of(context).colorScheme] only.
/// Supports system / light / dark themes.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
            title: '1. Acceptance of Terms',
            body: 'By downloading, installing, or using MortgagePro Global '
                '("the App"), you agree to be bound by these Terms & '
                'Conditions. If you do not agree to these terms, please '
                'uninstall the App and discontinue use immediately. These '
                'terms apply to all users of the App regardless of the device '
                'or platform used.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '2. Description of Service',
            body: 'MortgagePro Global is a mortgage and loan calculator '
                'application that provides financial computation tools for '
                'multiple countries including the USA, Canada, United Kingdom, '
                'Australia, New Zealand, India, and the European Union. The '
                'App provides estimates and calculations for informational '
                'purposes only and does not constitute financial, legal, or '
                'tax advice.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '3. No Financial Advice',
            body: 'All calculations, estimates, amortisation schedules, '
                'affordability assessments, and interest rate information '
                'provided by the App are for informational and illustrative '
                'purposes only. Results may not reflect actual loan terms, '
                'rates, or conditions offered by any lender. You should '
                'consult a qualified financial adviser, mortgage broker, or '
                'lender before making any financial decisions. REO '
                'Technologies accepts no liability for decisions made based '
                'on App outputs.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '4. Accuracy of Information',
            body: 'While we strive to provide accurate and up-to-date '
                'information, REO Technologies makes no warranties or '
                'representations, express or implied, regarding the accuracy, '
                'completeness, or suitability of any information within the '
                'App. Interest rates, tax rates, regulatory thresholds, and '
                'lending criteria change frequently and may differ from those '
                'used in the App\'s calculations.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '5. Intellectual Property',
            body: 'All content, design, code, graphics, and features within '
                'MortgagePro Global are the exclusive intellectual property of '
                'REO Technologies and are protected by applicable copyright, '
                'trademark, and intellectual property laws. You may not copy, '
                'modify, distribute, sell, or create derivative works based on '
                'any part of the App without prior written consent from REO '
                'Technologies.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '6. Permitted Use',
            body: 'You are granted a limited, non-exclusive, non-transferable, '
                'revocable licence to use the App for personal, '
                'non-commercial purposes only. You must not:\n\n'
                '\u2022 Reverse engineer, decompile, or disassemble the App\n'
                '\u2022 Use the App for any unlawful or fraudulent purpose\n'
                '\u2022 Attempt to gain unauthorised access to any part of the App '
                'or its related systems\n'
                '\u2022 Use automated tools or bots to interact with the App\n'
                '\u2022 Reproduce or redistribute the App or its content',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '7. Advertising',
            body: 'The App is supported by advertising provided by Google '
                'AdMob. Advertisements are displayed in accordance with '
                'applicable privacy regulations and your consent choices. We '
                'are not responsible for the content of third-party '
                'advertisements. Clicking on advertisements may direct you to '
                'third-party websites or applications governed by their own '
                'terms and privacy policies.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '8. In-App Features',
            body: 'Certain features of the App, such as rewarded content, may '
                'require viewing an advertisement. Participation in rewarded '
                'ad experiences is entirely voluntary. No core calculator '
                'functionality is gated behind any advertisement or payment.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '9. Limitation of Liability',
            body: 'To the fullest extent permitted by applicable law, REO '
                'Technologies shall not be liable for any indirect, '
                'incidental, special, consequential, or punitive damages '
                'arising from your use of or inability to use the App, '
                'including but not limited to financial losses resulting from '
                'reliance on App calculations. In no event shall our total '
                'liability to you exceed the amount you have paid for the App '
                'in the twelve months preceding the claim.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '10. Disclaimer of Warranties',
            body: 'The App is provided on an "as is" and "as available" basis '
                'without any warranties of any kind, either express or '
                'implied, including but not limited to implied warranties of '
                'merchantability, fitness for a particular purpose, or '
                'non-infringement. We do not warrant that the App will be '
                'error-free, uninterrupted, or free of viruses or other '
                'harmful components.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '11. Governing Law',
            body: 'These Terms & Conditions shall be governed by and construed '
                'in accordance with the laws applicable to REO Technologies\' '
                'principal place of business. Any disputes arising under these '
                'terms shall be subject to the exclusive jurisdiction of the '
                'courts of that jurisdiction.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '12. Changes to Terms',
            body: 'REO Technologies reserves the right to modify these Terms '
                '& Conditions at any time. Changes will be effective '
                'immediately upon posting within the App. Your continued use '
                'of the App following any changes constitutes your acceptance '
                'of the revised terms. It is your responsibility to review '
                'these terms periodically.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '13. Termination',
            body: 'REO Technologies reserves the right to terminate or suspend '
                'your access to the App at any time, without notice, for '
                'conduct that violates these Terms & Conditions or is harmful '
                'to other users, us, or third parties, or for any other reason '
                'at our sole discretion.',
          ),
          _buildSection(
            cs: cs,
            tt: tt,
            title: '14. Contact Us',
            body: 'If you have any questions about these Terms & Conditions, '
                'please contact REO Technologies at:\n\n'
                'Email: reodevelopers@gmail.com\n'
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
          'Terms & Conditions',
          style: tt.headlineSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please read these Terms & Conditions carefully before using '
          'MortgagePro Global. These terms constitute a legally binding '
          'agreement between you and REO Technologies.',
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
              color: cs.tertiaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: cs.tertiary, width: 3),
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
