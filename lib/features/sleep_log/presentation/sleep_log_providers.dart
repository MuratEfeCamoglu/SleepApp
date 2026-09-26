import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_repository.dart';

final sleepRepositoryProvider = Provider<SleepRepository>(
  (ref) => LocalSleepRepository(ref.watch(sharedPreferencesProvider)),
);

/// Bugünün tarihi. Uygulama öne gelince yenilenir (bkz. `UykuApp`).
final todayProvider = Provider<DateTime>(
  (ref) => dateOnly(ref.watch(clockProvider).now()),
);

/// Tüm uyku kayıtları, geceye göre artan.
final sleepLogProvider = AsyncNotifierProvider<SleepLog, List<SleepEntry>>(
  SleepLog.new,
);

class SleepLog extends AsyncNotifier<List<SleepEntry>> {
  SleepRepository get _repo => ref.read(sleepRepositoryProvider);

  @override
  Future<List<SleepEntry>> build() =>
      ref.watch(sleepRepositoryProvider).fetchAll();

  Future<void> save(SleepEntry entry) async {
    await _repo.save(entry);
    state = AsyncData(await _repo.fetchAll());
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.fetchAll());
  }

  Future<void> clearAll() async {
    await _repo.clear();
    state = const AsyncData([]);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.fetchAll);
  }
}

extension SleepEntriesX on List<SleepEntry> {
  SleepEntry? forNight(DateTime night) {
    final key = nightKey(night);
    for (final e in this) {
      if (e.id == key) return e;
    }
    return null;
  }
}
