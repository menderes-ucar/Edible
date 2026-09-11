class DiscoveryStats {
  const DiscoveryStats({
    required this.total,
    required this.completed,
    required this.visited,
    required this.tried,
  });

  final int total;
  final int completed;
  final int visited;
  final int tried;

  double get progress {
    if (total <= 0) return 0;
    return (completed / total).clamp(0, 1);
  }

  int get percent => (progress * 100).round();
}
