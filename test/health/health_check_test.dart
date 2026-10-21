import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/health/domain/health_check.dart';

Map<HealthQuestion, int> _all(int value) => {
  for (final q in HealthQuestion.values) q: value,
};

void main() {
  group('evaluateHealthCheck', () {
    test('6 soru tanımlı', () {
      expect(HealthQuestion.values, hasLength(6));
    });

    test('hepsi 0 → bayrak yok', () {
      expect(evaluateHealthCheck(_all(0)), isEmpty);
    });

    test('hepsi 1 → bayrak yok (dalma + uyanma = 2)', () {
      expect(evaluateHealthCheck(_all(1)), isEmpty);
    });

    test('hepsi 3 → dört bayrak, sabit sırada', () {
      expect(evaluateHealthCheck(_all(3)), [
        HealthFlag.breathing,
        HealthFlag.daytimeSleepiness,
        HealthFlag.insomniaSymptoms,
        HealthFlag.restlessLegs,
      ]);
    });

    test('nefes: 1 → yok, 2 → var', () {
      expect(
        evaluateHealthCheck({..._all(0), HealthQuestion.breathing: 1}),
        isEmpty,
      );
      expect(evaluateHealthCheck({..._all(0), HealthQuestion.breathing: 2}), [
        HealthFlag.breathing,
      ]);
    });

    test('gün içi uyuklama: 1 → yok, 2 → var', () {
      expect(
        evaluateHealthCheck({..._all(0), HealthQuestion.daytimeSleepiness: 1}),
        isEmpty,
      );
      expect(
        evaluateHealthCheck({..._all(0), HealthQuestion.daytimeSleepiness: 2}),
        [HealthFlag.daytimeSleepiness],
      );
    });

    test('dalma + gece uyanma: toplam 3 → yok, 4 → var', () {
      expect(
        evaluateHealthCheck({
          ..._all(0),
          HealthQuestion.fallingAsleep: 2,
          HealthQuestion.nightWaking: 1,
        }),
        isEmpty,
      );
      expect(
        evaluateHealthCheck({
          ..._all(0),
          HealthQuestion.fallingAsleep: 3,
          HealthQuestion.nightWaking: 0,
        }),
        isEmpty,
      );
      expect(
        evaluateHealthCheck({
          ..._all(0),
          HealthQuestion.fallingAsleep: 2,
          HealthQuestion.nightWaking: 2,
        }),
        [HealthFlag.insomniaSymptoms],
      );
      expect(
        evaluateHealthCheck({
          ..._all(0),
          HealthQuestion.fallingAsleep: 1,
          HealthQuestion.nightWaking: 3,
        }),
        [HealthFlag.insomniaSymptoms],
      );
    });

    test('bacak huzursuzluğu: 1 → yok, 2 → var', () {
      expect(
        evaluateHealthCheck({..._all(0), HealthQuestion.restlessLegs: 1}),
        isEmpty,
      );
      expect(
        evaluateHealthCheck({..._all(0), HealthQuestion.restlessLegs: 2}),
        [HealthFlag.restlessLegs],
      );
    });

    test('sabah yorgunluğu tek başına bayrak üretmez', () {
      expect(
        evaluateHealthCheck({..._all(0), HealthQuestion.morningTired: 3}),
        isEmpty,
      );
    });

    test('cevaplanmamış soru 0 sayılır', () {
      expect(evaluateHealthCheck(const {}), isEmpty);
      expect(evaluateHealthCheck(const {HealthQuestion.restlessLegs: 3}), [
        HealthFlag.restlessLegs,
      ]);
    });
  });

  group('HealthCheckResult JSON', () {
    final taken = DateTime(2026, 10, 21, 9, 30);

    test('evaluate bayrakları hesaplar', () {
      final r = HealthCheckResult.evaluate({
        ..._all(0),
        HealthQuestion.breathing: 3,
      }, taken);
      expect(r.flags, [HealthFlag.breathing]);
      expect(r.hasFlags, isTrue);
      expect(r.takenAt, taken);
    });

    test('gidiş-dönüş', () {
      final r = HealthCheckResult.evaluate(_all(2), taken);
      expect(HealthCheckResult.fromJson(r.toJson()), r);
    });

    test('bayraksız sonuç gidiş-dönüş', () {
      final r = HealthCheckResult.evaluate(_all(0), taken);
      final back = HealthCheckResult.fromJson(r.toJson());
      expect(back, r);
      expect(back.hasFlags, isFalse);
    });

    test('bilinmeyen soru ve bayrak adları atlanır', () {
      final r = HealthCheckResult.fromJson(const {
        'answers': {'breathing': 2, 'eskiSoru': 1},
        'flags': ['breathing', 'eskiBayrak'],
        'takenAt': '2026-10-21T09:30:00.000',
      });
      expect(r.answers, {HealthQuestion.breathing: 2});
      expect(r.flags, [HealthFlag.breathing]);
    });

    test('yanlış tipli alanlar FormatException fırlatır', () {
      final bad = <Map<String, dynamic>>[
        {'answers': 'x', 'flags': <String>[], 'takenAt': '2026-10-21'},
        {
          'answers': {'breathing': '2'},
          'flags': <String>[],
          'takenAt': '2026-10-21',
        },
        {
          'answers': {'breathing': 7},
          'flags': <String>[],
          'takenAt': '2026-10-21',
        },
        {'answers': <String, dynamic>{}, 'flags': 'x', 'takenAt': '2026-10-21'},
        {'answers': <String, dynamic>{}, 'flags': <String>[], 'takenAt': 5},
        {'answers': <String, dynamic>{}, 'flags': <String>[], 'takenAt': 'dün'},
      ];
      for (final json in bad) {
        expect(
          () => HealthCheckResult.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });
  });
}
