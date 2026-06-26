// lib/features/notifications/providers/notifications_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_notification.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  final Box<Map> _box;

  NotificationsNotifier(this._box) : super([]) {
    _loadNotifications();
  }

  void _loadNotifications() {
    if (!_box.isOpen) return;
    state = _box.toMap().entries.map((e) {
      return AppNotification.fromMap(e.key.toString(), e.value);
    }).toList()
      ..sort((a, b) => b.sentTime.compareTo(a.sentTime));
  }

  void addNotification(String title, String body, {String category = 'general', Map<String, dynamic> data = const {}}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final newNotif = AppNotification(
      id: id,
      title: title,
      body: body,
      sentTime: DateTime.now(),
      category: category,
      data: data,
    );
    _box.put(id, newNotif.toMap());
    _loadNotifications();
  }

  void markAsRead(String id) {
    final existing = _box.get(id);
    if (existing != null) {
      final updated = Map<String, dynamic>.from(existing);
      updated['read'] = true;
      _box.put(id, updated);
      _loadNotifications();
    }
  }

  void markAllAsRead() {
    for (var key in _box.keys) {
      final existing = _box.get(key);
      if (existing != null) {
        final updated = Map<String, dynamic>.from(existing);
        updated['read'] = true;
        _box.put(key, updated);
      }
    }
    _loadNotifications();
  }

  void deleteNotification(String id) {
    _box.delete(id);
    _loadNotifications();
  }

  void clearAll() {
    _box.clear();
    state = [];
  }
}

final notificationsBoxProvider = Provider<Box<Map>>((ref) {
  return Hive.box<Map>('app_notifications');
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  final box = ref.watch(notificationsBoxProvider);
  return NotificationsNotifier(box);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.read).length;
});

final fcmTokenProvider = StateProvider<String?>((ref) => null);
