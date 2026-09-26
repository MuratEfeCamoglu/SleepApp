import 'package:flutter/widgets.dart';

/// Metin stilleri (CLAUDE.md §5.3). Renk içermez; metin varsayılan olarak
/// `textPrimary` alır, ikincil metin `copyWith(color: ...)` ile verilir.
/// Widget'lar `context.text` ile okur.
@immutable
class AppTypography {
  const AppTypography._();

  static const instance = AppTypography._();

  static const display = 'Nunito';
  static const body = 'Figtree';
  static const _fallback = ['Segoe UI', 'system-ui', 'sans-serif'];

  static const _tabular = [FontFeature.tabularFigures()];

  /// 40 / 900 — trend ortalaması.
  TextStyle get displayNumber => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 40,
    height: 1,
    letterSpacing: -1,
    fontFeatures: _tabular,
  );

  /// [displayNumber] birimi.
  TextStyle get displayUnit => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 18,
    height: 1,
  );

  /// 72 / 900 — yalnızca Uyku modu saati.
  TextStyle get displayClock => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 72,
    height: 1,
    letterSpacing: -2,
    fontFeatures: _tabular,
  );

  /// 28 / 800 — ekran başlığı.
  TextStyle get titleLarge => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 32 / 28,
  );

  /// 20 / 700 — alt başlık.
  TextStyle get titleMedium => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 26 / 20,
  );

  /// 24 / 900 — halka merkezindeki süre.
  TextStyle get ringValue => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 24,
    height: 1.1,
    fontFeatures: _tabular,
  );

  /// 30 / 900 — fan grafiği merkezi.
  TextStyle get fanValue => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w900,
    fontSize: 30,
    height: 1,
  );

  /// 32 / 800 — Kaydet ekranı saatleri.
  TextStyle get clockValue => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    height: 1,
    fontFeatures: _tabular,
  );

  /// 22 / 800 — StageMetricTile ve stat kartı değeri.
  TextStyle get metric => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    height: 1,
    fontFeatures: _tabular,
  );

  /// 13 / 700 — [metric] birimi.
  TextStyle get metricUnit => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 13,
    height: 1,
  );

  /// 18 / 800 — kart içi toplam değer.
  TextStyle get valueMedium => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 18,
    height: 1.2,
    fontFeatures: _tabular,
  );

  /// 15 / 800 — satır sonu yüzdesi.
  TextStyle get valueSmall => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 15,
    height: 1.2,
    fontFeatures: _tabular,
  );

  /// 17 / 800 — pill butonlar.
  TextStyle get button => const TextStyle(
    fontFamily: display,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w800,
    fontSize: 17,
    height: 20 / 17,
  );

  /// 13 / 600 — başlık üstü satır.
  TextStyle get eyebrow => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 18 / 13,
  );

  /// 15 / 700 — kart ve bölüm başlığı.
  TextStyle get cardTitle => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 20 / 15,
  );

  /// 15 / 600 — satır etiketi.
  TextStyle get rowLabel => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 20 / 15,
  );

  /// 16 / 400 — açıklama.
  TextStyle get bodyLarge => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
  );

  /// 14 / 500 — satır değeri, lejant.
  TextStyle get bodyMedium => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
  );

  /// 14 / 700 — metin butonu, grafik başlığı.
  TextStyle get bodyStrong => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 20 / 14,
  );

  /// 13 / 400 — kart açıklaması.
  TextStyle get bodySmall => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.45,
  );

  /// 13 / 600 — rozet ve chip.
  TextStyle get chip => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 18 / 13,
  );

  /// 12.5 / 700 — uyanış hissi chip'i.
  TextStyle get chipStrong => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 12.5,
    height: 16 / 12.5,
  );

  /// 14 / 700 — segment etiketi.
  TextStyle get segment => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 18 / 14,
  );

  /// 12 / 700, büyük harf — grup başlığı.
  TextStyle get label => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.72,
  );

  /// 12 / 600 — tile başlığı.
  TextStyle get tileLabel => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
  );

  /// 12 / 500 — ipucu, lejant.
  TextStyle get caption => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
  );

  /// 12.5 / 400 — rutin adımı notu.
  TextStyle get note => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w400,
    fontSize: 12.5,
    height: 17 / 12.5,
  );

  /// 11 / 700 — alt panel etiketi, grafik ekseni.
  TextStyle get navLabel => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 14 / 11,
  );

  /// 11 / 600 — halka üst yazısı, hedef etiketi.
  TextStyle get micro => const TextStyle(
    fontFamily: body,
    fontFamilyFallback: _fallback,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 14 / 11,
  );
}
