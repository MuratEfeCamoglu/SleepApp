import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/dreams/domain/dream_journal.dart';
import 'package:uyku/features/dreams/domain/dream_reading.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

SleepEntry _entry(
  String id, {
  String note = '',
  DreamKind? kind,
  List<DreamEmotion> emotions = const [],
}) {
  final night = DateTime.parse(id);
  final bed = DateTime(night.year, night.month, night.day, 23);
  return SleepEntry(
    id: id,
    bedtime: bed,
    wake: bed.add(const Duration(hours: 8)),
    note: note,
    dreamKind: kind,
    dreamEmotions: emotions,
  );
}

void main() {
  group('readDream', () {
    test('semboller notta ilk geçiş sırasıyla', () {
      final reading = readDream(
        _entry('2026-10-01', note: 'Suda yüzüyordum, sonra yılan gördüm'),
      );
      expect(reading.symbols.map((s) => s.id), ['su', 'yuzmek', 'yilan']);
      expect(reading.hasSymbols, isTrue);
    });

    test('tür ve duygu yoksa tema yok', () {
      final reading = readDream(_entry('2026-10-01', note: 'Deniz'));
      expect(reading.theme, isNull);
      expect(reading.suggestion, isNull);
    });

    test('baskın duygu temayı belirler', () {
      final calm = readDream(
        _entry('2026-10-01', note: 'x', emotions: [DreamEmotion.calm]),
      );
      final mixed = readDream(
        _entry(
          '2026-10-01',
          note: 'x',
          kind: DreamKind.normal,
          emotions: [DreamEmotion.calm, DreamEmotion.fear],
        ),
      );
      expect(calm.theme, isNotNull);
      expect(mixed.theme, isNotNull);
      expect(mixed.theme, isNot(calm.theme));
      expect(
        dominantEmotion([DreamEmotion.calm, DreamEmotion.fear]),
        DreamEmotion.fear,
      );
    });

    test('yalnız tür girildiyse tür teması', () {
      final reading = readDream(
        _entry('2026-10-01', note: 'x', kind: DreamKind.lucid),
      );
      expect(reading.theme, isNotNull);
      expect(reading.kind, DreamKind.lucid);
    });

    test('kabusta sakinleştirici yeniden yazma önerisi', () {
      final reading = readDream(
        _entry(
          '2026-10-01',
          note: 'Karanlıkta kovalanıyordum',
          kind: DreamKind.nightmare,
          emotions: [DreamEmotion.fear],
        ),
      );
      expect(reading.suggestion, contains('yeniden yazmayı dene'));
      expect(reading.theme, isNotNull);
      expect(reading.symbols.map((s) => s.id), ['karanlik', 'kovalanmak']);
    });

    test('sembol yoksa boş liste', () {
      final reading = readDream(_entry('2026-10-01', note: 'Hiçbir şey'));
      expect(reading.symbols, isEmpty);
      expect(reading.hasSymbols, isFalse);
    });
  });

  group('dreamJournal', () {
    final entries = [
      _entry('2026-10-01', note: "İstanbul'da bir köprü"),
      _entry('2026-10-02'),
      _entry('2026-10-03', note: 'Yılan', kind: DreamKind.nightmare),
      _entry('2026-10-04', note: '   '),
      _entry('2026-10-05', note: 'Deniz ve ışık', kind: DreamKind.lucid),
    ];

    test('yalnız notu olan geceler, yeniden eskiye', () {
      expect(dreamJournal(entries).map((e) => e.id), [
        '2026-10-05',
        '2026-10-03',
        '2026-10-01',
      ]);
    });

    test('arama Türkçe büyük/küçük harf duyarsız', () {
      expect(dreamJournal(entries, query: 'ISTANBUL'), isEmpty);
      expect(dreamJournal(entries, query: 'İSTANBUL').single.id, '2026-10-01');
      expect(dreamJournal(entries, query: 'istanbul').single.id, '2026-10-01');
      expect(dreamJournal(entries, query: 'IŞIK').single.id, '2026-10-05');
      expect(dreamJournal(entries, query: 'yIlAn').single.id, '2026-10-03');
    });

    test('tür filtresi', () {
      expect(
        dreamJournal(entries, kind: DreamKind.nightmare).single.id,
        '2026-10-03',
      );
      expect(dreamJournal(entries, kind: DreamKind.recurring), isEmpty);
    });

    test('hasDream not, tür veya duyguyla', () {
      expect(_entry('2026-10-01').hasDream, isFalse);
      expect(_entry('2026-10-01', kind: DreamKind.normal).hasDream, isTrue);
      expect(
        _entry('2026-10-01', emotions: [DreamEmotion.joy]).hasDream,
        isTrue,
      );
    });
  });
}
