import '../../../explore/domain/entities/explore_category.dart';
import '../../../explore/domain/entities/explore_content.dart';

class VacationCategoryFilter {
  const VacationCategoryFilter._();

  static List<ExploreContent> apply({
    required Iterable<ExploreContent> contents,
    required ExploreCategory? category,
  }) {
    if (category == null) return List<ExploreContent>.unmodifiable(contents);
    return List<ExploreContent>.unmodifiable(
      contents.where((item) => item.category == category),
    );
  }
}
