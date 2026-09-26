import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/streaks/domain/streaks.dart';

final FutureProvider<StreakSummary> streakSummaryProvider =
    FutureProvider.autoDispose<StreakSummary>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      return Streaks.compute(
        entries,
        ref.watch(settingsControllerProvider),
        ref.watch(todayProvider),
      );
    });

/// Kullanıcının rozetler ekranında gördüğü rozetler; yeni kazanılanları
/// Bugün ekranında işaretlemek için.
final seenBadgesProvider = NotifierProvider<SeenBadges, Set<SleepBadge>>(
  SeenBadges.new,
);

class SeenBadges extends Notifier<Set<SleepBadge>> {
  static const storageKey = 'badges.seen.v1';

  @override
  Set<SleepBadge> build() {
    final names = ref
        .watch(sharedPreferencesProvider)
        .getStringList(storageKey);
    final byName = SleepBadge.values.asNameMap();
    return {for (final n in names ?? const <String>[]) ?byName[n]};
  }

  Future<void> markSeen(Iterable<SleepBadge> badges) async {
    final next = {...state, ...badges};
    if (next.length == state.length) return;
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(storageKey, [
      for (final b in next) b.name,
    ]);
  }
}
