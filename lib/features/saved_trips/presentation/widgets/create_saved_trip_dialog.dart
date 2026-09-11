import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/saved_trip.dart';
import '../../domain/entities/saved_trip_draft.dart';
import '../../domain/services/saved_trip_date_policy.dart';

class CreateSavedTripDialog extends StatefulWidget {
  const CreateSavedTripDialog({
    this.initialCountryCode = '',
    this.initialCountryName = '',
    this.initialCityName = '',
    this.initialName = '',
    this.existingTrip,
    super.key,
  });

  final String initialCountryCode;
  final String initialCountryName;
  final String initialCityName;
  final String initialName;
  final SavedTrip? existingTrip;

  bool get isEditing => existingTrip != null;

  @override
  State<CreateSavedTripDialog> createState() =>
      _CreateSavedTripDialogState();
}

class _CreateSavedTripDialogState extends State<CreateSavedTripDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _countryNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _notesController;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTrip;
    _nameController = TextEditingController(
      text: existing?.name ?? widget.initialName,
    );
    _countryCodeController = TextEditingController(
      text: existing?.countryCode ?? widget.initialCountryCode,
    );
    _countryNameController = TextEditingController(
      text: existing?.countryName ?? widget.initialCountryName,
    );
    _cityController = TextEditingController(
      text: existing?.cityName ?? widget.initialCityName,
    );
    _notesController = TextEditingController(
      text: existing?.notes ?? '',
    );

    final today = DateTime.now();
    _startDate = existing?.startDate ??
        DateTime(today.year, today.month, today.day);
    _endDate = existing?.endDate ?? _startDate.add(const Duration(days: 2));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryCodeController.dispose();
    _countryNameController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _pickStart() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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

  void _submit() {
    final name = _nameController.text.trim();
    final countryCode = _countryCodeController.text.trim();
    final countryName = _countryNameController.text.trim();
    final cityName = _cityController.text.trim();

    if (name.isEmpty ||
        countryCode.length != 2 ||
        countryName.isEmpty ||
        (!widget.isEditing && cityName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('completeRequiredFields'))),
      );
      return;
    }

    final tripDays = _endDate.difference(_startDate).inDays + 1;
    if (_endDate.isBefore(_startDate) ||
        tripDays < 1 ||
        tripDays > SavedTripDatePolicy.maxTripDays) {
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

    Navigator.of(context).pop(
      SavedTripDraft(
        name: name,
        countryCode: countryCode,
        countryName: countryName,
        cityName: cityName,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.l10n.text(
          widget.isEditing ? 'editTrip' : 'createTripWorkspace',
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isEditing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.text('tripDestinationLocked'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.text('tripName'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _countryCodeController,
              enabled: !widget.isEditing,
              textCapitalization: TextCapitalization.characters,
              maxLength: 2,
              decoration: InputDecoration(
                labelText: context.l10n.text('countryCode'),
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _countryNameController,
              enabled: !widget.isEditing,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.text('country'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cityController,
              enabled: !widget.isEditing,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: widget.isEditing && _cityController.text.trim().isEmpty
                    ? context.l10n.text('wholeCountry')
                    : context.l10n.text('city'),
                hintText: widget.isEditing && _cityController.text.trim().isEmpty
                    ? context.l10n.text('wholeCountry')
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n
                  .text('vacationMaxDaysHint')
                  .replaceAll('{count}', SavedTripDatePolicy.maxTripDays.toString()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStart,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_date(_startDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_date(_endDate)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.text('notes'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.text('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            context.l10n.text(widget.isEditing ? 'save' : 'create'),
          ),
        ),
      ],
    );
  }
}

Future<SavedTripDraft?> showCreateSavedTripDialog(
  BuildContext context, {
  String initialCountryCode = '',
  String initialCountryName = '',
  String initialCityName = '',
  String initialName = '',
}) {
  return showDialog<SavedTripDraft>(
    context: context,
    builder: (_) => CreateSavedTripDialog(
      initialCountryCode: initialCountryCode,
      initialCountryName: initialCountryName,
      initialCityName: initialCityName,
      initialName: initialName,
    ),
  );
}
