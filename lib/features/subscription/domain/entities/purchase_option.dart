class PurchaseOption {
  const PurchaseOption({
    required this.id,
    required this.title,
    required this.description,
    required this.priceText,
    required this.packageIdentifier,
  });

  final String id;
  final String title;
  final String description;
  final String priceText;
  final String packageIdentifier;
}
