import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

void main() {
  group('nightOf', () {
    test('sabah uyanışı önceki akşama düşer', () {
      expect(nightOf(DateTime(2026, 9, 25, 7, 22)), DateTime(2026, 9, 24));
    });

    test('öğleden sonra uyanışı aynı güne düşer', () {
      expect(nightOf(DateTime(2026, 9, 25, 13)), DateTime(2026, 9, 25));
    });

    test('ay ve yıl sınırını geçer', () {
      expect(nightOf(DateTime(2027, 1, 1, 6)), DateTime(2026, 12, 31));
    });
  });

  group('nightKey', () {
    test('ay ve günü sıfırla doldurur', () {
      expect(nightKey(DateTime(2026, 3, 7)), '2026-03-07');
    });

    test('saat kısmını yok sayar', () {
      expect(nightKey(DateTime(2026, 11, 24, 23, 59)), '2026-11-24');
    });
  });

  group('addDays', () {
    test('ay sonunu geçer', () {
      expect(addDays(DateTime(2026, 1, 31), 1), DateTime(2026, 2));
    });

    test('geriye gider', () {
      expect(addDays(DateTime(2026, 3), -1), DateTime(2026, 2, 28));
    });

    test('saat kısmını atar', () {
      expect(addDays(DateTime(2026, 3, 29, 15, 30), 1), DateTime(2026, 3, 30));
    });
  });

  test('dateOnly saat kısmını atar', () {
    expect(dateOnly(DateTime(2026, 9, 24, 23, 15)), DateTime(2026, 9, 24));
  });

  group('SleepEntry', () {
    final full = SleepEntry(
      id: '2026-09-24',
      bedtime: DateTime(2026, 9, 24, 23, 10),
      wake: DateTime(2026, 9, 25, 7, 2),
      mood: WakeMood.refreshed,
      factors: const [SleepFactor.caffeine, SleepFactor.stress],
      note: 'Suda yüzüyordum, "uçuyordum".',
    );

    test('toJson/fromJson gidiş-dönüş', () {
      expect(SleepEntry.fromJson(full.toJson()), full);
    });

    test("boş not JSON'a yazılmaz ve geri okunur", () {
      final entry = full.copyWith(note: '');
      final json = entry.toJson();
      expect(json.containsKey('note'), isFalse);
      expect(SleepEntry.fromJson(json), entry);
    });

    test('eksik alanlar varsayılana düşer', () {
      final entry = SleepEntry.fromJson(const {
        'id': '2026-09-24',
        'bedtime': '2026-09-24T23:00:00.000',
        'wake': '2026-09-25T07:00:00.000',
      });
      expect(entry.mood, WakeMood.normal);
      expect(entry.factors, isEmpty);
      expect(entry.note, '');
    });

    test('create geceyi uyanıştan bulur', () {
      final entry = SleepEntry.create(
        bedtime: DateTime(2026, 9, 25, 0, 30),
        wake: DateTime(2026, 9, 25, 8),
      );
      expect(entry.id, '2026-09-24');
      expect(entry.night, DateTime(2026, 9, 24));
      expect(entry.durationMinutes, 450);
    });
  });

  group('SleepEntry rüya alanları', () {
    final base = SleepEntry(
      id: '2026-09-24',
      bedtime: DateTime(2026, 9, 24, 23, 10),
      wake: DateTime(2026, 9, 25, 7, 2),
      note: 'Denizde yüzüyordum.',
    );

    test('eski JSON (rüya alanı yok) hatasız okunur', () {
      final entry = SleepEntry.fromJson(const {
        'id': '2026-09-24',
        'bedtime': '2026-09-24T23:00:00.000',
        'wake': '2026-09-25T07:00:00.000',
        'mood': 'refreshed',
        'factors': ['stress'],
        'note': 'Eski not',
      });
      expect(entry.dreamKind, isNull);
      expect(entry.dreamEmotions, isEmpty);
      expect(entry.note, 'Eski not');
      expect(entry.factors, [SleepFactor.stress]);
    });

    test('tür ve duygular JSON gidiş-dönüş', () {
      final entry = base.copyWith(
        dreamKind: DreamKind.nightmare,
        dreamEmotions: const [DreamEmotion.fear, DreamEmotion.confusion],
      );
      final json = entry.toJson();
      expect(json['dreamKind'], 'nightmare');
      expect(json['dreamEmotions'], ['fear', 'confusion']);
      expect(SleepEntry.fromJson(json), entry);
    });

    test("boş tür ve duygu JSON'a yazılmaz", () {
      final json = base.toJson();
      expect(json.containsKey('dreamKind'), isFalse);
      expect(json.containsKey('dreamEmotions'), isFalse);
      expect(SleepEntry.fromJson(json), base);
    });

    test('bilinmeyen tür ve duygu sessizce atlanır', () {
      final entry = SleepEntry.fromJson({
        ...base.toJson(),
        'dreamKind': 'prophetic',
        'dreamEmotions': const ['joy', 'nostalgia', 42, 'fear'],
      });
      expect(entry.dreamKind, isNull);
      expect(entry.dreamEmotions, const [DreamEmotion.joy, DreamEmotion.fear]);
    });

    test('bilinmeyen veya yanlış tipli etkenler atlanır, sıra korunur', () {
      final entry = SleepEntry.fromJson({
        ...base.toJson(),
        'factors': const ['screen', 'moonPhase', null, 7, 'caffeine'],
      });
      expect(entry.factors, const [SleepFactor.screen, SleepFactor.caffeine]);
    });

    test('factors alanı yoksa boş liste', () {
      final json = base.toJson()..remove('factors');
      expect(SleepEntry.fromJson(json).factors, isEmpty);
    });

    test('copyWith türü korur, null ile temizler', () {
      final lucid = base.copyWith(dreamKind: DreamKind.lucid);
      expect(lucid.copyWith(note: 'x').dreamKind, DreamKind.lucid);
      expect(lucid.copyWith(dreamKind: null).dreamKind, isNull);
    });

    test('== ve hashCode yeni alanları içerir', () {
      final a = base.copyWith(dreamEmotions: const [DreamEmotion.calm]);
      final b = base.copyWith(dreamEmotions: const [DreamEmotion.calm]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == base.copyWith(dreamEmotions: const [DreamEmotion.joy]),
        isFalse,
      );
      expect(base == base.copyWith(dreamKind: DreamKind.normal), isFalse);
    });
  });
}
