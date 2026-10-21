import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Çarşamba. Dün gece = 20 Ekim.
final _today = DateTime(2026, 10, 21);

SleepEntry _night(
  int daysAgo, {
  String note = '',
  DreamKind? kind,
  List<DreamEmotion> emotions = const [],
  int minutes = 480,
  List<SleepFactor> factors = const [],
}) {
  final night = addDays(_today, -daysAgo);
  final bed = DateTime(night.year, night.month, night.day, 23);
  return SleepEntry(
    id: nightKey(night),
    bedtime: bed,
    wake: bed.add(Duration(minutes: minutes)),
    note: note,
    dreamKind: kind,
    dreamEmotions: emotions,
    factors: factors,
  );
}

void main() {
  test('kayıt yoksa boş', () {
    final i = computeDreamInsights(const [], _today);
    expect(i.isEmpty, isTrue);
    expect(i.topSymbols, isEmpty);
    expect(i.nightmareRate, isNull);
    expect(i.durationDelta, isNull);
    expect(i.nightmareFactor, isNull);
  });

  test('en sık 5 sembol: sayı azalan, eşitlikte sözlük sırası', () {
    final entries = [
      _night(1, note: 'yılan ve su'),
      _night(2, note: 'yılan, yılan, yılan'), // aynı gece bir kez
      _night(3, note: 'yılan ev'),
      _night(4, note: 'ev kedi'),
      _night(5, note: 'deniz köpek'),
      _night(6, note: 'deniz'),
      _night(7, note: 'kedi'),
    ];
    final top = computeDreamInsights(entries, _today).topSymbols;
    expect(top.map((c) => c.symbol.id), [
      'yilan', // 3
      'deniz', // 2 — sözlükte ev ve kediden önce
      'kedi', // 2 — sözlükte evden önce
      'ev', // 2
      'su', // 1 — köpekten önce
    ]);
    expect(top.map((c) => c.nights), [3, 2, 2, 2, 1]);
  });

  test('90 gece penceresi: daha eskisi ve bugün sayılmaz', () {
    final entries = [
      _night(90, note: 'yılan'), // pencerenin ilk gecesi
      _night(91, note: 'deniz'), // dışarıda
      _night(0, note: 'kedi'), // bu gece; henüz bitmemiş
    ];
    final i = computeDreamInsights(entries, _today);
    expect(i.dreamNights, 1);
    expect(i.topSymbols.map((c) => c.symbol.id), ['yilan']);
  });

  group('kabus karşılaştırması (≥3 gece kuralı)', () {
    List<SleepEntry> build({required int nightmares, required int others}) => [
      for (var d = 1; d <= nightmares; d++)
        _night(
          d,
          note: 'Kovalanıyordum',
          kind: DreamKind.nightmare,
          minutes: 400,
          factors: const [SleepFactor.stress, SleepFactor.caffeine],
        ),
      for (var d = 1; d <= others; d++)
        _night(
          20 + d,
          note: 'Deniz',
          kind: DreamKind.normal,
          minutes: 460,
          factors: const [SleepFactor.caffeine],
        ),
    ];

    test('2 kabus gecesinde oran ve süre gösterilmez', () {
      final i = computeDreamInsights(build(nightmares: 2, others: 5), _today);
      expect(i.nightmareNights, 2);
      expect(i.nightmareRate, isNull);
      expect(i.nightmareAverage, isNull);
      expect(i.otherAverage, isNull);
      expect(i.nightmareFactor, isNull);
    });

    test('2 diğer rüyalı gecede oran ve süre gösterilmez', () {
      final i = computeDreamInsights(build(nightmares: 4, others: 2), _today);
      expect(i.nightmareRate, isNull);
      expect(i.durationDelta, isNull);
    });

    test('her iki tarafta 3 gece varsa gösterilir', () {
      final i = computeDreamInsights(build(nightmares: 3, others: 3), _today);
      expect(i.kindedNights, 6);
      expect(i.nightmareRate, closeTo(0.5, 1e-9));
      expect(i.nightmareAverage, 400);
      expect(i.otherAverage, 460);
      expect(i.durationDelta, -60);
    });

    test('kabus gecelerinde en sık etken, eşitlikte etken sırası', () {
      final i = computeDreamInsights(build(nightmares: 3, others: 3), _today);
      // Kafein ve stres 3'er gece; SleepFactor sırasında kafein önce.
      expect(i.nightmareFactor?.factor, SleepFactor.caffeine);
      expect(i.nightmareFactor?.nights, 3);
    });

    test('etken 3 kabus gecesinden azsa null', () {
      final entries = [
        for (var d = 1; d <= 3; d++)
          _night(
            d,
            note: 'x',
            kind: DreamKind.nightmare,
            factors: d == 1 ? const [SleepFactor.noise] : const [],
          ),
      ];
      expect(computeDreamInsights(entries, _today).nightmareFactor, isNull);
    });

    test('oran türü girilmiş rüyalar içinde hesaplanır', () {
      final entries = [
        ...build(nightmares: 3, others: 3),
        _night(40, note: 'türsüz rüya'),
        _night(41, note: 'türsüz rüya'),
      ];
      final i = computeDreamInsights(entries, _today);
      expect(i.dreamNights, 8);
      expect(i.kindedNights, 6);
      expect(i.nightmareRate, closeTo(0.5, 1e-9));
      // Süre karşılaştırmasında diğer rüyalı geceler türsüzleri de içerir.
      expect(i.otherAverage, 468);
    });
  });
}
