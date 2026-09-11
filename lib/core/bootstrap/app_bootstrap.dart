import '../config/app_config.dart';
import '../services/supabase_service.dart';
import '../../features/notifications/data/notification_service.dart';

enum AppBootstrapFailureType {
  missingConfiguration,
  initializationFailed,
}

class AppBootstrapFailure {
  const AppBootstrapFailure({
    required this.type,
    this.debugError,
  });

  final AppBootstrapFailureType type;
  final Object? debugError;
}

class AppBootstrapResult {
  const AppBootstrapResult._({
    required this.isReady,
    this.failure,
  });

  const AppBootstrapResult.ready() : this._(isReady: true);

  const AppBootstrapResult.failed(AppBootstrapFailure failure)
      : this._(isReady: false, failure: failure);

  final bool isReady;
  final AppBootstrapFailure? failure;
}

class AppBootstrap {
  const AppBootstrap();

  Future<AppBootstrapResult> initialize() async {
    final config = AppConfig.fromEnvironment();

    if (!config.hasSupabaseCredentials) {
      return const AppBootstrapResult.failed(
        AppBootstrapFailure(
          type: AppBootstrapFailureType.missingConfiguration,
        ),
      );
    }

    final initialized = await SupabaseService.initialize(config);

    if (!initialized || !SupabaseService.isInitialized) {
      return AppBootstrapResult.failed(
        AppBootstrapFailure(
          type: AppBootstrapFailureType.initializationFailed,
          debugError: SupabaseService.lastInitializationError,
        ),
      );
    }

    // Notification infrastructure is deliberately non-blocking: a missing
    // native Firebase configuration must never prevent Edible from opening.
    await NotificationService.instance.start();

    return const AppBootstrapResult.ready();
  }
}
