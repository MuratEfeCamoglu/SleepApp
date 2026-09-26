import 'package:flutter/foundation.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_quality.dart';
import 'package:uyku/features/trends/domain/trend_aggregator.dart';

/// Geçen haftanın özeti: pazar akşamından cumartesi akşamına 7 gece, yani
/// pazartesiden pazara 7 sabah. Pazar sabahı hazır olur.
@immutable
class WeeklyReport {
  const WeeklyReport({
    required this.firstNight,
    required this.lastNight,
    required this.entries,
    required this.goalMinutes,
    required this.average,
    required this.previousAverage,
    required this.goalNights,
    required this.goodNights,
    required this.averageBedMinute,
    required this.averageWakeMinute,
    required this.bedtimeSpread,
    required this.bestNight,
    required this.topFactor,
  });

  factory WeeklyReport.build(
    List<SleepEntry> all,
    int goalMinutes,
    DateTime today,
  ) {
    final (:first, :last) = weekFor(today);
    bool within(SleepEntry e, DateTime from, DateTime to) =>
        !e.night.isBefore(from) && !e.night.isAfter(to);

    final week = [
      for (final e in all)
        if (within(e, first, last)) e,
    ]..sort((a, b) => a.night.compareTo(b.night));
    final previous = [
      for (final e in all)
        if (within(e, addDays(first, -nightsInWeek), addDays(first, -1))) e,
    ];

    int? avg(List<SleepEntry> list) => list.isEmpty
        ? null
        : (list.fold<int>(0, (s, e) => s + e.durationMinutes) / list.length)
              .round();

    final bedMinutes = [
      for (final e in week) e.bedtime.hour * 60 + e.bedtime.minute,
    ];
    final averageBed = TrendAggregator.circularMean(bedMinutes);
    int? spread;
    if (averageBed != null) {
      final total = bedMinutes.fold<int>(0, (s, m) {
        final diff = ((m - averageBed + 720) % 1440 + 1440) % 1440 - 720;
        return s + diff.abs();
      });
      spread = (total / bedMinutes.length).round();
    }

    SleepEntry? best;
    var bestScore = -1;
    for (final e in week) {
      final score = QualityClassifier.score(e, goalMinutes);
      if (score > bestScore) {
        best = e;
        bestScore = score;
      }
    }

    ({SleepFactor factor, int nights})? top;
    for (final f in SleepFactor.values) {
      final n = week.where((e) => e.factors.contains(f)).length;
      if (n > 0 && (top == null || n > top.nights)) {
        top = (factor: f, nights: n);
      }
    }

    return WeeklyReport(
      firstNight: first,
      lastNight: last,
      entries: week,
      goalMinutes: goalMinutes,
      average: avg(week),
      previousAverage: avg(previous),
      goalNights: week.where((e) => e.durationMinutes >= goalMinutes).length,
      goodNights: week
          .where(
            (e) => QualityClassifier.isGood(
              QualityClassifier.classify(e, goalMinutes),
            ),
          )
          .length,
      averageBedMinute: averageBed,
      averageWakeMinute: TrendAggregator.circularMean([
        for (final e in week) e.wake.hour * 60 + e.wake.minute,
      ]),
      bedtimeSpread: spread,
      bestNight: best,
      topFactor: top,
    );
  }

  /// Haftanın ilk gecesi (pazar akşamı).
  final DateTime firstNight;

  /// Haftanın son gecesi (cumartesi akşamı).
  final DateTime lastNight;

  /// O haftanın kayıtları, geceye göre artan.
  final List<SleepEntry> entries;
  final int goalMinutes;
  final int? average;
  final int? previousAverage;

  /// Hedef süreye ulaşılan gece sayısı.
  final int goalNights;

  /// "İyi geçen gece" sayısı.
  final int goodNights;
  final int? averageBedMinute;
  final int? averageWakeMinute;

  /// Yatış saatinin ortalamadan ortalama sapması (dk).
  final int? bedtimeSpread;

  /// Kalite puanı en yüksek gece.
  final SleepEntry? bestNight;

  /// En sık işaretlenen etken ve gece sayısı.
  final ({SleepFactor factor, int nights})? topFactor;

  static const nightsInWeek = 7;

  int get nights => entries.length;

  bool get isEmpty => entries.isEmpty;

  /// İlk ve son sabah (uyanış günleri): pazartesi ve pazar.
  DateTime get firstMorning => addDays(firstNight, 1);
  DateTime get lastMorning => addDays(lastNight, 1);

  int? get delta => average == null || previousAverage == null
      ? null
      : average! - previousAverage!;

  /// [today] için en son tamamlanan hafta. Pazar günü o sabah biten hafta;
  /// diğer günlerde bir önceki pazar biten hafta.
  static ({DateTime first, DateTime last}) weekFor(DateTime today) {
    final day = dateOnly(today);
    final sunday = addDays(day, -(day.weekday % 7));
    final last = addDays(sunday, -1);
    return (first: addDays(last, -(nightsInWeek - 1)), last: last);
  }
}
