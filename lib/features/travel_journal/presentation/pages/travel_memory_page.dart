import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/error/app_error_presenter.dart';

import '../../../travel_share/domain/entities/travel_share_card.dart';
import '../../../travel_share/presentation/services/travel_card_share_service.dart';
import '../../../travel_share/presentation/widgets/travel_share_card_widget.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../travel_history/domain/entities/travel_visit.dart';
import '../../../travel_history/presentation/providers/travel_history_provider.dart';
import '../../domain/entities/travel_memory.dart';
import '../../domain/entities/travel_memory_draft.dart';
import '../providers/travel_memory_provider.dart';

class TravelMemoryPage extends StatefulWidget {
  const TravelMemoryPage({
    required this.travelVisitId,
    super.key,
  });

  final String travelVisitId;

  @override
  State<TravelMemoryPage> createState() => _TravelMemoryPageState();
}

class _TravelMemoryPageState extends State<TravelMemoryPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _favoriteFoodController = TextEditingController();
  final _picker = ImagePicker();
  final _shareCardKey = GlobalKey();

  TravelVisit? _visit;
  int? _rating;
  TravelMood? _mood;
  bool _initializedForm = false;
  bool _didLoad = false;
  bool _didPersistChanges = false;
  bool _isBootstrapping = true;
  String? _bootstrapError;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didLoad) {
      _didLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final visitId = widget.travelVisitId;

    if (mounted) {
      setState(() {
        _isBootstrapping = true;
        _bootstrapError = null;
      });
    }

    try {
      final history = context.read<TravelHistoryProvider>();

      var visit = _findVisit(history.visits);
      if (visit == null) {
        await history.refresh();
        visit = _findVisit(history.visits);
      }

      if (!mounted ||
          generation != _loadGeneration ||
          widget.travelVisitId != visitId) {
        return;
      }

      if (visit == null) {
        setState(() {
          _visit = null;
          _isBootstrapping = false;
        });
        return;
      }

      final memoryProvider = context.read<TravelMemoryProvider>();
      await memoryProvider.load(visitId);

      if (!mounted ||
          generation != _loadGeneration ||
          widget.travelVisitId != visitId) {
        return;
      }

      final memory = memoryProvider.memory;

      if (!_initializedForm) {
        _titleController.text =
            memory?.title.trim().isNotEmpty == true
                ? memory!.title
                : '${context.l10n.text('myTripTo')} ${visit.cityName}';

        _noteController.text = memory?.note ?? '';
        _favoriteFoodController.text = memory?.favoriteFood ?? '';
        _rating = memory?.rating;
        _mood = memory?.mood;
        _initializedForm = true;
      }

      setState(() {
        _visit = visit;
        _isBootstrapping = false;
        _bootstrapError = null;
      });
    } catch (error) {
      if (!mounted ||
          generation != _loadGeneration ||
          widget.travelVisitId != visitId) {
        return;
      }

      setState(() {
        _isBootstrapping = false;
        _bootstrapError = AppErrorPresenter.message(context, error);
      });
    }
  }

  TravelVisit? _findVisit(List<TravelVisit> visits) {
    for (final visit in visits) {
      if (visit.id == widget.travelVisitId) return visit;
    }

    return null;
  }

  Future<void> _pickPhoto() async {
    final visit = _visit;
    if (visit == null) {
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (image == null || !mounted) {
      return;
    }

    final provider = context.read<TravelMemoryProvider>();
    final uploadedPath = await provider.uploadPhoto(
      travelVisitId: visit.id,
      filePath: image.path,
    );

    if (!mounted) return;

    if (uploadedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage == null
                ? context.l10n.text('photoUploadFailed')
                : AppErrorPresenter.message(
                    context,
                    provider.errorMessage,
                  ),
          ),
        ),
      );
      return;
    }

    final saved = await _save(showMessage: false);
    if (!mounted || saved) return;

    // A badge shines only when the memory row actually references the photo.
    // If persistence fails, remove the uploaded object/state instead of leaving
    // an orphaned photo that appears saved only locally.
    await provider.removePhoto(uploadedPath);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage == null
              ? context.l10n.text('memorySaveFailed')
              : AppErrorPresenter.message(
                  context,
                  provider.errorMessage,
                ),
        ),
      ),
    );
  }


  Future<void> _shareMemory() async {
    final visit = _visit;
    if (visit == null) {
      return;
    }

    final boundary = _shareCardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return;
    }

    try {
      await const TravelCardShareService().shareBoundary(
        boundary: boundary,
        fileName: 'edible_${visit.cityName}_${visit.id}',
        shareText:
            '${_titleController.text.trim()} • ${visit.cityName}, ${visit.countryName}',
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

  Future<bool> _save({
    bool showMessage = true,
  }) async {
    final visit = _visit;
    if (visit == null) {
      return false;
    }

    final provider = context.read<TravelMemoryProvider>();

    final success = await provider.save(
      TravelMemoryDraft(
        travelVisitId: visit.id,
        countryCode: visit.countryCode,
        countryName: visit.countryName,
        cityName: visit.cityName,
        visitDate: visit.visitDay,
        title: _titleController.text.trim().isEmpty
            ? '${context.l10n.text('myTripTo')} ${visit.cityName}'
            : _titleController.text,
        note: _noteController.text,
        favoriteFood: _favoriteFoodController.text,
        rating: _rating,
        mood: _mood,
        photoPaths: provider.photoPaths,
      ),
    );

    if (!mounted) {
      return success;
    }

    if (success) {
      _didPersistChanges = true;
    }

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? context.l10n.text('memorySaved')
                : provider.errorMessage == null
                    ? context.l10n.text('memorySaveFailed')
                    : AppErrorPresenter.message(
                        context,
                        provider.errorMessage,
                      ),
          ),
        ),
      );
    }

    return success;
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _moodLabel(BuildContext context, TravelMood mood) {
    return switch (mood) {
      TravelMood.happy => context.l10n.text('moodHappy'),
      TravelMood.amazed => context.l10n.text('moodAmazed'),
      TravelMood.relaxed => context.l10n.text('moodRelaxed'),
      TravelMood.adventurous =>
        context.l10n.text('moodAdventurous'),
    };
  }

  String _moodEmoji(TravelMood mood) {
    return switch (mood) {
      TravelMood.happy => '😊',
      TravelMood.amazed => '🤩',
      TravelMood.relaxed => '😌',
      TravelMood.adventurous => '🧭',
    };
  }

  @override
  void dispose() {
    _loadGeneration++;
    _titleController.dispose();
    _noteController.dispose();
    _favoriteFoodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<TravelMemoryProvider>();
    final history = context.read<TravelHistoryProvider>();
    final visit = _visit;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop || !_didPersistChanges) return;
        history.refresh();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('tripMemory')),
        actions: [
          IconButton(
            tooltip: context.l10n.text('save'),
            onPressed:
                provider.isSaving || visit == null ? null : _save,
            icon: provider.isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: auth.isGuest
          ? Center(child: Text(context.l10n.text('passportLogin')))
          : _isBootstrapping || provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bootstrapError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              _bootstrapError!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(context.l10n.text('retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : visit == null
                      ? Center(
                          child: Text(
                            context.l10n.text('travelVisitNotFound'),
                          ),
                        )
                      : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        32,
                      ),
                      children: [
                        _TripHeader(
                          cityName: visit.cityName,
                          countryName: visit.countryName,
                          date: _date(visit.visitDay),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.text('memoryTitle'),
                            prefixIcon:
                                const Icon(Icons.title_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          minLines: 5,
                          maxLines: 12,
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.text('memoryNote'),
                            alignLabelWithHint: true,
                            prefixIcon:
                                const Icon(Icons.notes_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _favoriteFoodController,
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.text('favoriteFood'),
                            prefixIcon:
                                const Icon(Icons.restaurant_outlined),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          context.l10n.text('tripRating'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final value = index + 1;
                            final selected =
                                (_rating ?? 0) >= value;

                            return IconButton(
                              onPressed: () {
                                setState(() => _rating = value);
                              },
                              icon: Icon(
                                selected
                                    ? Icons.star
                                    : Icons.star_border,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.text('tripMood'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: TravelMood.values.map((mood) {
                            return ChoiceChip(
                              selected: _mood == mood,
                              label: Text(
                                '${_moodEmoji(mood)} '
                                '${_moodLabel(context, mood)}',
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _mood =
                                      _mood == mood ? null : mood;
                                });
                              },
                            );
                          }).toList(growable: false),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.text('tripPhotos'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: provider.isUploading
                                  ? null
                                  : _pickPhoto,
                              icon: provider.isUploading
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_photo_alternate_outlined,
                                    ),
                              label: Text(
                                context.l10n.text('addPhoto'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (provider.photoPaths.isEmpty)
                          Text(
                            context.l10n.text('noTripPhotos'),
                          )
                        else
                          _PhotoGrid(
                            paths: provider.photoPaths,
                            signedUrls: provider.signedPhotoUrls,
                            isRemovePending:
                                provider.isPhotoDeletePending,
                            onRemove: provider.removePhoto,
                          ),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            AppErrorPresenter.message(
                              context,
                              provider.errorMessage,
                            ),
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),
                        Text(
                          context.l10n.text('shareTripCard'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        RepaintBoundary(
                          key: _shareCardKey,
                          child: TravelShareCardWidget(
                            card: TravelShareCard(
                              title: _titleController.text.trim().isEmpty
                                  ? '${context.l10n.text('myTripTo')} ${visit.cityName}'
                                  : _titleController.text.trim(),
                              location:
                                  '${visit.cityName}, ${visit.countryName}',
                              dateLabel: _date(visit.visitDay),
                              rating: _rating,
                              favoriteFood:
                                  _favoriteFoodController.text,
                              note: _noteController.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _shareMemory,
                          icon: const Icon(Icons.ios_share_outlined),
                          label: Text(context.l10n.text('shareTripCard')),
                        ),

                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push(
                            AppRoutes.travelCardEditorFor(visit.id),
                          ),
                          icon: const Icon(Icons.tune_outlined),
                          label: Text(
                            context.l10n.text('editTravelCard'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed:
                              provider.isSaving ? null : _save,
                          icon: const Icon(Icons.bookmark_added_outlined),
                          label: Text(
                            context.l10n.text('saveMemory'),
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({
    required this.cityName,
    required this.countryName,
    required this.date,
  });

  final String cityName;
  final String countryName;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              child: Icon(Icons.auto_stories_outlined),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text('$countryName • $date'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.paths,
    required this.signedUrls,
    required this.isRemovePending,
    required this.onRemove,
  });

  final List<String> paths;
  final Map<String, String> signedUrls;
  final bool Function(String path) isRemovePending;
  final Future<bool> Function(String path) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: paths.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final path = paths[index];
        final url = signedUrls[path];

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                child: url == null
                    ? const Center(
                        child: Icon(Icons.broken_image_outlined),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: IconButton.filledTonal(
                  onPressed: isRemovePending(path)
                      ? null
                      : () async {
                          await onRemove(path);
                        },
                  icon: isRemovePending(path)
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}