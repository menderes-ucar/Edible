import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/push_device_registration.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Authentication required.');
    return id;
  }

  Future<NotificationPreferences> loadPreferences() async {
    final userId = _userId;
    final row = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return const NotificationPreferences();
    return NotificationPreferences.fromMap(Map<String, dynamic>.from(row));
  }

  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences,
  ) async {
    final userId = _userId;
    final row = await _client
        .from('notification_preferences')
        .upsert({
          'user_id': userId,
          ...preferences.toMap(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return NotificationPreferences.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<List<AppNotification>> loadInbox({int limit = 50}) async {
    final userId = _userId;
    final rows = await _client
        .from('app_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit.clamp(1, 100));

    return (rows as List)
        .whereType<Map>()
        .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<void> markRead(String notificationId) async {
    await _client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllRead() async {
    await _client.rpc('mark_all_notifications_read');
  }

  Future<void> registerDevice(PushDeviceRegistration registration) async {
    if (registration.token.trim().isEmpty ||
        registration.deviceId.trim().isEmpty) {
      throw ArgumentError('Push token and device id are required.');
    }

    await _client.from('device_push_tokens').upsert({
      'user_id': _userId,
      'token': registration.token,
      'platform': registration.platform,
      'enabled': true,
      'language_code': registration.locale,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,token');
  }

  Future<void> unregisterDeviceToken(String token) async {
    if (token.trim().isEmpty) return;
    await _client
        .from('device_push_tokens')
        .update({
          'enabled': false,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _userId)
        .eq('token', token.trim());
  }
}
