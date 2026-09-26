import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// Uyku modunun sonucu.
sealed class TrackResult {
  const TrackResult();
}

class TrackSaved extends TrackResult {
  const TrackSaved(this.entry);

  final SleepEntry entry;
}

class TrackTooShort extends TrackResult {
  const TrackTooShort();
}

/// Uyku modunu başlatır/bitirir. Başlangıç anı ayarlarda saklanır; uygulama
/// kapansa da sürer.
final NotifierProvider<TrackController, TrackResult?> trackControllerProvider =
    NotifierProvider.autoDispose<TrackController, TrackResult?>(
      TrackController.new,
    );

class TrackController extends Notifier<TrackResult?> {
  static const minMinutes = 20;

  @override
  TrackResult? build() => null;

  Future<void> start() => ref
      .read(settingsControllerProvider.notifier)
      .startTracking(ref.read(clockProvider).now());

  Future<void> cancel() =>
      ref.read(settingsControllerProvider.notifier).stopTracking();

  Future<TrackResult> finish() async {
    final start = ref.read(settingsControllerProvider).trackingStart;
    final now = ref.read(clockProvider).now();
    final settings = ref.read(settingsControllerProvider.notifier);
    if (start == null || now.difference(start).inMinutes < minMinutes) {
      await settings.stopTracking();
      return state = const TrackTooShort();
    }
    final night = nightOf(now);
    final log = ref.read(sleepLogProvider.notifier);
    final existing = (await ref.read(sleepLogProvider.future)).forNight(night);
    final entry = SleepEntry(
      id: nightKey(night),
      bedtime: start,
      wake: now,
      mood: existing?.mood ?? WakeMood.normal,
      factors: existing?.factors ?? const [],
      note: existing?.note ?? '',
    );
    await log.save(entry);
    await settings.stopTracking();
    return state = TrackSaved(entry);
  }
}
