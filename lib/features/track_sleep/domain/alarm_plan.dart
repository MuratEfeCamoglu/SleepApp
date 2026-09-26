import 'package:flutter/foundation.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Uyku modu başlarken kurulan alarm.
///
/// Akıllı alarm hafif uykuyu ölçmez: uykuya dalmaya [fallAsleepMinutes] ve
/// her döngüye [cycleMinutes] varsayarak pencere içindeki son döngü sonunu
/// tahmin eder. Döngü sonu pencereye düşmüyorsa pencerenin sonunda çalar.
@immutable
class AlarmPlan {
  const AlarmPlan({
    required this.windowStart,
    required this.windowEnd,
    required this.at,
    required this.smart,
  });

  /// [start]'ta başlayan uyku için alarm planı.
  factory AlarmPlan.forStart(UserSettings settings, DateTime start) {
    final windowEnd = nextOccurrence(
      start,
      settings.wakeFor(nightOfBedtime(start)),
    );
    final windowStart = windowEnd.subtract(
      const Duration(minutes: UserSettings.alarmWindow),
    );
    final smartAt = settings.smartAlarm
        ? cycleEndWithin(start, windowStart, windowEnd)
        : null;
    return AlarmPlan(
      windowStart: windowStart,
      windowEnd: windowEnd,
      at: smartAt ?? windowEnd,
      smart: smartAt != null,
    );
  }

  static const fallAsleepMinutes = 15;
  static const cycleMinutes = 90;

  final DateTime windowStart;
  final DateTime windowEnd;

  /// Alarmın çalacağı an.
  final DateTime at;

  /// [at] tahmini döngü sonu mu (yoksa pencerenin sonu mu)?
  final bool smart;

  /// Pencere içindeki son tahmini döngü sonu; yoksa null.
  static DateTime? cycleEndWithin(
    DateTime start,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final asleep = start.add(const Duration(minutes: fallAsleepMinutes));
    if (!windowEnd.isAfter(asleep)) return null;
    final cycles = windowEnd.difference(asleep).inMinutes ~/ cycleMinutes;
    if (cycles == 0) return null;
    final end = asleep.add(Duration(minutes: cycles * cycleMinutes));
    return end.isBefore(windowStart) ? null : end;
  }
}

/// Yatışın ait olduğu gece: öğleden önceki yatışlar bir önceki akşama sayılır.
DateTime nightOfBedtime(DateTime start) {
  final day = dateOnly(start);
  return start.hour < 12 ? addDays(day, -1) : day;
}

/// [minute] (gece yarısından dk) saatinin [from]'dan sonraki ilk oluşumu.
DateTime nextOccurrence(DateTime from, int minute) {
  var at = DateTime(from.year, from.month, from.day, minute ~/ 60, minute % 60);
  if (!at.isAfter(from)) {
    at = DateTime(at.year, at.month, at.day + 1, at.hour, at.minute);
  }
  return at;
}
