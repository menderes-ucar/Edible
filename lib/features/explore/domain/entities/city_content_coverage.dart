
class CityContentCoverage {
  const CityContentCoverage({
    required this.cityId, required this.countryCode, required this.cityName,
    required this.placeCount, required this.foodCount, required this.drinkCount,
    required this.snackCount, required this.cultureCount,
    required this.regionalProductCount, required this.isContentReady,
  });
  final String cityId,countryCode,cityName;
  final int placeCount,foodCount,drinkCount,snackCount,cultureCount,regionalProductCount;
  final bool isContentReady;

  List<String> get missingCategories => <String>[
    if(placeCount<3) 'place',
    if(foodCount<1) 'food',
    if(drinkCount<1) 'drink',
    if(snackCount<1) 'snack',
    if(cultureCount<1) 'culture',
    if(regionalProductCount<1) 'fruit',
  ];
}
