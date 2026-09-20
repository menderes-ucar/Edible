import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/supabase_service.dart';
import '../../../firebase_options.dart';

/// Central notification infrastructure for Edible.
///
/// Responsibilities:
/// - FCM token registration and refresh.
/// - Foreground/background/terminated notification handling.
/// - Visible foreground notifications through flutter_local_notifications.
/// - Daily local discovery reminder as a resilient fallback.
/// - In-app notification inbox backed by Supabase.
/// - Navigation payload delivery to the app router.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'edible_general';
  static const String _channelName = 'Edible bildirimleri';
  static const String _channelDescription =
      'Edible mesaj, keşif ve seyahat bildirimleri';
  static const String _messageChannelId = 'edible_messages';
  static const String _socialChannelId = 'edible_social';
  static const String _travelChannelId = 'edible_travel';
  static const int _dailyNotificationId = 47001;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  String? _userId;
  String? _token;
  bool _started = false;
  bool _localReady = false;
  bool _firebaseReady = false;
  bool _initialMessageHandled = false;

  void Function(String route)? onRouteRequested;

  bool get isFirebaseReady => _firebaseReady;
  bool get isLocalReady => _localReady;
  String? get currentToken => _token;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      tz.initializeTimeZones();
      try {
        final timeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZone.identifier));
      } catch (error) {
        debugPrint('[NOTIFICATIONS] Timezone detection failed: $error');
      }
      await _initializeLocalNotifications();
    } catch (error) {
      debugPrint('[NOTIFICATIONS] Local init failed: $error');
    }

    // Firebase permission/handlers are not tied to authentication. This is
    // important because a first-run user must see the OS permission prompt
    // before an auth state transition happens. Token persistence remains
    // user-scoped below.
    await _initializeFirebase();
    if (_firebaseReady) {
      try {
        await _requestPermission();
        await _configureFcmHandlers();
      } catch (error) {
        debugPrint('[NOTIFICATIONS] FCM setup failed: $error');
      }
    }

    final client = SupabaseService.client;
    if (client == null) return;

    _authSubscription = client.auth.onAuthStateChange.listen((state) {
      final nextUserId = state.session?.user.id;
      if (nextUserId == _userId) return;

      if (nextUserId == null) {
        unawaited(_disableCurrentToken());
        _userId = null;
        _token = null;
        return;
      }

      unawaited(_initializeForUser(nextUserId));
    });

    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId != null) {
      await _initializeForUser(currentUserId);
    }
  }

  Future<void> _initializeForUser(String userId) async {
    _userId = userId;

    if (!_firebaseReady) {
      // Local daily discovery still works without FCM configuration.
      await scheduleDailyDiscovery(
        languageCode: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      );
      return;
    }

    try {
      await _saveCurrentToken();
      await _scheduleDailyDiscoveryFromLocale();
    } catch (error) {
      debugPrint('[NOTIFICATIONS] User init failed: $error');
    }
  }

  Future<void> _initializeFirebase() async {
    if (_firebaseReady) return;
    if (kIsWeb) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseReady = true;
    } catch (error) {
      // Firebase configuration is intentionally optional at bootstrap time.
      // Supabase + local notifications must continue to work when native
      // Firebase files have not yet been added to a developer build.
      _firebaseReady = false;
      debugPrint('[NOTIFICATIONS] Firebase unavailable: $error');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '[NOTIFICATIONS] FCM Permission: ${settings.authorizationStatus.name}',
    );

    // Android 13+ POST_NOTIFICATIONS is requested by MainActivity after the
    // Flutter activity is attached. Keeping a second Android runtime request
    // here can race the native dialog during bootstrap.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
        '[NOTIFICATIONS] Android notification permission is requested by MainActivity',
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _messageChannelId,
        'Mesajlar',
        description: 'Yeni mesaj bildirimleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _socialChannelId,
        'Sosyal bildirimler',
        description: 'Topluluk ve sosyal etkileşim bildirimleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _travelChannelId,
        'Seyahat bildirimleri',
        description: 'Gezi, keşif ve seyahat hatırlatıcıları',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    _localReady = true;
  }

  Future<void> _configureFcmHandlers() async {
    if (!_firebaseReady) return;

    await _messaging.setAutoInitEnabled(true);

    // Register the background handler once before any background message can
    // arrive. This is required for data/notification handling when the app
    // is backgrounded or terminated.
    FirebaseMessaging.onBackgroundMessage(
      edibleFirebaseMessagingBackgroundHandler,
    );

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_handleForegroundMessage(message));
    });

    await _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRemoteMessageTap(message);
    });

    if (!_initialMessageHandled) {
      _initialMessageHandled = true;
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleRemoteMessageTap(initial);
      }
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token));
    });
  }

  Future<void> _saveCurrentToken() async {
    if (!_firebaseReady || _userId == null) return;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // FCM requires the APNs token to be available before token APIs on iOS.
      for (var i = 0; i < 10; i++) {
        final apns = await _messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
        debugPrint('[NOTIFICATIONS] FCM token registered for user $_userId');
      } else {
        debugPrint('[NOTIFICATIONS] FCM token is empty');
      }
    } catch (error) {
      // Some Huawei/non-GMS devices can report SERVICE_NOT_AVAILABLE because
      // Google Play services are unavailable. Keep the app/in-app inbox
      // functional and retry on the next auth/start cycle.
      debugPrint('[NOTIFICATIONS] Token retrieval failed: $error');
    }
  }

  Future<void> _saveToken(String token) async {
    final client = SupabaseService.client;
    final userId = _userId;
    if (client == null || userId == null || token.trim().isEmpty) return;

    _token = token;

    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
    final languageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    try {
      await client.from('device_push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'enabled': true,
          'language_code': languageCode,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
    } catch (error) {
      debugPrint('[NOTIFICATIONS] Token save failed: $error');
    }
  }

  Future<void> _disableCurrentToken() async {
    final client = SupabaseService.client;
    final token = _token;
    if (client == null || token == null) return;

    try {
      await client
          .from('device_push_tokens')
          .update({'enabled': false})
          .eq('token', token);
    } catch (_) {
      // Logout must never fail because notification cleanup failed.
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        (message.data['title']?.toString() ?? 'Edible');
    final body = notification?.body ??
        (message.data['body']?.toString() ?? 'Yeni bir keşfin var.');

    await showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
      type: message.data['type']?.toString(),
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final route = _routeFromData(message.data);
    if (route != null) onRouteRequested?.call(route);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        final route = _routeFromData(Map<String, dynamic>.from(data));
        if (route != null) onRouteRequested?.call(route);
      }
    } catch (_) {
      if (payload.startsWith('/')) {
        onRouteRequested?.call(payload);
      }
    }
  }

  String? _routeFromData(Map<String, dynamic> data) {
    final route = data['route']?.toString().trim();
    if (route == null || route.isEmpty || !route.startsWith('/')) return null;
    return route;
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? type,
  }) async {
    if (!_localReady) return;

    final channel = switch (type) {
      'message' || 'messages' => (id: _messageChannelId, name: 'Mesajlar', description: 'Yeni mesaj bildirimleri'),
      'social' || 'community' => (id: _socialChannelId, name: 'Sosyal bildirimler', description: 'Topluluk ve sosyal etkileşim bildirimleri'),
      'trip' || 'travel' || 'discovery' => (id: _travelChannelId, name: 'Seyahat bildirimleri', description: 'Gezi, keşif ve seyahat hatırlatıcıları'),
      _ => (id: _channelId, name: _channelName, description: _channelDescription),
    };

    final android = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: type == 'discovery' || type == 'travel'
          ? Importance.defaultImportance
          : Importance.high,
      priority: type == 'discovery' || type == 'travel'
          ? Priority.defaultPriority
          : Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
       NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  Future<void> scheduleDailyDiscovery({required String languageCode}) async {
    if (!_localReady) return;

    final copy = _dailyCopy(languageCode);
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.zonedSchedule(
      _dailyNotificationId,
      copy.$1,
      copy.$2,
      next,
      const NotificationDetails(
        android: android,
        iOS: ios,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'route': '/',
        'type': 'daily_discovery',
      }),
    );
  }

  Future<void> _scheduleDailyDiscoveryFromLocale() async {
    await scheduleDailyDiscovery(
      languageCode: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
  }

  /// Keeps notification content aligned with the app-selected language.
  /// The previous implementation used the device locale, so changing Edible's
  /// language left the daily reminder and token language in the old language.
  Future<void> updateLanguage(String languageCode) async {
    final normalized = languageCode.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    if (normalized.isEmpty) return;

    final client = SupabaseService.client;
    final userId = _userId;
    if (client != null && userId != null) {
      try {
        await client
            .from('device_push_tokens')
            .update({'language_code': normalized, 'last_seen_at': DateTime.now().toUtc().toIso8601String()})
            .eq('user_id', userId);
      } catch (error) {
        debugPrint('[NOTIFICATIONS] Language sync failed: $error');
      }
    }

    await scheduleDailyDiscovery(languageCode: normalized);
  }

  (String, String) _dailyCopy(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return (
          'Today on Edible ✨',
          'Discover a new place, taste its culture and make your next trip memorable.',
        );
      case 'de':
        return (
          'Heute auf Edible ✨',
          'Entdecke einen neuen Ort, lerne seine Kultur kennen und plane deine nächste Reise.',
        );
      case 'fr':
        return (
          'Aujourd’hui sur Edible ✨',
          'Découvre un nouvel endroit, sa culture et prépare ta prochaine escapade.',
        );
      case 'es':
        return (
          'Hoy en Edible ✨',
          'Descubre un lugar nuevo, conoce su cultura y prepara tu próximo viaje.',
        );
      case 'it':
        return (
          'Oggi su Edible ✨',
          'Scopri un nuovo luogo, conosci la sua cultura e prepara il tuo prossimo viaggio.',
        );
      default:
        return (
          'Bugün Edible’da ✨',
          'Bugün yeni bir yer keşfet, kültürünü öğren ve bir sonraki yolculuğuna ilham kat.',
        );
    }
  }

  Future<List<Map<String, dynamic>>> notifications({int limit = 100}) async {
    final client = SupabaseService.client;
    final userId = _userId;
    if (client == null || userId == null) return const [];

    final rows = await client
        .from('app_notifications')
        .select('id,type,title,body,data,read_at,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Stream<List<Map<String, dynamic>>> notificationStream() {
    final client = SupabaseService.client;
    final userId = _userId;
    if (client == null || userId == null) return const Stream.empty();

    return client
        .from('app_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> markRead(String id) async {
    final client = SupabaseService.client;
    final userId = _userId;
    if (client == null || userId == null) return;

    await client
        .from('app_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> markAllRead() async {
    final client = SupabaseService.client;
    final userId = _userId;
    if (client == null || userId == null) return;

    await client
        .from('app_notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }

  Future<void> sendMessageNotification(String conversationId) async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      await client.functions.invoke(
        'send-message-notification',
        body: {'conversation_id': conversationId},
      );
    } catch (error) {
      // The message itself is already persisted. FCM failure must not make
      // sending a message appear to have failed to the user.
      debugPrint('[NOTIFICATIONS] Message push failed: $error');
    }
  }

  /// Returns a concise notification capability snapshot for diagnostics.
  /// This does not expose the full FCM token in logs/UI.
  Future<Map<String, dynamic>> diagnostics() async {
    final result = <String, dynamic>{
      'firebase_ready': _firebaseReady,
      'local_ready': _localReady,
      'user_id_present': _userId != null,
      'token_registered': _token != null && _token!.isNotEmpty,
      'platform': kIsWeb
          ? 'web'
          : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
    };

    if (_firebaseReady) {
      try {
        final settings = await _messaging.getNotificationSettings();
        result['permission'] = settings.authorizationStatus.name;
      } catch (_) {}
    }

    return result;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _authSubscription = null;
    _tokenSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _started = false;
  }
}

/// Top-level FCM background entry point required by FlutterFire.
@pragma('vm:entry-point')
Future<void> edibleFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    // Native Firebase configuration is validated during normal app startup.
  }
}
