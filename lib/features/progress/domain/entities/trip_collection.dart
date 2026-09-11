class TripCollection {
  const TripCollection({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.contentIds,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<String> contentIds;
}
