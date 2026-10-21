import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/health/domain/health_snapshot.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

// Testçi turu: ISKELET.md §5 formüllerinin elle hesaplanmış bağımsız
// örnekleri. Beklenen değerler kodu çağırmadan, yorumdaki hesapla bulunur.

/// Çarşamba. 1 gece önce = 20 Ekim salı, 4 = 17 Ekim cumartesi,
/// 5 = 16 Ekim cuma.
final _today = DateTime(2026, 10, 21);

/// [today]'den [daysAgo] gece önceki akşam; yatış ve uyanış duvar saati
/// olarak verilir (yaz saati geçişinde de saatler aynı kalır).
SleepEntry _wall(
  DateTime today,
  int daysAgo, {
  required int bedHour,
  required int wakeHour,
  int bedMinute = 0,
  int wakeMinute = 0,
  WakeMood mood = WakeMood.normal,
}) {
  final night = addDays(dateOnly(today), -daysAgo);
  final bedDay = bedHour >= 24 ? addDays(night, 1) : night;
  final wakeDay = addDays(night, 1);
  return SleepEntry(
    id: nightKey(night),
    bedtime: DateTime(
      bedDay.year,
      bedDay.month,
      bedDay.day,
      bedHour % 24,
      bedMinute,
    ),
    wake: DateTime(
      wakeDay.year,
      wakeDay.month,
      wakeDay.day,
      wakeHour,
      wakeMinute,
    ),
    mood: mood,
  );
}

/// 23:00'te yatış, [minutes] uyku.
SleepEntry _night(
  int daysAgo, {
  int minutes = 480,
  WakeMood mood = WakeMood.normal,
}) {
  final night = addDays(_today, -daysAgo);
  final bed = DateTime(night.year, night.month, night.day, 23);
  return SleepEntry(
    id: nightKey(night),
    bedtime: bed,
    wake: bed.add(Duration(minutes: minutes)),
    mood: mood,
  );
}

void main() {
  group('sosyal jetlag: gece yarısı sarması', () {
    test('hafta içi 23:30 ve 00:30 karışık, hafta sonu 01:30 → 90 dk', () {
      // Hafta içi: 23:30–07:30 orta nokta 03:30, 00:30–08:30 orta 04:30;
      // ortalama 04:00. Hafta sonu 01:30–09:30 orta 05:30. Fark 90 dk.
      // (Saat-of-day ortalaması 23:30=1410 ile 00:30=30'u karıştırırdı.)
      final entries = [
        _wall(
          _today,
          1,
          bedHour: 23,
          bedMinute: 30,
          wakeHour: 7,
          wakeMinute: 30,
        ), // salı
        _wall(
          _today,
          2,
          bedHour: 24,
          bedMinute: 30,
          wakeHour: 8,
          wakeMinute: 30,
        ), // pazartesi
        _wall(
          _today,
          3,
          bedHour: 23,
          bedMinute: 30,
          wakeHour: 7,
          wakeMinute: 30,
        ), // pazar (hafta içi sayılır)
        _wall(
          _today,
          6,
          bedHour: 24,
          bedMinute: 30,
          wakeHour: 8,
          wakeMinute: 30,
        ), // perşembe
        _wall(
          _today,
          4,
          bedHour: 25,
          bedMinute: 30,
          wakeHour: 9,
          wakeMinute: 30,
        ), // cumartesi
        _wall(
          _today,
          5,
          bedHour: 25,
          bedMinute: 30,
          wakeHour: 9,
          wakeMinute: 30,
        ), // cuma
      ];
      expect(UserSettings.isWeekendNight(addDays(_today, -3)), isFalse);
      expect(computeSocialJetlag(entries), 90);
    });

    test('hafta sonu daha erken orta nokta → mutlak değer', () {
      // Hafta içi 00:30–08:30 (orta 04:30), hafta sonu 23:00–06:00
      // (orta 02:30) → 120 dk.
      final entries = [
        _wall(
          _today,
          1,
          bedHour: 24,
          bedMinute: 30,
          wakeHour: 8,
          wakeMinute: 30,
        ),
        _wall(
          _today,
          2,
          bedHour: 24,
          bedMinute: 30,
          wakeHour: 8,
          wakeMinute: 30,
        ),
        _wall(_today, 4, bedHour: 23, wakeHour: 6),
        _wall(_today, 5, bedHour: 23, wakeHour: 6),
      ];
      expect(computeSocialJetlag(entries), 120);
    });
  });

  group('SRI: gece yarısını aşan yatışlar', () {
    test('23:30 ve 00:30 dönüşümlü, 8 saat → 100 − 200·120/1440', () {
      // Her ardışık çiftte 23:30–00:30 ve 07:30–08:30 farklı: 120 dk.
      // p = 1320/1440, SRI = 200p − 100 = 83,33…
      final entries = [
        for (var d = 1; d <= 6; d++)
          _wall(
            _today,
            d,
            bedHour: d.isEven ? 23 : 24,
            bedMinute: 30,
            wakeHour: d.isEven ? 7 : 8,
            wakeMinute: 30,
          ),
      ];
      expect(computeRegularity(entries), closeTo(83.3333, 1e-3));
    });

    test('aradaki boş gece çifti böler: 7 kayıt ama 4 çift → null', () {
      // 1–3 ve 5–8 kayıtlı, 4 eksik: çiftler (1,2),(2,3),(5,6),(6,7),(7,8)
      // = 5 → değer; 8'i çıkarınca 4 → null.
      final five = [
        for (final d in [1, 2, 3, 5, 6, 7, 8]) _night(d),
      ];
      expect(computeRegularity(five), 100);
      final four = [
        for (final d in [1, 2, 3, 5, 6, 7]) _night(d),
      ];
      expect(computeRegularity(four), isNull);
    });
  });

  group('yaz saati geçişi içeren pencere', () {
    // Avrupa'da 25 Ekim 2026 ve 29 Mart 2026 pazar geçişleri. Saatler duvar
    // saatiyle aynı tutulur; sonuç saat diliminden bağımsız olmalı.
    for (final today in [DateTime(2026, 10, 27), DateTime(2026, 3, 31)]) {
      test('${nightKey(today)}: 14 gece eksiksiz sayılır, SRI 100', () {
        final entries = [
          for (var d = 1; d <= 16; d++)
            _wall(today, d, bedHour: 23, wakeHour: 7),
        ];
        final window = entriesInWindow(entries, today, 14);
        expect(window, hasLength(14));
        expect(window.first.id, nightKey(addDays(today, -14)));
        expect(window.last.id, nightKey(addDays(today, -1)));
        for (var i = 1; i < window.length; i++) {
          expect(
            window[i].id,
            nightKey(addDays(window[i - 1].night, 1)),
            reason: 'gün atlanmamalı/tekrarlanmamalı',
          );
        }
        expect(computeRegularity(window), 100);
        final s = computeHealthSnapshot(entries, const UserSettings(), today)!;
        expect(s.nights, 14);
        expect(s.regularity, 100);
      });

      test('${nightKey(today)}: skor geçmişi ardışık 30 gece', () {
        final history = healthScoreHistory(
          const [],
          const UserSettings(),
          today,
        );
        for (var i = 1; i < history.length; i++) {
          expect(
            nightKey(history[i].night),
            nightKey(addDays(history[i - 1].night, 1)),
          );
        }
      });
    }
  });

  group('hedef uçları', () {
    test('hedef 5 sa: %90 (270 dk) → süre 40, borç 90 dk → skor 84 İyi', () {
      // Gün aşırı 3 gece (çift yok → SRI null).
      // Süre 40; borç 3×30 = 90 → 20·(1 − 90/420) = 15,714;
      // uyanış normal 7,5. (40 + 15,714 + 7,5) / 75 · 100 = 84,29 → 84.
      final s = computeHealthSnapshot(
        [
          _night(1, minutes: 270),
          _night(3, minutes: 270),
          _night(5, minutes: 270),
        ],
        const UserSettings(goalMinutes: UserSettings.minGoal),
        _today,
      )!;
      expect(s.regularity, isNull);
      expect(s.debtMinutes, 90);
      expect(s.component(HealthComponentKind.duration)!.points, 40);
      expect(s.component(HealthComponentKind.debt)!.points, 16);
      expect(s.score, 84);
      expect(s.band, HealthBand.good);
    });

    test('hedef 11 sa: 8 saat uyku → skor 17 Geliştirilebilir', () {
      // Oran 480/660 = 0,7273 → (0,0273/0,2)·40 = 5,4545; borç 3×180 = 540
      // ≥ 420 → 0; uyanış 7,5. (5,4545 + 0 + 7,5) / 75 · 100 = 17,27 → 17.
      final s = computeHealthSnapshot(
        [_night(1), _night(3), _night(5)],
        const UserSettings(goalMinutes: UserSettings.maxGoal),
        _today,
      )!;
      expect(s.debtMinutes, 540);
      expect(s.component(HealthComponentKind.duration)!.points, 5);
      expect(s.component(HealthComponentKind.debt)!.points, 0);
      expect(s.score, 17);
      expect(s.band, HealthBand.needsWork);
    });

    test('hedef 11 sa: %90 (594 dk) → süre tam puan', () {
      final s = computeHealthSnapshot(
        [
          _night(1, minutes: 594),
          _night(3, minutes: 594),
          _night(5, minutes: 594),
        ],
        const UserSettings(goalMinutes: UserSettings.maxGoal),
        _today,
      )!;
      expect(s.component(HealthComponentKind.duration)!.points, 40);
      // Borç 3×66 = 198 → 20·(1 − 198/420) = 10,57 → 11.
      expect(s.debtMinutes, 198);
      expect(s.component(HealthComponentKind.debt)!.points, 11);
    });
  });

  group('SRI dahil tam skor', () {
    test('düzenlilik 83,3, hep "dinç" → 92', () {
      // 6 ardışık gece, 23:00 / 00:00 dönüşümlü 8 saat: SRI 83,33 → 20,83.
      // Süre 40, borç 20, uyanış 3/4·15 = 11,25. Toplam 92,08 → 92.
      final entries = [
        for (var d = 1; d <= 6; d++)
          _wall(
            _today,
            d,
            bedHour: d.isEven ? 23 : 24,
            wakeHour: d.isEven ? 7 : 8,
            mood: WakeMood.refreshed,
          ),
      ];
      final s = computeHealthSnapshot(entries, const UserSettings(), _today)!;
      expect(s.regularity, closeTo(83.3333, 1e-3));
      expect(s.components, const [
        HealthComponent(
          kind: HealthComponentKind.duration,
          points: 40,
          max: 40,
        ),
        HealthComponent(
          kind: HealthComponentKind.regularity,
          points: 21,
          max: 25,
        ),
        HealthComponent(kind: HealthComponentKind.debt, points: 20, max: 20),
        HealthComponent(kind: HealthComponentKind.mood, points: 11, max: 15),
      ]);
      expect(s.score, 92);
    });
  });

  group('borç geri ödemesi', () {
    test('300 dk borç, sonra +200 (tavan 60) ve +30 → 210', () {
      final entries = [
        _night(3, minutes: 180), // +300
        _night(2, minutes: 680), // −60 (200 fazla)
        _night(1, minutes: 510), // −30
      ];
      expect(computeSleepDebt(entries, 480), 210);
    });

    test('tam hedef gece borcu değiştirmez', () {
      expect(computeSleepDebt([_night(2, minutes: 400), _night(1)], 480), 80);
    });
  });

  group('aynı gece iki kayıt olmaz', () {
    test(
      'aynı geceyi yeniden kaydetmek üzerine yazar; skor 1 gece sayar',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo = LocalSleepRepository(
          await SharedPreferences.getInstance(),
        );
        await repo.saveAll([_night(1), _night(2), _night(3)]);
        // 20 Ekim gecesinin ikinci kaydı (daha kısa) öncekinin yerine geçer.
        await repo.save(_night(1, minutes: 300));
        final all = await repo.fetchAll();
        expect(all, hasLength(3));
        expect(
          all.where((e) => e.id == nightKey(addDays(_today, -1))),
          hasLength(1),
        );
        final s = computeHealthSnapshot(all, const UserSettings(), _today)!;
        expect(s.nights, 3);
        // 480 − 300 = 180 borç; diğer iki gece tam.
        expect(s.debtMinutes, 180);
        // JSON'da da tek kayıt.
        final prefs = await SharedPreferences.getInstance();
        final raw =
            jsonDecode(prefs.getString(LocalSleepRepository.storageKey)!)
                as List<dynamic>;
        expect(raw, hasLength(3));
      },
    );
  });
}
