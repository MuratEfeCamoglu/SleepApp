import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

extension DreamEntryX on SleepEntry {
  /// Rüya notu yazılmış mı?
  bool get hasDreamNote => note.trim().isNotEmpty;

  /// Not, tür veya duygudan en az biri girilmiş mi?
  bool get hasDream =>
      hasDreamNote || dreamKind != null || dreamEmotions.isNotEmpty;
}

/// Rüya günlüğü listesi: notu olan geceler, yeniden eskiye.
///
/// [query] notta geçen metni Türkçe büyük/küçük harf duyarsız süzer
/// ("İSTANBUL" ↔ "istanbul'da"). [kind] verilirse yalnız o tür.
List<SleepEntry> dreamJournal(
  List<SleepEntry> entries, {
  String query = '',
  DreamKind? kind,
}) {
  final needle = normalizeTr(query);
  // Kimlik `2026-09-24` biçiminde olduğundan metin sırası gece sırasıdır.
  final newestFirst = [...entries]..sort((a, b) => b.id.compareTo(a.id));
  return [
    for (final e in newestFirst)
      if (e.hasDreamNote &&
          (kind == null || e.dreamKind == kind) &&
          (needle.isEmpty || normalizeTr(e.note).contains(needle)))
        e,
  ];
}
