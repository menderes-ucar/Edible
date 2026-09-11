import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/travel_year_summary.dart';

class YearInTravelShareCard extends StatelessWidget {
  const YearInTravelShareCard({
    required this.summary,
    super.key,
  });

  final TravelYearSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.secondaryContainer,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.public_rounded, size: 30),
                ),
                const Spacer(),
                Text(
                  'EDIBLE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${summary.year}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              context.l10n.text('yearInTravel'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 28),
            _ShareStat(
              value: summary.countryCount,
              label: context.l10n.text('countries'),
            ),
            const SizedBox(height: 14),
            _ShareStat(
              value: summary.cityCount,
              label: context.l10n.text('cities'),
            ),
            const SizedBox(height: 14),
            _ShareStat(
              value: summary.travelDayCount,
              label: context.l10n.text('travelDays'),
            ),
            const SizedBox(height: 14),
            _ShareStat(
              value: summary.photoCount,
              label: context.l10n.text('travelPhotos'),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded),
                const SizedBox(width: 8),
                Text(
                  '${summary.travelStreakYears} '
                  '${context.l10n.text('yearTravelStreak')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  const _ShareStat({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
