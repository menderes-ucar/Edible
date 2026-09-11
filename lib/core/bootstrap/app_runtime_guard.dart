import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class AppRuntimeGuard {
  AppRuntimeGuard._();

  static void install() {
    FlutterError.onError = FlutterError.presentError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'Edible runtime',
        ),
      );
      return true;
    };

    ErrorWidget.builder = (details) {
      return _RuntimeErrorFallback(details: details);
    };
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
