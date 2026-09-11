
import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/city_content_coverage.dart';
void main(){
 test('reports exact missing discovery categories',(){
  const c=CityContentCoverage(cityId:'1',countryCode:'KZ',cityName:'Almaty',
    placeCount:3,foodCount:1,drinkCount:0,snackCount:1,cultureCount:0,
    regionalProductCount:1,isContentReady:false);
  expect(c.missingCategories,['drink','culture']);
 });
}
