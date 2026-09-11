import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/explore_category.dart';
import '../../domain/entities/explore_filters.dart';

class ExploreFilterSheet extends StatefulWidget {
  const ExploreFilterSheet({
    super.key,
    required this.initial,
    required this.initialCategory,
    required this.countryCodes,
    required this.countryNames,
    required this.citiesByCountry,
    required this.onApply,
  });

  final ExploreFilters initial;
  final ExploreCategory? initialCategory;
  final List<String> countryCodes;
  final Map<String, String> countryNames;
  final Map<String, List<String>> citiesByCountry;
  final void Function(ExploreFilters filters, ExploreCategory? category) onApply;

  @override
  State<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<ExploreFilterSheet> {
  late ExploreFilters _draft;
  late ExploreCategory? _category;

  static const _categoryOptions = <ExploreCategory>[
    ExploreCategory.food,
    ExploreCategory.snack,
    ExploreCategory.drink,
    ExploreCategory.culture,
    ExploreCategory.fruit,
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _category = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = _draft.countryCode?.trim().toUpperCase();
    final filteredCities = (selectedCountry == null || selectedCountry.isEmpty)
        ? widget.citiesByCountry.values.expand((cities) => cities).toSet().toList()
        : List<String>.from(widget.citiesByCountry[selectedCountry] ?? const <String>[]);

    filteredCities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.text('filters'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _draft = const ExploreFilters();
                      _category = null;
                    }),
                    child: Text(context.l10n.text('clearAll')),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.text('filterCountry'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _draft.countryCode,
                decoration: InputDecoration(
                  hintText: context.l10n.text('all'),
                  prefixIcon: const Icon(Icons.public_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text(context.l10n.text('all'))),
                  ...widget.countryCodes.map((code) => DropdownMenuItem<String>(
                    value: code,
                    child: Text(widget.countryNames[code] ?? code),
                  )),
                ],
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(countryCode: value, clearCountry: value == null, clearCity: true);
                }),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.text('filterCity'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: filteredCities.contains(_draft.cityName) ? _draft.cityName : null,
                decoration: InputDecoration(
                  hintText: context.l10n.text('all'),
                  prefixIcon: const Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text(context.l10n.text('all'))),
                  ...filteredCities.map((city) => DropdownMenuItem<String>(value: city, child: Text(city))),
                ],
                onChanged: (value) => setState(() {
                  _draft = _draft.copyWith(cityName: value, clearCity: value == null);
                }),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.text('filterCategory'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _category == null,
                    label: Text(context.l10n.text('all')),
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  ..._categoryOptions.map((category) => ChoiceChip(
                    selected: _category == category,
                    avatar: Icon(_iconFor(category), size: 17),
                    label: Text(context.l10n.text(category.localizationKey)),
                    onSelected: (_) => setState(() => _category = category),
                  )),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onApply(_draft, _category);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(context.l10n.text('applyFilters')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(ExploreCategory category) => switch (category) {
    ExploreCategory.food => Icons.restaurant_rounded,
    ExploreCategory.snack => Icons.cookie_rounded,
    ExploreCategory.drink => Icons.local_cafe_rounded,
    ExploreCategory.culture => Icons.museum_rounded,
    ExploreCategory.fruit => Icons.apple_rounded,
    ExploreCategory.place => Icons.place_rounded,
  };
}
