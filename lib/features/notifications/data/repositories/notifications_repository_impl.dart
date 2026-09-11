import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/push_device_registration.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);
  final NotificationsRemoteDataSource _remote;

  @override
  Future<List<AppNotification>> loadInbox({int limit = 50}) =>
      _remote.loadInbox(limit: limit);

  @override
  Future<NotificationPreferences> loadPreferences() =>
      _remote.loadPreferences();

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<void> markRead(String notificationId) =>
      _remote.markRead(notificationId);

  @override
  Future<void> registerDevice(PushDeviceRegistration registration) =>
      _remote.registerDevice(registration);

  @override
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences,
  ) =>
      _remote.savePreferences(preferences);

  @override
  Future<void> unregisterDeviceToken(String token) =>
      _remote.unregisterDeviceToken(token);
}
