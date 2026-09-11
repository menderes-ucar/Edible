import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../domain/entities/saved_trip_draft.dart';
import '../../domain/services/saved_trip_date_policy.dart';
import '../providers/saved_trips_provider.dart';

class VacationPlannerPage extends StatefulWidget {
  const VacationPlannerPage({
    this.initialCountryCode,
    this.initialCountryName,
    this.initialCityName,
    super.key,
  });

  final String? initialCountryCode;
  final String? initialCountryName;
  final String? initialCityName;

  @override
  State<VacationPlannerPage> createState() => _VacationPlannerPageState();
}

class _VacationPlannerPageState extends State<VacationPlannerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<ExploreContent>? _catalog;
  String? _loadError;
  String? _countryCode;
  String? _countryName;
  String? _cityName;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _loadedLanguage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, today.day);
    _endDate = _startDate.add(const Duration(days: 4));

    final code = widget.initialCountryCode?.trim() ?? '';
    final country = widget.initialCountryName?.trim() ?? '';
    final city = widget.initialCityName?.trim() ?? '';
    if (code.isNotEmpty && country.isNotEmpty) {
      _countryCode = code.toUpperCase();
      _countryName = country;
    }
    if (city.isNotEmpty) _cityName = city;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_loadedLanguage == language) return;
    _loadedLanguage = language;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog(language));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog(String languageCode) async {
    if (!mounted) return;
    setState(() {
      _loadError = null;
      _catalog = null;
    });

    try {
      final items = await context.read<ExploreRepository>().getContents(
            languageCode: languageCode,
          );
      if (!mounted || _loadedLanguage != languageCode) return;
      setState(() {
        _catalog = items;
        _normalizeSelection(items);
      });
    } catch (error) {
      if (!mounted || _loadedLanguage != languageCode) return;
      setState(() {
        _loadError = AppErrorPresenter.message(context, error);
      });
    }
  }

  void _normalizeSelection(List<ExploreContent> items) {
    final code = _countryCode?.toLowerCase();
    if (code != null &&
        !items.any((item) => item.countryCode.toLowerCase() == code)) {
      _countryCode = null;
      _countryName = null;
      _cityName = null;
      return;
    }

    if (_cityName != null && _countryCode != null) {
      final city = _cityName!.toLowerCase();
      final country = _countryCode!.toLowerCase();
      if (!items.any(
        (item) =>
            item.countryCode.toLowerCase() == country &&
            item.cityName.toLowerCase() == city,
      )) {
        _cityName = null;
      }
    }
  }

  List<_CountryOption> get _countries {
    final byCode = <String, _CountryOption>{};
    for (final item in _catalog ?? const <ExploreContent>[]) {
      byCode.putIfAbsent(
        item.countryCode.toUpperCase(),
        () => _CountryOption(
          code: item.countryCode.toUpperCase(),
          name: item.countryName,
        ),
      );
    }
    final values = byCode.values.toList(growable: false);
    values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  List<String> get _cities {
    final country = _countryCode?.toLowerCase();
    if (country == null) return const [];
    final values = <String>{};
    for (final item in _catalog ?? const <ExploreContent>[]) {
      if (item.countryCode.toLowerCase() == country) {
        values.add(item.cityName);
      }
    }
    final result = values.toList(growable: false);
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  int get _tripDayCount =>
      _endDate.difference(_startDate).inDays + 1;

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (value == null || !mounted) return;

    setState(() {
      _startDate = value;
      final maxEnd = _startDate.add(
        const Duration(days: SavedTripDatePolicy.maxTripDays - 1),
      );
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      } else if (_endDate.isAfter(maxEnd)) {
        _endDate = maxEnd;
      }
    });
  }

  Future<void> _pickEnd() async {
    final maxEnd = _startDate.add(
      const Duration(days: SavedTripDatePolicy.maxTripDays - 1),
    );
    final initialEnd = _endDate.isBefore(_startDate)
        ? _startDate
        : _endDate.isAfter(maxEnd)
            ? maxEnd
            : _endDate;

    final value = await showDatePicker(
      context: context,
      initialDate: initialEnd,
      firstDate: _startDate,
      lastDate: maxEnd,
    );
    if (value == null || !mounted) return;
    setState(() => _endDate = value);
  }

  Future<void> _create() async {
    if (_submitting) return;
    final code = _countryCode?.trim() ?? '';
    final country = _countryName?.trim() ?? '';

    if (code.isEmpty || country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('vacationCountryRequired'))),
      );
      return;
    }

    if (_endDate.isBefore(_startDate) ||
        _tripDayCount < 1 ||
        _tripDayCount > SavedTripDatePolicy.maxTripDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n
                .text('vacationDateRangeInvalid')
                .replaceAll('{count}', SavedTripDatePolicy.maxTripDays.toString()),
          ),
        ),
      );
      return;
    }

    final city = _cityName?.trim() ?? '';
    final typedName = _nameController.text.trim();
    final generatedName = city.isNotEmpty
        ? '$city • ${_date(_startDate)}'
        : '$country • ${_date(_startDate)}';

    setState(() => _submitting = true);
    final provider = context.read<SavedTripsProvider>();
    final trip = await provider.create(
      SavedTripDraft(
        name: typedName.isEmpty ? generatedName : typedName,
        countryCode: code,
        countryName: country,
        cityName: city,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorPresenter.message(context, provider.errorMessage),
          ),
        ),
      );
      return;
    }

    context.go(AppRoutes.savedTripDetailFor(trip.id));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final countries = _countries;
    final cities = _cities;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('planVacation')),
      ),
      body: catalog == null && _loadError == null
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _LoadError(
                  message: _loadError!,
                  onRetry: () => _loadCatalog(
                    _loadedLanguage ??
                        Localizations.localeOf(context).languageCode,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                  children: [
                    _HeroCard(
                      title: context.l10n.text('vacationPlannerHeroTitle'),
                      subtitle:
                          context.l10n.text('vacationPlannerHeroSubtitle'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.text('whereTo'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: countries.any((item) => item.code == _countryCode)
                          ? _countryCode
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('country'),
                        prefixIcon: const Icon(Icons.public_rounded),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final country in countries)
                          DropdownMenuItem(
                            value: country.code,
                            child: Text(country.name),
                          ),
                      ],
                      onChanged: (value) {
                        final selected = countries
                            .where((item) => item.code == value)
                            .firstOrNull;
                        setState(() {
                          _countryCode = selected?.code;
                          _countryName = selected?.name;
                          _cityName = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: cities.contains(_cityName) ? _cityName : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('cityOptional'),
                        helperText: context.l10n.text('cityOptionalHelper'),
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(context.l10n.text('wholeCountry')),
                        ),
                        for (final city in cities)
                          DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          ),
                      ],
                      onChanged: _countryCode == null
                          ? null
                          : (value) => setState(
                                () => _cityName =
                                    value == null || value.isEmpty ? null : value,
                              ),
                    ),
                    if (_countryName != null) ...[
                      const SizedBox(height: 12),
                      _DestinationSelectionCard(
                        countryName: _countryName!,
                        cityName: _cityName,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.text('whenTo'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DateCard(
                            icon: Icons.flight_takeoff_rounded,
                            label: context.l10n.text('startDate'),
                            value: _date(_startDate),
                            onTap: _pickStart,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateCard(
                            icon: Icons.flight_land_rounded,
                            label: context.l10n.text('endDate'),
                            value: _date(_endDate),
                            onTap: _pickEnd,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n
                          .text('vacationMaxDaysHint')
                          .replaceAll('{count}', SavedTripDatePolicy.maxTripDays.toString()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _TripSummaryCard(
                      destination: _cityName?.trim().isNotEmpty == true
                          ? '${_cityName!}, ${_countryName ?? ''}'
                          : (_countryName ??
                              context.l10n.text('chooseDestination')),
                      days: _tripDayCount,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('tripNameOptional'),
                        helperText:
                            context.l10n.text('tripNameOptionalHelper'),
                        prefixIcon: const Icon(Icons.edit_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('notesOptional'),
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: catalog == null || _loadError != null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: FilledButton.icon(
                onPressed: _submitting ? null : _create,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(context.l10n.text('createVacationPlan')),
              ),
            ),
    );
  }
}

class _CountryOption {
  const _CountryOption({required this.code, required this.name});
  final String code;
  final String name;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 27,
            child: Icon(Icons.luggage_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationSelectionCard extends StatelessWidget {
  const _DestinationSelectionCard({
    required this.countryName,
    required this.cityName,
  });

  final String countryName;
  final String? cityName;

  @override
  Widget build(BuildContext context) {
    final city = cityName?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              city.isEmpty ? countryName : '$city, $countryName',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            city.isEmpty
                ? context.l10n.text('wholeCountry')
                : context.l10n.text('citySelected'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({
    required this.destination,
    required this.days,
  });

  final String destination;
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n
                .text('tripDays')
                .replaceAll('{count}', days.toString()),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.text('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
