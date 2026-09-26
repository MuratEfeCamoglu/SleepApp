import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_stages.dart';

enum TrendRange { week, month, year }

/// Grafikteki bir bar: bir gece, bir hafta ya da bir ayın ortalaması.
@immutable
class TrendBar {
  const TrendBar({required this.start, required this.minutes, this.index = 0});

  /// Dönemin ilk gecesi.
  final DateTime start;

  /// Kayıtlı gecelerin ortalaması; kayıt yoksa null.
  final int? minutes;

  /// Aylık görünümde hafta sırası (1 tabanlı).
  final int index;

  SleepStages get stages => StageEstimator.estimate(minutes ?? 0);
}

@immutable
class TrendSeries {
  const TrendSeries({
    required this.range,
    required this.bars,
    required this.average,
    required this.previousAverage,
    required this.averageBedMinute,
    required this.averageWakeMinute,
  });

  final TrendRange range;
  final List<TrendBar> bars;
  final int? average;
  final int? previousAverage;
  final int? averageBedMinute;
  final int? averageWakeMinute;

  int? get delta => average == null || previousAverage == null
      ? null
      : average! - previousAverage!;

  bool get isEmpty => average == null;
}

/// Kayıtları seçilen aralığa göre özetler. `today` bugünün tarihidir; son
/// gece dünün akşamıdır.
abstract final class TrendAggregator {
  static TrendSeries build(
    List<SleepEntry> entries,
    TrendRange range,
    DateTime today,
  ) {
    final byNight = {for (final e in entries) nightKey(e.night): e};
    final lastNight = addDays(dateOnly(today), -1);

    List<SleepEntry> between(DateTime first, DateTime last) => [
      for (var d = first; !d.isAfter(last); d = addDays(d, 1))
        ?byNight[nightKey(d)],
    ];

    int? avg(List<SleepEntry> list) => list.isEmpty
        ? null
        : (list.fold<int>(0, (s, e) => s + e.durationMinutes) / list.length)
              .round();

    final List<TrendBar> bars;
    final List<SleepEntry> current;
    final List<SleepEntry> previous;
    switch (range) {
      case TrendRange.week:
        final first = addDays(lastNight, -6);
        bars = [
          for (var i = 0; i < 7; i++)
            TrendBar(
              start: addDays(first, i),
              minutes: byNight[nightKey(addDays(first, i))]?.durationMinutes,
            ),
        ];
        current = between(first, lastNight);
        previous = between(addDays(first, -7), addDays(first, -1));
      case TrendRange.month:
        final first = addDays(lastNight, -27);
        bars = [
          for (var w = 0; w < 4; w++)
            TrendBar(
              start: addDays(first, w * 7),
              index: w + 1,
              minutes: avg(
                between(addDays(first, w * 7), addDays(first, w * 7 + 6)),
              ),
            ),
        ];
        current = between(first, lastNight);
        previous = between(addDays(first, -28), addDays(first, -1));
      case TrendRange.year:
        final year = lastNight.year;
        bars = [
          for (var m = 1; m <= lastNight.month; m++)
            TrendBar(
              start: DateTime(year, m),
              minutes: avg(
                between(
                  DateTime(year, m),
                  _min(DateTime(year, m + 1, 0), lastNight),
                ),
              ),
            ),
        ];
        current = between(DateTime(year), lastNight);
        previous = between(
          DateTime(year - 1),
          DateTime(year - 1, lastNight.month, lastNight.day),
        );
    }

    return TrendSeries(
      range: range,
      bars: bars,
      average: avg(current),
      previousAverage: avg(previous),
      averageBedMinute: circularMean([
        for (final e in current) e.bedtime.hour * 60 + e.bedtime.minute,
      ]),
      averageWakeMinute: circularMean([
        for (final e in current) e.wake.hour * 60 + e.wake.minute,
      ]),
    );
  }

  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  /// Gece yarısını saran saatlerin ortalaması (23:50 ve 00:10 → 00:00).
  static int? circularMean(List<int> minutes) {
    if (minutes.isEmpty) return null;
    var x = 0.0;
    var y = 0.0;
    for (final m in minutes) {
      final a = m / 1440 * 2 * math.pi;
      x += math.cos(a);
      y += math.sin(a);
    }
    final angle = math.atan2(y, x);
    final value = (angle / (2 * math.pi) * 1440).round();
    return (value + 1440) % 1440;
  }
}
