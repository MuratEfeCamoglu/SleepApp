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
    this.dreamKind,
    this.dreamEmotions = const {},
  });

  factory LogDraft.fromEntry(SleepEntry e) => LogDraft(
    entry: e,
    mood: e.mood,
    factors: {...e.factors},
    note: e.note,
    dreamKind: e.dreamKind,
    dreamEmotions: {...e.dreamEmotions},
  );

  /// Uyku modunun kaydettiği gece.
  final SleepEntry entry;
  final WakeMood mood;
  final Set<SleepFactor> factors;
  final String note;
  final DreamKind? dreamKind;
  final Set<DreamEmotion> dreamEmotions;

  DateTime get night => entry.night;

  SleepEntry toEntry() => entry.copyWith(
    mood: mood,
    factors: SleepFactor.values.where(factors.contains).toList(),
    note: note.trim(),
    dreamKind: dreamKind,
    dreamEmotions: DreamEmotion.values.where(dreamEmotions.contains).toList(),
  );

  static const _unset = Object();

  /// [dreamKind] için `null` vermek seçimi kaldırır; vermemek korur.
  LogDraft copyWith({
    WakeMood? mood,
    Set<SleepFactor>? factors,
    String? note,
    Object? dreamKind = _unset,
    Set<DreamEmotion>? dreamEmotions,
  }) => LogDraft(
    entry: entry,
    mood: mood ?? this.mood,
    factors: factors ?? this.factors,
    note: note ?? this.note,
    dreamKind: identical(dreamKind, _unset)
        ? this.dreamKind
        : dreamKind as DreamKind?,
    dreamEmotions: dreamEmotions ?? this.dreamEmotions,
  );

  /// Kayıtla aynı içerikte mi? ("Kaydedildi" durumu)
  bool matches(SleepEntry? e) => e != null && e == toEntry();

  /// Bekleyen rüya taslağını not alanına koyar; tür boşsa taslağınki,
  /// duygu mevcutlara eklenir.
  LogDraft withPendingDream(PendingDreamDraft p) => copyWith(
    note: p.note,
    dreamKind: dreamKind ?? p.kind,
    dreamEmotions: {...dreamEmotions, ?p.emotion},
  );
}

/// Rüya yorumundan gelen, henüz bir geceye bağlanamamış not (dün gecenin
/// uyku kaydı yoktu). Yalnızca bellekte tutulur; Kaydet ekranında notu boş
/// ilk gecenin not alanına dolar ve o gece kaydedilince temizlenir.
@immutable
class PendingDreamDraft {
  const PendingDreamDraft({required this.note, this.kind, this.emotion});

  final String note;
  final DreamKind? kind;
  final DreamEmotion? emotion;

  @override
  bool operator ==(Object other) =>
      other is PendingDreamDraft &&
      other.note == note &&
      other.kind == kind &&
      other.emotion == emotion;

  @override
  int get hashCode => Object.hash(note, kind, emotion);
}

/// Kısa ömürlü: autoDispose değildir ki yorum ekranı kapanınca da kalsın;
/// diske yazılmaz.
final NotifierProvider<PendingDreamDraftNotifier, PendingDreamDraft?>
pendingDreamDraftProvider =
    NotifierProvider<PendingDreamDraftNotifier, PendingDreamDraft?>(
      PendingDreamDraftNotifier.new,
    );

class PendingDreamDraftNotifier extends Notifier<PendingDreamDraft?> {
  @override
  PendingDreamDraft? build() => null;

  /// Boş not (ve tür/duygu yoksa) taslak bırakmaz.
  void set(PendingDreamDraft draft) {
    final note = draft.note.trim();
    if (note.isEmpty && draft.kind == null && draft.emotion == null) return;
    state = PendingDreamDraft(
      note: note,
      kind: draft.kind,
      emotion: draft.emotion,
    );
  }

  void clear() => state = null;
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
  /// Taslak bekleyen rüya notuyla mı kuruldu (kaydedince temizlenir).
  bool _usesPending = false;

  @override
  LogDraft? build() {
    final night = ref.watch(logNightProvider);
    final stored = ref.watch(
      sleepLogProvider.select((v) => v.value?.forNight(night)),
    );
    final pending = ref.watch(pendingDreamDraftProvider);
    _usesPending = false;
    if (stored == null) return null;
    final draft = LogDraft.fromEntry(stored);
    // Notu olan geceyi ezmez; taslak notu boş bir geceyi bekler.
    if (pending == null || stored.note.trim().isNotEmpty) return draft;
    _usesPending = true;
    return draft.withPendingDream(pending);
  }

  void setMood(WakeMood mood) => state = state?.copyWith(mood: mood);

  void setNote(String note) => state = state?.copyWith(note: note);

  /// Tek seçim; seçili türe yeniden dokunmak seçimi kaldırır.
  void toggleDreamKind(DreamKind kind) {
    final draft = state;
    if (draft == null) return;
    state = draft.copyWith(dreamKind: draft.dreamKind == kind ? null : kind);
  }

  void toggleDreamEmotion(DreamEmotion emotion) {
    final draft = state;
    if (draft == null) return;
    final next = {...draft.dreamEmotions};
    if (!next.remove(emotion)) next.add(emotion);
    state = draft.copyWith(dreamEmotions: next);
  }

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
    final usedPending = _usesPending;
    await ref.read(sleepLogProvider.notifier).save(draft.toEntry());
    if (usedPending && ref.mounted) {
      ref.read(pendingDreamDraftProvider.notifier).clear();
    }
  }
}
