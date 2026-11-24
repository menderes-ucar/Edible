import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class AppRuntimeGuard {
  AppRuntimeGuard._();

  static void install() {
    final crashReportingEnabled = _configureCrashReporting();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (crashReportingEnabled) {
        _record(details.exception, details.stack, fatal: true);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Edible runtime',
        ),
      );
      // FlutterError.reportError above already routes through
      // FlutterError.onError, which records to Crashlytics once.
      return true;
    };

    ErrorWidget.builder = (details) {
      return _RuntimeErrorFallback(details: details);
    };
  }
}

/// Crashlytics is optional infrastructure: it must never be the reason the
/// app fails to start. Collection is disabled in debug/profile builds.
bool _configureCrashReporting() {
  try {
    final enabled = kReleaseMode;
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    return enabled;
  } catch (error) {
    debugPrint('Crashlytics unavailable: $error');
    return false;
  }
}

void _record(Object error, StackTrace? stack, {required bool fatal}) {
  try {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  } catch (_) {
    // Reporting must never throw back into the error handler.
  }
}

class _RuntimeErrorFallback extends StatelessWidget {
  const _RuntimeErrorFallback({
    required this.details,
  });

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }

    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  l10n.text('unexpectedErrorTitle'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.text('unexpectedErrorMessage'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
