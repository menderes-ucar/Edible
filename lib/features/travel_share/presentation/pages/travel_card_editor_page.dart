import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:edible/core/error/app_error_presenter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../travel_history/domain/entities/travel_visit.dart';
import '../../../travel_history/presentation/providers/travel_history_provider.dart';
import '../../../travel_journal/presentation/providers/travel_memory_provider.dart';
import '../../domain/entities/travel_card_style.dart';
import '../../domain/entities/travel_share_card.dart';
import '../services/travel_card_share_service.dart';
import '../widgets/editable_travel_card.dart';

class TravelCardEditorPage extends StatefulWidget {
  const TravelCardEditorPage({
    required this.travelVisitId,
    super.key,
  });

  final String travelVisitId;

  @override
  State<TravelCardEditorPage> createState() =>
      _TravelCardEditorPageState();
}

class _TravelCardEditorPageState extends State<TravelCardEditorPage> {
  final _shareKey = GlobalKey();

  TravelCardAspect _aspect = TravelCardAspect.portrait;
  TravelCardTemplate _template = TravelCardTemplate.minimal;
  String? _backgroundPath;
  TravelVisit? _visit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final history = context.read<TravelHistoryProvider>();

    TravelVisit? visit;
    for (final item in history.visits) {
      if (item.id == widget.travelVisitId) {
        visit = item;
        break;
      }
    }

    if (visit == null) {
      await history.refresh();

      for (final item in history.visits) {
        if (item.id == widget.travelVisitId) {
          visit = item;
          break;
        }
      }
    }

    if (!mounted) {
      return;
    }

    if (visit != null) {
      final memoryProvider = context.read<TravelMemoryProvider>();
      await memoryProvider.load(widget.travelVisitId);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _visit = visit;
      _loading = false;
    });
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  TravelShareCard _card(
    TravelVisit visit,
    TravelMemoryProvider memoryProvider,
  ) {
    final memory = memoryProvider.memory;

    return TravelShareCard(
      title: memory?.title.trim().isNotEmpty == true
          ? memory!.title
          : '${context.l10n.text('myTripTo')} ${visit.cityName}',
      location: '${visit.cityName}, ${visit.countryName}',
      dateLabel: _date(visit.visitDay),
      rating: memory?.rating,
      favoriteFood: memory?.favoriteFood ?? '',
      note: memory?.note ?? '',
    );
  }

  String? _backgroundUrl(
    TravelMemoryProvider provider,
  ) {
    final path = _backgroundPath;
    if (path == null) {
      return null;
    }
    return provider.signedPhotoUrls[path];
  }

  Future<void> _share() async {
    final visit = _visit;
    if (visit == null) {
      return;
    }

    final boundary = _shareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return;
    }

    try {
      await const TravelCardShareService().shareBoundary(
        boundary: boundary,
        fileName:
            'edible_${visit.cityName}_${_aspect.name}_${_template.name}',
        shareText:
            '${visit.cityName}, ${visit.countryName} • Edible',
      );
    } catch (error) {
      if (!mounted) {
      return;
    }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorPresenter.message(context, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = context.watch<TravelMemoryProvider>();
    final visit = _visit;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('travelCardEditor')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : visit == null
              ? Center(
                  child: Text(
                    context.l10n.text('travelVisitNotFound'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      context.l10n.text('cardFormat'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TravelCardAspect>(
                      segments: TravelCardAspect.values
                          .map(
                            (aspect) => ButtonSegment(
                              value: aspect,
                              label: Text(aspect.label),
                            ),
                          )
                          .toList(growable: false),
                      selected: {_aspect},
                      onSelectionChanged: (value) {
                        setState(() => _aspect = value.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.text('cardTemplate'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TravelCardTemplate.values.map((template) {
                        return ChoiceChip(
                          selected: _template == template,
                          label: Text(
                            switch (template) {
                              TravelCardTemplate.minimal =>
                                context.l10n.text('templateMinimal'),
                              TravelCardTemplate.postcard =>
                                context.l10n.text('templatePostcard'),
                              TravelCardTemplate.bold =>
                                context.l10n.text('templateBold'),
                            },
                          ),
                          onSelected: (_) {
                            setState(() => _template = template);
                          },
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.text('cardBackground'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    _BackgroundPicker(
                      paths: memoryProvider.photoPaths,
                      signedUrls: memoryProvider.signedPhotoUrls,
                      selectedPath: _backgroundPath,
                      onChanged: (path) {
                        setState(() => _backgroundPath = path);
                      },
                    ),
                    const SizedBox(height: 24),
                    RepaintBoundary(
                      key: _shareKey,
                      child: EditableTravelCard(
                        card: _card(visit, memoryProvider),
                        aspect: _aspect,
                        template: _template,
                        backgroundImageUrl:
                            _backgroundUrl(memoryProvider),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: Text(context.l10n.text('shareEditedCard')),
                    ),
                  ],
                ),
    );
  }
}

class _BackgroundPicker extends StatelessWidget {
  const _BackgroundPicker({
    required this.paths,
    required this.signedUrls,
    required this.selectedPath,
    required this.onChanged,
  });

  final List<String> paths;
  final Map<String, String> signedUrls;
  final String? selectedPath;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selectedPath == null,
              label: Text(context.l10n.text('noPhoto')),
              avatar: const Icon(Icons.hide_image_outlined),
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...paths.map((path) {
            final url = signedUrls[path];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(path),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: selectedPath == path ? 3 : 1,
                      color: selectedPath == path
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: url == null
                      ? const Icon(Icons.broken_image_outlined)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
