import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/food_filter.dart';

class FoodFilterBar extends StatelessWidget {
  const FoodFilterBar({
    required this.selected,
    required this.onToggle,
    required this.onClear,
    super.key,
  });

  final Set<FoodFilter> selected;
  final ValueChanged<FoodFilter> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.clear, size: 18),
                label: Text(context.l10n.text('clearFilters')),
                onPressed: onClear,
              ),
            ),
          ...FoodFilter.values.map(
            (filter) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected.contains(filter),
                label: Text(context.l10n.text(filter.localizationKey)),
                onSelected: (_) => onToggle(filter),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
