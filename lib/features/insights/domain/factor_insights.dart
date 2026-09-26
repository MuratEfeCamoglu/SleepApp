import 'package:flutter/foundation.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_quality.dart';

/// Bir etkenin işaretlendiği ve işaretlenmediği gecelerin karşılaştırması.
///
/// Evreler süreden tahmin edildiği için karşılaştırma ölçülen değerler
/// üzerinden yapılır: uyku süresi ve "iyi geçen gece" oranı.
@immutable
class FactorInsight {
  const FactorInsight({
    required this.factor,
    required this.nightsWith,
    required this.nightsWithout,
    required this.averageWith,
    required this.averageWithout,
    required this.goodRateWith,
    required this.goodRateWithout,
  });

  final SleepFactor factor;
  final int nightsWith;
  final int nightsWithout;

  /// Ortalama uyku süresi (dk).
  final int averageWith;
  final int averageWithout;

  /// İyi geçen gece oranı, 0–1.
  final double goodRateWith;
  final double goodRateWithout;

  /// Etkenli − etkensiz ortalama süre (dk).
  int get durationDelta => averageWith - averageWithout;

  /// Etkenli − etkensiz iyi gece oranı (yüzde puan).
  int get goodRateDelta => ((goodRateWith - goodRateWithout) * 100).round();
}

/// Henüz yeterli gecesi olmayan etken.
typedef FactorProgress = ({SleepFactor factor, int nights});

@immutable
class FactorAnalysis {
  const FactorAnalysis({required this.insights, required this.pending});

  /// Etkisi büyükten küçüğe.
  final List<FactorInsight> insights;

  /// En az bir kez işaretlenmiş ama karşılaştırma için az gecesi olanlar.
  final List<FactorProgress> pending;

  bool get isEmpty => insights.isEmpty;
}

abstract final class FactorAnalyzer {
  /// Bu kadar geriye bakılır.
  static const windowNights = 60;

  /// Hem etkenli hem etkensiz tarafta en az bu kadar gece gerekir.
  static const minNights = 3;

  /// Bu kadar dakikadan küçük fark "değişmedi" sayılır.
  static const noticeableMinutes = 10;

  static FactorAnalysis analyze(
    List<SleepEntry> entries,
    int goalMinutes,
    DateTime today,
  ) {
    final lastNight = addDays(dateOnly(today), -1);
    final first = addDays(lastNight, -(windowNights - 1));
    final window = [
      for (final e in entries)
        if (!e.night.isBefore(first) && !e.night.isAfter(lastNight)) e,
    ];

    int avg(List<SleepEntry> list) =>
        (list.fold<int>(0, (s, e) => s + e.durationMinutes) / list.length)
            .round();
    double goodRate(List<SleepEntry> list) =>
        list
            .where(
              (e) => QualityClassifier.isGood(
                QualityClassifier.classify(e, goalMinutes),
              ),
            )
            .length /
        list.length;

    final insights = <FactorInsight>[];
    final pending = <FactorProgress>[];
    for (final factor in SleepFactor.values) {
      final withF = [
        for (final e in window)
          if (e.factors.contains(factor)) e,
      ];
      final withoutF = [
        for (final e in window)
          if (!e.factors.contains(factor)) e,
      ];
      if (withF.length < minNights || withoutF.length < minNights) {
        if (withF.isNotEmpty) {
          pending.add((factor: factor, nights: withF.length));
        }
        continue;
      }
      insights.add(
        FactorInsight(
          factor: factor,
          nightsWith: withF.length,
          nightsWithout: withoutF.length,
          averageWith: avg(withF),
          averageWithout: avg(withoutF),
          goodRateWith: goodRate(withF),
          goodRateWithout: goodRate(withoutF),
        ),
      );
    }
    insights.sort(
      (a, b) => b.durationDelta.abs().compareTo(a.durationDelta.abs()),
    );
    pending.sort((a, b) => b.nights.compareTo(a.nights));
    return FactorAnalysis(insights: insights, pending: pending);
  }
}
