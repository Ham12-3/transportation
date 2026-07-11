import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/aircraft.dart';
import '../models/arrival.dart';
import '../models/journey.dart';
import '../models/saved_item.dart';
import '../models/stop_point.dart';
import '../models/transport_mode.dart';
import '../services/air_fleet_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/tfl_service.dart';

// ─────────────────────────── Services ───────────────────────────

final tflServiceProvider = Provider<TflService>((ref) => TflService());
final airFleetServiceProvider =
    Provider<AirFleetService>((ref) => AirFleetService.fromConfig());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

/// Set from main() after `StorageService.init()`.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in main()');
});

// ─────────────────────────── Location ───────────────────────────

final currentLocationProvider = FutureProvider<LatLng>((ref) async {
  return ref.read(locationServiceProvider).currentOrFallback();
});

// ─────────────────────────── Search state ───────────────────────

class JourneyQuery {
  final String from;
  final String fromLabel;
  final String to;
  final String toLabel;
  final Set<TransportMode> modes;
  final DateTime? when;
  final bool arriveBy;

  const JourneyQuery({
    this.from = 'Current Location',
    this.fromLabel = 'Current Location',
    this.to = '',
    this.toLabel = 'Where to?',
    this.modes = const {TransportMode.all},
    this.when,
    this.arriveBy = false,
  });

  bool get isReady => to.trim().isNotEmpty;

  JourneyQuery copyWith({
    String? from,
    String? fromLabel,
    String? to,
    String? toLabel,
    Set<TransportMode>? modes,
    DateTime? when,
    bool? arriveBy,
    bool clearWhen = false,
  }) =>
      JourneyQuery(
        from: from ?? this.from,
        fromLabel: fromLabel ?? this.fromLabel,
        to: to ?? this.to,
        toLabel: toLabel ?? this.toLabel,
        modes: modes ?? this.modes,
        when: clearWhen ? null : (when ?? this.when),
        arriveBy: arriveBy ?? this.arriveBy,
      );
}

class SearchController extends StateNotifier<JourneyQuery> {
  SearchController() : super(const JourneyQuery());

  void setFrom(String value, {String? label}) =>
      state = state.copyWith(from: value, fromLabel: label ?? value);
  void setTo(String value, {String? label}) =>
      state = state.copyWith(to: value, toLabel: label ?? value);

  void swap() => state = state.copyWith(
        from: state.to,
        fromLabel: state.toLabel,
        to: state.from,
        toLabel: state.fromLabel,
      );

  void toggleMode(TransportMode mode) {
    final next = {...state.modes};
    if (mode == TransportMode.all) {
      state = state.copyWith(modes: {TransportMode.all});
      return;
    }
    next.remove(TransportMode.all);
    if (next.contains(mode)) {
      next.remove(mode);
    } else {
      next.add(mode);
    }
    state = state.copyWith(modes: next.isEmpty ? {TransportMode.all} : next);
  }

  void setWhen(DateTime? when, {bool arriveBy = false}) {
    state = when == null
        ? state.copyWith(clearWhen: true)
        : state.copyWith(when: when, arriveBy: arriveBy);
  }
}

final searchProvider =
    StateNotifierProvider<SearchController, JourneyQuery>((ref) => SearchController());

// ─────────────────────────── Journey results ────────────────────

final journeyProvider = FutureProvider<List<Journey>>((ref) async {
  final q = ref.watch(searchProvider);
  if (!q.isReady) return const [];
  final tfl = ref.read(tflServiceProvider);

  String from = q.from;
  if (from == 'Current Location') {
    final loc = await ref.read(currentLocationProvider.future);
    from = '${loc.latitude},${loc.longitude}';
  }
  return tfl.planJourney(
    from: from,
    to: q.to,
    modes: q.modes.toList(),
    when: q.when,
    arriveBy: q.arriveBy,
  );
});

// ─────────────────────────── Nearby stops ───────────────────────

final nearbyModeProvider = StateProvider<TransportMode>((ref) => TransportMode.all);

final nearbyStopsProvider = FutureProvider<List<StopPoint>>((ref) async {
  final loc = await ref.watch(currentLocationProvider.future);
  final mode = ref.watch(nearbyModeProvider);
  final tfl = ref.read(tflServiceProvider);
  final modes = mode == TransportMode.all
      ? const [TransportMode.bus, TransportMode.tube, TransportMode.rail, TransportMode.tram]
      : [mode];
  return tfl.nearbyStops(center: loc, modes: modes);
});

// ─────────────────────────── Live arrivals ──────────────────────

final arrivalsProvider =
    FutureProvider.family<List<Arrival>, String>((ref, stopId) async {
  // Auto-refresh every 30s while watched.
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.read(tflServiceProvider).arrivals(stopId);
});

// ─────────────────────────── Air fleet ──────────────────────────

final airFleetProvider = FutureProvider<List<Aircraft>>((ref) async {
  // Auto-refresh every 15s.
  final timer = Timer(const Duration(seconds: 15), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.read(airFleetServiceProvider).statesInBounds(GeoBounds.london);
});

// ─────────────────────────── Saved items ────────────────────────

class SavedController extends StateNotifier<List<SavedItem>> {
  SavedController(this._storage) : super(_storage.all());
  final StorageService _storage;

  bool isSaved(String id) => _storage.isSaved(id);

  Future<void> toggle(SavedItem item) async {
    await _storage.toggle(item);
    state = _storage.all();
  }

  Future<void> remove(String id) async {
    await _storage.remove(id);
    state = _storage.all();
  }
}

final savedProvider =
    StateNotifierProvider<SavedController, List<SavedItem>>((ref) {
  return SavedController(ref.read(storageServiceProvider));
});
