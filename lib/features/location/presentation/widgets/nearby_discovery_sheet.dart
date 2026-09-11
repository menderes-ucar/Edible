import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../explore/domain/entities/explore_category.dart';
import '../../domain/entities/nearby_discovery.dart';

class NearbyDiscoverySheet extends StatelessWidget {
  const NearbyDiscoverySheet({
    required this.items,
    required this.radiusMeters,
    required this.onRadiusChanged,
    required this.onItemTap,
    super.key,
  });

  final List<NearbyDiscovery> items;
  final double radiusMeters;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<NearbyDiscovery> onItemTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.text('aroundYou'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                DropdownButton<double>(
                  value: radiusMeters,
                  items: const [
                    DropdownMenuItem(value: 1000, child: Text('1 km')),
                    DropdownMenuItem(value: 3000, child: Text('3 km')),
                    DropdownMenuItem(value: 5000, child: Text('5 km')),
                    DropdownMenuItem(value: 10000, child: Text('10 km')),
                  ],
                  onChanged: (value) {
                    if (value != null) onRadiusChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Text(
                  context.l10n.text('noNearbyDiscoveries'),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(_iconFor(item.content.category)),
                      ),
                      title: Text(
                        item.content.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${item.content.cityName} • ${item.content.category.name}',
                      ),
                      trailing: Text(
                        item.distanceLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onTap: () => onItemTap(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

IconData _iconFor(ExploreCategory category) {
  return switch (category) {
    ExploreCategory.place => Icons.place,
    ExploreCategory.food => Icons.restaurant,
    ExploreCategory.snack => Icons.cookie,
    ExploreCategory.culture => Icons.museum,
    ExploreCategory.fruit => Icons.eco,
    ExploreCategory.drink => Icons.local_cafe,
  };
}

}
