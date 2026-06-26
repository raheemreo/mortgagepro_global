// lib/features/settings/feedback_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/text_styles.dart';

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

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'General Feedback';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General Feedback',
    'Bug Report',
    'Feature Request',
    'Calculator Issue',
    'Other'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final category = _selectedCategory;
    final subjectText = _subjectController.text.trim();
    final emailText = _emailController.text.trim();
    final messageText = _messageController.text.trim();

    try {
      String appVersion = 'unknown';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {
        // Non-critical: proceed without version info if this fails.
      }

      await FirebaseFirestore.instance.collection('feedback').add({
        'category': category,
        'senderEmail': emailText,
        'subject': subjectText,
        'message': messageText,
        'appVersion': appVersion,
        'platform': 'android',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      }).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Firestore write timed out'),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks! Your feedback has been sent.'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Firestore write failed (e.g. offline) — fall back to mailto, then clipboard.
      await _fallbackToEmail(category, subjectText, emailText, messageText);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _fallbackToEmail(
    String category,
    String subjectText,
    String emailText,
    String messageText,
  ) async {
    final String subject = '[$category] $subjectText';
    final String body = 'Category: $category\n'
        'Sender Email: $emailText\n\n'
        'Message:\n$messageText\n\n'
        '---\n'
        'Sent via Mortgage Pro Global App';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@mortgageproglobal.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (!mounted) return;
        _copyToClipboardAndShowSnackBar(context, body);
      }
    } catch (e) {
      if (!mounted) return;
      _copyToClipboardAndShowSnackBar(context, body);
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _copyToClipboardAndShowSnackBar(BuildContext context, String fullBody) {
    Clipboard.setData(
        ClipboardData(text: 'support@mortgageproglobal.com\n\n$fullBody'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Could not send feedback. Details copied to clipboard — please email us manually.'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _C.update(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0A0F1E) : const Color(0xFF0B1D3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feedback & Support',
          style: AppTextStyles.playfair(size: 18, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top intro card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We\'d love to hear from you!',
                        style: AppTextStyles.dmSans(
                          size: 15,
                          weight: FontWeight.w800,
                          color: _C.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Have a suggestion, found a bug, or need help? Fill out the form below or email us directly at support@mortgageproglobal.com.',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          color: _C.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Field
                Text(
                  'FEEDBACK CATEGORY',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _C.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      dropdownColor: Theme.of(context).cardColor,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w700,
                        color: _C.navy,
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sender Email Field
                Text(
                  'YOUR EMAIL ADDRESS',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _C.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.dmSans(
                      size: 14, color: _C.navy, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: AppTextStyles.dmSans(size: 14, color: _C.muted),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _C.teal, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB91C1C)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFB91C1C), width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Subject Field
                Text(
                  'SUBJECT',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _C.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.dmSans(
                      size: 14, color: _C.navy, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'What is this regarding?',
                    hintStyle: AppTextStyles.dmSans(size: 14, color: _C.muted),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _C.teal, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB91C1C)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFB91C1C), width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Message / Feedback Field
                Text(
                  'MESSAGE / FEEDBACK',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: _C.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  maxLines: 8,
                  minLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.dmSans(
                      size: 14, color: _C.navy, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Describe your feedback or issue in detail...',
                    hintStyle: AppTextStyles.dmSans(size: 14, color: _C.muted),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _C.teal, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB91C1C)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFB91C1C), width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _sendFeedback,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send Feedback',
                            style: AppTextStyles.dmSans(
                              size: 15,
                              color: Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
