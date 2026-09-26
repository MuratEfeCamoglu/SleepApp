import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/routine/data/local_routine_repository.dart';
import 'package:uyku/features/routine/domain/routine_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => LocalRoutineRepository(ref.watch(sharedPreferencesProvider)),
);

/// Bu akşam tamamlanan adımlar.
final NotifierProvider<RoutineProgress, Set<int>> routineProgressProvider =
    NotifierProvider.autoDispose<RoutineProgress, Set<int>>(
      RoutineProgress.new,
    );

class RoutineProgress extends Notifier<Set<int>> {
  String get _key => nightKey(eveningOf(ref.read(clockProvider).now()));

  @override
  Set<int> build() {
    ref.watch(clockProvider);
    return ref.watch(routineRepositoryProvider).doneSteps(_key);
  }

  /// Adımı işaretler; zaten işaretliyse dokunmaz.
  Future<void> markDone(int step) async {
    if (!state.contains(step)) await toggle(step);
  }

  Future<void> toggle(int step) async {
    final next = {...state};
    if (!next.remove(step)) next.add(step);
    state = next;
    await ref.read(routineRepositoryProvider).saveDoneSteps(_key, next);
  }
}

/// Bildirim izni durumu (hatırlatıcı uyarısı için).
final FutureProvider<bool> notificationPermissionProvider =
    FutureProvider.autoDispose<bool>(
      (ref) => ref.watch(notificationServiceProvider).permissionGranted(),
    );
