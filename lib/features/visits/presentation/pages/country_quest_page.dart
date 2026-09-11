import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/country_quest.dart';
import '../providers/visits_provider.dart';

class CountryQuestPage extends StatefulWidget {
  const CountryQuestPage({super.key});

  @override
  State<CountryQuestPage> createState() => _CountryQuestPageState();
}

class _CountryQuestPageState extends State<CountryQuestPage> {
  String? _loadedLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedLanguageCode == languageCode) return;
    _loadedLanguageCode = languageCode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitsProvider>().loadCountryQuests(languageCode);
    });
  }

  Future<void> _refresh() {
    return context.read<VisitsProvider>().loadCountryQuests(
          Localizations.localeOf(context).languageCode,
        );
  }

  void _openNext(CountryQuest quest) {
    final id = quest.nextContentId;
    if (id == null || id.trim().isEmpty) return;
    context.push(AppRoutes.contentDetail(id));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitsProvider>();
    final quests = provider.countryQuests;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.text('countryQuests'))),
      body: provider.isQuestLoading && quests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.questErrorMessage != null && quests.isEmpty
              ? _StateView(
                  icon: Icons.cloud_off_rounded,
                  title: context.l10n.text('countryQuestsLoadFailed'),
                  message: context.l10n.text('countryQuestsLoadFailedMessage'),
                  action: FilledButton.tonalIcon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.text('retry')),
                  ),
                )
              : quests.isEmpty
                  ? _StateView(
                      icon: Icons.explore_outlined,
                      title: context.l10n.text('countryQuestsEmptyTitle'),
                      message: context.l10n.text('countryQuestsEmptyMessage'),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          _Hero(quests: quests),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.text('countryQuestsSubtitle'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          ...quests.map(
                            (quest) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QuestCard(
                                quest: quest,
                                onTap: () => _openNext(quest),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.quests});

  final List<CountryQuest> quests;

  @override
  Widget build(BuildContext context) {
    final completed =
        quests.fold<int>(0, (sum, q) => sum + q.completedCount);
    final total = quests.fold<int>(0, (sum, q) => sum + q.totalCount);
    final finished = quests.where((q) => q.isComplete).length;
    final progress = total == 0 ? 0.0 : completed / total;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.secondaryContainer, scheme.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('countryQuestsHeroTitle'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed/$total ${context.l10n.text('countryQuestDiscoveriesDone')}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: quests.length, label: context.l10n.text('countries')),
              _Stat(
                value: finished,
                label: context.l10n.text('countryQuestFinishedCountries'),
              ),
              _Stat(
                value: completed,
                label: context.l10n.text('countryMasteryDiscoveries'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.onTap});

  final CountryQuest quest;
  final VoidCallback onTap;

  String _flag(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 2) return '🌍';
    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => unit + 127397),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_flag(quest.countryCode),
                    style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quest.countryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '${quest.percent}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: quest.progress, minHeight: 9),
            const SizedBox(height: 8),
            Text(
              '${quest.completedCount}/${quest.totalCount} '
              '${context.l10n.text('countryQuestDiscoveriesDone')}',
            ),
            const SizedBox(height: 14),
            if (quest.isComplete)
              Row(
                children: [
                  const Icon(Icons.verified_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.l10n.text('countryQuestComplete')),
                  ),
                ],
              )
            else if (quest.hasNext)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (quest.nextCategory) {
                    'food' || 'snack' || 'drink' || 'fruit' =>
                      Icons.restaurant_outlined,
                    'culture' => Icons.museum_outlined,
                    _ => Icons.place_outlined,
                  },
                ),
                title: Text(
                  quest.nextTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${context.l10n.text('countryQuestNextDiscovery')}'
                  '${(quest.nextCityName ?? '').trim().isEmpty ? '' : ' • ${quest.nextCityName}'}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onTap,
              )
            else
              Text(context.l10n.text('countryQuestNoNextDiscovery')),
          ],
        ),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 62),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
