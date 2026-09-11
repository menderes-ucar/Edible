import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/culture_guide.dart';

class CultureGuideSection extends StatelessWidget {
  const CultureGuideSection({
    required this.guide,
    super.key,
  });

  final CultureGuide guide;

  @override
  Widget build(BuildContext context) {
    if (guide.isEmpty) return const SizedBox.shrink();

    final groups = <CultureTipType, List<CultureGuideItem>>{
      for (final type in CultureTipType.values)
        type: guide.ofType(type),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(),
        const SizedBox(height: 14),
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty) ...[
            _Section(
              type: entry.key,
              items: entry.value,
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.public),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.l10n.text('cultureIntelligence'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.type,
    required this.items,
  });

  final CultureTipType type;
  final List<CultureGuideItem> items;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _label(context, type),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        ...sorted.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: item.isPhrase
                ? _PhraseCard(item: item)
                : _CultureCard(
                    item: item,
                    icon: _icon(type),
                  ),
          ),
        ),
      ],
    );
  }

  String _label(BuildContext context, CultureTipType type) {
    final key = switch (type) {
      CultureTipType.doTip => 'cultureDo',
      CultureTipType.dontTip => 'cultureDont',
      CultureTipType.tipping => 'tipping',
      CultureTipType.transport => 'transportEtiquette',
      CultureTipType.religiousPlace => 'religiousEtiquette',
      CultureTipType.touristMistake => 'touristMistakes',
      CultureTipType.safety => 'safetyTips',
      CultureTipType.scam => 'scamWarnings',
      CultureTipType.phrase => 'basicPhrases',
    };

    return context.l10n.text(key);
  }

  IconData _icon(CultureTipType type) {
    return switch (type) {
      CultureTipType.doTip => Icons.check_circle_outline,
      CultureTipType.dontTip => Icons.block_outlined,
      CultureTipType.tipping => Icons.payments_outlined,
      CultureTipType.transport => Icons.directions_transit,
      CultureTipType.religiousPlace => Icons.account_balance_outlined,
      CultureTipType.touristMistake => Icons.error_outline,
      CultureTipType.safety => Icons.shield_outlined,
      CultureTipType.scam => Icons.warning_amber_rounded,
      CultureTipType.phrase => Icons.translate,
    };
  }
}

class _CultureCard extends StatelessWidget {
  const _CultureCard({
    required this.item,
    required this.icon,
  });

  final CultureGuideItem item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(item.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.item});

  final CultureGuideItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            if (item.phraseLocal?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              SelectableText(
                item.phraseLocal!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
            if (item.phrasePronunciation?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                item.phrasePronunciation!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (item.phraseTranslation?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(item.phraseTranslation!),
            ],
            if (item.body.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.body,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
