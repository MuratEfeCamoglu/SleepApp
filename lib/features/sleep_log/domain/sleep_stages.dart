import 'package:flutter/foundation.dart';

/// Tahmini evre süreleri (dakika). Toplamı uyku süresine eşittir.
@immutable
class SleepStages {
  const SleepStages({
    required this.deep,
    required this.rem,
    required this.light,
  });

  final int deep;
  final int rem;
  final int light;

  int get total => deep + rem + light;

  @override
  bool operator ==(Object other) =>
      other is SleepStages &&
      other.deep == deep &&
      other.rem == rem &&
      other.light == light;

  @override
  int get hashCode => Object.hash(deep, rem, light);

  @override
  String toString() => 'SleepStages(deep: $deep, rem: $rem, light: $light)';
}

/// Evreleri süreden deterministik olarak tahmin eder. Uyku 90 dakikalık
/// döngülerden oluşur; derin uyku ilk döngülerde, REM son döngülerde ağır
/// basar. Tıbbi ölçüm değildir, arayüzde bu belirtilir.
abstract final class StageEstimator {
  static const cycleMinutes = 90;

  /// Hedef süre içinde beklenen REM ve derin payı (halka hedefleri).
  static const remTargetShare = 0.25;
  static const deepTargetShare = 0.20;

  static SleepStages estimate(int minutes) {
    if (minutes <= 0) return const SleepStages(deep: 0, rem: 0, light: 0);
    var deep = 0.0;
    var rem = 0.0;
    var remaining = minutes.toDouble();
    var cycle = 0;
    while (remaining > 0) {
      final length = remaining < cycleMinutes ? remaining : cycleMinutes;
      final deepShare = (0.30 - 0.06 * cycle).clamp(0.05, 0.30);
      final remShare = (0.10 + 0.06 * cycle).clamp(0.10, 0.40);
      deep += length * deepShare;
      rem += length * remShare;
      remaining -= length;
      cycle++;
    }
    final d = deep.round();
    final r = rem.round();
    return SleepStages(deep: d, rem: r, light: minutes - d - r);
  }
}
