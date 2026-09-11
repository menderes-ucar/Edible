import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

enum TourSort { topRated, mostFavorite }

class TourFilterSheet extends StatefulWidget {
  const TourFilterSheet({
    super.key,
    required this.countryCodes,
    required this.countryNames,
    required this.citiesByCountry,
    required this.initialCountry,
    required this.initialCity,
    required this.initialMinRating,
    required this.initialSort,
    required this.onApply,
  });

  final List<String> countryCodes;
  final Map<String, String> countryNames;
  final Map<String, List<String>> citiesByCountry;
  final String? initialCountry;
  final String? initialCity;
  final double? initialMinRating;
  final TourSort initialSort;
  final void Function(String? country, String? city, double? minRating, TourSort sort) onApply;

  @override
  State<TourFilterSheet> createState() => _TourFilterSheetState();
}

class _TourFilterSheetState extends State<TourFilterSheet> {
  late String? _country = widget.initialCountry;
  late String? _city = widget.initialCity;
  late double? _minRating = widget.initialMinRating;
  late TourSort _sort = widget.initialSort;

  @override
  Widget build(BuildContext context) {
    final cities = (_country == null
            ? widget.citiesByCountry.values.expand((e) => e)
            : (widget.citiesByCountry[_country!] ?? const <String>[]))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(context.l10n.text('filters'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _country = null;
                      _city = null;
                      _minRating = null;
                      _sort = TourSort.topRated;
                    }),
                    child: Text(context.l10n.text('clearAll')),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: InputDecoration(
                  labelText: context.l10n.text('filterCountry'),
                  prefixIcon: const Icon(Icons.public_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text(context.l10n.text('all'))),
                  ...widget.countryCodes.map((code) => DropdownMenuItem<String>(value: code, child: Text(widget.countryNames[code] ?? code))),
                ],
                onChanged: (value) => setState(() {
                  _country = value;
                  _city = null;
                }),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: cities.contains(_city) ? _city : null,
                decoration: InputDecoration(
                  labelText: context.l10n.text('filterCity'),
                  prefixIcon: const Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text(context.l10n.text('all'))),
                  ...cities.map((city) => DropdownMenuItem<String>(value: city, child: Text(city))),
                ],
                onChanged: (value) => setState(() => _city = value),
              ),
              const SizedBox(height: 18),
              Text(context.l10n.text('minimumRating'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in <double?>[null, 3, 4, 4.5])
                    ChoiceChip(
                      selected: _minRating == value,
                      label: Text(value == null ? context.l10n.text('all') : '${value.toStringAsFixed(value == 4.5 ? 1 : 0)}+ ★'),
                      onSelected: (_) => setState(() => _minRating = value),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(context.l10n.text('sortBy'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SegmentedButton<TourSort>(
                segments: [
                  ButtonSegment<TourSort>(value: TourSort.topRated, label: Text(context.l10n.text('topRated'))),
                  ButtonSegment<TourSort>(value: TourSort.mostFavorite, label: Text(context.l10n.text('mostFavorite'))),
                ],
                selected: {_sort},
                onSelectionChanged: (value) => setState(() => _sort = value.first),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onApply(_country, _city, _minRating, _sort);
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
}
