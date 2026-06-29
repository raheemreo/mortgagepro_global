// lib/features/notifications/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/text_styles.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';

class _C {
  static Color navy = const Color(0xFF0B1D3A);
  static Color royal = const Color(0xFF1A3A8F);
  static Color bg = const Color(0xFFF0F4FF);
  static Color card = const Color(0xFFFFFFFF);
  static Color muted = const Color(0xFF5B6E8F);
  static Color border = const Color(0x171B3A8F);

  static void update(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    navy = isDark ? Colors.white : const Color(0xFF0B1D3A);
    royal = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1A3A8F);
    bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    card = isDark ? const Color(0xFF141C33) : const Color(0xFFFFFFFF);
    muted = isDark ? Colors.white70 : const Color(0xFF5B6E8F);
    border = isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0x171B3A8F);
  }
}

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    _C.update(context);
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _C.navy, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.playfair(size: 19, color: _C.navy),
        ),
        actions: [
          // Developer/Test Actions
          IconButton(
            icon: Icon(Icons.science_outlined, color: _C.royal),
            tooltip: 'Trigger Test Notification',
            onPressed: _showTestNotificationDialog,
          ),
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).clearAll();
              },
              child: Text(
                'Clear All',
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildDismissibleCard(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _C.royal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🔔', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: AppTextStyles.playfair(size: 20, color: _C.navy),
            ),
            const SizedBox(height: 8),
            Text(
              'When you receive messages or rate updates from MortgagePro, they will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(size: 13, color: _C.muted),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _triggerDefaultTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.royal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.add_alert_rounded),
              label: Text(
                'Simulate Rate Alert',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: _getCategoryIcon(notification.category),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: notification.read ? FontWeight.w500 : FontWeight.w800,
                        color: _C.navy,
                      ),
                    ),
                  ),
                  if (!notification.read)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                _formatTimestamp(notification.sentTime),
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: _C.muted,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: Alignment.topLeft,
              onExpansionChanged: (expanded) {
                if (expanded && !notification.read) {
                  ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                }
              },
              children: [
                Text(
                  notification.body,
                  style: AppTextStyles.dmSans(
                    size: 13,
                    color: _C.navy.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                if (notification.data.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 4),
                  ...notification.data.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w700,
                              color: _C.muted,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: AppTextStyles.dmSans(
                                size: 11,
                                color: _C.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    String emoji = '🔔';
    Color bgColor = const Color(0xFFEFF6FF);

    switch (category.toLowerCase()) {
      case 'rate':
        emoji = '📈';
        bgColor = const Color(0xFFECFDF5); // green
        break;
      case 'promo':
        emoji = '🎁';
        bgColor = const Color(0xFFFFF7ED); // orange
        break;
      case 'system':
        emoji = '⚙️';
        bgColor = const Color(0xFFF3F4F6); // grey
        break;
      default:
        emoji = '🔔';
        bgColor = const Color(0xFFEFF6FF); // blue
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM dd, yyyy · hh:mm a').format(dateTime);
    }
  }

  void _triggerDefaultTestNotification() {
    ref.read(notificationsProvider.notifier).addNotification(
      'Mortgage Rate Dropped!',
      'Great news! The average 30-year fixed mortgage rate dropped by 0.15% today, down to 6.25%. Click to compare available options and calculate potential savings.',
      category: 'rate',
      data: {'rate_drop': '0.15%', 'new_rate': '6.25%', 'target': 'usa'},
    );
  }

  void _showTestNotificationDialog() {
    final fcmToken = ref.read(fcmTokenProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/notification/test'),
      builder: (_) {
        return Material(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Simulate Push Notifications',
                    style: AppTextStyles.playfair(size: 17, color: _C.navy),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a message type to trigger locally.',
                    style: AppTextStyles.dmSans(size: 12, color: _C.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Text('📈', style: TextStyle(fontSize: 22)),
                    title: Text(
                      'Rate Alert Notification',
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: _C.navy),
                    ),
                    subtitle: Text(
                      'Rate updates or trends alerts',
                      style: AppTextStyles.dmSans(size: 11, color: _C.muted),
                    ),
                    onTap: () {
                      _triggerDefaultTestNotification();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Text('🎁', style: TextStyle(fontSize: 22)),
                    title: Text(
                      'Promotional Notification',
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: _C.navy),
                    ),
                    subtitle: Text(
                      'Special tools unlocks or premium benefits',
                      style: AppTextStyles.dmSans(size: 11, color: _C.muted),
                    ),
                    onTap: () {
                      ref.read(notificationsProvider.notifier).addNotification(
                        'Unlock Premium Tools for Free',
                        'Watch a short video and unlock premium ad-free tools for a full day. Click to claim your promotion.',
                        category: 'promo',
                        data: {'coupon_code': 'FREEAD24', 'duration': '24h'},
                      );
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Text('⚙️', style: TextStyle(fontSize: 22)),
                    title: Text(
                      'System Update Notification',
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: _C.navy),
                    ),
                    subtitle: Text(
                      'New features or maintenance messages',
                      style: AppTextStyles.dmSans(size: 11, color: _C.muted),
                    ),
                    onTap: () {
                      ref.read(notificationsProvider.notifier).addNotification(
                        'New Indian Mortgage Suite Added!',
                        'We have expanded the calculator suites! Try out the new India Home Loan Calculator, EMI Splitter, and Prepayment optimizer now.',
                        category: 'system',
                        data: {'new_feature': 'india_suite', 'version': '1.1.0'},
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'FCM Device Registration Token',
                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: _C.navy),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _C.border),
                          ),
                          child: SelectableText(
                            fcmToken ?? 'Fetching token or not available...',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: _C.navy.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (fcmToken != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, color: _C.royal, size: 20),
                          tooltip: 'Copy Token',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: fcmToken));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('FCM Token copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
