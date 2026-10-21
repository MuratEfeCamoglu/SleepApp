import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/features/dreams/domain/dream_interview.dart';
import 'package:uyku/features/dreams/domain/dream_reading.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/log_editor.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// Kaydetme sonucu.
enum DreamSaveResult {
  /// Gecenin kaydı güncellendi.
  saved,

  /// Hedef gecenin uyku kaydı yok; not, tür ve duygu Kaydet ekranına
  /// taşınmak üzere [pendingDreamDraftProvider]a bırakıldı.
  noEntry,
}

const Object _unset = Object();

/// Sorulu yorum akışının durumu. Adım 0 rüya notu, 1–6 sorular,
/// [resultStep] çıkarım sayfasıdır.
@immutable
class DreamInterviewState {
  const DreamInterviewState({
    this.step = 0,
    this.note = '',
    this.night,
    this.kind,
    this.answers = const DreamInterviewAnswers(),
    this.saved = false,
  });

  static const maxNoteLength = 1000;
  static final int resultStep = DreamQuestion.values.length + 1;

  final int step;
  final String note;

  /// Akış günlükteki bir geceden başladıysa onun anahtarı (`2026-09-24`).
  final String? night;
  final DreamKind? kind;
  final DreamInterviewAnswers answers;

  /// Son çıkarım kaydedildi mi ("Kaydedildi" etiketi).
  final bool saved;

  /// 1–6. adımdaki soru; diğer adımlarda null.
  DreamQuestion? get question =>
      step >= 1 && step < resultStep ? DreamQuestion.values[step - 1] : null;

  bool get isResult => step == resultStep;

  bool get canAdvance {
    if (step == 0) return note.trim().isNotEmpty || night != null;
    final q = question;
    return q != null && answers.isAnswered(q);
  }

  DreamInterviewState copyWith({
    int? step,
    String? note,
    Object? night = _unset,
    Object? kind = _unset,
    DreamInterviewAnswers? answers,
    bool? saved,
  }) => DreamInterviewState(
    step: step ?? this.step,
    note: note ?? this.note,
    night: identical(night, _unset) ? this.night : night as String?,
    kind: identical(kind, _unset) ? this.kind : kind as DreamKind?,
    answers: answers ?? this.answers,
    saved: saved ?? this.saved,
  );

  @override
  bool operator ==(Object other) =>
      other is DreamInterviewState &&
      other.step == step &&
      other.note == note &&
      other.night == night &&
      other.kind == kind &&
      other.answers == answers &&
      other.saved == saved;

  @override
  int get hashCode => Object.hash(step, note, night, kind, answers, saved);
}

/// Ekrandan çıkınca sıfırlanır; kaydetmeden çıkılırsa hiçbir şey kalıcı
/// olmaz.
final NotifierProvider<DreamInterviewController, DreamInterviewState>
dreamInterviewProvider =
    NotifierProvider.autoDispose<DreamInterviewController, DreamInterviewState>(
      DreamInterviewController.new,
    );

class DreamInterviewController extends Notifier<DreamInterviewState> {
  @override
  DreamInterviewState build() => const DreamInterviewState();

  void _set(DreamInterviewState next) => state = next.copyWith(saved: false);

  void next() {
    if (!state.canAdvance || state.isResult) return;
    state = state.copyWith(step: state.step + 1);
  }

  /// Bir önceki adım; cevaplar korunur.
  void back() {
    if (state.step == 0) return;
    state = state.copyWith(step: state.step - 1);
  }

  void setNote(String note) {
    final trimmed = note.length > DreamInterviewState.maxNoteLength
        ? note.substring(0, DreamInterviewState.maxNoteLength)
        : note;
    _set(state.copyWith(note: trimmed));
  }

  /// Tek seçim; seçili türe tekrar dokununca kalkar.
  void toggleKind(DreamKind kind) =>
      _set(state.copyWith(kind: state.kind == kind ? null : kind));

  /// Günlükteki bir geceden başlar: not, tür ve baskın duygu taşınır.
  void startFrom(SleepEntry entry) {
    _set(
      state.copyWith(
        night: entry.id,
        note: entry.note,
        kind: entry.dreamKind,
        answers: state.answers.copyWith(
          emotion:
              state.answers.emotion ?? dominantEmotion(entry.dreamEmotions),
        ),
      ),
    );
  }

  /// Günlük seçimini bırakır; not alanı boşalır.
  void clearNight() => _set(state.copyWith(night: null, note: '', kind: null));

  void setEmotion(DreamEmotion v) =>
      _set(state.copyWith(answers: state.answers.copyWith(emotion: v)));

  void setWake(DreamWakeFeeling v) =>
      _set(state.copyWith(answers: state.answers.copyWith(wake: v)));

  void setControl(DreamControl v) =>
      _set(state.copyWith(answers: state.answers.copyWith(control: v)));

  /// `null` → "Hiçbiri".
  void togglePerson(DreamPerson? v) =>
      _set(state.copyWith(answers: state.answers.togglePerson(v)));

  void setLife(LifeFocus v) =>
      _set(state.copyWith(answers: state.answers.copyWith(life: v)));

  void setRecurrence(DreamRecurrence v) =>
      _set(state.copyWith(answers: state.answers.copyWith(recurrence: v)));

  /// Çıkarımı geceye bağlar: akış bir geceden başladıysa o gece, değilse dün
  /// gece. Not, tür ve baskın duygu kayda yazılır; diğer alanlar korunur.
  /// Kayıt yoksa hiçbir şey kalıcı olmaz; taslak Kaydet ekranına taşınır.
  Future<DreamSaveResult> save() async {
    final entries = await ref.read(sleepLogProvider.future);
    final key = state.night ?? nightKey(addDays(ref.read(todayProvider), -1));
    SleepEntry? entry;
    for (final e in entries) {
      if (e.id == key) entry = e;
    }
    if (entry == null) {
      ref
          .read(pendingDreamDraftProvider.notifier)
          .set(
            PendingDreamDraft(
              note: state.note,
              kind: state.kind,
              emotion: state.answers.emotion,
            ),
          );
      return DreamSaveResult.noEntry;
    }
    final emotion = state.answers.emotion;
    final updated = entry.copyWith(
      note: state.note.trim(),
      dreamKind: state.kind ?? entry.dreamKind,
      dreamEmotions: [
        ?emotion,
        for (final e in entry.dreamEmotions)
          if (e != emotion) e,
      ],
    );
    await ref.read(sleepLogProvider.notifier).save(updated);
    if (ref.mounted) state = state.copyWith(night: key, saved: true);
    return DreamSaveResult.saved;
  }
}
