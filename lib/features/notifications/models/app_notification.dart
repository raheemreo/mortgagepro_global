// lib/features/notifications/models/app_notification.dart

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime sentTime;
  final bool read;
  final String category; // 'rate', 'promo', 'system', 'general'
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sentTime,
    this.read = false,
    this.category = 'general',
    this.data = const {},
  });

  AppNotification copyWith({
    bool? read,
    String? category,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      sentTime: sentTime,
      read: read ?? this.read,
      category: category ?? this.category,
      data: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'sentTime': sentTime.millisecondsSinceEpoch,
      'read': read,
      'category': category,
      'data': data,
    };
  }

  factory AppNotification.fromMap(String id, Map map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      sentTime: DateTime.fromMillisecondsSinceEpoch(
        map['sentTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      read: map['read'] ?? false,
      category: map['category'] ?? 'general',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : const {},
    );
  }
}
