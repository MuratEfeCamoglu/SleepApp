import 'package:flutter/foundation.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_quality.dart';

/// Son [windowNights] gecenin kalite gruplarına dağılımı.
@immutable
class QualityDistribution {
  const QualityDistribution(this.counts);

  factory QualityDistribution.fromEntries(
    List<SleepEntry> entries,
    int goalMinutes,
    DateTime today,
  ) {
    final lastNight = addDays(dateOnly(today), -1);
    final first = addDays(lastNight, -(windowNights - 1));
    final counts = {for (final c in QualityCategory.values) c: 0};
    for (final e in entries) {
      final night = e.night;
      if (night.isBefore(first) || night.isAfter(lastNight)) continue;
      final c = QualityClassifier.classify(e, goalMinutes);
      counts[c] = counts[c]! + 1;
    }
    return QualityDistribution(counts);
  }

  static const windowNights = 30;

  /// Her grup için gece sayısı ([QualityCategory] sırasıyla).
  final Map<QualityCategory, int> counts;

  int get total => counts.values.fold(0, (a, b) => a + b);

  bool get isEmpty => total == 0;

  int countOf(QualityCategory c) => counts[c] ?? 0;

  int percentOf(QualityCategory c) =>
      total == 0 ? 0 : (countOf(c) * 100 / total).round();

  int get goodPercent => total == 0
      ? 0
      : (QualityCategory.values
                    .where(QualityClassifier.isGood)
                    .fold<int>(0, (s, c) => s + countOf(c)) *
                100 /
                total)
            .round();
}
