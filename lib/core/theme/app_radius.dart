import 'package:flutter/widgets.dart';

/// Köşe yarıçapları (CLAUDE.md §5.5). Pill için `StadiumBorder` kullan.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double mdPlus = 16;
  static const double lgMinus = 18;
  static const double lg = 20;
  static const double lgPlus = 24;
  static const double xl = 28;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const mdPlusAll = BorderRadius.all(Radius.circular(mdPlus));
  static const lgMinusAll = BorderRadius.all(Radius.circular(lgMinus));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const lgPlusAll = BorderRadius.all(Radius.circular(lgPlus));
  static const xlAll = BorderRadius.all(Radius.circular(xl));
  static const xlTop = BorderRadius.vertical(top: Radius.circular(xl));
}
