import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/detected_arrival.dart';

class ArrivalWelcomeSheet extends StatelessWidget {
  const ArrivalWelcomeSheet({
    required this.arrival,
    required this.onOpenGuide,
    required this.onNotNow,
    super.key,
  });

  final DetectedArrival arrival;
  final VoidCallback onOpenGuide;
  final VoidCallback onNotNow;

  String _flag(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2) return '🌍';

    return String.fromCharCodes(
      code.codeUnits.map((unit) => unit + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _flag(arrival.countryCode),
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.l10n.text('welcomeTo')} ${arrival.cityName}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.text('arrivalDetectedSubtitle'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenGuide,
              icon: const Icon(Icons.flight_land),
              label: Text(context.l10n.text('openFirst24Hours')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onNotNow,
              child: Text(context.l10n.text('notNow')),
            ),
          ],
        ),
      ),
    );
  }
}
