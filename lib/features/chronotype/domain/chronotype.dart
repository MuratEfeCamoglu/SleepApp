/// Sabahçı–akşamcı eğilimi.
enum Chronotype { morning, intermediate, evening }

/// Beş soruluk kısa kronotip anketi (Horne–Östberg anketinin kısaltılmış
/// sürümündeki puanlama aralıkları temel alınmıştır). Tıbbi tanı değildir.
abstract final class ChronotypeQuiz {
  /// Her sorunun seçenek puanları; seçenek sırası ekrandaki sırayla aynıdır.
  static const List<List<int>> scores = [
    [5, 4, 3, 2, 1], // Serbest günde doğal uyanış saati
    [1, 2, 3, 4], // Uyandıktan sonraki ilk yarım saat
    [5, 4, 3, 2, 1], // Akşam yorgunluğun başladığı saat
    [4, 3, 2, 1], // Günün en verimli olduğun zamanı
    [6, 4, 2, 0], // Kendini nasıl tanımlarsın
  ];

  static int get questionCount => scores.length;

  /// Toplam puan 4–25; ≤11 akşamcı, ≥18 sabahçı.
  static Chronotype classify(List<int> answers) {
    assert(answers.length == questionCount, 'Her soru cevaplanmalı');
    var total = 0;
    for (var i = 0; i < answers.length; i++) {
      total += scores[i][answers[i]];
    }
    if (total >= 18) return Chronotype.morning;
    if (total <= 11) return Chronotype.evening;
    return Chronotype.intermediate;
  }

  /// Türe göre doğal uyanış saati (gün içi dakika).
  static int idealWakeMinute(Chronotype type) => switch (type) {
    Chronotype.morning => 6 * 60 + 30,
    Chronotype.intermediate => 7 * 60 + 15,
    Chronotype.evening => 8 * 60,
  };

  /// Önerilen yatış: doğal uyanıştan hedef süre kadar önce, 15 dk'ya yuvarlı.
  static int suggestedBedtime(Chronotype type, int goalMinutes) {
    const day = 24 * 60;
    final raw = idealWakeMinute(type) - goalMinutes;
    final rounded = (raw / 15).round() * 15;
    return ((rounded % day) + day) % day;
  }
}
