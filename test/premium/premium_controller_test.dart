import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/premium/data/local_premium_repository.dart';
import 'package:uyku/features/premium/domain/premium_status.dart';
import 'package:uyku/features/premium/presentation/premium_providers.dart';

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final _now = DateTime(2026, 10, 21, 9, 30);

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(_FixedClock(_now)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('kayıt yoksa premium kapalı başlar', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    expect(container.read(premiumProvider), const PremiumStatus());
    expect(container.read(isPremiumProvider), isFalse);
  });

  test('activateDebug kilidi açar ve saat clockProvider’dan gelir', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    await container.read(premiumProvider.notifier).activateDebug();
    final status = container.read(premiumProvider);
    expect(status.active, isTrue);
    expect(status.source, PremiumSource.debug);
    expect(status.since, _now);
    expect(container.read(isPremiumProvider), isTrue);
  });

  test('activateDebug yeniden başlatmadan sonra kalıcıdır', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await _container();
    await first.read(premiumProvider.notifier).activateDebug();
    first.dispose();

    // Yeni container = uygulamanın yeniden açılması; aynı prefs örneği.
    final second = await _container();
    expect(second.read(isPremiumProvider), isTrue);
    expect(
      second.read(premiumProvider),
      PremiumStatus(active: true, since: _now, source: PremiumSource.debug),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(LocalPremiumRepository.storageKey), isNotNull);
  });

  test('deactivate kapatır ve kalıcıdır', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await _container();
    await first.read(premiumProvider.notifier).activateDebug();
    await first.read(premiumProvider.notifier).deactivate();
    expect(first.read(isPremiumProvider), isFalse);
    first.dispose();

    final second = await _container();
    expect(second.read(premiumProvider), const PremiumStatus());
  });

  test('kayıtlı premium açılışta okunur', () async {
    SharedPreferences.setMockInitialValues({
      LocalPremiumRepository.storageKey:
          '{"active":true,"since":"2026-01-02T00:00:00.000Z","source":"store"}',
    });
    final container = await _container();
    final status = container.read(premiumProvider);
    expect(status.active, isTrue);
    expect(status.source, PremiumSource.store);
    expect(status.since, DateTime.utc(2026, 1, 2));
  });

  test('isPremiumProvider durum değişince güncellenir', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _container();
    expect(container.read(isPremiumProvider), isFalse);
    await container.read(premiumProvider.notifier).activateDebug();
    expect(container.read(isPremiumProvider), isTrue);
    await container.read(premiumProvider.notifier).deactivate();
    expect(container.read(isPremiumProvider), isFalse);
  });
}
