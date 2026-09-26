import 'package:flutter/foundation.dart';

/// Uyanış hissi — Kaydet ekranındaki 5 chip, kötüden iyiye.
enum WakeMood { exhausted, tired, normal, refreshed, great }

/// Uykuyu etkileyen etkenler — Kaydet ekranındaki 7 chip.
enum SleepFactor {
  caffeine,
  alcohol,
  lateMeal,
  exercise,
  screen,
  stress,
  noise;

  /// Uykuyu olumsuz etkileyen etkenler.
  bool get isDisruptive => this != exercise;
}

/// Bir gecenin kaydı. Her geceye tek kayıt düşer; [id] gecenin tarihidir
/// (`2026-09-24`), böylece aynı geceyi yeniden kaydetmek üzerine yazar.
@immutable
class SleepEntry {
  const SleepEntry({
    required this.id,
    required this.bedtime,
    required this.wake,
    this.mood = WakeMood.normal,
    this.factors = const <SleepFactor>[],
    this.note = '',
  });

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
    id: json['id'] as String,
    bedtime: DateTime.parse(json['bedtime'] as String),
    wake: DateTime.parse(json['wake'] as String),
    mood: WakeMood.values.asNameMap()[json['mood']] ?? WakeMood.normal,
    factors:
        (json['factors'] as List<dynamic>?)
            ?.map((e) => SleepFactor.values.byName(e as String))
            .toList() ??
        const <SleepFactor>[],
    note: json['note'] as String? ?? '',
  );

  /// Kayıt, yatış ve uyanıştan geceyi hesaplayarak oluşturulur.
  factory SleepEntry.create({
    required DateTime bedtime,
    required DateTime wake,
    WakeMood mood = WakeMood.normal,
    List<SleepFactor> factors = const [],
  }) => SleepEntry(
    id: nightKey(nightOf(wake)),
    bedtime: bedtime,
    wake: wake,
    mood: mood,
    factors: factors,
  );

  final String id;
  final DateTime bedtime;
  final DateTime wake;
  final WakeMood mood;
  final List<SleepFactor> factors;

  /// Rüya günlüğü: sabah yazılan serbest not; boş olabilir.
  final String note;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'bedtime': bedtime.toIso8601String(),
    'wake': wake.toIso8601String(),
    'mood': mood.name,
    'factors': factors.map((e) => e.name).toList(),
    if (note.isNotEmpty) 'note': note,
  };

  SleepEntry copyWith({
    String? id,
    DateTime? bedtime,
    DateTime? wake,
    WakeMood? mood,
    List<SleepFactor>? factors,
    String? note,
  }) => SleepEntry(
    id: id ?? this.id,
    bedtime: bedtime ?? this.bedtime,
    wake: wake ?? this.wake,
    mood: mood ?? this.mood,
    factors: factors ?? this.factors,
    note: note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepEntry &&
          other.id == id &&
          other.bedtime == bedtime &&
          other.wake == wake &&
          other.mood == mood &&
          listEquals(other.factors, factors) &&
          other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, bedtime, wake, mood, Object.hashAll(factors), note);

  @override
  String toString() =>
      'SleepEntry(id: $id, bedtime: $bedtime, wake: $wake, mood: $mood, '
      'factors: $factors, note: $note)';

  int get durationMinutes => wake.difference(bedtime).inMinutes;

  /// Gecenin başladığı akşamın tarihi ([id]'den).
  DateTime get night => DateTime.parse(id);
}

/// Uyanış anından gecenin (akşamın) tarihini bulur: 07:22 Cuma → Perşembe.
DateTime nightOf(DateTime wake) {
  final shifted = wake.subtract(const Duration(hours: 12));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// Yalnızca tarih kısmı.
DateTime dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);

/// `2026-09-24`
String nightKey(DateTime night) {
  final m = night.month.toString().padLeft(2, '0');
  final d = night.day.toString().padLeft(2, '0');
  return '${night.year}-$m-$d';
}

/// [day] tarihine gün ekler; yaz saati geçişlerinden etkilenmez.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
