import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Kalite ekranındaki 5 grup, iyiden kötüye (fan grafiği sırası).
enum QualityCategory { restorative, good, fair, fragmented, sleepless }

/// Bir geceyi süre, uyanış hissi ve etkenlere göre sınıflar.
abstract final class QualityClassifier {
  /// Bu sürenin altı "Uykusuz" sayılır.
  static const int sleeplessBelow = 5 * 60;

  /// 0–100 puan: süre (60) + uyanış hissi (40) − olumsuz etkenler.
  static int score(SleepEntry entry, int goalMinutes) {
    final ratio = goalMinutes <= 0
        ? 1.0
        : (entry.durationMinutes / goalMinutes).clamp(0.0, 1.0);
    final disruptive = entry.factors.where((f) => f.isDisruptive).length;
    final exercise = entry.factors.contains(SleepFactor.exercise) ? 4 : 0;
    final value =
        60 * ratio + entry.mood.index * 10 - disruptive * 4 + exercise;
    return value.round().clamp(0, 100);
  }

  static QualityCategory classify(SleepEntry entry, int goalMinutes) {
    if (entry.durationMinutes < sleeplessBelow) {
      return QualityCategory.sleepless;
    }
    final interrupted =
        entry.mood == WakeMood.exhausted ||
        entry.factors.contains(SleepFactor.noise) ||
        entry.factors.contains(SleepFactor.alcohol);
    if (interrupted) return QualityCategory.fragmented;
    final s = score(entry, goalMinutes);
    if (s >= 85) return QualityCategory.restorative;
    if (s >= 70) return QualityCategory.good;
    return QualityCategory.fair;
  }

  /// "İyi geçen gece" sayılan gruplar.
  static bool isGood(QualityCategory category) =>
      category == QualityCategory.restorative ||
      category == QualityCategory.good;
}
