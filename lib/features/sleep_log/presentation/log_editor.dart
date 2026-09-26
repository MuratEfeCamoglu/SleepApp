import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// Kaydet ekranındaki taslak. Saatler yalnızca Uyku modundan gelir ve
/// değiştirilemez; kullanıcı yalnızca uyanış hissini ve etkenleri ekler.
@immutable
class LogDraft {
  const LogDraft({
    required this.entry,
    required this.mood,
    required this.factors,
    this.note = '',
  });

  factory LogDraft.fromEntry(SleepEntry e) =>
      LogDraft(entry: e, mood: e.mood, factors: {...e.factors}, note: e.note);

  /// Uyku modunun kaydettiği gece.
  final SleepEntry entry;
  final WakeMood mood;
  final Set<SleepFactor> factors;
  final String note;

  DateTime get night => entry.night;

  SleepEntry toEntry() => entry.copyWith(
    mood: mood,
    factors: SleepFactor.values.where(factors.contains).toList(),
    note: note.trim(),
  );

  LogDraft copyWith({
    WakeMood? mood,
    Set<SleepFactor>? factors,
    String? note,
  }) => LogDraft(
    entry: entry,
    mood: mood ?? this.mood,
    factors: factors ?? this.factors,
    note: note ?? this.note,
  );

  /// Kayıtla aynı içerikte mi? ("Kaydedildi" durumu)
  bool matches(SleepEntry? e) => e != null && e == toEntry();
}

/// Kaydedilen gece; varsayılan dün akşam.
final NotifierProvider<LogNight, DateTime> logNightProvider =
    NotifierProvider.autoDispose<LogNight, DateTime>(LogNight.new);

class LogNight extends Notifier<DateTime> {
  @override
  DateTime build() => addDays(ref.watch(todayProvider), -1);

  void select(DateTime night) => state = dateOnly(night);
}

/// Seçili gecenin taslağı; o gece Uyku modu kullanılmadıysa null.
final NotifierProvider<LogEditor, LogDraft?> logEditorProvider =
    NotifierProvider.autoDispose<LogEditor, LogDraft?>(LogEditor.new);

class LogEditor extends Notifier<LogDraft?> {
  @override
  LogDraft? build() {
    final night = ref.watch(logNightProvider);
    final stored = ref.watch(
      sleepLogProvider.select((v) => v.value?.forNight(night)),
    );
    return stored == null ? null : LogDraft.fromEntry(stored);
  }

  void setMood(WakeMood mood) => state = state?.copyWith(mood: mood);

  void setNote(String note) => state = state?.copyWith(note: note);

  void toggleFactor(SleepFactor factor) {
    final draft = state;
    if (draft == null) return;
    final next = {...draft.factors};
    if (!next.remove(factor)) next.add(factor);
    state = draft.copyWith(factors: next);
  }

  Future<void> save() async {
    final draft = state;
    if (draft == null) return;
    await ref.read(sleepLogProvider.notifier).save(draft.toEntry());
  }
}
