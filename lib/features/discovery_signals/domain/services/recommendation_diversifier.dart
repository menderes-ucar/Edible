import '../entities/for_you_recommendation.dart';

class RecommendationDiversifier {
  const RecommendationDiversifier({this.maxSameCategoryInWindow = 2, this.windowSize = 4});
  final int maxSameCategoryInWindow;
  final int windowSize;

  List<ForYouRecommendation> diversify(List<ForYouRecommendation> ranked, {int limit = 12}) {
    final remaining = [...ranked];
    final result = <ForYouRecommendation>[];
    while (remaining.isNotEmpty && result.length < limit) {
      final start = result.length > windowSize ? result.length - windowSize : 0;
      final recent = result.sublist(start);
      var index = remaining.indexWhere((candidate) {
        final same = recent.where((item) => item.content.category == candidate.content.category).length;
        return same < maxSameCategoryInWindow;
      });
      if (index < 0) index = 0;
      result.add(remaining.removeAt(index));
    }
    return result;
  }
}
