class ContentExposure {
  const ContentExposure({
    required this.contentId,
    required this.interactionCount,
    required this.uniqueUsers,
  });

  final String contentId;
  final int interactionCount;
  final int uniqueUsers;

  factory ContentExposure.fromMap(Map<String, dynamic> map) {
    return ContentExposure(
      contentId: (map['content_id'] ?? '').toString(),
      interactionCount: _asInt(map['interaction_count']),
      uniqueUsers: _asInt(map['unique_users']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
