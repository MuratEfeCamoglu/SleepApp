import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/health/presentation/health_providers.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final _now = DateTime(2026, 10, 21, 9, 30);

SleepEntry _night(int daysAgo) {
  final night = addDays(dateOnly(_now), -daysAgo);
  final bed = DateTime(night.year, night.month, night.day, 23);
  return SleepEntry(
    id: nightKey(night),
    bedtime: bed,
    wake: bed.add(const Duration(hours: 8)),
  );
}

Future<ProviderContainer> _container(List<SleepEntry> entries) async {
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([
      for (final e in entries) e.toJson(),
    ]),
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(_FixedClock(_now)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('3’ten az kayıtta null', () async {
    final c = await _container([_night(1), _night(2)]);
    final sub = c.listen(healthSnapshotProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await c.read(healthSnapshotProvider.future), isNull);
  });

  test('kayıtlardan, ayarlardan ve bugünden türer', () async {
    final c = await _container([for (var d = 1; d <= 14; d++) _night(d)]);
    final sub = c.listen(healthSnapshotProvider, (_, _) {});
    addTearDown(sub.close);
    final s = await c.read(healthSnapshotProvider.future);
    expect(s, isNotNull);
    expect(s!.nights, 14);
    expect(s.debtMinutes, 0);
    expect(s.regularity, 100);
  });

  test('skor geçmişi 30 gece', () async {
    final c = await _container([for (var d = 1; d <= 14; d++) _night(d)]);
    final sub = c.listen(healthHistoryProvider, (_, _) {});
    addTearDown(sub.close);
    final history = await c.read(healthHistoryProvider.future);
    expect(history, hasLength(30));
    expect(history.last.score, isNotNull);
  });
}
