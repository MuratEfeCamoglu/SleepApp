import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/health/data/local_health_check_repository.dart';
import 'package:uyku/features/health/domain/health_check.dart';
import 'package:uyku/features/health/presentation/health_providers.dart';

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final _now = DateTime(2026, 10, 21, 9, 30);

Future<LocalHealthCheckRepository> _repo(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalHealthCheckRepository(await SharedPreferences.getInstance());
}

void main() {
  group('LocalHealthCheckRepository', () {
    test('kayıt yoksa null', () async {
      expect((await _repo({})).load(), isNull);
    });

    test('kaydedilen sonuç health.check.v1 anahtarından okunur', () async {
      final repo = await _repo({});
      final result = HealthCheckResult.evaluate({
        for (final q in HealthQuestion.values) q: 2,
      }, _now);
      await repo.save(result);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('health.check.v1'), isNotNull);
      expect(LocalHealthCheckRepository(prefs).load(), result);
    });

    test('bozuk JSON → null', () async {
      expect((await _repo({'health.check.v1': '{bozuk'})).load(), isNull);
    });

    test('nesne olmayan JSON → null', () async {
      expect((await _repo({'health.check.v1': '[1,2]'})).load(), isNull);
    });

    test('yanlış tipli cevap → null', () async {
      final repo = await _repo({
        'health.check.v1':
            '{"answers":{"breathing":"çok"},"flags":[],'
            '"takenAt":"2026-10-21T09:30:00.000"}',
      });
      expect(repo.load(), isNull);
    });

    test('aralık dışı cevap → null', () async {
      final repo = await _repo({
        'health.check.v1':
            '{"answers":{"breathing":9},"flags":[],'
            '"takenAt":"2026-10-21T09:30:00.000"}',
      });
      expect(repo.load(), isNull);
    });

    test('eksik alan → null', () async {
      expect(
        (await _repo({'health.check.v1': '{"answers":{}}'})).load(),
        isNull,
      );
    });

    test('bozuk tarih → null', () async {
      final repo = await _repo({
        'health.check.v1': '{"answers":{},"flags":[],"takenAt":"dün"}',
      });
      expect(repo.load(), isNull);
    });
  });

  group('healthCheckProvider', () {
    Future<ProviderContainer> container() async {
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

    test(
      'submit sonucu hesaplar, saati clockProvider’dan alır, saklar',
      () async {
        SharedPreferences.setMockInitialValues({});
        final first = await container();
        expect(first.read(healthCheckProvider), isNull);
        final result = await first.read(healthCheckProvider.notifier).submit({
          for (final q in HealthQuestion.values) q: 0,
          HealthQuestion.daytimeSleepiness: 3,
        });
        expect(result.flags, [HealthFlag.daytimeSleepiness]);
        expect(result.takenAt, _now);
        expect(first.read(healthCheckProvider), result);
        first.dispose();

        final second = await container();
        expect(second.read(healthCheckProvider), result);
      },
    );
  });
}
