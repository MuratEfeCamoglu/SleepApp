import 'package:flutter/material.dart';

/// Tema ile değişen renk tokenları (CLAUDE.md §5.1).
/// Widget'lar yalnızca `context.colors` ile okur.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.espresso,
    required this.onEspresso,
    required this.espressoSoft,
    required this.espressoDeep,
    required this.espressoSlice,
    required this.panel,
    required this.onPanel,
    required this.onPanelMuted,
    required this.panelOutline,
    required this.sageTint,
    required this.sageText,
    required this.emberTint,
    required this.emberText,
    required this.honeyTint,
    required this.honeyText,
    required this.chipLine,
    required this.goalLine,
    required this.outline,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color espresso;
  final Color onEspresso;
  final Color espressoSoft;
  final Color espressoDeep;
  final Color espressoSlice;
  final Color panel;
  final Color onPanel;
  final Color onPanelMuted;
  final Color panelOutline;
  final Color sageTint;
  final Color sageText;
  final Color emberTint;
  final Color emberText;
  final Color honeyTint;
  final Color honeyText;
  final Color chipLine;
  final Color goalLine;
  final Color outline;

  static const light = AppColors(
    background: Color(0xFFF4EDE2),
    surface: Color(0xFFFBF7F1),
    surfaceMuted: Color(0xFFE8DFD1),
    border: Color(0xFFDCD0BF),
    textPrimary: Color(0xFF2B211C),
    textSecondary: Color(0xFF6F5F54),
    espresso: Color(0xFF2B211C),
    onEspresso: Color(0xFFF4EDE2),
    espressoSoft: Color(0xFF6B5549),
    espressoDeep: Color(0xFF2B211C),
    espressoSlice: Color(0xFF2B211C),
    panel: Color(0xFF2B211C),
    onPanel: Color(0xFFF2EADF),
    onPanelMuted: Color(0xFFCDBFB1),
    panelOutline: Color(0xFF8A776A),
    sageTint: Color(0xFFDCE6D5),
    sageText: Color(0xFF43603C),
    emberTint: Color(0xFFF6DCCD),
    emberText: Color(0xFF8A3A17),
    honeyTint: Color(0xFFF5E3BC),
    honeyText: Color(0xFF7A5712),
    chipLine: Color(0xFFB8A999),
    goalLine: Color(0xFF8A776A),
    outline: Color(0x242B211C),
  );

  static const dark = AppColors(
    background: Color(0xFF1A1411),
    surface: Color(0xFF251D19),
    surfaceMuted: Color(0xFF352B25),
    border: Color(0xFF40352D),
    textPrimary: Color(0xFFF2EADF),
    textSecondary: Color(0xFFB3A395),
    espresso: Color(0xFFF2EADF),
    onEspresso: Color(0xFF2B211C),
    espressoSoft: Color(0xFFA38878),
    espressoDeep: Color(0xFF5C463B),
    espressoSlice: Color(0xFF7A6254),
    panel: Color(0xFF30251F),
    onPanel: Color(0xFFF2EADF),
    onPanelMuted: Color(0xFFCDBFB1),
    panelOutline: Color(0xFF8A776A),
    sageTint: Color(0xFF2E3A2B),
    sageText: Color(0xFFAECBA5),
    emberTint: Color(0xFF3D2419),
    emberText: Color(0xFFF0A07A),
    honeyTint: Color(0xFF3D3020),
    honeyText: Color(0xFFE7B04A),
    chipLine: Color(0xFF6B5B50),
    goalLine: Color(0xFF8A776A),
    outline: Color(0x29F2EADF),
  );

  /// Tamamen saydam — Material varsayılanlarını ezmek için.
  static const transparent = Color(0x00000000);

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      espresso: l(espresso, other.espresso),
      onEspresso: l(onEspresso, other.onEspresso),
      espressoSoft: l(espressoSoft, other.espressoSoft),
      espressoDeep: l(espressoDeep, other.espressoDeep),
      espressoSlice: l(espressoSlice, other.espressoSlice),
      panel: l(panel, other.panel),
      onPanel: l(onPanel, other.onPanel),
      onPanelMuted: l(onPanelMuted, other.onPanelMuted),
      panelOutline: l(panelOutline, other.panelOutline),
      sageTint: l(sageTint, other.sageTint),
      sageText: l(sageText, other.sageText),
      emberTint: l(emberTint, other.emberTint),
      emberText: l(emberText, other.emberText),
      honeyTint: l(honeyTint, other.honeyTint),
      honeyText: l(honeyText, other.honeyText),
      chipLine: l(chipLine, other.chipLine),
      goalLine: l(goalLine, other.goalLine),
      outline: l(outline, other.outline),
    );
  }
}
