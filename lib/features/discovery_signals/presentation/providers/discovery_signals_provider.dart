import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/discovery_event.dart';
import '../../domain/repositories/discovery_signals_repository.dart';

class DiscoverySignalsProvider extends ChangeNotifier {
  DiscoverySignalsProvider({
    required DiscoverySignalsRepository repository,
  }) : _repository = repository;

  final DiscoverySignalsRepository _repository;

  final Map<String, DateTime> _recent = {};
  int _pendingWrites = 0;
  int _generation = 0;
  bool _disposed = false;

  int get pendingWrites => _pendingWrites;

  void record(DiscoveryEvent event) {
    if (_disposed) return;

    final generation = _generation;
    final now = DateTime.now();
    final dedupeKey = [
      event.type.wireValue,
      event.contentId ?? '',
      event.category ?? '',
      event.countryCode ?? '',
      event.cityName ?? '',
    ].join('|');

    final previous = _recent[dedupeKey];
    if (previous != null && now.difference(previous) < const Duration(seconds: 20)) {
      return;
    }

    _recent[dedupeKey] = now;
    _prune(now);

    _pendingWrites++;
    unawaited(
      _repository.record(event).catchError((_) {
        // Behavior telemetry must never block or break discovery UX.
      }).whenComplete(() {
        if (_disposed || generation != _generation) return;
        _pendingWrites = (_pendingWrites - 1).clamp(0, 1 << 30);
      }),
    );
  }

  void _prune(DateTime now) {
    if (_disposed || _recent.length < 100) return;
    _recent.removeWhere(
      (_, timestamp) => now.difference(timestamp) > const Duration(minutes: 10),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _pendingWrites = 0;
    _recent.clear();
    super.dispose();
  }
}
