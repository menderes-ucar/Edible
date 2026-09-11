import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/error/app_error_presenter.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/repositories/explore_repository.dart';
import '../widgets/smart_content_image.dart';

class CityMapPage extends StatefulWidget {
  const CityMapPage({required this.countryCode, required this.cityName, this.focusContentId, super.key});
  final String countryCode;
  final String cityName;
  final String? focusContentId;

  @override
  State<CityMapPage> createState() => _CityMapPageState();
}

class _CityMapPageState extends State<CityMapPage> {
  GoogleMapController? _controller;
  List<ExploreContent>? _items;
  String? _error;
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null && _error == null) _load();
  }

  Future<void> _load() async {
    try {
      final all = await context.read<ExploreRepository>().getContents(
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      final items = all.where((item) =>
        item.countryCode.trim().toUpperCase() == widget.countryCode.trim().toUpperCase() &&
        _normalize(item.cityName) == _normalize(widget.cityName),
      ).toList(growable: false);
      setState(() => _items = items);
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusRequested());
    } catch (e) {
      if (mounted) setState(() => _error = AppErrorPresenter.message(context, e));
    }
  }

  String _normalize(String value) => value.trim().toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i');

  Future<void> _focusRequested() async {
    if (_focused || _items == null || _items!.isEmpty || _controller == null) return;
    _focused = true;
    final target = widget.focusContentId == null
        ? _items!.first
        : _items!.firstWhere((e) => e.id == widget.focusContentId, orElse: () => _items!.first);
    await _controller!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(target.latitude, target.longitude), 14.2));
    if (mounted && widget.focusContentId != null) _showItem(target);
  }

  void _showItem(ExploreContent item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => _MapItemSheet(item: item, onOpen: () {
        Navigator.pop(sheet);
        context.push(AppRoutes.contentDetail(item.id), extra: item);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (_error != null) return Scaffold(appBar: AppBar(title: Text(widget.cityName)), body: Center(child: Text(_error!)));
    if (items == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (items.isEmpty) return Scaffold(appBar: AppBar(title: Text(widget.cityName)), body: Center(child: Text(context.l10n.text('mapEmpty'))));

    final center = LatLng(items.first.latitude, items.first.longitude);
    final markers = items.map((item) => Marker(
      markerId: MarkerId(item.id),
      position: LatLng(item.latitude, item.longitude),
      consumeTapEvents: true,
      onTap: () => _showItem(item),
      infoWindow: InfoWindow(title: item.title, snippet: item.shortDescription.isEmpty ? item.description : item.shortDescription),
    )).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.cityName, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(context.l10n.text('discoveryCount').replaceAll('{count}', items.length.toString()), style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 12.5),
          minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
          markers: markers,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          onMapCreated: (controller) {
            _controller = controller;
            _focusRequested();
          },
        ),
        Positioned(
          left: 16, right: 16, top: 14,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.touch_app_rounded),
                const SizedBox(width: 10),
                Expanded(child: Text(context.l10n.text('mapHint'))),
              ]),
            ),
          ),
        ),
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _controller?.animateCamera(CameraUpdate.newLatLngZoom(center, 12.5)),
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: Text(context.l10n.text('showCity')),
          ),
        ),
      ]),
    );
  }
}

class _MapItemSheet extends StatelessWidget {
  const _MapItemSheet({required this.item, required this.onOpen});
  final ExploreContent item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final description = item.description.trim().isNotEmpty ? item.description : item.shortDescription;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(height: 180, width: double.infinity, child: SmartContentImage(
              title: item.title,
              locale: Localizations.localeOf(context).languageCode,
              city: item.cityName,
              country: item.countryName,
              category: item.category.value,
              preferredUrl: item.coverImageUrl,
            )),
          ),
          const SizedBox(height: 12),
          Text(item.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${item.cityName}, ${item.countryName}', style: Theme.of(context).textTheme.bodySmall),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(description, maxLines: 5, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.open_in_new_rounded), label: Text(context.l10n.text('openDetails')))),
        ]),
      ),
    );
  }
}
