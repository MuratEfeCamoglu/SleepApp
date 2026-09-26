import 'package:flutter/foundation.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_stages.dart';
import 'package:uyku/features/trends/domain/trend_aggregator.dart';

/// Bu geceki öneri türü.
enum BedtimeTip {
  /// Dün gece hedeften geç yatıldı.
  earlier,

  /// Dün gece hedeften erken yatıldı.
  later,

  /// Dün gece hedefe yakın yatıldı.
  onTrack,

  /// Karşılaştırılacak kayıt yok.
  noData,
}

/// Bugün ekranının ihtiyaç duyduğu her şey.
@immutable
class TodaySummary {
  const TodaySummary({
    required this.entry,
    required this.isLastNight,
    required this.stages,
    required this.goalMinutes,
    required this.weekDelta,
    required this.tip,
    required this.tipMinutes,
  });

  factory TodaySummary.fromEntries({
    required List<SleepEntry> entries,
    required int goalMinutes,

    /// Gecenin hedef yatışı (hafta sonu esnekliği dahil).
    required int Function(DateTime night) targetBedFor,
    required DateTime today,
  }) {
    final lastNight = addDays(dateOnly(today), -1);
    final oldest = addDays(lastNight, -(recentNights - 1));
    SleepEntry? entry;
    for (final e in entries.reversed) {
      final n = e.night;
      if (!n.isAfter(lastNight) && !n.isBefore(oldest)) {
        entry = e;
        break;
      }
    }
    final week = TrendAggregator.build(entries, TrendRange.week, today);

    var tip = BedtimeTip.noData;
    var tipMinutes = 0;
    if (entry != null) {
      final bed = entry.bedtime.hour * 60 + entry.bedtime.minute;
      // Gece yarısını saran fark: −720…720.
      final target = targetBedFor(entry.night);
      final diff = ((bed - target + 720) % 1440 + 1440) % 1440 - 720;
      tipMinutes = diff.abs();
      tip = diff > onTrackTolerance
          ? BedtimeTip.earlier
          : diff < -onTrackTolerance
          ? BedtimeTip.later
          : BedtimeTip.onTrack;
    }

    return TodaySummary(
      entry: entry,
      isLastNight: entry != null && entry.night == lastNight,
      stages: StageEstimator.estimate(entry?.durationMinutes ?? 0),
      goalMinutes: goalMinutes,
      weekDelta: week.delta,
      tip: tip,
      tipMinutes: tipMinutes,
    );
  }

  /// Gösterilen gece; hiç yakın kayıt yoksa null.
  final SleepEntry? entry;

  /// [entry] dün geceye mi ait?
  final bool isLastNight;
  final SleepStages stages;
  final int goalMinutes;

  /// Son 7 gecenin ortalaması − önceki 7 gecenin ortalaması (dk).
  final int? weekDelta;
  final BedtimeTip tip;

  /// Önerideki dakika farkı (mutlak).
  final int tipMinutes;

  bool get isEmpty => entry == null;

  /// Halka oranları: toplam/hedef, REM/REM hedefi, derin/derin hedefi.
  double get totalRatio => goalMinutes == 0 ? 0 : stages.total / goalMinutes;
  double get remRatio =>
      stages.rem / (goalMinutes * StageEstimator.remTargetShare);
  double get deepRatio =>
      stages.deep / (goalMinutes * StageEstimator.deepTargetShare);

  /// Bu kadar dakikalık sapma "yolunda" sayılır.
  static const onTrackTolerance = 5;

  /// En yeni kayıt bu kadar geceden eskiyse gösterilmez.
  static const recentNights = 7;
}
