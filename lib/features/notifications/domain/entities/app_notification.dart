enum AppNotificationType {
  trip,
  discovery,
  memory,
  achievement,
  social,
  system;

  static AppNotificationType parse(String value) {
    return values.firstWhere(
      (item) => item.name == value,
      orElse: () => AppNotificationType.system,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.deepLink,
    this.readAt,
    this.metadata = const {},
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: (map['id'] ?? '').toString(),
      type: AppNotificationType.parse((map['type'] ?? 'system').toString()),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      deepLink: map['deep_link']?.toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      readAt: DateTime.tryParse((map['read_at'] ?? '').toString()),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }
}
