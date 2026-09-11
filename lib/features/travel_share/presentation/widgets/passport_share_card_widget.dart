import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class PassportShareCardWidget extends StatelessWidget {
  const PassportShareCardWidget({
    required this.travelDays,
    required this.countries,
    required this.cities,
    super.key,
  });

  final int travelDays;
  final int countries;
  final int cities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EDIBLE PASSPORT',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.text('myWorldOneBite'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 30),
              _Stat(value: travelDays, label: context.l10n.text('travelDays')),
              const SizedBox(height: 16),
              _Stat(value: countries, label: context.l10n.text('countries')),
              const SizedBox(height: 16),
              _Stat(value: cities, label: context.l10n.text('cities')),
              const Spacer(),
              Text(
                context.l10n.text('generatedWithEdible'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}
