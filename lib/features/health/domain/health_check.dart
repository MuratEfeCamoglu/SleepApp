import 'package:flutter/foundation.dart';

/// Uyku sağlığı kontrolünün 6 sorusu (kendi yazdığımız öz-kontrol; lisanslı
/// bir ölçek değildir). Cevaplar 0–3: hiç, bazen, sık, neredeyse her gece.
enum HealthQuestion {
  breathing,
  daytimeSleepiness,
  fallingAsleep,
  nightWaking,
  morningTired,
  restlessLegs,
}

/// "Bir uzmana danışmayı düşün" sinyali veren işaretler; tanı değildir.
enum HealthFlag { breathing, daytimeSleepiness, insomniaSymptoms, restlessLegs }

abstract final class HealthCheckRules {
  static const minAnswer = 0;
  static const maxAnswer = 3;

  /// Tek soruluk bayraklar için eşik.
  static const singleFrom = 2;

  /// Dalma güçlüğü + gece uyanma toplamı için eşik.
  static const sleepContinuityFrom = 4;
}

/// ISKELET.md §5 kuralları. Cevaplanmamış soru 0 sayılır.
List<HealthFlag> evaluateHealthCheck(Map<HealthQuestion, int> answers) {
  int a(HealthQuestion q) => answers[q] ?? 0;
  return [
    if (a(HealthQuestion.breathing) >= HealthCheckRules.singleFrom)
      HealthFlag.breathing,
    if (a(HealthQuestion.daytimeSleepiness) >= HealthCheckRules.singleFrom)
      HealthFlag.daytimeSleepiness,
    if (a(HealthQuestion.fallingAsleep) + a(HealthQuestion.nightWaking) >=
        HealthCheckRules.sleepContinuityFrom)
      HealthFlag.insomniaSymptoms,
    if (a(HealthQuestion.restlessLegs) >= HealthCheckRules.singleFrom)
      HealthFlag.restlessLegs,
  ];
}

/// Son kontrolün sonucu (`health.check.v1`).
@immutable
class HealthCheckResult {
  const HealthCheckResult({
    required this.answers,
    required this.flags,
    required this.takenAt,
  });

  /// Cevaplardan bayrakları hesaplayarak oluşturur.
  factory HealthCheckResult.evaluate(
    Map<HealthQuestion, int> answers,
    DateTime takenAt,
  ) => HealthCheckResult(
    answers: Map.unmodifiable(answers),
    flags: List.unmodifiable(evaluateHealthCheck(answers)),
    takenAt: takenAt,
  );

  /// Yanlış tipli alanlarda [FormatException] fırlatır (TypeError değil);
  /// depo bozuk kaydı güvenle yok sayar. Bilinmeyen soru/bayrak adları
  /// atlanır.
  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    if (rawAnswers is! Map<String, dynamic>) {
      throw FormatException('health.answers', rawAnswers);
    }
    final byName = HealthQuestion.values.asNameMap();
    final answers = <HealthQuestion, int>{};
    for (final MapEntry(:key, :value) in rawAnswers.entries) {
      final question = byName[key];
      if (question == null) continue;
      if (value is! int ||
          value < HealthCheckRules.minAnswer ||
          value > HealthCheckRules.maxAnswer) {
        throw FormatException('health.answer', value);
      }
      answers[question] = value;
    }

    final rawFlags = json['flags'];
    if (rawFlags is! List<dynamic>) {
      throw FormatException('health.flags', rawFlags);
    }
    final flagByName = HealthFlag.values.asNameMap();
    final flags = <HealthFlag>[
      for (final f in rawFlags)
        if (f is String && flagByName[f] != null) flagByName[f]!,
    ];

    final rawTaken = json['takenAt'];
    if (rawTaken is! String) {
      throw FormatException('health.takenAt', rawTaken);
    }
    return HealthCheckResult(
      answers: Map.unmodifiable(answers),
      flags: List.unmodifiable(flags),
      takenAt: DateTime.parse(rawTaken),
    );
  }

  final Map<HealthQuestion, int> answers;
  final List<HealthFlag> flags;
  final DateTime takenAt;

  bool get hasFlags => flags.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'answers': {for (final e in answers.entries) e.key.name: e.value},
    'flags': [for (final f in flags) f.name],
    'takenAt': takenAt.toIso8601String(),
  };

  HealthCheckResult copyWith({
    Map<HealthQuestion, int>? answers,
    List<HealthFlag>? flags,
    DateTime? takenAt,
  }) => HealthCheckResult(
    answers: answers ?? this.answers,
    flags: flags ?? this.flags,
    takenAt: takenAt ?? this.takenAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthCheckResult &&
          mapEquals(other.answers, answers) &&
          listEquals(other.flags, flags) &&
          other.takenAt == takenAt;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(HealthQuestion.values.map((q) => answers[q])),
    Object.hashAll(flags),
    takenAt,
  );

  @override
  String toString() =>
      'HealthCheckResult(answers: $answers, flags: $flags, '
      'takenAt: $takenAt)';
}
