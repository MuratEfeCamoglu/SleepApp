import 'package:uyku/features/health/domain/health_check.dart';

/// Son uyku sağlığı kontrolü sonucunun kaynağı.
abstract interface class HealthCheckRepository {
  /// Kayıt yoksa veya okunamıyorsa null.
  HealthCheckResult? load();

  Future<void> save(HealthCheckResult result);
}
