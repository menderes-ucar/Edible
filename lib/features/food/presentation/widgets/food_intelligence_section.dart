import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/food_details.dart';

class FoodIntelligenceSection extends StatelessWidget {
  const FoodIntelligenceSection({
    required this.details,
    super.key,
  });

  final FoodDetails details;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.text('foodIntelligence'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        if (details.hasPrice)
          _InfoCard(
            icon: Icons.payments_outlined,
            title: context.l10n.text('typicalLocalPrice'),
            value: _priceLabel(),
          ),
        if (details.spicyLevel != null)
          _InfoCard(
            icon: Icons.local_fire_department_outlined,
            title: context.l10n.text('spicyLevel'),
            value: '${details.spicyLevel}/5',
          ),
        if (details.hasDietaryInfo)
          _DietaryCard(details: details),
        if (details.ingredients.isNotEmpty)
          _ChipsCard(
            icon: Icons.inventory_2_outlined,
            title: context.l10n.text('ingredients'),
            values: details.ingredients,
          ),
        if (details.allergens.isNotEmpty)
          _ChipsCard(
            icon: Icons.warning_amber_rounded,
            title: context.l10n.text('allergens'),
            values: details.allergens,
          ),
        if (_notEmpty(details.portionInfo))
          _InfoCard(
            icon: Icons.restaurant_menu,
            title: context.l10n.text('portion'),
            value: details.portionInfo!,
          ),
        if (_notEmpty(details.howLocalsEat))
          _InfoCard(
            icon: Icons.people_outline,
            title: context.l10n.text('howLocalsEat'),
            value: details.howLocalsEat!,
          ),
        if (_notEmpty(details.whenLocalsEat))
          _InfoCard(
            icon: Icons.schedule,
            title: context.l10n.text('whenLocalsEat'),
            value: details.whenLocalsEat!,
          ),
        if (_notEmpty(details.beforeYouOrder))
          _InfoCard(
            icon: Icons.lightbulb_outline,
            title: context.l10n.text('beforeYouOrder'),
            value: details.beforeYouOrder!,
          ),
      ],
    );
  }

  bool _notEmpty(String? value) => value != null && value.trim().isNotEmpty;

  String _priceLabel() {
    final currency = details.currencyCode ?? '';
    final min = details.typicalPriceMin;
    final max = details.typicalPriceMax;

    String number(double value) {
      return value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);
    }

    if (min != null && max != null) {
      return '$currency ${number(min)} – ${number(max)}'.trim();
    }
    if (min != null) return '$currency ${number(min)}+'.trim();
    if (max != null) return '≤ $currency ${number(max)}'.trim();
    return '';
  }
}

class _DietaryCard extends StatelessWidget {
  const _DietaryCard({required this.details});

  final FoodDetails details;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (details.halal != null)
        _StatusRow(
          label: context.l10n.text('halal'),
          value: details.halal!,
        ),
      if (details.vegan != null)
        _StatusRow(
          label: context.l10n.text('vegan'),
          value: details.vegan!,
        ),
      if (details.vegetarian != null)
        _StatusRow(
          label: context.l10n.text('vegetarian'),
          value: details.vegetarian!,
        ),
      if (details.containsPork != null)
        _StatusRow(
          label: context.l10n.text('containsPork'),
          value: details.containsPork!,
          positiveMeansGood: false,
        ),
      if (details.containsAlcohol != null)
        _StatusRow(
          label: context.l10n.text('containsAlcohol'),
          value: details.containsAlcohol!,
          positiveMeansGood: false,
        ),
      if (details.glutenFree != null)
        _StatusRow(
          label: context.l10n.text('glutenFree'),
          value: details.glutenFree!,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.text('dietaryInfo'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.positiveMeansGood = true,
  });

  final String label;
  final bool value;
  final bool positiveMeansGood;

  @override
  Widget build(BuildContext context) {
    final icon = value ? Icons.check_circle : Icons.cancel_outlined;
    final shownValue = value
        ? context.l10n.text('yes')
        : context.l10n.text('no');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            shownValue,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipsCard extends StatelessWidget {
  const _ChipsCard({
    required this.icon,
    required this.title,
    required this.values,
  });

  final IconData icon;
  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: values.map((value) => Chip(label: Text(value))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
