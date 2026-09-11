import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/discovery_affinity.dart';
import '../../domain/entities/content_exposure.dart';
import '../../domain/entities/discovery_event.dart';

class DiscoverySignalsRemoteDataSource {
  DiscoverySignalsRemoteDataSource(this._client);

  final SupabaseClient? _client;

  Future<List<ContentExposure>> loadContentExposure({
    int days = 90,
    int limit = 500,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return const [];

    final raw = await client.rpc(
      'get_discovery_content_exposure',
      params: {
        'p_days': days.clamp(1, 365).toInt(),
        'p_limit': limit.clamp(1, 1000).toInt(),
      },
    );

    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (row) => ContentExposure.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .where((item) => item.contentId.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<DiscoveryAffinity>> loadAffinities({int days = 90}) async {
    final client = _client;
    if (client == null) return const [];

    final user = client.auth.currentUser;
    if (user == null) return const [];

    final raw = await client.rpc(
      'get_my_discovery_affinities',
      params: {'p_days': days.clamp(1, 365).toInt()},
    );

    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (row) => DiscoveryAffinity.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .where((item) => item.category.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> record(DiscoveryEvent event) async {
    final client = _client;
    if (client == null) return;

    final user = client.auth.currentUser;
    if (user == null) return;

    final metadata = <String, dynamic>{
      if (event.category?.trim().isNotEmpty == true)
        'category': event.category!.trim(),
      if (event.countryCode?.trim().isNotEmpty == true)
        'country_code': event.countryCode!.trim().toUpperCase(),
      if (event.cityName?.trim().isNotEmpty == true)
        'city_name': event.cityName!.trim(),
      if (event.query?.trim().isNotEmpty == true)
        'query': _truncate(event.query!.trim(), 120),
    };

    await client.from('discovery_behavior_events').insert({
      'user_id': user.id,
      'event_type': event.type.wireValue,
      'content_id': event.contentId,
      'metadata': metadata,
    });
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }

}
