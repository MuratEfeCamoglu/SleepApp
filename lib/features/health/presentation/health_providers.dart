import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/health/data/local_health_check_repository.dart';
import 'package:uyku/features/health/domain/health_check.dart';
import 'package:uyku/features/health/domain/health_check_repository.dart';
import 'package:uyku/features/health/domain/health_snapshot.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// Son 14 geceye göre uyku sağlığı; 3'ten az kayıtta null.
final FutureProvider<HealthSnapshot?> healthSnapshotProvider =
    FutureProvider.autoDispose<HealthSnapshot?>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      return computeHealthSnapshot(
        entries,
        ref.watch(settingsControllerProvider),
        ref.watch(todayProvider),
      );
    });

/// Son 30 gecenin skor geçmişi (premium grafik).
final FutureProvider<List<HealthScorePoint>> healthHistoryProvider =
    FutureProvider.autoDispose<List<HealthScorePoint>>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      return healthScoreHistory(
        entries,
        ref.watch(settingsControllerProvider),
        ref.watch(todayProvider),
      );
    });

final healthCheckRepositoryProvider = Provider<HealthCheckRepository>(
  (ref) => LocalHealthCheckRepository(ref.watch(sharedPreferencesProvider)),
);

/// Son uyku sağlığı kontrolü; hiç yapılmadıysa null.
final healthCheckProvider =
    NotifierProvider<HealthCheckController, HealthCheckResult?>(
      HealthCheckController.new,
    );

class HealthCheckController extends Notifier<HealthCheckResult?> {
  @override
  HealthCheckResult? build() => ref.watch(healthCheckRepositoryProvider).load();

  /// Cevapları değerlendirir, saklar ve sonucu döndürür.
  Future<HealthCheckResult> submit(Map<HealthQuestion, int> answers) async {
    final result = HealthCheckResult.evaluate(
      answers,
      ref.read(clockProvider).now(),
    );
    state = result;
    await ref.read(healthCheckRepositoryProvider).save(result);
    return result;
  }
}
