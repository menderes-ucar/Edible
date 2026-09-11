class TravelDna {
  const TravelDna({
    required this.visitedCount,
    required this.triedCount,
    required this.categoryCounts,
  });

  final int visitedCount;
  final int triedCount;
  final Map<String, int> categoryCounts;

  int get totalInteractions => visitedCount + triedCount;

  int countFor(String category) => categoryCounts[category] ?? 0;

  int get foodScore =>
      countFor('food') +
      countFor('snack') +
      countFor('drink') +
      countFor('fruit');

  int get cultureScore => countFor('culture');

  int get placeScore => countFor('place');

  bool get hasData => totalInteractions > 0 || categoryCounts.isNotEmpty;

  String get profileKey {
    if (!hasData) return 'curiousExplorer';

    final food = foodScore;
    final culture = cultureScore;
    final place = placeScore;
    final maxScore = [food, culture, place].reduce(
      (a, b) => a > b ? a : b,
    );

    final topCount = [food, culture, place]
        .where((score) => score == maxScore)
        .length;

    if (topCount > 1) return 'curiousExplorer';
    if (food == maxScore) return 'tasteHunter';
    if (culture == maxScore) return 'cultureSeeker';
    return 'iconHunter';
  }

  String get profileTitleKey => switch (profileKey) {
        'tasteHunter' => 'travelDnaTasteHunter',
        'cultureSeeker' => 'travelDnaCultureSeeker',
        'iconHunter' => 'travelDnaIconHunter',
        _ => 'travelDnaCuriousExplorer',
      };

  String get profileSubtitleKey => switch (profileKey) {
        'tasteHunter' => 'travelDnaTasteHunterSubtitle',
        'cultureSeeker' => 'travelDnaCultureSeekerSubtitle',
        'iconHunter' => 'travelDnaIconHunterSubtitle',
        _ => 'travelDnaCuriousExplorerSubtitle',
      };
}
