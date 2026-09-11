class ExploreMetadata {
  const ExploreMetadata({
    this.priceLevel,
    this.bestTime,
    this.localTip,
    this.openingInfo,
    this.estimatedVisitMinutes,
    this.vegetarian,
    this.vegan,
    this.halal,
    this.spicyLevel,
    this.etiquette,
    this.doText,
    this.dontText,
    this.coordinatePrecision,
    this.editorialStatus,
  });

  final int? priceLevel;
  final String? bestTime;
  final String? localTip;
  final String? openingInfo;
  final int? estimatedVisitMinutes;
  final bool? vegetarian;
  final bool? vegan;
  final bool? halal;
  final int? spicyLevel;
  final String? etiquette;
  final String? doText;
  final String? dontText;
  final String? coordinatePrecision;
  final String? editorialStatus;

  bool get hasExactCoordinates =>
      coordinatePrecision?.trim().toLowerCase() == 'exact';

  bool get isEmpty =>
      priceLevel == null &&
      bestTime == null &&
      localTip == null &&
      openingInfo == null &&
      estimatedVisitMinutes == null &&
      vegetarian == null &&
      vegan == null &&
      halal == null &&
      spicyLevel == null &&
      etiquette == null &&
      doText == null &&
      dontText == null &&
      coordinatePrecision == null &&
      editorialStatus == null;
}
