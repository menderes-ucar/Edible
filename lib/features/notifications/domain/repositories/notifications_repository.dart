import '../entities/app_notification.dart';
import '../entities/notification_preferences.dart';
import '../entities/push_device_registration.dart';

abstract interface class NotificationsRepository {
  Future<NotificationPreferences> loadPreferences();
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences,
  );

  Future<List<AppNotification>> loadInbox({int limit = 50});
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();

  Future<void> registerDevice(PushDeviceRegistration registration);
  Future<void> unregisterDeviceToken(String token);
}
