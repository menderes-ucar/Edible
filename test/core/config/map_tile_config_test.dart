
import 'package:flutter_test/flutter_test.dart';
import 'package:edible/core/config/map_tile_config.dart';
void main(){
 test('map labels follow app locale',(){
  expect(MapTileConfig.localizedUrlTemplate('tr-TR'),contains('lang=tr'));
  expect(MapTileConfig.localizedUrlTemplate('en-US'),contains('lang=en'));
  expect(MapTileConfig.localizedUrlTemplate('zh-CN'),contains('lang=zh'));
  expect(MapTileConfig.localizedUrlTemplate('ko-KR'),contains('lang=ko'));
 });
}
