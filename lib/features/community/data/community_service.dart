import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.caption,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.imageUrls,
    required this.likeCount,
    required this.dislikeCount,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String caption;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final List<String> imageUrls;
  final int likeCount;
  final int dislikeCount;

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? map['display_name'] as String
          : 'Edible kullanıcısı',
      avatarUrl: map['avatar_url'] as String?,
      caption: (map['caption'] as String?) ?? '',
      locationName: (map['location_name'] as String?)?.trim(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      imageUrls: ((map['image_urls'] as List?) ?? const [])
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      dislikeCount: (map['dislike_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityService {
  SupabaseClient? get _client => SupabaseService.client;

  Future<List<CommunityPost>> feed({
    int limit = 30,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client.rpc(
      'get_community_feed',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return (rows as List)
        .whereType<Map>()
        .map((row) => CommunityPost.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<void> createPost({
    required String userId,
    required String caption,
    required List<Uint8List> images,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');
    if (images.isEmpty || images.length > 5) {
      throw ArgumentError('Bir paylaşım 1 ile 5 görsel içermelidir.');
    }

    final post = await client
        .from('community_posts')
        .insert({
          'user_id': userId,
          'caption': caption.trim(),
          'location_name': _clean(locationName),
          'latitude': latitude,
          'longitude': longitude,
        })
        .select('id')
        .single();

    final postId = post['id'] as String;
    final uploadedPaths = <String>[];

    try {
      for (var index = 0; index < images.length; index++) {
        final path =
            '$userId/$postId/${DateTime.now().microsecondsSinceEpoch}_$index.jpg';
        await client.storage.from('edible-community').uploadBinary(
              path,
              images[index],
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
                cacheControl: '31536000',
              ),
            );
        uploadedPaths.add(path);
        await client.from('community_post_images').insert({
          'post_id': postId,
          'storage_path': path,
          'sort_order': index,
        });
      }
    } catch (error) {
      if (uploadedPaths.isNotEmpty) {
        await client.storage.from('edible-community').remove(uploadedPaths);
      }
      await client.from('community_posts').delete().eq('id', postId);
      rethrow;
    }
  }

  Future<void> deletePost(CommunityPost post) async {
    final client = _client;
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');

    final rows = await client
        .from('community_post_images')
        .select('storage_path')
        .eq('post_id', post.id);
    final paths = (rows as List)
        .whereType<Map>()
        .map((e) => e['storage_path'])
        .whereType<String>()
        .toList();

    await client.from('community_posts').delete().eq('id', post.id);
    if (paths.isNotEmpty) {
      await client.storage.from('edible-community').remove(paths);
    }
  }

  Future<void> react({
    required String postId,
    required String userId,
    required String reaction,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase bağlantısı hazır değil.');

    final existing = await client
        .from('community_post_reactions')
        .select('reaction')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing?['reaction'] == reaction) {
      await client
          .from('community_post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await client.from('community_post_reactions').upsert({
        'post_id': postId,
        'user_id': userId,
        'reaction': reaction,
      });
    }
  }

  Future<Set<String>> myReactions({
    required String userId,
    required List<String> postIds,
  }) async {
    final client = _client;
    if (client == null || postIds.isEmpty) return {};
    final rows = await client
        .from('community_post_reactions')
        .select('post_id,reaction')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return (rows as List)
        .whereType<Map>()
        .where((e) => e['reaction'] == 'like')
        .map((e) => e['post_id'])
        .whereType<String>()
        .toSet();
  }

  String? _clean(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }
}
