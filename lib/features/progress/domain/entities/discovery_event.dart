/// The first time the user marked a discovery as visited or tried.
class DiscoveryEvent {
  const DiscoveryEvent({required this.contentId, required this.createdAt});

  final String contentId;
  final DateTime createdAt;
}
