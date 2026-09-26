import 'package:flutter/foundation.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_quality.dart';

/// Rozetler; sıra ekrandaki sıradır.
enum SleepBadge {
  firstNight(1),
  streak3(3),
  streak7(7),
  streak14(14),
  streak30(30),
  nights10(10),
  nights50(50),
  nights100(100),
  restful5(5),
  steady7(7),
  dreamer5(5);

  const SleepBadge(this.target);

  final int target;
}

@immutable
class BadgeProgress {
  const BadgeProgress(this.badge, this.progress);

  final SleepBadge badge;
  final int progress;

  bool get earned => progress >= badge.target;
}

@immutable
class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.best,
    required this.badges,
  });

  /// Son geceden geriye hedefe ulaşılan ardışık gece sayısı.
  final int current;

  /// Tüm kayıtlar içindeki en uzun seri.
  final int best;
  final List<BadgeProgress> badges;

  Iterable<BadgeProgress> get earned => badges.where((b) => b.earned);
}

abstract final class Streaks {
  /// Yatış hedefe bu kadar dakika yakınsa "düzenli" sayılır.
  static const steadyTolerance = 30;

  static bool metGoal(SleepEntry e, int goalMinutes) =>
      e.durationMinutes >= goalMinutes;

  /// [today] için özet. Dün gecenin kaydı henüz yoksa seri bir önceki
  /// geceden sayılır; gün bitmeden seri bozulmuş görünmez.
  static StreakSummary compute(
    List<SleepEntry> entries,
    UserSettings settings,
    DateTime today,
  ) {
    final goal = settings.goalMinutes;
    final byNight = {for (final e in entries) nightKey(e.night): e};

    var night = addDays(dateOnly(today), -1);
    if (!byNight.containsKey(nightKey(night))) night = addDays(night, -1);
    var current = 0;
    while (true) {
      final e = byNight[nightKey(night)];
      if (e == null || !metGoal(e, goal)) break;
      current++;
      night = addDays(night, -1);
    }

    final sorted = [...entries]..sort((a, b) => a.night.compareTo(b.night));
    final best = _longestRun(sorted, (e) => metGoal(e, goal));
    final steady = _longestRun(sorted, (e) {
      final bed = e.bedtime.hour * 60 + e.bedtime.minute;
      final target = settings.bedtimeFor(e.night);
      final diff = ((bed - target + 720) % 1440 + 1440) % 1440 - 720;
      return diff.abs() <= steadyTolerance;
    });
    final restful = entries
        .where(
          (e) =>
              QualityClassifier.classify(e, goal) ==
              QualityCategory.restorative,
        )
        .length;
    final notes = entries.where((e) => e.note.isNotEmpty).length;

    int progressOf(SleepBadge b) => switch (b) {
      SleepBadge.firstNight ||
      SleepBadge.nights10 ||
      SleepBadge.nights50 ||
      SleepBadge.nights100 => entries.length,
      SleepBadge.streak3 ||
      SleepBadge.streak7 ||
      SleepBadge.streak14 ||
      SleepBadge.streak30 => best,
      SleepBadge.restful5 => restful,
      SleepBadge.steady7 => steady,
      SleepBadge.dreamer5 => notes,
    };

    return StreakSummary(
      current: current,
      best: best,
      badges: [
        for (final b in SleepBadge.values) BadgeProgress(b, progressOf(b)),
      ],
    );
  }

  /// Takvimde ardışık ve [test]'i sağlayan en uzun gece dizisi.
  static int _longestRun(
    List<SleepEntry> sorted,
    bool Function(SleepEntry) test,
  ) {
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final e in sorted) {
      final consecutive = previous != null && addDays(previous, 1) == e.night;
      if (!test(e)) {
        run = 0;
      } else {
        run = consecutive ? run + 1 : 1;
        if (run > best) best = run;
      }
      previous = e.night;
    }
    return best;
  }
}
