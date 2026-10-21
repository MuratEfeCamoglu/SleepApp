import 'package:flutter/foundation.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Bir rüya notunun yorumu (türetilir, saklanmaz).
@immutable
class DreamReading {
  const DreamReading({
    required this.symbols,
    required this.theme,
    required this.kind,
    this.suggestion,
  });

  /// Notta bulunan semboller, ilk geçiş sırasıyla.
  final List<DreamSymbol> symbols;

  /// Tür ve baskın duygudan türetilen tek cümlelik genel tema; ikisi de
  /// girilmediyse null.
  final String? theme;

  final DreamKind? kind;

  /// Yalnızca kabusta: sakinleştirici, yeniden yazma önerisi.
  final String? suggestion;

  bool get hasSymbols => symbols.isNotEmpty;
}

/// Baskın duygu: işaretlenenler içinde en yoğun olanı. Yoğun ve zor duygular
/// önce gelir; çünkü temayı en çok onlar renklendirir.
DreamEmotion? dominantEmotion(List<DreamEmotion> emotions) {
  for (final e in DreamThemes.emotionPriority) {
    if (emotions.contains(e)) return e;
  }
  return null;
}

/// Notu, türü ve duyguları yorumlar. Kural tabanlıdır ve cihazda çalışır.
DreamReading readDream(SleepEntry entry) => DreamReading(
  symbols: findSymbols(entry.note),
  theme: DreamThemes.themeFor(entry.dreamKind, entry.dreamEmotions),
  kind: entry.dreamKind,
  suggestion: entry.dreamKind == DreamKind.nightmare
      ? DreamThemes.nightmareSuggestion
      : null,
);

/// Tema cümleleri. Sembol sözlüğü gibi alan verisidir; yansıtıcı ve temkinli
/// dil kullanır, kehanet veya sağlık iddiası içermez.
abstract final class DreamThemes {
  static const List<DreamEmotion> emotionPriority = [
    DreamEmotion.fear,
    DreamEmotion.anger,
    DreamEmotion.sadness,
    DreamEmotion.confusion,
    DreamEmotion.joy,
    DreamEmotion.calm,
  ];

  /// Kabus ve tekrarlayan rüyada tür, diğerlerinde baskın duygu öne çıkar.
  static String? themeFor(DreamKind? kind, List<DreamEmotion> emotions) {
    if (kind == DreamKind.nightmare || kind == DreamKind.recurring) {
      return _kind[kind];
    }
    final emotion = dominantEmotion(emotions);
    if (emotion != null) return _emotion[emotion];
    return kind == null ? null : _kind[kind];
  }

  static const nightmareSuggestion =
      'Uyandığında birkaç yavaş nefes al ve güvende olduğunu kendine '
      'hatırlat. Rüyanın sonunu kendi istediğin gibi yeniden yazmayı dene; '
      'gün içinde sakin bir anda bu yeni sonu birkaç dakika zihninde '
      'canlandırabilirsin.';

  static const _kind = <DreamKind, String>{
    DreamKind.normal:
        'Bu rüya, gün içinde zihninde dolaşan düşünceleri sindirmenin bir '
        'yolu olabilir.',
    DreamKind.lucid:
        'Rüyada farkında olman, zorlu bir durumda bile seçim yapabildiğini '
        'hatırlatıyor olabilir.',
    DreamKind.nightmare:
        'Kabuslar çoğu zaman gün içinde biriken gerginliğin işlenme '
        'biçimi olabilir; bir şeyin olacağını haber vermez.',
    DreamKind.recurring:
        'Tekrarlayan bir rüya, henüz kapanmamış bir konunun dikkatini '
        'istediğini düşündürebilir; kendine sor: Bu konu hayatımda nereye '
        'denk geliyor?',
  };

  static const _emotion = <DreamEmotion, String>{
    DreamEmotion.calm:
        'Rüyandaki sakinlik, şu sıralar içinde dengeye yer açtığını '
        'yansıtıyor olabilir.',
    DreamEmotion.joy:
        'Rüyandaki sevinç, hayatında seni besleyen bir şeye işaret ediyor '
        'olabilir; ne olduğunu fark etmek iyi gelebilir.',
    DreamEmotion.fear:
        'Rüyadaki korku, uyanıkken dile getirmediğin bir kaygının '
        'işlenmesiyle ilgili olabilir.',
    DreamEmotion.sadness:
        'Rüyadaki hüzün, bir kayıp ya da özlemle ilgili düşüncelerini '
        'yansıtıyor olabilir.',
    DreamEmotion.anger:
        'Rüyadaki öfke, ifade edilmeyi bekleyen bir sınır ya da ihtiyaçla '
        'ilgili olabilir.',
    DreamEmotion.confusion:
        'Rüyadaki karmaşa, birden çok seçenek arasında kaldığın bir konuyu '
        'yansıtıyor olabilir.',
  };
}
