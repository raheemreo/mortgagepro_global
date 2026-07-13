// lib/services/rating_service.dart

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/theme/text_styles.dart';
import 'analytics_service.dart';

class RatingService {
  RatingService._();
  static final RatingService instance = RatingService._();

  static const String _keyHasRated = 'rating_has_rated';
  static const String _keyHasDeclined = 'rating_has_declined';
  static const String _keyCompletedCalculations =
      'rating_completed_calculations';
  static const String _keyCalculationsAtLastPrompt =
      'rating_calculations_at_last_prompt';
  static const String _keyLastPromptDate = 'rating_last_prompt_date';

  // Constants
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.reotech.mortgagepro_global';
  static const String _marketUrl =
      'market://details?id=com.reotech.mortgagepro_global';

  /// Records app launch for install age and count threshold checking.
  Future<void> recordAppLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Set first launch date if not already set
      if (prefs.getString('rating_first_launch_date') == null) {
        await prefs.setString(
            'rating_first_launch_date', DateTime.now().toIso8601String());
      }

      // Increment app launch counter
      int currentCount = prefs.getInt('rating_app_launches') ?? 0;
      await prefs.setInt('rating_app_launches', currentCount + 1);
    } catch (e) {
      debugPrint('RatingService recordAppLaunch error: $e');
    }
  }

  /// Increments the completed calculations tracker.
  /// Prompts the review dialog if all triggers and thresholds are met.
  Future<void> incrementCalculations(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      int currentCount = prefs.getInt(_keyCompletedCalculations) ?? 0;
      currentCount++;
      await prefs.setInt(_keyCompletedCalculations, currentCount);

      final hasRated = prefs.getBool(_keyHasRated) ?? false;
      final hasDeclined = prefs.getBool(_keyHasDeclined) ?? false;
      if (hasRated || hasDeclined) return;

      if (await _shouldPrompt(prefs, currentCount)) {
        if (context.mounted) {
          await _showRatingDialog(context, prefs);
        }
      }
    } catch (e) {
      debugPrint('RatingService error: $e');
    }
  }

  Future<bool> _shouldPrompt(SharedPreferences prefs, int currentCount) async {
    final hasRated = prefs.getBool(_keyHasRated) ?? false;
    final hasDeclined = prefs.getBool(_keyHasDeclined) ?? false;

    if (hasRated || hasDeclined) return false;

    // Install Age & App Launches trigger
    final firstLaunchDateStr = prefs.getString('rating_first_launch_date');
    final appLaunches = prefs.getInt('rating_app_launches') ?? 0;

    // Minimum 1 day install age (24 hours) and at least 3 app launches required
    if (firstLaunchDateStr == null || appLaunches < 3) {
      return false;
    }
    final firstLaunchDate = DateTime.tryParse(firstLaunchDateStr);
    if (firstLaunchDate == null) return false;

    final hoursSinceInstall =
        DateTime.now().difference(firstLaunchDate).inHours;
    if (hoursSinceInstall < 24) {
      return false;
    }

    final lastPromptDateStr = prefs.getString(_keyLastPromptDate);

    if (lastPromptDateStr == null) {
      // First prompt logic: at least 3 calculations
      return currentCount >= 3;
    } else {
      // Later prompt logic: at least 7 days and at least 10 calculations since last prompt
      final lastPromptDate = DateTime.tryParse(lastPromptDateStr);
      if (lastPromptDate == null) return false;

      final daysPassed = DateTime.now().difference(lastPromptDate).inDays;
      final calculationsAtLastPrompt =
          prefs.getInt(_keyCalculationsAtLastPrompt) ?? 0;
      final calculationsSinceLastPrompt =
          currentCount - calculationsAtLastPrompt;

      return (daysPassed >= 7 && calculationsSinceLastPrompt >= 10);
    }
  }

  Future<void> _showRatingDialog(
      BuildContext context, SharedPreferences prefs) async {
    // Save last prompt info first to prevent repeated prompts if dialog is dismissed
    await prefs.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
    final currentCount = prefs.getInt(_keyCompletedCalculations) ?? 0;
    await prefs.setInt(_keyCalculationsAtLastPrompt, currentCount);

    if (!context.mounted) return;

    // Log dialog impression event
    AnalyticsService.instance.logRatingEvent('rating_prompt_shown');

    showDialog(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryColor =
            isDark ? const Color(0xFF38BDF8) : const Color(0xFF1B3F72);
        final cardColor = isDark ? const Color(0xFF141C33) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
        final mutedColor = isDark ? Colors.white70 : const Color(0xFF5B6E8F);

        return Dialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enjoying Mortgage Pro?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.playfair(
                    size: 20,
                    color: textColor,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Would you mind taking a moment to rate the app? Your feedback helps us improve and keep building new calculators.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(
                    size: 13,
                    color: mutedColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Rate Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Premium Gold
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await AnalyticsService.instance
                          .logRatingEvent('rating_rate_now');
                      await rateNow();
                    },
                    child: Text(
                      'Rate Now ⭐⭐⭐⭐⭐',
                      style: AppTextStyles.dmSans(
                        size: 13.5,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Later & No Thanks Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await AnalyticsService.instance
                              .logRatingEvent('rating_later');
                        },
                        child: Text(
                          'Later',
                          style: AppTextStyles.dmSans(
                            size: 12.5,
                            color: primaryColor,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await AnalyticsService.instance
                              .logRatingEvent('rating_no_thanks');
                          await declineRating();
                        },
                        child: Text(
                          'No Thanks',
                          style: AppTextStyles.dmSans(
                            size: 12.5,
                            color: Colors.redAccent,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> rateNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasRated, true);

      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await AnalyticsService.instance.logRatingEvent('rating_in_app_success');
      } else {
        await openStoreListing();
      }
    } catch (e) {
      debugPrint('Error triggering rating flow: $e');
      await openStoreListing();
    }
  }

  Future<void> declineRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasDeclined, true);
    } catch (e) {
      debugPrint('Error declining rating: $e');
    }
  }

  Future<void> openStoreListing() async {
    try {
      final Uri marketUri = Uri.parse(_marketUrl);
      final Uri webUri = Uri.parse(_playStoreUrl);

      await AnalyticsService.instance
          .logRatingEvent('rating_play_store_opened');

      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch store listing: $e');
    }
  }
}
