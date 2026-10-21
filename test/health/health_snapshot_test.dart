import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/health/domain/health_snapshot.dart';
import 'package:uyku/features/health/domain/health_tips.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Çarşamba. Dün gece = 20 Ekim (salı).
final _today = DateTime(2026, 10, 21);
const _settings = UserSettings(); // hedef 8 saat

/// [daysAgo] gece önceki akşam, [bedHour]:[bedMinute]'te yatış (24+ ertesi
/// gün), [minutes] uyku.
SleepEntry _night(
  int daysAgo, {
  int bedHour = 23,
  int bedMinute = 0,
  int minutes = 480,
  WakeMood mood = WakeMood.normal,
}) {
  final night = addDays(_today, -daysAgo);
  final bed = DateTime(night.year, night.month, night.day, bedHour, bedMinute);
  return SleepEntry(
    id: nightKey(night),
    bedtime: bed,
    wake: bed.add(Duration(minutes: minutes)),
    mood: mood,
  );
}

List<SleepEntry> _nights(
  Iterable<int> daysAgo, {
  int bedHour = 23,
  int minutes = 480,
  WakeMood mood = WakeMood.normal,
}) => [
  for (final d in daysAgo)
    _night(d, bedHour: bedHour, minutes: minutes, mood: mood),
];

void main() {
  group('computeHealthSnapshot', () {
    test('boş liste → null', () {
      expect(computeHealthSnapshot(const [], _settings, _today), isNull);
    });

    test('2 kayıt → null, 3 kayıt → skor', () {
      expect(computeHealthSnapshot(_nights([1, 2]), _settings, _today), isNull);
      final s = computeHealthSnapshot(_nights([1, 2, 3]), _settings, _today);
      expect(s, isNotNull);
      expect(s!.nights, 3);
      expect(s.score, inInclusiveRange(0, 100));
    });

    test('14 gecelik pencere dışındaki ve bu geceki kayıtlar sayılmaz', () {
      // 15 ve 16 gece önce + bu gece (0) → pencerede yalnız 2 kayıt.
      final entries = [
        ..._nights([15, 16, 0]),
        ..._nights([1, 2]),
      ];
      expect(computeHealthSnapshot(entries, _settings, _today), isNull);
      final withThird = [...entries, _night(14)];
      expect(computeHealthSnapshot(withThird, _settings, _today)!.nights, 3);
    });

    test('tam hedef, aynı saatler, en iyi uyanış → 100, Çok iyi', () {
      final s = computeHealthSnapshot(
        _nights(List.generate(14, (i) => i + 1), mood: WakeMood.great),
        _settings,
        _today,
      )!;
      expect(s.debtMinutes, 0);
      expect(s.regularity, 100);
      expect(s.score, 100);
      expect(s.band, HealthBand.veryGood);
      expect(s.components, const [
        HealthComponent(
          kind: HealthComponentKind.duration,
          points: 40,
          max: 40,
        ),
        HealthComponent(
          kind: HealthComponentKind.regularity,
          points: 25,
          max: 25,
        ),
        HealthComponent(kind: HealthComponentKind.debt, points: 20, max: 20),
        HealthComponent(kind: HealthComponentKind.mood, points: 15, max: 15),
      ]);
    });

    test('borç tavanı: 7 saat ve üstü borç → borç bileşeni 0', () {
      // 14 gece × 6 saat: gece başına 120 dk eksik.
      final s = computeHealthSnapshot(
        _nights(List.generate(14, (i) => i + 1), minutes: 360),
        _settings,
        _today,
      )!;
      expect(s.debtMinutes, 14 * 120);
      expect(s.component(HealthComponentKind.debt)!.points, 0);
      // Süre: 360/480 = 0,75 → (0,75 − 0,7) / 0,2 × 40 = 10.
      expect(s.component(HealthComponentKind.duration)!.points, 10);
    });

    test('borç bileşeni doğrusal: 210 dk borç → 10 puan', () {
      // 3 gece: ikisi tam, biri 210 dk eksik.
      final entries = [_night(1), _night(2), _night(3, minutes: 480 - 210)];
      final s = computeHealthSnapshot(entries, _settings, _today)!;
      expect(s.debtMinutes, 210);
      expect(s.component(HealthComponentKind.debt)!.points, 10);
    });

    test('süre bileşeni sınırları: %90 → 40, %70 → 0', () {
      final full = computeHealthSnapshot(
        _nights([1, 2, 3], minutes: 432), // 0,9 × 480
        _settings,
        _today,
      )!;
      expect(full.component(HealthComponentKind.duration)!.points, 40);
      final zero = computeHealthSnapshot(
        _nights([1, 2, 3], minutes: 336), // 0,7 × 480
        _settings,
        _today,
      )!;
      expect(zero.component(HealthComponentKind.duration)!.points, 0);
    });

    test('uyanış hissi: hep "bitkin" → 0, hep "harika" → 15', () {
      final low = computeHealthSnapshot(
        _nights([1, 2, 3], mood: WakeMood.exhausted),
        _settings,
        _today,
      )!;
      expect(low.component(HealthComponentKind.mood)!.points, 0);
      final high = computeHealthSnapshot(
        _nights([1, 2, 3], mood: WakeMood.great),
        _settings,
        _today,
      )!;
      expect(high.component(HealthComponentKind.mood)!.points, 15);
    });

    test('SRI null → düzenlilik dışarıda, skor 75 üzerinden ölçeklenir', () {
      // Gün aşırı 4 gece: ardışık çift yok.
      final s = computeHealthSnapshot(
        _nights([1, 3, 5, 7]),
        _settings,
        _today,
      )!;
      expect(s.regularity, isNull);
      expect(s.component(HealthComponentKind.regularity), isNull);
      expect(s.components, hasLength(3));
      // 40 + 20 + 7,5 (normal = 2/4) = 67,5 → 67,5 / 75 × 100 = 90.
      expect(s.score, 90);
    });

    test('hafta sonu esnekliği hedef süreyi değiştirmez', () {
      final entries = _nights([1, 2, 3, 4, 5, 6, 7]);
      final a = computeHealthSnapshot(entries, _settings, _today)!;
      final b = computeHealthSnapshot(
        entries,
        _settings.copyWith(weekendShift: 120),
        _today,
      )!;
      expect(b.score, a.score);
      expect(b.debtMinutes, a.debtMinutes);
    });

    test('jetlag null: hafta sonu gecesi yoksa', () {
      // 20 Ekim salı; 1, 2, 3 gece önce = salı, pazartesi, pazar.
      final s = computeHealthSnapshot(_nights([1, 2, 3]), _settings, _today)!;
      expect(s.socialJetlagMinutes, isNull);
    });
  });

  group('computeSleepDebt', () {
    test('fazla uyku borcu gece başına en çok 60 dk düşürür', () {
      final entries = [
        _night(3, minutes: 420), // +60
        _night(2, minutes: 600), // −60 (120 fazla, tavan 60)
        _night(1, minutes: 420), // +60
      ];
      expect(computeSleepDebt(entries, 480), 60);
    });

    test('önceden fazla uyumak borç biriktirmez (negatif olmaz)', () {
      final entries = [
        _night(3, minutes: 600), // borç 0 iken fazla → 0
        _night(2, minutes: 420),
        _night(1, minutes: 420),
      ];
      expect(computeSleepDebt(entries, 480), 120);
    });

    test('hep fazla uyku → 0', () {
      expect(computeSleepDebt(_nights([1, 2, 3], minutes: 600), 480), 0);
    });

    test('kayıt sırası sonucu değiştirmez (geceye göre işlenir)', () {
      final entries = [
        _night(1, minutes: 420),
        _night(2, minutes: 600),
        _night(3, minutes: 420),
      ];
      expect(computeSleepDebt(entries, 480), 60);
    });
  });

  group('computeRegularity (SRI)', () {
    test('aynı saatlerde uyunan 14 gece → 100', () {
      expect(computeRegularity(_nights(List.generate(14, (i) => i + 1))), 100);
    });

    test('her gece 1 saat kayan yatış → 100 − 200·120/1440', () {
      // 23:00–07:00 ve 00:00–08:00 dönüşümlü: her çiftte 120 dk farklı.
      final entries = [
        for (var d = 1; d <= 6; d++) _night(d, bedHour: d.isEven ? 23 : 24),
      ];
      expect(computeRegularity(entries), closeTo(100 - 200 * 120 / 1440, 1e-9));
    });

    test('5 ardışık çiftten azı → null; tam 5 → değer', () {
      expect(computeRegularity(_nights([1, 2, 3, 4, 5])), isNull);
      expect(computeRegularity(_nights([1, 2, 3, 4, 5, 6])), 100);
    });

    test('çok düzensiz uyku sıfıra kırpılır', () {
      // Gündüz ve gece dönüşümlü: hiç örtüşme yok → p küçük → negatif SRI.
      final entries = [
        for (var d = 1; d <= 6; d++)
          _night(d, bedHour: d.isEven ? 23 : 13, minutes: 600),
      ];
      expect(computeRegularity(entries), 0);
    });
  });

  group('computeSocialJetlag', () {
    test('hafta sonu orta noktası 2 saat geç → 120 dk', () {
      // 28 gece: cuma/cumartesi 01:00 yatış, diğerleri 23:00; hepsi 8 saat.
      final entries = [
        for (var d = 1; d <= 28; d++)
          if (UserSettings.isWeekendNight(addDays(_today, -d)))
            _night(d, bedHour: 25)
          else
            _night(d),
      ];
      expect(computeSocialJetlag(entries), 120);
    });

    test('her grupta en az 2 gece yoksa null', () {
      // 17 Ekim cumartesi = 4 gece önce; tek hafta sonu gecesi.
      final entries = [_night(4), _night(1), _night(2)];
      expect(computeSocialJetlag(entries), isNull);
      final two = [...entries, _night(5)]; // 16 Ekim cuma
      expect(computeSocialJetlag(two), 0);
    });

    test('snapshot jetlag için 28 gecelik pencereyi kullanır', () {
      final entries = [
        ..._nights([1, 2, 3]),
        // 25 ve 26 gece önce: 26 Eylül cumartesi, 25 Eylül cuma.
        _night(25, bedHour: 25),
        _night(26, bedHour: 25),
      ];
      expect(UserSettings.isWeekendNight(addDays(_today, -25)), isTrue);
      expect(UserSettings.isWeekendNight(addDays(_today, -26)), isTrue);
      final s = computeHealthSnapshot(entries, _settings, _today)!;
      expect(s.nights, 3);
      expect(s.socialJetlagMinutes, 120);
    });
  });

  group('HealthBand', () {
    test('bant sınırları', () {
      expect(HealthBand.of(100), HealthBand.veryGood);
      expect(HealthBand.of(85), HealthBand.veryGood);
      expect(HealthBand.of(84), HealthBand.good);
      expect(HealthBand.of(70), HealthBand.good);
      expect(HealthBand.of(69), HealthBand.fair);
      expect(HealthBand.of(50), HealthBand.fair);
      expect(HealthBand.of(49), HealthBand.needsWork);
      expect(HealthBand.of(0), HealthBand.needsWork);
    });
  });

  group('healthScoreHistory', () {
    test('30 nokta, eski → yeni; son nokta güncel skora eşit', () {
      final entries = _nights(List.generate(20, (i) => i + 1));
      final history = healthScoreHistory(entries, _settings, _today);
      expect(history, hasLength(30));
      expect(history.first.night, addDays(_today, -30));
      expect(history.last.night, addDays(_today, -1));
      expect(
        history.last.score,
        computeHealthSnapshot(entries, _settings, _today)!.score,
      );
      // 20 gece önce başlayan kayıtlar: ilk skor 3. kayıtlı gecede oluşur.
      expect(history[9].score, isNull); // 21 gece önce
      expect(history[11].score, isNull); // 19 gece önce: 2 kayıt
      expect(history[12].score, isNotNull); // 18 gece önce: 3 kayıt
    });

    test('ay geçişinde gün atlamaz', () {
      final history = healthScoreHistory(
        const [],
        _settings,
        DateTime(2026, 3, 2),
      );
      expect(history.last.night, DateTime(2026, 3));
      expect(history[history.length - 2].night, DateTime(2026, 2, 28));
    });
  });

  group('healthTips', () {
    HealthSnapshot snap({
      int debt = 0,
      double? regularity = 90,
      int? jetlag = 0,
      int average = 480,
    }) => HealthSnapshot(
      score: 80,
      debtMinutes: debt,
      regularity: regularity,
      socialJetlagMinutes: jetlag,
      components: const [],
      nights: 10,
      averageMinutes: average,
      goalMinutes: 480,
    );

    test('her şey iyi → ritmini koru + genel öneri', () {
      expect(healthTips(snap()), [HealthTip.keepGoing, HealthTip.windDown]);
    });

    test('borç, düzensizlik ve jetlag → üç öneri', () {
      expect(healthTips(snap(debt: 200, regularity: 50, jetlag: 90)), [
        HealthTip.payDebt,
        HealthTip.steadyBedtime,
        HealthTip.weekendShift,
      ]);
    });

    test('jetlag eşiği 60 dk', () {
      expect(
        healthTips(snap(jetlag: 59)),
        isNot(contains(HealthTip.weekendShift)),
      );
      expect(healthTips(snap(jetlag: 60)).first, HealthTip.weekendShift);
    });

    test('borç düşük ama ortalama kısa → süre önerisi', () {
      expect(healthTips(snap(average: 400)).first, HealthTip.moreSleep);
    });

    test('SRI yoksa düzenlilik önerisi verilmez', () {
      expect(
        healthTips(snap(regularity: null)),
        isNot(contains(HealthTip.steadyBedtime)),
      );
    });
  });
}
