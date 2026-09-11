import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/discovery_stats.dart';

class DiscoveryScoreCard extends StatelessWidget {
  const DiscoveryScoreCard({
    required this.stats,
    super.key,
  });

  final DiscoveryStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: stats.progress,
                    strokeWidth: 7,
                  ),
                  Text(
                    '${stats.percent}%',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.text('discoveryScore'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.completed}/${stats.total} ${context.l10n.text('discoveriesCompleted')}',
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${context.l10n.text('visited')}: ${stats.visited}  •  '
                    '${context.l10n.text('tried')}: ${stats.tried}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
