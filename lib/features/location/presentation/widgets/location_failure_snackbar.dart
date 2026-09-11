import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
import '../providers/location_provider.dart';

Future<void> showLocationFailureSnackBar(
  BuildContext context,
  LocationProvider provider,
) async {
  final messageKey = provider.errorMessageKey ?? 'locationError';
  final failure = provider.failureType;

  final canOpenSettings =
      failure == LocationFailureType.serviceDisabled ||
      failure == LocationFailureType.permissionDeniedForever;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.text(messageKey)),
      action: canOpenSettings
          ? SnackBarAction(
              label: context.l10n.text('openSettings'),
              onPressed: () {
                provider.openRelevantSettings();
              },
            )
          : null,
    ),
  );
}
