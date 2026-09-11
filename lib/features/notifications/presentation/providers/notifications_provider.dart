import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({required NotificationsRepository repository})
      : _repository = repository;

  final NotificationsRepository _repository;

  NotificationPreferences _preferences = const NotificationPreferences();
  List<AppNotification> _inbox = const [];
  bool _isLoading = false;
  bool _isSavingPreferences = false;
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;

  NotificationPreferences get preferences => _preferences;
  List<AppNotification> get inbox => _inbox;
  bool get isLoading => _isLoading;
  bool get isSavingPreferences => _isSavingPreferences;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _inbox.where((item) => !item.isRead).length;

  Future<void> refresh() async {
    if (_disposed) return;

    final generation = ++_generation;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final preferencesFuture = _repository.loadPreferences();
      final inboxFuture = _repository.loadInbox();

      final preferences = await preferencesFuture;
      final inbox = await inboxFuture;
      if (!_isCurrent(generation)) return;

      _preferences = preferences;
      _inbox = inbox;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _errorMessage = error.toString();
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> savePreferences(NotificationPreferences next) async {
    if (_disposed || _isSavingPreferences) return false;

    final generation = _generation;

    final previous = _preferences;
    _preferences = next;
    _isSavingPreferences = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final saved = await _repository.savePreferences(next);
      if (!_isCurrent(generation)) return false;
      _preferences = saved;
      return true;
    } catch (error) {
      if (!_isCurrent(generation)) return false;
      _preferences = previous;
      _errorMessage = error.toString();
      return false;
    } finally {
      if (_isCurrent(generation)) {
        _isSavingPreferences = false;
        _notifyIfAlive();
      }
    }
  }

  Future<void> markRead(String id) async {
    if (_disposed) return;
    final generation = _generation;
    final index = _inbox.indexWhere((item) => item.id == id);
    if (index < 0 || _inbox[index].isRead) return;

    final previous = _inbox;
    final item = _inbox[index];
    final updated = AppNotification(
      id: item.id,
      type: item.type,
      title: item.title,
      body: item.body,
      createdAt: item.createdAt,
      deepLink: item.deepLink,
      readAt: DateTime.now().toUtc(),
      metadata: item.metadata,
    );

    final next = [..._inbox];
    next[index] = updated;
    _inbox = next;
    _notifyIfAlive();

    try {
      await _repository.markRead(id);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _inbox = previous;
      _errorMessage = error.toString();
      _notifyIfAlive();
    }
  }

  Future<void> markAllRead() async {
    if (_disposed) return;
    final generation = _generation;
    final previous = _inbox;
    final now = DateTime.now().toUtc();
    _inbox = _inbox
        .map(
          (item) => item.isRead
              ? item
              : AppNotification(
                  id: item.id,
                  type: item.type,
                  title: item.title,
                  body: item.body,
                  createdAt: item.createdAt,
                  deepLink: item.deepLink,
                  readAt: now,
                  metadata: item.metadata,
                ),
        )
        .toList(growable: false);
    _notifyIfAlive();

    try {
      await _repository.markAllRead();
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _inbox = previous;
      _errorMessage = error.toString();
      _notifyIfAlive();
    }
  }

  void invalidate() {
    if (_disposed) return;
    _generation++;
    _preferences = const NotificationPreferences();
    _inbox = const [];
    _isLoading = false;
    _isSavingPreferences = false;
    _errorMessage = null;
    _notifyIfAlive();
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _isLoading = false;
    _isSavingPreferences = false;
    super.dispose();
  }
}
