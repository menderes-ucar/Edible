import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/error/app_error_presenter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../providers/arrival_guide_provider.dart';

class ArrivalGuidePage extends StatefulWidget {
  const ArrivalGuidePage({
    required this.countryCode,
    required this.cityName,
    super.key,
  });

  final String countryCode;
  final String cityName;

  @override
  State<ArrivalGuidePage> createState() => _ArrivalGuidePageState();
}

class _ArrivalGuidePageState extends State<ArrivalGuidePage> {
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    if (_languageCode == language) return;

    _languageCode = language;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ArrivalGuideProvider>().load(
            countryCode: widget.countryCode,
            cityName: widget.cityName,
            languageCode: language,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArrivalGuideProvider>();
    final guide = state.guide;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('first24Hours')),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(AppErrorPresenter.message(context, state.errorMessage)))
              : guide == null || guide.isEmpty
                  ? Center(child: Text(context.l10n.text('noArrivalGuide')))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        _WelcomeCard(
                          cityName: guide.cityName,
                          countryName: guide.countryName,
                          currencyCode: guide.currencyCode,
                          emergencyNumber: guide.emergencyNumber,
                        ),
                        const SizedBox(height: 16),
                        _InfoCard(
                          icon: Icons.flight_land,
                          title: context.l10n.text('airportToCity'),
                          body: guide.airportTransfer,
                        ),
                        _InfoCard(
                          icon: Icons.local_taxi_outlined,
                          title: context.l10n.text('taxiTips'),
                          body: guide.taxiTip,
                        ),
                        _InfoCard(
                          icon: Icons.sim_card_outlined,
                          title: context.l10n.text('simEsim'),
                          body: guide.simTip,
                        ),
                        _InfoCard(
                          icon: Icons.payments_outlined,
                          title: context.l10n.text('tipping'),
                          body: guide.tippingTip,
                        ),
                        const SizedBox(height: 14),
                        _ListSection(
                          title: context.l10n.text('firstDayChecklist'),
                          icon: Icons.checklist_rtl,
                          items: guide.firstDayChecklist,
                        ),
                        _ListSection(
                          title: context.l10n.text('scamWarnings'),
                          icon: Icons.warning_amber_rounded,
                          items: guide.scamWarnings,
                        ),
                        _ListSection(
                          title: context.l10n.text('mustTry'),
                          icon: Icons.restaurant_menu,
                          items: guide.mustTryTitles,
                        ),
                        if (guide.basicPhrases.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            context.l10n.text('basicPhrases'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          ...guide.basicPhrases.map(
                            (phrase) => Card(
                              child: ListTile(
                                title: SelectableText(
                                  phrase.local,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${phrase.pronunciation}\n'
                                  '${phrase.translation}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.cityName,
    required this.countryName,
    required this.currencyCode,
    required this.emergencyNumber,
  });

  final String cityName;
  final String countryName;
  final String currencyCode;
  final String emergencyNumber;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.public, size: 52),
            const SizedBox(height: 10),
            Text(
              '${context.l10n.text('welcomeTo')} $cityName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(countryName),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: context.l10n.text('currency'),
                    value: currencyCode,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: context.l10n.text('emergency'),
                    value: emergencyNumber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();

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
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
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
          const SizedBox(height: 8),
          ...items.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
