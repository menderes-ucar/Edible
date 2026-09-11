class DiscoveryAffinity {
  const DiscoveryAffinity({
    required this.category,
    required this.signalScore,
    required this.eventCount,
    this.lastSignalAt,
  });

  final String category;
  final double signalScore;
  final int eventCount;
  final DateTime? lastSignalAt;

  factory DiscoveryAffinity.fromMap(Map<String, dynamic> map) {
    return DiscoveryAffinity(
      category: (map['category'] ?? '').toString().trim(),
      signalScore: _asDouble(map['signal_score']),
      eventCount: _asInt(map['event_count']),
      lastSignalAt: DateTime.tryParse(
        (map['last_signal_at'] ?? '').toString(),
      ),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
