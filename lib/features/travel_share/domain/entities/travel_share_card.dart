class TravelShareCard {
  const TravelShareCard({
    required this.title,
    required this.location,
    required this.dateLabel,
    required this.rating,
    required this.favoriteFood,
    required this.note,
  });

  final String title;
  final String location;
  final String dateLabel;
  final int? rating;
  final String favoriteFood;
  final String note;
}
