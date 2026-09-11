import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/data/datasources/world_flagship_catalog.dart';
import 'package:edible/features/explore/domain/entities/explore_category.dart';

void main() {
  test('ships 40 countries and 400 real named discoveries', () {
    final items=getWorldFlagshipCatalog('en');
    expect(items.length,400);
    expect(items.map((e)=>e.countryCode).toSet().length,40);
  });
  test('each flagship destination has five places and every discovery category', () {
    final items=getWorldFlagshipCatalog('en');
    for(final city in items.map((e)=>'${e.countryCode}:${e.cityName}').toSet()) {
      final parts=city.split(':');
      final scoped=items.where((e)=>e.countryCode==parts.first && e.cityName==parts.last).toList();
      expect(scoped.where((e)=>e.category==ExploreCategory.place).length,5,reason:city);
      expect(scoped.map((e)=>e.category).toSet().containsAll(ExploreCategory.values),isTrue,reason:city);
    }
  });
  test('does not attach misleading generic stock photos', () {
    expect(getWorldFlagshipCatalog('en').every((e)=>e.coverImageUrl==null),isTrue);
  });
}
