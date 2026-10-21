import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/premium/data/local_premium_repository.dart';
import 'package:uyku/features/premium/domain/premium_repository.dart';
import 'package:uyku/features/premium/domain/premium_status.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => LocalPremiumRepository(ref.watch(sharedPreferencesProvider)),
);

/// Premium durumu; değişiklikte kaydeder.
final premiumProvider = NotifierProvider<PremiumController, PremiumStatus>(
  PremiumController.new,
);

/// Kilitli yüzeyler için kısa yol.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(premiumProvider.select((s) => s.active)),
);

class PremiumController extends Notifier<PremiumStatus> {
  @override
  PremiumStatus build() => ref.watch(premiumRepositoryProvider).load();

  Future<void> _update(PremiumStatus next) async {
    state = next;
    await ref.read(premiumRepositoryProvider).save(next);
  }

  /// Yalnızca geliştirici derlemesinde: mağaza olmadan kilidi açar.
  Future<void> activateDebug() async {
    if (!kDebugMode) return;
    await _update(
      PremiumStatus(
        active: true,
        since: ref.read(clockProvider).now(),
        source: PremiumSource.debug,
      ),
    );
  }

  /// Premium'u kapatır (geliştirici).
  Future<void> deactivate() => _update(const PremiumStatus());
}
