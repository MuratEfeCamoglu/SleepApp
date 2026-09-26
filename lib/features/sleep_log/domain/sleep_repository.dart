import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Uyku kayıtlarının kaynağı. Şimdilik cihazda; ileride HealthKit / Health
/// Connect aynı arayüzle eklenir ve provider override ile değiştirilir.
abstract interface class SleepRepository {
  /// Tüm kayıtlar, geceye göre artan sırada.
  Future<List<SleepEntry>> fetchAll();

  /// Aynı [SleepEntry.id]'ye sahip kaydın üzerine yazar.
  Future<void> save(SleepEntry entry);

  Future<void> saveAll(List<SleepEntry> entries);

  Future<void> delete(String id);

  Future<void> clear();
}
