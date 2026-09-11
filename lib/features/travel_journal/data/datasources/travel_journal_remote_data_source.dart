import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/travel_memory_draft.dart';
import '../models/travel_memory_model.dart';

class TravelJournalRemoteDataSource {
  static const _bucket = 'travel-memory-photos';

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

  Future<TravelMemoryModel?> getForVisit(
    String travelVisitId,
  ) async {
    final row = await _client
        .from('travel_memories')
        .select()
        .eq('user_id', _userId)
        .eq('travel_visit_id', travelVisitId)
        .maybeSingle();

    if (row == null) return null;

    return TravelMemoryModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<TravelMemoryModel> save(
    TravelMemoryDraft draft,
  ) async {
    final row = await _client
        .from('travel_memories')
        .upsert(
          {
            'user_id': _userId,
            'travel_visit_id': draft.travelVisitId,
            'country_code': draft.countryCode,
            'country_name': draft.countryName,
            'city_name': draft.cityName,
            'visit_date': _dateOnly(draft.visitDate),
            'title': draft.title.trim(),
            'note': draft.note.trim(),
            'favorite_food': draft.favoriteFood.trim(),
            'rating': draft.rating,
            'mood': draft.mood?.name,
            'photo_paths': draft.photoPaths,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,travel_visit_id',
        )
        .select()
        .single();

    return TravelMemoryModel.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<String> uploadPhoto({
    required String travelVisitId,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw StateError('Selected photo no longer exists.');
    }

    final extension = _extension(file.path);
    final objectPath =
        '$_userId/$travelVisitId/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await _client.storage.from(_bucket).upload(
          objectPath,
          file,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentType(extension),
          ),
        );

    return objectPath;
  }

  Future<void> deletePhoto(String storagePath) async {
    if (!storagePath.startsWith('$_userId/')) {
      throw StateError('Photo does not belong to the current user.');
    }

    await _client.storage.from(_bucket).remove([storagePath]);
  }

  Future<String> createSignedPhotoUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) {
    return _client.storage
        .from(_bucket)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _extension(String path) {
    final raw = path.split('.').last.toLowerCase();

    return switch (raw) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      'heif' => 'heif',
      _ => 'jpg',
    };
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}
