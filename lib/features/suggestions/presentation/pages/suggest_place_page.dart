import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/support_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/suggestions_service.dart';

/// Lets signed-in users suggest a place. Nothing is published automatically:
/// every suggestion waits for editor approval on the server.
class SuggestPlacePage extends StatefulWidget {
  const SuggestPlacePage({this.city, super.key});

  final String? city;

  @override
  State<SuggestPlacePage> createState() => _SuggestPlacePageState();
}

class _SuggestPlacePageState extends State<SuggestPlacePage> {
  static const _service = SuggestionsService();
  static const _categories = <String, String>{
    'place': 'places',
    'food': 'food',
    'drink': 'drinks',
    'snack': 'snacks',
    'culture': 'culture',
    'other': 'suggestCategoryOther',
  };

  final _nameController = TextEditingController();
  late final _cityController = TextEditingController(text: widget.city ?? '');
  final _countryController = TextEditingController();
  final _noteController = TextEditingController();
  final _websiteController = TextEditingController();

  String _category = 'place';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _noteController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  bool _validWebsite(String value) =>
      value.isEmpty ||
      (value.startsWith('https://') &&
          value.length > 8 &&
          !RegExp(r'\s').hasMatch(value));

  Future<void> _submit() async {
    if (_sending) return;
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final website = _websiteController.text.trim();

    if (name.length < 2 || city.isEmpty || !_validWebsite(website)) {
      setState(() => _error = l10n.text('suggestInvalid'));
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final result = await _service.submit(
      name: name,
      city: city,
      country: _countryController.text.trim(),
      category: _category,
      note: _noteController.text.trim(),
      website: website,
    );
    if (!mounted) return;

    switch (result) {
      case SuggestionResult.ok:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.text('suggestThanks'))),
        );
        context.pop();
        return;
      case SuggestionResult.invalid:
        _error = l10n.text('suggestInvalid');
      case SuggestionResult.duplicate:
        _error = l10n.text('suggestDuplicate');
      case SuggestionResult.rateLimited:
        _error = l10n.text('suggestRateLimited');
      case SuggestionResult.failed:
        _error = l10n.text('referralError');
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final supportEmail = SupportConfig.email;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('suggestPlaceTitle'))),
      body: SafeArea(
        child: !auth.isAuthenticated
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.text('suggestLoginRequired'),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.push('/login?from=%2Fsuggest-place'),
                        child: Text(l10n.text('signIn')),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    l10n.text('suggestPlaceSubtitle'),
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.text('suggestPlaceNotice'),
                    style: textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.text('suggestName'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.text('suggestCity'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _countryController,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.text('suggestCountry'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.text('suggestCategory'),
                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in _categories.entries)
                        ChoiceChip(
                          selected: _category == entry.key,
                          label: Text(l10n.text(entry.value)),
                          onSelected: (_) => setState(() => _category = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.text('suggestDetails'),
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _websiteController,
                    maxLength: 300,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.text('suggestWebsite'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.text('suggestSubmit')),
                  ),
                  if (supportEmail != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.text('suggestRemovalContact').replaceAll('{email}', supportEmail),
                      style: textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
