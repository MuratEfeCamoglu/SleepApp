import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/dreams/domain/dream_interview.dart';
import 'package:uyku/features/dreams/presentation/dream_interview_controller.dart';
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

/// Dün gece (bugün 2026-10-21).
final _lastNight = SleepEntry(
  id: '2026-10-20',
  bedtime: DateTime(2026, 10, 20, 23),
  wake: DateTime(2026, 10, 21, 7),
  factors: const [SleepFactor.stress],
);

final _older = SleepEntry(
  id: '2026-10-18',
  bedtime: DateTime(2026, 10, 18, 23),
  wake: DateTime(2026, 10, 19, 7),
  note: 'Suda yüzüyordum',
  dreamKind: DreamKind.normal,
  dreamEmotions: const [DreamEmotion.calm, DreamEmotion.fear],
);

Future<ProviderContainer> _container({List<SleepEntry>? entries}) async {
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([
      for (final e in entries ?? [_lastNight, _older]) e.toJson(),
    ]),
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 10, 21, 9))),
    ],
  );
  addTearDown(c.dispose);
  c.listen(dreamInterviewProvider, (_, _) {});
  await c.read(sleepLogProvider.future);
  return c;
}

void _answerAll(DreamInterviewController n) {
  n
    ..setEmotion(DreamEmotion.fear)
    ..next()
    ..setWake(DreamWakeFeeling.uneasy)
    ..next()
    ..setControl(DreamControl.no)
    ..next()
    ..togglePerson(null)
    ..next()
    ..setLife(LifeFocus.change)
    ..next()
    ..setRecurrence(DreamRecurrence.first)
    ..next();
}

void main() {
  test('boş notla adım 0 ilerlemez; not yazınca ilerler', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier);
    expect(c.read(dreamInterviewProvider).canAdvance, isFalse);
    n
      ..setNote('   ')
      ..next();
    expect(c.read(dreamInterviewProvider).step, 0);
    n
      ..setNote('Uçuyordum')
      ..next();
    expect(c.read(dreamInterviewProvider).step, 1);
  });

  test('cevapsız soruda İleri pasif; cevaplayınca açılır', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('Uçuyordum')
      ..next();
    var s = c.read(dreamInterviewProvider);
    expect(s.question, DreamQuestion.emotion);
    expect(s.canAdvance, isFalse);
    n.next();
    expect(c.read(dreamInterviewProvider).step, 1);
    n.setEmotion(DreamEmotion.joy);
    s = c.read(dreamInterviewProvider);
    expect(s.canAdvance, isTrue);
  });

  test('çoklu soruda "Hiçbiri" cevap sayılır, kaldırınca pasif', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('x')
      ..next()
      ..setEmotion(DreamEmotion.joy)
      ..next()
      ..setWake(DreamWakeFeeling.neutral)
      ..next()
      ..setControl(DreamControl.yes)
      ..next();
    expect(c.read(dreamInterviewProvider).question, DreamQuestion.people);
    expect(c.read(dreamInterviewProvider).canAdvance, isFalse);
    n.togglePerson(null);
    expect(c.read(dreamInterviewProvider).canAdvance, isTrue);
    n.togglePerson(null);
    expect(c.read(dreamInterviewProvider).canAdvance, isFalse);
  });

  test('Geri önceki cevabı korur', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('x')
      ..next()
      ..setEmotion(DreamEmotion.anger)
      ..next()
      ..setWake(DreamWakeFeeling.tired)
      ..back()
      ..back();
    final s = c.read(dreamInterviewProvider);
    expect(s.step, 0);
    expect(s.note, 'x');
    expect(s.answers.emotion, DreamEmotion.anger);
    expect(s.answers.wake, DreamWakeFeeling.tired);
    n.next();
    expect(c.read(dreamInterviewProvider).canAdvance, isTrue);
  });

  test('altı sorudan sonra sonuç adımı', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('x')
      ..next();
    _answerAll(n);
    final s = c.read(dreamInterviewProvider);
    expect(s.isResult, isTrue);
    expect(s.answers.isComplete, isTrue);
    n.next();
    expect(c.read(dreamInterviewProvider).step, s.step);
  });

  test('günlükten başlama notu, türü ve baskın duyguyu taşır', () async {
    final c = await _container();
    c.read(dreamInterviewProvider.notifier).startFrom(_older);
    final s = c.read(dreamInterviewProvider);
    expect(s.night, _older.id);
    expect(s.note, _older.note);
    expect(s.kind, DreamKind.normal);
    expect(s.answers.emotion, DreamEmotion.fear);
    expect(s.canAdvance, isTrue);
  });

  test('kaydetmeden önce kayıt değişmez; gece kaydında not/tür/duygu '
      'güncellenir, diğer alanlar korunur', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..startFrom(_older)
      ..setNote('Suda yüzüyordum, sonra ev')
      ..toggleKind(DreamKind.nightmare)
      ..next();
    _answerAll(n);
    expect(
      c.read(sleepLogProvider).value!.firstWhere((e) => e.id == _older.id),
      _older,
    );

    expect(await n.save(), DreamSaveResult.saved);
    final saved = c
        .read(sleepLogProvider)
        .value!
        .firstWhere((e) => e.id == _older.id);
    expect(saved.note, 'Suda yüzüyordum, sonra ev');
    expect(saved.dreamKind, DreamKind.nightmare);
    expect(saved.dreamEmotions, [DreamEmotion.fear, DreamEmotion.calm]);
    expect(saved.bedtime, _older.bedtime);
    expect(c.read(dreamInterviewProvider).saved, isTrue);
  });

  test('günlük dışından: dün gecenin kaydına yazar', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('Uçuyordum')
      ..next();
    _answerAll(n);
    expect(await n.save(), DreamSaveResult.saved);
    final saved = c.read(sleepLogProvider).value!.forNight(_lastNight.night)!;
    expect(saved.note, 'Uçuyordum');
    expect(saved.dreamEmotions, [DreamEmotion.fear]);
    expect(saved.factors, [SleepFactor.stress]);
  });

  test('dün gece kaydı yoksa yeni kayıt açılmaz', () async {
    final c = await _container(entries: [_older]);
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('Uçuyordum')
      ..next();
    _answerAll(n);
    expect(await n.save(), DreamSaveResult.noEntry);
    expect(c.read(sleepLogProvider).value, [_older]);
  });

  test(
    'dün gece kaydı yoksa not, tür ve duygu Kaydet taslağına taşınır',
    () async {
      final c = await _container(entries: [_older]);
      final n = c.read(dreamInterviewProvider.notifier)
        ..setNote('Uçuyordum ')
        ..toggleKind(DreamKind.lucid)
        ..next();
      _answerAll(n);
      expect(c.read(pendingDreamDraftProvider), isNull);
      expect(await n.save(), DreamSaveResult.noEntry);
      expect(
        c.read(pendingDreamDraftProvider),
        const PendingDreamDraft(
          note: 'Uçuyordum',
          kind: DreamKind.lucid,
          emotion: DreamEmotion.fear,
        ),
      );
      // Kalıcı hiçbir şey yazılmadı.
      expect(c.read(sleepLogProvider).value, [_older]);
    },
  );

  test('kayıt varsa taslak bırakılmaz', () async {
    final c = await _container();
    final n = c.read(dreamInterviewProvider.notifier)
      ..setNote('Uçuyordum')
      ..next();
    _answerAll(n);
    expect(await n.save(), DreamSaveResult.saved);
    expect(c.read(pendingDreamDraftProvider), isNull);
  });
}
