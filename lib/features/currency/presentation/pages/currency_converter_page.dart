import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/currency_rates_service.dart';
import '../../domain/currency_converter.dart';
import '../../domain/currency_data.dart';

/// Converts prices between the traveller's home currency and the destination's.
/// Rates are cached, so the last saved rates still work offline.
class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({this.countryCode, super.key});

  /// Destination country; selects the default "from" currency.
  final String? countryCode;

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  static const _quickAmounts = <double>[10, 50, 100, 500, 1000];
  static const _popular = <String>[
    'USD', 'EUR', 'GBP', 'TRY', 'JPY', 'CHF', 'CAD', 'AUD', 'CNY',
  ];

  final _service = CurrencyRatesService();
  final _amountController = TextEditingController(text: '100');

  CurrencyRates? _rates;
  bool _loading = true;
  bool _failed = false;
  bool _initialized = false;
  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final locale = Localizations.localeOf(context);
    final home = homeCurrencyFor(
      countryCode: locale.countryCode,
      languageCode: locale.languageCode,
    );
    final destination = currencyForCountry(widget.countryCode) ?? 'USD';

    _from = destination;
    _to = destination == home ? (home == 'USD' ? 'EUR' : 'USD') : home;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final rates = await _service.load(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  List<String> _codes(CurrencyRates rates) {
    final ordered = <String>{_from, _to, ..._popular};
    final rest = rates.usdRates.keys.where((code) => !ordered.contains(code)).toList()
      ..sort();
    return [
      ...ordered.where((code) => code == _from || code == _to || rates.usdRates.containsKey(code)),
      ...rest,
    ];
  }

  String _date(DateTime value) => value.toLocal().toIso8601String().substring(0, 10);

  String _rateText(double value) =>
      formatMoney(value, value >= 100 ? 2 : (value >= 1 ? 3 : 5));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final rates = _rates;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('currencyConverter'))),
      body: SafeArea(
        child: _loading && rates == null
            ? const Center(child: CircularProgressIndicator())
            : rates == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.text('currencyUnavailable'),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _load(force: true),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.text('retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _content(context, rates),
      ),
    );
  }

  Widget _content(BuildContext context, CurrencyRates rates) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final codes = _codes(rates);

    final amount = parseAmount(_amountController.text);
    final result = amount == null
        ? null
        : convertAmount(
            amount: amount,
            from: _from,
            to: _to,
            usdRates: rates.usdRates,
          );
    final unitRate = convertAmount(
      amount: 1,
      from: _from,
      to: _to,
      usdRates: rates.usdRates,
    );
    final missing = !rates.usdRates.containsKey(_from)
        ? _from
        : (!rates.usdRates.containsKey(_to) ? _to : null);

    Widget picker(
      String label,
      String value,
      ValueChanged<String> onChanged,
    ) {
      // Plain DropdownButton keeps working across Flutter versions
      // (DropdownButtonFormField changed its value/initialValue API).
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: [
              for (final code in codes)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            labelText: l10n.text('currencyAmount'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: picker(
                l10n.text('currencyFrom'),
                _from,
                (code) => setState(() => _from = code),
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                final previous = _from;
                _from = _to;
                _to = previous;
              }),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            Expanded(
              child: picker(
                l10n.text('currencyTo'),
                _to,
                (code) => setState(() => _to = code),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: missing != null
              ? Text(
                  l10n.text('currencyNotSupported').replaceAll('{code}', missing),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result == null
                          ? '—'
                          : '${formatMoney(result, currencyDecimals(_to))} $_to',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    if (unitRate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '1 $_from = ${_rateText(unitRate)} $_to',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        if (missing == null) ...[
          const SizedBox(height: 22),
          Text(
            l10n.text('currencyQuickReference'),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final value in _quickAmounts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatMoney(value, 0)} $_from',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    () {
                      final converted = convertAmount(
                        amount: value,
                        from: _from,
                        to: _to,
                        usdRates: rates.usdRates,
                      );
                      return converted == null
                          ? '—'
                          : '${formatMoney(converted, currencyDecimals(_to))} $_to';
                    }(),
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 22),
        Text(
          l10n.text('currencyRatesDate').replaceAll('{date}', _date(rates.fetchedAt)),
          style: textTheme.bodySmall,
        ),
        if (rates.isStale) ...[
          const SizedBox(height: 4),
          Text(
            l10n.text('currencyOffline'),
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: 6),
        Text(l10n.text('currencyAttribution'), style: textTheme.bodySmall),
      ],
    );
  }
}
