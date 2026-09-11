import '../../../culture/domain/repositories/culture_repository.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../../food/domain/repositories/food_repository.dart';
import '../../domain/entities/offline_city_pack.dart';
import '../../domain/repositories/offline_city_pack_repository.dart';
import '../datasources/offline_city_pack_local_data_source.dart';

class OfflineCityPackRepositoryImpl implements OfflineCityPackRepository {
  OfflineCityPackRepositoryImpl({
    required ExploreRepository exploreRepository,
    required FoodRepository foodRepository,
    required CultureRepository cultureRepository,
    required OfflineCityPackLocalDataSource localDataSource,
  })  : _exploreRepository = exploreRepository,
        _foodRepository = foodRepository,
        _cultureRepository = cultureRepository,
        _localDataSource = localDataSource;

  final ExploreRepository _exploreRepository;
  final FoodRepository _foodRepository;
  final CultureRepository _cultureRepository;
  final OfflineCityPackLocalDataSource _localDataSource;

  @override
  Future<OfflineCityPack> download({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    final all = await _exploreRepository.getContents(
      languageCode: languageCode,
    );

    final contents = all.where((item) {
      return item.countryCode.toLowerCase() == countryCode.toLowerCase() &&
          item.cityName.toLowerCase() == cityName.toLowerCase();
    }).toList(growable: false);

    if (contents.isEmpty) {
      throw StateError('No city content is available to download.');
    }

    final foodDetails = await _foodRepository.getDetailsForContents(
      contentIds: contents.map((item) => item.id),
      languageCode: languageCode,
    );

    final cultureGuide = await _cultureRepository.getGuide(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );

    final pack = OfflineCityPack(
      countryCode: countryCode,
      countryName: contents.first.countryName,
      cityName: cityName,
      languageCode: languageCode,
      downloadedAt: DateTime.now(),
      contents: contents,
      foodDetails: foodDetails,
      cultureGuide: cultureGuide,
    );

    await _localDataSource.save(pack);
    return pack;
  }

  @override
  Future<OfflineCityPack?> get({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) {
    return _localDataSource.read(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );
  }

  @override
  Future<List<OfflineCityPack>> getAll() {
    return _localDataSource.readAll();
  }

  @override
  Future<void> delete({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) {
    return _localDataSource.delete(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );
  }

  @override
  Future<bool> isDownloaded({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    return await get(
          countryCode: countryCode,
          cityName: cityName,
          languageCode: languageCode,
        ) !=
        null;
  }
}
