import 'package:flutter/foundation.dart';
import 'package:uyku/features/dreams/domain/dream_journal.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Bir sembolün kaç gecede geçtiği.
typedef SymbolCount = ({DreamSymbol symbol, int nights});

/// Kabus gecelerinde en sık işaretlenen etken.
typedef FactorCount = ({SleepFactor factor, int nights});

/// Son 90 gecenin rüya içgörüleri (türetilir, saklanmaz).
@immutable
class DreamInsights {
  const DreamInsights({
    required this.dreamNights,
    required this.topSymbols,
    required this.kindedNights,
    required this.nightmareNights,
    required this.nightmareRate,
    required this.nightmareAverage,
    required this.otherAverage,
    required this.nightmareFactor,
    this.dreamAverage,
  });

  /// Pencerede rüya (not, tür veya duygu) girilmiş gece sayısı.
  final int dreamNights;

  /// En sık 5 sembol; gece sayısı azalan, eşitlikte sözlük sırası.
  final List<SymbolCount> topSymbols;

  /// Türü girilmiş rüyalı geceler.
  final int kindedNights;

  final int nightmareNights;

  /// Türü girilmiş rüyalar içinde kabus oranı (0–1). Kabus ve diğer
  /// türlerde en az [DreamInsightsCalculator.minNights] gece yoksa null.
  final double? nightmareRate;

  /// Kabus gecelerinin ortalama uyku süresi (dk). Kabus ve diğer rüyalı
  /// gecelerde en az [DreamInsightsCalculator.minNights] gece yoksa null.
  final int? nightmareAverage;

  /// Kabus olmayan rüyalı gecelerin ortalama uyku süresi (dk).
  final int? otherAverage;

  /// Kabus gecelerinde en sık etken; en az 3 kabus gecesinde
  /// işaretlenmemişse null.
  final FactorCount? nightmareFactor;

  /// Rüyalı gecelerin ortalama uyku süresi (dk); en az
  /// [DreamInsightsCalculator.minNights] rüyalı gece yoksa null.
  final int? dreamAverage;

  bool get isEmpty => dreamNights == 0;

  /// Kabus − diğer ortalama süre (dk).
  int? get durationDelta => nightmareAverage == null || otherAverage == null
      ? null
      : nightmareAverage! - otherAverage!;
}

abstract final class DreamInsightsCalculator {
  /// Bu kadar geriye bakılır.
  static const windowNights = 90;

  /// Karşılaştırmanın her iki tarafında en az bu kadar gece gerekir.
  static const minNights = 3;

  static const topCount = 5;
}

/// Son [DreamInsightsCalculator.windowNights] gecenin rüya içgörüleri. Dün
/// gece dahil, daha eskiler sayılmaz.
DreamInsights computeDreamInsights(List<SleepEntry> entries, DateTime today) {
  const min = DreamInsightsCalculator.minNights;
  final lastNight = addDays(dateOnly(today), -1);
  final first = addDays(lastNight, -(DreamInsightsCalculator.windowNights - 1));
  final dreams = [
    for (final e in entries)
      if (!e.night.isBefore(first) && !e.night.isAfter(lastNight) && e.hasDream)
        e,
  ];

  // Semboller: her gece bir kez.
  final counts = <DreamSymbol, int>{};
  for (final e in dreams) {
    for (final s in findSymbols(e.note)) {
      counts[s] = (counts[s] ?? 0) + 1;
    }
  }
  final order = {
    for (var i = 0; i < dreamSymbols.length; i++) dreamSymbols[i]: i,
  };
  final ranked = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : order[a.key]!.compareTo(order[b.key]!);
    });
  final top = [
    for (final c in ranked.take(DreamInsightsCalculator.topCount))
      (symbol: c.key, nights: c.value),
  ];

  final nightmares = [
    for (final e in dreams)
      if (e.dreamKind == DreamKind.nightmare) e,
  ];
  final kinded = dreams.where((e) => e.dreamKind != null).length;
  final otherKinded = kinded - nightmares.length;
  final others = [
    for (final e in dreams)
      if (e.dreamKind != DreamKind.nightmare) e,
  ];

  int avg(List<SleepEntry> list) =>
      (list.fold<int>(0, (s, e) => s + e.durationMinutes) / list.length)
          .round();

  final enoughNightmares = nightmares.length >= min;
  final compare = enoughNightmares && others.length >= min;

  FactorCount? factor;
  if (enoughNightmares) {
    for (final f in SleepFactor.values) {
      final n = nightmares.where((e) => e.factors.contains(f)).length;
      if (n >= min && (factor == null || n > factor.nights)) {
        factor = (factor: f, nights: n);
      }
    }
  }

  return DreamInsights(
    dreamNights: dreams.length,
    topSymbols: top,
    kindedNights: kinded,
    nightmareNights: nightmares.length,
    nightmareRate: enoughNightmares && otherKinded >= min
        ? nightmares.length / kinded
        : null,
    nightmareAverage: compare ? avg(nightmares) : null,
    otherAverage: compare ? avg(others) : null,
    nightmareFactor: factor,
    dreamAverage: dreams.length >= min ? avg(dreams) : null,
  );
}
