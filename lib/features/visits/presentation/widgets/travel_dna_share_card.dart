import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/travel_dna.dart';

class TravelDnaShareCard extends StatelessWidget {
  const TravelDnaShareCard({
    required this.dna,
    super.key,
  });

  final TravelDna dna;

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
              scheme.tertiaryContainer,
              scheme.primaryContainer,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 34),
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
              context.l10n.text('myTravelDna'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.text(dna.profileTitleKey),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.text(dna.profileSubtitleKey),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            _DnaBar(
              icon: Icons.restaurant_rounded,
              label: context.l10n.text('travelDnaTaste'),
              value: dna.foodScore,
              total: _safeTotal(dna),
            ),
            const SizedBox(height: 16),
            _DnaBar(
              icon: Icons.museum_rounded,
              label: context.l10n.text('travelDnaCulture'),
              value: dna.cultureScore,
              total: _safeTotal(dna),
            ),
            const SizedBox(height: 16),
            _DnaBar(
              icon: Icons.location_city_rounded,
              label: context.l10n.text('travelDnaPlaces'),
              value: dna.placeScore,
              total: _safeTotal(dna),
            ),
            const Spacer(),
            Text(
              '${dna.visitedCount} ${context.l10n.text('visited')} • '
              '${dna.triedCount} ${context.l10n.text('tried')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  int _safeTotal(TravelDna dna) {
    final total = dna.foodScore + dna.cultureScore + dna.placeScore;
    return total <= 0 ? 1 : total;
  }
}

class _DnaBar extends StatelessWidget {
  const _DnaBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.total,
  });

  final IconData icon;
  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / total).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text('$value'),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 9,
          ),
        ),
      ],
    );
  }
}
