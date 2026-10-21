import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/log_editor.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final _stored = SleepEntry(
  id: '2026-10-20',
  bedtime: DateTime(2026, 10, 20, 23),
  wake: DateTime(2026, 10, 21, 7),
  note: 'Suda yüzüyordum',
);

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([_stored.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 10, 21, 9))),
    ],
  );
  addTearDown(c.dispose);
  c.listen(logEditorProvider, (_, _) {});
  await c.read(sleepLogProvider.future);
  return c;
}

void main() {
  test('rüya alanı olmayan kayıt taslağı "Kaydedildi" görünür', () async {
    final c = await _container();
    final draft = c.read(logEditorProvider)!;
    expect(draft.matches(_stored), isTrue);
  });

  test('tür ve duygu seçimi kirli yapar, kaydedince saklanır', () async {
    final c = await _container();
    final editor = c.read(logEditorProvider.notifier)
      ..toggleDreamKind(DreamKind.nightmare)
      ..toggleDreamEmotion(DreamEmotion.fear)
      ..toggleDreamEmotion(DreamEmotion.calm);
    final stored = c.read(sleepLogProvider).value!.forNight(_stored.night);
    expect(c.read(logEditorProvider)!.matches(stored), isFalse);

    await editor.save();
    final saved = c.read(sleepLogProvider).value!.forNight(_stored.night)!;
    expect(saved.dreamKind, DreamKind.nightmare);
    // Enum sırası: seçim sırası değil.
    expect(saved.dreamEmotions, [DreamEmotion.calm, DreamEmotion.fear]);
    expect(saved.note, 'Suda yüzüyordum');
    expect(c.read(logEditorProvider)!.matches(saved), isTrue);

    final prefs = c.read(sharedPreferencesProvider);
    final reread = await LocalSleepRepository(prefs).fetchAll();
    expect(reread.single, saved);
  });

  test('seçimi geri almak taslağı yeniden "Kaydedildi" yapar', () async {
    final c = await _container();
    c.read(logEditorProvider.notifier)
      ..toggleDreamKind(DreamKind.lucid)
      ..toggleDreamKind(DreamKind.lucid)
      ..toggleDreamEmotion(DreamEmotion.joy)
      ..toggleDreamEmotion(DreamEmotion.joy);
    final draft = c.read(logEditorProvider)!;
    expect(draft.dreamKind, isNull);
    expect(draft.matches(_stored), isTrue);
  });

  test('tür değiştirmek tek seçimdir; mood ve etkenler korunur', () async {
    final c = await _container();
    c.read(logEditorProvider.notifier)
      ..setMood(WakeMood.great)
      ..toggleFactor(SleepFactor.stress)
      ..toggleDreamKind(DreamKind.lucid)
      ..toggleDreamKind(DreamKind.recurring);
    final entry = c.read(logEditorProvider)!.toEntry();
    expect(entry.dreamKind, DreamKind.recurring);
    expect(entry.mood, WakeMood.great);
    expect(entry.factors, [SleepFactor.stress]);
  });

  group('bekleyen rüya taslağı', () {
    test('notu olan geceyi ezmez; taslak bekler', () async {
      final c = await _container();
      c
          .read(pendingDreamDraftProvider.notifier)
          .set(
            const PendingDreamDraft(
              note: 'Uçuyordum',
              kind: DreamKind.lucid,
              emotion: DreamEmotion.joy,
            ),
          );
      final draft = c.read(logEditorProvider)!;
      expect(draft.note, 'Suda yüzüyordum');
      expect(draft.dreamKind, isNull);
      expect(draft.matches(_stored), isTrue);
      expect(c.read(pendingDreamDraftProvider), isNotNull);
    });

    test('notsuz gecede not alanını doldurur; kaydedince temizlenir', () async {
      SharedPreferences.setMockInitialValues({
        LocalSleepRepository.storageKey: jsonEncode([
          _stored.copyWith(note: '', dreamKind: DreamKind.normal).toJson(),
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(
            _FixedClock(DateTime(2026, 10, 21, 9)),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(logEditorProvider, (_, _) {});
      await c.read(sleepLogProvider.future);

      c
          .read(pendingDreamDraftProvider.notifier)
          .set(
            const PendingDreamDraft(
              note: '  Uçuyordum ',
              kind: DreamKind.lucid,
              emotion: DreamEmotion.joy,
            ),
          );
      final draft = c.read(logEditorProvider)!;
      expect(draft.note, 'Uçuyordum');
      // Kayıtta tür varsa korunur; duygu eklenir.
      expect(draft.dreamKind, DreamKind.normal);
      expect(draft.dreamEmotions, {DreamEmotion.joy});
      final stored = c.read(sleepLogProvider).value!.forNight(_stored.night);
      expect(draft.matches(stored), isFalse, reason: 'yalnız Kaydet yazar');

      await c.read(logEditorProvider.notifier).save();
      expect(c.read(pendingDreamDraftProvider), isNull);
      final saved = c.read(sleepLogProvider).value!.forNight(_stored.night)!;
      expect(saved.note, 'Uçuyordum');
      expect(saved.dreamEmotions, [DreamEmotion.joy]);
      expect(c.read(logEditorProvider)!.matches(saved), isTrue);
    });

    test('boş taslak bırakılmaz', () async {
      final c = await _container();
      c
          .read(pendingDreamDraftProvider.notifier)
          .set(const PendingDreamDraft(note: '   '));
      expect(c.read(pendingDreamDraftProvider), isNull);
    });
  });
}
