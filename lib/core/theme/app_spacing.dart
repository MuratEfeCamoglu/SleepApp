import 'package:flutter/widgets.dart';

/// Boşluk ölçeği (CLAUDE.md §5.4).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double xsPlus = 6;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double lgPlus = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Ekran yatay kenar boşluğu.
  static const screenH = EdgeInsets.symmetric(horizontal: xl);
}
