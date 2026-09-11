import 'package:flutter/material.dart';

import '../../domain/entities/travel_share_card.dart';

class TravelShareCardWidget extends StatelessWidget {
  const TravelShareCardWidget({
    required this.card,
    super.key,
  });

  final TravelShareCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.public,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EDIBLE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                card.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.location,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                card.dateLabel,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              if (card.rating != null)
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < card.rating!
                          ? Icons.star
                          : Icons.star_border,
                      size: 22,
                    ),
                  ),
                ),
              if (card.favoriteFood.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.restaurant_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.favoriteFood,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (card.note.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '“${card.note.trim()}”',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'My travel memory • Edible',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
