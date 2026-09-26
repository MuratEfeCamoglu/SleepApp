/// Akşam rutini adımlarının tamamlanma durumu, akşam başına.
abstract interface class RoutineRepository {
  /// [eveningKey] akşamında tamamlanan adımların indeksleri.
  Set<int> doneSteps(String eveningKey);

  Future<void> saveDoneSteps(String eveningKey, Set<int> steps);

  Future<void> clear();
}

/// Rutindeki adım sayısı.
const routineStepCount = 5;

/// "4-7-8 nefes egzersizi" adımının indeksi.
const routineBreathStep = 2;

/// Öğleden sonra yeni akşam başlar; gece yarısından sonra hâlâ önceki akşam.
DateTime eveningOf(DateTime now) {
  final shifted = now.subtract(const Duration(hours: 12));
  return DateTime(shifted.year, shifted.month, shifted.day);
}
