import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/content_progress.dart';

class ProgressPersistenceException implements Exception {
  const ProgressPersistenceException(this.code);

  final String code;

  @override
  String toString() => 'ProgressPersistenceException($code)';
}

class ProgressRemoteDataSource {
  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not initialized.');
    }
    return client;
  }

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }
    return user.id;
  }

  Future<Set<String>> getIds(ContentProgressType type) async {
    final rows = await _client
        .from('content_progress')
        .select('content_id')
        .eq('user_id', _userId)
        .eq('progress_type', type.value);

    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map((row) => row['content_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> setProgress({
    required String contentId,
    required ContentProgressType type,
    required bool enabled,
  }) async {
    if (enabled) {
      await _requireCanonicalContent(contentId);

      await _client.from('content_progress').upsert(
        {
          'user_id': _userId,
          'content_id': contentId,
          'progress_type': type.value,
        },
        onConflict: 'user_id,content_id,progress_type',
      );
      return;
    }

    await _client
        .from('content_progress')
        .delete()
        .eq('user_id', _userId)
        .eq('content_id', contentId)
        .eq('progress_type', type.value);
  }

  Future<List<Map<String, dynamic>>> getCollections() async {
    final rows = await _client
        .from('trip_collections')
        .select(
          'id,name,description,created_at,updated_at,'
          'trip_collection_items(content_id)',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createCollection({
    required String name,
    String? description,
  }) async {
    final row = await _client
        .from('trip_collections')
        .insert({
          'user_id': _userId,
          'name': name.trim(),
          'description': _nullableTrim(description),
        })
        .select('id,name,description,created_at,updated_at')
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> updateCollection({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    final row = await _client
        .from('trip_collections')
        .update({
          'name': name.trim(),
          'description': _nullableTrim(description),
        })
        .eq('id', collectionId)
        .eq('user_id', _userId)
        .select('id,name,description,created_at,updated_at')
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<void> deleteCollection(String collectionId) async {
    await _client
        .from('trip_collections')
        .delete()
        .eq('id', collectionId)
        .eq('user_id', _userId);
  }

  Future<void> addContentToCollection({
    required String collectionId,
    required String contentId,
  }) async {
    await _requireCanonicalContent(contentId);

    await _client.from('trip_collection_items').upsert(
      {
        'collection_id': collectionId,
        'content_id': contentId,
      },
      onConflict: 'collection_id,content_id',
    );
  }

  Future<void> removeContentFromCollection({
    required String collectionId,
    required String contentId,
  }) async {
    await _client
        .from('trip_collection_items')
        .delete()
        .eq('collection_id', collectionId)
        .eq('content_id', contentId);
  }

  Future<void> _requireCanonicalContent(String contentId) async {
    final row = await _client
        .from('contents')
        .select('id')
        .eq('id', contentId)
        .maybeSingle();

    if (row == null) {
      throw const ProgressPersistenceException(
        'content_not_synced_to_supabase',
      );
    }
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
