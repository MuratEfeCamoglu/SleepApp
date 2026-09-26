import 'package:flutter/widgets.dart';

/// Hareket tokenları (CLAUDE.md §5.7).
abstract final class AppMotion {
  static const ringFill = Duration(milliseconds: 900);
  static const ringStagger = Duration(milliseconds: 120);
  static const Curve ringCurve = Curves.easeOutCubic;
  static const pageTransition = Duration(milliseconds: 280);
  static const double pageOffset = 16;
  static const sliceSelect = Duration(milliseconds: 180);
  static const Curve sliceCurve = Curves.easeOut;
  static const celebrate = Duration(milliseconds: 400);
  static const holdToConfirm = Duration(milliseconds: 1200);
  static const holdRelease = Duration(milliseconds: 150);
  static const skeletonPulse = Duration(milliseconds: 900);
  static const toggle = Duration(milliseconds: 160);
  static const progress = Duration(milliseconds: 200);

  /// Sekme içeriği ilk açılışta: öğeler sırayla solup 12 pt yükselir.
  static const entrance = Duration(milliseconds: 420);
  static const entranceStagger = Duration(milliseconds: 45);
  static const entranceMaxStagger = 5;
  static const double entranceOffset = 12;
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// Sekme değişiminde içerik solarak gelir.
  static const tabSwitch = Duration(milliseconds: 220);

  /// Basılıyken hafif küçülme.
  static const double pressScale = 0.97;

  /// Buton etiketi / durum değişimi (ör. "Kaydedildi").
  static const swap = Duration(milliseconds: 240);

  /// Trend grafiğinde aralık değişince çubukların akması.
  static const chartMorph = Duration(milliseconds: 380);

  /// Hareket azaltma açıksa animasyonlar son değere atlar.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
