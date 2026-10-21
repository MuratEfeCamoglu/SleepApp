import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Uyku sağlığı skorunun bileşenleri (ISKELET.md §5).
enum HealthComponentKind { duration, regularity, debt, mood }

/// Skor bantları: 85+ çok iyi, 70–84 iyi, 50–69 orta, <50 geliştirilebilir.
enum HealthBand {
  veryGood,
  good,
  fair,
  needsWork;

  static HealthBand of(int score) {
    if (score >= 85) return veryGood;
    if (score >= 70) return good;
    if (score >= 50) return fair;
    return needsWork;
  }
}

/// Bir bileşenin aldığı puan ve en yüksek puanı.
@immutable
class HealthComponent {
  const HealthComponent({
    required this.kind,
    required this.points,
    required this.max,
  });

  final HealthComponentKind kind;
  final int points;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is HealthComponent &&
      other.kind == kind &&
      other.points == points &&
      other.max == max;

  @override
  int get hashCode => Object.hash(kind, points, max);

  @override
  String toString() => 'HealthComponent($kind, $points/$max)';
}

/// Son gecelerden türetilen uyku sağlığı özeti; saklanmaz.
@immutable
class HealthSnapshot {
  const HealthSnapshot({
    required this.score,
    required this.debtMinutes,
    required this.regularity,
    required this.socialJetlagMinutes,
    required this.components,
    required this.nights,
    required this.averageMinutes,
    required this.goalMinutes,
  });

  /// 0–100.
  final int score;

  /// Son 14 gecenin uyku borcu (dk).
  final int debtMinutes;

  /// Uyku düzenlilik indeksi, 0–100'e kırpılmış; az veride null.
  final double? regularity;

  /// Hafta sonu ve hafta içi uyku orta noktası farkı (dk); az veride null.
  final int? socialJetlagMinutes;

  /// Skoru oluşturan bileşenler. Düzenlilik hesaplanamadıysa listede yoktur.
  final List<HealthComponent> components;

  /// Skor penceresindeki (14 gece) kayıt sayısı.
  final int nights;

  /// Skor penceresindeki ortalama süre (dk).
  final int averageMinutes;
  final int goalMinutes;

  HealthBand get band => HealthBand.of(score);

  HealthComponent? component(HealthComponentKind kind) {
    for (final c in components) {
      if (c.kind == kind) return c;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSnapshot &&
          other.score == score &&
          other.debtMinutes == debtMinutes &&
          other.regularity == regularity &&
          other.socialJetlagMinutes == socialJetlagMinutes &&
          listEquals(other.components, components) &&
          other.nights == nights &&
          other.averageMinutes == averageMinutes &&
          other.goalMinutes == goalMinutes;

  @override
  int get hashCode => Object.hash(
    score,
    debtMinutes,
    regularity,
    socialJetlagMinutes,
    Object.hashAll(components),
    nights,
    averageMinutes,
    goalMinutes,
  );

  @override
  String toString() =>
      'HealthSnapshot(score: $score, debt: $debtMinutes, '
      'regularity: $regularity, jetlag: $socialJetlagMinutes, '
      'components: $components)';
}

/// Hesaplama sabitleri (ISKELET.md §5).
abstract final class HealthRules {
  /// Skor, borç ve düzenlilik penceresi.
  static const scoreNights = 14;

  /// Sosyal jetlag penceresi.
  static const jetlagNights = 28;

  /// Skor geçmişi grafiğindeki gece sayısı.
  static const historyNights = 30;

  /// Skor için penceredeki en az kayıt.
  static const minEntries = 3;

  /// SRI için en az ardışık kayıtlı gece çifti.
  static const minRegularityPairs = 5;

  /// Sosyal jetlag için her grupta en az gece.
  static const minJetlagNights = 2;

  /// Fazla uyku borcu gece başına en çok bu kadar düşürür.
  static const maxRepayPerNight = 60;

  /// Bu borçta ve üstünde borç bileşeni 0 puandır.
  static const int debtCeiling = 7 * 60;

  static const durationMax = 40;
  static const regularityMax = 25;
  static const debtMax = 20;
  static const moodMax = 15;

  /// Ortalama süre hedefin bu oranı ve üstündeyse tam puan.
  static const durationFull = 0.9;

  /// Ortalama süre hedefin bu oranı ve altındaysa sıfır puan.
  static const durationZero = 0.7;

  static const int minutesPerDay = 24 * 60;
}

/// [today]'den önceki [count] gecenin kayıtları ([today] − count …
/// [today] − 1), geceye göre artan. Tarihler `addDays` ile bulunur.
List<SleepEntry> entriesInWindow(
  List<SleepEntry> entries,
  DateTime today,
  int count,
) {
  final day = dateOnly(today);
  final first = addDays(day, -count);
  final last = addDays(day, -1);
  return [
    for (final e in entries)
      if (!e.night.isBefore(first) && !e.night.isAfter(last)) e,
  ]..sort((a, b) => a.night.compareTo(b.night));
}

/// Uyku borcu (dk): gece başına `max(0, hedef − süre)`; hedefi aşan gece
/// mevcut borcu en çok 60 dk düşürür ("geri ödeme"). Geceler sırayla işlenir
/// ve borç hiçbir adımda sıfırın altına inmez, yani önceden "uyku
/// biriktirilemez". Kaydı olmayan gece hesaba katılmaz.
int computeSleepDebt(List<SleepEntry> nights, int goalMinutes) {
  final sorted = [...nights]..sort((a, b) => a.night.compareTo(b.night));
  var debt = 0;
  for (final e in sorted) {
    final diff = goalMinutes - e.durationMinutes;
    if (diff > 0) {
      debt += diff;
    } else {
      debt -= math.min(-diff, HealthRules.maxRepayPerNight);
      if (debt < 0) debt = 0;
    }
  }
  return debt;
}

/// İki tarih arasındaki gün farkı (saat diliminden ve yaz saatinden bağımsız).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// [time]'ın, [night] akşamı 12:00'den itibaren duvar saati dakikası.
int _minutesFromNoon(DateTime night, DateTime time) =>
    _daysBetween(night, time) * HealthRules.minutesPerDay +
    time.hour * 60 +
    time.minute -
    12 * 60;

/// Uyku Düzenlilik İndeksi: son 14 gecede, ardışık iki kayıtlı gecenin
/// 1440 dakikalık ızgarasında (gece 12:00 → ertesi gün 12:00) aynı durumda
/// (uyku/uyanık) olunan dakika oranı `p`; `SRI = 200·p − 100`, 0–100'e
/// kırpılır. 5'ten az ardışık çift varsa null.
double? computeRegularity(List<SleepEntry> nights) {
  final byKey = {for (final e in nights) e.id: e};
  final grids = <String, List<bool>>{};
  List<bool> grid(SleepEntry e) => grids.putIfAbsent(e.id, () {
    final cells = List<bool>.filled(HealthRules.minutesPerDay, false);
    final start = _minutesFromNoon(
      e.night,
      e.bedtime,
    ).clamp(0, HealthRules.minutesPerDay);
    final end = _minutesFromNoon(
      e.night,
      e.wake,
    ).clamp(0, HealthRules.minutesPerDay);
    for (var m = start; m < end; m++) {
      cells[m] = true;
    }
    return cells;
  });

  var pairs = 0;
  var same = 0;
  for (final e in nights) {
    final next = byKey[nightKey(addDays(e.night, 1))];
    if (next == null) continue;
    final a = grid(e);
    final b = grid(next);
    for (var m = 0; m < HealthRules.minutesPerDay; m++) {
      if (a[m] == b[m]) same++;
    }
    pairs++;
  }
  if (pairs < HealthRules.minRegularityPairs) return null;
  final p = same / (pairs * HealthRules.minutesPerDay);
  return (200 * p - 100).clamp(0, 100).toDouble();
}

/// Sosyal jetlag (dk): hafta sonu gecelerinin (cuma/cumartesi) uyku orta
/// noktası ortalaması ile hafta içi ortalaması arasındaki mutlak fark.
/// Gruplardan birinde 2'den az gece varsa null.
int? computeSocialJetlag(List<SleepEntry> nights) {
  final weekend = <int>[];
  final weekday = <int>[];
  for (final e in nights) {
    final mid = _minutesFromNoon(e.night, e.bedtime) + e.durationMinutes / 2;
    (UserSettings.isWeekendNight(e.night) ? weekend : weekday).add(mid.round());
  }
  if (weekend.length < HealthRules.minJetlagNights ||
      weekday.length < HealthRules.minJetlagNights) {
    return null;
  }
  double avg(List<int> v) => v.reduce((a, b) => a + b) / v.length;
  return (avg(weekend) - avg(weekday)).abs().round();
}

/// [today] itibarıyla uyku sağlığı özeti. Son 14 gecede 3'ten az kayıt
/// varsa null. Hedef süre `UserSettings.goalMinutes`'tır; hafta sonu
/// esnekliği yalnız saatleri kaydırır, süreyi değiştirmez.
HealthSnapshot? computeHealthSnapshot(
  List<SleepEntry> entries,
  UserSettings settings,
  DateTime today,
) {
  final window = entriesInWindow(entries, today, HealthRules.scoreNights);
  if (window.length < HealthRules.minEntries) return null;
  final goal = settings.goalMinutes;

  final average =
      window.fold<int>(0, (s, e) => s + e.durationMinutes) / window.length;
  final ratio = goal <= 0 ? 1.0 : average / goal;
  final durationPoints =
      ((ratio - HealthRules.durationZero) /
              (HealthRules.durationFull - HealthRules.durationZero))
          .clamp(0.0, 1.0) *
      HealthRules.durationMax;

  final debt = computeSleepDebt(window, goal);
  final debtPoints =
      (1 - debt / HealthRules.debtCeiling).clamp(0.0, 1.0) *
      HealthRules.debtMax;

  final moodAverage =
      window.fold<int>(0, (s, e) => s + e.mood.index) / window.length;
  final moodPoints =
      moodAverage / (WakeMood.values.length - 1) * HealthRules.moodMax;

  final regularity = computeRegularity(window);
  final regularityPoints = regularity == null
      ? null
      : regularity / 100 * HealthRules.regularityMax;

  var raw = durationPoints + debtPoints + moodPoints;
  if (regularityPoints == null) {
    const available =
        HealthRules.durationMax + HealthRules.debtMax + HealthRules.moodMax;
    raw = raw / available * 100;
  } else {
    raw += regularityPoints;
  }

  return HealthSnapshot(
    score: raw.round().clamp(0, 100),
    debtMinutes: debt,
    regularity: regularity,
    socialJetlagMinutes: computeSocialJetlag(
      entriesInWindow(entries, today, HealthRules.jetlagNights),
    ),
    components: [
      HealthComponent(
        kind: HealthComponentKind.duration,
        points: durationPoints.round(),
        max: HealthRules.durationMax,
      ),
      if (regularityPoints != null)
        HealthComponent(
          kind: HealthComponentKind.regularity,
          points: regularityPoints.round(),
          max: HealthRules.regularityMax,
        ),
      HealthComponent(
        kind: HealthComponentKind.debt,
        points: debtPoints.round(),
        max: HealthRules.debtMax,
      ),
      HealthComponent(
        kind: HealthComponentKind.mood,
        points: moodPoints.round(),
        max: HealthRules.moodMax,
      ),
    ],
    nights: window.length,
    averageMinutes: average.round(),
    goalMinutes: goal,
  );
}

/// Skor geçmişinde bir gece.
typedef HealthScorePoint = ({DateTime night, int? score});

/// Son [nights] gecenin her biri için, o gece dahil önceki 14 gecelik
/// pencerenin skoru; eski → yeni. Skor hesaplanamayan gecede `score` null.
List<HealthScorePoint> healthScoreHistory(
  List<SleepEntry> entries,
  UserSettings settings,
  DateTime today, {
  int nights = HealthRules.historyNights,
}) {
  final day = dateOnly(today);
  return [
    for (var i = nights; i >= 1; i--)
      (
        night: addDays(day, -i),
        score: computeHealthSnapshot(
          entries,
          settings,
          addDays(day, -i + 1),
        )?.score,
      ),
  ];
}
