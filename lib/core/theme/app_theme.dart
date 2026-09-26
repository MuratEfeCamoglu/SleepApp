import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uyku/core/theme/app_colors.dart';
import 'package:uyku/core/theme/app_typography.dart';

/// Material 3 açık, varsayılan görünüm ezilmiş (CLAUDE.md §5.8).
abstract final class AppTheme {
  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    const t = AppTypography.instance;
    final base = t.bodyMedium.copyWith(color: c.textPrimary);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.body,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.transparent,
      splashColor: AppColors.transparent,
      hoverColor: AppColors.transparent,
      focusColor: c.surfaceMuted,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.espresso,
        onPrimary: c.onEspresso,
        secondary: c.espressoSoft,
        onSecondary: c.onEspresso,
        error: c.emberText,
        onError: c.surface,
        surface: c.surface,
        onSurface: c.textPrimary,
        surfaceTint: AppColors.transparent,
        outline: c.border,
      ),
      textTheme: TextTheme(
        bodyMedium: base,
        bodyLarge: base,
        bodySmall: base,
        titleMedium: base,
        labelLarge: base,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.espresso,
        selectionColor: c.surfaceMuted,
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: c.espresso,
        textTheme: CupertinoTextThemeData(
          dateTimePickerTextStyle: t.titleMedium.copyWith(color: c.textPrimary),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        modalBackgroundColor: c.background,
        elevation: 0,
        modalElevation: 0,
        shadowColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [c],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get text => AppTypography.instance;
}
