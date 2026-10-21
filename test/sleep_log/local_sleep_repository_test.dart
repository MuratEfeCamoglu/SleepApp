import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// F4 öncesi sürümün yazdığı biçim: rüya alanı yok.
const List<Map<String, Object>> _legacy = [
  {
    'id': '2026-09-23',
    'bedtime': '2026-09-23T23:30:00.000',
    'wake': '2026-09-24T07:10:00.000',
    'mood': 'tired',
    'factors': ['caffeine', 'screen'],
  },
  {
    'id': '2026-09-24',
    'bedtime': '2026-09-24T23:00:00.000',
    'wake': '2026-09-25T07:00:00.000',
    'mood': 'great',
    'factors': <String>[],
    'note': 'Denizde yüzüyordum',
  },
];

Future<SharedPreferences> _prefs(String? raw) {
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: ?raw,
  });
  return SharedPreferences.getInstance();
}

void main() {
  test('eski kayıtlar (rüya alanı yok) okunur ve sıralanır', () async {
    final repo = LocalSleepRepository(await _prefs(jsonEncode(_legacy)));
    final all = await repo.fetchAll();
    expect(all.map((e) => e.id), ['2026-09-23', '2026-09-24']);
    expect(all.every((e) => e.dreamKind == null), isTrue);
    expect(all.every((e) => e.dreamEmotions.isEmpty), isTrue);
    expect(all.last.note, 'Denizde yüzüyordum');
  });

  test('eski kayda rüya alanı eklenip yazılınca diğerleri korunur', () async {
    final prefs = await _prefs(jsonEncode(_legacy));
    final repo = LocalSleepRepository(prefs);
    final last = (await repo.fetchAll()).last;
    await repo.save(
      last.copyWith(
        dreamKind: DreamKind.lucid,
        dreamEmotions: const [DreamEmotion.joy],
      ),
    );
    final again = await LocalSleepRepository(prefs).fetchAll();
    expect(again.first.factors, [SleepFactor.caffeine, SleepFactor.screen]);
    expect(again.last.dreamKind, DreamKind.lucid);
    expect(again.last.dreamEmotions, [DreamEmotion.joy]);
  });

  group('bozuk veri: sleepLogProvider hata durumuna düşer, çökmez', () {
    Future<bool> loadFails(String raw) async {
      final prefs = await _prefs(raw);
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      // Hata `future`'ı tamamlamayabilir (yeniden deneme); durumu oku.
      c.listen(sleepLogProvider, (_, _) {});
      for (var i = 0; i < 10 && !c.read(sleepLogProvider).hasError; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return c.read(sleepLogProvider).hasError;
    }

    test('geçersiz JSON', () async {
      expect(await loadFails('{bozuk'), isTrue);
    });
  });

  test("factors'ta bilinmeyen değer atlanır, kayıt okunur", () async {
    final raw = jsonEncode([
      {
        ..._legacy.first,
        'factors': ['caffeine', 'meditation'],
      },
    ]);
    final prefs = await _prefs(raw);
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    final entries = await c.read(sleepLogProvider.future);
    expect(entries, hasLength(1));
    expect(entries.single.factors, [SleepFactor.caffeine]);
  });
}
