import '../entities/offline_city_pack.dart';

abstract interface class OfflineCityPackRepository {
  Future<OfflineCityPack> download({
    required String countryCode,
    required String cityName,
    required String languageCode,
  });

  Future<OfflineCityPack?> get({
    required String countryCode,
    required String cityName,
    required String languageCode,
  });

  Future<List<OfflineCityPack>> getAll();

  Future<void> delete({
    required String countryCode,
    required String cityName,
    required String languageCode,
  });

  Future<bool> isDownloaded({
    required String countryCode,
    required String cityName,
    required String languageCode,
  });
}
